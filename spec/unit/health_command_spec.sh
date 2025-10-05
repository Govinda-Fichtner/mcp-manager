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
End
