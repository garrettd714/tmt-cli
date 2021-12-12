# frozen_string_literal: true

require 'yaml'

module Tmt
  # some comment
  class Settings
    def self.method_missing(message, *args, &block)
      config = YAML.safe_load(File.read(File.join(File.dirname(__FILE__), '../../settings.yml'))).freeze

      if config.keys.include?(message.to_s)
        config[message.to_s]
      else
        super
      end
    end

    def self.respond_to_missing?(message, include_private = false)
      config = YAML.safe_load(File.read(File.join(File.dirname(__FILE__), '../../settings.yml'))).freeze
      return true if config.keys.include?(message.to_s)

      super
    end
  end
end
