#!/usr/bin/env ruby
#####
# Copyright (C) 2005-2006 Murray Miron
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#	Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
#	Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
#	Neither the name of the organization nor the names of its contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#####

$version = '4.0.19'

if ARGV.any? { |arg| (arg == '-h') or (arg == '--help') }
	puts 'Usage:  lich [OPTION]'
	puts ''
	puts 'Options are:'
	puts '  -h, --help          Display this list.'
	puts '  -V, --version       Display the program version number and credits.'
	puts ''
	puts '  -d, --directory     Set the main Lich program directory.'
	puts '      --script-dir    Set the directoy where Lich looks for scripts.'
	puts '      --data-dir      Set the directory where Lich will store script data.'
	puts '      --temp-dir      Set the directory where Lich will store temporary files.'
	puts ''
	puts '  -w, --wizard        Run in Wizard mode (default)'
	puts '  -s, --stormfront    Run in StormFront mode.'
	puts ''
	puts '      --gemstone      Connect to the Gemstone IV Prime server (default).'
	puts '      --dragonrealms  Connect to the DragonRealms server.'
	puts '      --platinum      Connect to the Gemstone IV/DragonRealms Platinum server.'
	puts '  -g, --game          Set the IP address and port of the game.  See example below.'
	puts ''
#	puts '      --bare          Perform no data-scanning, just pass all game lines directly to scripts.  For maximizing efficiency w/ non-Simu MUDs.'
#	puts '  -c, --compressed    Do compression/decompression of the I/O data using Zlib (this is for MCCP, Mud Client Compression Protocol).'
#	puts '      --debug         Mainly of use in Windows; redirects the program\'s STDERR & STDOUT to the \'/lich_err.txt\' file.'
	puts '      --install       Edits the Windows/WINE registry so that Lich is started when logging in using the website or SGE.'
	puts '      --uninstall     Removes Lich from the registry.'
#	puts ''
#	puts '      --test'
#	puts '      --stderr'
	puts ''
	puts 'The majority of Lich\'s built-in functionality was designed and implemented with Simutronics MUDs in mind (primarily Gemstone IV): as such, many options/features provided by Lich may not be applicable when it is used with a non-Simutronics MUD.  In nearly every aspect of the program, users who are not playing a Simutronics game should be aware that if the description of a feature/option does not sound applicable and/or compatible with the current game, it should be assumed that the feature/option is not.  This particularly applies to in-script methods (commands) that depend heavily on the data received from the game conforming to specific patterns (for instance, it\'s extremely unlikely Lich will know how much "health" your character has left in a non-Simutronics game, and so the "health" script command will most likely return a value of 0).'
	puts ''
	puts 'The level of increase in efficiency when Lich is run in "bare-bones mode" (i.e. started with the --bare argument) depends on the data stream received from a given game, but on average results in a moderate improvement and it\'s recommended that Lich be run this way for any game that does not send "status information" in a format consistent with Simutronics\' GSL or XML encoding schemas.'
	puts ''
	puts ''
	puts 'Examples:'
	puts '  lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir \'/usr/bin/lich/\' as the program\'s home)'
	puts '  lich -g gs3.simutronics.net:4000   (run Lich using the IP address \'gs3.simutronics.net\' and the port number \'4000\')'
	puts '  lich --script-dir /mydir/scripts   (run Lich with its script directory set to \'/mydir/scripts\')'
	puts '  lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to \'skotos.net:5555\')'
	puts ''
	exit
end

if ARGV.any? { |arg| (arg == '-v') or (arg == '--version') }
	puts 'The Lich, version #{$version}'
	puts ' (an implementation of the Ruby interpreter by Yukihiro Matsumoto designed to be a \'script engine\' for text-based MUDs)'
	puts ''
	puts '- The Lich program and all material collectively referred to as "The Lich project" is copyright (C) 2005-2006 Murray Miron.'
	puts '- The Gemstone IV and DragonRealms games are copyright (C) Simutronics Corporation.'
	puts '- The Wizard front-end and the StormFront front-end are also copyrighted by the Simutronics Corporation.'
	puts '- Ruby is (C) Yukihiro \'Matz\' Matsumoto.'
	puts '- Inno Setup Compiler 5 is (C) 1997-2005 Jordan Russell (used for the Windows installation package).'
	puts ''
	puts 'Thanks to all those who\'ve reported bugs and helped me track down problems on both Windows and Linux.'
	exit
end

ARGV.delete_if { |arg| arg =~ /launcher\.exe/i }

if arg = ARGV.find { |a| (a == '-d') or (a == '--directory') }
	i = ARGV.index(arg)
	ARGV.delete_at(i)
	$lich_dir = ARGV[i]
	ARGV.delete_at(i)
	unless $lich_dir and File.exists?($lich_dir)
		$stdout.puts "warning: given Lich directory does not exist: #{$lich_dir}" rescue()
		$lich_dir = nil
	end
end
unless $lich_dir
	Dir.chdir(File.dirname($PROGRAM_NAME))
	$lich_dir = Dir.pwd
end

$lich_dir = $lich_dir.tr('\\', '/')
$lich_dir += '/' unless $lich_dir[-1..-1] == '/'
Dir.chdir($lich_dir)

if arg = ARGV.find { |a| a == '--script-dir' }
	i = ARGV.index(arg)
	ARGV.delete_at(i)
	$script_dir = ARGV[i]
	ARGV.delete_at(i)
	if $script_dir and File.exists?($script_dir)
		$script_dir = $script_dir.tr('\\', '/')
		$script_dir += '/' unless $script_dir[-1..-1] == '/'
	else
		$stdout.puts "warning: given script directory does not exist: #{$script_dir}" rescue()
		$script_dir = nil
	end
end
unless $script_dir
	$script_dir = "#{$lich_dir}scripts/"
	unless File.exists?($script_dir)
		$stdout.puts "info: creating directory: #{$script_dir}" rescue()
		Dir.mkdir($script_dir)
	end
end

if arg = ARGV.find { |a| a == '--data-dir' }
	i = ARGV.index(arg)
	ARGV.delete_at(i)
	$data_dir = ARGV[i]
	ARGV.delete_at(i)
	if $data_dir and File.exists?($data_dir)
		$data_dir = $data_dir.tr('\\', '/')
		$data_dir += '/' unless $data_dir[-1..-1] == '/'
	else
		$stdout.puts "warning: given data directory does not exist: #{$data_dir}" rescue()
		$data_dir = nil
	end
end
unless $data_dir
	$data_dir = "#{$lich_dir}data/"
	unless File.exists?($data_dir)
		$stdout.puts "info: creating directory: #{$data_dir}" rescue()
		Dir.mkdir($data_dir)
	end
end

if arg = ARGV.find { |a| a == '--temp-dir' }
	i = ARGV.index(arg)
	ARGV.delete_at(i)
	$temp_dir = ARGV[i]
	ARGV.delete_at(i)
	if $temp_dir and File.exists?($temp_dir)
		$temp_dir = $temp_dir.tr('\\', '/')
		$temp_dir += '/' unless $temp_dir[-1..-1] == '/'
	else
		$stdout.puts "warning: given temp directory does not exist: #{$temp_dir}" rescue()
		$temp_dir = nil
	end
end
unless $temp_dir
	$temp_dir = "#{$lich_dir}temp/"
	unless File.exists?($temp_dir)
		$stdout.puts "info: creating directory: #{$temp_dir}" rescue()
		Dir.mkdir($temp_dir)
	end
end

if arg = ARGV.find { |a| a == '--hosts-dir' }
	i = ARGV.index(arg)
	ARGV.delete_at(i)
	$hosts_dir = ARGV[i]
	ARGV.delete_at(i)
	if $hosts_dir and File.exists?($hosts_dir)
		$hosts_dir = $hosts_dir.tr('\\', '/')
		$hosts_dir += '/' unless $hosts_dir[-1..-1] == '/'
	else
		$stdout.puts "warning: given hosts directory does not exist: #{$hosts_dir}" rescue()
		$hosts_dir = nil
	end
else
	$hosts_dir = nil
end

num = Time.now.to_i
debug_filename = "#{$temp_dir}debug-#{num}.txt"
debug_filename = "#{$temp_dir}debug-#{num+=1}.txt" while File.exists?(debug_filename)
$stderr = File.open(debug_filename, 'w')

$stderr.puts "info: #{Time.now}"
$stderr.puts "info: $lich_dir: #{$lich_dir}"
$stderr.puts "info: $script_dir: #{$script_dir}"
$stderr.puts "info: $data_dir: #{$data_dir}"
$stderr.puts "info: $temp_dir: #{$temp_dir}"

#
# delete cache and debug files that are more than 24 hours old
#
Dir.entries($lich_dir).delete_if { |fn| (fn == '.') or (fn == '..') }.each { |filename|
	if filename =~ /^cache-([0-9]+).txt$/
		if $1.to_i + 86400 < Time.now.to_i
			File.delete($lich_dir + filename) rescue()
		end
	end
}
Dir.entries($temp_dir).delete_if { |fn| (fn == '.') or (fn == '..') }.each { |filename|
	if filename =~ /^(?:cache|debug)-([0-9]+).txt$/
		if $1.to_i + 86400 < Time.now.to_i
			File.delete($temp_dir + filename) rescue()
		end
	end
}

require 'time'
require 'socket'
include Socket::Constants
require 'rexml/document'
require 'rexml/streamlistener'
include REXML
require 'zlib'
require 'stringio'
require 'drb'
require 'resolv'
begin
	require 'win32/registry'
	HAVE_REGISTRY = true
	$stderr.puts "info: HAVE_REGISTRY: true"
rescue LoadError
	HAVE_REGISTRY = false
	if RUBY_PLATFORM =~ /win|mingw/i
		$stdout.puts "warning: failed to load win32/registry: #{$!}" rescue()
		$stderr.puts "warning: failed to load win32/registry: #{$!}"
	end
rescue
	HAVE_REGISTRY = false
	if RUBY_PLATFORM =~ /win|mingw/i
		$stdout.puts "warning: failed to load win32/registry: #{$!}" rescue()
		$stderr.puts "warning: failed to load win32/registry: #{$!}"
	end
end
begin
	require 'gtk2'
	require 'monitor'
	module Gtk
		GTK_PENDING_BLOCKS = []
		GTK_PENDING_BLOCKS_LOCK = Monitor.new
	
		def Gtk.queue &block
			GTK_PENDING_BLOCKS_LOCK.synchronize do
				GTK_PENDING_BLOCKS << block
			end
		end
	
		def Gtk.main_with_queue timeout
			Gtk.timeout_add timeout do
				GTK_PENDING_BLOCKS_LOCK.synchronize do
					for block in GTK_PENDING_BLOCKS
						begin
							block.call
						rescue
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue SyntaxError
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue SystemExit
							nil
						rescue SecurityError
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue ThreadError
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue Exception
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue ScriptError
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue LoadError
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue NoMemoryError
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						rescue
							$stdout.puts "error in Gtk.queue: #{$!}" rescue()
							$stderr.puts "error in Gtk.queue: #{$!}"
							$stderr.puts $!.backtrace
							$stderr.flush
						end
					end
					GTK_PENDING_BLOCKS.clear
				end
				true
			end
			Gtk.main
		end
	end
	# fixme: $gtk and $lich are depreciated in version 4.0.0, remove sooner or later
	class BeBackwardCompatible1
		def do(what)
			Gtk.queue { eval(what) }
		end
	end
	$gtk = BeBackwardCompatible1.new
	class BeBackwardCompatible2
		def do(what)
			eval(what)
		end
	end
	$lich = BeBackwardCompatible2.new
	HAVE_GTK = true
	$stderr.puts "info: HAVE_GTK: true"
rescue LoadError
	HAVE_GTK = false
	$stdout.puts "warning: failed to load GTK bindings: #{$!}" rescue()
	$stderr.puts "warning: failed to load GTK bindings: #{$!}"
rescue
	HAVE_GTK = false
	$stdout.puts "warning: failed to load GTK bindings: #{$!}" rescue()
	$stderr.puts "warning: failed to load GTK bindings: #{$!}"
end

# fixme: society.lic and sigils.lic not working in v4?
# fixme: not closing sometimes.
# fixme: warlock
# fixme: terminal mode
# fixme: signs3 uses Script.self.io
# fixme: maybe add script dir to load path

# at_exit { Process.waitall }

$room_count = 0

JUMP = Exception.exception('JUMP')
JUMP_ERROR = Exception.exception('JUMP_ERROR')

DIRMAP = {
	'out' => 'K',
	'ne' => 'B',
	'se' => 'D',
	'sw' => 'F',
	'nw' => 'H',
	'up' => 'I',
	'down' => 'J',
	'n' => 'A',
	'e' => 'C',
	's' => 'E',
	'w' => 'G',
}
SHORTDIR = {
	'out' => 'out',
	'northeast' => 'ne',
	'southeast' => 'se',
	'southwest' => 'sw',
	'northwest' => 'nw',
	'up' => 'up',
	'down' => 'down',
	'north' => 'n',
	'east' => 'e',
	'south' => 's',
	'west' => 'w',
}
LONGDIR = {
	'out' => 'out',
	'ne' => 'northeast',
	'se' => 'southeast',
	'sw' => 'southwest',
	'nw' => 'northwest',
	'up' => 'up',
	'down' => 'down',
	'n' => 'north',
	'e' => 'east',
	's' => 'south',
	'w' => 'west',
}
MINDMAP = {
	'clear as a bell' => 'A',
	'fresh and clear' => 'B',
	'clear' => 'C',
	'muddled' => 'D',
	'becoming numbed' => 'E',
	'numbed' => 'F',
	'must rest' => 'G',
	'saturated' => 'H',
}
ICONMAP = {
	'IconKNEELING' => 'GH',
	'IconPRONE' => 'G',
	'IconSITTING' => 'H',
	'IconSTANDING' => 'T',
	'IconSTUNNED' => 'I',
	'IconHIDDEN' => 'N',
	'IconINVISIBLE' => 'D',
	'IconDEAD' => 'B',
	'IconWEBBED' => 'C',
	'IconJOINED' => 'P',
	'IconBLEEDING' => 'O',
}

class NilClass
	def dup
		nil
	end
	def method_missing(*args)
		nil
	end
	def split(*val)
		Array.new
	end
	def to_s
		""
	end
	def strip
		""
	end
	def +(val)
		val
	end
	def closed?
		true
	end
end

class Array
	def method_missing(*usersave)
		self
	end
end

class LimitedArray < Array
	attr_accessor :max_size
	def initialize(size=0, obj=nil)
		@max_size = 200
		super
	end
	def push(line)
		self.shift while self.length >= @max_size
		super
	end
	def shove(line)
		push(line)
	end
end

# fixme: causes slowdown on Windows (maybe)
class CachedArray < Array
	attr_accessor :min_size, :max_size
	def initialize(size=0, obj=nil)
		@min_size = 200
		@max_size = 250
		num = Time.now.to_i-1
		@filename = "#{$temp_dir}cache-#{num}.txt"
		@filename = "#{$temp_dir}cache-#{num+=1}.txt" while File.exists?(@filename)
		File.open(@filename, 'w') { |f| f.write '' }
		super
	end
	def push(line)
		if self.length >= @max_size
			file = File.open(@filename, 'a')
			file.puts(self.shift) while (self.length >= @min_size)
			file.close
		end
		super
	end
	def history
		file = File.open(@filename)
		h = file.readlines
		file.close
		return h
	end
end

module StringFormatting
	def as_time
		sprintf("%d:%02d:%02d", (self / 60).truncate, self.truncate % 60, ((self % 1) * 60).truncate)
	end
end

class Numeric
	include StringFormatting
end

class TrueClass
	def method_missing(*usersave)
		true
	end
end

class FalseClass
	def method_missing(*usersave)
		nil
	end
end

class String
	def method_missing(*usersave)
		""
	end
	def silent
		false
	end
	def to_s
		self.dup
	end
end

