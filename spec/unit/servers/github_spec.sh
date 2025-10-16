#!/bin/bash
# Unit tests for GitHub MCP Server

Describe 'GitHub MCP Server'
  Include spec/spec_helper.sh

  # Use main registry file for tests
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh

  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'Registry Configuration'
    It 'parses server name'
      When call get_server_field "github" "name"
      The output should equal "GitHub MCP Server"
    End

    It 'parses server type'
      When call get_server_field "github" "server_type"
      The output should equal "api_based"
    End

    It 'parses description'
      When call get_server_field "github" "description"
      The output should equal "GitHub repository management, issues, pull requests, and code search"
    End

    It 'parses category'
      When call get_server_field "github" "category"
      The output should equal "development"
    End

    It 'parses source type as registry'
      When call get_server_field "github" "source.type"
      The output should equal "registry"
    End

    It 'parses image name'
      When call get_server_field "github" "source.image"
      The output should equal "ghcr.io/github/github-mcp-server:latest"
    End

    It 'parses environment variables'
      When call get_server_field "github" "environment_variables"
      The output should include "GITHUB_PERSONAL_ACCESS_TOKEN"
    End

    It 'parses network mode'
      When call get_server_field "github" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "github" "startup_timeout"
      The output should equal "10"
    End
  End

  Describe 'List Command'
    It 'includes github in server list'
      When call cmd_list
      The output should include "github"
      The output should include "GitHub repository management, issues, pull requests, and code search"
      The output should include "[development]"
    End
  End
End
