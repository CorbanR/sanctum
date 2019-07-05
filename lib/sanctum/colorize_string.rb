# frozen_string_literal: true

module Sanctum
  #:nodoc:
  module Colorizer
    def self.colorize=(flag)
      @colorize = !!flag # rubocop:disable Style/DoubleNegation
    end

    def self.colorize?
      @colorize = true if @colorize.nil?
      @colorize
    end

    def colorize(color_code, string, colorize: Colorizer.colorize?)
      if colorize
        "\e[#{color_code}m#{string}\e[0m"
      else
        string
      end
    end

    def red(string)
      colorize(31, string)
    end

    def green(string)
      colorize(32, string)
    end

    def yellow(string)
      colorize(33, string)
    end

    def blue(string)
      colorize(34, string)
    end

    def pink(string)
      colorize(35, string)
    end

    def light_blue(string)
      colorize(36, string)
    end
  end
end
