#!/bin/bash
# Unit tests for Context7 MCP server

Describe 'Context7 MCP Server'
  Include spec/spec_helper.sh
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh

  setup() { setup_test_env; }
  cleanup() { cleanup_test_env; }
  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'Registry Configuration'
    It 'parses server name'
      When call get_server_field "context7" "name"
      The output should equal "Context7 Documentation MCP Server"
    End
    It 'parses server type'
      When call get_server_field "context7" "server_type"
      The output should equal "standalone"
    End
    It 'parses description'
      When call get_server_field "context7" "description"
      The output should equal "Context7 library documentation server - up-to-date documentation and code examples for any programming library"
    End
    It 'parses category'
      When call get_server_field "context7" "category"
      The output should equal "documentation"
    End
    It 'parses source type'
      When call get_server_field "context7" "source.type"
      The output should equal "repository"
    End
    It 'parses repository'
      When call get_server_field "context7" "source.repository"
      The output should equal "https://github.com/upstash/context7.git"
    End
  End

  Describe 'List Command'
    It 'includes context7 in server list'
      When call cmd_list
      The output should include "context7"
      The output should include "[documentation]"
    End
  End
End
