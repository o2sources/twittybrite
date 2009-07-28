#!/usr/bin/env ruby
# twittybrite.rb - display direct messages sent to a twitter account 
# on a betabrite led display.
#
# Author::  Philippe Creux for O2Sources (pcreux AATT o2sources DOOT com)
# Copyright:: Copyright (c) 2009. O2Sources. All rights reserved.
#
# * Please run this script as root (or using sudo)
# * Please update the "config/bot.yml" with your details
# * The following packages are required: ruby, rubygems, libusb-dev
# * The following gems are required: twibot, betabrite, ruby-usb

require 'rubygems'
require 'usb'
require 'betabrite'
require 'twibot'
require 'iconv'

# Display text on the betabright!
# * available colors are: red, green, amber, dim_red, dim_green, brown, orange, yellow
# * available modes are: flash, hold, rotate, scroll
def betabrite (text, color = 'amber', anim = 'rotate')
  bb = BetaBrite::USB.new do |sign|
    sign.stringfile('0') do
      print string("dummy").green
    end
 
    sign.textfile do
      self.send(anim)
      print stringfile('0')
      print string(text.ascii).send(color).seven_stroke
    end
  end
  bb.write!
end

# That's the way we display twitter messages - feel free to custom it!
def display (sender, message)
  betabrite "NEW MESSAGE!", "orange", "flash"
  sleep 3
  2.times do
    betabrite "from" + " " * 5, "green"
    sleep 2
    betabrite sender, "green", "hold"
    sleep 3
    betabrite message + " " * 20
    sleep message.ascii.size / 10 + 4 # That's a hack. :)
  end
  betabrite ""
  sleep 2
end

class String
  # Return the ASCII string.
  # Looks like Ivonv does not work correctly. We use hard-coded conversions then.
  def ascii
    from = 'àâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÛÇ'
    to =   'aaeeeeeiioouuucAAAEEEEIIOUC'
    return Iconv.conv('US-ASCII//TRANSLIT','UTF-8', self.tr(from, to).gsub('&lt;', '<').gsub('&gt;', '>'))
  end
end

# Seconds to h:m
def time_to(h, m = 0)
  begin
    time_now = Time.now
    return (Time.local(time_now.year, time_now.month, time_now.day, h, m) - time_now).to_i
  rescue
    sleep 1
    retry
  end
end

# Create a new thread displaying time (HH:MM) on the betabrite every minute
def display_time_thread
  Thread.new {
    while true
      @@betamutex.synchronize {
        betabrite(Time.now.strftime('%H:%M'), "dim_green", "hold")
      }
      sleep 1
      st = 61 + time_to(Time.now.hour, Time.now.min)
      sleep st
    end
  }
end

# Get direct messages thanks to twibot and display them
message do |message, params|
  puts message.sender.screen_name
  puts message.to_s
  begin
    @@betamutex.synchronize {
      display message.sender.screen_name, message.to_s
    }
  rescue
    puts $!
  end
end

Thread.abort_on_exception = true
@@betamutex = Mutex.new
sleep 10 # let twibot starting up
display_time_thread
