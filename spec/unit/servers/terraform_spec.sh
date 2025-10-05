#!/bin/bash
# Unit tests for Terraform MCP server

Describe 'Terraform MCP Server'
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
      When call get_server_field "terraform" "name"
      The output should equal "Terraform MCP Server"
    End

    It 'parses server type'
      When call get_server_field "terraform" "server_type"
      The output should equal "standalone"
    End

    It 'parses description'
      When call get_server_field "terraform" "description"
      The output should equal "Terraform Registry API access - provider documentation, module discovery, and registry information"
    End

    It 'parses category'
      When call get_server_field "terraform" "category"
      The output should equal "infrastructure"
    End

    It 'parses source type as registry'
      When call get_server_field "terraform" "source.type"
      The output should equal "registry"
    End

    It 'parses image name'
      When call get_server_field "terraform" "source.image"
      The output should equal "hashicorp/terraform-mcp-server:latest"
    End

    It 'parses network mode'
      When call get_server_field "terraform" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "terraform" "startup_timeout"
      The output should equal "10"
    End
  End

  Describe 'List Command'
    It 'includes terraform in server list'
      When call cmd_list
      The output should include "terraform"
      The output should include "Terraform Registry API access - provider documentation, module discovery, and registry information"
      The output should include "[infrastructure]"
    End
  End
End
