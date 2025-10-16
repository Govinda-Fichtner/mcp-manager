#!/bin/bash
# Unit tests for Filesystem MCP Server

Describe 'Filesystem MCP Server'
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
      When call get_server_field "filesystem" "name"
      The output should equal "Filesystem MCP Server"
    End

    It 'parses server type'
      When call get_server_field "filesystem" "server_type"
      The output should equal "mount_based"
    End

    It 'parses description'
      When call get_server_field "filesystem" "description"
      The output should equal "Secure file system access with directory restrictions"
    End

    It 'parses category'
      When call get_server_field "filesystem" "category"
      The output should equal "storage"
    End

    It 'parses source type as registry'
      When call get_server_field "filesystem" "source.type"
      The output should equal "registry"
    End

    It 'parses image name'
      When call get_server_field "filesystem" "source.image"
      The output should equal "mcp/filesystem:latest"
    End

    It 'parses environment variables'
      When call get_server_field "filesystem" "environment_variables"
      The output should include "ALLOWED_DIRECTORIES"
    End

    It 'parses volumes'
      When call get_server_field "filesystem" "volumes"
      The output should include "/project"
    End

    It 'parses network mode'
      When call get_server_field "filesystem" "docker.network_mode"
      The output should equal "host"
    End

    It 'parses startup timeout'
      When call get_server_field "filesystem" "startup_timeout"
      The output should equal "5"
    End
  End

  Describe 'List Command'
    It 'includes filesystem in server list'
      When call cmd_list
      The output should include "filesystem"
      The output should include "Secure file system access with directory restrictions"
      The output should include "[storage]"
    End
  End
End
