#!/usr/bin/env bash
# MCP Manager - Manage Model Context Protocol servers with Docker
# Version: 0.1.0
# Following MacbookSetup proven patterns - monolithic initially

set -euo pipefail

#######################################
# Constants and Configuration
#######################################

# shellcheck disable=SC2155
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REGISTRY_FILE="${REGISTRY_FILE:-$SCRIPT_DIR/mcp_server_registry.yml}"
readonly ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"
readonly VERSION="0.1.0"

# Logging configuration
LOG_FILE="${LOG_FILE:-}"  # Can be set via --log-file flag
DEBUG="${DEBUG:-false}"    # Can be set via --debug or --verbose flag

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#######################################
# Logging Functions
#######################################

# Write to log file if configured
# Arguments:
#   $1 - Log level
#   $@ - Message
write_to_log_file() {
  if [[ -n "$LOG_FILE" ]]; then
    local level="$1"
    shift
    local timestamp
    timestamp="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
    echo "[$timestamp] [$level] $*" >> "$LOG_FILE"
  fi
}

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
  write_to_log_file "INFO" "$@"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
  write_to_log_file "WARN" "$@"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
  write_to_log_file "ERROR" "$@"
}

log_debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*" >&2
  fi
  write_to_log_file "DEBUG" "$@"
}

# Verbose logging - same as debug but with different semantic meaning
log_verbose() {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "${BLUE}[VERBOSE]${NC} $*" >&2
  fi
  write_to_log_file "VERBOSE" "$@"
}

#######################################
# Dependency Checking
#######################################

# Check if a single command exists
# Arguments:
#   $1 - Command name
# Returns:
#   0 if command exists, 1 otherwise
check_dependency() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Get installation instructions for a missing dependency
# Arguments:
#   $1 - Dependency name
get_install_instructions() {
  local dep="$1"
  case "$dep" in
    docker)
      echo "Install Docker: https://docs.docker.com/get-docker/"
      ;;
    yq)
      echo "Install yq: https://github.com/mikefarah/yq#install"
      echo "  macOS: brew install yq"
      echo "  Linux: Download from GitHub releases"
      ;;
    jq)
      echo "Install jq: https://stedolan.github.io/jq/download/"
      echo "  macOS: brew install jq"
      echo "  Linux: sudo apt-get install jq"
      ;;
    git)
      echo "Install git:"
      echo "  macOS: brew install git"
      echo "  Linux: sudo apt-get install git"
      ;;
    jinja2)
      echo "Install jinja2-cli:"
      echo "  pip install jinja2-cli"
      echo "  macOS: brew install jinja2-cli"
      ;;
    *)
      echo "Please install $dep"
      ;;
  esac
}

# Check all required dependencies
# Returns:
#   0 if all dependencies present, 1 otherwise
check_all_dependencies() {
  local missing=()
  local deps=(docker yq jq git jinja2)

  for dep in "${deps[@]}"; do
    if ! check_dependency "$dep"; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required dependencies: ${missing[*]}"
    echo ""
    for dep in "${missing[@]}"; do
      get_install_instructions "$dep"
      echo ""
    done
    return 1
  fi

  log_debug "All dependencies present"
  return 0
}

#######################################
# Registry Functions
#######################################

# Validate registry file exists and is readable
# Returns:
#   0 if valid, 1 otherwise
validate_registry() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    log_error "Registry file not found: $REGISTRY_FILE"
    return 1
  fi

  if [[ ! -r "$REGISTRY_FILE" ]]; then
    log_error "Registry file not readable: $REGISTRY_FILE"
    return 1
  fi

  # Validate YAML syntax
  if ! yq eval '.' "$REGISTRY_FILE" >/dev/null 2>&1; then
    log_error "Invalid YAML syntax in registry file"
    return 1
  fi

  log_debug "Registry file validated: $REGISTRY_FILE"
  return 0
}

# List all servers in registry
# Outputs:
#   Server names, one per line
list_servers() {
  yq eval '.servers | keys | .[]' "$REGISTRY_FILE"
}

