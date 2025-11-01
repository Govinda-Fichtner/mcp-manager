#!/bin/bash
# Integration tests for image name alignment between setup and config

Describe 'Image Name Alignment'
  Include spec/spec_helper.sh

  # Set REGISTRY_FILE before sourcing main script (it's readonly)
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
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

  Describe 'Repository-based servers with explicit source.image'
    It 'obsidian: registry specifies correct image'
      When call get_server_field obsidian "source.image"
      The output should equal "local/obsidian-mcp-server:latest"
    End

    It 'obsidian: config uses registry image'
      When call build_config_context obsidian full
      The output should include '"image": "local/obsidian-mcp-server:latest"'
    End

    It 'playwright: registry specifies correct image'
      When call get_server_field playwright "source.image"
      The output should equal "local/playwright-mcp-server:latest"
    End

    It 'playwright: config uses registry image'
      When call build_config_context playwright full
      The output should include '"image": "local/playwright-mcp-server:latest"'
    End

    It 'context7: registry specifies correct image'
      When call get_server_field context7 "source.image"
      The output should equal "local/context7-mcp:latest"
    End

    It 'context7: config uses registry image'
      When call build_config_context context7 full
      The output should include '"image": "local/context7-mcp:latest"'
    End
  End

  Describe 'All repository servers have explicit image names'
    It 'circleci has explicit image name'
      When call get_server_field circleci "source.image"
      The output should equal "local/mcp-server-circleci:latest"
    End

    It 'circleci config uses explicit image'
      When call build_config_context circleci full
      The output should include '"image": "local/mcp-server-circleci:latest"'
    End
  End

  Describe 'Generated config uses correct image name'
    It 'obsidian config snippet contains correct image'
      When call cmd_config obsidian --format claude-code --snippet
      The status should equal 0
      The output should include 'local/obsidian-mcp-server:latest'
      The output should not include 'mcp-obsidian:latest'
    End

    It 'playwright config snippet contains correct image'
      When call cmd_config playwright --format claude-code --snippet
      The status should equal 0
      The output should include 'local/playwright-mcp-server:latest'
      The output should not include 'mcp-playwright:latest'
    End

    It 'context7 config snippet contains correct image'
      When call cmd_config context7 --format claude-code --snippet
      The status should equal 0
      The output should include 'local/context7-mcp:latest'
      The output should not include 'mcp-context7:latest'
    End

    It 'obsidian --add-json contains correct image'
      When call cmd_config obsidian --add-json
      The output should include 'local/obsidian-mcp-server:latest'
    End

    It 'playwright --add-json contains correct image'
      When call cmd_config playwright --add-json
      The output should include 'local/playwright-mcp-server:latest'
    End

    It 'context7 --add-json contains correct image'
      When call cmd_config context7 --add-json
      The output should include 'local/context7-mcp:latest'
    End
  End
End
