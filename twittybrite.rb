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
require 'twibot'
require 'betabrite'
require 'iconv'

# Text displayed by default
DEFAULT_TEXT = ""

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
  3.times do
    betabrite "from", "green"
    sleep 1
    betabrite sender, "green", "hold"
    sleep 3
    betabrite message + " " * 20
    sleep message.size / 10 + 4
  end
  betabrite DEFAULT_TEXT
end

class String
  # Return the ASCII string.
  def ascii
    return Iconv.conv('US-ASCII//TRANSLIT','UTF-8', self)
  end
end

# Get direct messages thanks to twibot and display them
message do |message, params|
  begin
    display message.sender.screen_name, message.to_s
  rescue
    puts $!
  end
end

betabrite DEFAULT_TEXT