# Check if server exists in registry
# Arguments:
#   $1 - Server name
# Returns:
#   0 if exists, 1 otherwise
server_exists() {
  local server_name="$1"
  local servers
  servers="$(list_servers)"

  if grep -q "^${server_name}$" <<< "$servers"; then
    return 0
  else
    return 1
  fi
}

# Get server field from registry
# Arguments:
#   $1 - Server name
#   $2 - Field path (yq syntax)
# Outputs:
#   Field value
get_server_field() {
  local server_name="$1"
  local field="$2"
  yq eval ".servers.${server_name}.${field}" "$REGISTRY_FILE"
}

#######################################
# Platform Detection
#######################################

# Detect current platform architecture
# Outputs:
#   Platform string (e.g., "linux/amd64", "linux/arm64")
detect_platform() {
  local os
  local arch

  # Detect OS
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"

  # Detect architecture
  arch="$(uname -m)"
  case "$arch" in
    x86_64)
      arch="amd64"
      ;;
    aarch64|arm64)
      arch="arm64"
      ;;
    *)
      log_warn "Unknown architecture: $arch, defaulting to amd64"
      arch="amd64"
      ;;
  esac

  echo "${os}/${arch}"
}

#######################################
# Help and Usage
#######################################

show_help() {
  cat << EOF
MCP Manager v${VERSION}
Manage Model Context Protocol servers with Docker

USAGE:
  mcp_manager.sh [COMMAND] [OPTIONS]

COMMANDS:
  list                    List all available MCP servers
  setup <server>          Setup and pull/build MCP server
  info <server>           Show server information
  health <server>         Check server health
  config <server>         Generate configuration for MCP clients
  remove <server>         Remove MCP server
  version                 Show version information
  help                    Show this help message

OPTIONS:
  --debug, --verbose, -v  Enable verbose debug output
  --log-file <path>       Write detailed logs to file
  --registry <file>       Use custom registry file
  --env <file>            Use custom .env file

EXAMPLES:
  # List available servers
  mcp_manager.sh list

  # Setup GitHub server
  mcp_manager.sh setup github

  # Generate Claude Code config
  mcp_manager.sh config github --format claude-code

  # Check server health
  mcp_manager.sh health github

  # Enable verbose logging
  mcp_manager.sh --verbose setup filesystem

  # Log to file for troubleshooting
  mcp_manager.sh --log-file /tmp/mcp-debug.log setup github

For more information, see: https://github.com/yourusername/mcp-manager
EOF
}

show_version() {
  echo "MCP Manager v${VERSION}"
  echo "Platform: $(detect_platform)"
  echo ""
  echo "Dependencies:"
  check_dependency docker && echo "  docker: $(docker --version 2>&1 | head -1)" || echo "  docker: NOT FOUND"
  check_dependency yq && echo "  yq: $(yq --version 2>&1 | head -1)" || echo "  yq: NOT FOUND"
  check_dependency jq && echo "  jq: $(jq --version 2>&1 | head -1)" || echo "  jq: NOT FOUND"
  check_dependency git && echo "  git: $(git --version 2>&1 | head -1)" || echo "  git: NOT FOUND"
  check_dependency jinja2 && echo "  jinja2: $(jinja2 --version 2>&1 | head -1)" || echo "  jinja2: NOT FOUND"
}

#######################################
# Docker Helper Functions
#######################################

# Check if Docker image exists locally
# Arguments:
#   $1 - Image name (with optional tag)
# Returns:
#   0 if exists, 1 otherwise
docker_image_exists() {
  local image="$1"
  docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"
}

# Get Docker image ID
# Arguments:
#   $1 - Image name
# Outputs:
#   Image ID or empty string
docker_image_id() {
  local image="$1"
  docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep "^${image}" | awk '{print $2}' | head -1
}

# Pull Docker image from registry
# Arguments:
#   $1 - Image name with registry
#   $2 - Platform (optional, auto-detected if not provided)
# Returns:
#   0 if success, 1 otherwise
docker_pull_image() {
  local image="$1"
  local platform="${2:-$(detect_platform)}"

  log_info "Pulling image: $image (platform: $platform)"
  log_verbose "Docker pull command: docker pull --platform $platform $image"

  if docker pull --platform "$platform" "$image"; then
    log_info "Successfully pulled: $image"
    local image_id
    image_id="$(docker_image_id "$image")"
    log_verbose "Image ID: $image_id"
    return 0
  else
    log_error "Failed to pull image: $image"
    log_verbose "Docker pull failed - check network connection and image availability"
    return 1
  fi
}

