# - heartbeat listener
# - report generator
# - web frontend
# - query listener

# Heatmon main configuration
#
# Thread overview:
#   Main
#     - 1 x database handler
#     - <queue> x Schedule
#       - <monitors> x worker threads
#     - <pool> x threads per activated notification
Heatmon.configure do
  # Configure heatmon's behaviour of calling home.
  group :calling_home do
    # Set this to false if you don't want heatmon to check for updates when you run `heatmon --version`.
    set :check_version, false

    # You may want to opt-out here but please consider that the statistics really help us improving heatmon.
    # Set this to false if you don't want to deliver statistical data to the developers of heatmon.
    # You can further define what you want to share in the next setting.
    #
    # Reports are getting send everytime the heatmon daemon stops monitoring and after each 750 hours
    # of runtime (about a month). No report is being sent if heatmon runs less than 15 minutes
    # (e.g. if you're debugging or testing heatmon).
    #
    # There is no preview but you can find the last report sent in log/report.txt.
    set :report_metrics, true

    # If you've enabled reporting you can specify which information you want to share with us.
    group :metrics do
      # What you see when you call `heatmon --statistics`
      set :statistics, true

      # Heatmon environment (heatmon version & ruby version)
      set :heatenv, true

      # Runtime (how long did heatmon monitor?)
      set :runtime, true

      # Monitoring statistics
      #   - how many tasks
      #     - were executed in total
      #     - have succeeded (positive test result)
      #     - have failed (negative test result)
      #     - have raised an exception
      #     - got delayed (can't keep up)
      #   - how many incidents have been filed
      set :endstats, true
    end
  end

  # Configuration parsing behaviour
  group :configuration do
    # Abort on invalid configuration if set to true, otherwise it just warns and continues.
    # This, however, does not apply to this main configuration file.
    set :abort_on_error, true

    # Config file is ignored when block returns true.
    set :ignore_file, ->(file) { File.basename(file).start_with?("_") }
  end

  # Configure monitoring behaviour
  #
  # @note For each queue you will get an additional Scheduler thread.
  group :monitoring do
    # Amount of queues to hold your checks. If you have a lot of checks
    # one queue will slow down the process due to the synchronized acccess.
    # Tasks will be randomly assigned to one queue.
    #
    # You'll have to find the best balance between queues and threads per queue.
    set :queues, 2

    # Thread pool size for executing monitor checks (per queue!).
    set :monitors, 25
  end

  # Configure available notification methods and their behaviour
  group :notifications do
    group :email do
      set :enabled, true

      # the following values can be overriden for groups or resources
      set :from, "heatmon@localhost"

      # Thread pool size for sending emails
      set :pool, 2
    end

    group :xmpp do # not implemented
      set :enabled, false
    end

    group :sms do # not implemented
      set :enabled, false
    end
  end

  # configure storage where incidents and resource stati will be saved to
  group :storage do
    set :provider, :mysql2
  end
end
