#!/bin/bash
# Unit tests for info command

Describe 'Info Command'
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

  Describe 'cmd_info()'
    It 'shows server information from registry'
      When call cmd_info test-server
      The output should include "Test MCP Server"
      The output should include "Server: test-server"
      The status should equal 0
    End

    It 'shows Docker image status'
      When call cmd_info test-server
      The output should include "Registry Image"
      The status should equal 0
    End

    It 'shows environment variables'
      When call cmd_info test-server
      The output should include "Environment Variables"
      The status should equal 0
    End

    It 'fails gracefully for non-existent server'
      When call cmd_info nonexistent-server
      The status should equal 1
      The stderr should include "not found"
    End
  End
End
