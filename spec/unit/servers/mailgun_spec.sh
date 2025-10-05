#!/bin/bash
# Unit tests for Mailgun MCP server

Describe 'Mailgun MCP Server'
  Include spec/spec_helper.sh
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh

  setup() { setup_test_env; }
  cleanup() { cleanup_test_env; }
  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'Registry Configuration'
    It 'parses server name'
      When call get_server_field "mailgun" "name"
      The output should equal "Mailgun MCP Server"
    End
    It 'parses server type'
      When call get_server_field "mailgun" "server_type"
      The output should equal "api_based"
    End
    It 'parses description'
      When call get_server_field "mailgun" "description"
      The output should equal "Mailgun email service integration for AI-orchestrated email automation workflows"
    End
    It 'parses category'
      When call get_server_field "mailgun" "category"
      The output should equal "email"
    End
    It 'parses source type'
      When call get_server_field "mailgun" "source.type"
      The output should equal "repository"
    End
    It 'parses repository'
      When call get_server_field "mailgun" "source.repository"
      The output should equal "https://github.com/mailgun/mailgun-mcp-server.git"
    End
    It 'parses environment variables'
      When call get_server_field "mailgun" "environment_variables"
      The output should include "MAILGUN_API_KEY"
      The output should include "MAILGUN_DOMAIN"
    End
  End

  Describe 'List Command'
    It 'includes mailgun in server list'
      When call cmd_list
      The output should include "mailgun"
      The output should include "[email]"
    End
  End
End
