#!/bin/bash
# Unit tests for DAP MCP Server (debugger-nodejs)

Describe 'debugger-nodejs MCP Server'
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
      When call get_server_field "debugger-nodejs" "name"
      The output should equal "DAP MCP Server (Node.js)"
    End

    It 'parses server type'
      When call get_server_field "debugger-nodejs" "server_type"
      The output should equal "mount_based"
    End

    It 'parses description'
      When call get_server_field "debugger-nodejs" "description"
      The output should equal "Debug Adapter Protocol (DAP) server for Node.js - enables AI agents to debug Node.js applications"
    End

    It 'parses category'
      When call get_server_field "debugger-nodejs" "category"
      The output should equal "development"
    End

    It 'parses source type as repository'
      When call get_server_field "debugger-nodejs" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "debugger-nodejs" "source.repository"
      The output should equal "https://github.com/Govinda-Fichtner/debugger-mcp.git"
    End

    It 'parses image name'
      When call get_server_field "debugger-nodejs" "source.image"
      The output should equal "local/debugger-mcp-nodejs:latest"
    End

    It 'parses dockerfile name'
      When call get_server_field "debugger-nodejs" "source.dockerfile"
      The output should equal "Dockerfile.nodejs"
    End

    It 'parses build context'
      When call get_server_field "debugger-nodejs" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "debugger-nodejs" "environment_variables"
      The output should include "DEBUGGER_WORKSPACE"
    End

    It 'parses volumes'
      When call get_server_field "debugger-nodejs" "volumes"
      The output should include "DEBUGGER_WORKSPACE:/workspace"
    End

    It 'parses network mode'
      When call get_server_field "debugger-nodejs" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses cmd array'
      When call get_server_field "debugger-nodejs" "docker.cmd"
      The output should include "debugger_mcp"
      The output should include "serve"
    End

    It 'parses startup timeout'
      When call get_server_field "debugger-nodejs" "startup_timeout"
      The output should equal "15"
    End
  End

  Describe 'List Command'
    It 'includes debugger-nodejs in server list'
      When call cmd_list
      The output should include "debugger-nodejs"
      The output should include "Debug Adapter Protocol (DAP) server for Node.js"
      The output should include "[development]"
    End
  End
End