class XMLParser
	attr_reader :mana, :max_mana, :health, :max_health, :spirit, :max_spirit, :stamina, :max_stamina, :stance_text, :stance_value, :mind_text, :mind_value, :prepared_spell, :encumbrance_text, :encumbrance_full_text, :encumbrance_value, :indicator, :injuries, :injury_mode, :room_count, :room_title, :room_description, :room_exits, :room_exits_string, :familiar_room_title, :familiar_room_description, :familiar_room_exits, :spellfront, :bounty_task, :injury_mode, :server_time, :server_time_offset, :roundtime_end, :cast_roundtime_end, :last_pulse, :next_level_value, :next_level_text, :society_task, :stow_container_id, :name, :in_stream
	include StreamListener

	def initialize
		@bold = false
		@active_tags = Array.new
		@active_ids = Array.new
		@current_stream = String.new
		@current_style = String.new
		@stow_container_id = nil
		@obj_exist = nil
		@obj_noun = nil
		@in_stream = false
		@player_status = nil
		@fam_mode = String.new
		@room_window_disabled = false
		@wound_gsl = String.new
		@scar_gsl = String.new
		@send_fake_tags = false
		#@prompt = String.new
		@nerve_tracker_num = 0
		@nerve_tracker_active = 'no'
		@server_time = Time.now.to_i
		@server_time_offset = 0
		@roundtime_end = 0
		@cast_roundtime_end = 0
		@last_pulse = Time.now.to_i
		@next_level_value = 0
		@next_level_text = String.new

		@room_count = 0
		@room_title = String.new
		@room_description = String.new
		@room_exits = Array.new
		@room_exits_string = String.new

		@familiar_room_title = String.new
		@familiar_room_description = String.new
		@familiar_room_exits = Array.new

		@spellfront = Array.new
		@bounty_task = String.new
		@society_task = String.new

		@name = String.new
		@mana = 0
		@max_mana = 0
		@health = 0
		@max_health = 0
		@spirit = 0
		@max_spirit = 0
		@stamina = 0
		@max_stamina = 0
		@stance_text = String.new
		@stance_value = 0
		@mind_text = String.new
		@mind_value = 0
		@prepared_spell = 'None'
		@encumbrance_text = String.new
		@encumbrance_full_text = String.new
		@encumbrance_value = 0
		@indicator = Hash.new
		@injuries = {'back' => {'scar' => 0, 'wound' => 0}, 'leftHand' => {'scar' => 0, 'wound' => 0}, 'rightHand' => {'scar' => 0, 'wound' => 0}, 'head' => {'scar' => 0, 'wound' => 0}, 'rightArm' => {'scar' => 0, 'wound' => 0}, 'abdomen' => {'scar' => 0, 'wound' => 0}, 'leftEye' => {'scar' => 0, 'wound' => 0}, 'leftArm' => {'scar' => 0, 'wound' => 0}, 'chest' => {'scar' => 0, 'wound' => 0}, 'leftFoot' => {'scar' => 0, 'wound' => 0}, 'rightFoot' => {'scar' => 0, 'wound' => 0}, 'rightLeg' => {'scar' => 0, 'wound' => 0}, 'neck' => {'scar' => 0, 'wound' => 0}, 'leftLeg' => {'scar' => 0, 'wound' => 0}, 'nsys' => {'scar' => 0, 'wound' => 0}, 'rightEye' => {'scar' => 0, 'wound' => 0}}
		@injury_mode = 0
	end

	def reset
		@active_tags = Array.new
		@active_ids = Array.new
		@current_stream = String.new
		@current_style = String.new
	end

	def make_wound_gsl
		@wound_gsl = sprintf("0b0%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b",@injuries['nsys']['wound'],@injuries['leftEye']['wound'],@injuries['rightEye']['wound'],@injuries['back']['wound'],@injuries['abdomen']['wound'],@injuries['chest']['wound'],@injuries['leftHand']['wound'],@injuries['rightHand']['wound'],@injuries['leftLeg']['wound'],@injuries['rightLeg']['wound'],@injuries['leftArm']['wound'],@injuries['rightArm']['wound'],@injuries['neck']['wound'],@injuries['head']['wound'])
	end
	
	def make_scar_gsl
		@scar_gsl = sprintf("0b0%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b",@injuries['nsys']['scar'],@injuries['leftEye']['scar'],@injuries['rightEye']['scar'],@injuries['back']['scar'],@injuries['abdomen']['scar'],@injuries['chest']['scar'],@injuries['leftHand']['scar'],@injuries['rightHand']['scar'],@injuries['leftLeg']['scar'],@injuries['rightLeg']['scar'],@injuries['leftArm']['scar'],@injuries['rightArm']['scar'],@injuries['neck']['scar'],@injuries['head']['scar'])
	end
	
	def tag_start(name, attributes)
		begin
			@active_tags.push(name)
			@active_ids.push(attributes['id'].to_s)
			if name == 'pushStream'
				@in_stream = true
				@current_stream = attributes['id'].to_s
				GameObj.clear_inv if attributes['id'].to_s == 'inv'
			elsif name == 'popStream'
				@in_stream = false
				if attributes['id'] == 'room'
					@room_count += 1
					$room_count += 1 
				elsif attributes['id'] == 'bounty'
					@bounty_task.strip!
				end
				@current_stream = String.new
			elsif name == 'pushBold'
				@bold = true
			elsif name == 'popBold'
				@bold = false
			elsif name == 'style'
				@current_style = attributes['id']
			elsif name == 'prompt'
				@server_time = attributes['time'].to_i
				@server_time_offset = (Time.now.to_i - @server_time)
				$_CLIENT_.puts "\034GSq#{sprintf('%010d', @server_time)}\r\n" if @send_fake_tags
			elsif (name == 'compDef') or (name == 'component')
				if attributes['id'] == 'room objs'
					GameObj.clear_loot
					GameObj.clear_npcs
				elsif attributes['id'] == 'room players'
					GameObj.clear_pcs
				elsif attributes['id'] == 'room exits'
					@room_exits = Array.new
					@room_exits_string = String.new
				elsif attributes['id'] == 'room desc'
					@room_description = String.new
					GameObj.clear_room_desc
				# elsif attributes['id'] == 'sprite'
				end
			elsif (name == 'a') or (name == 'right') or (name == 'left')
				@obj_exist = attributes['exist']
				@obj_noun = attributes['noun']
			elsif name == 'clearContainer'
				if attributes['id'] == 'stow'
					GameObj.clear_container(@stow_container_id)
				else
					GameObj.clear_container(attributes['id'])
				end
			elsif name == 'deleteContainer'
				GameObj.delete_container(attributes['id'])
			elsif name == 'progressBar'
				if attributes['id'] == 'pbarStance'
					@stance_text = attributes['text'].split.first
					@stance_value = attributes['value'].to_i
					$_CLIENT_.puts "\034GSg#{sprintf('%010d', @stance_value)}\r\n" if @send_fake_tags
				elsif attributes['id'] == 'mana'
					last_mana = @mana
					@mana, @max_mana = attributes['text'].scan(/-?\d+/).collect { |num| num.to_i }
					difference = @mana - last_mana
					if (difference == noded_pulse) or (difference == unnoded_pulse) or ( (@mana == @max_mana) and (last_mana + noded_pulse > @max_mana) )
						@last_pulse = Time.now.to_i
						if @send_fake_tags
							$_CLIENT_.puts "\034GSZ#{sprintf('%010d',(@mana+1))}\n"
							$_CLIENT_.puts "\034GSZ#{sprintf('%010d',@mana)}\n"
						end
					end
					if @send_fake_tags
						$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', @max_health, @health, @max_spirit, @spirit, @max_mana, @mana, @wound_gsl, @scar_gsl)}\r\n"
					end
				elsif attributes['id'] == 'stamina'
					@stamina, @max_stamina = attributes['text'].scan(/-?\d+/).collect { |num| num.to_i }
				elsif attributes['id'] == 'mindState'
					@mind_text = attributes['text']
					@mind_value = attributes['value'].to_i
					$_CLIENT_.puts "\034GSr#{MINDMAP[@mind_text]}\r\n" if @send_fake_tags
				elsif attributes['id'] == 'health'
					@health, @max_health = attributes['text'].scan(/-?\d+/).collect { |num| num.to_i }
					$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', @max_health, @health, @max_spirit, @spirit, @max_mana, @mana, @wound_gsl, @scar_gsl)}\r\n" if @send_fake_tags
				elsif attributes['id'] == 'spirit'
					@spirit, @max_spirit = attributes['text'].scan(/-?\d+/).collect { |num| num.to_i }
					$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', @max_health, @health, @max_spirit, @spirit, @max_mana, @mana, @wound_gsl, @scar_gsl)}\r\n" if @send_fake_tags
				elsif attributes['id'] == 'nextLvlPB'
					Gift.pulse unless @next_level_text == attributes['text']
					@next_level_value = attributes['value'].to_i
					@next_level_text = attributes['text']
				elsif attributes['id'] == 'encumlevel'
					@encumbrance_value = attributes['value'].to_i
					@encumbrance_text = attributes['text']
				end
			elsif name == 'roundTime'
				@roundtime_end = attributes['value'].to_i
				$_CLIENT_.puts "\034GSQ#{sprintf('%010d', @roundtime_end)}\r\n" if @send_fake_tags
			elsif name == 'castTime'
				@cast_roundtime_end = attributes['value'].to_i
			elsif name == 'indicator'
				@indicator[attributes['id']] = attributes['visible']
				if @send_fake_tags
					if attributes['id'] == 'IconPOISONED'
						if attributes['visible'] == 'y'
							$_CLIENT_.puts "\034GSJ0000000000000000000100000000001\r\n"
						else
							$_CLIENT_.puts "\034GSJ0000000000000000000000000000000\r\n"
						end
					elsif attributes['id'] == 'IconDISEASED'
						if attributes['visible'] == 'y'
							$_CLIENT_.puts "\034GSK0000000000000000000100000000001\r\n"
						else
							$_CLIENT_.puts "\034GSK0000000000000000000000000000000\r\n"
						end
					else
						gsl_prompt = String.new; ICONMAP.keys.each { |icon| gsl_prompt += ICONMAP[icon] if @indicator[icon] == 'y' }
						$_CLIENT_.puts "\034GSP#{sprintf('%-30s', gsl_prompt)}\r\n"
					end
				end
			elsif (name == 'image') and @active_ids.include?('injuries')
				if @injuries.keys.include?(attributes['id'])
					if attributes['name'] =~ /Injury/i
						@injuries[attributes['id']]['wound'] = attributes['name'].slice(/\d/).to_i
					elsif attributes['name'] =~ /Scar/i
						@injuries[attributes['id']]['wound'] = 0
						@injuries[attributes['id']]['scar'] = attributes['name'].slice(/\d/).to_i
					elsif attributes['name'] =~ /Nsys/i
						rank = attributes['name'].slice(/\d/).to_i
						if rank == 0
							@injuries['nsys']['wound'] = 0
							@injuries['nsys']['scar'] = 0
						else
							Thread.new {
								wait_while { dead? }
								action = proc { |server_string|
									if (@nerve_tracker_active == 'maybe')
										if @nerve_tracker_active == 'maybe'
											if server_string =~ /^You/
												@nerve_tracker_active = 'yes'
												@injuries['nsys']['wound'] = 0
												@injuries['nsys']['scar'] = 0
											else
												@nerve_tracker_active = 'no'
											end
										end
									end
									if @nerve_tracker_active == 'yes'
										if server_string =~ /<output class=['"]['"]\/>/
											@nerve_tracker_active = 'no'
											@nerve_tracker_num -= 1
											DownstreamHook.remove('nerve_tracker') if @nerve_tracker_num < 1
											$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', @max_health, @health, @max_spirit, @spirit, @max_mana, @mana, make_wound_gsl, make_scar_gsl)}\r\n" if @send_fake_tags
											server_string
										elsif server_string =~ /a case of uncontrollable convulsions/
											@injuries['nsys']['wound'] = 3
											nil
										elsif server_string =~ /a case of sporadic convulsions/
											@injuries['nsys']['wound'] = 2
											nil
										elsif server_string =~ /a strange case of muscle twitching/
											@injuries['nsys']['wound'] = 1
											nil
										elsif server_string =~ /a very difficult time with muscle control/
											@injuries['nsys']['scar'] = 3
											nil
										elsif server_string =~ /constant muscle spasms/
											@injuries['nsys']['scar'] = 2
											nil
										elsif server_string =~ /developed slurred speech/
											@injuries['nsys']['scar'] = 1
											nil
										end
									else
										if server_string =~ /<output class=['"]mono['"]\/>/
											@nerve_tracker_active = 'maybe'
										end
										server_string
									end
								}
								@nerve_tracker_num += 1
								DownstreamHook.add('nerve_tracker', action)
								$_SERVER_.puts "<c>health\n"
							}
						end
					else
						@injuries[attributes['id']]['wound'] = 0
						@injuries[attributes['id']]['scar'] = 0
					end
				end
				$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', @max_health, @health, @max_spirit, @spirit, @max_mana, @mana, make_wound_gsl, make_scar_gsl)}\r\n" if @send_fake_tags
			elsif (name == 'streamWindow') and (attributes['id'] == 'main') and attributes['subtitle']
				@room_title = '[' + attributes['subtitle'][3..-1] + ']'
			elsif name == 'compass'
				if @current_stream == 'familiar'
					@fam_mode = String.new
				elsif @room_window_disabled
					@room_exits = Array.new
				end
			elsif @room_window_disabled and (name == 'dir') and @active_tags.include?('compass')
				@room_exits.push(LONGDIR[attributes['value']])
			elsif name == 'radio'
				if attributes['id'] == 'injrRad'
					@injury_mode = 0 if attributes['value'] == '1'
				elsif attributes['id'] == 'scarRad'
					@injury_mode = 1 if attributes['value'] == '1'
				elsif attributes['id'] == 'bothRad'
					@injury_mode = 2 if attributes['value'] == '1'
				end
			elsif name == 'label'
				if attributes['id'] == 'yourLvl'
					Stats.level = attributes['value'].slice(/\d+/).to_i
				elsif attributes['id'] == 'encumblurb'
					@encumbrance_full_text = attributes['value']
				end
			elsif (name == 'container') and (attributes['id'] == 'stow')
				@stow_container_id = attributes['target'].sub('#', '')
			elsif (name == 'clearStream')
				if attributes['id'] == 'spellfront'
					@spellfront.clear
				elsif attributes['id'] == 'bounty'
					@bounty_task = String.new
				end
			elsif (name == 'app') and (@name = attributes['char'])
				if $fake_stormfront
					# fixme: game name hardcoded as Gemstone IV; maybe doesn't make any difference to the client.
					$_CLIENT_.puts "\034GSB0000000000#{attributes['char']}\r\n\034GSA#{Time.now.to_i.to_s}GemStone IV\034GSD\r\n"
					# Sending fake GSL tags to the Wizard FE is disabled until now, because it doesn't accept the tags and just gives errors until initialized with the above line
					@send_fake_tags = true
					# Send all the tags we missed out on
					$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', @max_health, @health, @max_spirit, @spirit, @max_mana, @mana, make_wound_gsl, make_scar_gsl)}\r\n"
					$_CLIENT_.puts "\034GSg#{sprintf('%010d', @stance_value)}\r\n"
					$_CLIENT_.puts "\034GSr#{MINDMAP[@mind_text]}\r\n"
					gsl_prompt = String.new
					@indicator.keys.each { |icon| gsl_prompt += ICONMAP[icon] if @indicator[icon] == 'y' }
					$_CLIENT_.puts "\034GSP#{sprintf('%-30s', gsl_prompt)}\r\n"
					gsl_prompt = nil
					gsl_exits = String.new
					@room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
					$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
					gsl_exits = nil
					$_CLIENT_.puts "\034GSn#{sprintf('%-14s', @prepared_spell)}\r\n"
					$_CLIENT_.puts "\034GSm#{sprintf('%-45s', GameObj.right_hand.name)}\r\n"
					$_CLIENT_.puts "\034GSl#{sprintf('%-45s', GameObj.left_hand.name)}\r\n"
					$_CLIENT_.puts "\034GSq#{sprintf('%010d', @server_time)}\r\n"
					$_CLIENT_.puts "\034GSQ#{sprintf('%010d', @roundtime_end)}\r\n" if @roundtime_end > 0
				end
				UserVariables.init
				Alias.init
				Favorites.init
			end
		rescue
			$stdout.puts "--- error: XMLParser.tag_start: #{$!}"
			$stderr.puts "error: XMLParser.tag_start: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.1".to_f
			reset
		end
	end
	def text(text)
		begin
			if @active_tags.last == 'prompt'
				#@prompt = text
				nil
			elsif @active_tags.include?('right')
				GameObj.new_right_hand(@obj_exist, @obj_noun, text)
				$_CLIENT_.puts "\034GSm#{sprintf('%-45s', text)}\r\n" if @send_fake_tags
			elsif @active_tags.include?('left')
				GameObj.new_left_hand(@obj_exist, @obj_noun, text)
				$_CLIENT_.puts "\034GSl#{sprintf('%-45s', text)}\r\n" if @send_fake_tags
			elsif @active_tags.include?('spell')
				@prepared_spell = text
				$_CLIENT_.puts "\034GSn#{sprintf('%-14s', text)}\r\n" if @send_fake_tags
			elsif @active_tags.include?('compDef') or @active_tags.include?('component')
				if @active_ids.include?('room objs')
					if @active_tags.include?('a')
						if @bold
							GameObj.new_npc(@obj_exist, @obj_noun, text)
						else
							GameObj.new_loot(@obj_exist, @obj_noun, text)
						end
					elsif (text =~ /that (?:is|appears) ([\w\s]+)(?:,| and|\.)/) or (text =~ / \(([^\(]+)\)/)
						GameObj.npcs[-1].status = $1
					end
				elsif @active_ids.include?('room players')
					if @active_tags.include?('a')
						GameObj.new_pc(@obj_exist, @obj_noun, @player_title.to_s + text)
						GameObj.pcs[-1].status = @player_status unless @player_status.empty?
						@player_status = String.new
					else
						if (text =~ /^ who (?:is|appears) ([\w\s]+)(?:,| and|\.|$)/) or (text =~ / \(([\w\s]+)\)/)
							if $1
								if GameObj.pcs[-1].status.nil?
									GameObj.pcs[-1].status = $1
								else
									GameObj.pcs[-1].status.concat(" #{$1}")
								end
							end
						end
						if text =~ /(?:^Also here: |, )([a-z\s]+)?([\w\s]+)?$/
							@player_status = ($1.strip.gsub('the body of', 'dead')) if $1
							@player_title = $2
						end
					end
				elsif @active_ids.include?('room desc')
					if text == '[Room window disabled at this location.]'
						#respond '[Room window disabled at this location.]'
						@room_window_disabled = true
					else
						@room_window_disabled = false
						@room_description.concat(text)
						if @active_tags.include?('a')
							GameObj.new_room_desc(@obj_exist, @obj_noun, text)
						end
					end
				elsif @active_ids.include?('room exits')
					@room_exits_string.concat(text)
					@room_exits.push(text) if @active_tags.include?('d')
				end
			elsif @active_tags.include?('inv') and @active_tags.include?('a')
				container_id = @active_ids.find { |id| !id.nil? }
				if container_id.to_s == 'stow'
					container_id = @stow_container_id
				end
				unless container_id.nil? or (container_id == @obj_exist)
					obj = GameObj.new_inv(@obj_exist, @obj_noun, text, container_id)
				end
			elsif @current_stream == 'spellfront'
				@spellfront.push(text.strip)
			elsif @current_stream == 'bounty'
				@bounty_task += text
			elsif @current_stream == 'society'
				@society_task = text
			elsif (@current_stream == 'inv') and @active_tags.include?('a')
				GameObj.new_inv(@obj_exist, @obj_noun, text, nil)
			elsif @current_stream == 'familiar'
				# fixme: familiar room tracking does not (can not?) auto update, status of pcs and npcs isn't tracked at all, titles of pcs aren't tracked
				if @current_style == 'roomName'
					@familiar_room_title = text
					@familiar_room_description = String.new
					@familiar_room_exits = Array.new
					GameObj.clear_fam_room_desc
					GameObj.clear_fam_loot
					GameObj.clear_fam_npcs
					GameObj.clear_fam_pcs
					@fam_mode = String.new
				elsif @current_style == 'roomDesc'
					@familiar_room_description.concat(text)
					if @active_tags.include?('a')
						GameObj.new_fam_room_desc(@obj_exist, @obj_noun, text)
					end
				elsif text =~ /^You also see/
					@fam_mode = 'things'
				elsif text =~ /^Also here/
					@fam_mode = 'people'
				elsif text =~ /Obvious (?:paths|exits)/
					@fam_mode = 'paths'
				elsif @fam_mode == 'things'
					if @active_tags.include?('a')
						if @bold
							GameObj.new_fam_npc(@obj_exist, @obj_noun, text)
						else
							GameObj.new_fam_loot(@obj_exist, @obj_noun, text)
						end
					end
					# respond 'things: ' + text
				elsif @fam_mode == 'people' and @active_tags.include?('a')
					GameObj.new_fam_pc(@obj_exist, @obj_noun, text)
					# respond 'people: ' + text
				elsif (@fam_mode == 'paths') and @active_tags.include?('a')
					@familiar_room_exits.push(text)
				end
			elsif @room_window_disabled
				if @current_style == 'roomDesc'
					@room_description.concat(text)
					if @active_tags.include?('a')
						GameObj.new_room_desc(@obj_exist, @obj_noun, text)
					end
				elsif text =~ /^Obvious (?:paths|exits): $/
					@room_exits_string = text.strip
				end
			end
		rescue
			$stdout.puts "--- error: XMLParser.text: #{$!}"
			$stderr.puts "error: XMLParser.text: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.1".to_f
			reset
		end
	end
	def tag_end(name)
		begin
			if @send_fake_tags and (@active_ids.last == 'room exits')
				gsl_exits = String.new
				@room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
				$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
				gsl_exits = nil
			elsif @room_window_disabled and (name == 'compass')
				@room_window_disabled = false
				@room_description = @room_description.strip
				@room_exits_string = @room_exits_string + ' ' + @room_exits.join(', ')
				gsl_exits = String.new
				@room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
				$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
				gsl_exits = nil
			end
			@active_tags.pop
			@active_ids.pop
		rescue
			$stdout.puts "--- error: XMLParser.tag_end: #{$!}"
			$stderr.puts "error: XMLParser.tag_end: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.1".to_f
			reset
		end
	end
end

XMLData = XMLParser.new

class UpstreamHook
	@@upstream_hooks ||= Hash.new
	def UpstreamHook.add(name, action)
		unless action.class == Proc
			echo "UpstreamHook: not a Proc (#{action})"
			return false
		end
		@@upstream_hooks[name] = action
	end
	def UpstreamHook.run(client_string)
		for key in @@upstream_hooks.keys
			begin
				client_string = @@upstream_hooks[key].call(client_string)
			rescue
				@@upstream_hooks.delete(key)
				respond "--- Lich: UpstreamHook: #{$!}"
				respond $!.backtrace.first
			end
			return nil if client_string.nil?
		end
		return client_string
	end
	def UpstreamHook.remove(name)
		@@upstream_hooks.delete(name)
	end
	def UpstreamHook.list
		@@upstream_hooks.keys.dup
	end
end

class DownstreamHook
	@@downstream_hooks ||= Hash.new
	def DownstreamHook.add(name, action)
		unless action.class == Proc
			echo "DownstreamHook: not a Proc (#{action})"
			return false
		end
		@@downstream_hooks[name] = action
	end
	def DownstreamHook.run(server_string)
		for key in @@downstream_hooks.keys
			begin
				server_string = @@downstream_hooks[key].call(server_string)
			rescue
				@@downstream_hooks.delete(key)
				respond "--- Lich: DownstreamHook: #{$!}"
				respond $!.backtrace.first
			end
			return nil if server_string.nil?
		end
		return server_string
	end
	def DownstreamHook.remove(name)
		@@downstream_hooks.delete(name)
	end
	def DownstreamHook.list
		@@downstream_hooks.keys.dup
	end
end

class LichSettings
	@@settings ||= Hash.new
	def LichSettings.load
		if File.exists?("#{$data_dir}lich.sav")
			begin
				File.open("#{$data_dir}lich.sav", 'rb') { |f|
					@@settings = Marshal.load(f.read)['lichsettings']
				}
			rescue
				$stdout.puts "--- error: LichSettings.load: #{$!}"
				$stderr.puts "error: LichSettings.load: #{$!}"
				$stderr.puts $!.backtrace
			end
		end
		@@settings ||= Hash.new
	end
	def LichSettings.save
		begin
			all_settings = Hash.new
			if File.exists?("#{$data_dir}lich.sav")
				File.open("#{$data_dir}lich.sav", 'rb') { |f| all_settings = Marshal.load(f.read) }
			end
			all_settings['lichsettings'] = @@settings
			File.open("#{$data_dir}lich.sav", 'wb') { |f| f.write(Marshal.dump(all_settings)) }
			true
		rescue
			false
		end
	end
	def LichSettings.list
		@@settings.dup
	end
	def LichSettings.clear
		@@settings = Hash.new
	end
	def LichSettings.[](setting_name)
		@@settings[setting_name]
	end
	def LichSettings.[]=(setting_name, setting_value)
		@@settings[setting_name] = setting_value
	end
end

class Favorites
	@@settings ||= Hash.new
	def Favorites.init
		Favorites.load if @@settings.empty?
		begin
			@@settings['global'].each_pair { |scr,vars| start_script(scr, vars) }
			@@settings[XMLData.name].each_pair { |scr,vars| start_script(scr, vars) }
		rescue
			respond "--- Lich: error starting favorite scripts: (#{$!})"
		end
	end
	def Favorites.load
		if File.exists?("#{$data_dir}lich.sav")
			begin
				File.open("#{$data_dir}lich.sav", 'rb') { |f|
					@@settings = Marshal.load(f.read)['favorites']
				}
			rescue
				$stdout.puts "--- error: Favorites.load: #{$!}"
				$stderr.puts "error: Favorites.load: #{$!}"
				$stderr.puts $!.backtrace
			end
		end
		if File.exists?("#{$data_dir}favs.sav")
			File.open("#{$data_dir}favs.sav", 'rb') { |f|
				@@settings = Marshal.load(f.read)
			}
			@@settings['global'].delete('alias')
			@@settings['global'].delete('setting')
			File.rename("#{$data_dir}favs.sav", "#{$temp_dir}favs.sav")
			Favorites.save
		end
		@@settings ||= Hash.new
		@@settings['global'] ||= { 'updater' => ['update'], 'infomon' => [], 'lnet' => [] }
		@@settings[XMLData.name] ||= Hash.new
	end
	def Favorites.save
		all_settings = Hash.new
		if File.exists?("#{$data_dir}lich.sav")
			File.open("#{$data_dir}lich.sav", 'rb') { |f| all_settings = Marshal.load(f.read) }
		end
		all_settings['favorites'] = @@settings
		File.open("#{$data_dir}lich.sav", 'wb') { |f| f.write(Marshal.dump(all_settings)) }
	end
	def Favorites.list
		@@settings.dup
	end
	def Favorites.add(script_name, script_vars = Array.new, type = :char)
		if type == :char
			@@settings[XMLData.name] ||= Hash.new
			@@settings[XMLData.name][script_name] = script_vars
			Favorites.save
			true
		elsif type == :global
			@@settings['global'] ||= Hash.new
			@@settings['global'][script_name] = script_vars
			Favorites.save
			true
		else
			echo 'Favs.add: invalid type given, use :char or :global'
			false
		end
	end
	def Favorites.delete(script_name, type = :char)
		if type == :char
			if @@settings[XMLData.name].delete(script_name)
				Favorites.save
				true
			else
				false
			end
		elsif type == :global
			if @@settings['global'].delete(script_name)
				Favorites.save
				true
			else
				false
			end
		else
			false
		end
	end
end

class Favs < Favorites
end

class Alias
	@@char_regex_string ||= String.new
	@@global_regex_string ||= String.new
	@@settings ||= Hash.new
	def Alias.init
		if File.exists?("#{$data_dir}lich.sav")
			begin
				File.open("#{$data_dir}lich.sav", 'rb') { |f|
					@@settings = Marshal.load(f.read)['alias']
				}
			rescue
				$stdout.puts "--- error: Alias.init: #{$!}"
				$stderr.puts "error: Alias.init: #{$!}"
				$stderr.puts $!.backtrace
			end
		end
		if File.exists?("#{$data_dir}alias.sav")
			File.open("#{$data_dir}alias.sav", 'rb') { |f|
				@@settings = Marshal.load(f.read)
			}
			File.rename("#{$data_dir}alias.sav", "#{$temp_dir}alias.sav")
			Alias.save
		end
		@@settings ||= Hash.new
		@@settings['global'] ||= { 'repo' => ';repo' }
		@@settings[XMLData.name] ||= Hash.new
		@@char_regex_string = @@settings[XMLData.name].keys.join('|')
		@@global_regex_string = @@settings['global'].keys.join('|')
	end
	def Alias.save
		all_settings = Hash.new
		if File.exists?("#{$data_dir}lich.sav")
			File.open("#{$data_dir}lich.sav", 'rb') { |f| all_settings = Marshal.load(f.read) }
		end
		all_settings['alias'] = @@settings
		File.open("#{$data_dir}lich.sav", 'wb') { |f| f.write(Marshal.dump(all_settings)) }
		true
	end
	def Alias.add(trigger, target, type = :char)
		trigger = Regexp.escape(trigger)
		if type == :char
			@@settings[XMLData.name][trigger.downcase] = target
			@@char_regex_string = @@settings[XMLData.name].keys.join('|')
			Alias.save
			true
		elsif type == :global
			@@settings['global'][trigger.downcase] = target
			@@global_regex_string = @@settings['global'].keys.join('|')
			Alias.save
			true
		else
			echo 'Alias.add: invalid type given, use :char or :global'
			false
		end
	end
	def Alias.delete(trigger, type = :char)
		trigger = Regexp.escape(trigger)
		if type == :char
			which = @@settings[XMLData.name].keys.find { |key| key == trigger.downcase }
			if which and @@settings[XMLData.name].delete(which)
				@@char_regex_string = @@settings[XMLData.name].keys.join('|')
				Alias.save
				true
			else
				false
			end
		elsif type == :global
			which = @@settings['global'].keys.find { |key| key == trigger.downcase }
			if which and @@settings['global'].delete(which) 
				@@global_regex_string = @@settings['global'].keys.join('|')
				Alias.save
				true
			else
				false
			end
		else
			echo 'Alias.delete: invalid type given, use :char or :global'
			false
		end
	end
	def Alias.find(trigger)
		return false if trigger.nil? or trigger.empty?
		if not @@char_regex_string.empty? and /^(?:<c>)?(#{@@char_regex_string})(?:\s|$)/i.match(trigger.strip).captures.first
			true
		elsif not @@global_regex_string.empty? and /^(?:<c>)?(#{@@global_regex_string})(?:\s|$)/i.match(trigger.strip).captures.first
			true
		else
			false
		end
	end
	def Alias.list
		@@settings.dup
	end
	def Alias.run(trig)
		if trig.strip =~ /^(?:<c>)?(#{@@char_regex_string})(?:\s+|$)(.*)/i
			trigger, extra = $1, $2
		elsif trig.strip =~ /^(?:<c>)?(#{@@global_regex_string})(?:\s+|$)(.*)/i
			trigger, extra = $1, $2
		end
		unless target = @@settings[XMLData.name][Regexp.escape(trigger.downcase)].dup || target = @@settings['global'][Regexp.escape(trigger.downcase)].dup
			respond '--- Lich: tried to run unkown alias (' + trig.to_s.strip + ')'
			return false
		end
		unless extra.empty?
			if target.include?('\?')
				if (target =~ /^;e/) and target.include?('"\?"')
					target.gsub!('"\?"', extra.inspect)
				elsif (target =~ /^;e/) and target.include?('\'\?\'')
					target.gsub!('\'\?\'', "'#{extra.split("'").join("\\\\'")}'")
				else
					target.gsub!('\?', extra)
				end
			else
				target.concat(' ' + extra)
			end
		end
		target.gsub!('\?', '')
		target.split('\r').each { |str| do_client(str.chomp + "\n") }
	end
end

class UserVariables
	@@settings ||= Hash.new
	def UserVariables.init
		if File.exists?("#{$data_dir}lich.sav")
			begin
				File.open("#{$data_dir}lich.sav", 'rb') { |f|
					@@settings = Marshal.load(f.read)['uservariables']
				}
			rescue
				$stdout.puts "--- error: UserVariables.init: #{$!}"
				$stderr.puts "error: UserVariables.init: #{$!}"
				$stderr.puts $!.backtrace
			end
		end
		if File.exists?("#{$data_dir}setting.sav")
			File.open("#{$data_dir}setting.sav", 'rb') { |f|
				@@settings = Marshal.load(f.read)
			}
			File.rename("#{$data_dir}setting.sav", "#{$temp_dir}setting.sav")
			UserVariables.save
		end
		@@settings ||= Hash.new
		@@settings['global'] ||= Hash.new
		@@settings[XMLData.name] ||= Hash.new
	end
	def UserVariables.save
		all_settings = Hash.new
		if File.exists?("#{$data_dir}lich.sav")
			File.open("#{$data_dir}lich.sav", 'rb') { |f| all_settings = Marshal.load(f.read) }
		end
		all_settings['uservariables'] = @@settings
		File.open("#{$data_dir}lich.sav", 'wb') { |f| f.write(Marshal.dump(all_settings)) }
	end
	def UserVariables.change(var_name, value, type = :char)
		if type == :char
			@@settings[XMLData.name][var_name] = value
			UserVariables.save
			true
		elsif type == :global
			@@settings['global'][var_name] = value
			UserVariables.save
			true
		else
			echo 'UserVariables.change: invalid type given, use :char or :global.'
			false
		end
	end
	def UserVariables.add(var_name, value, type = :char)
		if type == :char
			@@settings[XMLData.name][var_name] = @@settings[XMLData.name][var_name].split(', ').push(value.strip).join(', ')
			UserVariables.save
			true
		elsif type == :global
			@@settings['global'][var_name] = @@settings['global'][var_name].split(', ').push(value.strip).join(', ')
			UserVariables.save
			true
		else
			echo 'UserVariables.add: invalid type given, use :char or :global.'
			nil
		end
	end
	def UserVariables.delete(var_name, type = :char)
		if type == :char
			if @@settings[XMLData.name].delete(var_name)
				UserVariables.save
				true
			else
				false
			end
		elsif type == :global
			if @@settings['global'].delete(var_name)
				UserVariables.save
				true
			else
				false
			end
		else
			false
		end
	end
	def UserVariables.list
		@@settings.dup
	end
	def UserVariables.method_missing(arg1, arg2='')
		if arg1.to_s.split('')[-1] == '='
			@@settings[XMLData.name][arg1.to_s.chop] = arg2
			UserVariables.save
		elsif @@settings[XMLData.name][arg1.to_s]
			@@settings[XMLData.name][arg1.to_s]
		else
			@@settings['global'][arg1.to_s]
		end
	end
end

class UserVars < UserVariables
end

class Lich < UserVariables
	def Lich.list_settings
		@@settings
	end
	def Lich.fetchloot
		if items = checkloot.find_all { |item| item =~ /#{@@treasure.join('|')}/ }
			take(items)
		else
			return false
		end
	end
end

class Script
	@@running ||= Array.new
	attr_reader :name, :vars, :safe, :labels, :file_name, :label_order, :thread_group
	attr_accessor :quiet, :no_echo, :jump_label, :current_label, :want_downstream, :want_downstream_xml, :want_upstream, :dying_procs, :hidden, :paused, :silent, :no_pause_all, :no_kill_all, :downstream_buffer, :upstream_buffer, :unique_buffer, :die_with, :match_stack_labels, :match_stack_strings
	def initialize(file_name, cli_vars=[])
		@name = /.*[\/\\]+([^\.]+)\./.match(file_name).captures.first
		@file_name = file_name
		@vars = Array.new
		unless cli_vars.empty?
			cli_vars.each_index { |idx| @vars[idx+1] = cli_vars[idx] }
			@vars[0] = @vars[1..-1].join(' ')
			cli_vars = nil
		end
		if @vars.first =~ /^quiet$/i
			@quiet = true
			@vars.shift
		else 
			@quiet = false
		end
		@downstream_buffer = LimitedArray.new
		@want_downstream = true
		@want_downstream_xml = false
		@upstream_buffer = LimitedArray.new
		@want_upstream = false
		@unique_buffer = LimitedArray.new
		@dying_procs = Array.new
		@die_with = Array.new
		@paused = false
		@hidden = false
		@no_pause_all = false
		@no_kill_all = false
		@silent = false
		@safe = false
		@no_echo = false
		@match_stack_labels = Array.new
		@match_stack_strings = Array.new
		@label_order = Array.new
		@labels = Hash.new
		data = nil
		begin
			Zlib::GzipReader.open(file_name) { |f| data = f.readlines.collect { |line| line.chomp } }
		rescue
			begin
				File.open(file_name) { |f| data = f.readlines.collect { |line| line.chomp } }
			rescue
				respond "--- Lich: error reading script file (#{file_name}): #{$!}"
				return nil
			end
		end
		@quiet = true if data[0] =~ /^[\t\s]*#?[\t\s]*(?:quiet|hush)$/i
		@current_label = '~start'
		@label_order.push(@current_label)
		for line in data
			if line =~ /^([\d_\w]+):$/
				@current_label = $1
				@label_order.push(@current_label)
				@labels[@current_label] = String.new
			else
				@labels[@current_label] += "#{line}\n"
			end
		end
		data = nil
		@current_label = @label_order[0]
		@thread_group = ThreadGroup.new
		@@running.push(self)
		return self
	end
	def kill
		Thread.new {
			die_with, dying_procs = @die_with.dup, @dying_procs.dup
			@die_with, @dying_procs = nil, nil
			@thread_group.list.dup.each { |thr|
				unless thr == Thread.current
					thr.kill rescue()
				end
			}
			@thread_group.add(Thread.current)
			die_with.each { |script_name| stop_script script_name }
			@paused = false
			dying_procs.each { |runme|
				begin
					runme.call
				rescue SyntaxError
					echo("Syntax error in dying code block: #{$!}")
				rescue SystemExit
					nil
				rescue Exception
					if $! == JUMP or $! == JUMP_ERROR
						echo('Cannot execute jumps in before_dying code blocks...!')
					else
						echo("--- error in dying code block: #{$!}")
					end
				rescue
					echo("--- error in dying code block: #{$!}")
				end
			}
			@downstream_buffer = @upstream_buffer = @match_stack_labels = @match_stack_strings = nil
			@@running.delete(self)
			respond("--- Lich: #{@name} has exited.") unless @quiet
			GC.start
		}
		@name
	end
	def pause
		respond "--- Lich: #{@name} paused."
		@paused = true
	end
	def unpause
		respond "--- Lich: #{@name} unpaused."
		@paused = false
	end
	def get_next_label
		if !@jump_label
			@current_label = @label_order[@label_order.index(@current_label)+1]
		else
			if label = @labels.keys.find { |val| val =~ /^#{@jump_label}$/ }
				@current_label = label
			elsif label = @labels.keys.find { |val| val =~ /^#{@jump_label}$/i }
				@current_label = label
			elsif label = @labels.keys.find { |val| val =~ /^labelerror$/i }
				@current_label = label
			else
				@current_label = nil
				return JUMP_ERROR
			end
			@jump_label = nil
			@current_label
		end
	end
	def clear
		to_return = @downstream_buffer.dup
		@downstream_buffer.clear
		to_return
	end
	def Script.self
		script = @@running.find { |scr| scr.thread_group == Thread.current.group }
		return nil unless script
		while script.paused; sleep "0.2".to_f; end
		script
	end
	def Script.running
		list = Array.new
		for script in @@running
			list.push(script) unless script.hidden
		end
		return list
	end
	def Script.index
		Script.running
	end
	def Script.hidden
		list = Array.new
		for script in @@running
			list.push(script) if script.hidden
		end
		return list
	end
	def to_s
		@name
	end	
	def Script.new_downstream(line)
		for script in @@running
			script.downstream_buffer.push(line.chomp) if script.want_downstream
			# fixme: watchfor
		end
	end
	def Script.new_downstream_xml(line)
		for script in @@running
			script.downstream_buffer.push(line.chomp) if script.want_downstream_xml
		end
	end
	def Script.new_upstream(line)
		for script in @@running
			script.upstream_buffer.push(line.chomp) if script.want_upstream
		end
	end
	def gets
		if @want_downstream or @want_downstream_xml
			sleep "0.05".to_f while @downstream_buffer.empty?
			@downstream_buffer.shift
		else
			echo 'this script is set as unique but is waiting for game data...'
			sleep 2
			false
		end
	end
	def gets?
		if @want_downstream or @want_downstream_xml
			if @downstream_buffer.empty?
				nil
			else
				@downstream_buffer.shift
			end
		else
			echo 'this script is set as unique but is waiting for game data...'
			sleep 2
			false
		end
	end
	def upstream_gets
		sleep "0.05".to_f while @upstream_buffer.empty?
		@upstream_buffer.shift
	end
	def upstream_gets?
		if @upstream_buffer.empty?
			nil
		else
			@upstream_buffer.shift
		end
	end
	def unique_gets
		sleep "0.05".to_f while @unique_buffer.empty?
		@unique_buffer.shift
	end
	def unique_gets?
		if @unique_buffer.empty?
			nil
		else
			@unique_buffer.shift
		end
	end
	def safe?
		@safe
	end
	def feedme_upstream
		@want_upstream = !@want_upstream
	end
	def match_stack_add(label,string)
		@match_stack_labels.push(label)
		@match_stack_strings.push(string)
	end
	def match_stack_clear
		@match_stack_labels.clear
		@match_stack_strings.clear
	end
	# for backwards compatability
	def Script.namescript_incoming(line)
		Script.new_downstream(line)
	end
end

class ExecScript<Script
	attr_reader :cmd_data
	def initialize(cmd_data, quiet=false)
		num = '1'
		while @@running.find { |script| script.name == "exec%s" % num }
			num.succ!
		end
		@name = "exec#{num}"
		@cmd_data = cmd_data
		@vars = Array.new
		@downstream_buffer = LimitedArray.new
		@want_downstream = true
		@want_downstream_xml = false
		@upstream_buffer = LimitedArray.new
		@want_upstream = false
		@dying_procs = Array.new
		@hidden = false
		@paused = false
		@silent = false
		@quiet = quiet
		@safe = false
		@no_echo = false
		@thread_group = ThreadGroup.new
		@unique_buffer = LimitedArray.new
		@die_with = Array.new
		@no_pause_all = false
		@no_kill_all = false
		@match_stack_labels = Array.new
		@match_stack_strings = Array.new
		@@running.push(self)
		self
	end
	def get_next_label
		echo 'goto labels are not available in exec scripts.'
		nil
	end
end

class WizardScript<Script
	def initialize(file_name, cli_vars=[])
		@name = /.*[\/\\]+([^\.]+)\./.match(file_name).captures.first
		@file_name = file_name
		@vars = Array.new
		unless cli_vars.empty?
			cli_vars.each_index { |idx| @vars[idx+1] = cli_vars[idx] }
			@vars[0] = @vars[1..-1].join(' ')
			cli_vars = nil
		end
		if @vars.first =~ /^quiet$/i
			@quiet = true
			@vars.shift
		else 
			@quiet = false
		end
		@downstream_buffer = LimitedArray.new
		@want_downstream = true
		@want_downstream_xml = false
		@upstream_buffer = LimitedArray.new
		@want_upstream = false
		@unique_buffer = LimitedArray.new
		@dying_procs = Array.new
		@die_with = Array.new
		@paused = false
		@hidden = false
		@no_pause_all = false
		@no_kill_all = false
		@silent = false
		@safe = false
		@no_echo = false
		@match_stack_labels = Array.new
		@match_stack_strings = Array.new
		@label_order = Array.new
		@labels = Hash.new
		data = nil
		begin
			Zlib::GzipReader.open(file_name) { |f| data = f.readlines.collect { |line| line.chomp } }
		rescue
			begin
				File.open(file_name) { |f| data = f.readlines.collect { |line| line.chomp } }
			rescue
				respond "--- Lich: error reading script file (#{file_name}): #{$!}"
				return nil
			end
		end
		@quiet = true if data[0] =~ /^[\t\s]*#?[\t\s]*(?:quiet|hush)$/i

		counter_action = {
			'add'      => '+',
			'sub'      => '-',
			'subtract' => '-',
			'multiply' => '*',
			'divide'   => '/',
			'set'      => ''
		}
		
		setvars = Array.new
		data.each { |line| setvars.push($1) if line =~ /[\s\t]*setvariable\s+([^\s\t]+)[\s\t]/i and not setvars.include?($1) }
		has_counter = data.find { |line| line =~ /%c/i }
		has_save = data.find { |line| line =~ /%s/i }
		has_nextroom = data.find { |line| line =~ /nextroom/i }
		
		fixstring = proc { |str|
			while not setvars.empty? and str =~ /%(#{setvars.join('|')})%/io
				str.gsub!('%' + $1 + '%', '#{' + $1.downcase + '}')
			end
			str.gsub!(/%c(?:%)?/i, '#{c}')
			str.gsub!(/%s(?:%)?/i, '#{sav}')
			while str =~ /%([0-9])(?:%)?/
				str.gsub!(/%#{$1}(?:%)?/, '#{script.vars[' + $1 + ']}')
			end
			str
		}
		
		fixline = proc { |line|
			if line =~ /^[\s\t]*[A-Za-z0-9_\-']+:/i
				line = line.downcase.strip
			elsif line =~ /^([\s\t]*)counter\s+(add|sub|subtract|divide|multiply|set)\s+([0-9]+)/i
				line = "#{$1}c #{counter_action[$2]}= #{$3}"
			elsif line =~ /^([\s\t]*)counter\s+(add|sub|subtract|divide|multiply|set)\s+(.*)/i
				indent, action, arg = $1, $2, $3
				line = "#{indent}c #{counter_action[action]}= #{fixstring.call(arg.inspect)}.to_i"
			elsif line =~ /^([\s\t]*)save[\s\t]+"?(.*?)"?[\s\t]*$/i
				indent, arg = $1, $2
				line = "#{indent}sav = #{fixstring.call(arg.inspect)}"
			elsif line =~ /^([\s\t]*)echo[\s\t]+(.+)/i
				indent, arg = $1, $2
				line = "#{indent}echo #{fixstring.call(arg.inspect)}"
			elsif line =~ /^([\s\t]*)waitfor[\s\t]+(.+)/i
				indent, arg = $1, $2
				line = "#{indent}waitfor #{fixstring.call(Regexp.escape(arg).inspect.gsub("\\\\ ", ' '))}"
			elsif line =~ /^([\s\t]*)(put|move)[\s\t]+(.+)/i
				indent, cmd, arg = $1, $2, $3
				line = "#{indent}waitrt?\n#{indent}clear\n#{indent}#{cmd.downcase} #{fixstring.call(arg.inspect)}"
			elsif line =~ /^([\s\t]*)goto[\s\t]+(.+)/i
				indent, arg = $1, $2
				line = "#{indent}goto #{fixstring.call(arg.inspect).downcase}"
			elsif line =~ /^([\s\t]*)waitforre[\s\t]+(.+)/i
				indent, arg = $1, $2
				line = "#{indent}waitforre #{arg}"
			elsif line =~ /^([\s\t]*)pause[\s\t]*(.*)/i
				indent, arg = $1, $2
				arg = '1' if arg.empty?
				arg = '0'+arg.strip if arg.strip =~ /^\.[0-9]+$/
				line = "#{indent}pause #{arg}"
			elsif line =~ /^([\s\t]*)match[\s\t]+([^\s\t]+)[\s\t]+(.+)/i
				indent, label, arg = $1, $2, $3
				line = "#{indent}match #{fixstring.call(label.inspect).downcase}, #{fixstring.call(Regexp.escape(arg).inspect.gsub("\\\\ ", ' '))}"
			elsif line =~ /^([\s\t]*)matchre[\s\t]+([^\s\t]+)[\s\t]+(.+)/i
				indent, label, regex = $1, $2, $3
				line = "#{indent}matchre #{fixstring.call(label.inspect).downcase}, #{regex}"
			elsif line =~ /^([\s\t]*)setvariable[\s\t]+([^\s\t]+)[\s\t]+(.+)/i
				indent, var, arg = $1, $2, $3
				line = "#{indent}#{var.downcase} = #{fixstring.call(arg.inspect)}"
			elsif line =~ /^([\s\t]*)deletevariable[\s\t]+(.+)/i
				line = "#{$1}#{$2.downcase} = nil"
			elsif line =~ /^([\s\t]*)(wait|nextroom|exit|echo)\b/i
				line = "#{$1}#{$2.downcase}"
			elsif line =~ /^([\s\t]*)matchwait\b/i
				line = "#{$1}matchwait"
			elsif line =~ /^([\s\t]*)if_([0-9])[\s\t]+(.*)/i
				indent, num, stuff = $1, $2, $3
				line = "#{indent}if script.vars[#{num}]\n#{indent}\t#{fixline.call($3)}\n#{indent}end"
			elsif line =~ /^([\s\t]*)shift\b/i
				line = "#{$1}script.vars.shift"
			else
				respond "--- Lich: unknown line: #{line}"
				line = '#' + line
			end
		}
		
		lich_block = false
		
		data.each_index { |idx|
			if lich_block
				if data[idx] =~ /\}[\s\t]*LICH[\s\t]*$/
					data[idx] = data[idx].sub(/\}[\s\t]*LICH[\s\t]*$/, '')
					lich_block = false
				else
					next
				end		
			elsif data[idx] =~ /^[\s\t]*#|^[\s\t]*$/
				next
			elsif data[idx] =~ /^[\s\t]*LICH[\s\t]*\{/
				data[idx] = data[idx].sub(/LICH[\s\t]*\{/, '')
				if data[idx] =~ /\}[\s\t]*LICH[\s\t]*$/
					data[idx] = data[idx].sub(/\}[\s\t]*LICH[\s\t]*$/, '')
				else
					lich_block = true
				end
			else
				data[idx] = fixline.call(data[idx])
			end
		}
		
		if has_counter or has_save or has_nextroom
			data.each_index { |idx|
				next if data[idx] =~ /^[\s\t]*#/
				data.insert(idx, '')
				data.insert(idx, 'c = 0') if has_counter
				data.insert(idx, "Settings.load\nsav = Settings['sav'] || String.new\nbefore_dying { Settings['sav'] = sav; Settings.save }") if has_save
				data.insert(idx, "def nextroom\n\troom_count = XMLData.room_count\n\twait_while { room_count == XMLData.room_count }\nend") if has_nextroom
				data.insert(idx, '')
				break
			}
		end
		
		@current_label = '~start'
		@label_order.push(@current_label)
		for line in data
			if line =~ /^([\d_\w]+):$/
				@current_label = $1
				@label_order.push(@current_label)
				@labels[@current_label] = String.new
			else
				@labels[@current_label] += "#{line}\n"
			end
		end
		data = nil
		@current_label = @label_order[0]
		@thread_group = ThreadGroup.new
		@@running.push(self)
		return self
	end
end

class ScriptBinder
	def create_block
		Proc.new { }
	end
end

class Settings
	@@hash ||= {}
	@@auto ||= false
	@@stamp ||= Hash.new
	def Settings.auto=(val)
		@@auto = val
	end
	def Settings.auto
		@@auto
	end
	def Settings.save
		if script = Script.self
			if script.to_s == 'lich'
				respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use Settings, because it will conflict with Lich\'s settings.'
				return false
			end
			@@hash[script.to_s] ||= Hash.new
			File.open($data_dir + script.to_s + '.sav', 'wb') { |f|
				f.write(Marshal.dump(@@hash[script.to_s]))
			}
		else
			respond "--- Lich: The script trying to save its data cannot be identified!"
			return false
		end
	end
	def Settings.autoload
		if Script.self.to_s == 'lich'
			respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use Settings, because it will conflict with Lich\'s settings.'
			return false
		end
		fname = $data_dir + Script.self.to_s + '.sav'
		if File.mtime(fname) > @@stamp[Script.self.to_s]
			Settings.load
			true
		else
			false
		end
	end
	def Settings.load(who = nil)
		@@stamp[Script.self.to_s] = Time.now
		if !who.nil?
			who.concat('.sav') unless who =~ /\.sav$/i
			if File.exists?("#{$data_dir}who")
				begin
					File.open("#{$data_dir}who", 'rb') { |f|
						@@hash[who.sub(/\..*/, '')] = Marshal.load(f.read)
					}
				rescue
					$stdout.puts "--- error: Settings.load: #{$!}"
					$stderr.puts "error: Settings.load: #{$!}"
					$stderr.puts $!.backtrace
				end
			else
				nil
			end
		elsif script = Script.self
			if script.to_s == 'lich'
				respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use the Settings class, because it will conflict with Lich\'s settings.'
				return false
			end
			if File.exists?($data_dir + script.to_s + ".sav")
				begin
					File.open($data_dir + script.to_s + '.sav', 'rb') { |f|
						data = Marshal.load(f.read)
						@@hash[script.to_s] = data
					}
				rescue
					$stdout.puts "--- error: Settings.load: #{$!}"
					$stderr.puts "error: Settings.load: #{$!}"
					$stderr.puts $!.backtrace
				end
			else
				nil
			end
		else
			respond "--- Lich: The script trying to save its data cannot be identified!"
			return false
		end
	end
	def Settings.clear
		unless script = Script.self
			respond "--- Lich: The script trying to access settings cannot be identified!"
			return false
		end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s].clear
	end
	def Settings.[](val)
		Settings.autoload if @@auto
		unless script = Script.self
			respond "--- Lich: The script trying to access settings cannot be identified!"
			return nil
		end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s][val]
	end
	def Settings.[]=(setting, val)
		unless script = Script.self
			respond "--- Lich: The script trying to access settings cannot be identified!"
			return nil
		end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s][setting] = val
		Settings.save if @@auto
		@@hash[script.to_s][setting]
	end
	def Settings.to_hash
		unless script = Script.self
			respond "--- Lich: The script trying to access settings cannot be identified!"
			return nil
		end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s]
	end
end

class String
	def split_as_list
		string = self
		string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
		string.sub('.','').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
	end
end
	
class Char
	@@cha ||= nil
	@@name ||= nil
	@@citizenship ||= nil
	private_class_method :new
	def Char.init(blah)
		echo 'Char.init is no longer used.  Update or fix your script.'
	end
	def Char.name
		XMLData.name
	end
	def Char.name=(name)
		# fixme
		# @@name = name
		nil
	end
	def Char.health(*args)
		health(*args)
	end
	def Char.mana(*args)
		checkmana(*args)
	end
	def Char.spirit(*args)
		checkspirit(*args)
	end
	def Char.maxhealth
		Object.module_eval { maxhealth }
	end
	def Char.maxmana
		Object.module_eval { maxmana }
	end
	def Char.maxspirit
		Object.module_eval { maxspirit }
	end
	def Char.stamina(*args)
		checkstamina(*args)
	end
	def Char.maxstamina
		Object.module_eval { maxstamina }
	end
	def Char.cha(val=nil)
		val == nil ? @@cha : @@cha = val
	end
	def Char.dump_info
		Marshal.dump([
			Spell.detailed?,
			Spell.serialize,
			Spellsong.serialize,
			Stats.serialize,
			Skills.serialize,
			Spells.serialize,
			Gift.serialize,
			Society.serialize,
		])
	end
	def Char.load_info(string)
		save = Char.dump_info
		begin
			Spell.load_detailed,
			Spell.load_active,
			Spellsong.load_serialized,
			Stats.load_serialized,
			Skills.load_serialized,
			Spells.load_serialized,
			Gift.load_serialized,
			Society.load_serialized = Marshal.load(string)
		rescue
			raise $! if string == save
			string = save
			retry
		end
	end
	def Char.method_missing(meth, *args)
		[ Stats, Skills, Spellsong, Society ].each { |klass|
			begin
				result = klass.__send__(meth, *args)
				return result
			rescue
			end
		}
		raise NoMethodError
	end
	def Char.info
		ary = []
		ary.push sprintf("Name: %s  Race: %s  Profession: %s", Char.name, Stats.race, Stats.prof)
		ary.push sprintf("Gender: %s    Age: %d    Expr: %d    Level: %d", Stats.gender, Stats.age, Stats.exp, Stats.level)
		ary.push sprintf("%017.17s Normal (Bonus)  ...  Enhanced (Bonus)", "")
		%w[ Strength Constitution Dexterity Agility Discipline Aura Logic Intuition Wisdom Influence ].each { |stat|
			val, bon = Stats.send(stat[0..2].downcase)
			spc = " " * (4 - bon.to_s.length)
			ary.push sprintf("%012s (%s): %05s (%d) %s ... %05s (%d)", stat, stat[0..2].upcase, val, bon, spc, val, bon)
		}
		ary.push sprintf("Mana: %04s", mana)
		ary
	end
	def Char.skills
		ary = []
		ary.push sprintf("%s (at level %d), your current skill bonuses and ranks (including all modifiers) are:", Char.name, Stats.level)
		ary.push sprintf("  %-035s| Current Current", 'Skill Name')
		ary.push sprintf("  %-035s|%08s%08s", '', 'Bonus', 'Ranks')
		fmt = [ [ 'Two Weapon Combat', 'Armor Use', 'Shield Use', 'Combat Maneuvers', 'Edged Weapons', 'Blunt Weapons', 'Two-Handed Weapons', 'Ranged Weapons', 'Thrown Weapons', 'Polearm Weapons', 'Brawling', 'Ambush', 'Multi Opponent Combat', 'Combat Leadership', 'Physical Fitness', 'Dodging', 'Arcane Symbols', 'Magic Item Use', 'Spell Aiming', 'Harness Power', 'Elemental Mana Control', 'Mental Mana Control', 'Spirit Mana Control', 'Elemental Lore - Air', 'Elemental Lore - Earth', 'Elemental Lore - Fire', 'Elemental Lore - Water', 'Spiritual Lore - Blessings', 'Spiritual Lore - Religion', 'Spiritual Lore - Summoning', 'Sorcerous Lore - Demonology', 'Sorcerous Lore - Necromancy', 'Mental Lore - Divination', 'Mental Lore - Manipulation', 'Mental Lore - Telepathy', 'Mental Lore - Transference', 'Mental Lore - Transformation', 'Survival', 'Disarming Traps', 'Picking Locks', 'Stalking and Hiding', 'Perception', 'Climbing', 'Swimming', 'First Aid', 'Trading', 'Pickpocketing' ], [ 'twoweaponcombat', 'armoruse', 'shielduse', 'combatmaneuvers', 'edgedweapons', 'bluntweapons', 'twohandedweapons', 'rangedweapons', 'thrownweapons', 'polearmweapons', 'brawling', 'ambush', 'multiopponentcombat', 'combatleadership', 'physicalfitness', 'dodging', 'arcanesymbols', 'magicitemuse', 'spellaiming', 'harnesspower', 'emc', 'mmc', 'smc', 'elair', 'elearth', 'elfire', 'elwater', 'slblessings', 'slreligion', 'slsummoning', 'sldemonology', 'slnecromancy', 'mldivination', 'mlmanipulation', 'mltelepathy', 'mltransference', 'mltransformation', 'survival', 'disarmingtraps', 'pickinglocks', 'stalkingandhiding', 'perception', 'climbing', 'swimming', 'firstaid', 'trading', 'pickpocketing' ] ]
		0.upto(fmt.first.length - 1) { |n|
			dots = '.' * (35 - fmt[0][n].length)
			rnk = Skills.send(fmt[1][n])
			ary.push sprintf("  %s%s|%08s%08s", fmt[0][n], dots, Skills.to_bonus(rnk), rnk) unless rnk.zero?
		}
		%[Minor Elemental,Major Elemental,Minor Spirit,Major Spirit,Bard,Cleric,Empath,Paladin,Ranger,Sorcerer,Wizard].split(',').each { |circ|
			rnk = Spells.send(circ.gsub(" ", '').downcase)
			if rnk.nonzero?
				ary.push ''
				ary.push "Spell Lists"
				dots = '.' * (35 - circ.length)
				ary.push sprintf("  %s%s|%016s", circ, dots, rnk)
			end
		}
		ary
	end
	def Char.citizenship
		@@citizenship
	end
	def Char.citizenship=(val)
		@@citizenship = val.to_s
	end
end

class Society
	@@status ||= String.new
	@@rank ||= 0
	def Society.serialize
		[@@status,@@rank]
	end
	def Society.load_serialized=(val)
		@@status,@@rank = val
	end
	def Society.status=(val)
		@@status = val
	end
	def Society.status
		@@status.dup
	end
	def Society.rank=(val)
		if val =~ /Master/
			if @@status =~ /Voln/
				@@rank = 26
			elsif @@status =~ /Council of Light|Guardians of Sunfist/
				@@rank = 20
			else
				@@rank = val.to_i
			end
		else
			@@rank = val.slice(/[0-9]+/).to_i
		end
	end
	def Society.step
		@@rank
	end
	def Society.member
		@@status.dup
	end
	def Society.rank
		@@rank
	end
	def Society.task
		XMLData.society_task
	end
end

class Spellsong
	@@renewed ||= Time.at(Time.now.to_i - 1200)
	def Spellsong.renewed
		@@renewed = Time.now
	end
	def Spellsong.renewed=(val)
		@@renewed = val
	end
	def Spellsong.renewed_at
		@@renewed
	end
	def Spellsong.timeleft
		if Time.now - @@renewed > Spellsong.duration
			@@renewed = Time.now
		end
		(Spellsong.duration - (Time.now - @@renewed)) / "60.0".to_f
	end
	def Spellsong.serialize
		Spellsong.timeleft
	end
	def Spellsong.load_serialized=(old)
		Thread.new {
			n = 0
			while Stats.level == 0
				sleep "0.25".to_f
				n += 1
				break if n >= 4
			end
			unless n >= 4
				@@renewed = Time.at(Time.now.to_f - (Spellsong.duration - old * "60.00".to_f))
			else
				@@renewed = Time.now
			end
		}
		nil
	end
	def Spellsong.duration
		total = 120
		1.upto(Stats.level.to_i) { |n|
			if n < 26
				total += 4
			elsif n < 51
				total += 3
			elsif n < 76
				total += 2
			else
				total += 1
			end
		}
		(total + Stats.log[1].to_i + (Stats.inf[1].to_i * 3) + (Skills.mltelepathy.to_i * 2))
	end
	def Spellsong.tonisdodgebonus
		thresholds = [1,2,3,5,8,10,14,17,21,26,31,36,42,49,55,63,70,78,87,96]
		bonus = 20
		thresholds.each { |val| if Skills.elair >= val then bonus += 1 end }
		bonus
	end
	def Spellsong.tonishastebonus
		bonus = -1
		thresholds = [30,75]
		thresholds.each { |val| if Skills.elair >= val then bonus -= 1 end }
		bonus
	end
	def Spellsong.mirrorsdodgebonus
		20 + ((Spells.bard - 19) / 2).round
	end
	def Spellsong.mirrorscost
		[19 + ((Spells.bard - 19) / 5).truncate, 8 + ((Spells.bard - 19) / 10).truncate]
	end
	def Spellsong.depressionpushdown
		20 + Skills.mltelepathy
	end
	def Spellsong.depressionslow
		thresholds = [10,25,45,70,100]
		bonus = -2
		thresholds.each { |val| if Skills.mltelepathy >= val then bonus -= 1 end }
		bonus
	end
	def Spellsong.sonicarmordurability
		210 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
	end
	def Spellsong.sonicbladedurability
		160 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
	end
	def Spellsong.sonicweapondurability
		Spellsong.sonicbladedurability
	end
	def Spellsong.sonicshielddurability
		125 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
	end
	def Spellsong.sonicbonus
		(Spells.bard / 2).round
	end
	def Spellsong.sonicarmorbonus
		Spellsong.sonicbonus + 15
	end
	def Spellsong.sonicbladebonus
		Spellsong.sonicbonus + 10
	end
	def Spellsong.sonicweaponbonus
		Spellsong.sonicbladebonus
	end
	def Spellsong.sonicshieldbonus
		Spellsong.sonicbonus + 10
	end
	def Spellsong.valorbonus
		10 + (([Spells.bard, Stats.level].min - 10) / 2).round
	end
	def Spellsong.valorcost
		[10 + (Spellsong.valorbonus / 2), 3 + (Spellsong.valorbonus / 5)]
	end
	def Spellsong.luckcost
		[6 + ((Spells.bard - 6) / 4),(6 + ((Spells.bard - 6) / 4) / 2).round]
	end
	def Spellsong.holdingtargets
		1 + ((Spells.bard - 1) / 7).truncate
	end
	def Spellsong.manacost
		[18,15]
	end
	def Spellsong.fortcost
		[3,1]
	end
	def Spellsong.shieldcost
		[9,4]
	end
	def Spellsong.weaponcost
		[12,4]
	end
	def Spellsong.armorcost
		[14,5]
	end
	def Spellsong.swordcost
		[25,15]
	end
	def Spellsong.cost
		total = 0 
		total += Spellsong.fortcost[1] if Spell[1003].active? 
		total += Spellsong.luckcost[1] if Spell[1006].active? 
		total += Spellsong.shieldcost[1] if Spell[1009].active? 
		total += Spellsong.valorcost[1] if Spell[1010].active? 
		total += Spellsong.weaponcost[1] if Spell[1012].active? 
		total += Spellsong.armorcost[1] if Spell[1014].active? 
		total += Spellsong.manacost[1] if Spell[1018].active? 
		total += Spellsong.mirrorscost[1] if Spell[1019].active? 
		total += Spellsong.swordcost[1] if Spell[1025].active?
		return total
	end
end

class Skills
	@@twoweaponcombat ||= 0
	@@armoruse ||= 0
	@@shielduse ||= 0
	@@combatmaneuvers ||= 0
	@@edgedweapons ||= 0
	@@bluntweapons ||= 0
	@@twohandedweapons ||= 0
	@@rangedweapons ||= 0
	@@thrownweapons ||= 0
	@@polearmweapons ||= 0
	@@brawling ||= 0
	@@ambush ||= 0
	@@multiopponentcombat ||= 0
	@@combatleadership ||= 0
	@@physicalfitness ||= 0
	@@dodging ||= 0
	@@arcanesymbols ||= 0
	@@magicitemuse ||= 0
	@@spellaiming ||= 0
	@@harnesspower ||= 0
	@@emc ||= 0
	@@mmc ||= 0
	@@smc ||= 0
	@@elair ||= 0
	@@elearth ||= 0
	@@elfire ||= 0
	@@elwater ||= 0
	@@slblessings ||= 0
	@@slreligion ||= 0
	@@slsummoning ||= 0
	@@sldemonology ||= 0
	@@slnecromancy ||= 0
	@@mldivination ||= 0
	@@mlmanipulation ||= 0
	@@mltelepathy ||= 0
	@@mltransference ||= 0
	@@mltransformation ||= 0
	@@survival ||= 0
	@@disarmingtraps ||= 0
	@@pickinglocks ||= 0
	@@stalkingandhiding ||= 0
	@@perception ||= 0
	@@climbing ||= 0
	@@swimming ||= 0
	@@firstaid ||= 0
	@@trading ||= 0
	@@pickpocketing ||= 0
	def Skills.serialize
		[@@twoweaponcombat, @@armoruse, @@shielduse, @@combatmaneuvers, @@edgedweapons, @@bluntweapons, @@twohandedweapons, @@rangedweapons, @@thrownweapons, @@polearmweapons, @@brawling, @@ambush, @@multiopponentcombat, @@combatleadership, @@physicalfitness, @@dodging, @@arcanesymbols, @@magicitemuse, @@spellaiming, @@harnesspower, @@emc, @@mmc, @@smc, @@elair, @@elearth, @@elfire, @@elwater, @@slblessings, @@slreligion, @@slsummoning, @@sldemonology, @@slnecromancy, @@mldivination, @@mlmanipulation, @@mltelepathy, @@mltransference, @@mltransformation, @@survival, @@disarmingtraps, @@pickinglocks, @@stalkingandhiding, @@perception, @@climbing, @@swimming, @@firstaid, @@trading, @@pickpocketing]
	end
	def Skills.load_serialized=(array)
		@@twoweaponcombat, @@armoruse, @@shielduse, @@combatmaneuvers, @@edgedweapons, @@bluntweapons, @@twohandedweapons, @@rangedweapons, @@thrownweapons, @@polearmweapons, @@brawling, @@ambush, @@multiopponentcombat, @@combatleadership, @@physicalfitness, @@dodging, @@arcanesymbols, @@magicitemuse, @@spellaiming, @@harnesspower, @@emc, @@mmc, @@smc, @@elair, @@elearth, @@elfire, @@elwater, @@slblessings, @@slreligion, @@slsummoning, @@sldemonology, @@slnecromancy, @@mldivination, @@mlmanipulation, @@mltelepathy, @@mltransference, @@mltransformation, @@survival, @@disarmingtraps, @@pickinglocks, @@stalkingandhiding, @@perception, @@climbing, @@swimming, @@firstaid, @@trading, @@pickpocketing = array
	end
	def Skills.method_missing(arg1, arg2='')
		instance_eval("@@#{arg1}#{arg2}", if Script.self then Script.self.name else "Lich" end)
	end
	def Skills.to_bonus(ranks)
		bonus = 0
		while ranks > 0
			if ranks > 40
				bonus += (ranks - 40)
				ranks = 40
			elsif ranks > 30
				bonus += (ranks - 30) * 2
				ranks = 30
			elsif ranks > 20
				bonus += (ranks - 20) * 3
				ranks = 20
			elsif ranks > 10
				bonus += (ranks - 10) * 4
				ranks = 10
			else
				bonus += (ranks * 5)
				ranks = 0
			end
		end
		bonus
	end
end

class Spells
	@@minorelemental ||= 0
	@@majorelemental ||= 0
	@@minorspiritual ||= 0
	@@majorspiritual ||= 0
	@@wizard ||= 0
	@@sorcerer ||= 0
	@@ranger ||= 0
	@@paladin ||= 0
	@@empath ||= 0
	@@cleric ||= 0
	@@bard ||= 0
	def Spells.method_missing(arg1, arg2='')
		instance_eval("@@#{arg1}#{arg2}")
	end
	def Spells.minorspirit
		@@minorspiritual
	end
	def Spells.minorspirit=(val)
		@@minorspiritual = val
	end
	def Spells.majorspirit
		@@majorspiritual
	end
	def Spells.majorspirit=(val)
		@@majorspiritual = val
	end
	def Spells.get_circle_name(num)
		val = num.to_s
		if val == '1' then 'Minor Spirit'
		elsif val == '2' then 'Major Spirit'
		elsif val == '3' then 'Cleric'
		elsif val == '4' then 'Minor Elemental'
		elsif val == '5' then 'Major Elemental'
		elsif val == '6' then 'Ranger'
		elsif val == '7' then 'Sorcerer'
		elsif val == '9' then 'Wizard'
		elsif val == '10' then 'Bard'
		elsif val == '11' then 'Empath'
		elsif val == '16' then 'Paladin'
		elsif val == '17' then 'Arcane'
		elsif val == '66' then 'Death'
		elsif val == '65' then 'Imbedded Enchantment'
		elsif val == '90' then 'Miscellaneous'
		elsif val == '96' then 'Combat Maneuvers'
		elsif val == '97' then 'Guardians of Sunfist'
		elsif val == '98' then 'Order of Voln'
		elsif val == '99' then 'Council of Light'
		else 'Unknown Circle' end
	end
	def Spells.active
		Spell.active
	end
	def Spells.known
		known_spells = Array.new
		Spell.list.each { |spell| known_spells.push(spell) if spell.known? }
		return known_spells
	end
	def Spells.serialize
		[@@minorelemental,@@majorelemental,@@minorspiritual,@@majorspiritual,@@wizard,@@sorcerer,@@ranger,@@paladin,@@empath,@@cleric,@@bard]
	end
	def Spells.load_serialized=(val)
		@@minorelemental,@@majorelemental,@@minorspiritual,@@majorspiritual,@@wizard,@@sorcerer,@@ranger,@@paladin,@@empath,@@cleric,@@bard = val
	end
end

class CMan
	def CMan.method_missing(arg1, arg2='')
		if arg2.class == Array
			instance_eval("@@#{arg1}[#{arg2.join(',')}]", if Script.self then Script.self.name else "Lich" end)
		elsif arg2.to_s =~ /^\d+$/
			instance_eval("@@#{arg1}#{arg2}", if Script.self then Script.self.name else "Lich" end)
		elsif arg2.empty?
			begin
				instance_eval("@@#{arg1}", if Script.self then Script.self.name else "Lich" end)
			rescue
				nil
			end
		else
			instance_eval("@@#{arg1}'#{arg2}'", if Script.self then Script.self.name else "Lich" end)
		end
	end
end

class Spell
	@@list ||= Array.new
	@@cast_lock = false
	attr_reader :timestamp, :num, :name, :duration, :timeleft, :msgup, :msgdn, :stacks, :circle, :circlename, :selfonly, :manaCost, :spiritCost, :staminaCost, :renewCost, :boltAS, :physicalAS, :boltDS, :physicalDS, :elementalCS, :spiritCS, :sorcererCS, :elementalTD, :spiritTD, :sorcererTD, :strength, :dodging, :active, :type, :command
	attr_accessor :stance, :channel
	def initialize(num,name,type,duration,manaCost,spiritCost,staminaCost,renewCost,stacks,selfonly,command,msgup,msgdn,boltAS,physicalAS,boltDS,physicalDS,elementalCS,spiritCS,sorcererCS,elementalTD,spiritTD,sorcererTD,strength,dodging,stance,channel)
		@name,@type,@duration,@manaCost,@spiritCost,@staminaCost,@renewCost,@stacks,@selfonly,@command,@msgup,@msgdn,@boltAS,@physicalAS,@boltDS,@physicalDS,@elementalCS,@spiritCS,@sorcererCS,@elementalTD,@spiritTD,@sorcererTD,@strength,@dodging,@stance,@channel = name,type,duration,manaCost,spiritCost,staminaCost,renewCost,stacks,selfonly,command,msgup,msgdn,boltAS,physicalAS,boltDS,physicalDS,elementalCS,spiritCS,sorcererCS,elementalTD,spiritTD,sorcererTD,strength,dodging,stance,channel
		if num.to_i.nonzero? then @num = num.to_i else @num = num end
		@timestamp = Time.now
		@active = false
		@timeleft = 0
		@msgup = msgup
		@msgdn = msgdn
		@circle = (num.to_s.length == 3 ? num.to_s[0..0] : num.to_s[0..1])
		@circlename = Spells.get_circle_name(@circle)
		@@list.push(self) unless @@list.find { |spell| spell.num == @num }
	end
	def Spell.load(filename="#{$script_dir}spell-list.xml.txt")
		begin
			@@list.clear
			File.open(filename) { |file|
				file.read.split(/<\/spell>.*?<spell>/m).each { |spell_data|
					spell = Hash.new
					spell_data.split("\n").each { |line| if line =~ /<(number|name|type|duration|manaCost|spiritCost|staminaCost|renewCost|stacks|command|selfonly|msgup|msgdown|boltAS|physicalAS|boltDS|physicalDS|elementalCS|spiritCS|sorcererCS|elementalTD|spiritTD|sorcererTD|strength|dodging|stance|channel)[^>]*>([^<]*)<\/\1>/ then spell[$1] = $2 end }
					Spell.new(spell['number'],spell['name'],spell['type'],(spell['duration'] || '0'),(spell['manaCost'] || '0'),(spell['spiritCost'] || '0'),(spell['staminaCost'] || '0'),(spell['renewCost'] || '0'),(if spell['stacks'] and spell['stacks'] != 'false' then true else false end),(if spell['selfonly'] and spell['selfonly'] != 'false' then true else false end),spell['command'],spell['msgup'],spell['msgdown'],(spell['boltAS'] || '0'),(spell['physicalAS'] || '0'),(spell['boltDS'] || '0'),(spell['physicalDS'] || '0'),(spell['elementalCS'] || '0'),(spell['spiritCS'] || '0'),(spell['sorcererCS'] || '0'),(spell['elementalTD'] || '0'),(spell['spiritTD'] || '0'),(spell['sorcererTD'] || '0'),(spell['strength'] || '0'),(spell['dodging'] || '0'),(if spell['stance'] and spell['stance'] != 'false' then true else false end),(if spell['channel'] and spell['channel'] != 'false' then true else false end))
				}
			}
			return true
		rescue
			$stdout.puts "--- error: Spell.load: #{$!}"
			$stderr.puts "error: Spell.load: #{$!}"
			$stderr.puts $!.backtrace
			return false
		end
	end
	def Spell.[](val)
		Spell.load if @@list.empty?
		if val.class == Spell
			val
		elsif (val.class == Fixnum) or (val.class == String and val =~ /^[0-9]+$/)
			@@list.find { |spell| spell.num == val.to_i }
		else
			if (ret = @@list.find { |spell| spell.name =~ /^#{val}$/i })
				ret
			elsif (ret = @@list.find { |spell| spell.name =~ /^#{val}/i })
				ret
			else
				@@list.find { |spell| spell.msgup =~ /#{val}/i or spell.msgdn =~ /#{val}/i }
			end
		end
	end
	def Spell.active
		Spell.load if @@list.empty?
		active = Array.new
		@@list.each { |spell| active.push(spell) if spell.active? }
		active
	end
	def Spell.active?(val)
		Spell.load if @@list.empty?
		Spell[val].active?
	end
	def Spell.list
		Spell.load if @@list.empty?
		@@list
	end
	def Spell.upmsgs
		Spell.load if @@list.empty?
		@@list.collect { |spell| spell.msgup }
	end
	def Spell.dnmsgs
		Spell.load if @@list.empty?
		@@list.collect { |spell| spell.msgdn }
	end
	def timeleft
		# this is just a copy and paste of the "touch" function.  For some reason, just calling touch here does not work correctly.
		if @duration.to_s == "Spellsong.timeleft"
			@timeleft = Spellsong.timeleft
		else
			@timeleft = @timeleft - ((Time.now - @timestamp) / "60.00".to_f)
			if @timeleft.to_f <= 0
				self.putdown
				return 0.0
			end
		end
		@timestamp = Time.now
		@timeleft
	end
	def active=(val)
		@active = val
	end
	def active?
		touch
		@active
	end
	def known?
		if @num.to_s.length == 3
			circle_num = @num.to_s[0..0].to_i
		elsif @num.to_s.length == 4
			circle_num = @num.to_s[0..1].to_i
		else
			return false
		end
		if circle_num == 1
			ranks = Spells.minorspiritual
		elsif circle_num == 2
			ranks = Spells.majorspiritual
		elsif circle_num == 3
			ranks = Spells.cleric
		elsif circle_num == 4
			ranks = Spells.minorelemental
		elsif circle_num == 5
			ranks = Spells.majorelemental
		elsif circle_num == 6
			ranks = Spells.ranger
		elsif circle_num == 7
			ranks = Spells.sorcerer
		elsif circle_num == 9
			ranks = Spells.wizard
		elsif circle_num == 10
			ranks = Spells.bard
		elsif circle_num == 11
			ranks = Spells.empath
		elsif circle_num == 16
			ranks = Spells.paladin
		elsif (circle_num == 97) and (Society.status == 'Guardians of Sunfist')
			ranks = Society.rank
		elsif (circle_num == 98) and (Society.status == 'Order of Voln')
			ranks = Society.rank
		elsif (circle_num == 99) and (Society.status == 'Council of Light')
			ranks = Society.rank
		else
			return false
		end
		if @num.to_s[-2..-1].to_i <= ranks
			return true
		else
			return false
		end
	end
	def timeleft=(val)
		touch
		@timeleft = val
		@timestamp = Time.now
	end
	def touch
		if @duration.to_s == "Spellsong.timeleft"
			@timeleft = Spellsong.timeleft
		else
			@timeleft = @timeleft - ((Time.now - @timestamp) / "60.00".to_f)
			if @timeleft.to_f <= 0
				self.putdown
				return 0.0
			end
		end
		@timestamp = Time.now
		@timeleft
	end
	def minsleft
		touch
	end
	def secsleft
		touch * 60
	end
	def to_s
		@name.to_s
	end
	def putup
		touch
		@stacks ? @timeleft += eval(@duration).to_f : @timeleft = eval(@duration).to_f
		if (@num == 9710) or (@num == 9711) or (@num == 9719)
			if @timeleft > 3 then @timeleft = 2.983 end
		else
			if @timeleft > 250 then @timeleft = 249.983 end
		end
		@active = true
	end
	def putdown
		@active = false
		@timeleft = 0
		@timestamp = Time.now
	end
	def remaining
		self.touch.as_time
	end
	def cost
		@manaCost
	end
	def affordable?
		return false if Spell[9699].active? and (eval(@staminaCost).to_i > 0)
		mana(eval(@manaCost).to_i) and checkspirit(eval(@spiritCost).to_i + 1 + (if checkspell(9912) then 1 else 0 end) + (if checkspell(9913) then 1 else 0 end) + (if checkspell(9914) then 1 else 0 end) + (if checkspell(9916) then 5 else 0 end)) and checkstamina(eval(@staminaCost).to_i)
	end
	def cast(target=nil)
		if @type.nil?
			echo "cast: spell missing type (#{@name})"
			return false
		end
		unless checkmana(eval(@manaCost))
			echo 'cast: not enough mana'
			return false
		end
		unless checkspirit(eval(@spiritCost) + 1 + (if checkspell(9912) then 1 else 0 end) + (if checkspell(9913) then 1 else 0 end) + (if checkspell(9914) then 1 else 0 end) + (if checkspell(9916) then 5 else 0 end))
			echo 'cast: not enough spirit'
			return false
		end
		unless checkstamina(eval(@staminaCost))
			echo 'cast: not enough stamina'
			return false
		end
		wait_while { @@cast_lock and (locking_script = (Script.hidden + Script.running).find { |s| s.name == @@cast_lock }) and not locking_script.paused and (locking_script.name != Script.self.name) }
		@@cast_lock = Script.self.name
		# fixme: check mana/stamina/spirit again
		if @command
			waitrt?
			waitcastrt?
			fput @command
			@@cast_lock = false
		else
			if @channel
				cast_cmd = 'channel'
			else
				cast_cmd = 'cast'
			end
			if (target.nil? or target.empty?) and (@type =~ /attack/i)
				cast_cmd += ' target'
			else
				cast_cmd += " #{target}"
			end
			waitrt?
			waitcastrt?
			unless checkprep == @name
				unless checkprep == 'None'
					dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
					unless checkmana(eval(@manaCost))
						@@cast_lock = false
						echo 'cast: not enough mana'
						return false
					end
					unless checkspirit(eval(@spiritCost) + 1 + (if checkspell(9912) then 1 else 0 end) + (if checkspell(9913) then 1 else 0 end) + (if checkspell(9914) then 1 else 0 end) + (if checkspell(9916) then 5 else 0 end))
						@@cast_lock = false
						echo 'cast: not enough spirit'
						return false
					end
					unless checkstamina(eval(@staminaCost))
						@@cast_lock = false
						echo 'cast: not enough stamina'
						return false
					end
				end
				loop {
					waitrt?
					waitcastrt?
					prepare_result = dothistimeout "prepare #{@num}", 8, /^You already have a spell readied!  You must RELEASE it if you wish to prepare another!$|^Your spell(?:song)? is ready\.|^You can't think clearly enough to prepare a spell!$|^You are concentrating too intently .*?to prepare a spell\.$|^You are too injured to make that dextrous of a movement|^The searing pain in your throat makes that impossible|^But you don't have any mana!\.$/
					if prepare_result =~ /^Your spell(?:song)? is ready\./
						break
					elsif prepare_result == 'You already have a spell readied!  You must RELEASE it if you wish to prepare another!'
						dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
						unless checkmana(eval(@manaCost))
							echo 'cast: not enough mana'
							$cast_lock = false
							return false
						end
					elsif prepare_result =~ /^You can't think clearly enough to prepare a spell!$|^You are concentrating too intently .*?to prepare a spell\.$|^You are too injured to make that dextrous of a movement|^The searing pain in your throat makes that impossible|^But you don't have any mana!\.$/
						$cast_lock = false
						return false
					end
				}
			end
			if @stance and checkstance != 'offensive'
				dothistimeout 'stance offensive', 5, /^You are now in an offensive stance\.$|^You are unable to change your stance\.$/
			end
			cast_result = dothistimeout cast_cmd, 5, /^(?:Cast|Sing) Roundtime [0-9]+ Seconds\.$|^Cast at what\?$|^But you don't have any mana!$|Spell Hindrance for|^You don't have a spell prepared!$|keeps? the spell from working\.|^Be at peace my child, there is no need for spells of war in here\.$|Spells of War cannot be cast|^As you focus on your magic, your vision swims with a swirling haze of crimson\.$/
			if @stance and checkstance !~ /^guarded$|^defensive$/
				dothistimeout 'stance guarded', 5, /^You are now in an? \w+ stance\.$|^You are unable to change your stance\.$/
			end
			if cast_result == 'Cast at what?'
				dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
			end
			@@cast_lock = false
			cast_result
		end
	end
end

class Stats
	@@race ||= 'unknown'
	@@prof ||= 'unknown'
	@@gender ||= 'unknown'
	@@age ||= 0
	@@exp ||= 0
	@@level ||= 0
	@@str ||= [0,0]
	@@con ||= [0,0]
	@@dex ||= [0,0]
	@@agi ||= [0,0]
	@@dis ||= [0,0]
	@@aur ||= [0,0]
	@@log ||= [0,0]
	@@int ||= [0,0]
	@@wis ||= [0,0]
	@@inf ||= [0,0]
	def Stats.method_missing(arg1, arg2='')
		if arg2.class == Array
			instance_eval("@@#{arg1}[#{arg2.join(',')}]", if Script.self then Script.self.name else "Lich" end)
		elsif arg2.to_s =~ /^\d+$/
			instance_eval("@@#{arg1}#{arg2}", if Script.self then Script.self.name else "Lich" end)
		elsif arg2.empty?
			instance_eval("@@#{arg1}", if Script.self then Script.self.name else "Lich" end)
		else
			instance_eval("@@#{arg1}'#{arg2}'", if Script.self then Script.self.name else "Lich" end)
		end
	end
	def Stats.serialize
		[@@race,@@prof,@@gender,@@age,@@exp,@@level,@@str,@@con,@@dex,@@agi,@@dis,@@aur,@@log,@@int,@@wis,@@inf]
	end
	def Stats.load_serialized=(array)
		@@race,@@prof,@@gender,@@age,@@exp,@@level,@@str,@@con,@@dex,@@agi,@@dis,@@aur,@@log,@@int,@@wis,@@inf = array
	end
end

class Gift
	@@gift_start ||= Time.now
	@@pulse_count ||= 0
	def Gift.started
		@@gift_start = Time.now
		@@pulse_count = 0
	end
	def Gift.pulse
		@@pulse_count += 1
	end
	def Gift.remaining
		([360 - @@pulse_count, 0].max * 60).to_f
	end
	def Gift.restarts_on
		@@gift_start + 604800
	end
	def Gift.serialize
		[@@gift_start, @@pulse_count]
	end
	def Gift.load_serialized=(array)
		@@gift_start = array[0]
		@@pulse_count = array[1].to_i
	end
	def Gift.ended
		@@pulse_count = 360
	end
	def Gift.stopwatch
		nil
	end
end

class Wounds
	def Wounds.method_missing(arg)
		arg = arg.to_s
		fix_injury_mode
		fix_name = { 'nerves' => 'nsys', 'lleg' => 'leftLeg', 'rleg' => 'rightLeg', 'rarm' => 'rightArm', 'larm' => 'leftArm', 'rhand' => 'rightHand', 'lhand' => 'leftHand', 'reye' => 'rightEye', 'leye' => 'leftEye', 'abs' => 'abdomen' }
		if XMLData.injuries[arg]['wound']
			XMLData.injuries[arg]['wound']
		elsif XMLData.injuries[fix_name[arg]]['wound']
			XMLData.injuries[fix_name[arg]]['wound']
		else
			echo 'Wounds: Invalid area, try one of these: arms, limbs, torso, ' + XMLData.injuries.keys.join(', ')
			nil
		end
	end
	def Wounds.arms
		fix_injury_mode
		[XMLData.injuries['leftArm']['wound'],XMLData.injuries['rightArm']['wound'],XMLData.injuries['leftHand']['wound'],XMLData.injuries['rightHand']['wound']].max
	end
	def Wounds.limbs
		fix_injury_mode
		[XMLData.injuries['leftArm']['wound'],XMLData.injuries['rightArm']['wound'],XMLData.injuries['leftHand']['wound'],XMLData.injuries['rightHand']['wound'],XMLData.injuries['leftLeg']['wound'],XMLData.injuries['rightLeg']['wound']].max
	end
	def Wounds.torso
		fix_injury_mode
		[XMLData.injuries['rightEye']['wound'],XMLData.injuries['leftEye']['wound'],XMLData.injuries['chest']['wound'],XMLData.injuries['abdomen']['wound'],XMLData.injuries['back']['wound']].max
	end
end

class Scars
	def Scars.method_missing(arg)
		arg = arg.to_s
		fix_injury_mode
		fix_name = { 'nerves' => 'nsys', 'lleg' => 'leftLeg', 'rleg' => 'rightLeg', 'rarm' => 'rightArm', 'larm' => 'leftArm', 'rhand' => 'rightHand', 'lhand' => 'leftHand', 'reye' => 'rightEye', 'leye' => 'leftEye', 'abs' => 'abdomen' }
		if XMLData.injuries[arg]['scar']
			XMLData.injuries[arg]['scar']
		elsif XMLData.injuries[fix_name[arg]]['scar']
			XMLData.injuries[fix_name[arg]]['scar']
		else
			echo 'Scars: Invalid area, try one of these: arms, limbs, torso, ' + XMLData.injuries.keys.join(', ')
			nil
		end
	end
	def Scars.arms
		fix_injury_mode
		[XMLData.injuries['leftArm']['scar'],XMLData.injuries['rightArm']['scar'],XMLData.injuries['leftHand']['scar'],XMLData.injuries['rightHand']['scar']].max
	end
	def Scars.limbs
		fix_injury_mode
		[XMLData.injuries['leftArm']['scar'],XMLData.injuries['rightArm']['scar'],XMLData.injuries['leftHand']['scar'],XMLData.injuries['rightHand']['scar'],XMLData.injuries['leftLeg']['scar'],XMLData.injuries['rightLeg']['scar']].max
	end
	def Scars.torso
		fix_injury_mode
		[XMLData.injuries['rightEye']['scar'],XMLData.injuries['leftEye']['scar'],XMLData.injuries['chest']['scar'],XMLData.injuries['abdomen']['scar'],XMLData.injuries['back']['scar']].max
	end
end

class Watchfor
	def Watchfor.method_missing(*args)
		nil
	end
end

class GameObj
	@@loot ||= Array.new
	@@npcs ||= Array.new
	@@pcs ||= Array.new
	@@inv ||= Array.new
	@@contents ||= Hash.new
	@@right_hand ||= nil
	@@left_hand ||= nil
	@@room_desc ||= Array.new
	@@fam_loot ||= Array.new
	@@fam_npcs ||= Array.new
	@@fam_pcs ||= Array.new
	@@fam_room_desc ||= Array.new
	attr_reader :id
	attr_accessor :noun, :name, :status
	def initialize(id, noun, name, status=nil)
		@id = id
		@noun = noun
		@noun = 'lapis' if @noun == 'lapis lazuli'
		# fixme: 'mother-of-pearl' gives 'pearl' as the noun?
		@noun = 'mother-of-pearl' if (@noun == 'pearl') and (@name =~ /mother\-of\-pearl/)
		@name = name
		@status = status
	end
	def GameObj
		@noun
	end
	def to_s
		@noun
	end
	def empty?
		false
	end
	def GameObj.new_npc(id, noun, name, status=nil)
		obj = GameObj.new(id, noun, name, status)
		@@npcs.push(obj)
	end
	def GameObj.new_loot(id, noun, name)
		obj = GameObj.new(id, noun, name, nil)
		@@loot.push(obj)
	end
	def GameObj.new_pc(id, noun, name, status=nil)
		obj = GameObj.new(id, noun, name, status)
		@@pcs.push(obj)
	end
	def GameObj.new_inv(id, noun, name, container=nil)
		obj = GameObj.new(id, noun, name)
		if container
			@@contents[container].push(obj)
		else
			@@inv.push(obj)
		end
	end
	def GameObj.new_room_desc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@room_desc.push(obj)
	end
	def GameObj.new_fam_room_desc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_room_desc.push(obj)
	end
	def GameObj.new_fam_loot(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_loot.push(obj)
	end
	def GameObj.new_fam_npc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_npcs.push(obj)
	end
	def GameObj.new_fam_pc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_pcs.push(obj)
	end
	def GameObj.new_right_hand(id, noun, name)
		@@right_hand = GameObj.new(id, noun, name)
	end
	def GameObj.right_hand
		@@right_hand.dup
	end
	def GameObj.new_left_hand(id, noun, name)
		@@left_hand = GameObj.new(id, noun, name)
	end
	def GameObj.left_hand
		@@left_hand.dup
	end
	def GameObj.clear_loot
		@@loot.clear
	end
	def GameObj.clear_npcs
		@@npcs.clear
	end
	def GameObj.clear_pcs
		@@pcs.clear
	end
	def GameObj.clear_inv
		@@inv.clear
	end
	def GameObj.clear_room_desc
		@@room_desc.clear
	end
	def GameObj.clear_fam_room_desc
		@@fam_room_desc.clear
	end
	def GameObj.clear_fam_loot
		@@fam_loot.clear
	end
	def GameObj.clear_fam_npcs
		@@fam_npcs.clear
	end
	def GameObj.clear_fam_pcs
		@@fam_pcs.clear
	end
	def GameObj.npcs
		if @@npcs.empty?
			nil
		else
			@@npcs.dup
		end
	end
	def GameObj.loot
		if @@loot.empty?
			nil
		else
			@@loot.dup
		end
	end
	def GameObj.pcs
		if @@pcs.empty?
			nil
		else
			@@pcs.dup
		end
	end
	def GameObj.inv
		if @@inv.empty?
			nil
		else
			@@inv.dup
		end
	end
	def GameObj.room_desc
		if @@room_desc.empty?
			nil
		else
			@@room_desc.dup
		end
	end
	def GameObj.fam_room_desc
		if @@fam_room_desc.empty?
			nil
		else
			@@fam_room_desc.dup
		end
	end
	def GameObj.fam_loot
		if @@fam_loot.empty?
			nil
		else
			@@fam_loot.dup
		end
	end
	def GameObj.fam_npcs
		if @@fam_npcs.empty?
			nil
		else
			@@fam_npcs.dup
		end
	end
	def GameObj.fam_pcs
		if @@fam_pcs.empty?
			nil
		else
			@@fam_pcs.dup
		end
	end
	def GameObj.clear_container(container_id)
		@@contents[container_id] = Array.new
	end
	def GameObj.delete_container(container_id)
		@@contents.delete(container_id)
	end
	def GameObj.dead
		dead_list = Array.new
		for obj in @@npcs
			dead_list.push(obj) if obj.status == "dead"
		end
		return nil if dead_list.empty?
		return dead_list
	end
	def GameObj.containers
		@@contents.dup
	end
	def contents
		@@contents[@id].dup
	end
end

class RoomObj < GameObj
end

class Map
	@@list ||= Array.new
	attr_reader :id
	attr_accessor :title, :desc, :paths, :wayto, :timeto, :pause, :geo, :realcost, :searched, :nadj, :adj, :parent, :atlas_id, :map_name, :map_x, :map_y, :map_roomsize
	def initialize(id, title, desc, paths, wayto={}, timeto={}, geo=nil, pause = nil)
		@id, @title, @desc, @paths, @wayto, @timeto, @geo, @pause = id, title, desc, paths, wayto, timeto, geo, pause
		@@list[@id] = self
	end
	def Map.get_free_id
		Map.load if @@list.empty?
		free_id = 0
		free_id += 1 until @@list[free_id].nil?
		free_id
	end
	def Map.clear
		@@list.clear
	end
	def Map.uniq_new(id, title, desc, paths, wayto={}, timeto={}, geo=nil)
		# id ignored, but left in for backward compatability
		Map.load if @@list.empty?
		unless dupe_room = @@list.find { |room| room.title.include(title) and room.desc.include?(desc.strip) and room.paths.include?(paths) }
			return Map.new(Map.get_free_id, [title], [desc], [paths], wayto, timeto, geo)
		end
		return dupe_room
	end
	def Map.uniq!
		# fixme
		echo 'Map.uniq! called.  Doing nothing.'
		return false
	end
	def Map.list
		Map.load if @@list.empty?
		@@list
	end
	def Map.[](val)
		Map.load if @@list.empty?
		if (val.class == Fixnum) or (val.class == Bignum) or val =~ /^[0-9]+$/
			@@list[val.to_i]
		else
			chkre = /#{val.strip.sub(/\.$/, '').gsub(/\.(?:\.\.)?/, '|')}/i
			chk = /#{Regexp.escape(val.strip)}/i
			@@list.find { |room| room.title.find { |title| title =~ chk } } || @@list.find { |room| room.desc.find { |desc| desc =~ chk } } || @@list.find { |room| room.desc.find { |desc| desc =~ chkre } }
		end
	end
	def Map.current
		Map.load if @@list.empty?
		room = @@list.find { |room| room.title.include?(XMLData.room_title) and room.desc.include?(XMLData.room_description.strip) and room.paths.include?(XMLData.room_exits_string.strip) }
		unless room
			desc_regex = /#{Regexp.escape(XMLData.room_description.strip).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
			room = @@list.find { |room| room.title.include?(XMLData.room_title) and room.paths.include?(XMLData.room_exits_string.strip) and room.desc.find { |desc| desc =~ desc_regex } }
		end
		return room
	end
	def Map.reload
		@@list.clear
		Map.load
		GC.start
	end
	def Map.load(file=($script_dir.to_s + "map.dat"))
		unless File.exists?(file)
			raise Exception.exception("MapDatabaseError"), "Fatal error: file `#{file}' does not exist!"
		end
		fd = File.open(file, 'rb')
		@@list = Marshal.load(fd.read)
		fd.close
		fd = nil
		GC.start
		# try not to freak out if we load an old style map database
		if Map.list[0].desc.class == String
			Map.list.each { |room| room.desc = [ room.desc ] if room.desc.class == String }
		end
		if Map.list[0].title.class == String
			Map.list.each { |room| room.title = [ room.title ] if room.title.class == String }
		end
		if Map.list[0].paths.class == String
			Map.list.each { |room| room.paths = [ room.paths ] if room.paths.class == String }
		end
	end
	def Map.load_xml(filename=($script_dir.to_s + "map.xml"))
		unless File.exists?(filename)
			raise Exception.exception("MapDatabaseError"), "Fatal error: file `#{file}' does not exist!"
		end
		File.open(filename) { |file|
			file.read.split(/(?=<room)/).each { |room_tag|
				room = Hash.new
				room['wayto'] = Hash.new
				room['timeto'] = Hash.new
				room['title'] = Array.new
				room['description'] = Array.new
				room['paths'] = Array.new
				map_name, map_x, map_y, map_roomsize = nil, nil, nil, nil
				room_tag.split(/(?=<(?:\w|\/room))/).each { |line|
					if line =~ /<room\s+id=['"]([0-9]+)['"]>/
						room['id'] = $1
					elsif line =~ /<(title|description|paths)>(.*?)<\/\1>/
						room[$1].push($2.gsub('&gt;','>').gsub('&lt;','<'))
					elsif line =~ /<exit\s+target=['"](.*?)['"]\s+type=['"](.*?)['"]\s+cost=['"](.*?)['"]>(.*?)<\/exit>/m
						target, type, cost, way = $1, $2, $3, $4
						if type =~ /String/i
							room['wayto'][target] = way
						elsif type =~ /Proc/i
							room['wayto'][target] = StringProc.new(way.gsub('&gt;','>').gsub('&lt;','<'))
						end
						room['timeto'][target] = cost.to_f
					elsif line =~ /<(?:image|narost)\s+name=['"](.*?)['"]\s+x=['"]([0-9]+)['"]\s+y=['"]([0-9]+)['"]\s+size=['"]([0-9]+)['"]\s*\/>/
						map_name, map_x, map_y, map_roomsize = $1, $2.to_i, $3.to_i, $4.to_i
					elsif line =~ /<\/room>/
						new_room = Map.new(room['id'].to_i, room['title'], room['description'], room['paths'], room['wayto'], room['timeto'])
						new_room.map_name = map_name
						new_room.map_x = map_x
						new_room.map_y = map_y
						new_room.map_roomsize = map_roomsize
					end
				}
			}
		}
	end
	def Map.load_unique(file)
		Map.load if @@list.empty?
		nil
	end
	def Map.save(filename=($script_dir.to_s + 'map.dat'))
		if File.exists?(filename)
			respond "File exists!  Backing it up before proceeding..."
			begin
				file = nil
				bakfile = nil
				file = File.open(filename, 'rb')
				bakfile = File.open(filename + ".bak", "wb")
				bakfile.write(file.read)
			rescue
				respond $!
			ensure
				file ? file.close : nil
				bakfile ? bakfile.close : nil
			end
		end
		begin
			file = nil
			file = File.open(filename, 'wb')
			file.write(Marshal.dump(@@list))
			respond "The current map database has been saved!"
		rescue
			respond $!
		ensure
			file ? file.close : nil
		end
		GC.start
	end
	def Map.save_xml(filename=($script_dir.to_s + 'map.xml'))
		if File.exists?(filename)
			respond "File exists!  Backing it up before proceeding..."
			begin
				file = nil
				bakfile = nil
				file = File.open(filename, 'rb')
				bakfile = File.open(filename + ".bak", "wb")
				bakfile.write(file.read)
			rescue
				respond $!
			ensure
				file ? file.close : nil
				bakfile ? bakfile.close : nil
			end
		end
		begin
			file = nil
			file = File.open(filename, 'wb')
			@@list.each { |room|
				next if room == nil
				file.write "<room id=\"#{room.id}\">\n"
				room.title.each { |title| file.write "	<title>#{title.gsub('<', '&lt;').gsub('>', '&gt;')}</title>\n" }
				room.desc.each { |desc| file.write "	<description>#{desc.gsub('<', '&lt;').gsub('>', '&gt;')}</description>\n" }
				room.paths.each { |paths| file.write "	<paths>#{paths.gsub('<', '&lt;').gsub('>', '&gt;')}</paths>\n" }
				file.write "	<image name=\"#{room.map_name}\" x=\"#{room.map_x}\" y=\"#{room.map_y}\" size=\"#{room.map_roomsize}\" />\n" if room.map_name
				room.wayto.keys.each { |target|
					if room.timeto[target]
						cost = " cost=\"#{room.timeto[target]}\""
					else
						cost = ''
					end
					if room.wayto[target].class == Proc
						file.write "	<exit target=\"#{target}\" type=\"Proc\"#{cost}>#{room.wayto[target]._dump.gsub('<', '&lt;').gsub('>', '&gt;')}</exit>\n"
					else
						file.write "	<exit target=\"#{target}\" type=\"#{room.wayto[target].class}\"#{cost}>#{room.wayto[target].gsub('<', '&lt;').gsub('>', '&gt;')}</exit>\n"
					end
				}
				file.write "</room>\n"
			}
			respond "The current map database has been saved!"
		rescue
			respond $!
		ensure
			file ? file.close : nil
		end
		GC.start
	end
	def Map.smart_check
		Map.load if @@list.empty?
		error_rooms = []
		@@list.each { |room|
			if room.wayto.keys.include?(room.id.to_s)
				error_rooms.push("Room references itself as adjacent:\n#{room}")
			end
			room.wayto.dup.each { |torm, way|
				if way =~ /^(?:g |go )?(?:n|no|nor|nort|north)$/ and !(room.paths =~ /\bnorth,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:ne|northeast|northeas|northea|northe)$/ and !(room.paths =~ /\bnortheast,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:e|ea|eas|east)$/ and !(room.paths =~ /\beast,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:southeast|southeas|southea|southe)$/ and !(room.paths =~ /\bsoutheast,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:south|sout|sou|so|s)$/ and !(room.paths =~ /\bsouth,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:sw|southwest|southwes|southwe|southw)$/ and !(room.paths =~ /\bsouthwest,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:west|wes|we|w)$/ and !(room.paths =~ /\bwest,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:nw|northwest|northwes|northwe|northw)$/ and !(room.paths =~ /\bnorthwest,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:u|up)$/ and !(room.paths =~ /\bup,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				elsif way =~ /^(?:g |go )?(?:d|do|dow|down)$/ and !(room.paths =~ /\bdown,?\b/)
					puts("Dir error in room:\n#{room}\n... cannot reach room #{torm} by going #{way}!")
					room.wayto.delete(torm)
				end
			}
		}
		error_rooms
	end
	def Map.estimate_time(array)
		Map.load if @@list.empty?
		unless array.class == Array
			raise Exception.exception("MapError"), "Map.estimate_time was given something not an array!"
		end
		time = 0.00
		until array.length < 2
			room = array.shift
			if t = Map[room].timeto[array.first.to_s]
				time += t.to_f
			else
				time += 0.2
			end
		end
		time
	end
	def Map.findpath(source, destination)
		Map.load if @@list.empty?
		previous, shortest_distances = Map.dijkstra(source, destination)
		return nil unless previous[destination]
		path = [ destination ]
		path.push(previous[path[-1]]) until previous[path[-1]] == source
		path.reverse!
		path.pop
		return path
	end
	def Map.dijkstra(source, destination=nil)
		begin
			Map.load if @@list.empty?
			source = source.to_i
			visited = Array.new
			shortest_distances = Array.new
			previous = Array.new
			pq = [ source ]
			pq_push = proc { |val|
				for i in 0...pq.size
					if shortest_distances[val] <= shortest_distances[pq[i]]
						pq.insert(i, val)
						break
					end
				end
				pq.push(val) if i.nil? or (i == pq.size-1)
			}
			visited[source] = true
			shortest_distances[source] = 0
			if destination.nil?
				until pq.size == 0
					v = pq.shift
					visited[v] = true
					@@list[v].wayto.keys.each { |adj_room|
						adj_room_i = adj_room.to_i
						nd = shortest_distances[v] + (@@list[v].timeto[adj_room] || 0.2)
						if !visited[adj_room.to_i] and (shortest_distances[adj_room_i].nil? or shortest_distances[adj_room_i] > nd)
							shortest_distances[adj_room_i] = nd
							previous[adj_room_i] = v
							pq_push.call(adj_room_i)
						end
					}
				end
			elsif destination.class == Fixnum
				until pq.size == 0
					v = pq.shift
					break if v == destination
					visited[v] = true
					@@list[v].wayto.keys.each { |adj_room|
						adj_room_i = adj_room.to_i
						nd = shortest_distances[v] + (@@list[v].timeto[adj_room] || 0.2)
						if !visited[adj_room.to_i] and (shortest_distances[adj_room_i].nil? or shortest_distances[adj_room_i] > nd)
							shortest_distances[adj_room_i] = nd
							previous[adj_room_i] = v
							pq_push.call(adj_room_i)
						end
					}
				end
			elsif destination.class == Array
				dest_list = destination.collect { |dest| dest.to_i }
				until pq.size == 0
					v = pq.shift
					break if dest_list.include?(v) and (shortest_distances[v] < 20)
					visited[v] = true
					@@list[v].wayto.keys.each { |adj_room|
						adj_room_i = adj_room.to_i
						nd = shortest_distances[v] + (@@list[v].timeto[adj_room] || 0.2)
						if !visited[adj_room.to_i] and (shortest_distances[adj_room_i].nil? or shortest_distances[adj_room_i] > nd)
							shortest_distances[adj_room_i] = nd
							previous[adj_room_i] = v
							pq_push.call(adj_room_i)
						end
					}
				end
			end
			return previous, shortest_distances
		rescue
			echo "Map.dijkstra: error: #{$!}"
			respond $!.backtrace
			nil
		end
	end
	def outside?
		@paths =~ /Obvious paths:/
	end
	def to_i
		@id
	end
	def to_s
		"##{@id}:\n#{@title[0]}\n#{@desc[0]}\n#{@paths[0]}"
	end
	def inspect
		self.instance_variables.collect { |var| var.to_s + "=" + self.instance_variable_get(var).inspect }.join("\n")
	end
	def cinspect
		inspect
	end
	# backward compatability
	def guaranteed_shortest_pathfind(target)
		Map.findpath(self.id, target.id)
	end
	def estimation_pathfind(target)
		Map.findpath(self.id, target.id)
	end
end

class Room < Map
#	private_class_method :new
	def Room.method_missing(*args)
		super(*args)
	end
end

# backward compatability
class Pathfind
	def Pathfind.reassoc_nodes
		nil
	end
	def Pathfind.trace_field_positions
		nil
	end
	def Pathfind.find_node(target_id)
		Room[target_id.to_i]
	end
end

class NilClass
	def +(arg)
		arg
	end
end

# proc objects can't be dumped, since an intrinsic part of what they are is the 'binding' environment... this is just a quick fix so that a proc object can be saved; it's identical to a proc except that it also carries around the string that created the proc, so when it's loaded from a Marshal dump the proc object is recreated from the original string.  Basically it's a way for each room to carry around a mini-script they can save and load with the rest of the map database info
class StringProc
	def initialize(string)
		@string = string
	end
	def kind_of?(type)
		Proc.new {}.kind_of? type
	end
	def class
		Proc
	end
	def call(*args)
		eval(@string, nil, "StringProc")
	end
	def _dump(depth = nil)
		@string
	end
	def StringProc._load(string)
		StringProc.new(string)
	end
	def inspect
		"StringProc.new(#{@string.inspect})"
	end
end

class Critter
	unless defined?(LIST)
		LIST = []
	end
	attr_reader :id, :name, :level, :race, :type, :undead, :geo
	attr_accessor :as, :ds, :cs, :td, :attacks, :mb
	def initialize(id,name,level,race,type,undead=false,geo=nil)
		@id,@name,@level,@race,@type,@undead,@geo = id,name,level.to_i,race,type,undead,geo
		LIST.push(self) unless LIST.find { |critter| critter.name == @name }
	end
end

module Enumerable
	def qfind(obj)
		find { |el| el.match obj }
	end
end

def hide_me
	Script.self.hidden = !Script.self.hidden
end

def no_kill_all
	script = Script.self
	script.no_kill_all = !script.no_kill_all
end

def no_pause_all
	script = Script.self
	script.no_pause_all = !script.no_pause_all
end

def toggle_upstream
	unless script = Script.self then echo 'toggle_upstream: cannot identify calling script.'; return nil; end
	script.want_upstream = !script.want_upstream
end

def silence_me
	unless script = Script.self then echo 'silence_me: cannot identify calling script.'; return nil; end
	if script.safe? then echo("WARNING: 'safe' script attempted to silence itself.  Ignoring the request.")
		sleep 1
		return true
	end
	script.silent = !script.silent
end

def toggle_echo
	unless script = Script.self then respond('--- toggle_echo: Unable to identify calling script.'); return nil; end
	script.no_echo = !script.no_echo
end

def echo_on
	unless script = Script.self then respond('--- echo_on: Unable to identify calling script.'); return nil; end
	script.no_echo = false
end

def echo_off
	unless script = Script.self then respond('--- echo_off: Unable to identify calling script.'); return nil; end
	script.no_echo = true
end

def upstream_get
	unless script = Script.self then echo 'upstream_get: cannot identify calling script.'; return nil; end
	unless script.want_upstream
		echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)")
		return false
	end
	script.upstream_gets
end

def upstream_get?
	unless script = Script.self then echo 'upstream_get: cannot identify calling script.'; return nil; end
	unless script.want_upstream
		echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)")
		return false
	end
	script.upstream_gets?
end

def echo(*messages)
	if script = Script.self 
		unless script.no_echo
			messages = messages.flatten.compact
			respond if messages.empty?
			messages.each { |message| respond("[#{script.name}: #{message.to_s.chomp}]") }
		end
	else
		messages = messages.flatten.compact
		respond if messages.empty?
		messages.each { |message| respond("[(unknown script): #{message.to_s.chomp}]") }
	end
	nil
end

def goto(label)
	Script.self.jump_label = label.to_s
	raise JUMP
end

def start_script(script_name,cli_vars=[],force=false)
	# fixme: look in wizard script directory
	file_name = nil
	if File.exists?($script_dir + script_name + '.lic')
		file_name = $script_dir + script_name + '.lic'
	elsif File.exists?($script_dir + script_name + '.cmd')
		file_name = $script_dir + script_name + '.cmd'
	elsif File.exists?($script_dir + script_name + '.wiz')
		file_name = $script_dir + script_name + '.wiz'
	else
		file_list = Dir.entries($script_dir).delete_if { |fn| (fn == '.') or (fn == '..') }
		unless file_name = file_list.find { |val| val =~ /^#{script_name}\.(?:lic|rbw?|cmd|wiz)(?:\.gz|\.Z)?$/i } or 
		       file_name = file_list.find { |val| val =~ /^#{script_name}[^.]+\.(?i:lic|rbw?|cmd|wiz)(?:\.gz|\.Z)?$/ } or 
		       file_name = file_list.find { |val| val =~ /^#{script_name}[^.]+\.(?:lic|rbw?|cmd|wiz)(?:\.gz|\.Z)?$/i } or 
		       file_name = file_list.find { |val| val =~ /^#{script_name}$/i }
			respond("--- Lich: could not find script `#{script_name}' in directory #{$script_dir}!")
			file_list = nil
			return false
		end
		file_name = $script_dir + file_name
		file_list = nil
	end
	if not force and (Script.running + Script.hidden).find { |scr| scr.name == /.*[\/\\]+([^\.]+)\./.match(file_name).captures.first }
		respond("--- Lich: #{script_name} is already running (use #{$clean_lich_char}force [ScriptName] if desired).")
		return false
	end
	begin
		if file_name =~ /cmd$|wiz$/i
			new_script = WizardScript.new(file_name, cli_vars)
		else
			new_script = Script.new(file_name, cli_vars)
		end
		if new_script.labels.length > 1
			script_binding = ScriptBinder.new.create_block.binding
		else
			script_binding = nil
		end
	rescue
		respond "--- Lich: error starting script (#{script_name}): #{$!}"
		return false
	end
	unless new_script
		respond "--- Lich: failed to start script (#{script_name})"
		return false
	end
	new_thread = Thread.new {
		100.times { break if Script.self == new_script; sleep 0.01 }
		if script = Script.self
			eval('script = Script.self', script_binding, Script.self.name) if script_binding
			Thread.current.priority = 1
			respond("--- Lich: #{script.name} active.") unless script.quiet
			begin
				while Script.self.current_label
					eval(Script.self.labels[Script.self.current_label].to_s, script_binding, Script.self.name)
					Script.self.get_next_label
				end
				Script.self.kill
			rescue SystemExit
				Script.self.kill
			rescue SyntaxError
				$stdout.puts "--- SyntaxError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- SyntaxError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				respond "--- Lich: cannot execute #{Script.self.name}, aborting."
				Script.self.kill
			rescue ScriptError
				$stdout.puts "--- ScriptError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- ScriptError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue NoMemoryError
				$stdout.puts "--- NoMemoryError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- NoMemoryError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue LoadError
				$stdout.puts "--- LoadError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- LoadError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue SecurityError
				$stdout.puts "--- SecurityError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- SecurityError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue ThreadError
				$stdout.puts "--- ThreadError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- ThreadError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue Exception
				if $! == JUMP
					retry if Script.self.get_next_label != JUMP_ERROR
					$stdout.puts "--- Label Error: `#{Script.self.jump_label}' was not found, and no `LabelError' label was found!"
					$stdout.puts $!.backtrace.first
					$stderr.puts "--- Label Error: `#{Script.self.jump_label}' was not found, and no `LabelError' label was found!"
					$stderr.puts $!.backtrace
					$stderr.flush
					Script.self.kill
				else
					$stdout.puts "--- Exception: #{$!}"
					$stdout.puts $!.backtrace.first
					$stderr.puts "--- Exception: #{$!}"
					$stderr.puts $!.backtrace
					$stderr.flush
					Script.self.kill
				end
			rescue
				$stdout.puts "--- Error: #{Script.self.name}: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- Error: #{Script.self.name}: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			end
		else
			respond 'start_script screwed up...'
		end
	}
	new_script.thread_group.add(new_thread)
	true
end

def start_scripts(*script_names)
	script_names.flatten.each { |script_name|
		start_script(script_name)
		sleep "0.02".to_f
	}
end

def force_start_script(script_name,cli_vars=[])
	start_script(script_name,cli_vars,true)
end

def start_exec_script(cmd_data, quiet=false)
	unless new_script = ExecScript.new(cmd_data, quiet)
		respond '--- Lich: failed to start exec script'
		return false
	end
	new_thread = Thread.new {
		100.times { break if Script.self == new_script; sleep 0.01 }
		if script = Script.self
			Thread.current.priority = 1
			respond("--- Lich: #{script.name} active.") unless script.quiet
			begin
				eval(cmd_data, nil, script.name.to_s)
				Script.self.kill
			rescue SystemExit
				Script.self.kill
			rescue SyntaxError
				$stdout.puts "--- SyntaxError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- SyntaxError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue ScriptError
				$stdout.puts "--- ScriptError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- ScriptError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue NoMemoryError
				$stdout.puts "--- NoMemoryError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- NoMemoryError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue LoadError
				respond("--- LoadError: #{$!}")
				$stdout.puts "--- LoadError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- LoadError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue SecurityError
				$stdout.puts "--- SecurityError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- SecurityError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue ThreadError
				$stdout.puts "--- ThreadError: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- ThreadError: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue Exception
				$stdout.puts "--- Exception: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- Exception: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			rescue
				$stdout.puts "--- Error: #{$!}"
				$stdout.puts $!.backtrace.first
				$stderr.puts "--- Error: #{$!}"
				$stderr.puts $!.backtrace
				$stderr.flush
				Script.self.kill
			end
		else
			respond 'start_exec_script screwed up...'
		end
	}
	new_script.thread_group.add(new_thread)
	true
end

def pause_script(*names)
	names.flatten!
	if names.empty?
		Script.self.pause
		Script.self
	else
		names.each { |scr|
			fnd = (Script.running + Script.hidden).find { |nm| nm.name =~ /^#{scr}/i }
			fnd.pause unless (fnd.paused || fnd.nil?)
		}
	end
end

def unpause_script(*names)
	names.flatten!
	names.each { |scr| 
		fnd = (Script.running + Script.hidden).find { |nm| nm.name =~ /^#{scr}/i }
		fnd.unpause if (fnd.paused and not fnd.nil?)
	}
end

def fix_injury_mode
	unless XMLData.injury_mode == 2
		$_SERVER_.puts '_injury 2'
		150.times { sleep "0.05".to_f; break if XMLData.injury_mode == 2 }
	end
end

def hide_script(*args)
	args.flatten!
	args.each { |name|
		if script = Script.running.find { |scr| scr.name == name }
			script.hidden = !script.hidden
		end
	}
end

def parse_list(string)
	string.split_as_list
end

def waitrt
	until XMLData.roundtime_end > XMLData.server_time
		sleep "0.1".to_f
	end
	if XMLData.server_time >= XMLData.roundtime_end then return end
	sleep((XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + 0.6).abs)
end

def waitrt?
	if XMLData.roundtime_end > XMLData.server_time then waitrt end
end

def waitcastrt
	until XMLData.cast_roundtime_end > XMLData.server_time
		sleep "0.1".to_f
	end
	if XMLData.server_time >= XMLData.cast_roundtime_end then return end
	sleep((XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + 0.6).abs)
end

def waitcastrt?
	if XMLData.cast_roundtime_end > XMLData.server_time then waitcastrt end
end

def checkrt
	[XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f, 0].max
end

def checkcastrt
	[XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f, 0].max
end

def checkpoison
	XMLData.indicator['IconPOISONED'] == 'y'
end

def checkdisease
	XMLData.indicator['IconDISEASED'] == 'y'
end

def checksitting
	XMLData.indicator['IconSITTING'] == 'y'
end

def checkkneeling
	XMLData.indicator['IconKNEELING'] == 'y'
end

def checkstunned
	XMLData.indicator['IconSTUNNED'] == 'y'
end

def checkbleeding
	XMLData.indicator['IconBLEEDING'] == 'y'
end

def checkgrouped
	XMLData.indicator['IconJOINED'] == 'y'
end

def checkdead
	XMLData.indicator['IconDEAD'] == 'y'
end

def checkreallybleeding
	# fixme: What the hell does W stand for?
	# checkbleeding and !$_TAGHASH_['GSP'].include?('W')
	checkbleeding
end

def muckled?
	muckled = checkwebbed or checkdead or checkstunned or checkdead
	if defined?(checksleeping)
		muckled = muckled or checksleeping
	end
	if defined?(checkbound)
		muckled = muckled or checkbound
	end
	return muckled
end

def checkhidden
	XMLData.indicator['IconHIDDEN'] == 'y'
end

def checkinvisible
	XMLData.indicator['IconINVISIBLE'] == 'y'
end

def checkwebbed
	XMLData.indicator['IconWEBBED'] == 'y'
end

def checkprone
	XMLData.indicator['IconPRONE'] == 'y'
end

def checknotstanding
	XMLData.indicator['IconSTANDING'] == 'n'
end

def checkstanding
	XMLData.indicator['IconSTANDING'] == 'y'
end

def checkname(*strings)
	strings.flatten!
	if strings.empty?
		Char.name
	else
		Char.name =~ /^(?:#{strings.join('|')})/i
	end
end

def checkloot
	GameObj.loot.collect { |item| item.noun }
end

def i_stand_alone
	unless script = Script.self then echo 'i_stand_alone: cannot identify calling script.'; return nil; end
	script.want_downstream = !script.want_downstream
	return !script.want_downstream
end

def debug(*args)
	if $LICH_DEBUG
		if block_given?
			yield(*args)
		else
			echo(*args)
		end
	end
end

def timetest(*contestants)
	contestants.collect { |code| start = Time.now; 5000.times { code.call }; Time.now - start }
end

def dec2bin(n)
	"0" + [n].pack("N").unpack("B32")[0].sub(/^0+(?=\d)/, '')
end

def bin2dec(n)
	[("0"*32+n.to_s)[-32..-1]].pack("B32").unpack("N")[0]
end

def idle?(time = 60)
	Time.now - $_IDLETIMESTAMP_ >= time
end

def selectput(string, success, failure, timeout = nil)
	timeout = timeout.to_f if timeout and !timeout.kind_of?(Numeric)
	success = [ success ] if success.kind_of? String
	failure = [ failure ] if failure.kind_of? String
	if !string.kind_of?(String) or !success.kind_of?(Array) or !failure.kind_of?(Array) or timeout && !timeout.kind_of?(Numeric)
		raise ArgumentError, "usage is: selectput(game_command,success_array,failure_array[,timeout_in_secs])" 
	end
	success.flatten!
	failure.flatten!
	regex = /#{(success + failure).join('|')}/i
	successre = /#{success.join('|')}/i
	failurere = /#{failure.join('|')}/i
	thr = Thread.current

	timethr = Thread.new {
		timeout -= sleep("0.1".to_f) until timeout <= 0
		thr.raise(StandardError)
	} if timeout

	begin
		loop {
			fput(string)
			response = waitforre(regex)
			if successre.match(response.to_s)
				timethr.kill if timethr.alive?
				break(response.string)
			end
			yield(response.string) if block_given?
		}
	rescue
		nil
	end
end

def toggle_unique
	unless script = Script.self then echo 'toggle_unique: cannot identify calling script.'; return nil; end
	script.want_downstream = !script.want_downstream
end

def die_with_me(*vals)
	unless script = Script.self then echo 'die_with_me: cannot identify calling script.'; return nil; end
	script.die_with.push vals
	script.die_with.flatten!
	echo("The following script(s) will now die when I do: #{script.die_with.join(', ')}") unless script.die_with.empty?
end

def upstream_waitfor(*strings)
	strings.flatten!
	script = Script.self
	unless script.upstream then echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)") ; return false end
	regexpstr = strings.join('|')
	while line = script.upstream_gets
		if line =~ /#{regexpstr}/i
			return line
		end
	end
end

def survivepoison?
	# fixme
	echo 'survivepoison? called, but there is no XML for poison rate'
	return true
end

def survivedisease?
	# fixme
	echo 'survivepoison? called, but there is no XML for disease rate'
	return true
end

def before_dying(&code)
	unless script = Script.self then echo 'before_dying: cannot identify calling script.'; return nil; end
	if code.nil?
		echo "No code block was given to the `before_dying' command!  (a \"code block\" is the stuff inside squiggly-brackets); cannot register a block of code to run when this script dies unless it provides the code block."
		sleep 1
		return nil
	end
	script.dying_procs.push(code)
	true
end

def undo_before_dying
	unless script = Script.self then echo 'undo_before_dying: cannot identify calling script.'; return nil; end
	script.dying_procs.clear
	nil
end

def abort!
	unless script = Script.self then echo 'abort!: cannot identify calling script.'; return nil; end
	script.dying_procs.clear
	exit
end

def send_to_script(*values)
	values.flatten!
	if script = (Script.running + Script.hidden).find { |val| val.name =~ /^#{values.first}/i }
		values[1..-1].each { |val| script.downstream_buffer.push(val) }
		echo("Sent to #{script.name} -- '#{values[1..-1].join(' ; ')}'")
		return true
	else
		echo("'#{values.first}' does not match any active scripts!")
		return false
	end
end

def unique_send_to_script(*values)
	values.flatten!
	if script = (Script.running + Script.hidden).find { |val| val.name =~ /^#{values.first}/i }
		values[1..-1].each { |val| script.unique_buffer.push(val) }
		echo("sent to #{script}: #{values[1..-1].join(' ; ')}")
		return true
	else
		echo("'#{values.first}' does not match any active scripts!")
		return false
	end
end

def unique_waitfor(*strings)
	unless script = Script.self then echo 'unique_waitfor: cannot identify calling script.'; return nil; end
	strings.flatten!
	regexp = /#{strings.join('|')}/
	while true
		str = script.unique_gets
		if str =~ regexp
			return str
		end
	end
end

def unique_get
	unless script = Script.self then echo 'unique_get: cannot identify calling script.'; return nil; end
	script.unique_gets
end

def unique_get?
	unless script = Script.self then echo 'unique_get: cannot identify calling script.'; return nil; end
	script.unique_gets?
end

def multimove(*dirs)
	dirs.flatten.each { |dir| move(dir) }
end

def n
	'north'
end
def ne
	'northeast'
end
def e
	'east'
end
def se
	'southeast'
end
def s
	'south'
end
def sw
	'southwest'
end
def w
	'west'
end
def nw
	'northwest'
end
def u
	'up'
end
def up
	'up'
end
def down
	'down'
end
def d
	'down'
end
def o
	'out'
end
def out
	'out'
end

def move(dir='none', giveup_seconds=30, giveup_lines=30)
	# Guardsman Simlasyth stops you and says, "Stop.  You need to make sure you check in at Wyveryn Keep and get proper identification papers.  We don't let just anyone wander around here.  Now go o
	# You approach the entrance and identify yourself to the guard.  The guard checks over a long scroll of names and says, "I'm sorry, the Guild is open to invitees only.  Please do return at a later date when we will be open to the public."
	if dir == 'none'
		echo 'move: no direction given'
		return false
	end

	need_full_hands = false
	tried_open = false
	line_count = 0
	room_count = XMLData.room_count
	giveup_time = Time.now.to_i + giveup_seconds.to_i
	save_stream = Array.new

	put_dir = proc {
		if XMLData.room_count > room_count
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			return true
		end
		waitrt?
		wait_while { stunned? }
		giveup_time = Time.now.to_i + giveup_seconds.to_i
		line_count = 0
		save_stream.push(clear)
		put dir
	}

	put_dir.call

	loop {
		line = get?
		unless line.nil?
			save_stream.push(line)
			line_count += 1
		end
		if line.nil?
			sleep "0.1".to_f
		elsif line =~ /^You can't enter .+ and remain hidden or invisible\.|if he can't see you!$|^You can't enter .+ when you can't be seen\.$|^You can't do that without being seen\.$/
			fput 'unhide'
			put_dir.call
		elsif line =~ /^You can't go there|^Where are you trying to go\?|^What were you referring to\?|^I could not find what you were referring to\.|^How do you plan to do that here\?|^You take a few steps towards|^You cannot do that\.|^You settle yourself on|^You shouldn't annoy|^You can't go to|^That's probably not a very good idea|^You can't do that|^Maybe you should look|^You are already|^You walk over to|^You step over to|The [\w\s]+ is too far away|You may not pass\.|become impassable\.|prevents you from entering\.|Please leave promptly\.|is too far above you to attempt that\.$|^Uh, yeah\.  Right\.$|^Definitely NOT a good idea\.$|^Your attempt fails|^There doesn't seem to be any way to do that at the moment\.$/
			echo 'move: failed'
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			return false
		elsif line =~ /^An unseen force prevents you\.$|^Sorry, you aren't allowed to enter here\.|^That looks like someplace only performers should go\.|^As you climb, your grip gives way and you fall down|^The clerk stops you from entering the partition and says, "I'll need to see your ticket!"$|^The guard stops you, saying, "Only members of registered groups may enter the Meeting Hall\.  If you'd like to visit, ask a group officer for a guest pass\."$|^An? .*? reaches over and grasps [A-Z][a-z]+ by the neck preventing (?:him|her) from being dragged anywhere\.$/
			echo 'move: failed'
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			# return nil instead of false to show the direction shouldn't be removed from the map database
			return nil
		elsif line =~ /^You grab [A-Z][a-z]+ and try to drag h(?:im|er), but s?he is too heavy\.$|^Tentatively, you attempt to swim through the nook\.  After only a few feet, you begin to sink!  Your lungs burn from lack of air, and you begin to panic!  You frantically paddle back to safety!$/
			sleep 1
			waitrt?
			put_dir.call
		elsif line =~ /^Climbing.*you plunge towards the ground below\.|^Tentatively, you attempt to climb.*(?:fall|slip)|^You start.*but quickly realize|^You.*drop back to the ground|^You leap .* fall unceremoniously to the ground in a heap\.$/
			sleep 1
			waitrt?
			fput 'stand' unless standing?
			waitrt?
			put_dir.call
		elsif line =~ /^You will have to climb that\.$|^You're going to have to climb that\./
			dir.gsub!('go', 'climb')
			put_dir.call
		elsif line =~ /^You can't climb that\./
			dir.gsub!('climb', 'go')
			put_dir.call
		elsif line =~ /^Maybe if your hands were empty|^You figure freeing up both hands might help\.|^You can't .+ with your hands full\.$|^You'll need empty hands to climb that\.$/
			need_full_hands = true
			empty_hands
			put_dir.call
		elsif line =~ /(?:appears|seems) to be closed\.$/
			if tried_open
				fill_hands if need_full_hands
				Script.self.downstream_buffer.unshift(save_stream)
				Script.self.downstream_buffer.flatten!
				return false
			else
				tried_open = true
				fput dir.sub(/go|climb/, 'open')
				put_dir.call
			end
		elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
			if $2.to_i > 1
				sleep ($2.to_i - 0.2)
			else
				sleep 0.3
			end
			put_dir.call
		elsif line =~ /will have to stand up first|must be standing first|You'll have to get up first\.|But you're already sitting!|Shouldn't you be standing first|Try standing up\.|Perhaps you should stand up/
			fput 'stand'
			waitrt?
			put_dir.call
		elsif line =~ /^Sorry, you may only type ahead/
			sleep 1
			put_dir.call
		elsif line == 'You are still stunned.'
			wait_while { stunned? }
			put_dir.call
		elsif line =~ /you slip (?:on a patch of ice )?and flail uselessly as you land on your rear(?:\.|!)$|You wobble and stumble only for a moment before landing flat on your face!$/
			waitrt?
			fput 'stand' unless standing?
			waitrt?
			put_dir.call
		end
		if XMLData.room_count > room_count
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			return true
		end
		if Time.now.to_i >= giveup_time
			echo "move: no recognized response in #{giveup_seconds} seconds.  giving up."
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			return nil
		end
		if line_count >= giveup_lines
			echo "move: no recognized response after #{line_count} lines.  giving up."
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			return nil
		end
	}
end

def fetchloot(userbagchoice=Lich.lootsack)
	if GameObj.loot.empty?
		return false
	end
	if Lich.excludeloot.empty?
		regexpstr = nil
	else
		regexpstr = Lich.excludeloot.split(', ').join('|')
	end
	if checkright and checkleft
		stowed = GameObj.right_hand.noun
		fput "put my #{stowed} in my #{Lich.lootsack}"
	else
		stowed = nil
	end
	GameObj.loot.each { |loot|
		unless not regexpstr.nil? and loot.name =~ /#{regexpstr}/
			fput "get #{loot.noun}"
			fput("put my #{loot.noun} in my #{userbagchoice}") if (checkright || checkleft)
		end
	}
	if stowed
		fput "take my #{stowed} from my #{Lich.lootsack}"
	end
end

def take(*items)
	items.flatten!
	if (righthand? && lefthand?)
		weap = checkright
		fput "put my #{checkright} in my #{Lich.lootsack}"
		unsh = true
	else
		unsh = false
	end
	items.each { |trinket|
		fput "take #{trinket}"
		fput("put my #{trinket} in my #{Lich.lootsack}") if (righthand? || lefthand?)
	}
	if unsh then fput("take my #{weap} from my #{Lich.lootsack}") end
end

def watchhealth(value, theproc=nil, &block)
	value = value.to_i
	if block.nil?
		if !theproc.respond_to? :call
			respond "`watchhealth' was not given a block or a proc to execute!"
			return nil
		else
			block = theproc
		end
	end
	Thread.new {
		wait_while { health(value) }
		block.call
	}
end

def wait_until(announce=nil)
	priosave = Thread.current.priority
	Thread.current.priority = 0
	unless announce.nil? or yield
		respond(announce)
	end
	until yield
		sleep "0.25".to_f
	end
	Thread.current.priority = priosave
end

def wait_while(announce=nil)
	priosave = Thread.current.priority
	Thread.current.priority = 0
	unless announce.nil? or !yield
		respond(announce)
	end
	while yield
		sleep "0.25".to_f
	end
	Thread.current.priority = priosave
end

def checkpaths(dir="none")
	if dir == "none"
		if XMLData.room_exits.empty?
			return false
		else
			return XMLData.room_exits.collect { |dir| dir = SHORTDIR[dir] }
		end
	else
		XMLData.room_exits.include?(dir) || XMLData.room_exits.include?(SHORTDIR[dir])
	end
end

def reverse_direction(dir)
	if dir == "n" then 's'
	elsif dir == "ne" then 'sw'
	elsif dir == "e" then 'w'
	elsif dir == "se" then 'nw'
	elsif dir == "s" then 'n'
	elsif dir == "sw" then 'ne'
	elsif dir == "w" then 'e'
	elsif dir == "nw" then 'se'
	elsif dir == "up" then 'down'
	elsif dir == "down" then 'up'
	elsif dir == "out" then 'out'
	elsif dir == 'o' then out
	elsif dir == 'u' then 'down'
	elsif dir == 'd' then up
	elsif dir == n then s
	elsif dir == ne then sw
	elsif dir == e then w
	elsif dir == se then nw
	elsif dir == s then n
	elsif dir == sw then ne
	elsif dir == w then e
	elsif dir == nw then se
	elsif dir == u then d
	elsif dir == d then u
	else echo("Cannot recognize direction to properly reverse it!"); false
	end
end

def walk(*boundaries, &block)
	boundaries.flatten!
	unless block.nil?
		until val = yield
			walk(*boundaries)
		end
		return val
	end
	if $last_dir and !boundaries.empty? and checkroomdescrip =~ /#{boundaries.join('|')}/i
		move($last_dir)
		$last_dir = reverse_direction($last_dir)
		return checknpcs
	end
	dirs = checkpaths
	dirs.delete($last_dir) unless dirs.length < 2
	this_time = rand(dirs.length)
	$last_dir = reverse_direction(dirs[this_time])
	move(dirs[this_time])
	checknpcs
end

def run
	loop { break unless walk }
end

def check_mind(string=nil)
	if string.nil?
		return XMLData.mind_text
	elsif (string.class == String) and (string.to_i == 0)
		if string =~ /#{XMLData.mind_text}/i
			return true
		else
			return false
		end
	elsif string.to_i.between?(0,100)
		return string.to_i <= XMLData.mind_value.to_i
	else
		echo("check_mind error! You must provide an integer ranging from 0-100, the common abbreviation of how full your head is, or provide no input to have check_mind return an abbreviation of how filled your head is.") ; sleep 1
		return false
	end
end

def checkmind(string=nil)
	if string.nil?
		return XMLData.mind_text
	elsif string.class == String and string.to_i == 0
		if string =~ /#{XMLData.mind_text}/i
			return true
		else
			return false
		end
	elsif string.to_i.between?(1,8)
		mind_state = ['clear as a bell','fresh and clear','clear','muddled','becoming numbed','numbed','must rest','saturated']
		if mind_state.index(XMLData.mind_text)
			mind = mind_state.index(XMLData.mind_text) + 1
			return string.to_i <= mind
		else
			echo "Bad string in checkmind: mind_state"
			nil
		end
	else
		echo("Checkmind error! You must provide an integer ranging from 1-8 (7 is fried, 8 is 100% fried), the common abbreviation of how full your head is, or provide no input to have checkmind return an abbreviation of how filled your head is.") ; sleep 1
		return false
	end
end

def percentmind(num=nil)
	if num.nil?
		XMLData.mind_value
	else 
		XMLData.mind_value >= num.to_i
	end
end

def checkfried
	if XMLData.mind_text =~ /fried|saturated/
		true
	else
		false
	end
end

def checksaturated
	if XMLData.mind_text =~ /saturated/
		true
	else
		false
	end
end

def checkmana(num=nil)
	if num.nil?
		XMLData.mana
	else
		XMLData.mana >= num.to_i
	end
end

def maxmana
	XMLData.max_mana
end

def percentmana(num=nil)
	return 100 if XMLData.max_mana == 0
	unless num.nil?
		((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i >= num.to_i
	else 
		((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
	end
end

def checkhealth(num=nil)
	if num.nil?
		XMLData.health
	else
		XMLData.health >= num.to_i
	end
end

def maxhealth
	XMLData.max_health
end

def percenthealth(num=nil)
	unless num.nil?
		((health.to_f / maxhealth.to_f) * 100).to_i >= num.to_i
	else
		((health.to_f / maxhealth.to_f) * 100).to_i
	end
end

def checkspirit(num=nil)
	if num.nil?
		XMLData.spirit
	else
		XMLData.spirit >= num.to_i
	end
end

def maxspirit
	XMLData.max_spirit
end

def percentspirit(num=nil)
	if num.nil?
		((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
	else
		((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i >= num.to_i
	end
end

def checkstamina(num=nil)
	if num.nil?
		XMLData.stamina
	else
		XMLData.stamina >= num.to_i
	end
end

def maxstamina()
	XMLData.max_stamina
end

def percentstamina(num=nil)
	if num.nil?
		((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
	else
		((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i >= num.to_i
	end
end

def checkstance(num=nil)
	if num.nil?
		XMLData.stance_text
	elsif (num.class == String) and (num.to_i == 0)
		if num =~ /off/i
			XMLData.stance_value == 0
		elsif num =~ /adv/i
			XMLData.stance_value.between?(01, 20)
		elsif num =~ /for/i
			XMLData.stance_value.between?(21, 40)
		elsif num =~ /neu/i
			XMLData.stance_value.between?(41, 60)
		elsif num =~ /gua/i
			XMLData.stance_value.between?(61, 80)
		elsif num =~ /def/i
			XMLData.stance_value == 100
		else
			echo "checkstance: invalid argument (#{num}).  Must be off/adv/for/neu/gua/def or 0-100"
			nil
		end
	elsif (num.class == Fixnum) or (num =~ /^[0-9]+$/ and num = num.to_i)
		XMLData.stance_value == num.to_i
	else
		echo "checkstance: invalid argument (#{num}).  Must be off/adv/for/neu/gua/def or 0-100"
		nil
	end
end

def percentstance(num=nil)
	if num.nil?
		XMLData.stance_value
	else
		XMLData.stance_value >= num.to_i
	end
end

def checkencumbrance(string=nil)
	if string.nil?
		XMLData.encumbrance_text
	elsif (string.class == Fixnum) or (string =~ /^[0-9]+$/ and string = string.to_i)
		string <= XMLData.encumbrance_value
	else
		# fixme
		if string =~ /#{XMLData.encumbrance_text}/i
			true
		else
			false
		end
	end
end

def percentencumbrance(num=nil)
	if num.nil?
		XMLData.encumbrance_value
	else
		num.to_i <= XMLData.encumbrance_value
	end
end

def checkarea(*strings)
	strings.flatten!
	if strings.empty?
		XMLData.room_title.split(',').first.sub('[','')
	else
		XMLData.room_title.split(',').first =~ /#{strings.join('|')}/i
	end
end

def checkroom(*strings)
	strings.flatten!
	if strings.empty?
		XMLData.room_title.chomp
	else
		XMLData.room_title =~ /#{strings.join('|')}/i
	end
end

def outside?
	if XMLData.room_exits_string =~ /Obvious paths:/
		true
	else
		false
	end
end

def checkfamarea(*strings)
	strings.flatten!
	if strings.empty? then return XMLData.familiar_room_title.split(',').first.sub('[','') end
	XMLData.familiar_room_title.split(',').first =~ /#{strings.join('|')}/i
end

def checkfampaths(dir="none")
	if dir == "none"
		if XMLData.familiar_room_exits.empty?
			return false
		else
			return XMLData.familiar_room_exits
		end
	else
		XMLData.familiar_room_exits.include?(dir)
	end
end

def checkfamroom(*strings)
	strings.flatten! ; if strings.empty? then return XMLData.familiar_room_title.chomp end
	XMLData.familiar_room_title =~ /#{strings.join('|')}/i
end

def checkfamnpcs(*strings)
	parsed = Array.new
	XMLData.familiar_npcs.each { |val| parsed.push(val.split.last) }
	if strings.empty?
		if parsed.empty?
			return false
		else
			return parsed
		end
	else
		if mtch = strings.find { |lookfor| parsed.find { |critter| critter =~ /#{lookfor}/ } }
			return mtch
		else
			return false
		end
	end
end

def checkfampcs(*strings)
	familiar_pcs = Array.new
	XMLData.familiar_pcs.to_s.gsub(/Lord |Lady |Great |High |Renowned |Grand |Apprentice |Novice |Journeyman /,'').split(',').each { |line| familiar_pcs.push(line.slice(/[A-Z][a-z]+/)) }
	if familiar_pcs.empty?
		return false
	elsif strings.empty?
		return familiar_pcs
	else
		regexpstr = strings.join('|\b')
		peeps = familiar_pcs.find_all { |val| val =~ /\b#{regexpstr}/i }
		if peeps.empty?
			return false
		else
			return peeps
		end
	end
end

def checkpcs(*strings)
	pcs = GameObj.pcs.collect { |pc| pc.noun }
	if pcs.empty?
		if strings.empty? then return nil else return false end
	end
	strings.flatten!
	if strings.empty?
		pcs
	else
		regexpstr = strings.join(' ')
		pcs.find { |pc| regexpstr =~ /\b#{pc}/i }
	end
end

def checknpcs(*strings)
	npcs = GameObj.npcs.collect { |npc| npc.noun }
	if npcs.empty?
		if strings.empty? then return nil else return false end
	end
	strings.flatten!
	if strings.empty?
		npcs
	else
		regexpstr = strings.join(' ')
		npcs.find { |npc| regexpstr =~ /\b#{npc}/i }
	end
end

def count_npcs
	checknpcs.length
end

def checkright(*hand)
	if GameObj.right_hand.nil? then return nil end
	hand.flatten!
	if GameObj.right_hand.name == "Empty" or GameObj.right_hand.name.empty?
		nil
	elsif hand.empty?
		GameObj.right_hand.noun
	else
		hand.find { |instance| GameObj.right_hand.name =~ /#{instance}/i }
	end
end

def checkleft(*hand)
	if GameObj.left_hand.nil? then return nil end
	hand.flatten!
	if GameObj.left_hand.name == "Empty" or GameObj.left_hand.name.empty?
		nil
	elsif hand.empty?
		GameObj.left_hand.noun
	else
		hand.find { |instance| GameObj.left_hand.name =~ /#{instance}/i }
	end
end

def checkroomdescrip(*val)
	val.flatten!
	if val.empty?
		return XMLData.room_description
	else
		return XMLData.room_description =~ /#{val.join('|')}/i
	end
end

def checkfamroomdescrip(*val)
	val.flatten!
	if val.empty?
		return XMLData.familiar_room_description
	else
		return XMLData.familiar_room_description =~ /#{val.join('|')}/i
	end
end

def checkspell(*spells)
	spells.flatten!
	return false if Spell.active.empty?
	spells.each { |spell| return false unless Spell[spell].active? }
	true
end

def checkprep(spell=nil)
	if spell.nil?
		XMLData.prepared_spell
	elsif spell.class != String
		echo("Checkprep error, spell # not implemented!  You must use the spell name")
		false
	else
		XMLData.prepared_spell =~ /^#{spell}/i
	end
end

def setpriority(val=nil)
	if val.nil? then return Thread.current.priority end
	if val.to_i > 3
		echo("You're trying to set a script's priority as being higher than the send/recv threads (this is telling Lich to run the script before it even gets data to give the script, and is useless); the limit is 3")
		return Thread.current.priority
	else
		Thread.current.group.list.each { |thr| thr.priority = val.to_i }
		return Thread.current.priority
	end
end

def checkbounty
	if XMLData.bounty_task
		return XMLData.bounty_task
	else
		return nil
	end
end

def variable
	unless script = Script.self then echo 'variable: cannot identify calling script.'; return nil; end
	script.vars
end

def pause(num=1)
	if num =~ /m/
		sleep((num.sub(/m/, '').to_f * 60))
	elsif num =~ /h/
		sleep((num.sub(/h/, '').to_f * 3600))
	elsif num =~ /d/
		sleep((num.sub(/d/, '').to_f * 86400))
	else
		sleep(num.to_f)
	end
end

def cast(spell, target=nil)
	if spell.class == Spell
		spell.cast(target)
	elsif ( (spell.class == Fixnum) or (spell.to_s =~ /^[0-9]+$/) ) and (find_spell = Spell[spell.to_i])
		find_spell.cast(target)
	elsif (spell.class == String) and (find_spell = Spell[spell])
		find_spell.cast(target)
	else
		echo "cast: invalid spell (#{spell})"
		false
	end
end

def clear(opt=0)
	unless script = Script.self then respond('--- clear: Unable to identify calling script.'); return false; end
	to_return = script.downstream_buffer.dup
	script.downstream_buffer.clear
	to_return
end

def match(label, string)
	strings = [ label, string ]
	strings.flatten!
	unless script = Script.self then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting...") ; Thread.current.kill ; return false end
	if strings.empty? then echo("Error! 'match' was given no strings to look for!") ; sleep 1 ; return false end
	unless strings.length == 2
		while line_in = script.gets
			strings.each { |string|
				if line_in =~ /#{string}/ then return $~.to_s end
			}
		end
	else
		if script.respond_to?(:match_stack_add)
			script.match_stack_add(strings.first.to_s, strings.last)
		else	
			script.match_stack_labels.push(strings[0].to_s)
			script.match_stack_strings.push(strings[1])
		end
	end
end

def matchtimeout(secs, *strings)
	unless script = Script.self then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting...") ; Thread.current.kill ; return false end
	unless (secs.class == Float || secs.class == Fixnum)
		echo('matchtimeout error! You appear to have given it a string, not a #! Syntax:  matchtimeout(30, "You stand up")')
		return false
	end
	strings.flatten!
	if strings.empty?
		echo("matchtimeout without any strings to wait for!")
		sleep 1
		return false
	end
	regexpstr = strings.join('|')
	end_time = Time.now.to_f + secs
	loop {
		line = get?
		if line.nil?
			sleep "0.1".to_f
		elsif line =~ /#{regexpstr}/i
			return line
		end
		if (Time.now.to_f > end_time)
			return false
		end
	}
end

def matchbefore(*strings)
  strings.flatten!
  unless script = Script.self then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting...") ; Thread.current.kill ; return false end
  if strings.empty? then echo("matchbefore without any strings to wait for!") ; return false end
  regexpstr = strings.join('|')
  loop { if (line_in = script.gets) =~ /#{regexpstr}/ then return $`.to_s end }
end

def matchafter(*strings)
  strings.flatten!
  unless script = Script.self then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting...") ; Thread.current.kill ; return false end
  if strings.empty? then echo("matchafter without any strings to wait for!") ; return end
  regexpstr = strings.join('|')
  loop { if (line_in = script.gets) =~ /#{regexpstr}/ then return $'.to_s end }
end

def matchboth(*strings)
  strings.flatten!
  unless script = Script.self then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting...") ; Thread.current.kill ; return false end
  if strings.empty? then echo("matchboth without any strings to wait for!") ; return end
  regexpstr = strings.join('|')
  loop { if (line_in = script.gets) =~ /#{regexpstr}/ then break end }
  return [ $`.to_s, $'.to_s ]
end

def matchwait(*strings)
	unless script = Script.self then respond('--- matchwait: Unable to identify calling script.'); return false; end
	strings.flatten!
	unless strings.empty?
		regexpstr = strings.collect { |str| str.kind_of?(Regexp) ? str.source : str }.join('|')
		regexobj = /#{regexpstr}/
		while line_in = script.gets
			return line_in if line_in =~ regexobj
		end
	else
		strings = script.match_stack_strings
		labels = script.match_stack_labels
		regexpstr = /#{strings.join('|')}/i
		while line_in = script.gets
			if mdata = regexpstr.match(line_in)
				jmp = labels[strings.index(mdata.to_s) || strings.index(strings.find { |str| line_in =~ /#{str}/i })]
				script.match_stack_clear
				goto jmp
			end
		end
	end
end

def waitforre(regexp)
	unless script = Script.self then respond('--- waitforre: Unable to identify calling script.'); return false; end
	unless regexp.class == Regexp then echo("Script error! You have given 'waitforre' something to wait for, but it isn't a Regular Expression! Use 'waitfor' if you want to wait for a string."); sleep 1; return nil end
	regobj = regexp.match(script.gets) until regobj
end

def waitfor(*strings)
	unless script = Script.self then respond('--- waitfor: Unable to identify calling script.'); return false; end
	strings.flatten!
	if (script.class == WizardScript) and (strings.length == 1) and (strings.first.strip == '>')
		return script.gets
	end
	if strings.empty?
		echo 'waitfor: no string to wait for'
		return false
	end
	regexpstr = strings.join('|')
	while true
		line_in = script.gets
		if (line_in =~ /#{regexpstr}/i) then return line_in end
	end
end

def wait
	unless script = Script.self then respond('--- wait: unable to identify calling script.'); return false; end
	script.clear
	return script.gets
end

def get
	Script.self.gets
end

def get?
	Script.self.gets?
end

def reget(*lines)
	unless script = Script.self then respond('--- reget: Unable to identify calling script.'); return false; end
	lines.flatten!
	if caller.find { |c| c =~ /regetall/ }
		history = ($_SERVERBUFFER_.history + $_SERVERBUFFER_).join("\n")
	else
		history = $_SERVERBUFFER_.dup.join("\n")
	end
	unless script.want_downstream_xml
		history.gsub!(/<pushStream id=["'](?:spellfront|inv|bounty|society)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
		history.gsub!(/<stream id="Spells">.*?<\/stream>/m, '')
		history.gsub!(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
		history.gsub!(/<[^>]+>/, '')
		history.gsub!('&gt;', '>')
		history.gsub!('&lt;', '<')
		history = history.split("\n").delete_if { |line| line.nil? or line.empty? or line =~ /^[\r\n\s\t]*$/ }
	end
	if lines.first.kind_of? Numeric or lines.first.to_i.nonzero?
		history = history[-([lines.shift.to_i,history.length].min)..-1]
	end
	unless lines.empty? or lines.nil?
		regex = /#{lines.join('|')}/i
		history = history[-num..-1].find_all { |line| line =~ regex }
	end
	if history.empty?
		nil
	else
		history
	end
end

def regetall(*lines)
	reget(*lines)
end

def multifput(*cmds)
	cmds.flatten.compact.each { |cmd| fput(cmd) }
end

def fput(message, *waitingfor)
	unless script = Script.self then respond('--- waitfor: Unable to identify calling script.'); return false; end
	waitingfor.flatten!
	clear
	put(message)

	while string = get
		if string =~ /(?:\.\.\.wait |Wait )[0-9]+/
			hold_up = string.slice(/[0-9]+/).to_i
			sleep(hold_up) unless hold_up.nil?
			clear
			put(message)
			next
		elsif string =~ /struggle.+stand/
			clear
			fput("stand")
			next
		elsif string =~ /stunned|can't do that while|cannot seem|can't seem|don't seem|Sorry, you may only type ahead/
			if dead?
				echo("You're dead...! You can't do that!")
				sleep 1
				script.downstream_buffer.unshift(string)
				return false
			elsif checkstunned
				while checkstunned
					sleep(0.25)
				end
			elsif checkwebbed
				while checkwebbed
					sleep(0.25)
				end
			else
				sleep(1)
			end
			clear
			put(message)
			next
		else
			if waitingfor.empty?
				script.downstream_buffer.unshift(string)
				return string
			else
				if foundit = waitingfor.find { |val| string =~ /#{val}/i }
					script.downstream_buffer.unshift(string)
					return foundit
				end
				sleep 1
				clear
				put(message)
				next
			end
		end
	end
end

def put(*messages)
	unless script = Script.self then script = "(script unknown)" end
	$_SCRIPTIDLETIMESTAMP_ = Time.now
	messages.each { |message|
		message.chomp!
		unless scr = Script.self then scr = "(script unknown)" end
		$_CLIENTBUFFER_.push("[#{scr}]#{$SEND_CHARACTER}<c>#{message}\r\n")
		respond("[#{scr}]#{$SEND_CHARACTER}#{message}\r\n") unless scr.silent
		$_SERVER_.write("<c>#{message}\n")
		$_LASTUPSTREAM_ = "[#{scr}]#{$SEND_CHARACTER}#{message}"
	}
end

def quiet_exit
	script = Script.self
	script.quiet = !(script.quiet)
end

def matchfindexact(*strings)
	strings.flatten!
  	unless script = Script.self then echo("An unknown script thread tried to fetch a game line from the queue, but Lich can't process the call without knowing which script is calling! Aborting...") ; Thread.current.kill ; return false end
	if strings.empty? then echo("error! 'matchfind' with no strings to look for!") ; sleep 1 ; return false end
	looking = Array.new
	strings.each { |str| looking.push(str.gsub('?', '(\b.+\b)')) }
	if looking.empty? then echo("matchfind without any strings to wait for!") ; return false end
	regexpstr = looking.join('|')
	while line_in = script.gets
		if gotit = line_in.slice(/#{regexpstr}/)
			matches = Array.new
			looking.each_with_index { |str,idx|
				if gotit =~ /#{str}/i
					strings[idx].count('?').times { |n| matches.push(eval("$#{n+1}")) }
				end
			}
			break
		end
	end
	if matches.length == 1
		return matches.first
	else
		return matches.compact
	end
end

def matchfind(*strings)
	regex = /#{strings.flatten.join('|').gsub('?', '(.+)')}/i
	unless script = Script.self
		respond "Unknown script is asking to use matchfind!  Cannot process request without identifying the calling script; killing this thread."
		Thread.current.kill
	end
	while true
		if reobj = regex.match(script.gets)
			ret = reobj.captures.compact
			if ret.length < 2
				return ret.first
			else
				return ret
			end
		end
	end
end

def matchfindword(*strings)
	regex = /#{strings.flatten.join('|').gsub('?', '([\w\d]+)')}/i
	unless script = Script.self
		respond "Unknown script is asking to use matchfindword!  Cannot process request without identifying the calling script; killing this thread."
		Thread.current.kill
	end
	while true
		if reobj = regex.match(script.gets)
			ret = reobj.captures.compact
			if ret.length < 2
				return ret.first
			else
				return ret
			end
		end
	end
end

def send_scripts(*messages)
	messages.flatten!
	messages.each { |message|
		Script.new_downstream(message)
	}
	true
end

def status_tags(onoff="none")
	script = Script.self
	if onoff == "on"
		script.want_downstream = false
		script.want_downstream_xml = true
		echo("Status tags will be sent to this script.")
	elsif onoff == "off"
		script.want_downstream = true
		script.want_downstream_xml = false
		echo("Status tags will no longer be sent to this script.")
	elsif script.want_downstream_xml
		script.want_downstream = true
		script.want_downstream_xml = false
	else
		script.want_downstream = false
		script.want_downstream_xml = true
	end
end

def stop_script(*target_names)
	numkilled = 0
	target_names.each { |target_name| 
		condemned = (Script.running + Script.hidden).find { |s_sock| s_sock.name =~ /^#{target_name}/i }
		if condemned.nil?
			respond("--- Lich: '#{Script.self}' tried to stop '#{target_name}', but it isn't running!")
		else
			if condemned.name =~ /^#{Script.self.name}$/i
				exit
			end
			condemned.kill
			respond("--- Lich: '#{condemned}' has been stopped by #{Script.self}.")
			numkilled += 1
		end
	}
	if numkilled == 0
		return false
	else
		return numkilled
	end
end

def running?(*snames)
	snames.each { |checking| (return false) unless (Script.running.find { |lscr| lscr.name =~ /^#{checking}$/i } || Script.running.find { |lscr| lscr.name =~ /^#{checking}/i } || Script.hidden.find { |lscr| lscr.name =~ /^#{checking}$/i } || Script.hidden.find { |lscr| lscr.name =~ /^#{checking}/i }) }
	true
end

def respond(first = "", *messages)
	str = ''
	begin
		if first.class == Array
			first.flatten.each { |ln| str += sprintf("%s\r\n", ln.to_s.chomp) }
		else	
			str += sprintf("%s\r\n", first.to_s.chomp)
		end
		messages.flatten.each { |message| str += sprintf("%s\r\n", message.to_s.chomp) }
		str = "<output class=\"mono\"/>\r\n#{str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')}<output class=\"\"/>\r\n" unless $fake_stormfront
		wait_while { XMLData.in_stream }
		$_CLIENT_.puts(str)
	rescue
		puts $!
		puts $!.backtrace.first
	end
end

def noded_pulse
	if Stats.prof =~ /warrior|rogue|sorcerer/i
		stats = [ Skills.smc.to_i, Skills.emc.to_i ]
	elsif Stats.prof =~ /empath|bard/i
		stats = [ Skills.smc.to_i, Skills.mmc.to_i ]
	elsif Stats.prof =~ /wizard/i
		stats = [ Skills.emc.to_i, 0 ]
	elsif Stats.prof =~ /paladin|cleric|ranger/i
		stats = [ Skills.smc.to_i, 0 ]
	else
		stats = [ 0, 0 ]
	end
	return (maxmana * 25 / 100) + (stats.max/10) + (stats.min/20)
end

def unnoded_pulse
	if Stats.prof =~ /warrior|rogue|sorcerer/i
		stats = [ Skills.smc.to_i, Skills.emc.to_i ]
	elsif Stats.prof =~ /empath|bard/i
		stats = [ Skills.smc.to_i, Skills.mmc.to_i ]
	elsif Stats.prof =~ /wizard/i
		stats = [ Skills.emc.to_i, 0 ]
	elsif Stats.prof =~ /paladin|cleric|ranger/i
		stats = [ Skills.smc.to_i, 0 ]
	else
		stats = [ 0, 0 ]
	end
	return (maxmana * 15 / 100) + (stats.max/10) + (stats.min/20)
end

def empty_hands
	$rh_thingie, $lh_thingie = checkright, checkleft
	if $rh_thingie
		if Lich.lootsack.nil?
			fput "stow #{$rh_thingie}"
		else
			result = dothistimeout "put my #{$rh_thingie} in my #{Lich.lootsack}", 4, /^You put|^You can't .+ It's closed!$/
			if result =~ /^You can't .+ It's closed!$/
				fput "open my #{Lich.lootsack}"
				fput "put my #{$rh_thingie} in my #{Lich.lootsack}"
				$close_lootsack = true
			end
		end
		
	end
	if $lh_thingie
		if $lh_thingie =~ /shield|buckler|targe|heater|parma|aegis|scutum|greatshield|mantlet|pavis|arbalest/
			fput "wear my #{$lh_thingie}"
		else
			if Lich.lootsack.nil?
				fput "stow #{$lh_thingie}"
			else
				result = dothistimeout "put my #{$lh_thingie} in my #{Lich.lootsack}", 4, /^You put|^You can't .+ It's closed!$/
				if result =~ /^You can't .+ It's closed!$/
					fput "open my #{Lich.lootsack}"
					fput "put my #{$lh_thingie} in my #{Lich.lootsack}"
					$close_lootsack = true
				end
			end
		end
	end
end

def fill_hands
	$rh_thingie ||= nil
	$lh_thingie ||= nil
	$close_lootsack ||= nil
	if $rh_thingie
		waitrt?
		if Lich.lootsack.nil?
			fput "get my #{$rh_thingie}"
		else
			fput "get my #{$rh_thingie} from my #{Lich.lootsack}"
		end
	end
	if $lh_thingie
		waitrt?
		if $lh_thingie =~ /shield|buckler|targe|heater|parma|aegis|scutum|greatshield|mantlet|pavis/
			fput "remove my #{$lh_thingie}"
		elsif Lich.lootsack.nil?
			fput "get my #{$lh_thingie}"
		else
			fput "get my #{$lh_thingie} from my #{Lich.lootsack}"
		end
	end
	fput "close my #{Lich.lootsack}" if $close_lootsack
	$rh_thingie, $lh_thingie, $close_lootsack = nil, nil, nil
end

def dothis (action, success_line)
	loop {
		clear
		put action
		loop {
			line = get
			if line =~ success_line
				return line
			elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
				if $2.to_i > 1
					sleep ($2.to_i - 0.5)
				else
					sleep "0.3".to_f
				end
				break
			elsif line == 'Sorry, you may only type ahead 1 command.'
				sleep 1
				break
			elsif line == 'You are still stunned.'
				wait_while { stunned? }
				break
			elsif line == 'That is impossible to do while unconscious!'
				100.times {
					unless line = get?
						sleep 0.1
					else
						break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
					end
				}
				break
			elsif line == "You don't seem to be able to move to do that."
				100.times {
					unless line = get?
						sleep 0.1
					else
						break if line == 'The restricting force that envelops you dissolves away.'
					end
				}
				break
			elsif line == "You can't do that while entangled in a web."
				wait_while { checkwebbed }
				break
			elsif line == 'You find that impossible under the effects of the lullabye.'
				100.times {
					unless line = get?
						sleep 0.1
					else
						# fixme
						break if line == 'You shake off the effects of the lullabye.'
					end
				}
				break
			end
		}
	}
end

def dothistimeout (action, timeout, success_line)
	end_time = Time.now.to_i + timeout
	line = nil
	loop {
		clear
		put action unless action.nil?
		loop {
			line = get?
			if line.nil?
				sleep "0.1".to_f
			elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
				if $2.to_i > 1
					sleep ($2.to_i - 0.5)
				else
					sleep "0.3".to_f
				end
				end_time = Time.now.to_i + timeout
				break
			elsif line == 'Sorry, you may only type ahead 1 command.'
				sleep 1
				end_time = Time.now.to_i + timeout
				break
			elsif line == 'You are still stunned.'
				wait_while { stunned? }
				end_time = Time.now.to_i + timeout
				break
			elsif line == 'That is impossible to do while unconscious!'
				100.times {
					unless line = get?
						sleep 0.1
					else
						break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
					end
				}
				break
			elsif line == "You don't seem to be able to move to do that."
				100.times {
					unless line = get?
						sleep 0.1
					else
						break if line == 'The restricting force that envelops you dissolves away.'
					end
				}
				break
			elsif line == "You can't do that while entangled in a web."
				wait_while { checkwebbed }
				break
			elsif line == 'You find that impossible under the effects of the lullabye.'
				100.times {
					unless line = get?
						sleep 0.1
					else
						# fixme
						break if line == 'You shake off the effects of the lullabye.'
					end
				}
				break
			elsif line =~ success_line
				return line
			end
			if Time.now.to_i >= end_time
				return nil
			end
		}
	}
end

def registry_get(key)
	hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures
	if HAVE_REGISTRY
		begin
			if hkey == 'HKEY_LOCAL_MACHINE'
				Win32::Registry::HKEY_LOCAL_MACHINE.open(subkey) do |reg|
					reg_type, reg_val = reg.read(thingie)
					return reg_val
				end
			elsif hkey == 'HKEY_CURRENT_USER'
				Win32::Registry::HKEY_CURRENT_USER.open(subkey) do |reg|
					reg_type, reg_val = reg.read(subkey)
					return reg_val
				end
			else
				respond "--- registry_get: bad key (#{key})"
				return nil
			end
		rescue
			$stderr.puts "error: registry_get: #{$!}"
			$stderr.puts $!.backtrace
			return nil
		end
	else
		if ENV['WINEPREFIX'] and File.exists?(ENV['WINEPREFIX'])
			wine_dir = ENV['WINEPREFIX']
		elsif ENV['HOME'] and File.exists?(ENV['HOME'] + '/.wine')
			wine_dir = ENV['HOME'] + '/.wine'
		else
			return false
		end
		if File.exists?(wine_dir + '/system.reg')
			if hkey == 'HKEY_LOCAL_MACHINE'
				reg_file = File.open(wine_dir + '/system.reg')
				reg_data = reg_file.readlines
				reg_file.close
				lookin = false
				result = false
				subkey = '[' + subkey.gsub('\\', '\\\\\\') + ']'
				if thingie.nil? or thingie.empty?
					thingie = '@'
				else
					thingie = '"' + thingie + '"'
				end
				reg_data.each { |line|
					if line[0...subkey.length] == subkey
						lookin = true
					elsif line =~ /^\[/
						lookin = false
					elsif lookin and line =~ /^#{thingie}="(.*)"$/i
						result = $1.split('\\"').join('"').split('\\\\').join('\\')
						break
					end
				}
				return result
			else
				return false
			end
		else
			return false
		end
	end
end

def registry_put(key, value)
	hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures
	if HAVE_REGISTRY
		begin
			if hkey == 'HKEY_LOCAL_MACHINE'
				if value.class == String
					Win32::Registry::HKEY_LOCAL_MACHINE.open(subkey,Win32::Registry::KEY_WRITE).write(thingie,Win32::Registry::REG_SZ,value)
				elsif value.class == Fixnum
					Win32::Registry::HKEY_LOCAL_MACHINE.open(subkey,Win32::Registry::KEY_WRITE).write(thingie,Win32::Registry::REG_DWORD,value)
				end
			elsif hkey == 'HKEY_CURRENT_USER'
				if value.class == String
					Win32::Registry::HKEY_CURRENT_USER.open(subkey,Win32::Registry::KEY_WRITE).write(thingie,Win32::Registry::REG_SZ,value)
				elsif value.class == Fixnum
					Win32::Registry::HKEY_CURRENT_USER.open(subkey,Win32::Registry::KEY_WRITE).write(thingie,Win32::Registry::REG_DWORD,value)
				end
			else
				return false
			end
		rescue
			return false
			$stderr.puts "error: registry_put: #{$!}"
			$stderr.puts $!.backtrace
		end
		return true
	else
		if ENV['WINEPREFIX'] and File.exists?(ENV['WINEPREFIX'])
			wine_dir = ENV['WINEPREFIX']
		elsif ENV['HOME'] and File.exists?(ENV['HOME'] + '/.wine')
			wine_dir = ENV['HOME'] + '/.wine'
		else
			return false
		end
		if File.exists?(wine_dir)
			if thingie.nil? or thingie.empty?
				thingie = '@'
			else
				thingie = '"' + thingie + '"'
			end
			# gsub sucks for this..
			value = value.split('\\').join('\\\\')
			value = value.split('"').join('\"')
			begin
				regedit_data = "REGEDIT4\n\n[#{hkey}\\#{subkey}]\n#{thingie}=\"#{value}\"\n\n"
				File.open('wine.reg', 'w') { |f| f.write(regedit_data) }
				system('wine regedit wine.reg')
				sleep "0.2".to_f
				File.delete('wine.reg')
			rescue
				return false
			end
			return true
		end
	end
end

def find_hosts_dir
	(windir = ENV['windir']) || (windir = ENV['SYSTEMROOT'])
	if HAVE_REGISTRY
		if hosts_dir = registry_get('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Tcpip\Parameters\DataBasePath')
			return hosts_dir.gsub(/%SystemRoot%/, windir)
		elsif hosts_dir = registry_get('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\DataBasePath')
			return hosts_dir.gsub(/%SystemRoot%/, windir)
		end
	end
	if windir
		winxp = "\\system32\\drivers\\etc\\"
		win98 = "\\"
		if File.exists?(windir + winxp + "hosts.bak")
			heal_hosts(windir + winxp)
			return windir + winxp
		elsif File.exists?(windir + win98 + "hosts.bak")
			heal_hosts(windir + win98)
			return windir + win98
		elsif File.exists?(windir + winxp + "hosts")
			return windir + winxp
		elsif File.exists?(windir + win98 + "hosts")
			return windir + win98
		end
	end
	if Dir.pwd.to_s[0..1] =~ /(C|D|E|F|G|H)/
		prefix = "#{$1.dup}:"
	else
		prefix = String.new
	end
	winxp_pro = "#{prefix}\\winnt\\system32\\drivers\\etc\\"
	winxp_home = "#{prefix}\\windows\\system32\\drivers\\etc\\"
	win98 = "#{prefix}\\windows\\"
	nix = "/etc/"
	[ winxp_pro, winxp_home, win98, nix ].each { |windir|
		if File.exists?(windir + "hosts.bak") or File.exists?(windir + "hosts")
			heal_hosts(windir)
			return windir
		end
	}
	winxp_pro.sub!(/[A-Z]:/, '')
	winxp_home.sub!(/[A-Z]:/, '')
	win98.sub!(/[A-Z]:/, '')
	[ "hosts" ].each { |fname|
		[ "C:", "D:", "E:", "F:", "G:" ].each { |drive|
			[ winxp_pro, winxp_home, win98 ].each { |windir|
				if File.exists?(drive + windir + "hosts.bak") or File.exists?(drive + windir + "hosts")
					heal_hosts(drive + windir)
					return drive + windir
				end
			}
		}
	}
	nil
end

def hack_hosts(hosts_dir, game_host)
	hosts_dir += File::Separator unless hosts_dir[-1..-1] =~ /\/\\/
	at_exit { heal_hosts(hosts_dir) }
	begin
		begin
			unless File.exists?("#{hosts_dir}hosts.bak")
				File.open("#{hosts_dir}hosts") { |infile|
					File.open("#{$temp_dir}hosts.sav", 'w') { |outfile|
						outfile.write(infile.read)
					}
				}
			end
		rescue
			File.unlink("#{$temp_dir}hosts.sav") if File.exists?("#{$temp_dir}hosts.sav")
		end
		if File.exists?("#{hosts_dir}hosts.bak")
			sleep 1
			if File.exists?("#{hosts_dir}hosts.bak")
				heal_hosts(hosts_dir)
			end
		end
		File.open("#{hosts_dir}hosts") { |file|
			File.open("#{hosts_dir}hosts.bak", 'w') { |f|
				f.write(file.read)
			}
		}
		File.open("#{hosts_dir}hosts", 'w') { |file|
			file.puts "127.0.0.1\t\tlocalhost\r\n127.0.0.1\t\t#{game_host}"
		}
	rescue SystemCallError
		$stdout.puts "--- error: hack_hosts: #{$!}"
		$stderr.puts "error: hack_hosts: #{$!}"
		$stderr.puts $!.backtrace
		exit(1)
	end
end

def heal_hosts(hosts_dir)
	hosts_dir += File::Separator unless hosts_dir[-1..-1] =~ /\/\\/
	begin
		if File.exists? "#{hosts_dir}hosts.bak"
			File.open("#{hosts_dir}hosts.bak") { |infile|
				File.open("#{hosts_dir}hosts", 'w') { |outfile|
					outfile.write(infile.read)
				}
			}
			File.unlink "#{hosts_dir}hosts.bak"
		end
	rescue
		$stdout.puts "--- error: heal_hosts: #{$!}"
		$stderr.puts "error: heal_hosts: #{$!}"
		$stderr.puts $!.backtrace
		exit(1)
	end
end

$link_highlight_start = "\207"
$link_highlight_end = "\240"

def sf_to_wiz(line)
	# fixme: voln thoughts
	begin
		return line if line == "\r\n"
	
		if $sftowiz_multiline
			$sftowiz_multiline = $sftowiz_multiline + line
			line = $sftowiz_multiline
		end
		if (line.scan(/<pushStream[^>]*\/>/).length > line.scan(/<popStream[^>]*\/>/).length)
			$sftowiz_multiline = line
			return nil
		end
		if (line.scan(/<style id="\w+"[^>]*\/>/).length > line.scan(/<style id=""[^>]*\/>/).length)
			$sftowiz_multiline = line
			return nil
		end
		$sftowiz_multiline = nil
	
		if line =~ /<LaunchURL src="(\/gs4\/play\/cm\/loader.asp[^"]*)" \/>/
			$_CLIENT_.puts "\034GSw00005\r\nhttps://www.play.net#{$1}\r\n"
		end
		if line =~ /<pushStream id="thoughts"[^>]*>(?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\s*([\s\[\]A-Za-z]+)?:(.*?)<popStream\/>/m
			line = line.sub(/<pushStream id="thoughts"[^>]*>(?:<a[^>]*>)?[A-Z][a-z]+(?:<\/a>)?\s*[\s\[\]A-Za-z]*:.*?<popStream\/>/m, "You hear the faint thoughts of #{$1} echo in your mind:\r\n#{$2}#{$3}")
		end
		if line =~ /<stream id="thoughts"[^>]*>([^:]+): (.*?)<\/stream>/m
			line = line.sub(/<stream id="thoughts"[^>]*>.*?<\/stream>/m, "You hear the faint thoughts of #{$1} echo in your mind:\r\n#{$2}")
		end
		if line =~ /<pushStream id="familiar"[^>]*>(.*)<popStream\/>/m
			line = line.sub(/<pushStream id="familiar"[^>]*>.*<popStream\/>/m, "\034GSe\r\n#{$1}\034GSf\r\n")
		end
		if line =~ /<pushStream id="death"\/>(.*?)<popStream\/>/m
			line = line.sub(/<pushStream id="death"\/>.*?<popStream\/>/m, "\034GSw00003\r\n#{$1}\034GSw00004\r\n")
		end
		if line =~ /<style id="roomName" \/>(.*?)<style id=""\/>/m
			line = line.sub(/<style id="roomName" \/>.*?<style id=""\/>/m, "\034GSo\r\n#{$1}\034GSp\r\n")
		end
		if line =~ /<style id="roomDesc"\/>(.*?)<style id=""\/>/m
			desc = $1.gsub(/<a[^>]*>/, $link_highlight_start).gsub("</a>", $link_highlight_end)
			line = line.sub(/<style id="roomDesc"\/>.*?<style id=""\/>/m, "\034GSH\r\n#{desc}\034GSI\r\n")
		end
		line = line.gsub("</prompt>\r\n", "</prompt>")
		line = line.gsub("<pushBold/>", "\034GSL\r\n")
		line = line.gsub("<popBold/>", "\034GSM\r\n")
		line = line.gsub(/<pushStream id=["'](?:spellfront|inv|bounty|society)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
		line = line.gsub(/<stream id="Spells">.*?<\/stream>/m, '')
		line = line.gsub(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
		line = line.gsub(/<[^>]+>/, '')
		line = line.gsub('&gt;', '>')
		line = line.gsub('&lt;', '<')
		return nil if line.gsub("\r\n", '').length < 1
		return line
	rescue
		$_CLIENT_.puts "--- Error: sf_to_wiz: #{$!}"
		$_CLIENT_.puts '$_SERVERSTRING_: ' + $_SERVERSTRING_.to_s
	end
end

def strip_xml(line)
	return line if line == "\r\n"

	if $strip_xml_multiline
		$strip_xml_multiline = $strip_xml_multiline + line
		line = $strip_xml_multiline
	end
	if (line.scan(/<pushStream[^>]*\/>/).length > line.scan(/<popStream[^>]*\/>/).length)
		$strip_xml_multiline = line
		return nil
	end
	$strip_xml_multiline = nil

	line = line.gsub(/<pushStream id=["'](?:spellfront|inv|bounty|society)["'][^>]*\/>.*?<popStream[^>]*>/m, '')
	line = line.gsub(/<stream id="Spells">.*?<\/stream>/m, '')
	line = line.gsub(/<(compDef|inv|component|right|left|spell|prompt)[^>]*>.*?<\/\1>/m, '')
	line = line.gsub(/<[^>]+>/, '')
	line = line.gsub('&gt;', '>')
	line = line.gsub('&lt;', '<')

	return nil if line.gsub("\n", '').gsub("\r", '').gsub(' ', '').length < 1
	return line
end

def monsterbold_start
	if $fake_stormfront
		"\034GSL\r\n"
	elsif $stormfront
		'<pushBold/>'
	else
		''
	end
end

def monsterbold_end
	if $fake_stormfront
		"\034GSM\r\n"
	elsif $stormfront
		'<popBold/>'
	else
		''
	end
end

def install_to_registry(psinet_compatible = false)
	Dir.chdir(File.dirname($PROGRAM_NAME))
	launch_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\')
	launch_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory')
	return false unless launch_cmd or launch_dir
	if RUBY_PLATFORM =~ /win|mingw/i
		if ruby_dir = ENV['RUBY_PATH'] and File.exists?(ruby_dir)
			ruby_dir = "#{ruby_dir.tr('/', "\\")}\\"
		elsif ruby_dir = registry_get('HKEY_LOCAL_MACHINE\Software\RubyInstaller\DefaultPath')
			ruby_dir = "#{ruby_dir.tr('/', "\\")}\\bin\\"
		else
			ruby_dir = ''
		end
		win_lich_dir = $lich_dir.tr('/', "\\")

		if lich_exe = ENV['OCRA_EXECUTABLE']
			lich_launch_cmd = "\"#{ENV['OCRA_EXECUTABLE']}\" %1"
			lich_launch_dir = "\"#{ENV['OCRA_EXECUTABLE']}\" "
		elsif psinet_compatible
			File.open("#{$lich_dir}lich.bat", 'w') { |f| f.puts "start /D\"#{ruby_dir}\" rubyw.exe \"#{win_lich_dir}#{$PROGRAM_NAME.split(/\/|\\/).last}\" %1 %2 %3 %4 %5 %6 %7 %8 %9" }
			lich_launch_cmd = "\"#{win_lich_dir}lich.bat\" %1"
			lich_launch_dir = "\"#{win_lich_dir}lich.bat\" "
		else
			lich_launch_cmd = "\"#{ruby_dir}rubyw.exe\" \"#{win_lich_dir}#{$PROGRAM_NAME.split(/\/|\\/).last}\" %1"
			lich_launch_dir = "\"#{ruby_dir}rubyw.exe\" \"#{win_lich_dir}#{$PROGRAM_NAME.split(/\/|\\/).last}\" "
		end
	else
		lich_launch_cmd = "#{$lich_dir}#{$PROGRAM_NAME.split(/\/|\\/).last} %1"
		lich_launch_dir = "#{$lich_dir}#{$PROGRAM_NAME.split(/\/|\\/).last} "
	end
	result = true
	if launch_cmd
		if launch_cmd =~ /lich/i
			$stdout.puts "--- warning: Lich appears to already be installed to the registry"
			$stderr.puts "warning: Lich appears to already be installed to the registry"
			$stderr.puts 'info: launch_cmd: ' + launch_cmd
		else
			registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\RealCommand', launch_cmd) || result = false
			registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\', lich_launch_cmd) || result = false
		end
	end
	if launch_dir
		if launch_dir =~ /lich/i
			$stdout.puts "--- warning: Lich appears to already be installed to the registry"
			$stderr.puts "warning: Lich appears to already be installed to the registry"
			$stderr.puts 'info: launch_dir: ' + launch_dir
		else
			registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\RealDirectory', launch_dir) || result = false
			registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory', lich_launch_dir) || result = false
		end
	end
	unless RUBY_PLATFORM =~ /win|mingw/i
		wine = `which wine`.strip
		if File.exists?(wine)
			registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Wine', wine)
		end
	end
	return result
end

def uninstall_from_registry
	real_launch_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\RealCommand')
	real_launch_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\RealDirectory')
	unless (real_launch_cmd and not real_launch_cmd.empty?) or (real_launch_dir and not real_launch_dir.empty?)
		$stdout.puts "--- warning: Lich does not appear to be installed to the registry"
		$stderr.puts "warning: Lich does not appear to be installed to the registry"
		return false
	end
	result = true
	if real_launch_cmd and not real_launch_cmd.empty?
		registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\', real_launch_cmd) || result = false
		registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\RealCommand', '') || result = false
	end
	if real_launch_dir and not real_launch_dir.empty?
		registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory', real_launch_dir) || result = false
		registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\RealDirectory', '') || result = false
	end
	return result
end

def do_client(client_string)
	client_string = UpstreamHook.run(client_string)
	return nil if client_string.nil?
	if client_string =~ /^(?:<c>)?#{$lich_char}(.+)$/
		cmd = $1
		if cmd =~ /^k$|^kill$|^stop$/
			if Script.running.empty?
				respond('--- Lich: no scripts to kill')
			else
				Script.running.last.kill
			end

		elsif cmd =~ /^p$|^pause$/
			script = Script.running.reverse.find { |scr| scr.paused == false }
			unless script
				respond('--- Lich: no scripts to pause')
			else
				script.pause
			end
			script = nil
		elsif cmd =~ /^u$|^unpause$/
			script = Script.running.reverse.find { |scr| scr.paused == true }
			unless script
				respond('--- Lich: no scripts to unpause')
			else
				script.unpause
			end
			script = nil
		elsif cmd =~ /^ka$|^kill\s?all$|^stop\s?all$/
			killed = false
			Script.running.each { |script|
				unless script.no_kill_all
					script.kill
					killed = true
				end
			}
			respond('--- Lich: no scripts to kill') unless killed
		elsif cmd =~ /^pa$|^pause\s?all$/
			paused = false
			Script.running.each { |script|
				unless script.paused or script.no_pause_all
					script.pause
					paused = true
				end
			}
			unless paused
				respond('--- Lich: no scripts to pause')
			end
			paused_scripts = nil
		elsif cmd =~ /^ua$|^unpause\s?all$/
			unpaused = false
			Script.running.each { |script|
				if script.paused and not script.no_pause_all
					script.unpause
					unpaused = true
				end
			}
			unless unpaused
				respond('--- Lich: no scripts to unpause')
			end
			unpaused_scripts = nil
		elsif cmd =~ /^(k|kill|stop|p|pause|u|unpause)\s(.+)/
			action = $1
			target = $2
			script = Script.running.find { |scr| scr.name == target }
			script = Script.hidden.find { |scr| scr.name == target } unless script
			script = Script.running.find { |scr| scr.name =~ /^#{target}/i } unless script
			script = Script.hidden.find { |scr| scr.name =~ /^#{target}/i } unless script
			if script.nil?
				respond("--- Lich: #{target}.lic does not appear to be running! Use ';list' or ';listall' to see what's active.")
			elsif action =~ /^k|kill|stop$/
				script.kill
				begin
					GC.start
				rescue
					respond('--- Lich: Error starting garbage collector. (3)')
				end
			elsif action =~/^p|pause$/
				script.pause
			elsif action =~/^u|unpause$/
				script.unpause
			end
			action = target = script = nil
		elsif cmd =~ /^list\s?(?:all)?$|^l(?:a)?$/i
			if cmd =~ /a(?:ll)?/i
				list = Script.running + Script.hidden
			else
				list = Script.running
			end
			unless list.empty?
				list.each_index { |index| if list[index].paused then list[index] = list[index].name + ' (paused)' end }
				respond("--- Lich: #{list.join(", ")}.")
			else
				respond("--- Lich: no active scripts.")
			end
			list = nil
		elsif cmd =~ /^force\s+(?:.+)$/
			script_name = Regexp.escape(cmd.split[1].chomp)
			vars = cmd.split[2..-1].join(' ').scan(/"[^"]+"|[^"\s]+/).collect { |val| val.gsub(/(?!\\)?"/,'') }
			force_start_script(script_name, vars)
		elsif cmd =~ /^send |^s /
			if cmd.split[1] == "to"
				script = (Script.running + Script.hidden).find { |scr| scr.name == cmd.split[2].chomp.strip } || script = (Script.running + Script.hidden).find { |scr| scr.name =~ /^#{cmd.split[2].chomp.strip}/i }
				if script
					msg = cmd.split[3..-1].join(' ').chomp
					if script.want_downstream
						script.downstream_buffer.push(msg)
					else
						script.unique_buffer.push(msg)
					end
					respond("--- sent to '#{script.name}': #{msg}")
				else
					respond("--- Lich: '#{cmd.split[2].chomp.strip}' does not match any active script!")
					return
				end
				script = nil
			else
				if Script.running.empty? and Script.hidden.empty?
					respond('--- Lich: no active scripts to send to.')
				else
					msg = cmd.split[1..-1].join(' ').chomp
					respond("--- sent: #{msg}")
					Script.new_downstream(msg)
				end
			end
		elsif eobj = /^(?:exec|e)(q)? (.+)$/.match(cmd)
			cmd_data = cmd.sub(/^(?:exec|execq|e|eq) /i, '')
			if eobj.captures.first.nil?
				start_exec_script(cmd_data, false)
			else
				# quiet mode
				start_exec_script(cmd_data, true)
			end
		elsif cmd =~ /^favs?(?: |$)(.*)?/i
			args = $1.split(' ')
			if (args[0].downcase == 'add') and (args[1] =~ /^all$|^global$/i) and not args[2].nil?
				Favs.add(args[2], args[3..-1], :global)
				respond "--- Lich: added #{args[2]} to the global favs list."
			elsif (args[0].downcase == 'add') and not args[1].nil?
				Favs.add(args[1], args[2..-1], :char)
				respond "--- Lich: added #{args[1]} to #{Char.name}'s favs list."
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (args[1] =~ /^all$|^global$/i) and not args[2].nil?
				if Favs.delete(args[2], :global)
					respond "--- Lich: removed #{args[2]} from the global favs list."
				else
					respond "--- Lich: #{args[2]} was not found in the global favs list."
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and not args[1].nil?
				if Favs.delete(args[1], :char)
					respond "--- Lich: removed #{args[1]} from #{Char.name}'s favs list."
				else
					respond "--- Lich: #{args[1]} was not found in #{Char.name}'s favs list."
				end
			elsif args[0].downcase == 'list'
				favs = Favs.list
				if favs['global'].empty?
					global_favs = 'none'
				else
					global_favs = favs['global'].keys.join(', ')
				end
				if favs[Char.name].empty?
					char_favs = 'none'
				else
					char_favs = favs[Char.name].keys.join(', ')
				end
				respond "--- Lich: Global favs: #{global_favs}"
				respond "--- Lich: #{Char.name}'s favs: #{char_favs}"
				favs = global_favs = char_favs = nil
			else
				respond
				respond 'Usage:'
				respond "       #{$clean_lich_char}favs add [global] <script name> <vars>"
				respond "       #{$clean_lich_char}favs delete [global] <script name>"
				respond "       #{$clean_lich_char}favs list"
				respond
			end
		elsif cmd =~ /^alias(?: |$)(.*)?/i
			args = $1.split(' ')
			if (args[0] =~ /^add$|^set$/i) and (args[1] =~ /^all$|^global$/i) and (args[2..-1].join(' ') =~ /([^=]+)=(.+)/)
				trigger, target = $1, $2
				Alias.add(trigger, target, :global)
				respond "--- Lich: added (#{trigger} => #{target}) to the global alias list."
			elsif (args[0] =~ /^add$|^set$/i) and (args[1..-1].join(' ') =~ /([^=]+)=(.+)/)
				trigger, target = $1, $2
				Alias.add(trigger, target, :char)
				respond "--- Lich: added (#{trigger} => #{target}) to #{Char.name}'s alias list."
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (args[1] =~ /^all$|^global$/i) and not args[2].nil?
				if Alias.delete(args[2], :global)
					respond "--- Lich: removed #{args[2]} from the global alias list."
				else
					respond "--- Lich: #{args[2]} was not found in the global alias list."
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and not args[1].nil?
				if Alias.delete(args[1], :char)
					respond "--- Lich: removed #{args[1]} from #{Char.name}'s alias list."
				else
					respond "--- Lich: #{args[1]} was not found in #{Char.name}'s alias list."
				end
			elsif args[0].downcase == 'list'
				alist = Alias.list
				if alist['global'].empty? and alist[Char.name].empty?
					respond "\n--- You currently have no Lich aliases.\n"
				end
				unless alist['global'].empty?
					respond '--- Global aliases'
					alist['global'].each_pair { |trigger,target| respond "   #{trigger} => #{target}" }
				end
				unless alist[Char.name].empty?
					respond "--- #{Char.name}'s aliases"
					alist[Char.name].each_pair { |trigger,target| respond "   #{trigger} => #{target}" }
				end
				alist = nil
			else
				respond
				respond 'Usage:'
				respond "       #{$clean_lich_char}alias add [global] <trigger>=<alias>"
				respond "       #{$clean_lich_char}alias delete [global] <trigger>"
				respond "       #{$clean_lich_char}alias list"
				respond
			end
		elsif cmd =~ /^set(?:ting|tings)?(?: |$)(.*)?/i
			args = $1.split(' ')
			if (args[0].downcase == 'change') and (args[1] =~ /^all$|^global$/i) and (var_name = args[2]) and (value = args[3..-1].join(' '))
				UserVars.change(var_name, value, :global)
				respond "--- Lich: global setting changed (#{var_name}: #{value})"
			elsif (args[0].downcase == 'change') and (var_name = args[1]) and (value = args[2..-1].join(' '))
				UserVars.change(var_name, value, :char)
				respond "--- Lich: #{Char.name}'s setting changed (#{var_name}: #{value})"
			elsif (args[0].downcase == 'add') and (args[1] =~ /^all$|^global$/i) and (var_name = args[2]) and (value = args[3..-1].join(' '))
				UserVars.add(var_name, value, :global)
				respond "--- Lich: added to global setting (#{var_name}: #{value})"
			elsif (args[0].downcase == 'add') and (var_name = args[1]) and (value = args[2..-1].join(' '))
				UserVars.add(var_name, value, :char)
				respond "--- Lich: added to #{Char.name}'s setting (#{var_name}: #{value})"
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (args[1] =~ /^all$|^global$/i) and (var_name = args[2]) and args[3]
				rem_value = args[3..-1].join(' ')
				echo rem_value.inspect
				value = UserVars.list['global'][var_name].to_s.split(', ')
				if value.delete(rem_value)
					UserVars.change(var_name, value.join(', '), :global)
					respond "--- Lich: removed '#{rem_value}' from global setting '#{var_name}'"
				else
					respond "--- Lich: could not find '#{rem_value}' in global setting '#{var_name}'"
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (args[1] =~ /^all$|^global$/i) and (var_name = args[2])
				if UserVars.delete(var_name, :global)
					respond "--- Lich: removed global setting '#{var_name}'"
				else
					respond "--- Lich: could not find global setting '#{var_name}'"
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (var_name = args[1]) and args[2]
				rem_value = args[2..-1].join(' ')
				respond rem_value.inspect
				value = UserVars.list[XMLData.name][var_name].to_s.split(', ')
				if value.delete(rem_value)
					UserVars.change(var_name, value.join(', '), :char)
					respond "--- Lich: removed '#{rem_value}' from #{Char.name}'s setting '#{var_name}'"
				else
					respond "--- Lich: could not find '#{rem_value}' in #{Char.name}'s setting '#{var_name}'"
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (var_name = args[1])
				if UserVars.delete(var_name, :char)
					respond "--- Lich: removed #{Char.name}'s setting '#{var_name}'"
				else
					respond "--- Lich: could not find #{Char.name}'s setting '#{var_name}'"
				end
			elsif args[0].downcase == 'list'
				user_vars = UserVars.list
				if user_vars['global'].empty? and user_vars[Char.name].empty?
					respond "\n--- You currently have no Lich settings.\n"
				end
				unless user_vars['global'].empty?
					respond '--- Global settings'
					user_vars['global'].each_pair { |name,value| respond "   #{name}: #{value}" }
				end
				unless user_vars[Char.name].empty?
					respond "--- #{Char.name}'s settings"
					user_vars[Char.name].each_pair { |name,value| respond "   #{name}: #{value}" }
				end
			else
				respond
				respond "Usage:"
				respond "       #{$clean_lich_char}settings add [global] <setting name> <value>"
				respond "       #{$clean_lich_char}settings change [global] <setting name> <value>"
				respond "       #{$clean_lich_char}settings delete [global] <setting name> [value]"
				respond "       #{$clean_lich_char}settings list"
				respond
			end
		elsif cmd =~ /^help$/i
			respond
			respond "Lich v#{$version}"
			respond
			respond 'built-in commands:'
			respond "   #{$clean_lich_char}<script name>             start a script"
			respond "   #{$clean_lich_char}pause <script name>       pause a script"
			respond "   #{$clean_lich_char}p <script name>           ''"
			respond "   #{$clean_lich_char}unpause <script name>     unpause a script"
			respond "   #{$clean_lich_char}u <script name>           ''"
			respond "   #{$clean_lich_char}kill <script name>        kill a script"
			respond "   #{$clean_lich_char}k <script name>           ''"
			respond "   #{$clean_lich_char}pause                     pause the most recently started script that isn't aready paused"
			respond "   #{$clean_lich_char}p                         ''"
			respond "   #{$clean_lich_char}unpause                   unpause the most recently started script that is paused"
			respond "   #{$clean_lich_char}u                         ''"
			respond "   #{$clean_lich_char}kill                      kill the most recently started script"
			respond "   #{$clean_lich_char}k                         ''"
			respond "   #{$clean_lich_char}pause all                 pause all scripts"
			respond "   #{$clean_lich_char}pa                        ''"
			respond "   #{$clean_lich_char}unpause all               unpause all scripts"
			respond "   #{$clean_lich_char}ua                        ''"
			respond "   #{$clean_lich_char}kill all                  kill all scripts"
			respond "   #{$clean_lich_char}ka                        ''"
			respond
			respond "   #{$clean_lich_char}force <script name>       start a script even if it's already running"
			respond "   #{$clean_lich_char}send <line>               send a line to all scripts as if it came from the game"
			respond "   #{$clean_lich_char}send to <script> <line>   send a line to a specific script"
			respond
			respond "   #{$clean_lich_char}favs add [global] <script name> [vars]   automatically start a script start each time Lich starts"
			respond "   #{$clean_lich_char}favs delete [global] <script name>       "
			respond "   #{$clean_lich_char}favs list                                "
			respond
			respond "   #{$clean_lich_char}alias add [global] <trigger>=<alias>   "
			respond "   #{$clean_lich_char}alias delete [global] <trigger>        "
			respond "   #{$clean_lich_char}alias list                             "
			respond
			respond 'If you liked this help message, you might also enjoy:'
			respond "   #{$clean_lich_char}chat help      (lnet must be running)"
			respond "   #{$clean_lich_char}magic help     (infomon must be running)"
			respond "   #{$clean_lich_char}go2 help"
			respond "   #{$clean_lich_char}repository help"
			respond "   #{$clean_lich_char}updater help"
			respond "   #{$clean_lich_char}setting help"
			respond
		else
			script_name = Regexp.escape(cmd.split.first.chomp)
			vars = cmd.split[1..-1].join(' ').scan(/"[^"]+"|[^"\s]+/).collect { |val| val.gsub(/(?!\\)?"/,'') }
			start_script(script_name, vars)
		end
	else
		if $offline_mode
			respond "--- Lich: offline mode: ignoring #{client_string}"
		else
			$_SERVER_.puts client_string
		end
		$_CLIENTBUFFER_.push client_string
	end
	Script.new_upstream(client_string)
end

sock_keepalive_proc = proc { |sock|
	err_msg = proc { |err|
		err ||= $!
		$stdout.puts "--- error: sock_keepalive_proc: #{err}"
		$stderr.puts "error: sock_keepalive_proc: #{err}"
		$stderr.puts err.backtrace
	}
	begin
		sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
	rescue
		err_msg.call($!)
	rescue Exception
		err_msg.call($!)
	end
}

read_psinet_installstate = proc { |file_name|
	psinet_installstate = Hash.new
	File.open(file_name) { |f|
		data = f.readlines
		the_keys = Array.new
		data.find_all { |line| line =~ /<Keys/i }.collect { |line| /ref-([0-9]+)/i.match(line).captures.first }.each { |ref|
			data.join("\n").scan(/<SOAP-ENC:Array id="ref-#{ref}".*?<\/SOAP-ENC:Array>/m).each { |stupid|
				stupid.scan(/<item.*?<\/item>|<item.*?\/>/).each { |whore|
					whore =~ /<item .*?id="ref-([0-9]+).*?>(.*?)<\/item>/
					the_keys.push($2)
				}
			}
		}
		the_values = Array.new
		data.find_all { |line| line =~ /<Values/i }.collect { |line| /ref-([0-9]+)/i.match(line).captures.first }.each { |ref|
			data.join("\n").scan(/<SOAP-ENC:Array id="ref-#{ref}".*?<\/SOAP-ENC:Array>/m).each { |stupid|
				stupid.scan(/<item.*?<\/item>|<item.*?\/>/).each { |whore|
					whore =~ /<item .*?id="ref-([0-9]+).*?>(.*?)<\/item>/
					the_values.push($2)
				}
			}
		}
		the_keys.each_index { |index| psinet_installstate[the_keys[index]] = the_values[index] }
	}
	psinet_installstate
}

get_real_launcher_cmd = proc {
	psinet_dir = nil
	launcher_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\RealCommand')
	psinet_dir = $1 if launcher_cmd =~ /^"?(.*?)PsiNet2.exe/i
	unless (launcher_cmd =~ /launcher\.exe(?: |")/i)
		launcher_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\')
		psinet_dir = $1 if launcher_cmd =~ /^"?(.*?)PsiNet2.exe/i
	end
	unless (launcher_cmd =~ /launcher\.exe(?: |")/i)
		if psinet_dir and File.exists?(psinet_dir)
			Dir.entries(psinet_dir).each { |f|
				if f =~ /^SageInstaller.*\.InstallState$/i
					psinet_installstate = read_psinet_installstate.call("#{psinet_dir}#{f}")
					launcher_cmd = psinet_installstate['UninstallSalCommand'].gsub(/&#([0-9]+);/) { $1.to_i.chr }
					break
				end
			}
		end
	end
	unless (launcher_cmd =~ /launcher\.exe(?: |")/i)
		launcher_cmd = false
	end
	launcher_cmd
}

fix_game_host_port = proc { |gamehost,gameport|
	if (gamehost == 'gs-plat.simutronics.net') and (gameport == '10121')
		gamehost = 'storm.gs4.game.play.net'
		gameport = '10124'
	elsif (gamehost == 'gs3.simutronics.net') and (gameport == '4900')
		gamehost = 'storm.gs4.game.play.net'
		gameport = '10024'
	elsif (gamehost == 'prime.dr.game.play.net') and (gameport == '4901')
		gamehost = 'dr.simutronics.net'
		gameport = '11024'
	end
	[ gamehost, gameport ]
}

begin
	undef :abort
	alias :mana :checkmana
	alias :mana? :checkmana
	alias :max_mana :maxmana
	alias :health :checkhealth
	alias :health? :checkhealth
	alias :spirit :checkspirit
	alias :spirit? :checkspirit
	alias :stamina :checkstamina
	alias :stamina? :checkstamina
	alias :stunned? :checkstunned
	alias :bleeding? :checkbleeding
	alias :reallybleeding? :checkreallybleeding
	alias :dead? :checkdead
	alias :hiding? :checkhidden
	alias :hidden? :checkhidden
	alias :hidden :checkhidden
	alias :checkhiding :checkhidden
	alias :invisible? :checkinvisible
	alias :standing? :checkstanding
	alias :stance? :checkstance
	alias :stance :checkstance
	alias :joined? :checkgrouped
	alias :checkjoined :checkgrouped
	alias :group? :checkgrouped
	alias :myname? :checkname
	alias :active? :checkspell
	alias :righthand? :checkright
	alias :lefthand? :checkleft
	alias :righthand :checkright
	alias :lefthand :checkleft
	alias :mind? :checkmind
	alias :checkactive :checkspell
	alias :forceput :fput
	alias :send_script :send_scripts
	alias :stop_scripts :stop_script
	alias :kill_scripts :stop_script
	alias :kill_script :stop_script
	alias :fried? :checkfried
	alias :saturated? :checksaturated
	alias :webbed? :checkwebbed
	alias :pause_scripts :pause_script
	alias :roomdescription? :checkroomdescrip
	alias :prepped? :checkprep
	alias :checkprepared :checkprep
	alias :unpause_scripts :unpause_script
	alias :priority? :setpriority
	alias :checkoutside :outside?
	alias :toggle_status :status_tags
	alias :encumbrance? :checkencumbrance
	alias :bounty? :checkbounty
	alias $_PSINET_ $_CLIENT_
	alias $_PSINETSTRING_ $_CLIENTSTRING_
	alias $_PSINETBUFFER_ $_CLIENTBUFFER_
rescue
	$stdout.puts "--- error: #{$!}"
	$stderr.puts "error: #{$!}"
	$stderr.puts $!.backtrace
end












	
if RUBY_PLATFORM =~ /win|mingw/i
	wine_dir = wine_bin = nil
else
	if ENV['WINEPREFIX'] and File.exists?(ENV['WINEPREFIX'])
		wine_dir = ENV['WINEPREFIX']
	elsif ENV['HOME'] and File.exists?(ENV['HOME'] + '/.wine')
		wine_dir = ENV['HOME'] + '/.wine'
	else
		wine_dir = nil
	end
	wine_bin = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Wine')
	wine_bin = nil unless wine_bin and File.exists?(wine_bin)
end

if ARGV.include?('--install')
	psinet_compatible = ARGV.any? { |arg| arg =~ /^--psinet-compat(?:ible)?/ }
	if install_to_registry(psinet_compatible)
		$stdout.puts 'Install was successful.'
		$stderr.puts 'Install was successful.'
	else
		$stdout.puts 'Install failed.'
		$stderr.puts 'Install failed.'
	end
	exit
elsif ARGV.include?('--uninstall')
	if uninstall_from_registry
		$stdout.puts 'Uninstall was successful.'
		$stderr.puts 'Uninstall was successful.'
	else
		$stdout.puts 'Uninstall failed.'
		$stderr.puts 'Uninstall failed.'
	end
	exit
end

if launch_file = ARGV.find { |arg| arg =~ /\.sal$|Gse\.~xt$/i }
	unless File.exists?(launch_file)
		$stderr.puts "warning: launch file does not exist: #{launch_file}"
		launch_file = ARGV.join(' ').slice(/[A-Z]:\\.+\.(?:sal|~xt)/i)
		unless File.exists?(launch_file)
			$stderr.puts "warning: launch file does not exist: #{launch_file}"
			if wine_dir
				launch_file = "#{wine_dir}/drive_c/#{launch_file[3..-1].split('\\').join('/')}"
				unless File.exists?(launch_file)
					$stdout.puts "error: launch file does not exist: #{launch_file}"
					$stderr.puts "error: launch file does not exist: #{launch_file}"
					exit
				end
			end
		end
	end
	$stderr.puts "info: launch file: #{launch_file}"
	if launch_file =~ /SGE\.sal/i
		unless launcher_cmd = get_real_launcher_cmd.call
			$stdout.puts 'error: failed to find the Simutronics launcher'
			$stderr.puts 'error: failed to find the Simutronics launcher'
			exit(1)
		end
		launcher_cmd = "#{wine_bin} #{launcher_cmd}" if wine_bin
		launcher_cmd.sub!('%1', launch_file)
		$stderr.puts "info: launcher_cmd: #{launcher_cmd}"
		system(launcher_cmd)
		exit
	end
else
	launch_file = nil
	$stderr.puts "info: no launch file given"
end

if arg = ARGV.find { |a| (a == '-g') or (a == '--game') }
	game_host, game_port = ARGV[ARGV.index(arg)+1].split(':')
	game_port = game_port.to_i
	if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
		$frontend = 'stormfront'
		$fake_stormfront = false
	elsif ARGV.any? { |arg| (arg == '-w') or (arg == '--wizard') }
		$frontend = 'wizard'
		$fake_stormfront = true
	else
		$frontend = 'unknown'
		$fake_stormfront = true
	end
elsif ARGV.include?('--gemstone')
	ARGV.delete('--gemstone')
	if ARGV.include?('--platinum')
		ARGV.delete('--platinum')
		$platinum = true
		if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
			game_host = 'storm.gs4.game.play.net'
			game_port = 10124
			$frontend = 'stormfront'
		else
			game_host = 'gs-plat.simutronics.net'
			game_port = 10121
			$frontend = 'wizard'
		end
	else
		$platinum = false
		if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
			game_host = 'storm.gs4.game.play.net'
			game_port = 10024
			$frontend = 'stormfront'
		else
			game_host = 'gs3.simutronics.net'
			game_port = 4900
			$frontend = 'wizard'
		end
	end
elsif ARGV.include?('--dragonrealms')
	if ARGV.include?('--platinum')
		$platinum = true
		if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
			$stdout.puts "fixme"
			$stderr.puts "fixme"
			exit
			$frontend = 'stormfront'
		else
			$stdout.puts "fixme"
			$stderr.puts "fixme"
			exit
			$frontend = 'wizard'
		end
	else
		$platinum = false
		if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
			$frontend = 'stormfront'
			$stdout.puts "fixme"
			$stderr.puts "fixme"
			exit
		else
			game_host = 'dr.simutronics.net'
			game_port = 4901
			$frontend = 'wizard'
		end
	end
else
	game_host, game_port = nil, nil
	$stderr.puts "info: no force-mode info given"
end

$stormfront = true

if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
	$fake_stormfront = false
else
	$fake_stormfront = true
end

main_thread = Thread.new {

	       test_mode = false
	             sge = nil
	    $ZLIB_STREAM = false
	 $SEND_CHARACTER = '>'

	LichSettings.load
	LichSettings['lich_char'] ||= ';'
	LichSettings['cache_serverbuffer'] = false if LichSettings['cache_serverbuffer'].nil?
	LichSettings['serverbuffer_max_size'] ||= 300
	LichSettings['serverbuffer_min_size'] ||= 200
	LichSettings['clientbuffer_max_size'] ||= 100
	LichSettings['clientbuffer_min_size'] ||= 50

	$clean_lich_char = LichSettings['lich_char']
	$lich_char = Regexp.escape("#{$clean_lich_char}")

	launch_data = nil

	if HAVE_GTK and ARGV.empty?
		Gtk.queue {

			login_server = nil
			window = nil

			msgbox = proc { |msg|
				dialog = Gtk::MessageDialog.new(window, Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::QUESTION, Gtk::MessageDialog::BUTTONS_CLOSE, msg)
				dialog.run
				dialog.destroy
			}

			#
			# quick game entry tab
			#

			LichSettings['quick_game_entry'] ||= Hash.new
			if LichSettings['quick_game_entry'].empty?
				box = Gtk::HBox.new
				box.pack_start(Gtk::Label.new('You have no saved login info.'), true, true, 0)
				quick_game_entry_tab = Gtk::VBox.new
				quick_game_entry_tab.pack_start(box, true, true, 0)
			else
				quick_pass_entry = Gtk::Entry.new
				quick_pass_entry.visibility = false
	
				quick_pass_box = Gtk::HBox.new
				quick_pass_box.pack_end(quick_pass_entry, false, false, 5)
				quick_pass_box.pack_end(Gtk::Label.new('Password:'), false, false, 5)
	
				quick_table = Gtk::Table.new(LichSettings['quick_game_entry'].length, 3, true)
				row = 0
				LichSettings['quick_game_entry'].keys.sort.each { |char_name|
					label = Gtk::Label.new(char_name)
					play_button = Gtk::Button.new('Play')
					remove_button = Gtk::Button.new('Remove')
					quick_table.attach(label, 0, 1, row, row+1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
					quick_table.attach(play_button, 1, 2, row, row+1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
					quick_table.attach(remove_button, 2, 3, row, row+1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
					row += 1
					play_button.signal_connect('clicked') {
						play_button.sensitive = false
						begin
							login_server = TCPSocket.new('eaccess.play.net', 7900)
						rescue
							msgbox.call "error connecting to server: #{$!}"
							play_button.sensitive = true
						end
						if login_server
							login_server.puts "K\n"
							hashkey = login_server.gets
							if 'test'[0].class == String
								password = quick_pass_entry.text.split('').collect { |c| c.getbyte(0) }
								hashkey = hashkey.split('').collect { |c| c.getbyte(0) }
							else
								password = quick_pass_entry.text.split('').collect { |c| c[0] }
								hashkey = hashkey.split('').collect { |c| c[0] }
							end
							quick_pass_entry.text = String.new
							password.each_index { |i| password[i] = ((password[i]-32)^hashkey[i])+32 }
							password = password.collect { |c| c.chr }.join
							login_server.puts "A\t#{LichSettings['quick_game_entry'][char_name][0]}\t#{password}\n"
							password = nil
							response = login_server.gets
							login_key = /KEY\t([^\t]+)\t/.match(response).captures.first
							if login_key
								login_server.puts "M\n"
								response = login_server.gets
								if response =~ /^M\t/
									login_server.puts "F\t#{LichSettings['quick_game_entry'][char_name][1]}\n"
									response = login_server.gets
									if response =~ /NORMAL|PREMIUM|TRIAL/
										login_server.puts "G\t#{LichSettings['quick_game_entry'][char_name][1]}\n"
										login_server.gets
										login_server.puts "P\t#{LichSettings['quick_game_entry'][char_name][1]}\n"
										login_server.gets
										login_server.puts "C\n"
										response = login_server.gets
										login_server.puts "L\t#{LichSettings['quick_game_entry'][char_name][2]}\tSTORM\n"
										response = login_server.gets
										if response =~ /^L\t/
											login_server.close unless login_server.closed?
											launch_data = response.sub(/^L\tOK\t/, '').split("\t")
											if LichSettings['quick_game_entry'][char_name][3]
												launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, 'GAMEFILE=WIZARD.EXE').sub(/GAME=.+/, 'GAME=WIZ').sub(/FULLGAMENAME=.+/, 'FULLGAMENAME=Wizard Front End') }
											end
											main_thread.run
											window.destroy
										else
											login_server.close unless login_server.closed?
											msgbox.call("Unrecognized response from server. (#{response})")
											play_button.sensitive = true
										end
									else
										login_server.close unless login_server.closed?
										msgbox.call("Unrecognized response from server. (#{response})")
										play_button.sensitive = true
									end
								else
									login_server.close unless login_server.closed?
									msgbox.call("Unrecognized response from server. (#{response})")
									play_button.sensitive = true
								end
							else
								login_server.close unless login_server.closed?
								msgbox.call "Something went wrong... probably invalid user id and/or password.\nserver response: #{response}"
								play_button.sensitive = true
							end
						else
							msgbox.call "failed to connect to server"
							play_button.sensitive = true
						end
					}
					remove_button.signal_connect('clicked') {
						LichSettings['quick_game_entry'].delete(char_name)
						LichSettings.save
						label.visible = false
						play_button.visible = false
						remove_button.visible = false
					}
				}
	
				quick_game_entry_tab = Gtk::VBox.new
				quick_game_entry_tab.pack_start(quick_pass_box, false, false, 5)
				quick_game_entry_tab.pack_start(quick_table, false, false, 5)
			end

			#
			# game entry tab
			#

			user_id_entry = Gtk::Entry.new

			pass_entry = Gtk::Entry.new
			pass_entry.visibility = false

			login_table = Gtk::Table.new(2, 2, false)
			login_table.attach(Gtk::Label.new('User ID:'), 0, 1, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			login_table.attach(user_id_entry, 1, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			login_table.attach(Gtk::Label.new('Password:'), 0, 1, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			login_table.attach(pass_entry, 1, 2, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)

			disconnect_button = Gtk::Button.new(' Disconnect ')
			disconnect_button.sensitive = false

			connect_button = Gtk::Button.new(' Connect ')

			login_button_box = Gtk::HBox.new
			login_button_box.pack_end(connect_button, false, false, 5)
			login_button_box.pack_end(disconnect_button, false, false, 5)

			game_liststore = Gtk::ListStore.new(String, String)
			game_liststore.set_sort_column_id(1, Gtk::SORT_ASCENDING)

			game_renderer = Gtk::CellRendererText.new
			game_renderer.background = 'white'

			col = Gtk::TreeViewColumn.new("Select game:", game_renderer, :text => 1, :background_set => 2)
			col.resizable = true

			game_treeview = Gtk::TreeView.new(game_liststore)
			game_treeview.height_request = 160
			game_treeview.append_column(col)

			game_sw = Gtk::ScrolledWindow.new
			game_sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
			game_sw.add(game_treeview)

			char_liststore = Gtk::ListStore.new(String, String)
			char_liststore.set_sort_column_id(1, Gtk::SORT_ASCENDING)

			char_renderer = Gtk::CellRendererText.new
			char_renderer.background = 'white'

			col = Gtk::TreeViewColumn.new("Select character:", char_renderer, :text => 1, :background_set => 2)
			col.resizable = true

			char_treeview = Gtk::TreeView.new(char_liststore)
			char_treeview.height_request = 90
			char_treeview.append_column(col)

			char_sw = Gtk::ScrolledWindow.new
			char_sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
			char_sw.add(char_treeview)

			wizard_option = Gtk::RadioButton.new('Wizard')
			stormfront_option = Gtk::RadioButton.new(wizard_option, 'Stormfront')

			frontend_box = Gtk::HBox.new(false, 10)
			frontend_box.pack_start(wizard_option, false, false, 0)
			frontend_box.pack_start(stormfront_option, false, false, 0)

			make_quick_option = Gtk::CheckButton.new('Save this info for quick game entry')

			# fixme: add option to use launcher or not

			play_button = Gtk::Button.new(' Play ')
			play_button.sensitive = false

			play_button_box = Gtk::HBox.new
			play_button_box.pack_end(play_button, false, false, 5)

			game_entry_tab = Gtk::VBox.new
			game_entry_tab.pack_start(login_table, false, false, 0)
			game_entry_tab.pack_start(login_button_box, false, false, 0)
			game_entry_tab.pack_start(game_sw, true, true, 3)
			game_entry_tab.pack_start(char_sw, false, true, 3)
			game_entry_tab.pack_start(frontend_box, false, false, 3)
			game_entry_tab.pack_start(make_quick_option, false, false, 3)
			game_entry_tab.pack_start(play_button_box, false, false, 3)

			selected_game_code = nil

			connect_button.signal_connect('clicked') {
				connect_button.sensitive = false
				user_id_entry.sensitive = false
				pass_entry.sensitive = false
				begin
					login_server = TCPSocket.new('eaccess.play.net', 7900)
				rescue
					msgbox.call "error connecting to server: #{$!}"
					connect_button.sensitive = true
					user_id_entry.sensitive = true
					pass_entry.sensitive = true
				end
				disconnect_button.sensitive = true
				if login_server
					login_server.puts "K\n"
					hashkey = login_server.gets
					if 'test'[0].class == String
						password = pass_entry.text.split('').collect { |c| c.getbyte(0) }
						hashkey = hashkey.split('').collect { |c| c.getbyte(0) }
					else
						password = pass_entry.text.split('').collect { |c| c[0] }
						hashkey = hashkey.split('').collect { |c| c[0] }
					end
					pass_entry.text = String.new
					password.each_index { |i| password[i] = ((password[i]-32)^hashkey[i])+32 }
					password = password.collect { |c| c.chr }.join
					login_server.puts "A\t#{user_id_entry.text}\t#{password}\n"
					password = nil
					response = login_server.gets
					login_key = /KEY\t([^\t]+)\t/.match(response).captures.first
					if login_key
						login_server.puts "M\n"
						response = login_server.gets
						if response =~ /^M\t/
							response.sub(/^M\t/, '').scan(/[^\t]+\t[^\t]+/).each { |line|
								game_code, game_name = line.split("\t")
								login_server.puts "N\t#{game_code}\n"
								if login_server.gets =~ /STORM/
									iter = game_liststore.append
									iter[0] = game_code.strip
									iter[1] = game_name.strip
								end
							}
							disconnect_button.sensitive = true
						else
							login_server.close unless login_server.closed?
							msgbox.call "Unrecognized response from server (#{response})"
						end

					else
						login_server.close unless login_server.closed?
						disconnect_button.sensitive = false
						connect_button.sensitive = true
						user_id_entry.sensitive = true
						pass_entry.sensitive = true
						msgbox.call "Something went wrong... probably invalid user id and/or password.\nserver response: #{response}"
					end
				end
			}
			disconnect_button.signal_connect('clicked') {
				disconnect_button.sensitive = false
				play_button.sensitive = false
				game_liststore.clear
				char_liststore.clear
				login_server.close unless login_server.closed?
				connect_button.sensitive = true
				user_id_entry.sensitive = true
				pass_entry.sensitive = true
			}
			game_treeview.signal_connect('cursor-changed') {
				if selected_game_code != game_treeview.selection.selected[0]
					selected_game_code = game_treeview.selection.selected[0]
					char_liststore.clear
					if login_server and not login_server.closed?
						login_server.puts "F\t#{selected_game_code.upcase}\n"
						response = login_server.gets
						if response =~ /NORMAL|PREMIUM|TRIAL/
							login_server.puts "G\t#{selected_game_code.upcase}\n"
							login_server.gets
							login_server.puts "P\t#{selected_game_code.upcase}\n"
							login_server.gets
							login_server.puts "C\n"
							response = login_server.gets
							response.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+\t/, '').scan(/[^\t]+\t[^\t]+/).each { |line|
								char_code, char_name = line.split("\t")
								iter = char_liststore.append
								iter[0] = char_code.strip
								iter[1] = char_name.strip
							}
						elsif response =~ /NEW_TO_GAME/
							play_button.sensitive = false
						else
							msgbox.call("Unrecognized response from server. (#{response})")
							# fixme
						end
					else
						disconnect_button.sensitive = false
						play_button.sensitive = false
						connect_button.sensitive = true
						user_id_entry.sensitive = true
						pass_entry.sensitive = true
					end
				end
			}
			char_treeview.signal_connect('cursor-changed') {
				play_button.sensitive = true unless char_treeview.selection.selected[0].nil? or char_treeview.selection.selected[0].empty?
			}
			play_button.signal_connect('clicked') {
				play_button.sensitive = false
				char_code = char_treeview.selection.selected[0]
				if login_server and not login_server.closed?
					login_server.puts "L\t#{char_code}\tSTORM\n"
					response = login_server.gets
					if response =~ /^L\t/
						login_server.close unless login_server.closed?
						port = /GAMEPORT=([0-9]+)/.match(response).captures.first
						host = /GAMEHOST=([^\t\n]+)/.match(response).captures.first
						key = /KEY=([^\t\n]+)/.match(response).captures.first
						launch_data = response.sub(/^L\tOK\t/, '').split("\t")
						login_server.close unless login_server.closed?
						if wizard_option.active?
							launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, "GAMEFILE=WIZARD.EXE").sub(/GAME=.+/, "GAME=WIZ") }
						end
						if make_quick_option.active?
							LichSettings['quick_game_entry'] ||= Hash.new
							LichSettings['quick_game_entry'][char_treeview.selection.selected[1]] = [ user_id_entry.text, selected_game_code, char_code, wizard_option.active? ]
							LichSettings.save
						end
						main_thread.run
						window.destroy
					else
						login_server.close unless login_server.closed?
						disconnect_button.sensitive = false
						play_button.sensitive = false
						connect_button.sensitive = true
						user_id_entry.sensitive = true
						pass_entry.sensitive = true
					end
				else
					disconnect_button.sensitive = false
					play_button.sensitive = false
					connect_button.sensitive = true
					user_id_entry.sensitive = true
					pass_entry.sensitive = true
				end
			}

			#
			# install tab
			#

			website_order_entry_1 = Gtk::Entry.new
			website_order_entry_1.editable = false
			website_order_entry_2 = Gtk::Entry.new
			website_order_entry_2.editable = false
			website_order_entry_3 = Gtk::Entry.new
			website_order_entry_3.editable = false

			website_order_box = Gtk::VBox.new
			website_order_box.pack_start(website_order_entry_1, true, true, 5)
			website_order_box.pack_start(website_order_entry_2, true, true, 5)
			website_order_box.pack_start(website_order_entry_3, true, true, 5)

			website_order_frame = Gtk::Frame.new('Website Launch Order')
			website_order_frame.add(website_order_box)

			sge_order_entry_1 = Gtk::Entry.new
			sge_order_entry_1.editable = false
			sge_order_entry_2 = Gtk::Entry.new
			sge_order_entry_2.editable = false
			sge_order_entry_3 = Gtk::Entry.new
			sge_order_entry_3.editable = false

			sge_order_box = Gtk::VBox.new
			sge_order_box.pack_start(sge_order_entry_1, true, true, 5)
			sge_order_box.pack_start(sge_order_entry_2, true, true, 5)
			sge_order_box.pack_start(sge_order_entry_3, true, true, 5)

			sge_order_frame = Gtk::Frame.new('SGE Launch Order')
			sge_order_frame.add(sge_order_box)

			refresh_button = Gtk::Button.new(' Refresh ')

			refresh_box = Gtk::HBox.new
			refresh_box.pack_end(refresh_button, false, false, 5)

			psinet_compatible_button = Gtk::CheckButton.new('Use PsiNet compatible install method')

			install_button = Gtk::Button.new('Install')
			uninstall_button = Gtk::Button.new('Uninstall')
			
			install_table = Gtk::Table.new(1, 2, true)
			install_table.attach(install_button, 0, 1, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			install_table.attach(uninstall_button, 1, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)

			install_tab = Gtk::VBox.new
			install_tab.pack_start(website_order_frame, false, false, 5)
			install_tab.pack_start(sge_order_frame, false, false, 5)
			install_tab.pack_start(refresh_box, false, false, 5)
			install_tab.pack_start(psinet_compatible_button, false, false, 5)
			install_tab.pack_start(install_table, false, false, 5)

			psinet_installstate = nil

			refresh_button.signal_connect('clicked') {
				launch_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\').to_s
				website_order_entry_1.text = launch_cmd

				if launch_cmd =~ /"(.*?)PsiNet2.exe"/i
					website_order_entry_2.visible = true
					psinet_dir = $1
					if File.exists?(psinet_dir)
						Dir.entries(psinet_dir).each { |f|
							if f =~ /^SageInstaller.*\.InstallState$/i
								psinet_installstate = read_psinet_installstate.call("#{psinet_dir}#{f}")
								launch_cmd = psinet_installstate['UninstallSalCommand'].gsub(/&#([0-9]+);/) { $1.to_i.chr }
								website_order_entry_2.text = launch_cmd
								break
							end
						}
					end
				else
					website_order_entry_2.visible = false
				end
	
				if launch_cmd =~ /lich/i
					website_order_entry_3.visible = true
					website_order_entry_3.text = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\RealCommand').to_s
				else
					website_order_entry_3.visible = false
				end

				launch_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory').to_s
				sge_order_entry_1.text = launch_cmd
				sge_order_entry_1.text += '\Launcher.exe' unless sge_order_entry_1.text[-1].chr == ' '
	
				if launch_cmd =~ /^"?(.*?)PsiNet2.exe/i
					sge_order_entry_2.visible = true
					psinet_dir = $1
					if psinet_installstate.nil? or psinet_installstate.empty?
						if File.exists?(psinet_dir)
							Dir.entries(psinet_dir).each { |f|
								if f =~ /^SageInstaller.*\.InstallState$/i
									psinet_installstate = read_psinet_installstate.call("#{psinet_dir}#{f}")
									launch_cmd = psinet_installstate['RollbackLauncherDirectory'].gsub(/&#([0-9]+);/) { $1.to_i.chr }
									sge_order_entry_2.text = launch_cmd
									sge_order_entry_2.text += '\Launcher.exe' unless sge_order_entry_2.text[-1].chr == ' '
									break
								end
							}
						end
					else
						launch_cmd = psinet_installstate['RollbackLauncherDirectory'].gsub(/&#([0-9]+);/) { $1.to_i.chr }
						sge_order_entry_2.text = launch_cmd
					end
				else
					sge_order_entry_2.visible = false
				end

				if ENV['OCRA_EXECUTABLE']
					psinet_compatible_button.active = true
					psinet_compatible_button.sensitive = false
				end
				if launch_cmd =~ /lich/i
					if launch_cmd =~ /lich\.bat/i
						psinet_compatible_button.active = true
					end
					sge_order_entry_3.visible = true
					sge_order_entry_3.text = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\RealDirectory').to_s
					sge_order_entry_3.text += '\Launcher.exe' unless sge_order_entry_3.text[-1].chr == ' '
				else
					sge_order_entry_3.visible = false
				end

				if (website_order_entry_1.text =~ /PsiNet/i) or (sge_order_entry_1.text =~ /PsiNet/i)
					install_button.sensitive = false
					uninstall_button.sensitive = false
					psinet_compatible_button.sensitive = false
				elsif (website_order_entry_1.text =~ /lich/i) or (sge_order_entry_1.text =~ /lich/i)
					install_button.sensitive = false
					uninstall_button.sensitive = true
					psinet_compatible_button.sensitive = false
				else
					install_button.sensitive = true
					uninstall_button.sensitive = false
					psinet_compatible_button.sensitive = true unless ENV['OCRA_EXECUTABLE']
				end
				unless RUBY_PLATFORM =~ /win|mingw/i
					psinet_compatible_button.active = false
					psinet_compatible_button.visible = false
				end
			}
			install_button.signal_connect('clicked') {
				install_to_registry(psinet_compatible_button.active?)
				if RUBY_PLATFORM =~ /win|mingw/i
					refresh_button.clicked
				else
					msgbox.call('WINE will take 5-30 seconds (maybe more) to update the registry.  Wait a while and click the refresh button.')
				end
			}
			uninstall_button.signal_connect('clicked') {
				uninstall_from_registry
				if RUBY_PLATFORM =~ /win|mingw/i
					refresh_button.clicked
				else
					msgbox.call('WINE will take 5-30 seconds (maybe more) to update the registry.  Wait a while and click the refresh button.')
				end
			}

			#
			# options tab
			#

			lich_char_label = Gtk::Label.new('Lich char:')
			lich_char_label.xalign = 1
			lich_char_entry = Gtk::Entry.new
			lich_char_entry.text = LichSettings['lich_char'].to_s
			lich_box = Gtk::HBox.new
			lich_box.pack_end(lich_char_entry, true, true, 5)
			lich_box.pack_end(lich_char_label, true, true, 5)

			cache_serverbuffer_button = Gtk::CheckButton.new('Cache to disk')
			cache_serverbuffer_button.active = LichSettings['cache_serverbuffer']

			serverbuffer_max_label = Gtk::Label.new('Maximum lines in memory:')
			serverbuffer_max_entry = Gtk::Entry.new
			serverbuffer_max_entry.text = LichSettings['serverbuffer_max_size'].to_s
			serverbuffer_min_label = Gtk::Label.new('Minumum lines in memory:')
			serverbuffer_min_entry = Gtk::Entry.new
			serverbuffer_min_entry.text = LichSettings['serverbuffer_min_size'].to_s
			serverbuffer_min_entry.sensitive = cache_serverbuffer_button.active?

			serverbuffer_table = Gtk::Table.new(2, 2, false)
			serverbuffer_table.attach(serverbuffer_max_label, 0, 1, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			serverbuffer_table.attach(serverbuffer_max_entry, 1, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			serverbuffer_table.attach(serverbuffer_min_label, 0, 1, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			serverbuffer_table.attach(serverbuffer_min_entry, 1, 2, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)

			serverbuffer_box = Gtk::VBox.new
			serverbuffer_box.pack_start(cache_serverbuffer_button, false, false, 5)
			serverbuffer_box.pack_start(serverbuffer_table, false, false, 5)

			serverbuffer_frame = Gtk::Frame.new('Server Buffer')
			serverbuffer_frame.add(serverbuffer_box)

			cache_clientbuffer_button = Gtk::CheckButton.new('Cache to disk')
			cache_clientbuffer_button.active = LichSettings['cache_clientbuffer']

			clientbuffer_max_label = Gtk::Label.new('Maximum lines in memory:')
			clientbuffer_max_entry = Gtk::Entry.new
			clientbuffer_max_entry.text = LichSettings['clientbuffer_max_size'].to_s
			clientbuffer_min_label = Gtk::Label.new('Minumum lines in memory:')
			clientbuffer_min_entry = Gtk::Entry.new
			clientbuffer_min_entry.text = LichSettings['clientbuffer_min_size'].to_s
			clientbuffer_min_entry.sensitive = cache_clientbuffer_button.active?

			clientbuffer_table = Gtk::Table.new(2, 2, false)
			clientbuffer_table.attach(clientbuffer_max_label, 0, 1, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			clientbuffer_table.attach(clientbuffer_max_entry, 1, 2, 0, 1, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			clientbuffer_table.attach(clientbuffer_min_label, 0, 1, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)
			clientbuffer_table.attach(clientbuffer_min_entry, 1, 2, 1, 2, Gtk::EXPAND|Gtk::FILL, Gtk::EXPAND|Gtk::FILL, 5, 5)

			clientbuffer_box = Gtk::VBox.new
			clientbuffer_box.pack_start(cache_clientbuffer_button, false, false, 5)
			clientbuffer_box.pack_start(clientbuffer_table, false, false, 5)

			clientbuffer_frame = Gtk::Frame.new('Client Buffer')
			clientbuffer_frame.add(clientbuffer_box)

			save_button = Gtk::Button.new(' Save ')
			save_button.sensitive = false

			save_button_box = Gtk::HBox.new
			save_button_box.pack_end(save_button, false, false, 5)

			options_tab = Gtk::VBox.new
			options_tab.pack_start(lich_box, false, false, 5)
			options_tab.pack_start(serverbuffer_frame, false, false, 5)
			options_tab.pack_start(clientbuffer_frame, false, false, 5)
			options_tab.pack_start(save_button_box, false, false, 5)

			check_changed = proc {
				Gtk.queue {
					if (LichSettings['lich_char'] == lich_char_entry.text) and (LichSettings['cache_serverbuffer'] == cache_serverbuffer_button.active?) and (LichSettings['serverbuffer_max_size'] == serverbuffer_max_entry.text.to_i) and (LichSettings['serverbuffer_min_size'] == serverbuffer_min_entry.text.to_i) and (LichSettings['cache_clientbuffer'] == cache_clientbuffer_button.active?) and (LichSettings['clientbuffer_max_size'] == clientbuffer_max_entry.text.to_i) and (LichSettings['clientbuffer_min_size'] == clientbuffer_min_entry.text.to_i)
						save_button.sensitive = false
					else
						save_button.sensitive = true
					end
				}
			}

			lich_char_entry.signal_connect('key-press-event') {
				check_changed.call
				false
			}
			serverbuffer_max_entry.signal_connect('key-press-event') {
				check_changed.call
				false
			}
			serverbuffer_min_entry.signal_connect('key-press-event') {
				check_changed.call
				false
			}
			clientbuffer_max_entry.signal_connect('key-press-event') {
				check_changed.call
				false
			}
			clientbuffer_min_entry.signal_connect('key-press-event') {
				check_changed.call
				false
			}
			cache_serverbuffer_button.signal_connect('clicked') {
				serverbuffer_min_entry.sensitive = cache_serverbuffer_button.active?
				check_changed.call
			}
			cache_clientbuffer_button.signal_connect('clicked') {
				clientbuffer_min_entry.sensitive = cache_clientbuffer_button.active?
				check_changed.call
			}
			save_button.signal_connect('clicked') {
				LichSettings['lich_char']             = lich_char_entry.text
				LichSettings['cache_serverbuffer']    = cache_serverbuffer_button.active?
				LichSettings['serverbuffer_max_size'] = serverbuffer_max_entry.text.to_i
				LichSettings['serverbuffer_min_size'] = serverbuffer_min_entry.text.to_i
				LichSettings['cache_clientbuffer']    = cache_clientbuffer_button.active?
				LichSettings['clientbuffer_max_size'] = clientbuffer_max_entry.text.to_i
				LichSettings['clientbuffer_min_size'] = clientbuffer_min_entry.text.to_i
				LichSettings.save
				save_button.sensitive = false
			}

			#
			#
			#

			notebook = Gtk::Notebook.new
			notebook.append_page(quick_game_entry_tab, Gtk::Label.new('Quick Game Entry'))
			notebook.append_page(game_entry_tab, Gtk::Label.new('Game Entry'))
			notebook.append_page(install_tab, Gtk::Label.new('Install'))
			notebook.append_page(options_tab, Gtk::Label.new('Options'))

			window = Gtk::Window.new
			window.title = "Lich v#{$version}"
			window.border_width = 5
			window.add(notebook)
			window.signal_connect('delete_event') { Gtk.main_quit }

			window.show_all

			refresh_button.clicked

			notebook.set_page(1) if LichSettings['quick_game_entry'].empty?
		}

		Thread.stop

	end

	if LichSettings['cache_serverbuffer']
		$_SERVERBUFFER_ = CachedArray.new
		$_SERVERBUFFER_.max_size = LichSettings['serverbuffer_max_size']
		$_SERVERBUFFER_.min_size = LichSettings['serverbuffer_min_size']
	else
		$_SERVERBUFFER_ = LimitedArray.new
		$_SERVERBUFFER_.max_size = LichSettings['serverbuffer_max_size']
	end

	if LichSettings['cache_clientbuffer']
		$_CLIENTBUFFER_ = CachedArray.new
		$_CLIENTBUFFER_.max_size = LichSettings['clientbuffer_max_size']
		$_CLIENTBUFFER_.min_size = LichSettings['clientbuffer_min_size']
	else
		$_CLIENTBUFFER_ = LimitedArray.new
		$_CLIENTBUFFER_.max_size = LichSettings['clientbuffer_max_size']
	end

	trace_var(:$_CLIENT_, sock_keepalive_proc)
	trace_var(:$_SERVER_, sock_keepalive_proc)
	Socket.do_not_reverse_lookup = true

	#
	# open the client and have it connect to us
	#
	if launch_data or launch_file
		if launch_file
			begin
				launch_data = File.open(launch_file) { |file| file.readlines }.collect { |line| line.chomp }
			rescue
				$stdout.puts "error: failed to read launch_file: #{$!}" rescue()
				$stderr.puts "info: launch_file: #{launch_file}"
				$stderr.puts "error: failed to read launch_file: #{$!}"
				$stderr.puts $!.backtrace
				exit(1)
			end
		end
		unless launcher_cmd = get_real_launcher_cmd.call
			$stdout.puts 'error: failed to find the Simutronics launcher' rescue()
			$stderr.puts 'error: failed to find the Simutronics launcher'
			exit(1)
		end
		unless gamecode = launch_data.find { |line| line =~ /GAMECODE=/ }
			$stdout.puts "error: launch_data contains no GAMECODE info" rescue()
			$stderr.puts "error: launch_data contains no GAMECODE info"
			exit(1)
		end
		unless gameport = launch_data.find { |line| line =~ /GAMEPORT=/ }
			$stdout.puts "error: launch_data contains no GAMEPORT info" rescue()
			$stderr.puts "error: launch_data contains no GAMEPORT info"
			exit(1)
		end
		unless gamehost = launch_data.find { |opt| opt =~ /GAMEHOST=/ }
			$stdout.puts "error: launch_data contains no GAMEHOST info" rescue()
			$stderr.puts "error: launch_data contains no GAMEHOST info"
			exit(1)
		end
		unless game = launch_data.find { |opt| opt =~ /GAME=/ }
			$stdout.puts "error: launch_data contains no GAME info" rescue()
			$stderr.puts "error: launch_data contains no GAME info"
			exit(1)
		end
		gamecode = gamecode.split('=').last
		gameport = gameport.split('=').last
		gamehost = gamehost.split('=').last
		game     = game.split('=').last
		if (gamehost == '127.0.0.1') or (gamehost == 'localhost')
			$psinet = true
			if (game !~ /WIZ/i) and ( File.exists?('fakestormfront.txt') or ( registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\WIZ32\Directory') and not registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\STORM32\Directory') ) )
				launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, 'GAMEFILE=WIZARD.EXE').sub(/GAME=.+/, 'GAME=WIZ').sub(/FULLGAMENAME=.+/, 'FULLGAMENAME=Wizard Front End') }
				game = 'WIZ'
			end
		else
			$psinet = false
		end
		if game =~ /WIZ/i
			$fake_stormfront = true
		else
			$fake_stormfront = false
		end
		if (gameport == '10121') or (gameport == '10124')
			$platinum = true
		else
			$platinum = false
		end
		$stderr.puts "info: gamehost: #{gamehost}"
		$stderr.puts "info: gameport: #{gameport}"
		$stderr.puts "info: game: #{game}"
		begin
			listener = TCPServer.new("localhost", nil)
		rescue
			$stdout.puts "--- error: cannot bind listen socket to local port: #{$!}" rescue()
			$stderr.puts "error: cannot bind listen socket to local port: #{$!}"
			$stderr.puts $!.backtrace
			exit(1)
		end
		begin
			listener.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
		rescue
			$stderr.puts "Cannot set SO_REUSEADDR sockopt"
		end
		localport = listener.addr[1]
		launch_data.collect! { |line| line.sub(/GAMEPORT=.+/, "GAMEPORT=#{localport}").sub(/GAMEHOST=.+/, "GAMEHOST=localhost") }
		File.open("#{$temp_dir}lich.sal", 'w') { |f| f.puts launch_data }
		launcher_cmd = launcher_cmd.sub('%1', "#{$temp_dir}lich.sal")
		launcher_cmd = launcher_cmd.tr('/', "\\") if RUBY_PLATFORM =~ /win|mingw/i
		launcher_cmd = "#{wine_bin} #{launcher_cmd}" if wine_bin
		$stderr.puts "info: launcher_cmd: #{launcher_cmd}"
		Thread.new { system(launcher_cmd) }
		timeout_thr = Thread.new {
			sleep 30
			$stdout.puts "error: timeout waiting for client to connect" rescue()
			$stderr.puts "error: timeout waiting for client to connect"
			exit(1)
		}
		$stderr.puts 'info: waiting for client to connect...'
		$_CLIENT_ = listener.accept
		$stderr.puts 'info: connected'
		begin
			timeout_thr.kill
			listener.close
		rescue
			$stderr.puts "error: #{$!}"
		end
		gamehost, gameport = fix_game_host_port.call(gamehost, gameport)
		$stderr.puts "info: connecting to game server (#{gamehost}:#{gameport})"
		$_SERVER_ = TCPSocket.open(gamehost, gameport)
		$stderr.puts 'info: connected'
	elsif game_host and game_port
		hosts_dir ||= find_hosts_dir
		unless hosts_dir and File.exists?(hosts_dir)
			$stdout.puts "error: hosts_dir does not exist: #{hosts_dir}" rescue()
			$stderr.puts "error: hosts_dir does not exist: #{hosts_dir}"
			exit
		end
		game_quad_ip = IPSocket.getaddress(game_host)
		error_count = 0
		begin
			listener = TCPServer.new('localhost', game_port)
			begin
				listener.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
			rescue
				$stderr.puts "warning: setsockopt with SO_REUSEADDR failed: #{$!}"
			end
		rescue
			sleep 1
			if (error_count += 1) >= 30
				$stdout.puts 'error: failed to bind to the proper port' rescue()
				$stderr.puts 'error: failed to bind to the proper port'
				exit!
			else
				retry
			end
		end

		hack_hosts(hosts_dir, game_host)
		undef :hack_hosts
=begin
		sge_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\SGE32\Directory')
		launch_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory')
		unless File.exists?("#{$lich_dir}nosge.txt") or (launch_dir.to_s =~ /lich/i) or not sge_dir
			sge_file = File.join(sge_dir, 'SGE.exe')
			sge_file = wine_dir + '/drive_c/' + sge_file[3..-1].split('\\').join('/') if wine_dir
			if File.exists?(sge_file)
				sge_file = wine_bin + ' ' + sge_file if wine_bin
				system(sge_file)
			end
	
		end
=end
		timeout_thread = Thread.new {
			sleep 120
			$stdout.puts 'error: timed out waiting for client to connect' rescue()
			$stderr.puts 'error: timed out waiting for client to connect'
			heal_hosts(hosts_dir)
			exit(1)
		}
		$stdout.puts "Pretending to be #{game_host}" rescue()
		$stdout.puts "Listening on port #{game_port}" rescue()
		$stdout.puts "Waiting for the client to connect..." rescue()
		$stderr.puts "info: pretending to be #{game_host}"
		$stderr.puts "info: listening on port #{game_port}"
		$stderr.puts "info: waiting for the client to connect..."
		$_CLIENT_ = listener.accept
		timeout_thread.kill
		timeout_thread = nil
		$stdout.puts "Connection with the local game client is open." rescue()
		$stderr.puts "info: connection with the game client is open"
		heal_hosts(hosts_dir)
		if test_mode
			$_SERVER_ = $stdin
			$_CLIENT_.puts "Running in test mode: host socket set to stdin."
		else
			$stderr.puts 'info: connecting to the real game host...'
			game_host, game_port = fix_game_host_port.call(game_host, game_port)
			$_SERVER_ = TCPSocket.open(game_host, game_port)
			$stderr.puts 'info: connection with the game host is open'
		end
	else
		#
		# offline mode
		#
		$stderr.puts "info: offline mode"

		$offline_mode = true
		begin
			listener = TCPServer.new("localhost", nil)
		rescue
			$stdout.puts "Cannot bind listening socket to local port: #{$!}" rescue()
			$stderr.puts "Cannot bind listening socket to local port: #{$!}"
			exit(1)
		end
		begin
			listener.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
		rescue
			$stderr.puts "Cannot set SO_REUSEADDR sockopt"
		end
		localport = listener.addr[1]
		if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
			$frontend = 'stormfront'
			$fake_stormfront = false
			frontend_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\STORM32\Directory')
			frontend_cmd = "\"#{frontend_dir}\\StormFront.exe\""
		else
			$frontend = 'wizard'
			$fake_stormfront = true
			frontend_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\WIZ32\Directory')
			frontend_cmd = "\"#{frontend_dir}\\wizard.exe\""
		end
		frontend_cmd += " /GGS /H127.0.0.1 /P#{localport} /Kfake_login_key"
		frontend_cmd = "#{wine_bin} #{frontend_cmd}" if wine_bin
		$stderr.puts "info: frontend_cmd: #{frontend_cmd}"
		$stderr.flush
		Thread.new {
			Dir.chdir(frontend_dir) rescue()
			system(frontend_cmd)
		}
		timeout_thr = Thread.new {
			sleep 30
			$stdout.puts "timeout waiting for connection" rescue()
			$stderr.puts "error: timeout waiting for connection"
			exit(1)
		}
		Dir.chdir($lich_dir)
		$_CLIENT_ = listener.accept
		begin
			timeout_thr.kill
			listener.close
		rescue
			$stderr.puts $!
		end
		$_SERVER_ = $stdin
		if $fake_stormfront
			$_CLIENT_.puts "\034GSB0000000000Lich\r\n\034GSA#{Time.now.to_i.to_s}GemStone IV\034GSD\r\n"
		end
	end
	
	listener = timeout_thr = nil

	#
	# drop superuser privileges
	#	
	unless RUBY_PLATFORM =~ /win|mingw/i
		$stderr.puts "info: dropping superuser privileges..."
		begin
			Process.uid = `id -ru`.strip.to_i
			Process.gid = `id -rg`.strip.to_i
			Process.egid = `id -rg`.strip.to_i
			Process.euid = `id -ru`.strip.to_i
		rescue SecurityError
			$stderr.puts "error: failed to drop superuser privileges: #{$!}"
			$stderr.puts $!.backtrace
		rescue SystemCallError
			$stderr.puts "error: failed to drop superuser privileges: #{$!}"
			$stderr.puts $!.backtrace
		rescue
			$stderr.puts "error: failed to drop superuser privileges: #{$!}"
			$stderr.puts $!.backtrace
		end
	end
	
	#
	# shutdown listening socket
	#
	error_count = 0
	begin
		# Somehow... for some ridiculous reason... Windows doesn't let us close the socket if we shut it down first...
		# listener.shutdown
		listener.close unless listener.closed?
	rescue
		$stderr.puts "warning: failed to close listener socket: #{$!}"
		if (error_count += 1) > 20
			$stderr.puts 'warning: giving up...'
		else
			sleep "0.05".to_f
			retry
		end
	end

	undef :exit!

	$stdout = $_CLIENT_
	
	$_CLIENT_.sync = true
	$_SERVER_.sync = true

	client_thread = Thread.new {
		$login_time = Time.now

		if $offline_mode
			nil
		elsif $fake_stormfront
			#
			# send the login key
			#
			client_string = $_CLIENT_.gets
			$_SERVER_.write(client_string)
			#
			# take the version string from the client, ignore it, and ask the server for xml
			#
			$_CLIENT_.gets
			client_string = "/FE:WIZARD /VERSION:1.0.1.22 /P:#{RUBY_PLATFORM} /XML\r\n"
			$_CLIENTBUFFER_.push(client_string.dup)
			$_SERVER_.write(client_string)
			#
			# tell the server we're ready
			#
			sleep "0.3".to_f
			client_string = "<c>\r\n"
			$_CLIENTBUFFER_.push(client_string)
			$_SERVER_.write(client_string)
			sleep "0.3".to_f
			client_string = "<c>\r\n"
			$_CLIENTBUFFER_.push(client_string)
			$_SERVER_.write(client_string)
			#
			# ask the server for both wound and scar information
			#
			for client_string in [ "<c>_injury 2\r\n", "<c>_flag Display Inventory Boxes 1\r\n", "<c>_flag Display Dialog Boxes 0\r\n" ]
				$_CLIENTBUFFER_.push(client_string)
				$_SERVER_.write(client_string)
			end
			#
			# client wants to send "GOOD", xml server won't recognize it
			#
			$_CLIENT_.gets
		else
=begin
			sf_inv_off_proc = proc { |server_string|
				if server_string =~ /^<container id=['"]-?[0-9]+['"]/
					server_string.gsub!(/<(?:container|clearContainer)[^>]*>/, '')
					server_string.gsub!(/<inv id=['"]-?[0-9]+['"].*/inv>/, '')
					if server_string.empty?
						nil
					else
						server_string
					end
				else
					server_string
				end
			}
			DownstreamHook.add('sf_inv_off', sf_inv_off_proc)
			sf_inv_toggle_proc = proc { |client_string|
				# set|flag inv on|off
				if client_string =~ /^(?:<c>)?_flag Display Inventory Boxes ([01])/
					if $1 == '0'
						DownstreamHook.add('sf_inv_off', sf_inv_off_proc)
					else
						DownstreamHook.remove('sf_inv_off')
					end
					nil
				else
					client_string
				end
			}
=end
			unless $offline_mode
				client_string = $_CLIENT_.gets
				$_SERVER_.write(client_string)
				client_string = $_CLIENT_.gets
				$_CLIENTBUFFER_.push(client_string.dup)
				$_SERVER_.write(client_string)
				# client_string = "<c>_flag Display Inventory Boxes 1\r\n"
				# $_CLIENTBUFFER_.push(client_string)
				# $_SERVER_.write(client_string)
			end
		end
	
		begin	
			while client_string = $_CLIENT_.gets
				client_string = '<c>' + client_string if $fake_stormfront
				begin
					$_IDLETIMESTAMP_ = Time.now
					if Alias.find(client_string)
						Alias.run(client_string)
					else
						do_client(client_string)
					end
				rescue
					$stdout.puts "--- error: client_thread: #{$!}"
					$stdout.puts $!.backtrace.first
					$stderr.puts "error: client_thread: #{$!}"
					$stderr.puts $!.backtrace
				end
			end
		rescue
			$stdout.puts "--- error: client_thread: #{$!}"
			$stdout.puts $!.backtrace.first
			$stderr.puts "error: client_thread: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.2".to_f
			retry unless $_CLIENT_.closed? or $_SERVER_.closed?
		end
		# $_SERVER_.puts('quit') unless $_SERVER_.closed?
		# $_SERVER_.close rescue()
		server_thread.kill rescue()
	}
	
	# fixme: bare bones
	
	server_thread = Thread.new {
		begin
			while $_SERVERSTRING_ = $_SERVER_.gets
				begin
					# The Rift, Scatter is broken...
					$_SERVERSTRING_.sub!(/(.*)\s\s<compDef id='room text'><\/compDef>/)  { "<compDef id='room desc'>#{$1}</compDef>" }

					$_SERVERBUFFER_.push($_SERVERSTRING_)
					if alt_string = DownstreamHook.run($_SERVERSTRING_)
						alt_string = sf_to_wiz(alt_string) if $fake_stormfront
						$_CLIENT_.write(alt_string)
					end
					begin
						REXML::Document.parse_stream($_SERVERSTRING_, XMLData)
					rescue
						if $_SERVERSTRING_ =~ /<[^>]+='[^=>'\\]+'[^=>']+'[\s>]/
							# Simu has a nasty habbit of bad quotes in XML.  <tag attr='this's that'>
							$_SERVERSTRING_.gsub!(/(<[^>]+=)'([^=>'\\]+'[^=>']+)'([\s>])/) { "#{$1}\"#{$2}\"#{$3}" }
							retry
						end
						$stdout.puts "--- error: server_thread: #{$!}"
						$stderr.puts "error: server_thread: #{$!}"
						$stderr.puts $!.backtrace
						XMLData.reset
					end
					Script.new_downstream_xml($_SERVERSTRING_)
					stripped_server = strip_xml($_SERVERSTRING_)
					stripped_server.split("\r\n").each { |line|
						unless line =~ /^\s\*\s[A-Z][a-z]+ (?:returns home from a hard day of adventuring|joins the adventure|just bit the dust)|^\r*\n*$/
							Script.new_downstream(line) unless line.empty?
						end
					}
				rescue
					$stdout.puts "--- error: server_thread: #{$!}"
					$stderr.puts "error: server_thread: #{$!}"
					$stderr.puts $!.backtrace
				end
			end
		rescue Exception
			$stdout.puts "--- error: server_thread: #{$!}"
			$stderr.puts "error: server_thread: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.2".to_f
			retry unless $_CLIENT_.closed? or $_SERVER_.closed? or ($!.to_s =~ /invalid argument/i)
		rescue
			$stdout.puts "--- error: server_thread: #{$!}"
			$stderr.puts "error: server_thread: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.2".to_f
			retry unless $_CLIENT_.closed? or $_SERVER_.closed?
		end
	}
	
	server_thread.priority = 4
	client_thread.priority = 3
	
	$_CLIENT_.puts "\n--- Lich v#{$version} is active.  Type #{$clean_lich_char}help for usage info.\n\n"
	
	unless LichSettings['seen_notice']
		$_CLIENT_.puts ''
		$_CLIENT_.puts "#{monsterbold_start}** NOTICE:"
		$_CLIENT_.puts ''
		$_CLIENT_.puts '** Lich is not intended to facilitate AFK scripting.'
		$_CLIENT_.puts '** The authors do not condone violation of game policy,'
		$_CLIENT_.puts '** nor are they in any way attempting to encourage it.'
		$_CLIENT_.puts ''
		$_CLIENT_.puts "** (this notice will not repeat)#{monsterbold_end} "
		$_CLIENT_.puts ''
		LichSettings['seen_notice'] = true
		LichSettings.save
	end
	
	server_thread.join rescue()
	
	Script.running.each { |script| script.kill }
	Script.hidden.each { |script| script.kill }
	100.times { sleep "0.1".to_f; break if Script.running.empty? or Script.hidden.empty? }
	$_SERVER_.puts('quit') unless $_SERVER_.closed?
	$_SERVER_.close rescue()
	$_CLIENT_.close rescue()
	client_thread.kill rescue()
	Gtk.queue { Gtk.main_quit } if HAVE_GTK
}

if HAVE_GTK
	Gtk.main_with_queue(100)
else
	main_thread.join
end
