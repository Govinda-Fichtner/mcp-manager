#!/bin/bash
# Unit tests for Docker helper functions

Describe 'Docker Helper Functions'
  Include mcp_manager.sh
  Include spec/spec_helper.sh

  setup() {
    setup_test_env
    mock_docker
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'docker_image_exists()'
    It 'returns 0 when mocked image exists'
      # Mock returns mcp/github:latest
      When call docker_image_exists "mcp/github:latest"
      The status should equal 0
    End

    It 'returns 1 when image does not exist'
      When call docker_image_exists "nonexistent/image:latest"
      The status should equal 1
    End
  End

  Describe 'redact_value()'
    It 'redacts sensitive values'
      When call redact_value "ghp_secret_token_12345"
      The output should equal "ghp_****"
      The status should equal 0
    End

    It 'shows (not set) for empty values'
      When call redact_value ""
      The output should equal "(not set)"
      The status should equal 0
    End
  End
End
