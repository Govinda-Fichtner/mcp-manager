#!/bin/bash
# Unit tests for platform detection

Describe 'Platform Detection'
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

  Describe 'detect_platform()'
    It 'detects platform in format os/arch'
      When call detect_platform
      The output should match pattern "linux/*"
      The status should equal 0
    End

    It 'includes either amd64 or arm64 architecture'
      When call detect_platform
      The output should satisfy 'grep -E "(amd64|arm64)"'
      The status should equal 0
    End
  End
End
