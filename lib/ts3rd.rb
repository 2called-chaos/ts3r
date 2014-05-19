# Heatmon daemon wrapper
require "fileutils"
require "daemons"
PROJECT_ROOT = File.expand_path("../..", __FILE__)

# Ensure directories
begin
  FileUtils.mkdir_p("#{PROJECT_ROOT}/log")
  FileUtils.mkdir_p("#{PROJECT_ROOT}/tmp")
rescue Errno::EPERM
  $stderr.puts "Can't create `log/' and/or `tmp/' directory. Permissons? (Errno::EPERM)"
  exit 1
end

# Run daemon
Daemons.run("#{PROJECT_ROOT}/lib/ts3r.rb dispatch",
  app_name: "ts3rd",
  dir_mode: :normal,               # use absolute path
  dir: "#{PROJECT_ROOT}/tmp",      # pid directory
  log_output: true,                # log application output
  log_dir: "#{PROJECT_ROOT}/log",  # log directory
  backtrace: true,                 # log backtrace on crash
  multiple: false,                 # allow only 1 instance
  monitor: true                    # restart app on crash
)
