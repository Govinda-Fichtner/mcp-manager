#!/bin/bash
# Unit tests for DAP MCP Server (debugger-ruby)

Describe 'debugger-ruby MCP Server'
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
      When call get_server_field "debugger-ruby" "name"
      The output should equal "DAP MCP Server (Ruby)"
    End

    It 'parses server type'
      When call get_server_field "debugger-ruby" "server_type"
      The output should equal "mount_based"
    End

    It 'parses description'
      When call get_server_field "debugger-ruby" "description"
      The output should equal "Debug Adapter Protocol (DAP) server for Ruby - enables AI agents to debug Ruby applications"
    End

    It 'parses category'
      When call get_server_field "debugger-ruby" "category"
      The output should equal "development"
    End

    It 'parses source type as repository'
      When call get_server_field "debugger-ruby" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "debugger-ruby" "source.repository"
      The output should equal "https://github.com/Govinda-Fichtner/debugger-mcp.git"
    End

    It 'parses image name'
      When call get_server_field "debugger-ruby" "source.image"
      The output should equal "mcp-debugger-ruby:latest"
    End

    It 'parses dockerfile name'
      When call get_server_field "debugger-ruby" "source.dockerfile"
      The output should equal "Dockerfile.ruby"
    End

    It 'parses build context'
      When call get_server_field "debugger-ruby" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "debugger-ruby" "environment_variables"
      The output should include "DEBUGGER_WORKSPACE"
    End

    It 'parses volumes'
      When call get_server_field "debugger-ruby" "volumes"
      The output should include "DEBUGGER_WORKSPACE:/workspace"
    End

    It 'parses network mode'
      When call get_server_field "debugger-ruby" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses cmd array'
      When call get_server_field "debugger-ruby" "docker.cmd"
      The output should include "debugger_mcp"
      The output should include "serve"
    End

    It 'parses startup timeout'
      When call get_server_field "debugger-ruby" "startup_timeout"
      The output should equal "15"
    End
  End

  Describe 'List Command'
    It 'includes debugger-ruby in server list'
      When call cmd_list
      The output should include "debugger-ruby"
      The output should include "Debug Adapter Protocol (DAP) server for Ruby"
      The output should include "[development]"
    End
  End
End
