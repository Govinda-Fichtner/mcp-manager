#!/bin/bash
# Unit tests for config command

Describe 'Config Command'
  Include mcp_manager.sh
  Include spec/spec_helper.sh

  setup() {
    setup_test_env
    # Create a minimal test registry
    cat > "$TEST_REGISTRY" <<'EOF'
servers:
  test-server:
    name: "Test Server"
    description: "Test description"
    category: "test"
    source:
      type: "registry"
      registry: "docker.io"
      image: "test/server"
      tag: "latest"
    environment_variables:
      - name: "TEST_VAR"
        description: "Test variable"
        required: true
    volumes:
      - source: "/test/path"
        target: "/data"
        mode: "ro"
EOF
    export REGISTRY_FILE="$TEST_REGISTRY"
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'build_config_context()'
    It 'generates JSON context with output_mode'
      When call build_config_context test-server full
      The status should equal 0
      The output should include '"server_id": "test-server"'
      The output should include '"output_mode": "full"'
    End

    It 'includes image information'
      When call build_config_context test-server full
      The output should include '"image": "docker.io/test/server:latest"'
    End

    It 'includes environment variables'
      When call build_config_context test-server full
      The output should include '"env_vars":'
      The output should include 'TEST_VAR'
    End

    It 'includes volumes'
      When call build_config_context test-server full
      The output should include '"volumes":'
      The output should include '/test/path'
    End

    It 'accepts snippet mode'
      When call build_config_context test-server snippet
      The output should include '"output_mode": "snippet"'
    End

    It 'accepts add-json mode'
      When call build_config_context test-server add-json
      The output should include '"output_mode": "add-json"'
    End
  End

  Describe 'Output modes validation'
    It 'generates different output for full mode'
      Skip "Requires full template rendering - integration test"
    End

    It 'generates different output for snippet mode'
      Skip "Requires full template rendering - integration test"
    End

    It 'generates single-line JSON for add-json mode'
      Skip "Requires full template rendering - integration test"
    End

    It 'validates --add-json only works with claude-code format'
      Skip "Requires command-line argument parsing - integration test"
    End
  End
End
