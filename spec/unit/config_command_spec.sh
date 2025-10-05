#!/bin/bash
# Unit tests for config command

Describe 'Config Command'
  Include spec/spec_helper.sh

  # Set REGISTRY_FILE before sourcing main script (it's readonly)
  export REGISTRY_FILE="$FIXTURES_DIR/sample_registry.yml"
  Include mcp_manager.sh

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'build_config_context()'
    It 'generates JSON context with output_mode'
      When call build_config_context test-server full
      The status should equal 0
      The output should include '"server_id": "test-server"'
      The output should include '"output_mode": "full"'
    End

    It 'includes image information'
      When call build_config_context test-server full
      The output should include '"image":'
      The output should include 'test/server'
    End

    It 'includes environment variables'
      When call build_config_context test-server full
      The output should include '"env_vars":'
      The output should include 'TEST_API_KEY'
    End

    It 'handles empty volumes list'
      When call build_config_context test-server full
      The output should include '"volumes": []'
    End

    It 'accepts snippet mode'
      When call build_config_context test-server snippet
      The output should include '"output_mode": "snippet"'
    End

    It 'accepts add-json mode'
      When call build_config_context test-server add-json
      The output should include '"output_mode": "add-json"'
    End
  End

  Describe 'Output modes validation'
    It 'generates different output for full mode'
      Skip "Requires full template rendering - integration test"
    End

    It 'generates different output for snippet mode'
      Skip "Requires full template rendering - integration test"
    End

    It 'generates single-line JSON for add-json mode'
      Skip "Requires full template rendering - integration test"
    End

    It 'validates --add-json only works with claude-code format'
      Skip "Requires command-line argument parsing - integration test"
    End
  End

  Describe 'cmd_config() with --add-json'
    It 'outputs single-line JSON without server name'
      When call cmd_config test-server --format claude-code --add-json
      The status should equal 0
      The output should start with '{"command":'
      The output should include '"docker"'
    End

    It 'outputs valid JSON for command substitution'
      When call cmd_config test-server --format claude-code --add-json
      # Output should be single-line JSON for: claude mcp add-json <name> $(...)
      The output should include '{"command": "docker"'
      The output should include '"args":'
    End

    It 'does not include server name in output'
      When call cmd_config test-server --format claude-code --add-json
      # Server name should NOT be in the JSON output
      The output should not start with "test-server"
    End
  End
End
