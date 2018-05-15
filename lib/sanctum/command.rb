#colorize_string needs to be required first
require 'sanctum/colorize_string'
require 'sanctum/vault_client'
require 'sanctum/vault_secrets'
require 'sanctum/vault_transit'

#base needs to be required first
require 'sanctum/command/base'

require 'sanctum/command/check'
require 'sanctum/command/config'
require 'sanctum/command/create'
require 'sanctum/command/edit'
require 'sanctum/command/editor_helper'
require 'sanctum/command/paths_helper'
require 'sanctum/command/pull'
require 'sanctum/command/push'
require 'sanctum/command/view'
