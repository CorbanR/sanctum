require 'gli'
require 'sanctum/command'
require 'sanctum/get_config'
require 'sanctum/version'

module Sanctum
  class CLI
    extend GLI::App

    program_desc 'Simple and secure filesystem-to-Vault secrets synchronization'

    version VERSION

    subcommand_option_handling :normal
    arguments :strict

    desc 'Checks differences that exist'
    command :check do |c|
      c.desc 'Comma seperated list of target application[s]'
      c.flag :t, :targets

      c.desc 'specify config file'
      c.flag :c, :config
      c.action do |global_options,options,args|
        Command::Check.new(@options_hash).run
      end
    end

    desc 'Pull in secrets that already exist in Vault.'
    command :pull do |c|
      c.desc 'Comma seperated list of target application[s]'
      c.flag :t, :targets

      c.desc 'specify a config file'
      c.flag :c, :config

      c.desc 'Force pull from vault (clobbering local changes)'
      c.switch :force
      c.action do |global_options,options,args|
        Command::Pull.new(@options_hash).run
      end
    end

    desc 'Synchronize secrets to Vault'
    command :push do |c|
      c.desc 'Comma seperated list of target application[s]'
      c.flag :t, :targets

      c.desc 'specify a config file'
      c.flag :c, :config

      c.desc 'Force push to vault (clobbering whats in vault)'
      c.switch :force
      c.action do |global_options,options,args|
        Command::Push.new(@options_hash).run
      end
    end

    desc 'Creates example config file'
    skips_pre
    command :config do |c|
      c.action do |global_options,options,args|
        Command::Config.new.run
      end
    end

    desc 'Create an encrypted file'
    arg_name 'path/to/file'
    command :create do |c|
      c.desc 'Comma seperated list of target application[s]'
      c.flag :t, :targets

      c.desc 'specify a config file'
      c.flag :c, :config

      c.action do |global_options,options,args|
        Command::Create.new(@options_hash, args).run
      end
    end

    desc 'View encrypted file[s]'
    arg_name 'path/to/file'
    command :view do |c|
      c.desc 'Specify a target application(required when specifying transit_key on a per app basis)'
      c.flag :t, :target

      c.desc 'specify a config file'
      c.flag :c, :config

      c.action do |global_options,options,args|
        if args.empty?
          help_now! "Please specify at least one argument"
        end
        Command::View.new(@options_hash, args).run
      end
    end

    desc 'Edit an encrypted file'
    arg_name 'path/to/file'
    command :edit do |c|
      c.desc 'Comma seperated list of target application[s]'
      c.flag :t, :targets

      c.desc 'specify a config file'
      c.flag :c, :config

      c.action do |global_options,options,args|
        Command::Edit.new(@options_hash, args).run
      end
    end

    pre do |global,command,options,args|

      @options_hash = GetConfig::ConfigMerge.new(config_file: options[:c], targets: options[:t], force: options[:force]).final_options
      Colorizer.colorize = @options_hash[:sanctum][:color]


      # Return true to proceed; false to abort and not call the
      # chosen command
      # Use skips_pre before a command to skip this block
      # on that command only
      true
    end

    post do |global,command,options,args|
      # Use skips_post before a command to skip this
    end

    on_error do |exception|

      true
    end

  end
end
