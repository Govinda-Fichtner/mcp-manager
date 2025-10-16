#!/bin/bash
# Unit tests for DAP MCP Server (debugger-go)

Describe 'debugger-go MCP Server'
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
      When call get_server_field "debugger-go" "name"
      The output should equal "DAP MCP Server (Go)"
    End

    It 'parses server type'
      When call get_server_field "debugger-go" "server_type"
      The output should equal "mount_based"
    End

    It 'parses description'
      When call get_server_field "debugger-go" "description"
      The output should equal "Debug Adapter Protocol (DAP) server for Go - enables AI agents to debug Go applications"
    End

    It 'parses category'
      When call get_server_field "debugger-go" "category"
      The output should equal "development"
    End

    It 'parses source type as repository'
      When call get_server_field "debugger-go" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "debugger-go" "source.repository"
      The output should equal "https://github.com/Govinda-Fichtner/debugger-mcp.git"
    End

    It 'parses image name'
      When call get_server_field "debugger-go" "source.image"
      The output should equal "mcp-debugger-go:latest"
    End

    It 'parses dockerfile name'
      When call get_server_field "debugger-go" "source.dockerfile"
      The output should equal "Dockerfile.go"
    End

    It 'parses build context'
      When call get_server_field "debugger-go" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "debugger-go" "environment_variables"
      The output should include "DEBUGGER_WORKSPACE"
    End

    It 'parses volumes'
      When call get_server_field "debugger-go" "volumes"
      The output should include "DEBUGGER_WORKSPACE:/workspace"
    End

    It 'parses network mode'
      When call get_server_field "debugger-go" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses cmd array'
      When call get_server_field "debugger-go" "docker.cmd"
      The output should include "debugger_mcp"
      The output should include "serve"
    End

    It 'parses startup timeout'
      When call get_server_field "debugger-go" "startup_timeout"
      The output should equal "15"
    End
  End

  Describe 'List Command'
    It 'includes debugger-go in server list'
      When call cmd_list
      The output should include "debugger-go"
      The output should include "Debug Adapter Protocol (DAP) server for Go"
      The output should include "[development]"
    End
  End
End
