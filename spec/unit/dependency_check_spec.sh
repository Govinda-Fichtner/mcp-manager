#!/bin/bash
# Unit tests for dependency checking

Describe 'Dependency Checking'
  Include mcp_manager.sh
  Include spec/spec_helper.sh

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'check_dependency()'
    It 'returns 0 when command exists'
      When call check_dependency bash
      The status should equal 0
    End

    It 'returns 1 when command does not exist'
      When call check_dependency nonexistent_command_xyz
      The status should equal 1
    End
  End

  Describe 'get_install_instructions()'
    It 'provides instructions for docker'
      When call get_install_instructions docker
      The output should include "Install Docker"
      The status should equal 0
    End

    It 'provides instructions for yq'
      When call get_install_instructions yq
      The output should include "Install yq"
      The status should equal 0
    End
  End
End
