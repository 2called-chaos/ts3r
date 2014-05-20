# Ts3r

A little framework to build teamspeak 3 bots.


## Requirements

- Ruby >= 1.9.3
- Git
- [bundler](http://bundler.io) gem
- TeamSpeak 3 server


## Important

You'll need to add the IP address of this bot to the TeamSpeak 3 server query_ip_whitelist.txt or the anti-spam feature will ban the bot every other minute.


## Installation

Choose and change to a directory in which you want to install the bot. You may want to run the bot under another user.

    su - teamspeak
    cd /home/teamspeak
    git clone https://github.com/2called-chaos/ts3r.git
    cd ts3r
    bundle install

You may also want to add the `bin` directory to your path:

    PATH=/home/teamspeak/ts3r/bin:$PATH
    export PATH


## Configuration

We are lacking a bit of documentation here but there are quite a few examples in the configuration directory.
For the most part this [Docu PDF of hell](http://media.teamspeak.com/ts3_literature/TeamSpeak%203%20Server%20Query%20Manual.pdf) will help you a lot.


## Usage

After editing the configuration you can start the bot with

    ts3rd start

or if you want to debug start it attached to the terminal with

    ts3r


## Contributing

1. Fork it ( http://github.com/2called-chaos/ts3r/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
