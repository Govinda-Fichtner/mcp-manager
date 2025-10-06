#!/bin/bash
# Unit tests for Figma MCP server

Describe 'Figma MCP Server'
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
      When call get_server_field "figma" "name"
      The output should equal "Figma Context MCP Server"
    End

    It 'parses server type'
      When call get_server_field "figma" "server_type"
      The output should equal "api_based"
    End

    It 'parses description'
      When call get_server_field "figma" "description"
      The output should equal "Figma design data extraction optimized for AI orchestration with intelligent design filtering"
    End

    It 'parses category'
      When call get_server_field "figma" "category"
      The output should equal "design"
    End

    It 'parses source type as registry'
      When call get_server_field "figma" "source.type"
      The output should equal "registry"
    End

    It 'parses image name'
      When call get_server_field "figma" "source.image"
      The output should equal "ghcr.io/metorial/mcp-container--glips--figma-context-mcp--figma-context-mcp:latest"
    End

    It 'parses environment variables'
      When call get_server_field "figma" "environment_variables"
      The output should include "FIGMA_API_KEY"
    End

    It 'parses network mode'
      When call get_server_field "figma" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "figma" "startup_timeout"
      The output should equal "10"
    End
  End

  Describe 'List Command'
    It 'includes figma in server list'
      When call cmd_list
      The output should include "figma"
      The output should include "Figma design data extraction optimized for AI orchestration with intelligent design filtering"
      The output should include "[design]"
    End
  End
End
