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
      The output should include 'test-image:latest'
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

    It 'includes empty container_args when docker.cmd is not set'
      When call build_config_context test-server full
      The output should include '"container_args": []'
    End

    It 'includes container_args when docker.cmd is set'
      When call build_config_context test-server-with-cmd full
      The status should equal 0
      The output should include '"container_args":'
      The output should include 'node'
      The output should include 'dist/index.js'
      The output should include '--transport'
      The output should include 'stdio'
    End

    It 'handles docker.cmd as JSON array'
      When call build_config_context test-server-with-cmd full
      # JSON may be formatted with newlines, so check for array elements
      The output should include '"container_args": ['
      The output should include '"node"'
      The output should include '"stdio"'
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

  Describe 'cmd_config() with docker.cmd override'
    It 'includes docker.cmd arguments in generated config'
      When call cmd_config test-server-with-cmd --format claude-code --snippet
      The status should equal 0
      The output should include 'node'
      The output should include 'dist/index.js'
      The output should include '--transport'
      The output should include 'stdio'
    End

    It 'appends container_args after image in docker run command'
      When call cmd_config test-server-with-cmd --format claude-code --snippet
      The output should include 'test-server-cmd:latest'
      # Args should come after the image
      The output should include '"command": "docker"'
    End

    It 'works with --add-json format'
      When call cmd_config test-server-with-cmd --format claude-code --add-json
      The status should equal 0
      The output should include '"node"'
      The output should include '"dist/index.js"'
      The output should include '"--transport"'
      The output should include '"stdio"'
    End
  End
End
