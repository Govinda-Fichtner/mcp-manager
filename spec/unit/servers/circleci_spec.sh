#!/bin/bash
# Unit tests for CircleCI MCP server

Describe 'CircleCI MCP Server'
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
      When call get_server_field "circleci" "name"
      The output should equal "CircleCI MCP Server"
    End

    It 'parses server type'
      When call get_server_field "circleci" "server_type"
      The output should equal "api_based"
    End

    It 'parses description'
      When call get_server_field "circleci" "description"
      The output should equal "CircleCI pipeline monitoring and management"
    End

    It 'parses category'
      When call get_server_field "circleci" "category"
      The output should equal "cicd"
    End

    It 'parses source type as repository'
      When call get_server_field "circleci" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "circleci" "source.repository"
      The output should equal "https://github.com/CircleCI-Public/mcp-server-circleci.git"
    End

    It 'parses image name'
      When call get_server_field "circleci" "source.image"
      The output should equal "local/mcp-server-circleci:latest"
    End

    It 'parses build context'
      When call get_server_field "circleci" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "circleci" "environment_variables"
      The output should include "CIRCLECI_TOKEN"
    End

    It 'parses network mode'
      When call get_server_field "circleci" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "circleci" "startup_timeout"
      The output should equal "10"
    End
  End

  Describe 'List Command'
    It 'includes circleci in server list'
      When call cmd_list
      The output should include "circleci"
      The output should include "CircleCI pipeline monitoring and management"
      The output should include "[cicd]"
    End
  End
End