#######################################
# Environment Variable Functions
#######################################

# Load .env file if it exists
# Sets environment variables from .env
load_env_file() {
  if [[ -f "$ENV_FILE" ]]; then
    log_debug "Loading environment from: $ENV_FILE"
    log_verbose "Environment file found: $ENV_FILE"
    # shellcheck disable=SC1090
    set -a
    source "$ENV_FILE"
    set +a
    log_verbose "Environment variables loaded successfully"
  else
    log_debug "No .env file found at: $ENV_FILE"
  fi
}

# Redact sensitive value for display
# Arguments:
#   $1 - Value to redact
# Outputs:
#   Redacted string (e.g., "ghp_****")
redact_value() {
  local value="$1"
  if [[ -z "$value" ]]; then
    echo "(not set)"
  else
    local prefix="${value:0:4}"
    echo "${prefix}****"
  fi
}

#######################################
# Command: list
#######################################

cmd_list() {
  if ! validate_registry; then
    return 1
  fi

  log_info "Available MCP servers:"
  echo ""

  while IFS= read -r server; do
    local name desc category
    name="$(get_server_field "$server" "name")"
    desc="$(get_server_field "$server" "description")"
    category="$(get_server_field "$server" "category")"

    printf "  %-15s %-50s [%s]\n" "$server" "$desc" "$category"
  done < <(list_servers)
}

#######################################
# Command: info
#######################################

cmd_info() {
  local server_name="${1:-}"

  if [[ -z "$server_name" ]]; then
    log_error "Server name required"
    echo "Usage: mcp_manager.sh info <server>"
    return 1
  fi

  if ! validate_registry; then
    return 1
  fi

  if ! server_exists "$server_name"; then
    log_error "Server not found: $server_name"
    return 1
  fi

  load_env_file

  # Get server information from registry
  local name desc source_type image
  name="$(get_server_field "$server_name" "name")"
  desc="$(get_server_field "$server_name" "description")"
  source_type="$(get_server_field "$server_name" "source.type")"

  echo ""
  echo "Server: $server_name"
  echo "Name: $name"
  echo "Description: $desc"
  echo "Source Type: $source_type"
  echo ""

  # Get image information
  if [[ "$source_type" == "registry" ]]; then
    local registry image_name tag
    registry="$(get_server_field "$server_name" "source.registry")"
    image_name="$(get_server_field "$server_name" "source.image")"
    tag="$(get_server_field "$server_name" "source.tag")"
    image="${registry}/${image_name}:${tag}"

    echo "Registry Image: $image"

    if docker_image_exists "$image"; then
      local image_id
      image_id="$(docker_image_id "$image")"
      echo "Local Status: ✓ Present (ID: ${image_id:0:12})"
    else
      echo "Local Status: ✗ Not pulled yet"
    fi
  elif [[ "$source_type" == "repository" ]]; then
    local repo
    repo="$(get_server_field "$server_name" "source.repository")"
    echo "Repository: $repo"
    echo "Build Status: Run 'mcp_manager.sh setup $server_name' to build"
  elif [[ "$source_type" == "dockerfile" ]]; then
    local dockerfile_path
    dockerfile_path="$(get_server_field "$server_name" "source.dockerfile")"
    image="$(get_server_field "$server_name" "source.image")"

    # Default image name if not specified
    if [[ -z "$image" || "$image" == "null" ]]; then
      image="mcp-${server_name}:latest"
    fi

    echo "Dockerfile: $dockerfile_path"
    echo "Image Tag: $image"

    if docker_image_exists "$image"; then
      local image_id
      image_id="$(docker_image_id "$image")"
      echo "Local Status: ✓ Built (ID: ${image_id:0:12})"
    else
      echo "Local Status: ✗ Not built yet"
      echo "Build: Run 'mcp_manager.sh setup $server_name' to build"
    fi
  fi

  echo ""

  # Show environment variables
  echo "Environment Variables:"
  local env_vars
  env_vars="$(yq eval ".servers.${server_name}.environment_variables[].name" "$REGISTRY_FILE")"

  if [[ -n "$env_vars" ]]; then
    while IFS= read -r var_name; do
      local var_value="${!var_name:-}"
      local redacted
      redacted="$(redact_value "$var_value")"
      printf "  %-30s %s\n" "$var_name:" "$redacted"
    done <<< "$env_vars"
  else
    echo "  None"
  fi

  echo ""
}

