#!/bin/bash
# Unit tests for registry functions

Describe 'Registry Functions'
  Include mcp_manager.sh
  Include spec/spec_helper.sh

  setup() {
    setup_test_env
    export REGISTRY_FILE="$FIXTURES_DIR/sample_registry.yml"
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'validate_registry()'
    It 'returns 0 when registry file exists and is valid'
      When call validate_registry
      The status should equal 0
    End

    It 'returns 1 when registry file does not exist'
      export REGISTRY_FILE="/nonexistent/file.yml"
      When call validate_registry
      The status should equal 1
      The stderr should include "Registry file not found"
    End
  End

  Describe 'list_servers()'
    It 'lists servers from registry'
      When call list_servers
      The output should include "test-server"
      The status should equal 0
    End
  End

  Describe 'server_exists()'
    It 'returns 0 when server exists'
      When call server_exists test-server
      The status should equal 0
    End

    It 'returns 1 when server does not exist'
      When call server_exists nonexistent-server
      The status should equal 1
    End
  End

  Describe 'get_server_field()'
    It 'retrieves server name field'
      When call get_server_field test-server name
      The output should equal "Test MCP Server"
      The status should equal 0
    End

    It 'retrieves server description field'
      When call get_server_field test-server description
      The output should include "test server"
      The status should equal 0
    End

    It 'retrieves nested source.type field'
      When call get_server_field test-server source.type
      The output should equal "registry"
      The status should equal 0
    End
  End
End
