# Heatmon daemon wrapper
require "fileutils"
require "daemons"
HEATMON_ROOT = File.expand_path("../..", __FILE__)

# Ensure directories
begin
  FileUtils.mkdir_p("#{HEATMON_ROOT}/log")
  FileUtils.mkdir_p("#{HEATMON_ROOT}/tmp")
rescue Errno::EPERM
  $stderr.puts "Can't create `log/' and/or `tmp/' directory. Permissons? (Errno::EPERM)"
  exit 1
end

# Run daemon
Daemons.run("#{HEATMON_ROOT}/lib/heatmon.rb",
  app_name: "heatmond",
  dir_mode: :normal,               # use absolute path
  dir: "#{HEATMON_ROOT}/tmp",      # pid directory
  log_output: true,                # log application output
  log_dir: "#{HEATMON_ROOT}/log",  # log directory
  backtrace: true,                 # log backtrace on crash
  multiple: false,                 # allow only 1 instance
  monitor: true                    # restart app on crash
)
