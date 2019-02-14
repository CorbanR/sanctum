require 'gli'
require 'sanctum/command'
require 'sanctum/get_config'
require 'sanctum/version'

module Sanctum
  class CLI
    extend GLI::App

    def self.common_options(c, *opts)
      opts.map(&:to_sym).each do |opt|
        case opt
        when :config
          c.desc 'specify config file'
          c.flag :c, :config
        when :targets
          c.desc 'Comma seperated list of targets'
          c.flag :t, :targets
        when :force
          c.desc 'Force, will not ask you to confirm differences'
          c.switch :force
        else
          raise "unrecognized option #{opt.inspect}"
        end
      end
    end

    program_desc 'Simple and secure filesystem-to-Vault secrets synchronization'

    version VERSION

    subcommand_option_handling :normal
    arguments :strict

    desc 'Checks differences that exist'
    command :check do |c|
      common_options c, :targets, :config
      c.action do
        Command::Check.new(@options_hash).run
      end
    end

    desc 'Pull in secrets that already exist in Vault.'
    command :pull do |c|
      common_options c, :targets, :config, :force
      c.action do
        Command::Pull.new(@options_hash).run
      end
    end

    desc 'Synchronize secrets to Vault'
    command :push do |c|
      common_options c, :targets, :config, :force
      c.action do
        Command::Push.new(@options_hash).run
      end
    end

    desc 'Creates example config file'
    skips_pre
    command :config do |c|
      c.action do
        Command::Config.new.run
      end
    end

    desc 'Create an encrypted file'
    arg_name 'path/to/file'
    command :create do |c|
      common_options c, :config
      c.action do |_,_,args|
        Command::Create.new(@options_hash, args).run
      end
    end

    desc 'View encrypted file[s]'
    arg_name 'path/to/file'
    command :view do |c|
      common_options c, :config
      c.action do |_,_,args|
        if args.empty?
          help_now! "Please specify at least one argument"
        end
        Command::View.new(@options_hash, args).run
      end
    end

    desc 'Edit an encrypted file'
    arg_name 'path/to/file'
    command :edit do |c|
      common_options c, :config

      c.action do |_,_,args|
        Command::Edit.new(@options_hash, args).run
      end
    end

    desc 'Update secrets mount'
    command :update do |c|
      common_options c, :config, :force
      c.flag [:targets, :t], desc: 'Comma seperated list of targets', required: true
      c.action do
        Command::Update.new(@options_hash).run
      end
    end

    pre do |_,_,options,_|
      @options_hash = GetConfig::ConfigMerge.new(config_file: options[:c], targets: options[:t], force: options[:force]).final_options
      Colorizer.colorize = @options_hash[:sanctum][:color]
      true
    end

    on_error do |exception|
      true
    end

  end
end
