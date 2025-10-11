#!/bin/bash
# Unit tests for health command

Describe 'Health Command'
  Include spec/spec_helper.sh

  # Set REGISTRY_FILE before sourcing main script (it's readonly)
  export REGISTRY_FILE="$FIXTURES_DIR/sample_registry.yml"
  Include mcp_manager.sh

  setup() {
    setup_test_env
    mock_docker
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'cmd_health()'
    It 'checks Docker daemon accessibility'
      # Mock docker info returns 0
      When call cmd_health test-server
      The output should include "Docker daemon accessible"
    End

    It 'returns exit code 0 for healthy server with existing image'
      When call cmd_health test-server
      The status should equal 0
      The output should include "READY"
    End

    It 'returns error for non-existent server'
      When call cmd_health nonexistent-server
      The status should equal 1
      The stderr should include "not found"
    End
  End

  Describe 'test_mcp_protocol()'
    It 'calls function with correct parameters'
      When call test_mcp_protocol "test-server" "test-image:latest"
      The status should equal 0
      The stderr should include "MCP protocol"
      The output should include "abc123def456789"  # Container ID
    End
  End

  Describe 'test_mcp_resources()'
    It 'calls function with container ID'
      When call test_mcp_resources "container-id"
      The status should equal 0
      The output should include "resources"
    End
  End

  Describe 'test_mcp_tools()'
    It 'calls function with container ID'
      When call test_mcp_tools "container-id"
      The status should equal 0
      The output should include "tools"
    End
  End
End
