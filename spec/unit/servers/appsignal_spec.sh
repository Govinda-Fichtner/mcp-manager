#!/bin/bash
# Unit tests for AppSignal MCP server

Describe 'AppSignal MCP Server'
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
      When call get_server_field "appsignal" "name"
      The output should equal "AppSignal MCP Server"
    End

    It 'parses server type'
      When call get_server_field "appsignal" "server_type"
      The output should equal "api_based"
    End

    It 'parses description'
      When call get_server_field "appsignal" "description"
      The output should equal "AppSignal application performance monitoring and error tracking"
    End

    It 'parses category'
      When call get_server_field "appsignal" "category"
      The output should equal "monitoring"
    End

    It 'parses source type as repository'
      When call get_server_field "appsignal" "source.type"
      The output should equal "repository"
    End

    It 'parses repository URL'
      When call get_server_field "appsignal" "source.repository"
      The output should equal "https://github.com/appsignal/appsignal-mcp"
    End

    It 'parses image name'
      When call get_server_field "appsignal" "source.image"
      The output should equal "local/appsignal-mcp-server:latest"
    End

    It 'parses dockerfile path'
      When call get_server_field "appsignal" "source.dockerfile"
      The output should equal "support/docker/appsignal/Dockerfile"
    End

    It 'parses build context'
      When call get_server_field "appsignal" "source.build_context"
      The output should equal "."
    End

    It 'parses environment variables'
      When call get_server_field "appsignal" "environment_variables"
      The output should include "APPSIGNAL_API_KEY"
    End

    It 'parses network mode'
      When call get_server_field "appsignal" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "appsignal" "startup_timeout"
      The output should equal "10"
    End
  End

  Describe 'List Command'
    It 'includes appsignal in server list'
      When call cmd_list
      The output should include "appsignal"
      The output should include "AppSignal application performance monitoring and error tracking"
      The output should include "[monitoring]"
    End
  End
End
