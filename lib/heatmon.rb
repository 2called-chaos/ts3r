# Heatmon is a temperature based simple monitoring solution build with Ruby.
module Heatmon
  # Enable debug messages
  $heatmon_debug = ARGV.delete("--debug")

  # The Heatmon root directory
  require "pathname"
  ROOT = Pathname.new(File.expand_path("../..", __FILE__))

  # Bootstrap if file called directly or from daemons
  BOOTSTRAP = __FILE__.end_with?($0) || __FILE__.gsub("heatmon.rb", "heatmond.rb").end_with?($0) || %w[heatmon heatmond].include?($0)

  # Bootstrap
  if BOOTSTRAP
    Bundler.require(:default, :development)
    $:.unshift "#{ROOT}/lib"
  end

  # Require core files
  Banana.require_on self, %w[version exceptions kernel_stub core_ext queue logger singleton configuration gateway app]
  include Heatmon::Logger::DSL
  include Heatmon::Singleton

  # logger shortcuts
  module_function :logger, :log, :warn, :abort, :debug, :severe

  # Run app if file is called directly
  if BOOTSTRAP
    app.dispatch(ENV, ARGV)
  end
end

