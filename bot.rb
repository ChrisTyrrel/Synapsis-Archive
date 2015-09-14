#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)

require 'cinch'
require 'rubygems'
require 'lib/channelmanagement'

$config = YAML.load_file("config/config.yaml")
$bots = Hash.new
$zncs = Hash.new
$threads = Array.new

$config["servers"].each do |name, server|
	bot = Cinch::Bot.new do
		configure do |c|
			c.nick = $config["bot"]["nick"]
			c.server = $config["bot"]["zncaddr"]
			c.port = $config["bot"]["zncport"]
			c.password = "Synapsis/#{name}:#{$config["bot"]["zncpass"]}"
			c.ssl.use = true
			c.plugins.plugins = [ChannelManagement, Administration]
			c.plugins.prefix = /^~/
		end
	end
	if $config["adminnet"] == name
		$adminbot = bot
	end
	$bots[name] = bot
end

$config["zncs"].each do |name, server|
	bot = Cinch::Bot.new do
		configure do |c|
			c.nick = $config["bot"]["nick"]
			c.server = server["server"]
			c.port = $config["bot"]["zncport"]
			c.password = "Synapsis/Monitor:#{$config["bot"]["zncpass"]}"
			c.ssl.use = true
			c.plugins.plugins = [ZNCEvents]
			c.plugins.prefix = /^%/
		end
	end
	$zncs[name] = bot
end


$bots.each do |key, bot|
	puts "Starting IRC connection for #{key}..."
	$threads << Thread.new { bot.start }
end

$zncs.each do |key, bot|
	puts "Starting ZNC connection for #{key}..."
	$threads << Thread.new { bot.start }
end

puts "Connected!"
sleep 5

$threads.each { |t| t.join }
