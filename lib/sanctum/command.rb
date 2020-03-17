# frozen_string_literal: true

# colorize_string needs to be required first
require 'sanctum/colorize_string'
require 'sanctum/adapter/vault/client'
require 'sanctum/adapter/vault/secrets'
require 'sanctum/adapter/vault/transit'

# base needs to be required first
require 'sanctum/command/base'

require 'sanctum/command/check'
require 'sanctum/command/create'
require 'sanctum/command/edit'
require 'sanctum/command/import'
require 'sanctum/command/init'
require 'sanctum/command/pull'
require 'sanctum/command/push'
require 'sanctum/command/update'
require 'sanctum/command/view'