#######################################
# Command: health
#######################################

cmd_health() {
  local server_name="${1:-}"

  if [[ -z "$server_name" ]]; then
    log_error "Server name required"
    echo "Usage: mcp_manager.sh health <server>"
    return 1
  fi

  if ! validate_registry; then
    return 1
  fi

  if ! server_exists "$server_name"; then
    log_error "Server not found: $server_name"
    return 1
  fi

  log_info "Checking health for: $server_name"
  echo ""

  # Check Docker daemon
  if docker info >/dev/null 2>&1; then
    echo "✓ Docker daemon accessible"
  else
    echo "✗ Docker daemon not accessible"
    return 1
  fi

  # Check if image exists
  local source_type
  source_type="$(get_server_field "$server_name" "source.type")"

  if [[ "$source_type" == "registry" ]]; then
    local registry image_name tag image
    registry="$(get_server_field "$server_name" "source.registry")"
    image_name="$(get_server_field "$server_name" "source.image")"
    tag="$(get_server_field "$server_name" "source.tag")"
    image="${registry}/${image_name}:${tag}"

    if docker_image_exists "$image"; then
      echo "✓ Docker image present: $image"
    else
      echo "✗ Docker image not found: $image"
      echo "  Run: mcp_manager.sh setup $server_name"
      return 1
    fi
  elif [[ "$source_type" == "dockerfile" ]]; then
    local image
    image="$(get_server_field "$server_name" "source.image")"

    # Default image name if not specified
    if [[ -z "$image" || "$image" == "null" ]]; then
      image="mcp-${server_name}:latest"
    fi

    if docker_image_exists "$image"; then
      echo "✓ Docker image built: $image"
    else
      echo "✗ Docker image not found: $image"
      echo "  Run: mcp_manager.sh setup $server_name"
      return 1
    fi
  else
    echo "⊘ Build from source - image check skipped"
  fi

  echo ""
  log_info "Status: READY"
  return 0
}

#######################################
# Command: setup
#######################################

cmd_setup() {
  local server_name="${1:-}"

  if [[ -z "$server_name" ]]; then
    log_error "Server name required"
    echo "Usage: mcp_manager.sh setup <server>"
    return 1
  fi

  if ! validate_registry; then
    return 1
  fi

  if ! server_exists "$server_name"; then
    log_error "Server not found: $server_name"
    return 1
  fi

  load_env_file

  local source_type
  source_type="$(get_server_field "$server_name" "source.type")"

  case "$source_type" in
    registry)
      setup_from_registry "$server_name"
      ;;
    repository)
      setup_from_repository "$server_name"
      ;;
    dockerfile)
      setup_from_dockerfile "$server_name"
      ;;
    *)
      log_error "Unknown source type: $source_type"
      return 1
      ;;
  esac
}

# Setup server from registry (pull pre-built image)
# Arguments:
#   $1 - Server name
setup_from_registry() {
  local server_name="$1"

  log_info "Setting up $server_name from registry"
  log_verbose "Server name: $server_name"

  local registry image_name tag image
  registry="$(get_server_field "$server_name" "source.registry")"
  image_name="$(get_server_field "$server_name" "source.image")"
  tag="$(get_server_field "$server_name" "source.tag")"
  image="${registry}/${image_name}:${tag}"

  log_verbose "Registry: $registry"
  log_verbose "Image name: $image_name"
  log_verbose "Tag: $tag"
  log_verbose "Full image: $image"

  # Pull image
  if docker_pull_image "$image"; then
    log_info "Setup complete for: $server_name"
    log_verbose "Image pulled successfully"
    echo ""
    echo "Next steps:"
    echo "  1. Configure environment variables in .env file"
    echo "  2. Generate config: mcp_manager.sh config $server_name"
    echo "  3. Check health: mcp_manager.sh health $server_name"
    return 0
  else
    log_verbose "Image pull failed"
    return 1
  fi
}

