#!/bin/bash
# Unit tests for DAP MCP Server (debugger-rust)

Describe 'debugger-rust MCP Server'
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
      When call get_server_field "debugger-rust" "name"
      The output should equal "DAP MCP Server (Rust)"
    End

    It 'parses server type'
      When call get_server_field "debugger-rust" "server_type"
      The output should equal "mount_based"
    End

    It 'parses description'
      When call get_server_field "debugger-rust" "description"
      The output should equal "Debug Adapter Protocol (DAP) server for Rust - enables AI agents to debug Rust applications"
    End

    It 'parses category'
      When call get_server_field "debugger-rust" "category"
      The output should equal "development"
    End

    It 'parses source type as repository'
      When call get_server_field "debugger-rust" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "debugger-rust" "source.repository"
      The output should equal "https://github.com/Govinda-Fichtner/debugger-mcp.git"
    End

    It 'parses image name'
      When call get_server_field "debugger-rust" "source.image"
      The output should equal "mcp-debugger-rust:latest"
    End

    It 'parses dockerfile name'
      When call get_server_field "debugger-rust" "source.dockerfile"
      The output should equal "Dockerfile.rust"
    End

    It 'parses build context'
      When call get_server_field "debugger-rust" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "debugger-rust" "environment_variables"
      The output should include "DEBUGGER_WORKSPACE"
    End

    It 'parses volumes'
      When call get_server_field "debugger-rust" "volumes"
      The output should include "DEBUGGER_WORKSPACE:/workspace"
    End

    It 'parses network mode'
      When call get_server_field "debugger-rust" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses cmd array'
      When call get_server_field "debugger-rust" "docker.cmd"
      The output should include "debugger_mcp"
      The output should include "serve"
    End

    It 'parses startup timeout'
      When call get_server_field "debugger-rust" "startup_timeout"
      The output should equal "15"
    End
  End

  Describe 'List Command'
    It 'includes debugger-rust in server list'
      When call cmd_list
      The output should include "debugger-rust"
      The output should include "Debug Adapter Protocol (DAP) server for Rust"
      The output should include "[development]"
    End
  End
End
