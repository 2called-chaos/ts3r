require "thread"
require "pathname"
require "yaml"
require "optparse"
require "securerandom"
require "ostruct"
begin ; require "pry" ; rescue LoadError ; end

module Ts3r
  ROOT = Pathname.new(File.expand_path("../..", __FILE__))
  BASH_ENABLED = "#{ENV["SHELL"]}".downcase["bash"]
  $:.unshift "#{ROOT}/lib"

  def self.configure *args, &block
    Thread.main[:app_config].setup(*args, &block)
  end

  def self.task name, &block
    Thread.main[:app_config].setup do |c|
      c[:tasks] ||= {}
      c[:tasks][name.to_s] = Task.new(name.to_s, &block)
    end
  end
end

require "ts3query"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"

require "banana/logger"
require "ts3r/version"
require "ts3r/helpers"
require "ts3r/task"
require "ts3r/console"
require "ts3r/application/configuration"
require "ts3r/application/dispatch"
require "ts3r/application"


if ARGV.shift == "dispatch"
  begin
    Ts3r::Application.dispatch(ENV, ARGV)
  rescue Interrupt
    puts("\n\nInterrupted")
    exit 1
  end
else
  puts("\n\nInvalid call")
  exit 1
end