# Setup server from repository (clone and build)
# Arguments:
#   $1 - Server name
setup_from_repository() {
  local server_name="$1"

  log_info "Setting up $server_name from repository"
  log_verbose "Server name: $server_name"

  local repo subdirectory dockerfile build_context
  repo="$(get_server_field "$server_name" "source.repository")"
  subdirectory="$(get_server_field "$server_name" "source.subdirectory")"
  dockerfile="$(get_server_field "$server_name" "source.dockerfile")"
  build_context="$(get_server_field "$server_name" "source.build_context")"

  log_verbose "Repository: $repo"
  log_verbose "Subdirectory: $subdirectory"
  log_verbose "Dockerfile path: $dockerfile"
  log_verbose "Build context: $build_context"

  # Create temporary directory for clone
  local tmp_dir="$SCRIPT_DIR/tmp/build_${server_name}_$$"
  log_verbose "Creating temporary directory: $tmp_dir"
  mkdir -p "$tmp_dir"

  log_info "Cloning repository: $repo"
  log_verbose "Clone depth: 1 (shallow clone)"
  if ! git clone --depth 1 "$repo" "$tmp_dir"; then
    log_error "Failed to clone repository"
    log_verbose "Cleaning up: $tmp_dir"
    rm -rf "$tmp_dir"
    return 1
  fi
  log_verbose "Repository cloned successfully"

  # Determine build directory
  # If subdirectory is set, it's informational - build context is always from repo root
  local build_dir="$tmp_dir"
  log_verbose "Build directory: $build_dir"

  if [[ ! -d "$build_dir" ]]; then
    log_error "Build directory not found: $build_dir"
    log_verbose "Cleaning up: $tmp_dir"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Build Docker image
  local image_tag="mcp-${server_name}:latest"
  local platform
  platform="$(detect_platform)"

  log_info "Building Docker image: $image_tag"
  log_info "Platform: $platform"
  log_info "Dockerfile: $dockerfile"
  log_info "Build context: $build_context"
  log_verbose "Working directory for build: $build_dir"

  cd "$build_dir" || return 1

  log_verbose "Starting Docker build..."
  if docker build --platform "$platform" -t "$image_tag" -f "$dockerfile" "$build_context"; then
    log_info "Successfully built: $image_tag"
    log_verbose "Returning to script directory"
    cd "$SCRIPT_DIR" || true
    log_verbose "Cleaning up: $tmp_dir"
    rm -rf "$tmp_dir"

    echo ""
    echo "Next steps:"
    echo "  1. Configure environment variables in .env file"
    echo "  2. Generate config: mcp_manager.sh config $server_name"
    echo "  3. Check health: mcp_manager.sh health $server_name"
    return 0
  else
    log_error "Failed to build image"
    cd "$SCRIPT_DIR" || true
    rm -rf "$tmp_dir"
    return 1
  fi
}

