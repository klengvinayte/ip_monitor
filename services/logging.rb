# frozen_string_literal: true

# This module is used to log messages to the console.
# It is included in all classes that need to log messages.
module Logging
  def self.included(base)
    base.extend(ClassMethods)
  end

  def logger
    self.class.logger
  end

  module ClassMethods
    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
        log.datetime_format = '%Y-%m-%d %H:%M:%S'
        log.formatter = proc do |severity, datetime, _progname, msg|
          "#{datetime} [#{severity}]: #{msg}\n"
        end
      end
    end
  end
end
