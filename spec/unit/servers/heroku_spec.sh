#!/bin/bash
# Unit tests for Heroku MCP server

Describe 'Heroku MCP Server'
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
      When call get_server_field "heroku" "name"
      The output should equal "Heroku Platform MCP Server"
    End

    It 'parses server type'
      When call get_server_field "heroku" "server_type"
      The output should equal "api_based"
    End

    It 'parses description'
      When call get_server_field "heroku" "description"
      The output should equal "Official Heroku platform management - app lifecycle, database operations, and infrastructure automation"
    End

    It 'parses category'
      When call get_server_field "heroku" "category"
      The output should equal "platform"
    End

    It 'parses source type as repository'
      When call get_server_field "heroku" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "heroku" "source.repository"
      The output should equal "https://github.com/heroku/heroku-mcp-server.git"
    End

    It 'parses image name'
      When call get_server_field "heroku" "source.image"
      The output should equal "local/heroku-mcp-server:latest"
    End

    It 'parses build context'
      When call get_server_field "heroku" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "heroku" "environment_variables"
      The output should include "HEROKU_API_KEY"
    End

    It 'parses network mode'
      When call get_server_field "heroku" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "heroku" "startup_timeout"
      The output should equal "10"
    End
  End

  Describe 'List Command'
    It 'includes heroku in server list'
      When call cmd_list
      The output should include "heroku"
      The output should include "Official Heroku platform management - app lifecycle, database operations, and infrastructure automation"
      The output should include "[platform]"
    End
  End
End