# Setup server from local Dockerfile
# Arguments:
#   $1 - Server name
setup_from_dockerfile() {
  local server_name="$1"

  log_info "Setting up $server_name from local Dockerfile"
  log_verbose "Server name: $server_name"

  local dockerfile build_context image_tag
  dockerfile="$(get_server_field "$server_name" "source.dockerfile")"
  build_context="$(get_server_field "$server_name" "source.build_context")"
  image_tag="$(get_server_field "$server_name" "source.image")"

  # Default to mcp-<servername>:latest if not specified
  if [[ -z "$image_tag" || "$image_tag" == "null" ]]; then
    image_tag="mcp-${server_name}:latest"
  fi

  log_verbose "Dockerfile: $dockerfile"
  log_verbose "Build context: $build_context"
  log_verbose "Image tag: $image_tag"

  # Resolve paths relative to script directory
  local dockerfile_path="$SCRIPT_DIR/$dockerfile"
  local context_path="$SCRIPT_DIR/$build_context"

  log_verbose "Absolute Dockerfile path: $dockerfile_path"
  log_verbose "Absolute build context path: $context_path"

  # Check if Dockerfile exists
  if [[ ! -f "$dockerfile_path" ]]; then
    log_error "Dockerfile not found: $dockerfile_path"
    return 1
  fi

  # Check if build context directory exists
  if [[ ! -d "$context_path" ]]; then
    log_error "Build context directory not found: $context_path"
    return 1
  fi

  # Build Docker image
  local platform
  platform="$(detect_platform)"

  log_info "Building Docker image: $image_tag"
  log_info "Platform: $platform"
  log_info "Dockerfile: $dockerfile"
  log_info "Build context: $build_context"

  cd "$context_path" || return 1

  log_verbose "Starting Docker build..."
  if docker build --platform "$platform" -t "$image_tag" -f "$dockerfile_path" .; then
    log_info "Successfully built: $image_tag"
    log_verbose "Returning to script directory"
    cd "$SCRIPT_DIR" || true

    echo ""
    echo "Next steps:"
    echo "  1. Configure environment variables in .env file"
    echo "  2. Generate config: mcp_manager.sh config $server_name"
    echo "  3. Check health: mcp_manager.sh health $server_name"
    return 0
  else
    log_error "Failed to build image"
    log_verbose "Docker build failed - check Dockerfile and build context"
    cd "$SCRIPT_DIR" || true
    return 1
  fi
}

#######################################
# Command: config
#######################################

cmd_config() {
  local server_name="${1:-}"
  local format="${2:---format}"
  local output_mode="${3:-snippet}"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --format)
        format="$2"
        shift 2
        ;;
      --snippet)
        output_mode="snippet"
        shift
        ;;
      --full)
        output_mode="full"
        shift
        ;;
      --output)
        local output_file="$2"
        shift 2
        ;;
      *)
        if [[ -z "$server_name" ]]; then
          server_name="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$server_name" ]]; then
    log_error "Server name required"
    echo "Usage: mcp_manager.sh config <server> --format <claude-code|claude-desktop|gemini-cli> [--snippet|--full] [--output <file>]"
    return 1
  fi

  log_verbose "Generating config for server: $server_name"
  log_verbose "Format: $format"
  log_verbose "Output mode: $output_mode"

  if ! validate_registry; then
    return 1
  fi

  if ! server_exists "$server_name"; then
    log_error "Server not found: $server_name"
    return 1
  fi

  load_env_file

  # Validate format
  case "$format" in
    claude-code|claude-desktop|gemini-cli)
      log_verbose "Format validated: $format"
      ;;
    *)
      log_error "Unknown format: $format"
      echo "Supported formats: claude-code, claude-desktop, gemini-cli"
      return 1
      ;;
  esac

  # Build template context
  local context_json
  context_json="$(build_config_context "$server_name")"

  # Select template
  local template_file="$SCRIPT_DIR/support/templates/${format}.json.j2"
  if [[ "$format" == "gemini-cli" ]]; then
    template_file="$SCRIPT_DIR/support/templates/gemini-cli.yaml.j2"
  fi

  if [[ ! -f "$template_file" ]]; then
    log_error "Template not found: $template_file"
    return 1
  fi

  # Render template
  local config_output
  if ! config_output="$(echo "$context_json" | jinja2 "$template_file")"; then
    log_error "Failed to render template"
    return 1
  fi

  # Output configuration
  if [[ -n "${output_file:-}" ]]; then
    echo "$config_output" > "$output_file"
    log_info "Configuration written to: $output_file"
  else
    echo ""
    log_info "Generated configuration for $server_name ($format format):"
    echo ""
    echo "$config_output"
    echo ""

    if [[ "$output_mode" == "snippet" ]]; then
      echo "# To use this configuration:"
      case "$format" in
        claude-code)
          echo "#   Add the above to your .claude-code.json file under 'mcpServers'"
          ;;
        claude-desktop)
          echo "#   Add the above to ~/.config/claude/claude_desktop_config.json under 'mcpServers'"
          ;;
        gemini-cli)
          echo "#   Add the above to your gemini-cli config file"
          ;;
      esac
    fi
  fi
}

