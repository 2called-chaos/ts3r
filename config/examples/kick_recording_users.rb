# app   = app instance (most useful to access app.config)
# ts    = teamspeak query instance (app.connection)
# store = store for this task (local variables will last only one tick)
Ts3r.task :kick_recording_user do
  # use first virtual server (with sid 1)
  use_server(1)

  # iterate over all users and check if one is recording
  ts.clientlist.select{|c| c["client_type"] == "0" }.each do |client|
    clientinfo = ts.clientinfo(clid: client["clid"])[0]
    channelinfo = ts.channelinfo(cid: clientinfo["client_channel_group_inherited_channel_id"])[0]

    # user isn't recording ignore
    throw :return unless clientinfo["client_is_recording"] == "1"

    # ignore server admins based on client_talk_power
    throw :return if clientinfo["client_talk_power"].to_i >= 75

    # ignore in temporary channels (user channels)
    throw :return if channelinfo["channel_flag_permanent"] == "0" && channelinfo["channel_flag_semi_permanent"] == "0"

    # kick to default channel unless already there
    if channelinfo["channel_flag_default"] == "0"
      app.log "kicking #{clientinfo["client_nickname"]} due to recording"
      ts.clientkick(
        clid: client["clid"],
        reasonid: 4,
        reasonmsg: "Recording is only allowed in temporary user channels".gsub(" ", "\\s"),
      )
    end
  end
end
