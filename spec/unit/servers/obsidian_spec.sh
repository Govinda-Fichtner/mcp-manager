#!/bin/bash
# Unit tests for Obsidian MCP Server

Describe 'Obsidian MCP Server'
  Include spec/spec_helper.sh

  # Use main registry file for tests
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'Registry Configuration'
    It 'parses server name'
      When call get_server_field "obsidian" "name"
      The output should equal "Obsidian MCP Server"
    End

    It 'parses server type'
      When call get_server_field "obsidian" "server_type"
      The output should equal "api_based"
    End

    It 'parses description'
      When call get_server_field "obsidian" "description"
      The output should equal "Comprehensive Obsidian vault management with tools for reading, writing, searching, and managing notes, tags, and frontmatter"
    End

    It 'parses category'
      When call get_server_field "obsidian" "category"
      The output should equal "knowledge"
    End

    It 'parses source type as repository'
      When call get_server_field "obsidian" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "obsidian" "source.repository"
      The output should equal "https://github.com/cyanheads/obsidian-mcp-server.git"
    End

    It 'parses image name'
      When call get_server_field "obsidian" "source.image"
      The output should equal "local/obsidian-mcp-server:latest"
    End

    It 'parses dockerfile name'
      When call get_server_field "obsidian" "source.dockerfile"
      The output should equal "support/docker/Dockerfile.obsidian"
    End

    It 'parses build context'
      When call get_server_field "obsidian" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "obsidian" "environment_variables"
      The output should include "OBSIDIAN_API_KEY"
      The output should include "OBSIDIAN_BASE_URL"
    End

    It 'parses network mode'
      When call get_server_field "obsidian" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "obsidian" "startup_timeout"
      The output should equal "20"
    End
  End

  Describe 'List Command'
    It 'includes obsidian in server list'
      When call cmd_list
      The output should include "obsidian"
      The output should include "Comprehensive Obsidian vault management"
      The output should include "[knowledge]"
    End
  End
End