# Build configuration context for Jinja2 template
# Arguments:
#   $1 - Server name
# Outputs:
#   JSON context for template
build_config_context() {
  local server_name="$1"

  # Get server metadata
  local name desc source_type
  name="$(get_server_field "$server_name" "name")"
  desc="$(get_server_field "$server_name" "description")"
  source_type="$(get_server_field "$server_name" "source.type")"

  # Determine image name
  local image
  if [[ "$source_type" == "registry" ]]; then
    local registry image_name tag
    registry="$(get_server_field "$server_name" "source.registry")"
    image_name="$(get_server_field "$server_name" "source.image")"
    tag="$(get_server_field "$server_name" "source.tag")"
    image="${registry}/${image_name}:${tag}"
  elif [[ "$source_type" == "dockerfile" ]]; then
    # For local Dockerfile build, get image tag from registry or default
    image="$(get_server_field "$server_name" "source.image")"
    if [[ -z "$image" || "$image" == "null" ]]; then
      image="mcp-${server_name}:latest"
    fi
  else
    # For repository build, use local tag
    image="mcp-${server_name}:latest"
  fi

  # Get environment variables
  local env_vars_json="[]"
  local env_file_path="$SCRIPT_DIR/.env"

  local env_vars
  env_vars="$(yq eval ".servers.${server_name}.environment_variables[].name" "$REGISTRY_FILE" 2>/dev/null || echo "")"

  if [[ -n "$env_vars" ]]; then
    # Build array of env var names
    env_vars_json="$(echo "$env_vars" | jq -R -s 'split("\n") | map(select(length > 0))')"
  fi

  # Get volumes
  local volumes_json="[]"
  local volumes_count
  volumes_count="$(yq eval ".servers.${server_name}.volumes | length" "$REGISTRY_FILE" 2>/dev/null || echo "0")"

  if [[ "$volumes_count" != "0" && "$volumes_count" != "null" ]]; then
    volumes_json="$(yq eval ".servers.${server_name}.volumes" "$REGISTRY_FILE" -o=json)"
  fi

  # Build complete context
  jq -n \
    --arg server_id "$server_name" \
    --arg description "$desc" \
    --arg image "$image" \
    --arg env_file "$env_file_path" \
    --argjson env_vars "$env_vars_json" \
    --argjson volumes "$volumes_json" \
    '{
      server_id: $server_id,
      description: $description,
      image: $image,
      env_file: (if ($env_vars | length > 0) then $env_file else null end),
      env_vars: $env_vars,
      volumes: (if ($volumes | length > 0) then $volumes else [] end),
      container_args: []
    }'
}

#######################################
# Main Entry Point
#######################################

main() {
  local command="${1:-help}"

  # Parse global flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --debug|--verbose|-v)
        export DEBUG=true
        shift
        ;;
      --log-file)
        export LOG_FILE="$2"
        shift 2
        ;;
      --registry)
        export REGISTRY_FILE="$2"
        shift 2
        ;;
      --env)
        export ENV_FILE="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  # Get command (after flags)
  command="${1:-help}"
  shift || true

  # Initialize log file if specified
  if [[ -n "$LOG_FILE" ]]; then
    log_verbose "Log file enabled: $LOG_FILE"
    # Create log file directory if needed
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    if [[ ! -d "$log_dir" ]]; then
      mkdir -p "$log_dir"
    fi
    # Clear or create log file
    : > "$LOG_FILE"
    log_verbose "MCP Manager v$VERSION starting"
    log_verbose "Command: $command"
  fi

  # Route to command
  case "$command" in
    list)
      check_all_dependencies || exit 2
      cmd_list
      ;;
    setup)
      check_all_dependencies || exit 2
      cmd_setup "$@"
      ;;
    info)
      check_all_dependencies || exit 2
      cmd_info "$@"
      ;;
    health)
      check_all_dependencies || exit 2
      cmd_health "$@"
      ;;
    config)
      check_all_dependencies || exit 2
      cmd_config "$@"
      ;;
    remove)
      check_all_dependencies || exit 2
      log_error "Command 'remove' not yet implemented"
      exit 1
      ;;
    version)
      show_version
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      log_error "Unknown command: $command"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
