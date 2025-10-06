#!/bin/bash
# Unit tests for DAP MCP Server (debugger-python)

Describe 'debugger-python MCP Server'
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
      When call get_server_field "debugger-python" "name"
      The output should equal "DAP MCP Server (Python)"
    End

    It 'parses server type'
      When call get_server_field "debugger-python" "server_type"
      The output should equal "mount_based"
    End

    It 'parses description'
      When call get_server_field "debugger-python" "description"
      The output should equal "Debug Adapter Protocol (DAP) server for Python - enables AI agents to debug Python applications"
    End

    It 'parses category'
      When call get_server_field "debugger-python" "category"
      The output should equal "development"
    End

    It 'parses source type as repository'
      When call get_server_field "debugger-python" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "debugger-python" "source.repository"
      The output should equal "https://github.com/Govinda-Fichtner/debugger-mcp.git"
    End

    It 'parses image name'
      When call get_server_field "debugger-python" "source.image"
      The output should equal "local/debugger-mcp-python:latest"
    End

    It 'parses dockerfile name'
      When call get_server_field "debugger-python" "source.dockerfile"
      The output should equal "Dockerfile.python"
    End

    It 'parses build context'
      When call get_server_field "debugger-python" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "debugger-python" "environment_variables"
      The output should include "DEBUGGER_WORKSPACE"
    End

    It 'parses volumes'
      When call get_server_field "debugger-python" "volumes"
      The output should include "DEBUGGER_WORKSPACE:/workspace"
    End

    It 'parses network mode'
      When call get_server_field "debugger-python" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses cmd array'
      When call get_server_field "debugger-python" "docker.cmd"
      The output should include "debugger_mcp"
      The output should include "serve"
    End

    It 'parses startup timeout'
      When call get_server_field "debugger-python" "startup_timeout"
      The output should equal "15"
    End
  End

  Describe 'List Command'
    It 'includes debugger-python in server list'
      When call cmd_list
      The output should include "debugger-python"
      The output should include "Debug Adapter Protocol (DAP) server for Python"
      The output should include "[development]"
    End
  End
End
