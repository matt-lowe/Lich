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

=begin

	Lich is currently maintained by Tillmen (tillmen@lichproject.org)

=end

# I hate Windows...
begin
	$stderr.write(' ')
rescue
	require 'stringio'
	$stderr = StringIO.new('')
	$stdout = StringIO.new('')
	STDERR = $stderr rescue()
	STDOUT = $stderr rescue()
end

$version = '4.4.13'

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
	puts '      --avalon        Run in Avalon mode.'
	puts ''
	puts '      --gemstone      Connect to the Gemstone IV Prime server (default).'
	puts '      --dragonrealms  Connect to the DragonRealms server.'
	puts '      --platinum      Connect to the Gemstone IV/DragonRealms Platinum server.'
	puts '  -g, --game          Set the IP address and port of the game.  See example below.'
	puts ''
	puts '      --install       Edits the Windows/WINE registry so that Lich is started when logging in using the website or SGE.'
	puts '      --uninstall     Removes Lich from the registry.'
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
	# puts "The Lich, version #{$version}"
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
		$stdout.puts "warning: given Lich directory does not exist: #{$lich_dir}"
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
		$stdout.puts "warning: given script directory does not exist: #{$script_dir}"
		$script_dir = nil
	end
end
unless $script_dir
	$script_dir = "#{$lich_dir}scripts/"
	unless File.exists?($script_dir)
		$stdout.puts "info: creating directory: #{$script_dir}"
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
		$stdout.puts "warning: given data directory does not exist: #{$data_dir}"
		$data_dir = nil
	end
end
unless $data_dir
	$data_dir = "#{$lich_dir}data/"
	unless File.exists?($data_dir)
		$stdout.puts "info: creating directory: #{$data_dir}"
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
		$stdout.puts "warning: given temp directory does not exist: #{$temp_dir}"
		$temp_dir = nil
	end
end
unless $temp_dir
	$temp_dir = "#{$lich_dir}temp/"
	unless File.exists?($temp_dir)
		$stdout.puts "info: creating directory: #{$temp_dir}"
		Dir.mkdir($temp_dir)
	end
end

if arg = ARGV.find { |a| a == '--hosts-dir' }
	i = ARGV.index(arg)
	ARGV.delete_at(i)
	hosts_dir = ARGV[i]
	ARGV.delete_at(i)
	if hosts_dir and File.exists?(hosts_dir)
		hosts_dir = hosts_dir.tr('\\', '/')
		hosts_dir += '/' unless hosts_dir[-1..-1] == '/'
	else
		$stdout.puts "warning: given hosts directory does not exist: #{hosts_dir}"
		hosts_dir = nil
	end
else
	hosts_dir = nil
end

num = Time.now.to_i
debug_filename = "#{$temp_dir}debug-#{num}.txt"
debug_filename = "#{$temp_dir}debug-#{num+=1}.txt" while File.exists?(debug_filename)
$stderr = File.open(debug_filename, 'w')
$stderr.sync = true

$stderr.puts "info: #{Time.now}"
$stderr.puts "info: Lich #{$version}"
$stderr.puts "info: Ruby #{RUBY_VERSION}"
$stderr.puts "info: #{RUBY_PLATFORM}"
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

=begin
# fixme: Somehow this makes gtk2 fail to load?
begin
	require 'rubygems'
rescue LoadError
	$stdout.puts "warning: failed to load rubygems: #{$!}"
	$stderr.puts "warning: failed to load rubygems: #{$!}"
rescue
	$stdout.puts "warning: failed to load rubygems: #{$!}"
	$stderr.puts "warning: failed to load rubygems: #{$!}"
end
=end

require 'time'
require 'socket'
include Socket::Constants
require 'rexml/document'
require 'rexml/streamlistener'
include REXML
require 'stringio'
require 'dl'
require 'zlib'
require 'drb'
require 'resolv'
require 'digest/md5'

# stupid workaround for Windows to avoid 10 second or so freeze when lnet starts up
# no idea why this works
if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
	begin
		require 'openssl'
		OpenSSL::PKey::RSA.new(512)
	rescue LoadError
		$stderr.puts "warning: failed to load openssl: #{$!}"
	rescue
		$stderr.puts "warning: failed to load openssl: #{$!}"
	end
end

begin
	require 'gtk2'
	module Gtk
		@@pending_blocks = Array.new
		def Gtk.queue &block
			@@pending_blocks.push(block)
			GLib::Timeout.add(1) { Gtk.do_queue; false }
		end
		def Gtk.do_queue
			if block = @@pending_blocks.shift
				begin
					block.call
				rescue
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue SyntaxError
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue SystemExit
					nil
				rescue SecurityError
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue ThreadError
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue SystemStackError
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue Exception
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue ScriptError
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue LoadError
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue NoMemoryError
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				rescue
					respond "error in Gtk.queue: #{$!}"
					$stderr.puts "error in Gtk.queue: #{$!}"
					$stderr.puts $!.backtrace
				end
			end
		end
	end
	$warned_depreciated_gtk_do = false
	class BeBackwardCompatible1
		def do(what)
			unless $warned_depreciated_gtk_do
				unless script_name = Script.self.name
					script_name = 'unknown script'
				end
				respond "--- warning: #{script_name} is using depreciated method $gtk.do"
				$warned_depreciated_gtk_do = true
			end
			Gtk.queue { eval(what) }
		end
	end
	$gtk = BeBackwardCompatible1.new
	$warned_depreciated_lich_do = false
	class BeBackwardCompatible2
		def do(what)
			unless $warned_depreciated_lich_do
				unless script_name = Script.self.name
					script_name = 'unknown script'
				end
				respond "--- warning: #{script_name} is using depreciated method $lich.do"
				$warned_depreciated_lich_do = true
			end
			eval(what)
		end
	end
	$lich = BeBackwardCompatible2.new
	HAVE_GTK = true
	$stderr.puts "info: HAVE_GTK: true"
rescue LoadError
	HAVE_GTK = false
	$stdout.puts "warning: failed to load GTK bindings: #{$!}"
	$stderr.puts "warning: failed to load GTK bindings: #{$!}"
rescue
	HAVE_GTK = false
	$stdout.puts "warning: failed to load GTK bindings: #{$!}"
	$stderr.puts "warning: failed to load GTK bindings: #{$!}"
end

# fixme: warlock
# fixme: terminal mode
# fixme: maybe add script dir to load path

# at_exit { Process.waitall }

$room_count = 0

#
# Allow untrusted scripts to do a few things
#
UNTRUSTED_SETTINGS_LOAD = proc { Settings.load }
UNTRUSTED_SETTINGS_SAVE = proc { Settings.save }
UNTRUSTED_SETTINGS_SAVE_ALL = proc { Settings.save_all }
UNTRUSTED_GAMESETTINGS_LOAD = proc { GameSettings.load }
UNTRUSTED_GAMESETTINGS_SAVE = proc { GameSettings.save }
UNTRUSTED_GAMESETTINGS_SAVE_ALL = proc { GameSettings.save_all }
UNTRUSTED_CHARSETTINGS_LOAD = proc { CharSettings.load }
UNTRUSTED_CHARSETTINGS_SAVE = proc { CharSettings.save }
UNTRUSTED_CHARSETTINGS_SAVE_ALL = proc { CharSettings.save_all }
UNTRUSTED_MAP_LOAD = proc { Map.load }
UNTRUSTED_MAP_LOAD_DAT = proc { Map.load_dat }
UNTRUSTED_MAP_LOAD_XML = proc { Map.load_xml }
UNTRUSTED_MAP_SAVE = proc { Map.save }
UNTRUSTED_MAP_SAVE_XML = proc { Map.save_xml }
UNTRUSTED_SPELL_LOAD = proc { Spell.load }
UNTRUSTED_START_SCRIPT = proc { |script_name,cli_vars,force| start_script(script_name,cli_vars,force) }
UNTRUSTED_START_EXEC_SCRIPT = proc { |cmd_data,flags| flags = Hash.new unless flags.class == Hash; flags[:trusted] = false; start_exec_script(cmd_data, flags) }
UNTRUSTED_SCRIPT_EXISTS = proc { |scriptname| Script.exists?(scriptname) }
UNTRUSTED_UNTAINT = proc { |str| str.untaint }
UNTRUSTED_USERVARIABLES_METHOD_MISSING = proc { |arg1, arg2| UserVariables.method_missing(arg1, arg2) }
UNTRUSTED_USERVARIABLES_DELETE = proc { |var_name, type| UserVariables.delete(var_name, type) }
UNTRUSTED_USERVARIABLES_ADD = proc { |var_name, value, type| UserVariables.add(var_name, value, type) }
UNTRUSTED_USERVARIABLES_CHANGE = proc { |var_name, value, type| UserVariables.change(var_name, value, type) }
UNTRUSTED_USERVARIABLES_SAVE = proc { UserVariables.save }
UNTRUSTED_SPELL_RANKS_LOAD = proc { SpellRanks.load }
UNTRUSTED_SPELL_RANKS_SAVE = proc { SpellRanks.save }
UNTRUSTED_SCRIPT_LOG = proc { |data| Script.log(data) }
UNTRUSTED_GAMEOBJ_LOAD_DATA = proc { GameObj.load_data }

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
	def history
		Array.new
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
		@file = File.open(@filename, 'w')
		super
	end
	def push(line)
		if self.length >= @max_size
			@file.puts(self.shift) while (self.length >= @min_size)
			@file.flush
		end
		super
	end
	def history
		@file.flush
		@file.close
		@file = File.open(@filename, 'r')
		h = @file.readlines
		@file.close
		@file = File.open(@filename, 'a')
		h
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
	def to_ary
		nil
	end
end

class FalseClass
	def method_missing(*usersave)
		nil
	end
end

class String
# causes an error in File.exists? for Ruby 1.9.2
#	def method_missing(*usersave)
#		""
#	end
	def silent
		false
	end
	def to_s
		self.dup
	end
	def split_as_list
		string = self
		string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
		string.sub('.','').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
	end
end

class XMLParser
	attr_reader :mana, :max_mana, :health, :max_health, :spirit, :max_spirit, :last_spirit, :stamina, :max_stamina, :stance_text, :stance_value, :mind_text, :mind_value, :prepared_spell, :encumbrance_text, :encumbrance_full_text, :encumbrance_value, :indicator, :injuries, :injury_mode, :room_count, :room_title, :room_description, :room_exits, :room_exits_string, :familiar_room_title, :familiar_room_description, :familiar_room_exits, :bounty_task, :injury_mode, :server_time, :server_time_offset, :roundtime_end, :cast_roundtime_end, :last_pulse, :level, :next_level_value, :next_level_text, :society_task, :stow_container_id, :name, :game, :in_stream, :player_id, :active_spells
	attr_accessor :send_fake_tags

	@@warned_depreciated_spellfront = false

	include StreamListener

	def initialize
		@buffer = String.new
		@unescape = { 'lt' => '<', 'gt' => '>', 'quot' => '"', 'apos' => "'", 'amp' => '&' }
		@bold = false
		@active_tags = Array.new
		@active_ids = Array.new
		@last_tag = String.new
		@last_id = String.new
		@current_stream = String.new
		@current_style = String.new
		@stow_container_id = nil
		@obj_location = nil
		@obj_exist = nil
		@obj_noun = nil
		@obj_before_name = nil
		@obj_name = nil
		@obj_after_name = nil
		@pc = nil
		@last_obj = nil
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
		@level = 0
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

		@bounty_task = String.new
		@society_task = String.new

		@name = String.new
		@game = String.new
		@player_id = String.new
		@mana = 0
		@max_mana = 0
		@health = 0
		@max_health = 0
		@spirit = 0
		@max_spirit = 0
		@last_spirit = nil
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

		@active_spells = Hash.new

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

	def parse(line)
		@buffer.concat(line)
		loop {
			if str = @buffer.slice!(/^[^<]+/)
				text(str.gsub(/&(lt|gt|quot|apos|amp)/) { @unescape[$1] })
			elsif str = @buffer.slice!(/^<\/[^<]+>/)
				element = /^<\/([^\s>\/]+)/.match(str).captures.first
				tag_end(element)
			elsif str = @buffer.slice!(/^<[^<]+>/)
				element = /^<([^\s>\/]+)/.match(str).captures.first
				attributes = Hash.new
				str.scan(/([A-z][A-z0-9_\-]*)=(["'])(.*?)\2/).each { |attr| attributes[attr[0]] = attr[2] }
				tag_start(element, attributes)
				tag_end(element) if str =~ /\/>$/
			else
				break
			end
		}
	end

	def tag_start(name, attributes)
		begin
			@active_tags.push(name)
			@active_ids.push(attributes['id'].to_s)
			if name =~ /^(?:a|right|left)$/
				@obj_exist = attributes['exist']
				@obj_noun = attributes['noun']
			elsif name == 'inv'
				if attributes['id'] == 'stow'
					@obj_location = @stow_container_id
				else
					@obj_location = attributes['id']
				end
				@obj_exist = nil
				@obj_noun = nil
				@obj_name = nil
				@obj_before_name = nil
				@obj_after_name = nil
			elsif name == 'dialogData' and attributes['id'] == 'ActiveSpells' and attributes['clear'] == 't'
				@active_spells.clear
			elsif name == 'resource' or name == 'nav'
				nil
			elsif name == 'pushStream'
				@in_stream = true
				@current_stream = attributes['id'].to_s
				GameObj.clear_inv if attributes['id'].to_s == 'inv'
			elsif name == 'popStream'
				if attributes['id'] == 'room'
					@room_count += 1
					$room_count += 1
				end
				@in_stream = false
				if attributes['id'] == 'bounty'
					@bounty_task.strip!
				end
				@current_stream = String.new
			elsif name == 'pushBold'
				@bold = true
			elsif name == 'popBold'
				@bold = false
			elsif (name == 'streamWindow')
				if (attributes['id'] == 'main') and attributes['subtitle']
					@room_title = '[' + attributes['subtitle'][3..-1] + ']'
				end
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
				elsif attributes['id'] == 'room extra' # DragonRealms
					@room_count += 1
					$room_count += 1
				# elsif attributes['id'] == 'sprite'
				end
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
					# fixme: enhancives screw this up
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
					@last_spirit = @spirit if @last_spirit
					@spirit, @max_spirit = attributes['text'].scan(/-?\d+/).collect { |num| num.to_i }
					@last_spirit = @spirit unless @last_spirit
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
								$_SERVER_.puts "#{$cmd_prefix}health\n"
							}
						end
					else
						@injuries[attributes['id']]['wound'] = 0
						@injuries[attributes['id']]['scar'] = 0
					end
				end
				$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', @max_health, @health, @max_spirit, @spirit, @max_mana, @mana, make_wound_gsl, make_scar_gsl)}\r\n" if @send_fake_tags
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
					@level = Stats.level = attributes['value'].slice(/\d+/).to_i
				elsif attributes['id'] == 'encumblurb'
					@encumbrance_full_text = attributes['value']
				elsif @active_tags[-2] == 'dialogData' and @active_ids[-2] == 'ActiveSpells'
					if (name = /^lbl(.+)$/.match(attributes['id']).captures.first) and (value = /^\s*([0-9\:]+)\s*$/.match(attributes['value']).captures.first)
						hour, minute = value.split(':')
						@active_spells[name] = Time.now + (hour.to_i * 3600) + (minute.to_i * 60)
					end
				end
			elsif (name == 'container') and (attributes['id'] == 'stow')
				@stow_container_id = attributes['target'].sub('#', '')
			elsif (name == 'clearStream')
				if attributes['id'] == 'bounty'
					@bounty_task = String.new
				end
			elsif (name == 'playerID')
				@player_id = attributes['id']
				unless $frontend =~ /^(?:wizard|avalon)$/
					LichSettings[@player_id] ||= Hash.new
					if LichSettings[@player_id]['enable_inventory_boxes']
						DownstreamHook.remove('inventory_boxes_off')
					end
				end
			elsif (name == 'app') and (@name = attributes['char'])
				@game = attributes['game']
				if @game.nil? or @game.empty?
					@game = 'unknown'
				end
				unless File.exists?("#{$data_dir}#{@game}")
					Dir.mkdir("#{$data_dir}#{@game}")
				end
				unless File.exists?("#{$data_dir}#{@game}/#{@name}")
					Dir.mkdir("#{$data_dir}#{@game}/#{@name}")
				end
				if $frontend =~ /^(?:wizard|avalon)$/
					$_SERVER_.puts "#{$cmd_prefix}_flag Display Dialog Boxes 0"
					sleep "0.05".to_f
					$_SERVER_.puts "#{$cmd_prefix}_injury 2"
					sleep "0.05".to_f
					# fixme: game name hardcoded as Gemstone IV; maybe doesn't make any difference to the client
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
				$_SERVER_.puts("#{$cmd_prefix}_flag Display Inventory Boxes 1")
				UserVariables.init
				Alias.init
				Favorites.init
				if arg = ARGV.find { |a| a=~ /^\-\-start\-scripts=/ }
					for script_name in arg.sub('--start-scripts=', '').split(',')
						start_script(script_name)
					end
				end
			end
		rescue
			$stdout.puts "--- error: XMLParser.tag_start: #{$!}"
			$stderr.puts "error: XMLParser.tag_start: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.1".to_f
			reset
		end
	end
	def text(text_string)
		begin
			# fixme: /<stream id="Spells">.*?<\/stream>/m
			# $_CLIENT_.write(text_string) unless ($frontend != 'suks') or (@current_stream =~ /^(?:spellfront|inv|bounty|society)$/) or @active_tags.any? { |tag| tag =~ /^(?:compDef|inv|component|right|left|spell)$/ } or (@active_tags.include?('stream') and @active_ids.include?('Spells')) or (text_string == "\n" and (@last_tag =~ /^(?:popStream|prompt|compDef|dialogData|openDialog|switchQuickBar|component)$/))
			if @active_tags.include?('inv')
				if @active_tags[-1] == 'a'
					@obj_name = text_string
				elsif @obj_name.nil?
					@obj_before_name = text_string.strip
				else
					@obj_after_name = text_string.strip
				end
			elsif @active_tags.last == 'prompt'
				#@prompt = text_string
				nil
			elsif @active_tags.include?('right')
				GameObj.new_right_hand(@obj_exist, @obj_noun, text_string)
				$_CLIENT_.puts "\034GSm#{sprintf('%-45s', text_string)}\r\n" if @send_fake_tags
			elsif @active_tags.include?('left')
				GameObj.new_left_hand(@obj_exist, @obj_noun, text_string)
				$_CLIENT_.puts "\034GSl#{sprintf('%-45s', text_string)}\r\n" if @send_fake_tags
			elsif @active_tags.include?('spell')
				@prepared_spell = text_string
				$_CLIENT_.puts "\034GSn#{sprintf('%-14s', text_string)}\r\n" if @send_fake_tags
			elsif @active_tags.include?('compDef') or @active_tags.include?('component')
				if @active_ids.include?('room objs')
					if @active_tags.include?('a')
						if @bold
							GameObj.new_npc(@obj_exist, @obj_noun, text_string)
						else
							GameObj.new_loot(@obj_exist, @obj_noun, text_string)
						end
					elsif (text_string =~ /that (?:is|appears) ([\w\s]+)(?:,| and|\.)/) or (text_string =~ / \(([^\(]+)\)/)
						GameObj.npcs[-1].status = $1
					end
				elsif @active_ids.include?('room players')
					if @active_tags.include?('a')
						@pc = GameObj.new_pc(@obj_exist, @obj_noun, "#{@player_title}#{text_string}", @player_status)
						@player_status = nil
					else
						if @game =~ /^DR/
							GameObj.clear_pcs
							text_string.sub(/^Also here\: /, '').sub(/ and ([^,]+)\./) { ", #{$1}" }.split(', ').each { |player|
								if player =~ / who is (.+)/
									status = $1
									player.sub!(/ who is .+/, '')
								elsif player =~ / \((.+)\)/
									status = $1
									player.sub!(/ \(.+\)/, '')
								else
									status = nil
								end
								noun = player.slice(/\b[A-Z][a-z]+$/)
								if player =~ /the body of /
									player.sub!('the body of ', '')
									if status
										status.concat ' dead'
									else
										status = 'dead'
									end
								end
								if player =~ /a stunned /
									player.sub!('a stunned ', '')
									if status
										status.concat ' stunned'
									else
										status = 'stunned'
									end
								end
								GameObj.new_pc(nil, noun, player, status)
							}
						else
							if (text_string =~ /^ who (?:is|appears) ([\w\s]+)(?:,| and|\.|$)/) or (text_string =~ / \(([\w\s]+)\)(?: \(([\w\s]+)\))?/)
								if @pc.status
									@pc.status.concat " #{$1}"
								else
									@pc.status = $1
								end
								@pc.status.concat " #{$2}" if $2
							end
							if text_string =~ /(?:^Also here: |, )(?:a )?([a-z\s]+)?([\w\s\-!\?',]+)?$/
								@player_status = ($1.strip.gsub('the body of', 'dead')) if $1
								@player_title = $2
							end
						end
					end
				elsif @active_ids.include?('room desc')
					if text_string == '[Room window disabled at this location.]'
						@room_window_disabled = true
					else
						@room_window_disabled = false
						@room_description.concat(text_string)
						if @active_tags.include?('a')
							GameObj.new_room_desc(@obj_exist, @obj_noun, text_string)
						end
					end
				elsif @active_ids.include?('room exits')
					@room_exits_string.concat(text_string)
					@room_exits.push(text_string) if @active_tags.include?('d')
				end
			elsif @current_stream == 'bounty'
				@bounty_task += text_string
			elsif @current_stream == 'society'
				@society_task = text_string
			elsif (@current_stream == 'inv') and @active_tags.include?('a')
				GameObj.new_inv(@obj_exist, @obj_noun, text_string, nil)
			elsif @current_stream == 'familiar'
				# fixme: familiar room tracking does not (can not?) auto update, status of pcs and npcs isn't tracked at all, titles of pcs aren't tracked
				if @current_style == 'roomName'
					@familiar_room_title = text_string
					@familiar_room_description = String.new
					@familiar_room_exits = Array.new
					GameObj.clear_fam_room_desc
					GameObj.clear_fam_loot
					GameObj.clear_fam_npcs
					GameObj.clear_fam_pcs
					@fam_mode = String.new
				elsif @current_style == 'roomDesc'
					@familiar_room_description.concat(text_string)
					if @active_tags.include?('a')
						GameObj.new_fam_room_desc(@obj_exist, @obj_noun, text_string)
					end
				elsif text_string =~ /^You also see/
					@fam_mode = 'things'
				elsif text_string =~ /^Also here/
					@fam_mode = 'people'
				elsif text_string =~ /Obvious (?:paths|exits)/
					@fam_mode = 'paths'
				elsif @fam_mode == 'things'
					if @active_tags.include?('a')
						if @bold
							GameObj.new_fam_npc(@obj_exist, @obj_noun, text_string)
						else
							GameObj.new_fam_loot(@obj_exist, @obj_noun, text_string)
						end
					end
					# puts 'things: ' + text_string
				elsif @fam_mode == 'people' and @active_tags.include?('a')
					GameObj.new_fam_pc(@obj_exist, @obj_noun, text_string)
					# puts 'people: ' + text_string
				elsif (@fam_mode == 'paths') and @active_tags.include?('a')
					@familiar_room_exits.push(text_string)
				end
			elsif @room_window_disabled
				if @current_style == 'roomDesc'
					@room_description.concat(text_string)
					if @active_tags.include?('a')
						GameObj.new_room_desc(@obj_exist, @obj_noun, text_string)
					end
				elsif text_string =~ /^Obvious (?:paths|exits): (?:none)?$/
					@room_exits_string = text_string.strip
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
			if name == 'inv'
				if @obj_exist == @obj_location
					if @obj_after_name == 'is closed.'
						GameObj.delete_container(@stow_container_id)
					end
				elsif @obj_exist
					GameObj.new_inv(@obj_exist, @obj_noun, @obj_name, @obj_location, @obj_before_name, @obj_after_name)
				end
			elsif @send_fake_tags and (@active_ids.last == 'room exits')
				gsl_exits = String.new
				@room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
				$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
				gsl_exits = nil
			elsif @room_window_disabled and (name == 'compass')
				@room_window_disabled = false
				@room_description = @room_description.strip
				@room_exits_string.concat " #{@room_exits.join(', ')}" unless @room_exits.empty?
				gsl_exits = String.new
				@room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
				$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
				gsl_exits = nil
			end
			@last_tag = @active_tags.pop
			@last_id = @active_ids.pop
		rescue
			$stdout.puts "--- error: XMLParser.tag_end: #{$!}"
			$stderr.puts "error: XMLParser.tag_end: #{$!}"
			$stderr.puts $!.backtrace
			sleep "0.1".to_f
			reset
		end
	end
	# here for backwards compatibility, but spellfront xml isn't sent by the game anymore
	def spellfront
		unless @@warned_depreciated_spellfront
			@@warned_depreciated_spellfront = true
			unless script_name = Script.self.name
				script_name = 'unknown script'
			end
			respond "--- warning: #{script_name} is using depreciated method XMLData.spellfront"
		end
		@active_spells.keys
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
				server_string = @@downstream_hooks[key].call(server_string.dup)
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
				respond "--- error: LichSettings.load: #{$!}"
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
		settings = @@settings.dup
		if caller.any? { |line| line =~ /start_script|start_exec_script|main_with_queue/ }
			settings.delete('quick_game_entry')
			settings.delete('trusted_scripts')
			settings.delete('untrusted_scripts')
		end
		settings
	end
	def LichSettings.clear
		@@settings = Hash.new
	end
	def LichSettings.[](setting_name)
		if (setting_name == 'quick_game_entry') and (($SAFE != 0) or caller.any? { |line| line =~ /start_script|start_exec_script|main_with_queue/})
			nil
		elsif (setting_name == 'trusted_scripts' or setting_name == 'untrusted_scripts') and (($SAFE != 0) or (caller.any? { |line| line =~ /start_script|start_exec_script|main_with_queue/} and Script.self.name !~ /^updater$|^repository$/))
			@@settings[setting_name].dup
		else
			@@settings[setting_name]
		end
	end
	def LichSettings.[]=(setting_name, setting_value)
		if (setting_name == 'quick_game_entry') and (($SAFE != 0) or caller.any? { |line| line =~ /start_script|start_exec_script|main_with_queue/})
			nil
		elsif (setting_name == 'trusted_scripts' or setting_name == 'untrusted_scripts') and (($SAFE != 0) or (caller.any? { |line| line =~ /start_script|start_exec_script|main_with_queue/} and Script.self.name !~ /^updater$|^repository$/))
			nil
		else
			@@settings[setting_name] = setting_value
		end
	end
end

class Settings
	@@settings   ||= Hash.new
	@@timestamps ||= Hash.new
	@@md5        ||= Hash.new
	def Settings.load
		if $SAFE == 0
			if script = Script.self
				if script.class == Script
					if script.name =~ /^lich$/i
						respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use Settings, because it will conflict with Lich\'s settings.'
						return false
					end
					filename = "#{$data_dir}#{script.name}.sav"
					if File.exists?(filename) and (@@timestamps[script.name].nil? or (@@timestamps[script.name] < File.mtime(filename)))
						begin
							File.open(filename, 'rb') { |f| @@settings[script.name] = Marshal.load(f.read) }
							@@timestamps[script] = File.mtime(filename)
							@@md5[script.name] = Digest::MD5.hexdigest(@@settings[script.name].inspect)
						rescue
							respond "--- error: Settings.load: #{$!}"
							$stderr.puts "error: Settings.load: #{$!}"
							$stderr.puts $!.backtrace
							begin
								filename.concat '~'
								if File.exists?(filename)
									File.open(filename, 'rb') { |f| @@settings[script.name] = Marshal.load(f.read) }
									@@timestamps[script] = File.mtime(filename)
									@@md5[script.name] = Digest::MD5.hexdigest(@@settings[script.name].inspect)
								end
							rescue
								respond "--- error: Settings.load: #{$!}"
								$stderr.puts "error: Settings.load: #{$!}"
								$stderr.puts $!.backtrace
							end
						end
					end
				end
			else
				respond '--- Lich: Settings: cannot identify calling script'
			end
		else
			UNTRUSTED_SETTINGS_LOAD.call
		end
		nil
	end
	def Settings.save
		if $SAFE == 0
			if script = Script.self
				if (script.class == Script) or (script.class == WizardScript)
					if script.name =~ /^lich$/i
						respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use Settings, because it will conflict with Lich\'s settings.'
						return false
					end
					filename = "#{$data_dir}#{script.name}.sav"
					@@settings[script.name] ||= Hash.new
					unless (@@settings[script.name].empty? and not File.exists?(filename))
						md5 = Digest::MD5.hexdigest(@@settings[script.name].inspect)
						unless @@md5[script.name] == md5
							begin
								if File.exists?(filename)
									File.rename(filename, "#{filename}~")
								end
								File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@settings[script.name])) }
								@@timestamps[script.name] = File.mtime(filename)
								@@md5[script.name] = md5
							rescue
								respond "--- error: Settings.save: #{$!}"
								$stderr.puts "error: Settings.save: #{$!}"
								$stderr.puts $!.backtrace
							end
						end
					end
				end
			else
				Settings.save_all
			end
		else
			UNTRUSTED_SETTINGS_SAVE.call
		end
		nil
	end
	def Settings.save_all
		if $SAFE == 0
			for script_name in @@settings.keys
				filename = "#{$data_dir}#{script_name}.sav"
				@@settings[script_name] ||= Hash.new
				unless (@@settings[script_name].empty? and not File.exists?(filename))
					md5 = Digest::MD5.hexdigest(@@settings[script_name].inspect)
					unless @@md5[script_name] == md5
						begin
							if File.exists?(filename)
								File.rename(filename, "#{filename}~")
							end
							File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@settings[script_name])) }
							@@timestamps[script_name] = File.mtime(filename)
							@@md5[script_name] = md5
						rescue
							respond "--- error: Settings.save_all: #{$!}"
							$stderr.puts "error: Settings.save_all: #{$!}"
							$stderr.puts $!.backtrace
						end
					end
				end
			end
		else
			UNTRUSTED_SETTINGS_SAVE_ALL.call
		end
		nil
	end
	def Settings.clear
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name].clear
		else
			respond '--- Lich: Settings: cannot identify calling script'
			nil
		end
	end
	def Settings.[](val)
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name][val]
		else
			respond '--- Lich: Settings: cannot identify calling script'
			nil
		end
	end
	def Settings.[]=(setting, val)
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name][setting] = val
			@@settings[script.name][setting]
		else
			respond '--- Lich: Settings: cannot identify calling script'
			nil
		end
	end
	def Settings.to_hash
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name]
		else
			respond '--- Lich: Settings: cannot identify calling script'
			nil
		end
	end
	def Settings.auto=(val)
		nil
	end
	def Settings.auto
		nil
	end
	def Settings.autoload
		nil
	end
end

class GameSettings
	@@settings   ||= Hash.new
	@@timestamps ||= Hash.new
	@@md5        ||= Hash.new
	def GameSettings.load
		if $SAFE == 0
			if script = Script.self
				if script.class == Script
					if script.name =~ /^lich$/i
						respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use GameSettings, because it will conflict with Lich\'s settings.'
						return false
					end
					filename = "#{$data_dir}#{XMLData.game}/#{script.name}.sav"
					if File.exists?(filename) and (@@timestamps[script.name].nil? or (@@timestamps[script.name] < File.mtime(filename)))
						begin
							File.open(filename, 'rb') { |f| @@settings[script.name] = Marshal.load(f.read) }
							@@timestamps[script] = File.mtime(filename)
							@@md5[script.name] = Digest::MD5.hexdigest(@@settings[script.name].inspect)
						rescue
							respond "--- error: GameSettings.load: #{$!}"
							$stderr.puts "error: GameSettings.load: #{$!}"
							$stderr.puts $!.backtrace
							begin
								filename.concat '~'
								if File.exists?(filename)
									File.open(filename, 'rb') { |f| @@settings[script.name] = Marshal.load(f.read) }
									@@timestamps[script] = File.mtime(filename)
									@@md5[script.name] = Digest::MD5.hexdigest(@@settings[script.name].inspect)
								end
							rescue
								respond "--- error: GameSettings.load: #{$!}"
								$stderr.puts "error: GameSettings.load: #{$!}"
								$stderr.puts $!.backtrace
							end
						end
					end
				end
			else
				respond '--- Lich: GameSettings: cannot identify calling script'
			end
		else
			UNTRUSTED_GAMESETTINGS_LOAD.call
		end
		nil
	end
	def GameSettings.save
		if $SAFE == 0
			if script = Script.self
				if script.class == Script
					if script.name =~ /^lich$/i
						respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use Settings, because it will conflict with Lich\'s settings.'
						return false
					end
					filename = "#{$data_dir}#{XMLData.game}/#{script.name}.sav"
					@@settings[script.name] ||= Hash.new
					unless (@@settings[script.name].empty? and not File.exists?(filename))
						md5 = Digest::MD5.hexdigest(@@settings[script.name].inspect)
						unless @@md5[script.name] == md5
							begin
								if File.exists?(filename)
									File.rename(filename, "#{filename}~")
								end
								File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@settings[script.name])) }
								@@timestamps[script.name] = File.mtime(filename)
								@@md5[script.name] = md5
							rescue
								respond "--- error: GameSettings.save: #{$!}"
								$stderr.puts "error: GameSettings.save: #{$!}"
								$stderr.puts $!.backtrace
							end
						end
					end
				end
			else
				GameSettings.save_all
			end
		else
			UNTRUSTED_GAMESETTINGS_SAVE.call
		end
		nil
	end
	def GameSettings.save_all
		if $SAFE == 0
			for script_name in @@settings.keys
				filename = "#{$data_dir}#{XMLData.game}/#{script_name}.sav"
				@@settings[script_name] ||= Hash.new
				unless (@@settings[script_name].empty? and not File.exists?(filename))
					md5 = Digest::MD5.hexdigest(@@settings[script_name].inspect)
					unless @@md5[script_name] == md5
						begin
							if File.exists?(filename)
								File.rename(filename, "#{filename}~")
							end
							File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@settings[script_name])) }
							@@timestamps[script_name] = File.mtime(filename)
							@@md5[script_name] = md5
						rescue
							respond "--- error: GameSettings.save_all: #{$!}"
							$stderr.puts "error: GameSettings.save_all: #{$!}"
							$stderr.puts $!.backtrace
						end
					end
				end
			end
		else
			UNTRUSTED_GAMESETTINGS_SAVE_ALL.call
		end
		nil
	end
	def GameSettings.clear
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name].clear
		else
			respond '--- Lich: GameSettings: cannot identify calling script'
			nil
		end
	end
	def GameSettings.[](val)
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name][val]
		else
			respond '--- Lich: GameSettings: cannot identify calling script'
			nil
		end
	end
	def GameSettings.[]=(setting, val)
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name][setting] = val
			@@settings[script.name][setting]
		else
			respond '--- Lich: GameSettings: cannot identify calling script'
			nil
		end
	end
	def GameSettings.to_hash
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name]
		else
			respond '--- Lich: GameSettings: cannot identify calling script'
			nil
		end
	end
end

class CharSettings
	@@settings   ||= Hash.new
	@@timestamps ||= Hash.new
	@@md5        ||= Hash.new
	def CharSettings.load
		if $SAFE == 0
			if script = Script.self
				if script.class == Script
					if script.name =~ /^lich$/i
						respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use CharSettings, because it will conflict with Lich\'s settings.'
						return false
					end
					filename = "#{$data_dir}#{XMLData.game}/#{XMLData.name}/#{script.name}.sav"
					if File.exists?(filename) and (@@timestamps[script.name].nil? or (@@timestamps[script.name] < File.mtime(filename)))
						begin
							File.open(filename, 'rb') { |f| @@settings[script.name] = Marshal.load(f.read) }
							@@timestamps[script] = File.mtime(filename)
							@@md5[script.name] = Digest::MD5.hexdigest(@@settings[script.name].inspect)
						rescue
							respond "--- error: CharSettings.load: #{$!}"
							$stderr.puts "error: CharSettings.load: #{$!}"
							$stderr.puts $!.backtrace
							begin
								filename.concat '~'
								if File.exists?(filename)
									File.open(filename, 'rb') { |f| @@settings[script.name] = Marshal.load(f.read) }
									@@timestamps[script] = File.mtime(filename)
									@@md5[script.name] = Digest::MD5.hexdigest(@@settings[script.name].inspect)
								end
							rescue
								respond "--- error: CharSettings.load: #{$!}"
								$stderr.puts "error: CharSettings.load: #{$!}"
								$stderr.puts $!.backtrace
							end
						end
					end
				end
			else
				respond '--- Lich: CharSettings: cannot identify calling script'
			end
		else
			UNTRUSTED_CHARSETTINGS_LOAD.call
		end
		nil
	end
	def CharSettings.save
		if $SAFE == 0
			if script = Script.self
				if script.class == Script
					if script.name =~ /^lich$/i
						respond '--- Lich: If you insist, you may have a script named \'lich\', but it cannot use Settings, because it will conflict with Lich\'s settings.'
						return false
					end
					filename = "#{$data_dir}#{XMLData.game}/#{XMLData.name}/#{script.name}.sav"
					@@settings[script.name] ||= Hash.new
					unless (@@settings[script.name].empty? and not File.exists?(filename))
						md5 = Digest::MD5.hexdigest(@@settings[script.name].inspect)
						unless @@md5[script.name] == md5
							begin
								if File.exists?(filename)
									File.rename(filename, "#{filename}~")
								end
								File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@settings[script.name])) }
								@@timestamps[script.name] = File.mtime(filename)
								@@md5[script.name] = md5
							rescue
								respond "--- error: CharSettings.save: #{$!}"
								$stderr.puts "error: CharSettings.save: #{$!}"
								$stderr.puts $!.backtrace
							end
						end
					end
				end
			else
				CharSettings.save_all
			end
		else
			UNTRUSTED_CHARSETTINGS_SAVE.call
		end
		nil
	end
	def CharSettings.save_all
		if $SAFE == 0
			for script_name in @@settings.keys
				filename = "#{$data_dir}#{XMLData.game}/#{XMLData.name}/#{script_name}.sav"
				@@settings[script_name] ||= Hash.new
				unless (@@settings[script_name].empty? and not File.exists?(filename))
					md5 = Digest::MD5.hexdigest(@@settings[script_name].inspect)
					unless @@md5[script_name] == md5
						begin
							if File.exists?(filename)
								File.rename(filename, "#{filename}~")
							end
							File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@settings[script_name])) }
							@@timestamps[script_name] = File.mtime(filename)
							@@md5[script_name] = md5
						rescue
							respond "--- error: CharSettings.save_all: #{$!}"
							$stderr.puts "error: CharSettings.save_all: #{$!}"
							$stderr.puts $!.backtrace
						end
					end
				end
			end
		else
			UNTRUSTED_CHARSETTINGS_SAVE_ALL.call
		end
		nil
	end
	def CharSettings.clear
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name].clear
		else
			respond '--- Lich: CharSettings: cannot identify calling script'
			nil
		end
	end
	def CharSettings.[](val)
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name][val]
		else
			respond '--- Lich: CharSettings: cannot identify calling script'
			nil
		end
	end
	def CharSettings.[]=(setting, val)
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name][setting] = val
			@@settings[script.name][setting]
		else
			respond '--- Lich: CharSettings: cannot identify calling script'
			nil
		end
	end
	def CharSettings.to_hash
		if (script = Script.self) and (script.class == Script)
			@@settings[script.name] ||= Hash.new
			@@settings[script.name]
		else
			respond '--- Lich: CharSettings: cannot identify calling script'
			nil
		end
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
				respond "--- error: Favorites.load: #{$!}"
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
				respond "--- error: Alias.init: #{$!}"
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
		trigger = Regexp.escape(trigger.strip)
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
		target = target.split('\\r')
		if extra.empty?
			target.collect! { |line| line.gsub('\\?', '') }
		elsif target.any? { |line| line.include?('\\?') }
			target.collect! { |line|
				if line =~ /^;e.*"\\\?"/
					line.gsub('"\\?"', extra.inspect)
				elsif line.include?('\\?')
					line.gsub('\\?', extra)
				else
					line
				end
			}
		elsif target.length == 1
			target.first.concat(" #{extra}")
		end
		target.each { |line| do_client("#{line.chomp}\n") }
	end
end

class UserVariables
	@@settings ||= Hash.new
	@@settings_mtime = nil
	@@char_settings ||= Hash.new

	def UserVariables.init
		if File.exists?("#{$data_dir}uservars.dat")
			begin
				File.open("#{$data_dir}uservars.dat", 'rb') { |f|
					@@settings = Marshal.load(f.read)
				}
				@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
			rescue
				respond "--- error: UserVariables.init: #{$!}"
				$stderr.puts "error: UserVariables.init: #{$!}"
				$stderr.puts $!.backtrace
			end
		elsif File.exists?("#{$data_dir}lich.sav")
			begin
				File.open("#{$data_dir}lich.sav", 'rb') { |f|
					@@settings = Marshal.load(f.read)['uservariables']['global'] || Hash.new
				}
				File.open("#{$data_dir}uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@settings)) }
				@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
			rescue
				respond "--- error: UserVariables.init: #{$!}"
				$stderr.puts "error: UserVariables.init: #{$!}"
				$stderr.puts $!.backtrace
			end
		end
		if File.exists?("#{$data_dir}#{XMLData.game}/#{XMLData.name}/uservars.dat")
			begin
				File.open("#{$data_dir}#{XMLData.game}/#{XMLData.name}/uservars.dat", 'rb') { |f|
					@@char_settings = Marshal.load(f.read)
				}
			rescue
				respond "--- error: UserVariables.init: #{$!}"
				$stderr.puts "error: UserVariables.init: #{$!}"
				$stderr.puts $!.backtrace
			end
		elsif File.exists?("#{$data_dir}lich.sav")
			begin
				File.open("#{$data_dir}lich.sav", 'rb') { |f|
					@@char_settings = Marshal.load(f.read)['uservariables'][XMLData.name] || Hash.new
				}
			rescue
				respond "--- error: UserVariables.init: #{$!}"
				$stderr.puts "error: UserVariables.init: #{$!}"
				$stderr.puts $!.backtrace
			end
		end
	end
	def UserVariables.save
		if $SAFE == 0
			File.open("#{$data_dir}uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@settings)) }
			@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
			File.open("#{$data_dir}#{XMLData.game}/#{XMLData.name}/uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@char_settings)) }
		else
			UNTRUSTED_USERVARIABLES_SAVE.call
		end
	end
	def UserVariables.change(var_name, value, type = :char)
		if $SAFE == 0
			if type == :char
				@@char_settings[var_name] = value
				File.open("#{$data_dir}#{XMLData.game}/#{XMLData.name}/uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@char_settings)) }
				true
				elsif type == :global
				if @@settings_mtime < File.mtime("#{$data_dir}uservars.dat")
					File.open("#{$data_dir}uservars.dat", 'rb') { |f| @@settings = Marshal.load(f.read) }
				end
				@@settings[var_name] = value
				File.open("#{$data_dir}uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@settings)) }
				@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
				true
			else
				echo 'UserVariables.change: invalid type given, use :char or :global.'
				false
			end
		else
			UNTRUSTED_USERVARIABLES_CHANGE.call(var_name, value, type)
		end
	end
	def UserVariables.add(var_name, value, type = :char)
		if $SAFE == 0
			if type == :char
				@@char_settings[var_name] = @@char_settings[var_name].split(', ').push(value.strip).join(', ')
				File.open("#{$data_dir}#{XMLData.game}/#{XMLData.name}/uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@char_settings)) }
				true
			elsif type == :global
				if @@settings_mtime < File.mtime("#{$data_dir}uservars.dat")
					File.open("#{$data_dir}uservars.dat", 'rb') { |f| @@settings = Marshal.load(f.read) }
				end
				@@settings[var_name] = @@settings[var_name].split(', ').push(value.strip).join(', ')
				File.open("#{$data_dir}uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@settings)) }
				@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
				true
			else
				echo 'UserVariables.add: invalid type given, use :char or :global.'
				nil
			end
		else
			UNTRUSTED_USERVARIABLES_ADD.call(var_name, value, type)
		end
	end
	def UserVariables.delete(var_name, type = :char)
		if $SAFE == 0
			if type == :char
				if @@char_settings.delete(var_name)
					File.open("#{$data_dir}#{XMLData.game}/#{XMLData.name}/uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@char_settings)) }
					true
				else
					false
				end
			elsif type == :global
				if @@settings_mtime < File.mtime("#{$data_dir}uservars.dat")
					File.open("#{$data_dir}uservars.dat", 'rb') { |f| @@settings = Marshal.load(f.read) }
					@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
				end
				if @@settings.delete(var_name)
					File.open("#{$data_dir}uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@settings)) }
					@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
					true
				else
					false
				end
			else
				false
			end
		else
			UNTRUSTED_USERVARIABLES_DELETE.call(var_name, type)
		end
	end
	def UserVariables.list_global
		@@settings.dup
	end
	def UserVariables.list_char
		@@char_settings.dup
	end
	def UserVariables.method_missing(arg1, arg2='')
		if $SAFE == 0
			if arg1.to_s.split('')[-1] == '='
				@@char_settings[arg1.to_s.chop] = arg2
				File.open("#{$data_dir}#{XMLData.game}/#{XMLData.name}/uservars.dat", 'wb') { |f| f.write(Marshal.dump(@@char_settings)) }
			elsif @@char_settings[arg1.to_s]
				@@char_settings[arg1.to_s]
			else
				if @@settings_mtime < File.mtime("#{$data_dir}uservars.dat")
					File.open("#{$data_dir}uservars.dat", 'rb') { |f| @@settings = Marshal.load(f.read) }
					@@settings_mtime = File.mtime("#{$data_dir}uservars.dat")
				end
				@@settings[arg1.to_s]
			end
		else
			UNTRUSTED_USERVARIABLES_METHOD_MISSING.call(arg1, arg2)
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
	attr_accessor :quiet, :no_echo, :jump_label, :current_label, :want_downstream, :want_downstream_xml, :want_upstream, :want_script_output, :dying_procs, :hidden, :paused, :silent, :no_pause_all, :no_kill_all, :downstream_buffer, :upstream_buffer, :unique_buffer, :die_with, :match_stack_labels, :match_stack_strings, :watchfor, :command_line
	def Script.self
		if script = @@running.find { |scr| scr.thread_group == Thread.current.group }
			sleep "0.2".to_f while script.paused
			script
		else
			nil
		end
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
	def Script.exists?(scriptname)
		scriptname += '.lic' unless (scriptname =~ /\.lic$/i)
		if $SAFE == 0
			if File.exists?("#{$script_dir}#{scriptname}") and (File.dirname("#{$script_dir}#{scriptname}") == $script_dir.sub(/\/$/,''))
				true
			else
				false
			end
		else
			UNTRUSTED_SCRIPT_EXISTS.call(scriptname)
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
	def Script.new_downstream(line)
		@@running.each { |script|
			script.downstream_buffer.push(line.chomp) if script.want_downstream
			unless script.watchfor.empty?
				script.watchfor.each_pair { |trigger,action|
					if line =~ trigger
						new_thread = Thread.new {
							sleep "0.011".to_f until Script.self
							begin
								action.call
							rescue
								echo "watchfor error: #{$!}"
							end
						}
						script.thread_group.add(new_thread)
					end
				}
			end
		}
	end
	def Script.new_script_output(line)
		for script in @@running
			script.downstream_buffer.push(line.chomp) if script.want_script_output
		end
	end
	def Script.log(data)
		if $SAFE == 0
			if script = Script.self
				begin
					unless File.exists?("#{$lich_dir}logs")
						Dir.mkdir("#{$lich_dir}logs")
					end
					File.open("#{$lich_dir}logs/#{script.name}.log", 'a') { |file| file.puts data }
					true
				rescue
					respond "--- error: Script.log: #{$!}"
					false
				end
			else
				respond '--- Script.log: unable to identify calling script'
				false
			end
		else
			UNTRUSTED_SCRIPT_LOG.call(data)
		end
	end
	def initialize(file_name, cli_vars=[], cmd_line=nil)
		@name = /.*[\/\\]+([^\.]+)\./.match(file_name).captures.first
		@file_name = file_name
		@command_line = cmd_line || cli_vars.join(' ')
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
		@want_script_output = false
		@upstream_buffer = LimitedArray.new
		@want_upstream = false
		@unique_buffer = LimitedArray.new
		@watchfor = Hash.new
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
		@labels[@current_label] = String.new
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
			begin
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
				Settings.save
				GameSettings.save
				CharSettings.save
				@@running.delete(self)
				respond("--- Lich: #{@name} has exited.") unless @quiet
				GC.start
			rescue
				puts $!
				puts $!.backtrace[0..2]
			end
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
	def to_s
		@name
	end
	def gets
		# fixme: no xml gets
		if @want_downstream or @want_downstream_xml or @want_script_output
			sleep "0.05".to_f while @downstream_buffer.empty?
			@downstream_buffer.shift
		else
			echo 'this script is set as unique but is waiting for game data...'
			sleep 2
			false
		end
	end
	def gets?
		if @want_downstream or @want_downstream_xml or @want_script_output
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
	def initialize(cmd_data, flags=Hash.new)
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
		@watchfor = Hash.new
		@hidden = false
		@paused = false
		@silent = false
		if flags[:quiet].nil?
			@quiet = false
		else
			@quiet = flags[:quiet]
		end
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
		@patchfor = Hash.new
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
			elsif line =~ /^([\s\t]*)put[\s\t]+(?:\.|;)(.+)$/i
				indent, arg = $1, $2
				if arg.include?(' ')
					line = "#{indent}start_script(#{Regexp.escape(fixstring.call(arg.split[0].inspect))}, #{fixstring.call(arg.split[1..-1].join(' ').scan(/"[^"]+"|[^"\s]+/).inspect)})\n#{indent}exit"
				else
					line = "#{indent}start_script(#{Regexp.escape(fixstring.call(arg.inspect))})\n#{indent}exit"
				end
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
		@labels[@current_label] = String.new
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

class UntrustedScriptBinder
	def create_block
		Proc.new { }
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
		ary.push sprintf("Name: %s  Race: %s  Profession: %s", XMLData.name, Stats.race, Stats.prof)
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
		ary.push sprintf("%s (at level %d), your current skill bonuses and ranks (including all modifiers) are:", XMLData.name, Stats.level)
		ary.push sprintf("  %-035s| Current Current", 'Skill Name')
		ary.push sprintf("  %-035s|%08s%08s", '', 'Bonus', 'Ranks')
		fmt = [ [ 'Two Weapon Combat', 'Armor Use', 'Shield Use', 'Combat Maneuvers', 'Edged Weapons', 'Blunt Weapons', 'Two-Handed Weapons', 'Ranged Weapons', 'Thrown Weapons', 'Polearm Weapons', 'Brawling', 'Ambush', 'Multi Opponent Combat', 'Combat Leadership', 'Physical Fitness', 'Dodging', 'Arcane Symbols', 'Magic Item Use', 'Spell Aiming', 'Harness Power', 'Elemental Mana Control', 'Mental Mana Control', 'Spirit Mana Control', 'Elemental Lore - Air', 'Elemental Lore - Earth', 'Elemental Lore - Fire', 'Elemental Lore - Water', 'Spiritual Lore - Blessings', 'Spiritual Lore - Religion', 'Spiritual Lore - Summoning', 'Sorcerous Lore - Demonology', 'Sorcerous Lore - Necromancy', 'Mental Lore - Divination', 'Mental Lore - Manipulation', 'Mental Lore - Telepathy', 'Mental Lore - Transference', 'Mental Lore - Transformation', 'Survival', 'Disarming Traps', 'Picking Locks', 'Stalking and Hiding', 'Perception', 'Climbing', 'Swimming', 'First Aid', 'Trading', 'Pickpocketing' ], [ 'twoweaponcombat', 'armoruse', 'shielduse', 'combatmaneuvers', 'edgedweapons', 'bluntweapons', 'twohandedweapons', 'rangedweapons', 'thrownweapons', 'polearmweapons', 'brawling', 'ambush', 'multiopponentcombat', 'combatleadership', 'physicalfitness', 'dodging', 'arcanesymbols', 'magicitemuse', 'spellaiming', 'harnesspower', 'emc', 'mmc', 'smc', 'elair', 'elearth', 'elfire', 'elwater', 'slblessings', 'slreligion', 'slsummoning', 'sldemonology', 'slnecromancy', 'mldivination', 'mlmanipulation', 'mltelepathy', 'mltransference', 'mltransformation', 'survival', 'disarmingtraps', 'pickinglocks', 'stalkingandhiding', 'perception', 'climbing', 'swimming', 'firstaid', 'trading', 'pickpocketing' ] ]
		0.upto(fmt.first.length - 1) { |n|
			dots = '.' * (35 - fmt[0][n].length)
			rnk = Skills.send(fmt[1][n])
			ary.push sprintf("  %s%s|%08s%08s", fmt[0][n], dots, Skills.to_bonus(rnk), rnk) unless rnk.zero?
		}
		%[Minor Elemental,Major Elemental,Minor Spirit,Major Spirit,Minor Mental,Bard,Cleric,Empath,Paladin,Ranger,Sorcerer,Wizard].split(',').each { |circ|
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
		(Spellsong.duration - ((Time.now - @@renewed) % Spellsong.duration)) / 60.to_f
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
				@@renewed = Time.at(Time.now.to_f - (Spellsong.duration - old * 60.to_f))
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
		total + Stats.log[1].to_i + (Stats.inf[1].to_i * 3) + (Skills.mltelepathy.to_i * 2)
	end
	def Spellsong.renew_cost
		# fixme: multi-spell penalty?
		total = num_active = 0
		[ 1003, 1006, 1009, 1010, 1012, 1014, 1018, 1019, 1025 ].each { |song_num|
			if song = Spell[song_num]
				if song.active?
					total += song.renew_cost
					num_active += 1
				end
			else
				echo "Spellsong.renew_cost: warning: can't find song number #{song_num}"
			end
		}
		return total
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
	def Spellsong.tonishastebonus
		bonus = -1
		thresholds = [30,75]
		thresholds.each { |val| if Skills.elair >= val then bonus -= 1 end }
		bonus
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
	def Spellsong.holdingtargets
		1 + ((Spells.bard - 1) / 7).truncate
	end
	#
	# depreciated
	#
	def Spellsong.cost
		Spellsong.renew_cost
	end
	def Spellsong.tonisdodgebonus
		thresholds = [1,2,3,5,8,10,14,17,21,26,31,36,42,49,55,63,70,78,87,96]
		bonus = 20
		thresholds.each { |val| if Skills.elair >= val then bonus += 1 end }
		bonus
	end
	def Spellsong.mirrorsdodgebonus
		20 + ((Spells.bard - 19) / 2).round
	end
	def Spellsong.mirrorscost
		[19 + ((Spells.bard - 19) / 5).truncate, 8 + ((Spells.bard - 19) / 10).truncate]
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

	def Skills.twoweaponcombat;           @@twoweaponcombat;         end
	def Skills.twoweaponcombat=(val);     @@twoweaponcombat=val;     end
	def Skills.armoruse;                  @@armoruse;                end
	def Skills.armoruse=(val);            @@armoruse=val;            end
	def Skills.shielduse;                 @@shielduse;               end
	def Skills.shielduse=(val);           @@shielduse=val;           end
	def Skills.combatmaneuvers;           @@combatmaneuvers;         end
	def Skills.combatmaneuvers=(val);     @@combatmaneuvers=val;     end
	def Skills.edgedweapons;              @@edgedweapons;            end
	def Skills.edgedweapons=(val);        @@edgedweapons=val;        end
	def Skills.bluntweapons;              @@bluntweapons;            end
	def Skills.bluntweapons=(val);        @@bluntweapons=val;        end
	def Skills.twohandedweapons;          @@twohandedweapons;        end
	def Skills.twohandedweapons=(val);    @@twohandedweapons=val;    end
	def Skills.rangedweapons;             @@rangedweapons;           end
	def Skills.rangedweapons=(val);       @@rangedweapons=val;       end
	def Skills.thrownweapons;             @@thrownweapons;           end
	def Skills.thrownweapons=(val);       @@thrownweapons=val;       end
	def Skills.polearmweapons;            @@polearmweapons;          end
	def Skills.polearmweapons=(val);      @@polearmweapons=val;      end
	def Skills.brawling;                  @@brawling;                end
	def Skills.brawling=(val);            @@brawling=val;            end
	def Skills.ambush;                    @@ambush;                  end
	def Skills.ambush=(val);              @@ambush=val;              end
	def Skills.multiopponentcombat;       @@multiopponentcombat;     end
	def Skills.multiopponentcombat=(val); @@multiopponentcombat=val; end
	def Skills.combatleadership;          @@combatleadership;        end
	def Skills.combatleadership=(val);    @@combatleadership=val;    end
	def Skills.physicalfitness;           @@physicalfitness;         end
	def Skills.physicalfitness=(val);     @@physicalfitness=val;     end
	def Skills.dodging;                   @@dodging;                 end
	def Skills.dodging=(val);             @@dodging=val;             end
	def Skills.arcanesymbols;             @@arcanesymbols;           end
	def Skills.arcanesymbols=(val);       @@arcanesymbols=val;       end
	def Skills.magicitemuse;              @@magicitemuse;            end
	def Skills.magicitemuse=(val);        @@magicitemuse=val;        end
	def Skills.spellaiming;               @@spellaiming;             end
	def Skills.spellaiming=(val);         @@spellaiming=val;         end
	def Skills.harnesspower;              @@harnesspower;            end
	def Skills.harnesspower=(val);        @@harnesspower=val;        end
	def Skills.emc;                       @@emc;                     end
	def Skills.emc=(val);                 @@emc=val;                 end
	def Skills.mmc;                       @@mmc;                     end
	def Skills.mmc=(val);                 @@mmc=val;                 end
	def Skills.smc;                       @@smc;                     end
	def Skills.smc=(val);                 @@smc=val;                 end
	def Skills.elair;                     @@elair;                   end
	def Skills.elair=(val);               @@elair=val;               end
	def Skills.elearth;                   @@elearth;                 end
	def Skills.elearth=(val);             @@elearth=val;             end
	def Skills.elfire;                    @@elfire;                  end
	def Skills.elfire=(val);              @@elfire=val;              end
	def Skills.elwater;                   @@elwater;                 end
	def Skills.elwater=(val);             @@elwater=val;             end
	def Skills.slblessings;               @@slblessings;             end
	def Skills.slblessings=(val);         @@slblessings=val;         end
	def Skills.slreligion;                @@slreligion;              end
	def Skills.slreligion=(val);          @@slreligion=val;          end
	def Skills.slsummoning;               @@slsummoning;             end
	def Skills.slsummoning=(val);         @@slsummoning=val;         end
	def Skills.sldemonology;              @@sldemonology;            end
	def Skills.sldemonology=(val);        @@sldemonology=val;        end
	def Skills.slnecromancy;              @@slnecromancy;            end
	def Skills.slnecromancy=(val);        @@slnecromancy=val;        end
	def Skills.mldivination;              @@mldivination;            end
	def Skills.mldivination=(val);        @@mldivination=val;        end
	def Skills.mlmanipulation;            @@mlmanipulation;          end
	def Skills.mlmanipulation=(val);      @@mlmanipulation=val;      end
	def Skills.mltelepathy;               @@mltelepathy;             end
	def Skills.mltelepathy=(val);         @@mltelepathy=val;         end
	def Skills.mltransference;            @@mltransference;          end
	def Skills.mltransference=(val);      @@mltransference=val;      end
	def Skills.mltransformation;          @@mltransformation;        end
	def Skills.mltransformation=(val);    @@mltransformation=val;    end
	def Skills.survival;                  @@survival;                end
	def Skills.survival=(val);            @@survival=val;            end
	def Skills.disarmingtraps;            @@disarmingtraps;          end
	def Skills.disarmingtraps=(val);      @@disarmingtraps=val;      end
	def Skills.pickinglocks;              @@pickinglocks;            end
	def Skills.pickinglocks=(val);        @@pickinglocks=val;        end
	def Skills.stalkingandhiding;         @@stalkingandhiding;       end
	def Skills.stalkingandhiding=(val);   @@stalkingandhiding=val;   end
	def Skills.perception;                @@perception;              end
	def Skills.perception=(val);          @@perception=val;          end
	def Skills.climbing;                  @@climbing;                end
	def Skills.climbing=(val);            @@climbing=val;            end
	def Skills.swimming;                  @@swimming;                end
	def Skills.swimming=(val);            @@swimming=val;            end
	def Skills.firstaid;                  @@firstaid;                end
	def Skills.firstaid=(val);            @@firstaid=val;            end
	def Skills.trading;                   @@trading;                 end
	def Skills.trading=(val);             @@trading=val;             end
	def Skills.pickpocketing;             @@pickpocketing;           end
	def Skills.pickpocketing=(val);       @@pickpocketing=val;       end

	def Skills.serialize
		[@@twoweaponcombat, @@armoruse, @@shielduse, @@combatmaneuvers, @@edgedweapons, @@bluntweapons, @@twohandedweapons, @@rangedweapons, @@thrownweapons, @@polearmweapons, @@brawling, @@ambush, @@multiopponentcombat, @@combatleadership, @@physicalfitness, @@dodging, @@arcanesymbols, @@magicitemuse, @@spellaiming, @@harnesspower, @@emc, @@mmc, @@smc, @@elair, @@elearth, @@elfire, @@elwater, @@slblessings, @@slreligion, @@slsummoning, @@sldemonology, @@slnecromancy, @@mldivination, @@mlmanipulation, @@mltelepathy, @@mltransference, @@mltransformation, @@survival, @@disarmingtraps, @@pickinglocks, @@stalkingandhiding, @@perception, @@climbing, @@swimming, @@firstaid, @@trading, @@pickpocketing]
	end
	def Skills.load_serialized=(array)
		@@twoweaponcombat, @@armoruse, @@shielduse, @@combatmaneuvers, @@edgedweapons, @@bluntweapons, @@twohandedweapons, @@rangedweapons, @@thrownweapons, @@polearmweapons, @@brawling, @@ambush, @@multiopponentcombat, @@combatleadership, @@physicalfitness, @@dodging, @@arcanesymbols, @@magicitemuse, @@spellaiming, @@harnesspower, @@emc, @@mmc, @@smc, @@elair, @@elearth, @@elfire, @@elwater, @@slblessings, @@slreligion, @@slsummoning, @@sldemonology, @@slnecromancy, @@mldivination, @@mlmanipulation, @@mltelepathy, @@mltransference, @@mltransformation, @@survival, @@disarmingtraps, @@pickinglocks, @@stalkingandhiding, @@perception, @@climbing, @@swimming, @@firstaid, @@trading, @@pickpocketing = array
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
	@@minormental    ||= 0
	@@majorelemental ||= 0
	@@minorspiritual ||= 0
	@@majorspiritual ||= 0
	@@wizard         ||= 0
	@@sorcerer       ||= 0
	@@ranger         ||= 0
	@@paladin        ||= 0
	@@empath         ||= 0
	@@cleric         ||= 0
	@@bard           ||= 0
	def Spells.minorelemental=(val); @@minorelemental = val; end
	def Spells.minorelemental;       @@minorelemental;       end
	def Spells.minormental=(val);    @@minormental = val;    end
	def Spells.minormental;          @@minormental;          end
	def Spells.majorelemental=(val); @@majorelemental = val; end
	def Spells.majorelemental;       @@majorelemental;       end
	def Spells.minorspiritual=(val); @@minorspiritual = val; end
	def Spells.minorspiritual;       @@minorspiritual;       end
	def Spells.minorspirit=(val);    @@minorspiritual = val; end
	def Spells.minorspirit;          @@minorspiritual;       end
	def Spells.majorspiritual=(val); @@majorspiritual = val; end
	def Spells.majorspiritual;       @@majorspiritual;       end
	def Spells.majorspirit=(val);    @@majorspiritual = val; end
	def Spells.majorspirit;          @@majorspiritual;       end
	def Spells.wizard=(val);         @@wizard = val;         end
	def Spells.wizard;               @@wizard;               end
	def Spells.sorcerer=(val);       @@sorcerer = val;       end
	def Spells.sorcerer;             @@sorcerer;             end
	def Spells.ranger=(val);         @@ranger = val;         end
	def Spells.ranger;               @@ranger;               end
	def Spells.paladin=(val);        @@paladin = val;        end
	def Spells.paladin;              @@paladin;              end
	def Spells.empath=(val);         @@empath = val;         end
	def Spells.empath;               @@empath;               end
	def Spells.cleric=(val);         @@cleric = val;         end
	def Spells.cleric;               @@cleric;               end
	def Spells.bard=(val);           @@bard = val;           end
	def Spells.bard;                 @@bard;                 end
	def Spells.get_circle_name(num)
		val = num.to_s
		if val == '1'
			'Minor Spirit'
		elsif val == '2'
			'Major Spirit'
		elsif val == '3'
			'Cleric'
		elsif val == '4'
			'Minor Elemental'
		elsif val == '5'
			'Major Elemental'
		elsif val == '6'
			'Ranger'
		elsif val == '7'
			'Sorcerer'
		elsif val == '9'
			'Wizard'
		elsif val == '10'
			'Bard'
		elsif val == '11'
			'Empath'
		elsif val == '12'
			'Minor Mental'
		elsif val == '16'
			'Paladin'
		elsif val == '17'
			'Arcane'
		elsif val == '66'
			'Death'
		elsif val == '65'
			'Imbedded Enchantment'
		elsif val == '90'
			'Miscellaneous'
		elsif val == '95'
			'Armor Specialization'
		elsif val == '96'
			'Combat Maneuvers'
		elsif val == '97'
			'Guardians of Sunfist'
		elsif val == '98'
			'Order of Voln'
		elsif val == '99'
			'Council of Light'
		else
			'Unknown Circle'
		end
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
		[@@minorelemental,@@majorelemental,@@minorspiritual,@@majorspiritual,@@wizard,@@sorcerer,@@ranger,@@paladin,@@empath,@@cleric,@@bard,@@minormental]
	end
	def Spells.load_serialized=(val)
		@@minorelemental,@@majorelemental,@@minorspiritual,@@majorspiritual,@@wizard,@@sorcerer,@@ranger,@@paladin,@@empath,@@cleric,@@bard,@@minormental = val
		# new spell circle added 2012-07-18; old data files will make @@minormental nil
		@@minormental ||= 0
	end
end

class SpellRanks
	@@list      ||= Array.new
	@@timestamp ||= 0
	@@loaded    ||= false
	attr_reader :name
	attr_accessor :minorspiritual, :majorspiritual, :cleric, :minorelemental, :majorelemental, :minormental, :ranger, :sorcerer, :wizard, :bard, :empath, :paladin, :arcanesymbols, :magicitemuse, :monk
	def SpellRanks.load
		if $SAFE == 0
			if File.exists?("#{$data_dir}#{XMLData.game}/spell-ranks.dat")
				begin
					File.open("#{$data_dir}#{XMLData.game}/spell-ranks.dat", 'rb') { |f|
						@@timestamp, @@list = Marshal.load(f.read)
					}
					# minor mental circle added 2012-07-18; old data files will have @minormental as nil
					@@list.each { |rank_info| rank_info.minormental ||= 0 }
					# monk circle added 2013-01-15; old data files will have @minormental as nil
					@@list.each { |rank_info| rank_info.monk ||= 0 }
					@@loaded = true
				rescue
					respond "--- error: SpellRanks.load: #{$!}"
					$stderr.puts "error: SpellRanks.load: #{$!}"
					$stderr.puts $!.backtrace
					@@list      = Array.new
					@@timestamp = 0
					@@loaded = true
				end
			else
				@@loaded = true
			end
		else
			UNTRUSTED_SPELL_RANKS_LOAD.call
		end
	end
	def SpellRanks.save
		if $SAFE == 0
			begin
				File.open("#{$data_dir}#{XMLData.game}/spell-ranks.dat", 'wb') { |f|
					f.write(Marshal.dump([@@timestamp, @@list]))
				}
			rescue
				respond "--- error: SpellRanks.save: #{$!}"
				$stderr.puts "error: SpellRanks.save: #{$!}"
				$stderr.puts $!.backtrace
			end
		else
			UNTRUSTED_SPELL_RANKS_SAVE.call
		end
	end
	def SpellRanks.timestamp
		SpellRanks.load unless @@loaded
		@@timestamp
	end
	def SpellRanks.timestamp=(val)
		SpellRanks.load unless @@loaded
		@@timestamp = val
	end
	def SpellRanks.[](name)
		SpellRanks.load unless @@loaded
		@@list.find { |n| n.name == name }
	end
	def SpellRanks.list
		SpellRanks.load unless @@loaded
		@@list
	end
	def SpellRanks.method_missing(arg=nil)
		echo "error: unknown method #{arg} for class SpellRanks"
		respond caller[0..1]
	end
	def initialize(name)
		SpellRanks.load unless @@loaded
		@name = name
		@minorspiritual, @majorspiritual, @cleric, @minorelemental, @majorelemental, @ranger, @sorcerer, @wizard, @bard, @empath, @paladin, @minormental, @arcanesymbols, @magicitemuse = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		@@list.push(self)
	end
end

class Spell
	@@list ||= Array.new
	@@loaded ||= false
	@@load_lock = Array.new
	@@cast_lock ||= Array.new
	@@bonus_list ||= Array.new
	@@cost_list ||= Array.new
	attr_reader :num, :name, :timestamp, :msgup, :msgdn, :circle, :active, :type, :cast_proc, :real_time, :persist_on_death, :availability
	attr_accessor :stance, :channel
	def initialize(xml_spell)
		@num = xml_spell.attributes['number'].to_i
		@name = xml_spell.attributes['name']
		@type = xml_spell.attributes['type']
		if xml_spell.attributes['availability'] == 'all'
			@availability = 'all'
		elsif xml_spell.attributes['availability'] == 'group'
			@availability = 'group'
		else
			@availability = 'self-cast'
		end
		@bonus = Hash.new
		xml_spell.elements.find_all { |e| e.name == 'bonus' }.each { |e|
			@bonus[e.attributes['type']] = e.text
			@bonus[e.attributes['type']].untaint
		}
		@msgup = xml_spell.elements.find_all { |e| (e.name == 'message') and (e.attributes['type'].downcase == 'start') }.collect { |e| e.text }.join('$|^')
		@msgup = nil if @msgup.empty?
		@msgdn = xml_spell.elements.find_all { |e| (e.name == 'message') and (e.attributes['type'].downcase == 'end') }.collect { |e| e.text }.join('$|^')
		@msgdn = nil if @msgdn.empty?
		@stance = (xml_spell.attributes['stance'] =~ /^(yes|true)$/i)
		@channel = (xml_spell.attributes['channel'] =~ /^(yes|true)$/i)
		@cost = Hash.new
		xml_spell.elements.find_all { |e| e.name == 'cost' }.each { |xml_cost|
			@cost[xml_cost.attributes['type'].downcase] ||= Hash.new
			if xml_cost.attributes['cast-type'].downcase == 'target'
				@cost[xml_cost.attributes['type'].downcase]['target'] = xml_cost.text
			else
				@cost[xml_cost.attributes['type'].downcase]['self'] = xml_cost.text
			end
		}
		@duration = Hash.new
		xml_spell.elements.find_all { |e| e.name == 'duration' }.each { |xml_duration|
			if xml_duration.attributes['cast-type'].downcase == 'target'
				cast_type = 'target'
			else
				cast_type = 'self'
				if xml_duration.attributes['real-time'] =~ /^(yes|true)$/i
					@real_time = true
				else
					@real_time = false
				end
			end
			@duration[cast_type] = Hash.new
			@duration[cast_type][:duration] = xml_duration.text
			@duration[cast_type][:stackable] = (xml_duration.attributes['span'].downcase == 'stackable')
			@duration[cast_type][:refreshable] = (xml_duration.attributes['span'].downcase == 'refreshable')
			if xml_duration.attributes['multicastable'] =~ /^(yes|true)$/i
				@duration[cast_type][:multicastable] = true
			else
				@duration[cast_type][:multicastable] = false
			end
			if xml_duration.attributes['persist-on-death'] =~ /^(yes|true)$/i
				@persist_on_death = true
			else
				@persist_on_death = false
			end
			if xml_duration.attributes['max']
				@duration[cast_type][:max_duration] = xml_duration.attributes['max'].to_f
			else
				@duration[cast_type][:max_duration] = 250.0
			end
		}
		@cast_proc = xml_spell.elements['cast-proc'].text
		@cast_proc.untaint
		@timestamp = Time.now
		@timeleft = 0
		@active = false
		@circle = (num.to_s.length == 3 ? num.to_s[0..0] : num.to_s[0..1])
		@@list.push(self) unless @@list.find { |spell| spell.num == @num }
		self
	end
	def Spell.load(filename="#{$script_dir}spell-list.xml")
		if $SAFE == 0
			script = Script.self
			begin
				@@load_lock.push(script)
				unless @@load_lock.first == script
					sleep "0.1".to_f until @loaded or (@@load_lock.first == script) or @@load_lock.empty?
					return true if @loaded
				end
				@@loaded = false
				begin
					spell_times = Hash.new
					# reloading spell data should not reset spell tracking...
					unless @@list.empty?
						@@list.each { |spell| spell_times[spell.num] = spell.timeleft if spell.active? }
						@@list.clear
					end
					File.open(filename) { |file|
						xml_doc = REXML::Document.new(file)
						xml_root = xml_doc.root
						xml_root.elements.each { |xml_spell| Spell.new(xml_spell) }
					}
					@@list.each { |spell|
						if spell_times[spell.num]
							spell.timeleft = spell_times[spell.num]
							spell.active = true
						end
					}
					@@loaded = true
					@@bonus_list = @@list.collect { |spell| spell._bonus.keys }.flatten
					@@bonus_list = @@bonus_list | @@bonus_list
					@@cost_list = @@list.collect { |spell| spell._cost.keys }.flatten
					@@cost_list = @@cost_list | @@cost_list
					return true
				rescue
					respond "--- error: Spell.load: #{$!}"
					$stderr.puts "error: Spell.load: #{$!}"
					$stderr.puts $!.backtrace
					@@loaded = false
					return false
				end
			ensure
				@@load_lock.delete(script)
			end
		else
			UNTRUSTED_SPELL_LOAD.call
		end
	end
	def Spell.[](val)
		Spell.load unless @@loaded
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
		Spell.load unless @@loaded
		active = Array.new
		@@list.each { |spell| active.push(spell) if spell.active? }
		active
	end
	def Spell.active?(val)
		Spell.load unless @@loaded
		Spell[val].active?
	end
	def Spell.list
		Spell.load unless @@loaded
		@@list
	end
	def Spell.upmsgs
		Spell.load unless @@loaded
		@@list.collect { |spell| spell.msgup }.compact
	end
	def Spell.dnmsgs
		Spell.load unless @@loaded
		@@list.collect { |spell| spell.msgdn }.compact
	end
	def time_per_formula(options={})
		activator_modifier = { 'tap' => 0.5, 'rub' => 1, 'wave' => 1, 'raise' => 1.33, 'drink' => 0, 'bite' => 0, 'eat' => 0, 'gobble' => 0 }
		can_haz_spell_ranks = /Spells\.(?:minorelemental|majorelemental|minorspiritual|majorspiritual|wizard|sorcerer|ranger|paladin|empath|cleric|bard|minormental)/
		skills = [ 'Spells.minorelemental', 'Spells.majorelemental', 'Spells.minorspiritual', 'Spells.majorspiritual', 'Spells.wizard', 'Spells.sorcerer', 'Spells.ranger', 'Spells.paladin', 'Spells.empath', 'Spells.cleric', 'Spells.bard', 'Spells.minormental', 'Skills.magicitemuse', 'Skills.arancesymbols' ]
		if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
			if options[:target] and (options[:target].downcase == options[:caster].downcase)
				formula = @duration['self'][:duration].to_s.dup
			else
				formula = @duration['target'][:duration].dup || @duration['self'][:duration].to_s.dup
			end
			if options[:activator] =~ /^(#{activator_modifier.keys.join('|')})$/i
				if formula =~ can_haz_spell_ranks
					skills.each { |skill_name| formula.gsub!(skill_name, "(SpellRanks['#{options[:caster]}'].magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
					formula = "(#{formula})/2.0"
				elsif formula =~ /Skills\.(?:magicitemuse|arancesymbols)/
					skills.each { |skill_name| formula.gsub!(skill_name, "(SpellRanks['#{options[:caster]}'].magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
				end
			elsif options[:activator] =~ /^(invoke|scroll)$/i
				if formula =~ can_haz_spell_ranks
					skills.each { |skill_name| formula.gsub!(skill_name, "SpellRanks['#{options[:caster]}'].arcanesymbols.to_i") }
					formula = "(#{formula})/2.0"
				elsif formula =~ /Skills\.(?:magicitemuse|arancesymbols)/
					skills.each { |skill_name| formula.gsub!(skill_name, "SpellRanks['#{options[:caster]}'].arcanesymbols.to_i") }
				end
			else
				skills.each { |skill_name| formula.gsub!(skill_name, "SpellRanks[#{options[:caster].to_s.inspect}].#{skill_name.sub(/^(?:Spells|Skills)\./, '')}.to_i") }
			end
		else
			if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
				formula = @duration['target'][:duration].dup || @duration['self'][:duration].to_s.dup
			else
				formula = @duration['self'][:duration].to_s.dup
			end
			if options[:activator] =~ /^(#{activator_modifier.keys.join('|')})$/i
				if formula =~ can_haz_spell_ranks
					skills.each { |skill_name| formula.gsub!(skill_name, "(Skills.magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
					formula = "(#{formula})/2.0"
				elsif formula =~ /Skills\.(?:magicitemuse|arancesymbols)/
					skills.each { |skill_name| formula.gsub!(skill_name, "(Skills.magicitemuse * #{activator_modifier[options[:activator]]}).to_i") }
				end
			elsif options[:activator] =~ /^(invoke|scroll)$/i
				if formula =~ can_haz_spell_ranks
					skills.each { |skill_name| formula.gsub!(skill_name, "Skills.arcanesymbols.to_i") }
					formula = "(#{formula})/2.0"
				elsif formula =~ /Skills\.(?:magicitemuse|arancesymbols)/
					skills.each { |skill_name| formula.gsub!(skill_name, "Skills.arcanesymbols.to_i") }
				end
			end
		end
		UNTRUSTED_UNTAINT.call(formula)
		formula
	end
	def time_per(options={})
		formula = self.time_per_formula(options)
		if options[:line]
			line = options[:line]
		end
		if $SAFE < 3
			proc { $SAFE = 3; eval(formula) }.call.to_f
		else
			eval(formula).to_f
		end
	end
	def timeleft=(val)
		@timeleft = val
		@timestamp = Time.now
	end
	def timeleft
		if self.time_per_formula.to_s == 'Spellsong.timeleft'
			@timeleft = Spellsong.timeleft
		else
			@timeleft = @timeleft - ((Time.now - @timestamp) / 60.to_f)
			if @timeleft <= 0
				self.putdown
				return 0.to_f
			end
		end
		@timestamp = Time.now
		@timeleft
	end
	def minsleft
		self.timeleft
	end
	def secsleft
		self.timeleft * 60
	end
	def active=(val)
		@active = val
	end
	def active?
		(self.timeleft > 0) and @active
	end
	def stackable?(options={})
		if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
			if options[:target] and (options[:target].downcase == options[:caster].downcase)
				@duration['self'][:stackable]
			else
				if @duration['target'][:stackable].nil?
					@duration['self'][:stackable]
				else
					@duration['target'][:stackable]
				end
			end
		else
			if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
				if @duration['target'][:stackable].nil?
					@duration['self'][:stackable]
				else
					@duration['target'][:stackable]
				end
			else
				@duration['self'][:stackable]
			end
		end
	end
	def refreshable?(options={})
		if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
			if options[:target] and (options[:target].downcase == options[:caster].downcase)
				@duration['self'][:refreshable]
			else
				if @duration['target'][:refreshable].nil?
					@duration['self'][:refreshable]
				else
					@duration['target'][:refreshable]
				end
			end
		else
			if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
				if @duration['target'][:refreshable].nil?
					@duration['self'][:refreshable]
				else
					@duration['target'][:refreshable]
				end
			else
				@duration['self'][:refreshable]
			end
		end
	end
	def multicastable?(options={})
		if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
			if options[:target] and (options[:target].downcase == options[:caster].downcase)
				@duration['self'][:multicastable]
			else
				if @duration['target'][:multicastable].nil?
					@duration['self'][:multicastable]
				else
					@duration['target'][:multicastable]
				end
			end
		else
			if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
				if @duration['target'][:multicastable].nil?
					@duration['self'][:multicastable]
				else
					@duration['target'][:multicastable]
				end
			else
				@duration['self'][:multicastable]
			end
		end
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
			ranks = [ Spells.minorspiritual, XMLData.level ].min
		elsif circle_num == 2
			ranks = [ Spells.majorspiritual, XMLData.level ].min
		elsif circle_num == 3
			ranks = [ Spells.cleric, XMLData.level ].min
		elsif circle_num == 4
			ranks = [ Spells.minorelemental, XMLData.level ].min
		elsif circle_num == 5
			ranks = [ Spells.majorelemental, XMLData.level ].min
		elsif circle_num == 6
			ranks = [ Spells.ranger, XMLData.level ].min
		elsif circle_num == 7
			ranks = [ Spells.sorcerer, XMLData.level ].min
		elsif circle_num == 9
			ranks = [ Spells.wizard, XMLData.level ].min
		elsif circle_num == 10
			ranks = [ Spells.bard, XMLData.level ].min
		elsif circle_num == 11
			ranks = [ Spells.empath, XMLData.level ].min
		elsif circle_num == 12
			ranks = [ Spells.minormental, XMLData.level ].min
		elsif circle_num == 16
			ranks = [ Spells.paladin, XMLData.level ].min
		elsif (circle_num == 97) and (Society.status == 'Guardians of Sunfist')
			ranks = Society.rank
		elsif (circle_num == 98) and (Society.status == 'Order of Voln')
			ranks = Society.rank
		elsif (circle_num == 99) and (Society.status == 'Council of Light')
			ranks = Society.rank
		elsif (circle_num == 96)
			if CMan[@name].to_i > 0
				return true
			else
				return false
			end
		else
			return false
		end
		if (@num % 100) <= ranks
			return true
		else
			return false
		end
	end
	def available?(options={})
		if self.known?
			if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
				if options[:target] and (options[:target].downcase == options[:caster].downcase)
					true
				else
					@availability == 'all'
				end
			else
				if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
					@availability == 'all'
				else
					true
				end
			end
		else
			false
		end
	end
	def to_s
		@name.to_s
	end
	def max_duration(options={})
		if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
			if options[:target] and (options[:target].downcase == options[:caster].downcase)
				@duration['self'][:max_duration]
			else
				@duration['target'][:max_duration] || @duration['self'][:max_duration]
			end
		else
			if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
				@duration['target'][:max_duration] || @duration['self'][:max_duration]
			else
				@duration['self'][:max_duration]
			end
		end
	end
	def putup(options={})
		if stackable?(options)
			self.timeleft = [ self.timeleft + self.time_per(options), self.max_duration(options) ].min
		else
			self.timeleft = [ self.time_per(options), self.max_duration(options) ].min
		end
		@active = true
	end
	def putdown
		self.timeleft = 0
		@active = false
	end
	def remaining
		self.timeleft.as_time
	end
	def affordable?(options={})
		# fixme: deal with them dirty bards!
		release_options = options.dup
		release_options[:multicast] = nil
		if (self.mana_cost(options) > 0) and (  !checkmana(self.mana_cost(options)) or (Spell[515].active? and !checkmana(self.mana_cost(options) + [self.mana_cost(release_options)/4, 1].max))  )
			false 
		elsif (self.stamina_cost(options) > 0) and (Spell[9699].active? or not checkstamina(self.stamina_cost(options)))
			false
		elsif (self.spirit_cost(options) > 0) and not checkspirit(self.spirit_cost(options) + 1 + [ 9912, 9913, 9914, 9916, 9916, 9916 ].delete_if { |num| !Spell[num].active? }.length)
			false
		else
			true
		end
	end
	def Spell.lock_cast
		script = Script.self
		@@cast_lock.push(script)
		until (@@cast_lock.first == script) or @@cast_lock.empty?
			sleep "0.1".to_f
			Script.self # allows this loop to be paused
			@@cast_lock.delete_if { |s| s.paused or not (Script.running + Script.hidden).include?(s) }
		end
	end
	def Spell.unlock_cast
		@@cast_lock.delete(Script.self)
	end
	def cast(target=nil, results_of_interest=nil)
		script = Script.self
		if @type.nil?
			echo "cast: spell missing type (#{@name})"
			sleep "0.1".to_f
			return false
		end
		unless (self.mana_cost <= 0) or checkmana(self.mana_cost)
			echo 'cast: not enough mana'
			sleep "0.1".to_f
			return false
		end
		unless (self.spirit_cost > 0) or checkspirit(self.spirit_cost + 1 + [ 9912, 9913, 9914, 9916, 9916, 9916 ].delete_if { |num| !Spell[num].active? }.length)
			echo 'cast: not enough spirit'
			sleep "0.1".to_f
			return false
		end
		unless (self.stamina_cost <= 0) or checkstamina(self.stamina_cost)
			echo 'cast: not enough stamina'
			sleep "0.1".to_f
			return false
		end
		begin
			save_want_downstream = script.want_downstream
			save_want_downstream_xml = script.want_downstream_xml
			script.want_downstream = true
			script.want_downstream_xml = false
			@@cast_lock.push(script)
			until (@@cast_lock.first == script) or @@cast_lock.empty?
				sleep "0.1".to_f
				Script.self # allows this loop to be paused
				@@cast_lock.delete_if { |s| s.paused or not (Script.running + Script.hidden).include?(s) }
			end
			unless (self.mana_cost <= 0) or checkmana(self.mana_cost)
				echo 'cast: not enough mana'
				sleep "0.1".to_f
				return false
			end
			unless (self.spirit_cost > 0) or checkspirit(self.spirit_cost + 1 + [ 9912, 9913, 9914, 9916, 9916, 9916 ].delete_if { |num| !Spell[num].active? }.length)
				echo 'cast: not enough spirit'
				sleep "0.1".to_f
				return false
			end
			unless (self.stamina_cost <= 0) or checkstamina(self.stamina_cost)
				echo 'cast: not enough stamina'
				sleep "0.1".to_f
				return false
			end
			if @cast_proc
				waitrt?
				waitcastrt?
				unless (self.mana_cost <= 0) or checkmana(self.mana_cost)
					echo 'cast: not enough mana'
					sleep "0.1".to_f
					return false
				end
				unless (self.spirit_cost > 0) or checkspirit(self.spirit_cost + 1 + [ 9912, 9913, 9914, 9916, 9916, 9916 ].delete_if { |num| !Spell[num].active? }.length)
					echo 'cast: not enough spirit'
					sleep "0.1".to_f
					return false
				end
				unless (self.stamina_cost <= 0) or checkstamina(self.stamina_cost)
					echo 'cast: not enough stamina'
					sleep "0.1".to_f
					return false
				end
				begin
					if $SAFE < 3
						proc { $SAFE = 3; eval(@cast_proc) }.call
					else
						eval(@cast_proc)
					end
				rescue
					echo "cast: error: #{$!}"
					respond $!.backtrace[0..2]
					return false
				end
			else
				if @channel
					cast_cmd = 'channel'
				else
					cast_cmd = 'cast'
				end
				if (target.nil? or target.to_s.empty?) and (@type =~ /attack/i) and not [410,435,525,912,909,609].include?(@num)
					cast_cmd += ' target'
				elsif target.class == GameObj
					cast_cmd += " ##{target.id}"
				elsif target.class == Fixnum
					cast_cmd += " ##{target}"
				else
					cast_cmd += " #{target}"
				end
				cast_result = nil
				loop {
					waitrt?
					unless checkprep == @name
						waitcastrt? unless Spell[515].active?
						unless checkprep == 'None'
							dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
							unless (self.mana_cost <= 0) or checkmana(self.mana_cost)
								echo 'cast: not enough mana'
								sleep "0.1".to_f
								return false
							end
							unless (self.spirit_cost <= 0) or checkspirit(self.spirit_cost + 1 + (if checkspell(9912) then 1 else 0 end) + (if checkspell(9913) then 1 else 0 end) + (if checkspell(9914) then 1 else 0 end) + (if checkspell(9916) then 5 else 0 end))
								echo 'cast: not enough spirit'
								sleep "0.1".to_f
								return false
							end
							unless (self.stamina_cost <= 0) or checkstamina(self.stamina_cost)
								echo 'cast: not enough stamina'
								sleep "0.1".to_f
								return false
							end
						end
						loop {
							waitrt?
							waitcastrt?
							prepare_result = dothistimeout "prepare #{@num}", 8, /^You already have a spell readied!  You must RELEASE it if you wish to prepare another!$|^Your spell(?:song)? is ready\.|^You can't think clearly enough to prepare a spell!$|^You are concentrating too intently .*?to prepare a spell\.$|^You are too injured to make that dextrous of a movement|^The searing pain in your throat makes that impossible|^But you don't have any mana!\.$|^You can't make that dextrous of a move!$|^As you begin to prepare the spell the wind blows small objects at you thwarting your attempt\.$|^You do not know that spell!$/
							if prepare_result =~ /^Your spell(?:song)? is ready\./
								break
							elsif prepare_result == 'You already have a spell readied!  You must RELEASE it if you wish to prepare another!'
								dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
								unless (self.mana_cost <= 0) or checkmana(self.mana_cost)
									echo 'cast: not enough mana'
									sleep "0.1".to_f
									return false
								end
							elsif prepare_result =~ /^You can't think clearly enough to prepare a spell!$|^You are concentrating too intently .*?to prepare a spell\.$|^You are too injured to make that dextrous of a movement|^The searing pain in your throat makes that impossible|^But you don't have any mana!\.$|^You can't make that dextrous of a move!$|^As you begin to prepare the spell the wind blows small objects at you thwarting your attempt\.$|^You do not know that spell!$/
								sleep "0.1".to_f
								return prepare_result
							end
						}
					end
					if @stance and checkstance != 'offensive'
						put 'stance offensive'
						# dothistimeout 'stance offensive', 5, /^You (?:are now in|move into) an? offensive stance|^You are unable to change your stance\.$/
					end
					if results_of_interest.class == Regexp
						results_regex = /^(?:Cast|Sing) Roundtime [0-9]+ Seconds\.$|^Cast at what\?$|^But you don't have any mana!$|^\[Spell Hindrance for|^You don't have a spell prepared!$|keeps? the spell from working\.|^Be at peace my child, there is no need for spells of war in here\.$|Spells of War cannot be cast|^As you focus on your magic, your vision swims with a swirling haze of crimson\.$|^Your magic fizzles ineffectually\.$|^All you manage to do is cough up some blood\.$|^And give yourself away!  Never!$|^You are unable to do that right now\.$|^You feel a sudden rush of power as you absorb [0-9]+ mana!$|^You are unable to drain it!$|leaving you casting at nothing but thin air!$|^You don't seem to be able to move to do that\.$|^Provoking a GameMaster is not such a good idea\.$|^You can't think clearly enough to prepare a spell!$|#{results_of_interest.to_s}/
					else
						results_regex = /^(?:Cast|Sing) Roundtime [0-9]+ Seconds\.$|^Cast at what\?$|^But you don't have any mana!$|^\[Spell Hindrance for|^You don't have a spell prepared!$|keeps? the spell from working\.|^Be at peace my child, there is no need for spells of war in here\.$|Spells of War cannot be cast|^As you focus on your magic, your vision swims with a swirling haze of crimson\.$|^Your magic fizzles ineffectually\.$|^All you manage to do is cough up some blood\.$|^And give yourself away!  Never!$|^You are unable to do that right now\.$|^You feel a sudden rush of power as you absorb [0-9]+ mana!$|^You are unable to drain it!$|leaving you casting at nothing but thin air!$|^You don't seem to be able to move to do that\.$|^Provoking a GameMaster is not such a good idea\.$|^You can't think clearly enough to prepare a spell!$/
					end
					cast_result = dothistimeout cast_cmd, 5, results_regex
					if cast_result == "You don't seem to be able to move to do that."
						100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep "0.1".to_f }
						cast_result = dothistimeout cast_cmd, 5, results_regex
					end
					if @stance and checkstance !~ /^guarded$|^defensive$/
						dothistimeout 'stance guarded', 5, /^You (?:are now in|move into) an? \w+ stance|^You are unable to change your stance\.$/
					end
					if cast_result =~ /^Cast at what\?$|^Be at peace my child, there is no need for spells of war in here\.$|^Provoking a GameMaster is not such a good idea\.$/
						dothistimeout 'release', 5, /^You feel the magic of your spell rush away from you\.$|^You don't have a prepared spell to release!$/
					end
					break unless (@circle.to_i == 10) and (cast_result =~ /^\[Spell Hindrance for/)
				}
				cast_result
			end
		ensure
			script.want_downstream = save_want_downstream
			script.want_downstream_xml = save_want_downstream_xml
			@@cast_lock.delete(script)
		end
	end
	def _bonus
		@bonus.dup
	end
	def _cost
		@cost.dup
	end
	def method_missing(*args)
		if @@bonus_list.include?(args[0].to_s.gsub('_', '-'))
			if @bonus[args[0].to_s.gsub('_', '-')]
				if $SAFE < 3
					proc { $SAFE = 3; eval(@bonus[args[0].to_s.gsub('_', '-')]) }.call.to_i
				else
					eval(@bonus[args[0].to_s.gsub('_', '-')]).to_i
				end
			else
				0
			end
		elsif @@bonus_list.include?(args[0].to_s.sub(/_formula$/, '').gsub('_', '-'))
			@bonus[args[0].to_s.sub(/_formula$/, '').gsub('_', '-')].dup
		elsif (args[0].to_s =~ /_cost(?:_formula)?$/) and @@cost_list.include?(args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, ''))
			options = args[1].to_hash
			if options[:caster] and (options[:caster] !~ /^(?:self|#{XMLData.name})$/i)
				if options[:target] and (options[:target].downcase == options[:caster].downcase)
					formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['self'].dup
				else
					formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['target'].dup || @cost[args[0].to_s.gsub('_', '-')]['self'].dup
				end
				skills = { 'Spells.minorelemental' => "SpellRanks['#{options[:caster]}'].minorelemental.to_i", 'Spells.majorelemental' => "SpellRanks['#{options[:caster]}'].majorelemental.to_i", 'Spells.minorspiritual' => "SpellRanks['#{options[:caster]}'].minorspiritual.to_i", 'Spells.majorspiritual' => "SpellRanks['#{options[:caster]}'].majorspiritual.to_i", 'Spells.wizard' => "SpellRanks['#{options[:caster]}'].wizard.to_i", 'Spells.sorcerer' => "SpellRanks['#{options[:caster]}'].sorcerer.to_i", 'Spells.ranger' => "SpellRanks['#{options[:caster]}'].ranger.to_i", 'Spells.paladin' => "SpellRanks['#{options[:caster]}'].paladin.to_i", 'Spells.empath' => "SpellRanks['#{options[:caster]}'].empath.to_i", 'Spells.cleric' => "SpellRanks['#{options[:caster]}'].cleric.to_i", 'Spells.bard' => "SpellRanks['#{options[:caster]}'].bard.to_i", 'Stats.level' => '100' }
				skills.each_pair { |a, b| formula.gsub!(a, b) }
			else
				if options[:target] and (options[:target] !~ /^(?:self|#{XMLData.name})$/i)
					formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['target'].dup || @cost[args[0].to_s.gsub('_', '-')]['self'].dup
				else
					formula = @cost[args[0].to_s.sub(/_formula$/, '').sub(/_cost$/, '')]['self'].dup
				end
			end
			if options[:multicast].to_i > 1
				formula = "(#{formula})*#{options[:multicast].to_i}"
			end
			if args[0].to_s =~ /_formula$/
				formula.dup
			else
				if formula
					if $SAFE < 3
						formula.untaint
						proc { $SAFE = 3; eval(formula) }.call.to_i
					else
						UNTRUSTED_UNTAINT.call(formula)
						eval(formula).to_i
					end
				else
					0
				end
			end
		else
			raise NoMethodError
		end
	end
	def circle_name
		Spells.get_circle_name(@circle)
	end
	def clear_on_death
		!@persist_on_death
	end
	# for backwards compatiblity
	def duration;      self.time_per_formula;            end
	def cost;          self.mana_cost_formula    || '0'; end
	def manaCost;      self.mana_cost_formula    || '0'; end
	def spiritCost;    self.spirit_cost_formula  || '0'; end
	def staminaCost;   self.stamina_cost_formula || '0'; end
	def boltAS;        self.bolt_as_formula;             end
	def physicalAS;    self.physical_as_formula;         end
	def boltDS;        self.bolt_ds_formula;             end
	def physicalDS;    self.physical_ds_formula;         end
	def elementalCS;   self.elemental_cs_formula;        end
	def mentalCS;      self.mental_cs_formula;           end
	def spiritCS;      self.spirit_cs_formula;           end
	def sorcererCS;    self.sorcerer_cs_formula;         end
	def elementalTD;   self.elemental_td_formula;        end
	def mentalTD;      self.mental_td_formula;           end
	def spiritTD;      self.spirit_td_formula;           end
	def sorcererTD;    self.sorcerer_td_formula;         end
	def castProc;      @cast_proc;                       end
	def stacks;        self.stackable?                   end
	def command;       nil;                              end
	def circlename;    self.circle_name;                 end
	def selfonly;      @availability != 'all';           end
end

class CMan
	@@bearhug            ||= 0
	@@berserk            ||= 0
	@@block_mastery      ||= 0
	@@bull_rush          ||= 0
	@@charge             ||= 0
	@@cheapshots         ||= 0
	@@combat_focus       ||= 0
	@@combat_mastery     ||= 0
	@@combat_mobility    ||= 0
	@@combat_movement    ||= 0
	@@combat_toughness   ||= 0
	@@coup_de_grace      ||= 0
	@@crowd_press        ||= 0
	@@cunning_defense    ||= 0
	@@cutthroat          ||= 0
	@@dirtkick           ||= 0
	@@disarm_weapon      ||= 0
	@@divert             ||= 0
	@@dust_shroud        ||= 0
	@@evade_mastery      ||= 0
	@@feint              ||= 0
	@@garrote            ||= 0
	@@groin_kick         ||= 0
	@@hamstring          ||= 0
	@@haymaker           ||= 0
	@@headbutt           ||= 0
	@@mighty_blow        ||= 0
	@@multi_fire         ||= 0
	@@parry_mastery      ||= 0
	@@precision          ||= 0
	@@quickstrike        ||= 0
	@@shadow_mastery     ||= 0
	@@shield_bash        ||= 0
	@@shield_charge      ||= 0
	@@side_by_side       ||= 0
	@@silent_strike      ||= 0
	@@specialization_i   ||= 0
	@@specialization_ii  ||= 0
	@@specialization_iii ||= 0
	@@spin_attack        ||= 0
	@@staggering_blow    ||= 0
	@@stun_maneuvers     ||= 0
	@@subdual_strike     ||= 0
	@@subdue             ||= 0
	@@sucker_punch       ||= 0
	@@sunder_shield      ||= 0
	@@surge_of_strength  ||= 0
	@@sweep              ||= 0
	@@tackle             ||= 0
	@@trip               ||= 0
	@@truehand           ||= 0
	@@twin_hammerfists   ||= 0
	@@weapon_bonding     ||= 0
	@@vanish             ||= 0
	@@duck_and_weave     ||= 0
	@@slipery_mind       ||= 0
	@@predators_eye      ||= 0
	@@rolling_krynch_stance  ||= 0
	@@stance_of_the_mongoose ||= 0
	@@slippery_mind          ||= 0
	@@flurry_of_blows        ||= 0
	@@inner_harmony          ||= 0

	def CMan.bearhug;            @@bearhug;            end
	def CMan.berserk;            @@berserk;            end
	def CMan.block_mastery;      @@block_mastery;      end
	def CMan.bull_rush;          @@bull_rush;          end
	def CMan.charge;             @@charge;             end
	def CMan.cheapshots;         @@cheapshots;         end
	def CMan.combat_focus;       @@combat_focus;       end
	def CMan.combat_mastery;     @@combat_mastery;     end
	def CMan.combat_mobility;    @@combat_mobility;    end
	def CMan.combat_movement;    @@combat_movement;    end
	def CMan.combat_toughness;   @@combat_toughness;   end
	def CMan.coup_de_grace;      @@coup_de_grace;      end
	def CMan.crowd_press;        @@crowd_press;        end
	def CMan.cunning_defense;    @@cunning_defense;    end
	def CMan.cutthroat;          @@cutthroat;          end
	def CMan.dirtkick;           @@dirtkick;           end
	def CMan.disarm_weapon;      @@disarm_weapon;      end
	def CMan.divert;             @@divert;             end
	def CMan.dust_shroud;        @@dust_shroud;        end
	def CMan.evade_mastery;      @@evade_mastery;      end
	def CMan.feint;              @@feint;              end
	def CMan.garrote;            @@garrote;            end
	def CMan.groin_kick;         @@groin_kick;         end
	def CMan.hamstring;          @@hamstring;          end
	def CMan.haymaker;           @@haymaker;           end
	def CMan.headbutt;           @@headbutt;           end
	def CMan.mighty_blow;        @@mighty_blow;        end
	def CMan.multi_fire;         @@multi_fire;         end
	def CMan.parry_mastery;      @@parry_mastery;      end
	def CMan.precision;          @@precision;          end
	def CMan.quickstrike;        @@quickstrike;        end
	def CMan.shadow_mastery;     @@shadow_mastery;     end
	def CMan.shield_bash;        @@shield_bash;        end
	def CMan.shield_charge;      @@shield_charge;      end
	def CMan.side_by_side;       @@side_by_side;       end
	def CMan.silent_strike;      @@silent_strike;      end
	def CMan.specialization_i;   @@specialization_i;   end
	def CMan.specialization_ii;  @@specialization_ii;  end
	def CMan.specialization_iii; @@specialization_iii; end
	def CMan.spin_attack;        @@spin_attack;        end
	def CMan.staggering_blow;    @@staggering_blow;    end
	def CMan.stun_maneuvers;     @@stun_maneuvers;     end
	def CMan.subdual_strike;     @@subdual_strike;     end
	def CMan.subdue;             @@subdue;             end
	def CMan.sucker_punch;       @@sucker_punch;       end
	def CMan.sunder_shield;      @@sunder_shield;      end
	def CMan.surge_of_strength;  @@surge_of_strength;  end
	def CMan.sweep;              @@sweep;              end
	def CMan.tackle;             @@tackle;             end
	def CMan.trip;               @@trip;               end
	def CMan.truehand;           @@truehand;           end
	def CMan.twin_hammerfists;   @@twin_hammerfists;   end
	def CMan.weapon_bonding;     @@weapon_bonding;     end
	def CMan.vanish;             @@vanish;             end
	def CMan.duck_and_weave;     @@duck_and_weave;     end
	def CMan.slipery_mind;       @@slipery_mind;       end
	def CMan.predators_eye;      @@predators_eye;      end

	def CMan.bearhug=(val);            @@bearhug=val;            end
	def CMan.berserk=(val);            @@berserk=val;            end
	def CMan.block_mastery=(val);      @@block_mastery=val;      end
	def CMan.bull_rush=(val);          @@bull_rush=val;          end
	def CMan.charge=(val);             @@charge=val;             end
	def CMan.cheapshots=(val);         @@cheapshots=val;         end
	def CMan.combat_focus=(val);       @@combat_focus=val;       end
	def CMan.combat_mastery=(val);     @@combat_mastery=val;     end
	def CMan.combat_mobility=(val);    @@combat_mobility=val;    end
	def CMan.combat_movement=(val);    @@combat_movement=val;    end
	def CMan.combat_toughness=(val);   @@combat_toughness=val;   end
	def CMan.coup_de_grace=(val);      @@coup_de_grace=val;      end
	def CMan.crowd_press=(val);        @@crowd_press=val;        end
	def CMan.cunning_defense=(val);    @@cunning_defense=val;    end
	def CMan.cutthroat=(val);          @@cutthroat=val;          end
	def CMan.dirtkick=(val);           @@dirtkick=val;           end
	def CMan.disarm_weapon=(val);      @@disarm_weapon=val;      end
	def CMan.divert=(val);             @@divert=val;             end
	def CMan.dust_shroud=(val);        @@dust_shroud=val;        end
	def CMan.evade_mastery=(val);      @@evade_mastery=val;      end
	def CMan.feint=(val);              @@feint=val;              end
	def CMan.garrote=(val);            @@garrote=val;            end
	def CMan.groin_kick=(val);         @@groin_kick=val;         end
	def CMan.hamstring=(val);          @@hamstring=val;          end
	def CMan.haymaker=(val);           @@haymaker=val;           end
	def CMan.headbutt=(val);           @@headbutt=val;           end
	def CMan.mighty_blow=(val);        @@mighty_blow=val;        end
	def CMan.multi_fire=(val);         @@multi_fire=val;         end
	def CMan.parry_mastery=(val);      @@parry_mastery=val;      end
	def CMan.precision=(val);          @@precision=val;          end
	def CMan.quickstrike=(val);        @@quickstrike=val;        end
	def CMan.shadow_mastery=(val);     @@shadow_mastery=val;     end
	def CMan.shield_bash=(val);        @@shield_bash=val;        end
	def CMan.shield_charge=(val);      @@shield_charge=val;      end
	def CMan.side_by_side=(val);       @@side_by_side=val;       end
	def CMan.silent_strike=(val);      @@silent_strike=val;      end
	def CMan.specialization_i=(val);   @@specialization_i=val;   end
	def CMan.specialization_ii=(val);  @@specialization_ii=val;  end
	def CMan.specialization_iii=(val); @@specialization_iii=val; end
	def CMan.spin_attack=(val);        @@spin_attack=val;        end
	def CMan.staggering_blow=(val);    @@staggering_blow=val;    end
	def CMan.stun_maneuvers=(val);     @@stun_maneuvers=val;     end
	def CMan.subdual_strike=(val);     @@subdual_strike=val;     end
	def CMan.subdue=(val);             @@subdue=val;             end
	def CMan.sucker_punch=(val);       @@sucker_punch=val;       end
	def CMan.sunder_shield=(val);      @@sunder_shield=val;      end
	def CMan.surge_of_strength=(val);  @@surge_of_strength=val;  end
	def CMan.sweep=(val);              @@sweep=val;              end
	def CMan.tackle=(val);             @@tackle=val;             end
	def CMan.trip=(val);               @@trip=val;               end
	def CMan.truehand=(val);           @@truehand=val;           end
	def CMan.twin_hammerfists=(val);   @@twin_hammerfists=val;   end
	def CMan.weapon_bonding=(val);     @@weapon_bonding=val;     end
	def CMan.vanish=(val);             @@vanish=val;             end
	def CMan.duck_and_weave=(val);     @@duck_and_weave=val;     end
	def CMan.slipery_mind=(val);       @@slipery_mind=val;       end
	def CMan.predators_eye=(val);      @@predators_eye=val;      end

	def CMan.method_missing(arg1, arg2=nil)
		nil
	end
	def CMan.[](name)
		CMan.send(name.gsub(/[\s\-]/, '_').gsub("'", "").downcase)
	end
	def CMan.[]=(name,val)
		CMan.send("#{name.gsub(/[\s\-]/, '_').gsub("'", "").downcase}=", val.to_i)
	end
end

class Stats
	@@race ||= 'unknown'
	@@prof ||= 'unknown'
	@@gender ||= 'unknown'
	@@age ||= 0
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
	def Stats.race;         @@race;       end
	def Stats.race=(val);   @@race=val;   end
	def Stats.prof;         @@prof;       end
	def Stats.prof=(val);   @@prof=val;   end
	def Stats.gender;       @@gender;     end
	def Stats.gender=(val); @@gender=val; end
	def Stats.age;          @@age;        end
	def Stats.age=(val);    @@age=val;    end
	def Stats.level;        @@level;      end
	def Stats.level=(val);  @@level=val;  end
	def Stats.str;          @@str;        end
	def Stats.str=(val);    @@str=val;    end
	def Stats.con;          @@con;        end
	def Stats.con=(val);    @@con=val;    end
	def Stats.dex;          @@dex;        end
	def Stats.dex=(val);    @@dex=val;    end
	def Stats.agi;          @@agi;        end
	def Stats.agi=(val);    @@agi=val;    end
	def Stats.dis;          @@dis;        end
	def Stats.dis=(val);    @@dis=val;    end
	def Stats.aur;          @@aur;        end
	def Stats.aur=(val);    @@aur=val;    end
	def Stats.log;          @@log;        end
	def Stats.log=(val);    @@log=val;    end
	def Stats.int;          @@int;        end
	def Stats.int=(val);    @@int=val;    end
	def Stats.wis;          @@wis;        end
	def Stats.wis=(val);    @@wis=val;    end
	def Stats.inf;          @@inf;        end
	def Stats.inf=(val);    @@inf=val;    end
	def Stats.exp
		if XMLData.next_level_text =~ /until next level/
			exp_threshold = [ 2500, 5000, 10000, 17500, 27500, 40000, 55000, 72500, 92500, 115000, 140000, 167000, 197500, 230000, 265000, 302000, 341000, 382000, 425000, 470000, 517000, 566000, 617000, 670000, 725000, 781500, 839500, 899000, 960000, 1022500, 1086500, 1152000, 1219000, 1287500, 1357500, 1429000, 1502000, 1576500, 1652500, 1730000, 1808500, 1888000, 1968500, 2050000, 2132500, 2216000, 2300500, 2386000, 2472500, 2560000, 2648000, 2736500, 2825500, 2915000, 3005000, 3095500, 3186500, 3278000, 3370000, 3462500, 3555500, 3649000, 3743000, 3837500, 3932500, 4028000, 4124000, 4220500, 4317500, 4415000, 4513000, 4611500, 4710500, 4810000, 4910000, 5010500, 5111500, 5213000, 5315000, 5417500, 5520500, 5624000, 5728000, 5832500, 5937500, 6043000, 6149000, 6255500, 6362500, 6470000, 6578000, 6686500, 6795500, 6905000, 7015000, 7125500, 7236500, 7348000, 7460000, 7572500 ]
			exp_threshold[XMLData.level] - XMLData.next_level_text.slice(/[0-9]+/).to_i
		else
			XMLData.next_level_text.slice(/[0-9]+/).to_i
		end
	end
	def Stats.exp=(val);    nil;    end
	def Stats.serialize
		[@@race,@@prof,@@gender,@@age,Stats.exp,@@level,@@str,@@con,@@dex,@@agi,@@dis,@@aur,@@log,@@int,@@wis,@@inf]
	end
	def Stats.load_serialized=(array)
		@@race,@@prof,@@gender,@@age = array[0..3]
		@@level,@@str,@@con,@@dex,@@agi,@@dis,@@aur,@@log,@@int,@@wis,@@inf = array[5..15]
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
		@@gift_start + 594000
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
	def Wounds.leftEye;   fix_injury_mode; XMLData.injuries['leftEye']['wound'];   end
	def Wounds.leye;      fix_injury_mode; XMLData.injuries['leftEye']['wound'];   end
	def Wounds.rightEye;  fix_injury_mode; XMLData.injuries['rightEye']['wound'];  end
	def Wounds.reye;      fix_injury_mode; XMLData.injuries['rightEye']['wound'];  end
	def Wounds.head;      fix_injury_mode; XMLData.injuries['head']['wound'];      end
	def Wounds.neck;      fix_injury_mode; XMLData.injuries['neck']['wound'];      end
	def Wounds.back;      fix_injury_mode; XMLData.injuries['back']['wound'];      end
	def Wounds.chest;     fix_injury_mode; XMLData.injuries['chest']['wound'];     end
	def Wounds.abdomen;   fix_injury_mode; XMLData.injuries['abdomen']['wound'];   end
	def Wounds.abs;       fix_injury_mode; XMLData.injuries['abdomen']['wound'];   end
	def Wounds.leftArm;   fix_injury_mode; XMLData.injuries['leftArm']['wound'];   end
	def Wounds.larm;      fix_injury_mode; XMLData.injuries['leftArm']['wound'];   end
	def Wounds.rightArm;  fix_injury_mode; XMLData.injuries['rightArm']['wound'];  end
	def Wounds.rarm;      fix_injury_mode; XMLData.injuries['rightArm']['wound'];  end
	def Wounds.rightHand; fix_injury_mode; XMLData.injuries['rightHand']['wound']; end
	def Wounds.rhand;     fix_injury_mode; XMLData.injuries['rightHand']['wound']; end
	def Wounds.leftHand;  fix_injury_mode; XMLData.injuries['leftHand']['wound'];  end
	def Wounds.lhand;     fix_injury_mode; XMLData.injuries['leftHand']['wound'];  end
	def Wounds.leftLeg;   fix_injury_mode; XMLData.injuries['leftLeg']['wound'];   end
	def Wounds.lleg;      fix_injury_mode; XMLData.injuries['leftLeg']['wound'];   end
	def Wounds.rightLeg;  fix_injury_mode; XMLData.injuries['rightLeg']['wound'];  end
	def Wounds.rleg;      fix_injury_mode; XMLData.injuries['rightLeg']['wound'];  end
	def Wounds.leftFoot;  fix_injury_mode; XMLData.injuries['leftFoot']['wound'];  end
	def Wounds.rightFoot; fix_injury_mode; XMLData.injuries['rightFoot']['wound']; end
	def Wounds.nsys;      fix_injury_mode; XMLData.injuries['nsys']['wound'];      end
	def Wounds.nerves;    fix_injury_mode; XMLData.injuries['nsys']['wound'];      end
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
	def Wounds.method_missing(arg=nil)
		echo "Wounds: Invalid area, try one of these: arms, limbs, torso, #{XMLData.injuries.keys.join(', ')}"
		nil
	end
end

class Scars
	def Scars.leftEye;   fix_injury_mode; XMLData.injuries['leftEye']['scar'];   end
	def Scars.leye;      fix_injury_mode; XMLData.injuries['leftEye']['scar'];   end
	def Scars.rightEye;  fix_injury_mode; XMLData.injuries['rightEye']['scar'];  end
	def Scars.reye;      fix_injury_mode; XMLData.injuries['rightEye']['scar'];  end
	def Scars.head;      fix_injury_mode; XMLData.injuries['head']['scar'];      end
	def Scars.neck;      fix_injury_mode; XMLData.injuries['neck']['scar'];      end
	def Scars.back;      fix_injury_mode; XMLData.injuries['back']['scar'];      end
	def Scars.chest;     fix_injury_mode; XMLData.injuries['chest']['scar'];     end
	def Scars.abdomen;   fix_injury_mode; XMLData.injuries['abdomen']['scar'];   end
	def Scars.abs;       fix_injury_mode; XMLData.injuries['abdomen']['scar'];   end
	def Scars.leftArm;   fix_injury_mode; XMLData.injuries['leftArm']['scar'];   end
	def Scars.larm;      fix_injury_mode; XMLData.injuries['leftArm']['scar'];   end
	def Scars.rightArm;  fix_injury_mode; XMLData.injuries['rightArm']['scar'];  end
	def Scars.rarm;      fix_injury_mode; XMLData.injuries['rightArm']['scar'];  end
	def Scars.rightHand; fix_injury_mode; XMLData.injuries['rightHand']['scar']; end
	def Scars.rhand;     fix_injury_mode; XMLData.injuries['rightHand']['scar']; end
	def Scars.leftHand;  fix_injury_mode; XMLData.injuries['leftHand']['scar'];  end
	def Scars.lhand;     fix_injury_mode; XMLData.injuries['leftHand']['scar'];  end
	def Scars.leftLeg;   fix_injury_mode; XMLData.injuries['leftLeg']['scar'];   end
	def Scars.lleg;      fix_injury_mode; XMLData.injuries['leftLeg']['scar'];   end
	def Scars.rightLeg;  fix_injury_mode; XMLData.injuries['rightLeg']['scar'];  end
	def Scars.rleg;      fix_injury_mode; XMLData.injuries['rightLeg']['scar'];  end
	def Scars.leftFoot;  fix_injury_mode; XMLData.injuries['leftFoot']['scar'];  end
	def Scars.rightFoot; fix_injury_mode; XMLData.injuries['rightFoot']['scar']; end
	def Scars.nsys;      fix_injury_mode; XMLData.injuries['nsys']['scar'];      end
	def Scars.nerves;    fix_injury_mode; XMLData.injuries['nsys']['scar'];      end
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
	def Scars.method_missing(arg=nil)
		echo "Scars: Invalid area, try one of these: arms, limbs, torso, #{XMLData.injuries.keys.join(', ')}"
		nil
	end
end

class Watchfor
	def initialize(line, theproc=nil, &block)
		return nil unless script = Script.self
		if line.class == String
			line = Regexp.new(Regexp.escape(line))
		elsif line.class != Regexp
			echo 'watchfor: no string or regexp given'
			return nil
		end
		if block.nil?
			if theproc.respond_to? :call
				block = theproc
			else
				echo 'watchfor: no block or proc given'
				return nil
			end
		end
		script.watchfor[line] = block
	end
	def Watchfor.clear
		script.watchfor = Hash.new
	end
end

class GameObj
	@@loot          ||= Array.new
	@@npcs          ||= Array.new
	@@npc_status    ||= Hash.new
	@@pcs           ||= Array.new
	@@pc_status     ||= Hash.new
	@@inv           ||= Array.new
	@@contents      ||= Hash.new
	@@right_hand    ||= nil
	@@left_hand     ||= nil
	@@room_desc     ||= Array.new
	@@fam_loot      ||= Array.new
	@@fam_npcs      ||= Array.new
	@@fam_pcs       ||= Array.new
	@@fam_room_desc ||= Array.new
	@@type_data     ||= Hash.new
	@@sellable_data ||= Hash.new

	attr_reader :id
	attr_accessor :noun, :name, :before_name, :after_name
	def initialize(id, noun, name, before=nil, after=nil)
		@id = id
		@noun = noun
		@noun = 'lapis' if @noun == 'lapis lazuli'
		@noun = 'hammer' if @noun == "Hammer of Kai"
		@noun = 'mother-of-pearl' if (@noun == 'pearl') and (@name =~ /mother\-of\-pearl/)
		@name = name
		@before_name = before
		@after_name = after
	end
	def type
		GameObj.load_data if @@type_data.empty?
		list = @@type_data.keys.find_all { |t| (@name =~ @@type_data[t][:name] or @noun =~ @@type_data[t][:noun]) and (@@type_data[t][:exclude].nil? or @name !~ @@type_data[t][:exclude]) }
		if list.empty?
			nil
		else
			list.join(',')
		end
	end
	def sellable
		GameObj.load_data if @@sellable_data.empty?
		list = @@sellable_data.keys.find_all { |t| (@name =~ @@sellable_data[t][:name] or @noun =~ @@sellable_data[t][:noun]) and (@@sellable_data[t][:exclude].nil? or @name !~ @@sellable_data[t][:exclude]) }
		if list.empty?
			nil
		else
			list.join(',')
		end
	end
	def status
		if @@npc_status.keys.include?(@id)
			@@npc_status[@id]
		elsif @@pc_status.keys.include?(@id)
			@@pc_status[@id]
		elsif @@loot.find { |obj| obj.id == @id } or @@inv.find { |obj| obj.id == @id } or @@room_desc.find { |obj| obj.id == @id } or @@fam_loot.find { |obj| obj.id == @id } or @@fam_npcs.find { |obj| obj.id == @id } or @@fam_pcs.find { |obj| obj.id == @id } or @@fam_room_desc.find { |obj| obj.id == @id } or (@@right_hand.id == @id) or (@@left_hand.id == @id) or @@contents.values.find { |list| list.find { |obj| obj.id == @id  } }
			nil
		else
			'gone'
		end
	end
	def status=(val)
		if @@npcs.any? { |npc| npc.id == @id }
			@@npc_status[@id] = val
		elsif @@pcs.any? { |pc| pc.id == @id }
			@@pc_status[@id] = val
		else
			nil
		end
	end
	def to_s
		@noun
	end
	def empty?
		false
	end
	def contents
		@@contents[@id].dup
	end
	def GameObj.[](val)
		if val.class == String
			if val =~ /^\-?[0-9]+$/
				obj = @@inv.find { |o| o.id == val } || @@loot.find { |o| o.id == val } || @@npcs.find { |o| o.id == val } || @@pcs.find { |o| o.id == val } || [ @@right_hand, @@left_hand ].find { |o| o.id == val } || @@room_desc.find { |o| o.id == val }
			elsif val.split(' ').length == 1
				obj = @@inv.find { |o| o.noun == val } || @@loot.find { |o| o.noun == val } || @@npcs.find { |o| o.noun == val } || @@pcs.find { |o| o.noun == val } || [ @@right_hand, @@left_hand ].find { |o| o.noun == val } || @@room_desc.find { |o| o.noun == val }
			else
				obj = @@inv.find { |o| o.name == val } || @@loot.find { |o| o.name == val } || @@npcs.find { |o| o.name == val } || @@pcs.find { |o| o.name == val } || [ @@right_hand, @@left_hand ].find { |o| o.name == val } || @@room_desc.find { |o| o.name == val } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || [ @@right_hand, @@left_hand ].find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val.strip)}$/i } || @@inv.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@loot.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@npcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@pcs.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || [ @@right_hand, @@left_hand ].find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i } || @@room_desc.find { |o| o.name =~ /\b#{Regexp.escape(val).sub(' ', ' .*')}$/i }
			end
		elsif val.class == Regexp
			obj = @@inv.find { |o| o.name =~ val } || @@loot.find { |o| o.name =~ val } || @@npcs.find { |o| o.name =~ val } || @@pcs.find { |o| o.name =~ val } || [ @@right_hand, @@left_hand ].find { |o| o.name =~ val } || @@room_desc.find { |o| o.name =~ val }
		end
	end
	def GameObj
		@noun
	end
	def full_name
		"#{@before_name}#{' ' unless @before_name.nil? or @before_name.empty?}#{name}#{' ' unless @after_name.nil? or @after_name.empty?}#{@after_name}"
	end
	def GameObj.new_npc(id, noun, name, status=nil)
		obj = GameObj.new(id, noun, name)
		@@npcs.push(obj)
		@@npc_status[id] = status
		obj
	end
	def GameObj.new_loot(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@loot.push(obj)
		obj
	end
	def GameObj.new_pc(id, noun, name, status=nil)
		obj = GameObj.new(id, noun, name)
		@@pcs.push(obj)
		@@pc_status[id] = status
		obj
	end
	def GameObj.new_inv(id, noun, name, container=nil, before=nil, after=nil)
		obj = GameObj.new(id, noun, name, before, after)
		if container
			@@contents[container].push(obj)
		else
			@@inv.push(obj)
		end
		obj
	end
	def GameObj.new_room_desc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@room_desc.push(obj)
		obj
	end
	def GameObj.new_fam_room_desc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_room_desc.push(obj)
		obj
	end
	def GameObj.new_fam_loot(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_loot.push(obj)
		obj
	end
	def GameObj.new_fam_npc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_npcs.push(obj)
		obj
	end
	def GameObj.new_fam_pc(id, noun, name)
		obj = GameObj.new(id, noun, name)
		@@fam_pcs.push(obj)
		obj
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
		@@npc_status.clear
	end
	def GameObj.clear_pcs
		@@pcs.clear
		@@pc_status.clear
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
	def GameObj.load_data(filename="#{$script_dir}gameobj-data.xml")
		if $SAFE == 0
			if File.exists?(filename)
				begin
					@@type_data = Hash.new
					@@sellable_data = Hash.new
					File.open(filename) { |file|
						doc = REXML::Document.new(file.read)
						doc.elements.each('data/type') { |e|
							if type = e.attributes['name']
								@@type_data[type] = Hash.new
								@@type_data[type][:name]    = Regexp.new(e.elements['name'].text) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
								@@type_data[type][:noun]    = Regexp.new(e.elements['noun'].text) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
								@@type_data[type][:exclude] = Regexp.new(e.elements['exclude'].text) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
							end
						}
						doc.elements.each('data/sellable') { |e|
							if sellable = e.attributes['name']
								@@sellable_data[sellable] = Hash.new
								@@sellable_data[sellable][:name]    = Regexp.new(e.elements['name'].text) unless e.elements['name'].text.nil? or e.elements['name'].text.empty?
								@@sellable_data[sellable][:noun]    = Regexp.new(e.elements['noun'].text) unless e.elements['noun'].text.nil? or e.elements['noun'].text.empty?
								@@sellable_data[sellable][:exclude] = Regexp.new(e.elements['exclude'].text) unless e.elements['exclude'].text.nil? or e.elements['exclude'].text.empty?
							end
						}
					}
					true
				rescue
					@@type_data = nil
					@@sellable_data = nil
					echo "error: GameObj.load_data: #{$!}"
					respond $!.backtrace[0..1]
					false
				end
			else
				@@type_data = nil
				@@sellable_data = nil
				echo "error: GameObj.load_data: file does not exist: #{filename}"
				false
			end
		else
			UNTRUSTED_GAMEOBJ_LOAD_DATA.call
		end
	end
	def GameObj.type_data
		@@type_data
	end
	def GameObj.sellable_data
		@@sellable_data
	end
end

class RoomObj < GameObj
end

class Map
	@@list ||= Array.new
	@@tags ||= Array.new
	@@warned_depreciated_guaranteed_shortest_pathfind = false
	@@warned_depreciated_estimation_pathfind = false
	@@current_room_id ||= 0
	@@current_room_count ||= -1
	@@current_location ||= nil
	@@current_location_count ||= -1
	attr_reader :id
	attr_accessor :title, :description, :paths, :location, :climate, :terrain, :wayto, :timeto, :image, :image_coords, :tags, :check_location, :unique_loot
	def initialize(id, title, description, paths, location=nil, climate=nil, terrain=nil, wayto={}, timeto={}, image=nil, image_coords=nil, tags=[], check_location=nil, unique_loot=nil)
		@id, @title, @description, @paths, @location, @climate, @terrain, @wayto, @timeto, @image, @image_coords, @tags, @check_location, @unique_loot = id, title, description, paths, location, climate, terrain, wayto, timeto, image, image_coords, tags, check_location, unique_loot
		@@list[@id] = self
	end
	def outside?
		@paths.first =~ /Obvious paths:/
	end
	def to_i
		@id
	end
	def to_s
		"##{@id}:\n#{@title[-1]}\n#{@description[-1]}\n#{@paths[-1]}"
	end
	def inspect
		self.instance_variables.collect { |var| var.to_s + "=" + self.instance_variable_get(var).inspect }.join("\n")
	end
	def Map.get_free_id
		Map.load if @@list.empty?
		free_id = 0
		until @@list[free_id].nil?
			free_id += 1
		end
		free_id
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
			@@list.find { |room| room.title.find { |title| title =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chkre } }
		end
	end
	def Map.get_location
		unless XMLData.room_count == @@current_location_count
			if script = Script.self
				save_want_downstream = script.want_downstream
				script.want_downstream = true
				waitrt?
				location_result = dothistimeout 'location', 15, /^You carefully survey your surroundings and guess that your current location is .*? or somewhere close to it\.$|^You can't do that while submerged under water\.$|^You can't do that\.$|^It would be rude not to give your full attention to the performance\.$|^You can't do that while hanging around up here!$|^You are too distracted by the difficulty of staying alive in these treacherous waters to do that\.$|^You carefully survey your surroundings but are unable to guess your current location\.$|^Not in pitch darkness you don't\.$/
				script.want_downstream = save_want_downstream
				@@current_location_count = XMLData.room_count
				if location_result =~ /^You can't do that while submerged under water\.$|^You can't do that\.$|^It would be rude not to give your full attention to the performance\.$|^You can't do that while hanging around up here!$|^You are too distracted by the difficulty of staying alive in these treacherous waters to do that\.$|^You carefully survey your surroundings but are unable to guess your current location\.$|^Not in pitch darkness you don't\.$/
					@@current_location = false
				else
					@@current_location = /^You carefully survey your surroundings and guess that your current location is (.*?) or somewhere close to it\.$/.match(location_result).captures.first
				end
			else
				nil
			end
		end
		@@current_location
	end
	def Map.current
		Map.load if @@list.empty?
		1.times {
			count = XMLData.room_count
			if (XMLData.room_count == @@current_room_count) and (room = @@list[@@current_room_id])
				return room
			else
				room = @@list.find { |r| r.title.include?(XMLData.room_title) and r.description.include?(XMLData.room_description.strip) and r.paths.include?(XMLData.room_exits_string.strip) and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) }
				unless room
					desc_regex = /#{Regexp.escape(XMLData.room_description.strip).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
					room = @@list.find { |r| r.title.include?(XMLData.room_title) and r.paths.include?(XMLData.room_exits_string.strip) and r.description.find { |desc| desc =~ desc_regex }  and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) }
				end
				if room.check_location
					if current_location = Map.get_location
						room = @@list.find { |r| (r.location == current_location) and r.title.include?(XMLData.room_title) and r.description.include?(XMLData.room_description.strip) and r.paths.include?(XMLData.room_exits_string.strip) and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) }
						unless room
							desc_regex = /#{Regexp.escape(XMLData.room_description.strip).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
							room = @@list.find { |r| (r.location == current_location) and r.title.include?(XMLData.room_title) and r.paths.include?(XMLData.room_exits_string.strip) and r.description.find { |desc| desc =~ desc_regex } and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) }
						end
					else
						room = nil
					end
				end
				if peer_tag = room.tags.find { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
					need_desc, peer_direction, peer_requirement = /^(set desc on; )?peer ([a-z]+) =~ \/(.+)\/$/.match(peer_tag).captures
					if script = Script.self
						if need_desc
							unless last_roomdesc = $_SERVERBUFFER_.reverse.find { |line| line =~ /<style id="roomDesc"\/>/ } and (last_roomdesc =~ /<style id="roomDesc"\/>[^<]/)
								put 'set description on'
							end
						end
						save_want_downstream = script.want_downstream
						script.want_downstream = true
						squelch_started = false
						squelch_proc = proc { |server_string|
							if squelch_started
								if server_string =~ /<prompt/
									DownstreamHook.remove('squelch-peer')
								end
								nil
							elsif server_string =~ /^You peer/
								squelch_started = true
								nil
							else
								server_string
							end
						}
						DownstreamHook.add('squelch-peer', squelch_proc)
						redo unless count == XMLData.room_count
						result = dothistimeout "peer #{peer_direction}", 3, /^You peer|^\[Usage: PEER/
						redo unless count == XMLData.room_count
						if result =~ /^You peer/
							peer_results = Array.new
							5.times {
								if line = get?
									peer_results.push line
									break if line =~ /^Obvious/
								end
							}
							unless peer_results.any? { |line| line =~ /#{peer_requirement}/ }
								while room = @@list[(room.id+1)..-1].find { |r| r.title.include?(XMLData.room_title) and r.description.include?(XMLData.room_description.strip) and r.paths.include?(XMLData.room_exits_string.strip) and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) }
									if peer_tag = room.tags.find { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
										new_need_desc, new_peer_direction, new_peer_requirement = /^(set desc on; )?peer ([a-z]+) =~ \/(.+)\/$/.match(peer_tag).captures
										if new_peer_direction == peer_direction
											# fixme: check new_need_desc
											if peer_results.any? { |line| line =~ /#{new_peer_requirement}/ }
												break
											end
										else
											# fixme: peer again..
										end
									else
										break
									end
								end
							end
						end
						script.want_downstream = save_want_downstream
					else
						room = nil
					end
				end
				if room
					@@current_room_count = count
					@@current_room_id = room.id
				end
				return room
			end
		}
	end
	def Map.current_or_new
		if XMLData.game =~ /DR/
			Map.current || Map.new(Map.get_free_id, [ XMLData.room_title ], [ XMLData.room_description.strip ], [ XMLData.room_exits_string.strip ])
		else
			peer_tag_good = proc { |r|
				if peer_tag = r.tags.find { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
					good = false
					need_desc, peer_direction, peer_requirement = /^(set desc on; )?peer ([a-z]+) =~ \/(.+)\/$/.match(peer_tag).captures
					if need_desc
						unless last_roomdesc = $_SERVERBUFFER_.reverse.find { |line| line =~ /<style id="roomDesc"\/>/ } and (last_roomdesc =~ /<style id="roomDesc"\/>[^<]/)
							put 'set description on'
						end
					end
					script = Script.self
					save_want_downstream = script.want_downstream
					script.want_downstream = true
					squelch_started = false
					squelch_proc = proc { |server_string|
						if squelch_started
							if server_string =~ /<prompt/
								DownstreamHook.remove('squelch-peer')
							end
							nil
						elsif server_string =~ /^You peer/
							squelch_started = true
							nil
						else
							server_string
						end
					}
					DownstreamHook.add('squelch-peer', squelch_proc)
					result = dothistimeout "peer #{peer_direction}", 3, /^You peer|^\[Usage: PEER/
					if result =~ /^You peer/
						peer_results = Array.new
						5.times {
							if line = get?
								peer_results.push line
								break if line =~ /^Obvious/
							end
						}
						if peer_results.any? { |line| line =~ /#{peer_requirement}/ }
							good = true
						end
					end
					script.want_downstream = save_want_downstream
				else
					good = true
				end
				good
			}
			current_location = Map.get_location
			if room = @@list.find { |r| (r.location == current_location) and r.title.include?(XMLData.room_title) and r.description.include?(XMLData.room_description.strip) and r.paths.include?(XMLData.room_exits_string.strip) and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) and peer_tag_good.call(r) }
				return room
			elsif room = @@list.find { |r| r.location.nil? and r.title.include?(XMLData.room_title) and r.description.include?(XMLData.room_description.strip) and r.paths.include?(XMLData.room_exits_string.strip) and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) and peer_tag_good.call(r) }
				room.location = current_location
				return room
			else
				title = [ XMLData.room_title ]
				description = [ XMLData.room_description.strip ]
				paths = [ XMLData.room_exits_string.strip ]
				room = Map.new(Map.get_free_id, title, description, paths, current_location)
				identical_rooms = @@list.find_all { |r| (r.location != current_location) and r.title.include?(XMLData.room_title) and r.description.include?(XMLData.room_description.strip) and r.paths.include?(XMLData.room_exits_string.strip) and (r.unique_loot.nil? or (r.unique_loot.to_a - GameObj.loot.to_a.collect { |obj| obj.name }).empty?) }
				if identical_rooms.length > 0
					room.check_location = true
					identical_rooms.each { |r| r.check_location = true }
				end
				return room
			end
		end
	end
	def Map.tags
		@@tags.dup
	end
	def Map.reload
		@@list.clear
		Map.load
		GC.start
	end
	def Map.load(filename=nil)
		if $SAFE == 0
			if filename.nil?
				file_list = Dir.entries("#{$data_dir}#{XMLData.game}").find_all { |filename| filename =~ /^map\-[0-9]+\.(?:dat|xml)$/ }.collect { |filename| "#{$data_dir}#{XMLData.game}/#{filename}" }.sort.reverse
			else
				file_list = [ filename ]
			end
			if file_list.empty?
				respond "--- error: no map database found"
				return false
			end
			while filename = file_list.shift
				if filename =~ /\.xml$/
					if Map.load_xml(filename)
						return true
					end
				else
					if Map.load_dat(filename)
						return true
					end
				end
			end
			return false
		else
			UNTRUSTED_MAP_LOAD.call
		end
	end
	def Map.load_dat(filename=nil)
		if $SAFE == 0
			if filename.nil?
				file_list = Dir.entries("#{$data_dir}#{XMLData.game}").find_all { |filename| filename =~ /^map\-[0-9]+\.dat$/ }.collect { |filename| "#{$data_dir}#{XMLData.game}/#{filename}" }.sort.reverse
			else
				file_list = [ filename ]
			end
			if file_list.empty?
				respond "--- error: no map database found"
				return false
			end
			error = false
			while filename = file_list.shift
				begin
					File.open(filename, 'rb') { |file| @@list = Marshal.load(file.read) }
					if @@list[0].instance_variables.include?('@pause') or @@list[0].instance_variables.include?(:@pause)
						respond "--- converting #{filename}"
						temp_list = @@list
						@@list = Array.new
						temp_list.each { |room|
							next if room.nil?
							if room.instance_variable_get('@map_x') and room.instance_variable_get('@map_y') and room.instance_variable_get('@map_roomsize')
								image_coords = [ (room.instance_variable_get('@map_x').to_i - (room.instance_variable_get('@map_roomsize')/2.0).round), (room.instance_variable_get('@map_y').to_i - (room.instance_variable_get('@map_roomsize')/2.0).round), (room.instance_variable_get('@map_x').to_i + (room.instance_variable_get('@map_roomsize')/2.0).round), (room.instance_variable_get('@map_y').to_i + (room.instance_variable_get('@map_roomsize')/2.0).round) ]
							else
								image_coords = nil
							end
							Map.new(room.id, room.title, room.instance_variable_get('@desc'), room.paths, nil, nil, nil, room.wayto, room.timeto, room.instance_variable_get('@map_name'), image_coords, Array.new, nil)
						}
						temp_list = nil
						Map.save
					end
					GC.start
					@@tags.clear
					@@list.each { |room| @@tags = @@tags | room.tags unless room.tags.nil? }
					respond "--- loaded #{filename}" if error
					return true
				rescue
					error = true
					if file_list.empty?
						respond "--- error: failed to load #{filename}: #{$!}"
					else
						respond "--- warning: failed to load #{filename}: #{$!}"
					end
				end
			end
			return false
		else
			UNTRUSTED_MAP_LOAD_DAT.call
		end
	end
	def Map.load_xml(filename="#{$data_dir}#{XMLData.game}/map.xml")
		if $SAFE == 0
			unless File.exists?(filename)
				raise Exception.exception("MapDatabaseError"), "Fatal error: file `#{filename}' does not exist!"
			end
			missing_end = false
			current_tag = nil
			current_attributes = nil
			room = nil
			buffer = String.new
			unescape = { 'lt' => '<', 'gt' => '>', 'quot' => '"', 'apos' => "'", 'amp' => '&' }
			tag_start = proc { |element,attributes|
				current_tag = element
				current_attributes = attributes
				if element == 'room'
					room = Hash.new
					room['id'] = attributes['id'].to_i
					room['location'] = attributes['location']
					room['climate'] = attributes['climate']
					room['terrain'] = attributes['terrain']
					room['wayto'] = Hash.new
					room['timeto'] = Hash.new
					room['title'] = Array.new
					room['description'] = Array.new
					room['paths'] = Array.new
					room['tags'] = Array.new
					room['unique_loot'] = Array.new
				elsif element =~ /^(?:image|tsoran)$/ and attributes['name'] and attributes['x'] and attributes['y'] and attributes['size']
					room['image'] = attributes['name']
					room['image_coords'] = [ (attributes['x'].to_i - (attributes['size']/2.0).round), (attributes['y'].to_i - (attributes['size']/2.0).round), (attributes['x'].to_i + (attributes['size']/2.0).round), (attributes['y'].to_i + (attributes['size']/2.0).round) ]
				elsif (element == 'image') and attributes['name'] and attributes['coords'] and (attributes['coords'] =~ /[0-9]+,[0-9]+,[0-9]+,[0-9]+/)
					room['image'] = attributes['name']
					room['image_coords'] = attributes['coords'].split(',').collect { |num| num.to_i }
				elsif element == 'map'
					missing_end = true
				end
			}
			text = proc { |text_string|
				if current_tag == 'tag'
					room['tags'].push(text_string)
				elsif current_tag =~ /^(?:title|description|paths|tag|unique_loot)$/
					room[current_tag].push(text_string)
				elsif current_tag == 'exit' and current_attributes['target']
					if current_attributes['type'].downcase == 'string'
						room['wayto'][current_attributes['target']] = text_string
					elsif
						room['wayto'][current_attributes['target']] = StringProc.new(text_string)
					end
					if current_attributes['cost'] =~ /^[0-9\.]+$/
						room['timeto'][current_attributes['target']] = current_attributes['cost'].to_f
					elsif current_attributes['cost'].length > 0
						room['timeto'][current_attributes['target']] = StringProc.new(current_attributes['cost'])
					else
						room['timeto'][current_attributes['target']] = 0.2
					end
				end
			}
			tag_end = proc { |element|
				if element == 'room'
					room['unique_loot'] = nil if room['unique_loot'].empty?
					Map.new(room['id'], room['title'], room['description'], room['paths'], room['location'], room['climate'], room['terrain'], room['wayto'], room['timeto'], room['image'], room['image_coords'], room['tags'], room['check_location'], room['unique_loot'])
				elsif element == 'map'
					missing_end = false
				end
				current_tag = nil
			}
			begin
				File.open(filename) { |file|
					while line = file.gets
						buffer.concat(line)
						# fixme: remove   (?=<)   ?
						while str = buffer.slice!(/^<([^>]+)><\/\1>|^[^<]+(?=<)|^<[^<]+>/)
							if str[0,1] == '<'
								if str[1,1] == '/'
									element = /^<\/([^\s>\/]+)/.match(str).captures.first
									tag_end.call(element)
								else
									if str =~ /^<([^>]+)><\/\1>/
										element = $1
										tag_start.call(element)
										text.call('')
										tag_end.call(element)
									else
										element = /^<([^\s>\/]+)/.match(str).captures.first
										attributes = Hash.new
										str.scan(/([A-z][A-z0-9_\-]*)=(["'])(.*?)\2/).each { |attr| attributes[attr[0]] = attr[2].gsub(/&(#{unescape.keys.join('|')});/) { unescape[$1] } }
										tag_start.call(element, attributes)
										tag_end.call(element) if str[-2,1] == '/'
									end
								end
							else
								text.call(str.gsub(/&(#{unescape.keys.join('|')});/) { unescape[$1] })
							end
						end
					end
				}
				if missing_end
					respond "--- error: failed to load #{filename}: unexpected end of file"
					return false
				end
				@@tags.clear
				@@list.each { |room| (@@tags = @@tags | room.tags) unless room.tags.nil? }
				true
			rescue
				respond "--- error: failed to load #{filename}: #{$!}"
				return false
			end
		else
			UNTRUSTED_MAP_LOAD_XML.call
		end
	end
	def Map.save(filename="#{$data_dir}#{XMLData.game}/map-#{Time.now.to_i}.dat")
		if $SAFE == 0
			if File.exists?(filename)
				respond "--- Backing up map database"
				begin
					File.open(filename, 'rb') { |infile|
						File.open("#{filename}.bak", 'wb') { |outfile|
							outfile.write(infile.read)
						}
					}
				rescue
					respond "--- error: #{$!}"
				end
			end
			begin
				File.open(filename, 'wb') { |file|
					file.write(Marshal.dump(@@list))
				}
				@@tags.clear
				@@list.each { |room| @@tags = @@tags | room.tags unless room.tags.nil? }
				respond "--- Map database saved"
			rescue
				respond "--- error: #{$!}"
			end
			GC.start
		else
			UNTRUSTED_MAP_SAVE.call
		end
	end
	def Map.save_xml(filename="#{$data_dir}#{XMLData.game}/map-#{Time.now.to_i}.xml")
		if $SAFE == 0
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
				escape = { '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => "&apos;", '&' => '&amp;' }
				File.open(filename, 'w') { |file|
					file.write "<map>\n"
					@@list.each { |room|
						next if room == nil
						if room.location
							location = " location=#{(room.location.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
						else
							location = ''
						end
						if room.climate
							climate = " climate=#{(room.climate.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
						else
							climate = ''
						end
						if room.terrain
							terrain = " terrain=#{(room.terrain.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
						else
							terrain = ''
						end
						file.write "	<room id=\"#{room.id}\"#{location}#{climate}#{terrain}>\n"
						room.title.each { |title| file.write "		<title>#{title.gsub(/(<|>|"|'|&)/) { escape[$1] }}</title>\n" }
						room.description.each { |desc| file.write "		<description>#{desc.gsub(/(<|>|"|'|&)/) { escape[$1] }}</description>\n" }
						room.paths.each { |paths| file.write "		<paths>#{paths.gsub(/(<|>|"|'|&)/) { escape[$1] }}</paths>\n" }
						room.tags.each { |tag| file.write "		<tag>#{tag.gsub(/(<|>|"|'|&)/) { escape[$1] }}</tag>\n" }
						room.unique_loot.to_a.each { |loot| file.write "		<unique_loot>#{loot.gsub(/(<|>|"|'|&)/) { escape[$1] }}</unique_loot>\n" }
						file.write "		<image name=\"#{room.image.gsub(/(<|>|"|'|&)/) { escape[$1] }}\" coords=\"#{room.image_coords.join(',')}\" />\n" if room.image and room.image_coords
						room.wayto.keys.each { |target|
							if room.timeto[target].class == Proc
								cost = " cost=\"#{room.timeto[target]._dump.gsub(/(<|>|"|'|&)/) { escape[$1] }}\""
							elsif room.timeto[target]
								cost = " cost=\"#{room.timeto[target]}\""
							else
								cost = ''
							end
							if room.wayto[target].class == Proc
								file.write "		<exit target=\"#{target}\" type=\"Proc\"#{cost}>#{room.wayto[target]._dump.gsub(/(<|>|"|'|&)/) { escape[$1] }}</exit>\n"
							else
								file.write "		<exit target=\"#{target}\" type=\"#{room.wayto[target].class}\"#{cost}>#{room.wayto[target].gsub(/(<|>|"|'|&)/) { escape[$1] }}</exit>\n"
							end
						}
						file.write "	</room>\n"
					}
					file.write "</map>\n"
				}
				@@tags.clear
				@@list.each { |room| @@tags = @@tags | room.tags unless room.tags.nil? }
				respond "--- map database saved to: #{filename}"
			rescue
				respond $!
			end
			GC.start
		else
			UNTRUSTED_MAP_SAVE_XML.call
		end
	end
	def Map.estimate_time(array)
		Map.load if @@list.empty?
		unless array.class == Array
			raise Exception.exception("MapError"), "Map.estimate_time was given something not an array!"
		end
		time = 0.to_f
		until array.length < 2
			room = array.shift
			if t = Map[room].timeto[array.first.to_s]
				if t.class == Proc
					time += t.call.to_f
				else
					time += t.to_f
				end
			else
				time += "0.2".to_f
			end
		end
		time
	end
	def Map.dijkstra(source, destination=nil)
		if source.class == Map
			source.dijkstra(destination)
		elsif room = Map[source]
			room.dijkstra(destination)
		else
			echo "Map.dijkstra: error: invalid source room"
			nil
		end
	end
	def dijkstra(destination=nil)
		begin
			Map.load if @@list.empty?
			source = @id
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
						unless visited[adj_room_i] 
							if @@list[v].timeto[adj_room].class == Proc
								nd = @@list[v].timeto[adj_room].call
							else
								nd = @@list[v].timeto[adj_room]
							end
							if nd
								nd += shortest_distances[v]
								if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
									shortest_distances[adj_room_i] = nd
									previous[adj_room_i] = v
									pq_push.call(adj_room_i)
								end
							end
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
						unless visited[adj_room_i] 
							if @@list[v].timeto[adj_room].class == Proc
								nd = @@list[v].timeto[adj_room].call
							else
								nd = @@list[v].timeto[adj_room]
							end
							if nd
								nd += shortest_distances[v]
								if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
									shortest_distances[adj_room_i] = nd
									previous[adj_room_i] = v
									pq_push.call(adj_room_i)
								end
							end
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
						unless visited[adj_room_i] 
							if @@list[v].timeto[adj_room].class == Proc
								nd = @@list[v].timeto[adj_room].call
							else
								nd = @@list[v].timeto[adj_room]
							end
							if nd
								nd += shortest_distances[v]
								if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
									shortest_distances[adj_room_i] = nd
									previous[adj_room_i] = v
									pq_push.call(adj_room_i)
								end
							end
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
	def Map.findpath(source, destination)
		if source.class == Map
			source.path_to(destination)
		elsif room = Map[source]
			room.path_to(destination)
		else
			echo "Map.findpath: error: invalid source room"
			nil
		end
	end
	def path_to(destination)
		Map.load if @@list.empty?
		destination = destination.to_i
		previous, shortest_distances = dijkstra(destination)
		return nil unless previous[destination]
		path = [ destination ]
		path.push(previous[path[-1]]) until previous[path[-1]] == @id
		path.reverse!
		path.pop
		return path
	end
	def find_nearest_by_tag(tag_name)
		target_list = Array.new
		@@list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
		previous, shortest_distances = Map.dijkstra(@id, target_list)
		if target_list.include?(@id)
			@id
		else
			target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
			target_list.sort { |a,b| shortest_distances[a] <=> shortest_distances[b] }.first
		end
	end
	def find_all_nearest_by_tag(tag_name)
		target_list = Array.new
		@@list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
		previous, shortest_distances = Map.dijkstra(@id)
		target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
		target_list.sort { |a,b| shortest_distances[a] <=> shortest_distances[b] }
	end
	def find_nearest(target_list)
		target_list = target_list.collect { |num| num.to_i }
		if target_list.include?(@id)
			@id
		else
			previous, shortest_distances = Map.dijkstra(@id, target_list)
			target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
			target_list.sort { |a,b| shortest_distances[a] <=> shortest_distances[b] }.first
		end
	end
	# depreciated
	def desc
		@description
	end
	def map_name
		@image
	end
	def map_x
		if @image_coords.nil?
			nil
		else
			((image_coords[0] + image_coords[2])/2.0).round
		end
	end
	def map_y
		if @image_coords.nil?
			nil
		else
			((image_coords[1] + image_coords[3])/2.0).round
		end
	end
	def map_roomsize
		if @image_coords.nil?
			nil
		else
			image_coords[2] - image_coords[0]
		end
	end
	def geo
		nil
	end
	def guaranteed_shortest_pathfind(target)
		unless @@warned_depreciated_guaranteed_shortest_pathfind
			unless script_name = Script.self.name
				script_name = 'unknown script'
			end
			respond "--- warning: #{script_name} is using depreciated method guaranteed_shortest_pathfind"
			@@warned_depreciated_guaranteed_shortest_pathfind = true
		end
		path_to(target)
	end
	def estimation_pathfind(target)
		unless @@warned_depreciated_estimation_pathfind
			unless script_name = Script.self.name
				script_name = 'unknown script'
			end
			respond "--- warning: #{script_name} is using depreciated method estimation_pathfind"
			@@warned_depreciated_estimation_pathfind = true
		end
		path_to(target)
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

# proc objects can't be dumped, since an intrinsic part of what they are is the 'binding' environment... this is just a quick fix so that a proc object can be saved; it's identical to a proc except that it also carries around the string that created the proc, so when it's loaded from a Marshal dump the proc object is recreated from the original string.  Basically it's a way for each room to carry around a mini-script they can save and load with the rest of the map database info
class StringProc
	def initialize(string)
		@string = string
		if $SAFE == 0
			@string.untaint
		else
			UNTRUSTED_UNTAINT.call(@string)
		end
	end
	def kind_of?(type)
		Proc.new {}.kind_of? type
	end
	def class
		Proc
	end
	def call(*args)
		if $SAFE < 3
			proc { $SAFE = 3; eval(@string) }.call
		else
			eval(@string)
		end
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
		sleep "0.3".to_f
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
			if messages.class == Array
				messages = messages.flatten.compact
			else
				messages = [ messages.to_s ]
			end
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

def start_script(script_name, cli_vars=[], flags=Hash.new)
	# fixme: look in wizard script directory
	if $SAFE == 0
		file_name = nil
		if File.exists?("#{$script_dir}#{script_name}.lic")
			file_name = "#{script_name}.lic"
		elsif File.exists?("#{$script_dir}#{script_name}.cmd")
			file_name = "#{script_name}.cmd"
		elsif File.exists?("#{$script_dir}#{script_name}.wiz")
			file_name = "#{script_name}.wiz"
		else
			file_list = Dir.entries($script_dir).delete_if { |fn| (fn == '.') or (fn == '..') }.sort
			file_name = (file_list.find { |val| val =~ /^#{script_name}\.(?:lic|rbw?|cmd|wiz)(?:\.gz|\.Z)?$/i } || file_list.find { |val| val =~ /^#{script_name}[^.]+\.(?i:lic|rbw?|cmd|wiz)(?:\.gz|\.Z)?$/ } || file_list.find { |val| val =~ /^#{script_name}[^.]+\.(?:lic|rbw?|cmd|wiz)(?:\.gz|\.Z)?$/i } || file_list.find { |val| val =~ /^#{script_name}$/i })
			file_list = nil
		end
		unless file_name
			respond("--- Lich: could not find script `#{script_name}' in directory #{$script_dir}!")
			return false
		end
		if (flags[:force] != true) and (Script.running + Script.hidden).find { |scr| scr.name == file_name.sub(/\..{1,3}$/, '') }
			respond("--- Lich: #{script_name} is already running (use #{$clean_lich_char}force [scriptname] if desired).")
			return false
		end
		begin
			if file_name =~ /cmd$|wiz$/i
				trusted = false
				new_script = WizardScript.new("#{$script_dir}#{file_name}", cli_vars)
			else
				trusted = LichSettings['trusted_scripts'].include?(file_name.sub(/\.lic$/,''))
				new_script = Script.new("#{$script_dir}#{file_name}", cli_vars, flags[:command_line])
			end
			if not trusted
				script_binding = UntrustedScriptBinder.new.create_block.binding
			elsif new_script.labels.length > 1
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
		new_script.quiet = true if flags[:quiet]
		new_thread = Thread.new {
			100.times { break if Script.self == new_script; sleep "0.01".to_f }
			if script = Script.self
				eval('script = Script.self', script_binding, script.name) if script_binding
				Thread.current.priority = 1
				respond("--- Lich: #{script.name} active.") unless script.quiet
				if trusted
					begin
						Settings.load
						GameSettings.load
						CharSettings.load
						while (script = Script.self) and script.current_label
							eval(script.labels[script.current_label].to_s, script_binding, script.name)
							Script.self.get_next_label
						end
						Script.self.kill
					rescue SystemExit
						Script.self.kill
					rescue SyntaxError
						respond "--- SyntaxError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- SyntaxError: #{$!}"
						$stderr.puts $!.backtrace
						respond "--- Lich: cannot execute #{Script.self.name}, aborting."
						Script.self.kill
					rescue ScriptError
						respond "--- ScriptError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- ScriptError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue NoMemoryError
						respond "--- NoMemoryError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- NoMemoryError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue LoadError
						respond "--- LoadError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- LoadError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue SecurityError
						respond "--- Review this script (#{Script.self.name}) to make sure it isn't malicious, and type ;trust #{Script.self.name}"
						respond "--- SecurityError: #{$!}"
						respond $!.backtrace[0..1]
						$stderr.puts "--- SecurityError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue ThreadError
						respond "--- ThreadError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- ThreadError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue SystemStackError
						respond "--- SystemStackError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- SystemStackError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue Exception
						if $! == JUMP
							retry if Script.self.get_next_label != JUMP_ERROR
							respond "--- Label Error: `#{Script.self.jump_label}' was not found, and no `LabelError' label was found!"
							respond $!.backtrace.first
							$stderr.puts "--- Label Error: `#{Script.self.jump_label}' was not found, and no `LabelError' label was found!"
							$stderr.puts $!.backtrace
							Script.self.kill
						else
							respond "--- Exception: #{$!}"
							respond $!.backtrace.first
							$stderr.puts "--- Exception: #{$!}"
							$stderr.puts $!.backtrace
							Script.self.kill
						end
					rescue
						respond "--- Error: #{Script.self.name}: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- Error: #{Script.self.name}: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					end
				else
					begin
						Settings.load
						GameSettings.load
						CharSettings.load
						while (script = Script.self) and script.current_label
							proc { script.labels[script.current_label].untaint; $SAFE = 3; eval(script.labels[script.current_label], script_binding, script.name, 1) }.call
							Script.self.get_next_label
						end
						Script.self.kill
					rescue SystemExit
						Script.self.kill
					rescue SyntaxError
						respond "--- SyntaxError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- SyntaxError: #{$!}"
						$stderr.puts $!.backtrace
						respond "--- Lich: cannot execute #{Script.self.name}, aborting."
						Script.self.kill
					rescue ScriptError
						respond "--- ScriptError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- ScriptError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue NoMemoryError
						respond "--- NoMemoryError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- NoMemoryError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue LoadError
						respond "--- LoadError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- LoadError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue SecurityError
						respond "--- Review this script (#{Script.self.name}) to make sure it isn't malicious, and type ;trust #{Script.self.name}"
						respond "--- SecurityError: #{$!}"
						respond $!.backtrace[0..1]
						$stderr.puts "--- SecurityError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue ThreadError
						respond "--- ThreadError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- ThreadError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue SystemStackError
						respond "--- SystemStackError: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- SystemStackError: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					rescue Exception
						if $! == JUMP
							retry if Script.self.get_next_label != JUMP_ERROR
							respond "--- Label Error: `#{Script.self.jump_label}' was not found, and no `LabelError' label was found!"
							respond $!.backtrace.first
							$stderr.puts "--- Label Error: `#{Script.self.jump_label}' was not found, and no `LabelError' label was found!"
							$stderr.puts $!.backtrace
							Script.self.kill
						else
							respond "--- Exception: #{$!}"
							respond $!.backtrace.first
							$stderr.puts "--- Exception: #{$!}"
							$stderr.puts $!.backtrace
							Script.self.kill
						end
					rescue
						respond "--- Error: #{Script.self.name}: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "--- Error: #{Script.self.name}: #{$!}"
						$stderr.puts $!.backtrace
						Script.self.kill
					end
				end
			else
				respond 'start_script screwed up...'
			end
		}
		new_script.thread_group.add(new_thread)
		true
	else
		UNTRUSTED_START_SCRIPT.call(script_name, cli_vars, flags)
	end
end

def start_scripts(*script_names)
	script_names.flatten.each { |script_name|
		start_script(script_name)
		sleep "0.02".to_f
	}
end

def force_start_script(script_name,cli_vars=[], flags={})
	flags = Hash.new unless flags.class == Hash
	flags[:force] = true
	start_script(script_name,cli_vars,flags)
end

def start_exec_script(cmd_data, flags=Hash.new)
	flags = { :quiet => true } if flags == true
	if $SAFE == 0
		trusted = flags[:trusted]
		unless new_script = ExecScript.new(cmd_data, flags)
			respond '--- Lich: failed to start exec script'
			return false
		end
		new_thread = Thread.new {
			100.times { break if Script.self == new_script; sleep "0.01".to_f }
			if script = Script.self
				Thread.current.priority = 1
				respond("--- Lich: #{script.name} active.") unless script.quiet
				begin
					if trusted
						eval(cmd_data, nil, script.name.to_s)
					else
						proc { cmd_data.untaint; $SAFE = 3; eval(cmd_data, nil, script.name.to_s) }.call
					end
					Script.self.kill
				rescue SystemExit
					Script.self.kill
				rescue SyntaxError
					respond "--- SyntaxError: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- SyntaxError: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue ScriptError
					respond "--- ScriptError: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- ScriptError: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue NoMemoryError
					respond "--- NoMemoryError: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- NoMemoryError: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue LoadError
					respond("--- LoadError: #{$!}")
					respond "--- LoadError: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- LoadError: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue SecurityError
					respond "--- SecurityError: #{$!}"
					respond $!.backtrace[0..1]
					$stderr.puts "--- SecurityError: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue ThreadError
					respond "--- ThreadError: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- ThreadError: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue SystemStackError
					respond "--- SystemStackError: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- SystemStackError: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue Exception
					respond "--- Exception: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- Exception: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				rescue
					respond "--- Error: #{$!}"
					respond $!.backtrace.first
					$stderr.puts "--- Error: #{$!}"
					$stderr.puts $!.backtrace
					Script.self.kill
				end
			else
				respond 'start_exec_script screwed up...'
			end
		}
		new_script.thread_group.add(new_thread)
		true
	else
		UNTRUSTED_START_EXEC_SCRIPT.call(cmd_data, flags)
	end
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
	wait_until { (XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f) > 0 }
	sleep((XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + "0.6".to_f).abs)
end

def waitrt?
	rt = XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + "0.6".to_f
	if rt > 0
		sleep rt
	end
end

def waitcastrt
	wait_until { (XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f) > 0 }
	sleep((XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + "0.6".to_f).abs)
end

def waitcastrt?
	rt = XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + "0.6".to_f
	if rt > 0
		sleep rt
	end
end

def checkrt
	[XMLData.roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + "0.6".to_f, 0].max
end

def checkcastrt
	[XMLData.cast_roundtime_end.to_f - Time.now.to_f + XMLData.server_time_offset.to_f + "0.6".to_f, 0].max
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
	checkbleeding and !(Spell[9909].active? or Spell[9905].active?)
end

def muckled?
	muckled = checkwebbed or checkdead or checkstunned
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
		XMLData.name
	else
		XMLData.name =~ /^(?:#{strings.join('|')})/i
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
	unless script.want_upstream then echo("This script wants to listen to the upstream, but it isn't set as receiving the upstream! This will cause a permanent hang, aborting (ask for the upstream with 'toggle_upstream' in the script)") ; return false end
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
		if script.want_downstream
			values[1..-1].each { |val| script.downstream_buffer.push(val) }
		else
			values[1..-1].each { |val| script.unique_buffer.push(val) }
		end
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

def n;    'north';     end
def ne;   'northeast'; end
def e;    'east';      end
def se;   'southeast'; end
def s;    'south';     end
def sw;   'southwest'; end
def w;    'west';      end
def nw;   'northwest'; end
def u;    'up';        end
def up;   'up';	       end
def down; 'down';      end
def d;    'down';      end
def o;    'out';       end
def out;  'out';       end

def move(dir='none', giveup_seconds=30, giveup_lines=30)
	#[LNet]-[Private]-Casis: "You begin to make your way up the steep headland pathway.  Before traveling very far, however, you lose your footing on the loose stones.  You struggle in vain to maintain your balance, then find yourself falling to the bay below!"  (20:35:36)
	#[LNet]-[Private]-Casis: "You smack into the water with a splash and sink far below the surface."  (20:35:50)
	# You approach the entrance and identify yourself to the guard.  The guard checks over a long scroll of names and says, "I'm sorry, the Guild is open to invitees only.  Please do return at a later date when we will be open to the public."
	if dir == 'none'
		echo 'move: no direction given'
		return false
	end

	need_full_hands = false
	tried_open = false
	tried_fix_drag = false
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
		elsif line =~ /^You can't enter .+ and remain hidden or invisible\.|if he can't see you!$|^You can't enter .+ when you can't be seen\.$|^You can't do that without being seen\.$|^How do you intend to get .*? attention\?  After all, no one can see you right now\.$/
			fput 'unhide'
			put_dir.call
		elsif (line == 'You take a few steps towards a rusty doorknob.') and (dir =~ /door/)
			which = [ 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eight', 'ninth', 'tenth', 'eleventh', 'twelfth' ]
			if dir =~ /\b#{which.join('|')}\b/
				dir.sub!(/\b(#{which.join('|')})\b/) { "#{which[which.index($1)+1]}" }
			else
				dir.sub!('door', 'second door')
			end
			put_dir.call
		elsif line =~ /^You can't go there|^You can't swim in that direction\.|^Where are you trying to go\?|^What were you referring to\?|^I could not find what you were referring to\.|^How do you plan to do that here\?|^You take a few steps towards|^You cannot do that\.|^You settle yourself on|^You shouldn't annoy|^You can't go to|^That's probably not a very good idea|^You can't do that|^Maybe you should look|^You are already|^You walk over to|^You step over to|The [\w\s]+ is too far away|You may not pass\.|become impassable\.|prevents you from entering\.|Please leave promptly\.|is too far above you to attempt that\.$|^Uh, yeah\.  Right\.$|^Definitely NOT a good idea\.$|^Your attempt fails|^There doesn't seem to be any way to do that at the moment\.$/
			echo 'move: failed'
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			return false
		elsif line =~ /^An unseen force prevents you\.$|^Sorry, you aren't allowed to enter here\.|^That looks like someplace only performers should go\.|^As you climb, your grip gives way and you fall down|^The clerk stops you from entering the partition and says, "I'll need to see your ticket!"$|^The guard stops you, saying, "Only members of registered groups may enter the Meeting Hall\.  If you'd like to visit, ask a group officer for a guest pass\."$|^An? .*? reaches over and grasps [A-Z][a-z]+ by the neck preventing (?:him|her) from being dragged anywhere\.$|^You'll have to wait, [A-Z][a-z]+ .* locker|^As you move toward the gate, you carelessly bump into the guard|^You attempt to enter the back of the shop, but a clerk stops you.  "Your reputation precedes you!/
			echo 'move: failed'
			fill_hands if need_full_hands
			Script.self.downstream_buffer.unshift(save_stream)
			Script.self.downstream_buffer.flatten!
			# return nil instead of false to show the direction shouldn't be removed from the map database
			return nil
		elsif line =~ /^You grab [A-Z][a-z]+ and try to drag h(?:im|er), but s?he (?:is too heavy|doesn't budge)\.$|^Tentatively, you attempt to swim through the nook\.  After only a few feet, you begin to sink!  Your lungs burn from lack of air, and you begin to panic!  You frantically paddle back to safety!$|^Guards(?:wo)?man [A-Z][a-z]+ stops you and says, "(?:Stop\.|Halt!)  You need to make sure you check in|^You step into the root, but can see no way to climb the slippery tendrils inside\.  After a moment, you step back out\.$|^As you start .*? back to safe ground\.$|^You stumble a bit as you try to enter the pool but feel that your persistence will pay off\.$|^A shimmering field of magical crimson and gold energy flows through the area\.$/
			sleep 1
			waitrt?
			put_dir.call
		elsif line =~ /^Climbing.*(?:plunge|fall)|^Tentatively, you attempt to climb.*(?:fall|slip)|^You start.*but quickly realize|^You.*drop back to the ground|^You leap .* fall unceremoniously to the ground in a heap\.$|^You search for a way to make the climb .*? but without success\.$|^You start to climb .* you fall to the ground|^You attempt to climb .* wrong approach|^You run towards .*? slowly retreat back, reassessing the situation\./
			sleep 1
			waitrt?
			fput 'stand' unless standing?
			waitrt?
			put_dir.call
		elsif line =~ /^You begin to climb up the silvery thread.* you tumble to the ground/
			sleep 0.5
			waitrt?
			fput 'stand' unless standing?
			waitrt?
			if checkleft or checkright
				need_full_hands = true
				empty_hands
			end
			put_dir.call
		elsif line == "You can't do that while engaged!"
			# DragonRealms
			fput 'retreat'
			fput 'retreat'
			put_dir.call
		elsif line == 'You are too injured to be doing any climbing!'
			if (resolve = Spell[9704]) and resolve.known?
				wait_until { resolve.affordable? }
				resove.cast
				put_dir.call
			else
				return nil
			end
		elsif line =~ /^You(?:'re going to| will) have to climb that\./
			dir.gsub!('go', 'climb')
			put_dir.call
		elsif line =~ /^You can't climb that\./
			dir.gsub!('climb', 'go')
			put_dir.call
		elsif line =~ /^You can't drag/
			if tried_fix_drag
				fill_hands if need_full_hands
				Script.self.downstream_buffer.unshift(save_stream)
				Script.self.downstream_buffer.flatten!
				return false
			elsif (dir =~ /^(?:go|climb) .+$/) and (drag_line = reget.reverse.find { |l| l =~ /^You grab .*?(?:'s body)? and drag|^You are now automatically attempting to drag .*? when/ })
				tried_fix_drag = true
				name = (/^You grab (.*?)('s body)? and drag/.match(drag_line).captures.first || /^You are now automatically attempting to drag (.*?) when/.match(drag_line).captures.first)
				target = /^(?:go|climb) (.+)$/.match(dir).captures.first
				fput "drag #{name}"
				dir = "drag #{name} #{target}"
				put_dir.call
			else
				tried_fix_drag = true
				dir.sub!(/^climb /, 'go ')
				put_dir.call
			end
		elsif line =~ /^Maybe if your hands were empty|^You figure freeing up both hands might help\.|^You can't .+ with your hands full\.$|^You'll need empty hands to climb that\.$|^It's a bit too difficult to swim holding|^You will need both hands free for such a difficult task\./
			need_full_hands = true
			empty_hands
			put_dir.call
		elsif line =~ /(?:appears|seems) to be closed\.$|^You cannot quite manage to squeeze between the stone doors\.$/
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
				sleep ($2.to_i - "0.2".to_f)
			else
				sleep "0.3".to_f
			end
			put_dir.call
		elsif line =~ /will have to stand up first|must be standing first|^You'll have to get up first|^But you're already sitting!|^Shouldn't you be standing first|^Try standing up|^Perhaps you should stand up|^Standing up might help|^You should really stand up first/
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
		elsif line =~ /^You flick your hand (?:up|down)wards and focus your aura on your disk, but your disk only wobbles briefly\.$/
			put_dir.call
		elsif line =~ /^You dive into the fast-moving river, but the current catches you and whips you back to shore, wet and battered\.$/
			waitrt?
			put_dir.call
		elsif line == "You don't seem to be able to move to do that."
			30.times { 
				break if clear.include?('You regain control of your senses!')
				sleep "0.1".to_f
			}
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
	if XMLData.mind_text =~ /must rest|saturated/
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
	if XMLData.max_mana == 0
		percent = 100
	else
		percent = ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
	end
	if num.nil?
		percent
	else 
		percent >= num.to_i
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
	if num.nil?
		((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
	else
		((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i >= num.to_i
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
	if XMLData.max_stamina == 0
		percent = 100
	else
		percent = ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
	end
	if num.nil?
		percent
	else
		percent >= num.to_i
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

def cast(spell, target=nil, results_of_interest=nil)
	if spell.class == Spell
		spell.cast(target, results_of_interest)
	elsif ( (spell.class == Fixnum) or (spell.to_s =~ /^[0-9]+$/) ) and (find_spell = Spell[spell.to_i])
		find_spell.cast(target, results_of_interest)
	elsif (spell.class == String) and (find_spell = Spell[spell])
		find_spell.cast(target, results_of_interest)
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
	end
	history = history.split("\n").delete_if { |line| line.nil? or line.empty? or line =~ /^[\r\n\s\t]*$/ }
	if lines.first.kind_of?(Numeric) or lines.first.to_i.nonzero?
		history = history[-([lines.shift.to_i,history.length].min)..-1]
	end
	unless lines.empty? or lines.nil?
		regex = /#{lines.join('|')}/i
		history = history.find_all { |line| line =~ regex }
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
		elsif string =~ /^You.+struggle.+stand/
			clear
			fput 'stand'
			next
		elsif string =~ /stunned|can't do that while|cannot seem|^(?!You rummage).*can't seem|don't seem|Sorry, you may only type ahead/
			if dead?
				echo "You're dead...! You can't do that!"
				sleep 1
				script.downstream_buffer.unshift(string)
				return false
			elsif checkstunned
				while checkstunned
					sleep("0.25".to_f)
				end
			elsif checkwebbed
				while checkwebbed
					sleep("0.25".to_f)
				end
			elsif string =~ /Sorry, you may only type ahead/
				sleep 1
			else
				sleep "0.1".to_f
				script.downstream_buffer.unshift(string)
				return false
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
		$_CLIENTBUFFER_.push("[#{scr}]#{$SEND_CHARACTER}#{$cmd_prefix}#{message}\r\n")
		respond("[#{scr}]#{$SEND_CHARACTER}#{message}\r\n") unless scr.silent
		$_SERVER_.write("#{$cmd_prefix}#{message}\n")
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
		str.split(/\r?\n/).each { |line| Script.new_script_output(line) }
		str = "<output class=\"mono\"/>\r\n#{str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')}<output class=\"\"/>\r\n" if $frontend == 'stormfront'
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
	$fill_hands_actions ||= Array.new
	actions = Array.new
	right_hand = GameObj.right_hand
	left_hand = GameObj.left_hand
	if UserVars.lootsack.nil? or UserVars.lootsack.empty?
		lootsack = nil
	else
		lootsack = GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack.strip)}/i } || GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack).sub(' ', ' .*')}/i }
	end
	other_containers_var = nil
	other_containers = proc {
		if other_containers_var.nil?
			Script.self.want_downstream = false
			Script.self.want_downstream_xml = true
			result = dothistimeout 'inventory containers', 5, /^You are wearing/
			Script.self.want_downstream_xml = false
			Script.self.want_downstream = true
			other_containers_ids = result.scan(/exist="(.*?)"/).flatten - [ lootsack.id ]
			other_containers_var = GameObj.inv.find_all { |obj| other_containers_ids.include?(obj.id) }
		end
		other_containers_var
	}
	if left_hand.id
		waitrt?
		if (left_hand.noun =~ /shield|buckler|targe|heater|parma|aegis|scutum|greatshield|mantlet|pavis|arbalest|bow|crossbow|yumi|arbalest/) and (wear_result = dothistimeout("wear ##{left_hand.id}", 8, /^You .*#{left_hand.noun}|^You can only wear \w+ items in that location\.$|^You can't wear that\.$/)) and (wear_result !~ /^You can only wear \w+ items in that location\.$|^You can't wear that\.$/)
			actions.unshift proc {
				dothistimeout "remove ##{left_hand.id}", 3, /^You|^Remove what\?/
				20.times { break if GameObj.left_hand.id == left_hand.id or GameObj.right_hand.id == left_hand.id; sleep "0.1".to_f }
				if GameObj.right_hand.id == left_hand.id
					dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
				end
			}
		else
			actions.unshift proc {
				dothistimeout "get ##{left_hand.id}", 3, /^You remove|^You reach into|^Get what\?|^You already have/
				20.times { break if (GameObj.left_hand.id == left_hand.id) or (GameObj.right_hand.id == left_hand.id); sleep "0.1".to_f }
				if GameObj.right_hand.id == left_hand.id
					dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
				end
			}
			if lootsack
				result = dothistimeout "put ##{left_hand.id} in ##{lootsack.id}", 4, /^You put|^You slip .*? into|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				if result =~ /^You can't .+ It's closed!$/
					actions.push proc { fput "close ##{lootsack.id}" }
					dothistimeout "open ##{lootsack.id}", 3, /^You open|^That is already open\./
					result = dothistimeout "put ##{left_hand.id} in ##{lootsack.id}", 3, /^You put|^You slip .*? into|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				end
			else
				result = nil
			end
			if result.nil? or result =~ /^Your .*? won't fit in .*?\.$/
				for container in other_containers.call
					result = dothistimeout "put ##{left_hand.id} in ##{container.id}", 4, /^You put|^You slip|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					if result =~ /^You can't .+ It's closed!$/
						actions.push proc { fput "close ##{container.id}" }
						dothistimeout "open ##{container.id}", 3, /^You open|^That is already open\./
						result = dothistimeout "put ##{left_hand.id} in ##{container.id}", 3, /^You put|^You slip|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					end
					break if result =~ /^You put|^You slip/
				end
			end
		end
	end
	if right_hand.id
		waitrt?
		if XMLData.active_spells.keys.include?('Sonic Weapon Song') or XMLData.active_spells.keys.include?('1012')
			type = right_hand.noun
			if (type == 'sword') and right_hand.name =~ /short/
				type = 'short'
			elsif (type.downcase == 'hammer') and right_hand.name =~ /Hammer of Kai/
				type = 'hammer of kai'
			end
			actions.unshift proc {
				if (sonic_weapon_song = Spell[1012]) and sonic_weapon_song.known? and sonic_weapon_song.affordable?
					sonic_weapon_song.cast(type)
				end
			}
			fput 'stop 1012'
		else
			actions.unshift proc {
				dothistimeout "get ##{right_hand.id}", 3, /^You remove|^You reach into|^Get what\?|^You already have/
				20.times { break if GameObj.left_hand.id == right_hand.id or GameObj.right_hand.id == right_hand.id; sleep "0.1".to_f }
				if GameObj.left_hand.id == right_hand.id
					dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
				end
			}
			if lootsack
				result = dothistimeout "put ##{right_hand.id} in ##{lootsack.id}", 4, /^You put|^You slip .*? into|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				if result =~ /^You can't .+ It's closed!$/
					actions.push proc { fput "close ##{lootsack.id}" }
					dothistimeout "open ##{lootsack.id}", 3, /^You open|^That is already open\./
					result = dothistimeout "put ##{right_hand.id} in ##{lootsack.id}", 3, /^You put|^You slip .*? into|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				end
			else
				result = nil
			end
			if result.nil? or result =~ /^Your .*? won't fit in .*?\.$/
				for container in other_containers.call
					result = dothistimeout "put ##{right_hand.id} in ##{container.id}", 4, /^You put|^You slip|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					if result =~ /^You can't .+ It's closed!$/
						actions.push proc { fput "close ##{container.id}" }
						dothistimeout "open ##{container.id}", 3, /^You open|^That is already open\./
						result = dothistimeout "put ##{right_hand.id} in ##{container.id}", 3, /^You put|^You slip|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					end
					break if result =~ /^You put|^You slip/
				end
			end
		end
	end
	$fill_hands_actions.push(actions)
end

def fill_hands
	$fill_hands_actions ||= Array.new
	for action in $fill_hands_actions.pop
		action.call
	end
end

def empty_hand
	$fill_hand_actions ||= Array.new
	actions = Array.new
	right_hand = GameObj.right_hand
	left_hand = GameObj.left_hand
	if UserVars.lootsack.nil? or UserVars.lootsack.empty?
		lootsack = nil
	else
		lootsack = GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack.strip)}/i } || GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack).sub(' ', ' .*')}/i }
	end
	other_containers_var = nil
	other_containers = proc {
		if other_containers_var.nil?
			Script.self.want_downstream = false
			Script.self.want_downstream_xml = true
			result = dothistimeout 'inventory containers', 5, /^You are wearing/
			Script.self.want_downstream_xml = false
			Script.self.want_downstream = true
			other_containers_ids = result.scan(/exist="(.*?)"/).flatten - [ lootsack.id ]
			other_containers_var = GameObj.inv.find_all { |obj| other_containers_ids.include?(obj.id) }
		end
		other_containers_var
	}
	unless (right_hand.id.nil? and ([ Wounds.rightArm, Wounds.rightHand, Scars.rightArm, Scars.rightHand ].max < 3)) or (left_hand.id.nil? and ([ Wounds.leftArm, Wounds.leftHand, Scars.leftArm, Scars.leftHand ].max < 3))
		if right_hand.id and ((!XMLData.active_spells.keys.include?('Sonic Weapon Song') and !XMLData.active_spells.keys.include?('1012')) or ([ Wounds.leftArm, Wounds.leftHand, Scars.leftArm, Scars.leftHand ].max == 3)) and ([ Wounds.rightArm, Wounds.rightHand, Scars.rightArm, Scars.rightHand ].max < 3 or [ Wounds.leftArm, Wounds.leftHand, Scars.leftArm, Scars.leftHand ].max = 3)
			waitrt?
			if XMLData.active_spells.keys.include?('Sonic Weapon Song') or XMLData.active_spells.keys.include?('1012')
				type = right_hand.noun
				if (type == 'sword') and right_hand.name =~ /short/
					type = 'short'
				elsif (type.downcase == 'hammer') and right_hand.name =~ /Hammer of Kai/
					type = 'hammer of kai'
				end
				actions.unshift proc {
					if (sonic_weapon_song = Spell[1012]) and sonic_weapon_song.known? and sonic_weapon_song.affordable?
						sonic_weapon_song.cast(type)
					end
				}
				fput 'stop 1012'
			else
				actions.unshift proc {
					dothistimeout "get ##{right_hand.id}", 3, /^You|^Get what\?|^You already have/
					20.times { break if GameObj.left_hand.id == right_hand.id or GameObj.right_hand.id == right_hand.id; sleep "0.1".to_f }
					if GameObj.left_hand.id == right_hand.id
						dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
					end
				}
				if lootsack
					result = dothistimeout "put ##{right_hand.id} in ##{lootsack.id}", 4, /^You put|^You slip .*? into|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					if result =~ /^You can't .+ It's closed!$/
						actions.push proc { fput "close ##{lootsack.id}" }
						dothistimeout "open ##{lootsack.id}", 3, /^You open|^That is already open\./
						result = dothistimeout "put ##{right_hand.id} in ##{lootsack.id}", 3, /^You put|^You slip .*? into|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					end
				else
					result = nil
				end
				if result.nil? or result =~ /^Your .*? won't fit in .*?\.$/
					for container in other_containers.call
						result = dothistimeout "put ##{right_hand.id} in ##{container.id}", 4, /^You put|^You slip|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
						if result =~ /^You can't .+ It's closed!$/
							actions.push proc { fput "close ##{container.id}" }
							dothistimeout "open ##{container.id}", 3, /^You open|^That is already open\./
							result = dothistimeout "put ##{right_hand.id} in ##{container.id}", 3, /^You put|^You slip|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
						end
						break if result =~ /^You put|^You slip/
					end
				end
			end
		else
			waitrt?
			if (left_hand.noun =~ /shield|buckler|targe|heater|parma|aegis|scutum|greatshield|mantlet|pavis|arbalest|bow|crossbow|yumi|arbalest/) and (wear_result = dothistimeout("wear ##{left_hand.id}", 8, /^You .*#{left_hand.noun}|^You can only wear \w+ items in that location\.$|^You can't wear that\.$/)) and (wear_result !~ /^You can only wear \w+ items in that location\.$|^You can't wear that\.$/)
				actions.unshift proc {
					dothistimeout "remove ##{left_hand.id}", 3, /^You|^Remove what\?/
					20.times { break if GameObj.left_hand.id == left_hand.id or GameObj.right_hand.id == left_hand.id; sleep "0.1".to_f }
					if GameObj.right_hand.id == left_hand.id
						dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
					end
				}
			else
				actions.unshift proc {
					dothistimeout "get ##{left_hand.id}", 3, /^You|^Get what\?|^You already have/
					20.times { break if GameObj.left_hand.id == left_hand.id or GameObj.right_hand.id == left_hand.id; sleep "0.1".to_f }
					if GameObj.right_hand.id == left_hand.id
						dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
					end
				}
				if lootsack
					result = dothistimeout "put ##{left_hand.id} in ##{lootsack.id}", 4, /^You put|^You slip .*? into|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					if result =~ /^You can't .+ It's closed!$/
						actions.push proc { fput "close ##{lootsack.id}" }
						dothistimeout "open ##{lootsack.id}", 3, /^You open|^That is already open\./
						result = dothistimeout "put ##{left_hand.id} in ##{lootsack.id}", 3, /^You put|^You slip .*? into|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					end
				else
					result = nil
				end
				if result.nil? or result =~ /^Your .*? won't fit in .*?\.$/
					for container in other_containers.call
						result = dothistimeout "put ##{left_hand.id} in ##{container.id}", 4, /^You put|^You slip|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
						if result =~ /^You can't .+ It's closed!$/
							actions.push proc { fput "close ##{container.id}" }
							dothistimeout "open ##{container.id}", 3, /^You open|^That is already open\./
							result = dothistimeout "put ##{left_hand.id} in ##{container.id}", 3, /^You put|^You slip|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
						end
						break if result =~ /^You put|^You slip/
					end
				end
			end
		end
	end
	$fill_hand_actions.push(actions)
end

def fill_hand
	$fill_hand_actions ||= Array.new
	for action in $fill_hand_actions.pop
		action.call
	end
end

def empty_right_hand
	$fill_right_hand_actions ||= Array.new
	actions = Array.new
	right_hand = GameObj.right_hand
	if UserVars.lootsack.nil? or UserVars.lootsack.empty?
		lootsack = nil
	else
		lootsack = GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack.strip)}/i } || GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack).sub(' ', ' .*')}/i }
	end
	other_containers_var = nil
	other_containers = proc {
		if other_containers_var.nil?
			Script.self.want_downstream = false
			Script.self.want_downstream_xml = true
			result = dothistimeout 'inventory containers', 5, /^You are wearing/
			Script.self.want_downstream_xml = false
			Script.self.want_downstream = true
			other_containers_ids = result.scan(/exist="(.*?)"/).flatten - [ lootsack.id ]
			other_containers_var = GameObj.inv.find_all { |obj| other_containers_ids.include?(obj.id) }
		end
		other_containers_var
	}
	if right_hand.id
		waitrt?
		if XMLData.active_spells.keys.include?('Sonic Weapon Song') or XMLData.active_spells.keys.include?('1012')
			type = right_hand.noun
			if (type == 'sword') and right_hand.name =~ /short/
				type = 'short'
			elsif (type.downcase == 'hammer') and right_hand.name =~ /Hammer of Kai/
				type = 'hammer of kai'
			end
			actions.unshift proc {
				if (sonic_weapon_song = Spell[1012]) and sonic_weapon_song.known? and sonic_weapon_song.affordable?
					sonic_weapon_song.cast(type)
				end
			}
			fput 'stop 1012'
		else
			actions.unshift proc {
				dothistimeout "get ##{right_hand.id}", 3, /^You|^Get what\?|^You already have/
				20.times { break if GameObj.left_hand.id == right_hand.id or GameObj.right_hand.id == right_hand.id; sleep "0.1".to_f }
				if GameObj.left_hand.id == right_hand.id
					dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
				end
			}
			if lootsack
				result = dothistimeout "put ##{right_hand.id} in ##{lootsack.id}", 4, /^You put|^You slip .*? into|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				if result =~ /^You can't .+ It's closed!$/
					actions.push proc { fput "close ##{lootsack.id}" }
					dothistimeout "open ##{lootsack.id}", 3, /^You open|^That is already open\./
					result = dothistimeout "put ##{right_hand.id} in ##{lootsack.id}", 3, /^You put|^You slip .*? into|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				end
			else
				result = nil
			end
			if result.nil? or result =~ /^Your .*? won't fit in .*?\.$/
				for container in other_containers.call
					result = dothistimeout "put ##{right_hand.id} in ##{container.id}", 4, /^You put|^You slip|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					if result =~ /^You can't .+ It's closed!$/
						actions.push proc { fput "close ##{container.id}" }
						dothistimeout "open ##{container.id}", 3, /^You open|^That is already open\./
						result = dothistimeout "put ##{right_hand.id} in ##{container.id}", 3, /^You put|^You slip|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					end
					break if result =~ /^You put|^You slip/
				end
			end
		end
	end
	$fill_right_hand_actions.push(actions)
end

def fill_right_hand
	$fill_right_hand_actions ||= Array.new
	for action in $fill_right_hand_actions.pop
		action.call
	end
end

def empty_left_hand
	$fill_left_hand_actions ||= Array.new
	actions = Array.new
	left_hand = GameObj.left_hand
	if UserVars.lootsack.nil? or UserVars.lootsack.empty?
		lootsack = nil
	else
		lootsack = GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack.strip)}/i } || GameObj.inv.find { |obj| obj.name =~ /#{Regexp.escape(UserVars.lootsack).sub(' ', ' .*')}/i }
	end
	other_containers_var = nil
	other_containers = proc {
		if other_containers_var.nil?
			Script.self.want_downstream = false
			Script.self.want_downstream_xml = true
			result = dothistimeout 'inventory containers', 5, /^You are wearing/
			Script.self.want_downstream_xml = false
			Script.self.want_downstream = true
			other_containers_var = result.scan(/exist="(.*?)"/) - [ lootsack.id ]
		end
		other_containers_var
	}
	if left_hand.id
		waitrt?
		if (left_hand.noun =~ /shield|buckler|targe|heater|parma|aegis|scutum|greatshield|mantlet|pavis|arbalest|bow|crossbow|yumi|arbalest/) and (wear_result = dothistimeout("wear ##{left_hand.id}", 8, /^You .*#{left_hand.noun}|^You can only wear \w+ items in that location\.$|^You can't wear that\.$/)) and (wear_result !~ /^You can only wear \w+ items in that location\.$|^You can't wear that\.$/)
			actions.unshift proc {
				dothistimeout "remove ##{left_hand.id}", 3, /^You|^Remove what\?/
				20.times { break if GameObj.left_hand.id == left_hand.id or GameObj.right_hand.id == left_hand.id; sleep "0.1".to_f }
				if GameObj.right_hand.id == left_hand.id
					dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
				end
			}
		else
			actions.unshift proc {
				dothistimeout "get ##{left_hand.id}", 3, /^You|^Get what\?|^You already have/
				20.times { break if GameObj.left_hand.id == left_hand.id or GameObj.right_hand.id == left_hand.id; sleep "0.1".to_f }
				if GameObj.right_hand.id == left_hand.id
					dothistimeout 'swap', 3, /^You don't have anything to swap!|^You swap/
				end
			}
			if lootsack
				result = dothistimeout "put ##{left_hand.id} in ##{lootsack.id}", 4, /^You put|^You slip .*? into|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				if result =~ /^You can't .+ It's closed!$/
					actions.push proc { fput "close ##{lootsack.id}" }
					dothistimeout "open ##{lootsack.id}", 3, /^You open|^That is already open\./
					dothistimeout "put ##{left_hand.id} in ##{lootsack.id}", 3, /^You put|^You slip .*? into|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
				end
			else
				result = nil
			end
			if result.nil? or result =~ /^Your .*? won't fit in .*?\.$/
				for container in other_containers.call
					result = dothistimeout "put ##{left_hand.id} in ##{container.id}", 4, /^You put|^You slip|^You can't .+ It's closed!$|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					if result =~ /^You can't .+ It's closed!$/
						actions.push proc { fput "close ##{container.id}" }
						dothistimeout "open ##{container.id}", 3, /^You open|^That is already open\./
						result = dothistimeout "put ##{left_hand.id} in ##{container.id}", 3, /^You put|^You slip|^I could not find what you were referring to\.|^Your .*? won't fit in .*?\.$/
					end
					break if result =~ /^You put|^You slip/
				end
			end
		end
	end
	$fill_left_hand_actions.push(actions)
end

def fill_left_hand
	$fill_left_hand_actions ||= Array.new
	for action in $fill_left_hand_actions.pop
		action.call
	end
end

def dothis (action, success_line)
	loop {
		Script.self.clear
		put action
		loop {
			line = get
			if line =~ success_line
				return line
			elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
				if $2.to_i > 1
					sleep ($2.to_i - "0.5".to_f)
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
						sleep "0.1".to_f
					else
						break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
					end
				}
				break
			elsif line == "You don't seem to be able to move to do that."
				100.times {
					unless line = get?
						sleep "0.1".to_f
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
						sleep "0.1".to_f
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
	end_time = Time.now.to_f + timeout
	line = nil
	loop {
		Script.self.clear
		put action unless action.nil?
		loop {
			line = get?
			if line.nil?
				sleep "0.1".to_f
			elsif line =~ success_line
				return line
			elsif line =~ /^(\.\.\.w|W)ait ([0-9]+) sec(onds)?\.$/
				if $2.to_i > 1
					sleep ($2.to_i - "0.5".to_f)
				else
					sleep "0.3".to_f
				end
				end_time = Time.now.to_f + timeout
				break
			elsif line == 'Sorry, you may only type ahead 1 command.'
				sleep 1
				end_time = Time.now.to_f + timeout
				break
			elsif line == 'You are still stunned.'
				wait_while { stunned? }
				end_time = Time.now.to_f + timeout
				break
			elsif line == 'That is impossible to do while unconscious!'
				100.times {
					unless line = get?
						sleep "0.1".to_f
					else
						break if line =~ /Your thoughts slowly come back to you as you find yourself lying on the ground\.  You must have been sleeping\.$|^You wake up from your slumber\.$/
					end
				}
				break
			elsif line == "You don't seem to be able to move to do that."
				100.times {
					unless line = get?
						sleep "0.1".to_f
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
						sleep "0.1".to_f
					else
						# fixme
						break if line == 'You shake off the effects of the lullabye.'
					end
				}
				break
			end
			if Time.now.to_f >= end_time
				return nil
			end
		}
	}
end

def registry_get(key)
	if $SAFE == 0
		if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
			path = /^(.*)\\.*?$/.match(key).captures.first.split("\\")
			value = /^.*\\(.*?)$/.match(key).captures.first
			begin
				advapi32 = DL.dlopen('advapi32.dll')
				reg_open_key_ex = advapi32['RegOpenKeyEx', 'LLSLLP']
				reg_query_value_ex = advapi32['RegQueryValueEx', 'LLSLPPP']
				kernel32 = DL.dlopen('kernel32.dll')
				close_handle = kernel32['CloseHandle', 'LL']
				keys = Array.new
				if path[0].downcase == 'hkey_classes_root'
					keys.push -2147483648
				elsif path[0].downcase == 'hkey_current_user'
					keys.push -2147483647
				elsif path[0].downcase == 'hkey_local_machine'
					keys.push -2147483646
				elsif path[0].downcase == 'hkey_users'
					keys.push -2147483645
				else
					raise "bad top level key: #{key}"
				end
				path[1..-1].each { |key|
					new_key = DL.malloc(DL.sizeof('L'))
					new_key.struct!('L', :data)
					result = reg_open_key_ex.call(keys[-1], key, 0, 131097, new_key) # 131097 = KEY_READ
					unless result.first == 0
						raise "failed to open key: #{key}"
					end
					keys.push(new_key[:data])
				}
				type = DL.malloc(DL.sizeof('L'))
				buffer = DL.malloc(DL.sizeof('C256'))
				buffer.struct!('C256', :data)
				size = DL.malloc(DL.sizeof('L'))
				size.struct!('L', :data)
				size[:data] = 256
				result = reg_query_value_ex.call(keys.last, value, 0, type, buffer, size)
				unless result.first == 0
					raise "failed to read value '#{value}' from key '#{path[-1]}'"
				end
				buffer[:data][0..size[:data]].collect { |char| char.chr }.join('').sub(/\0.*/, '')
			rescue
				$stderr.puts $!
				$stderr.puts $!.backtrace[0..1]
				nil
			ensure
				keys[1..-1].each { |key| close_handle.call(key) rescue() }
			end
		else
			hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures
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
					subkey = "[#{subkey.gsub('\\', '\\\\\\')}]"
					if thingie.nil? or thingie.empty?
						thingie = '@'
					else
						thingie = "\"#{thingie}\""
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
	else
		nil
	end
end

def registry_put(key, value)
	if $SAFE == 0
		if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
			path = key.split("\\")
			path.push('') if key =~ /\\$/
			value.concat("\0")
			begin
				advapi32 = DL.dlopen('advapi32.dll')
				reg_open_key_ex = advapi32['RegOpenKeyEx', 'LLSLLP']
				reg_set_value_ex = advapi32['RegSetValueEx', 'LLSLLPL']
				kernel32 = DL.dlopen('kernel32.dll')
				close_handle = kernel32['CloseHandle', 'LL']
				keys = Array.new
				if path[0].downcase == 'hkey_classes_root'
					keys.push -2147483648
				elsif path[0].downcase == 'hkey_current_user'
					keys.push -2147483647
				elsif path[0].downcase == 'hkey_local_machine'
					keys.push -2147483646
				elsif path[0].downcase == 'hkey_users'
					keys.push -2147483645
				else
					raise "bad top level key: #{key}"
				end
				path[1..-2].each_with_index { |key,index|
					new_key = DL.malloc(DL.sizeof('L'))
					new_key.struct!('L', :data)
					result = reg_open_key_ex.call(keys[-1], key, 0, 983103, new_key) # 983103 = KEY_ALL_ACCESS
					unless result.first == 0
						raise "failed to open key: #{key} (#{result.first})"
					end
					keys.push(new_key[:data])
				}
				result = reg_set_value_ex.call(keys.last, path[-1], 0, 1, value, DL.sizeof("C#{value.length+1}")) # 1 = REG_SZ
				if result.first == 0
					true
				else
					raise "failed to write to key '#{path[-1]}' (#{result.first})"
				end
			rescue
				$stderr.puts $!
				$stderr.puts $!.backtrace[0..1]
				false
			ensure
				keys[1..-1].each { |key| close_handle.call(key) rescue() }
			end
		else
			hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures
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
					thingie = "\"#{thingie}\""
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
	else
		false
	end
end

def find_hosts_dir
	if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
		if hosts_dir = registry_get('HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Services\\Tcpip\\Parameters\\DataBasePath')
			heal_hosts
			return hosts_dir.gsub(/%SystemRoot%/, windir)
		elsif hosts_dir = registry_get('HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\DataBasePath')
			heal_hosts
			return hosts_dir.gsub(/%SystemRoot%/, windir)
		else
			test_dirs = Array.new
			if windir = ENV['windir'] || ENV['SYSTEMROOT']
				test_dirs.push "#{windir}\\system32\\drivers\\etc\\" # winxp
				test_dirs.push "#{windir}\\" # win98
			end
			if prefix = /(C|D|E|F|G|H)/.match(Dir.pwd.to_s[0..1]).captures.first
				test_dirs.push "#{prefix}:\\winnt\\system32\\drivers\\etc\\"   # winxp_pro
				test_dirs.push "#{prefix}:\\windows\\system32\\drivers\\etc\\" # winxp_home
				test_dirs.push "#{prefix}:\\windows\\"                         # win98
				if prefix != 'C:'
					test_dirs.push "C:\\winnt\\system32\\drivers\\etc\\"   # winxp_pro
					test_dirs.push "C:\\windows\\system32\\drivers\\etc\\" # winxp_home
					test_dirs.push "C:\\windows\\"                         # win98
				end
			end
		end
	else
		test_dirs = [ '/etc/', '/private/etc/' ]
	end
	test_dirs.each { |dir|
		if File.exists?("#{dir}hosts.bak") or File.exists?("#{dir}hosts")
			heal_hosts(dir)
			return dir
		end
	}
	return nil
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

$link_highlight_start = ''
$link_highlight_end = ''
$speech_highlight_start = ''
$speech_highlight_end = ''

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
		if line =~ /<LaunchURL src="(.*?)" \/>/
			$_CLIENT_.puts "\034GSw00005\r\nhttps://www.play.net#{$1}\r\n"
		end
		if line =~ /<preset id='speech'>(.*?)<\/preset>/m
			line = line.sub(/<preset id='speech'>.*?<\/preset>/m, "#{$speech_highlight_start}#{$1}#{$speech_highlight_end}")
		end
		if line =~ /<pushStream id="thoughts"[^>]*>(?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\s*([\s\[\]\(\)A-z]+)?:(.*?)<popStream\/>/m
			line = line.sub(/<pushStream id="thoughts"[^>]*>(?:<a[^>]*>)?[A-Z][a-z]+(?:<\/a>)?\s*[\s\[\]\(\)A-z]+:.*?<popStream\/>/m, "You hear the faint thoughts of #{$1} echo in your mind:\r\n#{$2}#{$3}")
		end
		if line =~ /<pushStream id="voln"[^>]*>\[Voln \- (?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\]\s*(".*")[\r\n]*<popStream\/>/m
			line = line.sub(/<pushStream id="voln"[^>]*>\[Voln \- (?:<a[^>]*>)?([A-Z][a-z]+)(?:<\/a>)?\]\s*(".*")[\r\n]*<popStream\/>/m, "The Symbol of Thought begins to burn in your mind and you hear #{$1} thinking, #{$2}\r\n")
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
		line.gsub!(/<style id="roomDesc"\/><style id=""\/>\r?\n/, '')
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
	if $frontend =~ /^(?:wizard|avalon)$/
		"\034GSL\r\n"
	elsif $frontend == 'stormfront'
		'<pushBold/>'
	else
		''
	end
end

def monsterbold_end
	if $frontend =~ /^(?:wizard|avalon)$/
		"\034GSM\r\n"
	elsif $frontend == 'stormfront'
		'<popBold/>'
	else
		''
	end
end

def install_to_registry(psinet_compatible = false)
	Dir.chdir(File.dirname($PROGRAM_NAME))
	launch_cmd = registry_get('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\')
	launch_dir = registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory')
	return false unless launch_cmd or launch_dir
	if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
		if ruby_dir = ($:).find { |path| File.exists?("#{path}/../../../bin/rubyw.exe") }
			ruby_dir = "#{ruby_dir.scan(/[^\/]+/)[0..-4].join('\\')}\\bin\\"
		elsif ruby_dir = ($:).find { |path| File.exists?("#{path}/../../../../bin/rubyw.exe") }
			ruby_dir = "#{ruby_dir.scan(/[^\/]+/)[0..-5].join('\\')}\\bin\\"
		else
			ruby_dir = String.new
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
			registry_put('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand', launch_cmd) || result = false
			registry_put('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\', lich_launch_cmd) || result = false
		end
	end
	if launch_dir
		if launch_dir =~ /lich/i
			$stdout.puts "--- warning: Lich appears to already be installed to the registry"
			$stderr.puts "warning: Lich appears to already be installed to the registry"
			$stderr.puts 'info: launch_dir: ' + launch_dir
		else
			registry_put('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory', launch_dir) || result = false
			registry_put('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory', lich_launch_dir) || result = false
		end
	end
	unless (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
		wine = `which wine`.strip
		if File.exists?(wine)
			registry_put('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Wine', wine)
		end
	end
	return result
end

def uninstall_from_registry
	real_launch_cmd = registry_get('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand')
	real_launch_dir = registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory')
	unless (real_launch_cmd and not real_launch_cmd.empty?) or (real_launch_dir and not real_launch_dir.empty?)
		$stdout.puts "--- warning: Lich does not appear to be installed to the registry"
		$stderr.puts "warning: Lich does not appear to be installed to the registry"
		return false
	end
	result = true
	if real_launch_cmd and not real_launch_cmd.empty?
		registry_put('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\', real_launch_cmd) || result = false
		registry_put('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand', '') || result = false
	end
	if real_launch_dir and not real_launch_dir.empty?
		registry_put('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory', real_launch_dir) || result = false
		registry_put('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory', '') || result = false
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
			elsif action =~ /^(?:k|kill|stop)$/
				script.kill
				begin
					GC.start
				rescue
					respond('--- Lich: Error starting garbage collector. (3)')
				end
			elsif action =~/^(?:p|pause)$/
				script.pause
			elsif action =~/^(?:u|unpause)$/
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
			force_start_script(script_name, vars, flags={:command_line => client_string})
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
				start_exec_script(cmd_data, flags={ :quiet => false, :trusted => true })
			else
				start_exec_script(cmd_data, flags={ :quiet => true, :trusted => true })
			end
		elsif cmd =~ /^favs?(?: |$)(.*)?/i
			args = $1.split(' ')
			if (args[0].downcase == 'add') and (args[1] =~ /^all$|^global$/i) and not args[2].nil?
				Favs.add(args[2], args[3..-1], :global)
				respond "--- Lich: added #{args[2]} to the global favs list."
			elsif (args[0].downcase == 'add') and not args[1].nil?
				Favs.add(args[1], args[2..-1], :char)
				respond "--- Lich: added #{args[1]} to #{XMLData.name}'s favs list."
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (args[1] =~ /^all$|^global$/i) and not args[2].nil?
				if Favs.delete(args[2], :global)
					respond "--- Lich: removed #{args[2]} from the global favs list."
				else
					respond "--- Lich: #{args[2]} was not found in the global favs list."
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and not args[1].nil?
				if Favs.delete(args[1], :char)
					respond "--- Lich: removed #{args[1]} from #{XMLData.name}'s favs list."
				else
					respond "--- Lich: #{args[1]} was not found in #{XMLData.name}'s favs list."
				end
			elsif args[0].downcase == 'list'
				favs = Favs.list
				if favs['global'].empty?
					global_favs = '(none)'
				else
					global_favs = favs['global'].keys.join(', ')
				end
				if favs[XMLData.name].empty?
					char_favs = '(none)'
				else
					char_favs = favs[XMLData.name].keys.join(', ')
				end
				respond "--- Lich: Global favs: #{global_favs}"
				respond "--- Lich: #{XMLData.name}'s favs: #{char_favs}"
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
				respond "--- Lich: added (#{trigger} => #{target}) to #{XMLData.name}'s alias list."
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (args[1] =~ /^all$|^global$/i) and not args[2].nil?
				if Alias.delete(args[2], :global)
					respond "--- Lich: removed #{args[2]} from the global alias list."
				else
					respond "--- Lich: #{args[2]} was not found in the global alias list."
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and not args[1].nil?
				if Alias.delete(args[1], :char)
					respond "--- Lich: removed #{args[1]} from #{XMLData.name}'s alias list."
				else
					respond "--- Lich: #{args[1]} was not found in #{XMLData.name}'s alias list."
				end
			elsif args[0].downcase == 'list'
				alist = Alias.list
				if alist['global'].empty? and alist[XMLData.name].empty?
					respond "\n--- You currently have no Lich aliases.\n"
				end
				unless alist['global'].empty?
					respond '--- Global aliases'
					alist['global'].to_a.sort { |a,b| a[0] <=> b[0] }.each { |a| respond "   #{a[0]} => #{a[1]}" }
				end
				unless alist[XMLData.name].empty?
					respond "--- #{XMLData.name}'s aliases"
					alist[XMLData.name].to_a.sort { |a,b| a[0] <=> b[0] }.each { |a| respond "   #{a[0]} => #{a[1]}" }
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
				respond "--- Lich: #{XMLData.name}'s setting changed (#{var_name}: #{value})"
			elsif (args[0].downcase == 'add') and (args[1] =~ /^all$|^global$/i) and (var_name = args[2]) and (value = args[3..-1].join(' '))
				UserVars.add(var_name, value, :global)
				respond "--- Lich: added to global setting (#{var_name}: #{value})"
			elsif (args[0].downcase == 'add') and (var_name = args[1]) and (value = args[2..-1].join(' '))
				UserVars.add(var_name, value, :char)
				respond "--- Lich: added to #{XMLData.name}'s setting (#{var_name}: #{value})"
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (args[1] =~ /^all$|^global$/i) and (var_name = args[2]) and args[3]
				rem_value = args[3..-1].join(' ')
				echo rem_value.inspect
				value = UserVars.list_global[var_name].to_s.split(', ')
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
				value = UserVars.list_char[var_name].to_s.split(', ')
				if value.delete(rem_value)
					UserVars.change(var_name, value.join(', '), :char)
					respond "--- Lich: removed '#{rem_value}' from #{XMLData.name}'s setting '#{var_name}'"
				else
					respond "--- Lich: could not find '#{rem_value}' in #{XMLData.name}'s setting '#{var_name}'"
				end
			elsif (args[0] =~ /^rem(?:ove)$|^del(?:ete)?$/i) and (var_name = args[1])
				if UserVars.delete(var_name, :char)
					respond "--- Lich: removed #{XMLData.name}'s setting '#{var_name}'"
				else
					respond "--- Lich: could not find #{XMLData.name}'s setting '#{var_name}'"
				end
			elsif args[0].downcase == 'list'
				global_vars = UserVars.list_global
				char_vars = UserVars.list_char
				if global_vars.empty? and char_vars.empty?
					respond "\n--- You currently have no Lich settings.\n"
				end
				unless global_vars.empty?
					respond '--- Global settings'
					global_vars.each_pair { |name,value|
						respond "   #{name}: #{if value.class == String; value; else; value.inspect; end}"
					}
				end
				unless char_vars.empty?
					respond "--- #{XMLData.name}'s settings"
					char_vars.each_pair { |name,value|
						respond "   #{name}: #{if value.class == String; value; else; value.inspect; end}"
					}
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
		elsif cmd =~ /^trust\s+(.*)/i
			script_name = $1
			if File.exists?("#{$script_dir}#{script_name}.lic")
				LichSettings['trusted_scripts'] ||= Array.new
				LichSettings['trusted_scripts'].push(script_name) unless LichSettings['trusted_scripts'].include?(script_name)
				LichSettings.save
				respond "--- Lich: '#{script_name}' is now a trusted script."
			else
				respond "--- Lich: could not find script: #{script_name}"
			end
		elsif cmd =~ /^distrust\s+(.*)/i
			script_name = $1
			if LichSettings['trusted_scripts'].delete(script_name)
				LichSettings.save
				respond "--- Lich: '#{script_name}' is no longer a trusted script."
			else
				respond "--- Lich: '#{script_name}' was not found in the trusted script list."
			end
		elsif cmd =~ /^list\s?(?:un)?trust(?:ed)?$|^lt$/i
			if LichSettings['trusted_scripts'].nil? or LichSettings['untrusted_scripts'].empty?
				respond "--- Lich: no scripts are trusted"
			else
				respond "--- Lich: trusted scripts: #{LichSettings['trusted_scripts'].join(', ')}"
			end
		elsif cmd =~ /^help$/i
			respond
			respond "Lich v#{$version}"
			respond
			respond 'built-in commands:'
			respond "   #{$clean_lich_char}<script name>             start a script"
			respond "   #{$clean_lich_char}force <script name>       start a script even if it's already running"
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
			respond "   #{$clean_lich_char}list                      show running scripts (except hidden ones)"
			respond "   #{$clean_lich_char}l                         ''"
			respond "   #{$clean_lich_char}pause all                 pause all scripts"
			respond "   #{$clean_lich_char}pa                        ''"
			respond "   #{$clean_lich_char}unpause all               unpause all scripts"
			respond "   #{$clean_lich_char}ua                        ''"
			respond "   #{$clean_lich_char}kill all                  kill all scripts"
			respond "   #{$clean_lich_char}ka                        ''"
			respond "   #{$clean_lich_char}list all                  show all running scripts"
			respond "   #{$clean_lich_char}la                        ''"
			respond
			respond "   #{$clean_lich_char}exec <code>               executes the code as if it was in a script"
			respond "   #{$clean_lich_char}e <code>                  ''"
			respond "   #{$clean_lich_char}execq <code>              same as #{$clean_lich_char}exec but without the script active and exited messages"
			respond "   #{$clean_lich_char}eq <code>                 ''"
			respond
			respond "   #{$clean_lich_char}trust <script name>       let the script do whatever it wants"
			respond "   #{$clean_lich_char}distrust <script name>    restrict the script from doing things that might harm your computer"
			respond "   #{$clean_lich_char}list trusted              show what scripts are trusted"
			respond "   #{$clean_lich_char}lt                        ''"
			respond
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
			respond "   #{$clean_lich_char}setting add [global] <setting name> <value>"
			respond "   #{$clean_lich_char}setting change [global] <setting name> <value>"
			respond "   #{$clean_lich_char}setting delete [global] <setting name> [value]"
			respond "   #{$clean_lich_char}setting list"
			respond
			respond 'If you liked this help message, you might also enjoy:'
			respond "   #{$clean_lich_char}lnet help"
			respond "   #{$clean_lich_char}magic help     (infomon must be running)"
			respond "   #{$clean_lich_char}go2 help"
			respond "   #{$clean_lich_char}repository help"
			respond "   #{$clean_lich_char}updater help"
			respond
		else
			script_name = Regexp.escape(cmd.split.first.chomp)
			vars = cmd.split[1..-1].join(' ').scan(/"[^"]+"|[^"\s]+/).collect { |val| val.gsub(/(?!\\)?"/,'') }
			start_script(script_name, vars, flags={:command_line => client_string})
		end
	else
		if $offline_mode
			respond "--- Lich: offline mode: ignoring #{client_string}"
		else
			client_string = "#{$cmd_prefix}bbs\n" if ($frontend =~ /^(?:wizard|avalon)$/) and (client_string == "#{$cmd_prefix}\egbbk\n") # launch forum
			$_SERVER_.puts client_string
		end
		$_CLIENTBUFFER_.push client_string
	end
	Script.new_upstream(client_string)
end

def report_errors(&block)
	begin
		block.call
	rescue
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue SyntaxError
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue SystemExit
		nil
	rescue SecurityError
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue ThreadError
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue SystemStackError
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue Exception
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue ScriptError
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue LoadError
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue NoMemoryError
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	rescue
		respond "--- error: #{$!}"
		respond $!.backtrace[0..1]
		$stderr.puts "--- error: #{$!}"
		$stderr.puts $!.backtrace
	end
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
	launcher_cmd = registry_get('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand')
	psinet_dir = $1 if launcher_cmd =~ /^"?(.*?)PsiNet2.exe/i
	unless (launcher_cmd =~ /launcher\.exe(?: |")/i)
		launcher_cmd = registry_get('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\')
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
	if (gamehost == 'gs-plat.simutronics.net') and (gameport.to_i == 10121)
		gamehost = 'storm.gs4.game.play.net'
		gameport = 10124
	elsif (gamehost == 'gs3.simutronics.net') and (gameport.to_i == 4900)
		gamehost = 'storm.gs4.game.play.net'
		gameport = 10024
	elsif (gamehost == 'gs4.simutronics.net') and (gameport.to_i == 10321)
		game_host = 'storm.gs4.game.play.net'
		game_port = 10324
	elsif (gamehost == 'prime.dr.game.play.net') and (gameport.to_i == 4901)
		gamehost = 'dr.simutronics.net'
		gameport = 11024
	end
	[ gamehost, gameport ]
}

break_game_host_port = proc { |gamehost,gameport|
	if (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10324)
		gamehost = 'gs4.simutronics.net'
		gameport = 10321
	elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10124)
		gamehost = 'gs-plat.simutronics.net'
		gameport = 10121
	elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10024)
		gamehost = 'gs3.simutronics.net'
		gameport = 4900
	elsif (gamehost == 'storm.gs4.game.play.net') and (gameport.to_i == 10324)
		game_host = 'gs4.simutronics.net'
		game_port = 10321
	elsif (gamehost == 'dr.simutronics.net') and (gameport.to_i == 11024)
		gamehost = 'prime.dr.game.play.net'
		gameport = 4901
	end
	[ gamehost, gameport ]
}

get_process_list = proc {
	begin
		if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
			process_query_information = 1024
			process_vm_read = 16
			max_list_size = 100
			access = process_query_information | process_vm_read
			kernel32 = DL.dlopen('kernel32.dll')
			open_process = kernel32['OpenProcess', 'LLLL']
			begin
				psapi = DL.dlopen('psapi.dll')
				enum_processes = psapi['EnumProcesses', 'LPLP']
				get_module_filename_ex = psapi['GetModuleFileNameEx', 'LLLPL']
			rescue
				enum_processes = kernel32['EnumProcesses', 'LPLP']
				get_module_filename_ex = kernel32['GetModuleFileNameEx', 'LLLPL']
			end
			process_ids = DL.malloc(DL.sizeof('L')*max_list_size)
			size = DL.malloc(DL.sizeof('L'))
			buffer = DL.malloc(DL.sizeof('C256'))
			result = enum_processes.call(process_ids, DL.sizeof('L')*max_list_size, size)
			process_list = Array.new
			process_ids.to_a('L')[0...(size.to_a('L')[0]/DL.sizeof('L'))].each { |id|
				handle = open_process.call(access, 0, id)
				unless handle[0] == 0
					result = get_module_filename_ex.call(handle[0], 0, buffer, 255)
					process_list.push buffer.to_s
				end
			}
			process_list
		else
			`ps xo command`.split("\n")[1..-1]
		end
	rescue
		$stderr.puts "error: #{$!}"
		Array.new
	end
}

is_windows = proc {
	(RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
}

windows_version = proc {
	if is_windows.call
		kernel32 = DL.dlopen('kernel32.dll')
		get_version_ex = kernel32['GetVersionEx', 'LP']

		os_version_info = DL.malloc(DL.sizeof('LLLLLC128'))
		os_version_info.struct!('LLLLLC128', :dwOSVersionInfoSize, :dwMajorVersion, :dwMinorVersion, :dwBuildNumber, :dwPlatformId, :szCSDVersion)
		os_version_info[:dwOSVersionInfoSize] = DL.sizeof('LLLLLC128')
		get_version_ex.call(os_version_info)
		[os_version_info[:dwMajorVersion], os_version_info[:dwMinorVersion]]
	else
		[0,0]
	end
}

is_win_vista = proc {
	ver = windows_version.call
	(ver[0] == 6) and (ver[1] == 0)
}

is_win7 = proc {
	ver = windows_version.call
	(ver[0] == 6) and (ver[1] == 1)
}

is_win8 = proc {
	ver = windows_version.call
	(ver[0] == 6) and (ver[1] == 2)
}

is_win8 = proc {
	if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
		begin
			kernel32 = DL.dlopen('kernel32.dll')
			get_version_ex = kernel32['GetVersionEx', 'LP']

			os_version_info = DL.malloc(DL.sizeof('LLLLLC128'))
			os_version_info.struct!('LLLLLC128', :dwOSVersionInfoSize, :dwMajorVersion, :dwMinorVersion, :dwBuildNumber, :dwPlatformId, :szCSDVersion)
			os_version_info[:dwOSVersionInfoSize] = DL.sizeof('LLLLLC128')
			get_version_ex.call(os_version_info)

			$stderr.puts "info: Windows version: #{os_version_info[:dwMajorVersion]}.#{os_version_info[:dwMinorVersion]}"

			if (os_version_info[:dwMajorVersion] == 6) and (os_version_info[:dwMinorVersion] >= 2)
				true
			else
				false
			end
		rescue
			false
		end
	else
		false
	end
}

shell_execute_ex = proc { |verb,dir,file,param|
	if is_windows.call
		shell_execute_info = DL.malloc(DL.sizeof('LLLSSSSLLLSLLLL'))
		shell_execute_info.struct!('LLLSSSSLLLSLLLL', :cbSize, :fMask, :hwnd, :lpVerb, :lpFile, :lpParameters, :lpDirectory, :nShow, :hInstApp, :lpIDList, :lpClass, :hkeyClass, :dwHotKey, :hIcon, :hProcess)
		shell_execute_info[:cbSize] = DL.sizeof('LLLSSSSLLLSLLLL')
		shell_execute_info[:fMask] = 0
		shell_execute_info[:hwnd] = 0
		shell_execute_info[:lpVerb] = verb
		shell_execute_info[:lpParameters] = param
		shell_execute_info[:lpDirectory] = dir
		shell_execute_info[:lpFile] = file
		shell_execute_info[:nShow] = 1
		shell_execute_info[:hInstApp] = 0
		shell_execute_info[:lpIDList] = 0
		shell_execute_info[:lpClass] = ""
		shell_execute_info[:hkeyClass] = 0
		shell_execute_info[:dwHotKey] = 0 
		shell_execute_info[:hIcon] =  0
		shell_execute_info[:hProcess] = 0

		shell32 = DL.dlopen('shell32.dll')
		api = shell32['ShellExecuteEx', 'LP']
		api.call(shell_execute_info)
	else
		false
	end
}

system_win8fix = proc { |launcher_cmd|
	# fixme: launcher_cmd may not have quotes
	if is_win8.call and launcher_cmd =~ /^"(.*?)"\s*(.*)$/
		dir_file = $1
		param = $2
		dir = dir_file.slice(/^.*[\/\\]/)
		file = dir_file.sub(/^.*[\/\\]/, '')
		$stderr.puts "info: using Win8 workaround"
		$stderr.puts "info: dir = #{dir}, file = #{file}, parameters = #{param}"

		shell_execute_ex.call('open', dir, file, param)
	else
		system(launcher_cmd)
	end
}

reconnect_if_wanted = proc {
	if ARGV.include?('--reconnect') and ARGV.include?('--login') and not $_CLIENTBUFFER_.any? { |cmd| cmd =~ /^(?:\[.*?\])?(?:<c>)?(?:quit|exit)/i }
		if reconnect_arg = ARGV.find { |arg| arg =~ /^\-\-reconnect\-delay=[0-9]+(?:\+[0-9]+)?$/ }
			reconnect_arg =~ /^\-\-reconnect\-delay=([0-9]+)(\+[0-9]+)?/
			reconnect_delay = $1.to_i
			reconnect_step = $2.to_i
		else
			reconnect_delay = 60
			reconnect_step = 0
		end
		$stderr.puts "info: waiting #{reconnect_delay} seconds to reconnect..."
		sleep reconnect_delay
		$stderr.puts 'info: reconnecting...'
		if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
			args = [ 'rubyw.exe' ]
		else
			args = [ 'ruby' ]
		end
		args.push $PROGRAM_NAME.slice(/[^\/\\]+$/)
		args.concat ARGV
		args.push '--reconnected' unless args.include?('--reconnected')
		if reconnect_step > 0
			args.delete(reconnect_arg)
			args.concat ["--reconnect-delay=#{reconnect_delay+reconnect_step}+#{reconnect_step}"]
		end
		$stderr.puts "exec args.join(' '): exec #{args.join(' ')}"
		exec args.join(' ')
	end
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
	alias :kneeling? :checkkneeling
	alias :sitting? :checksitting
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

# backward compatibility - this variable was most often used by scripts to tell if the game stream was XML
$stormfront = true












if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
	wine_dir = wine_bin = nil
else
	if ENV['WINEPREFIX'] and File.exists?(ENV['WINEPREFIX'].to_s)
		wine_dir = ENV['WINEPREFIX']
	elsif ENV['HOME'] and File.exists?(ENV['HOME'] + '/.wine')
		wine_dir = ENV['HOME'] + '/.wine'
	else
		wine_dir = nil
	end
	begin
		wine_bin = `which wine`.strip
	rescue
		wine_bin = nil
	end
	if wine_bin.nil? or wine_bin.empty?
		wine_bin = registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Wine')
	end
	unless wine_bin and not wine_bin.empty? and File.exists?(wine_bin)
		wine_bin = nil
	end
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
		system_win8fix.call(launcher_cmd)
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
	elsif ARGV.any? { |arg| (arg == '-w') or (arg == '--wizard') }
		$frontend = 'wizard'
	elsif ARGV.any? { |arg| arg == '--avalon' }
		$frontend = 'avalon'
	else
		$frontend = 'unknown'
	end
elsif ARGV.include?('--gemstone')
	if ARGV.include?('--platinum')
		$platinum = true
		if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
			game_host = 'storm.gs4.game.play.net'
			game_port = 10124
			$frontend = 'stormfront'
		else
			game_host = 'gs-plat.simutronics.net'
			game_port = 10121
			if ARGV.any? { |arg| arg == '--avalon' }
				$frontend = 'avalon'
			else
				$frontend = 'wizard'
			end
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
			if ARGV.any? { |arg| arg == '--avalon' }
				$frontend = 'avalon'
			else
				$frontend = 'wizard'
			end
		end
	end
elsif ARGV.include?('--shattered')
	$platinum = false
	if ARGV.any? { |arg| (arg == '-s') or (arg == '--stormfront') }
		game_host = 'storm.gs4.game.play.net'
		game_port = 10324
		$frontend = 'stormfront'
	else
		game_host = 'gs4.simutronics.net'
		game_port = 10321
		if ARGV.any? { |arg| arg == '--avalon' }
			$frontend = 'avalon'
		else
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
			if ARGV.any? { |arg| arg == '--avalon' }
				$frontend = 'avalon'
			else
				$frontend = 'wizard'
			end
		end
	end
else
	game_host, game_port = nil, nil
	$stderr.puts "info: no force-mode info given"
end

main_thread = Thread.new {

	       test_mode = false
	             sge = nil
	    $ZLIB_STREAM = false
	 $SEND_CHARACTER = '>'
	     $cmd_prefix = '<c>'

	LichSettings.load
	LichSettings['lich_char'] ||= ';'
	LichSettings['cache_serverbuffer'] = false if LichSettings['cache_serverbuffer'].nil?
	LichSettings['serverbuffer_max_size'] ||= 300
	LichSettings['serverbuffer_min_size'] ||= 200
	LichSettings['clientbuffer_max_size'] ||= 100
	LichSettings['clientbuffer_min_size'] ||= 50
	LichSettings['trusted_scripts']       ||= [ 'updater', 'infomon', 'lnet', 'narost', 'repository' ]

	$clean_lich_char = LichSettings['lich_char']
	$lich_char = Regexp.escape("#{$clean_lich_char}")

	launch_data = nil

	if ARGV.include?('--login')
		if File.exists?("#{$data_dir}entry.dat")
			entry_data = File.open("#{$data_dir}entry.dat", 'r') { |file|
				begin
					Marshal.load(file.read.unpack('m').first)
				rescue
					Array.new
				end
			}
		else
			entry_data = Array.new
		end
		char_name = ARGV[ARGV.index('--login')+1].capitalize
		if ARGV.include?('--gemstone')
			if ARGV.include?('--platinum')
				data = entry_data.find { |d| (d[:char_name] == char_name) and (d[:game_code] == 'GSX') }
			elsif ARGV.include?('--shattered')
				data = entry_data.find { |d| (d[:char_name] == char_name) and (d[:game_code] == 'GSF') }
			else
				data = entry_data.find { |d| (d[:char_name] == char_name) and (d[:game_code] == 'GS3') }
			end
		elsif ARGV.include?('--shattered')
			data = entry_data.find { |d| (d[:char_name] == char_name) and (d[:game_code] == 'GSF') }
		else
			data = entry_data.find { |d| (d[:char_name] == char_name) }
		end
		if data
			$stderr.puts "info: using quick game entry settings for #{char_name}"
			msgbox = proc { |msg|
				if HAVE_GTK
					done = false
					Gtk.queue {
						dialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::QUESTION, Gtk::MessageDialog::BUTTONS_CLOSE, msg)
						dialog.run
						dialog.destroy
						done = true
					}
					sleep "0.1".to_f until done
				else
					$stdout.puts(msg)
					$stderr.puts(msg)
				end
			}
	
			login_server = nil
			connect_thread = nil
			timeout_thread = Thread.new {
				sleep 30
				$stdout.puts "error: timed out connecting to eaccess.play.net:7900"
				$stderr.puts "error: timed out connecting to eaccess.play.net:7900"
				connect_thread.kill rescue()
				login_server = nil
			}
			connect_thread = Thread.new {
				begin
					login_server = TCPSocket.new('eaccess.play.net', 7900)
				rescue
					login_server = nil
					$stdout.puts "error connecting to server: #{$!}"
					$stderr.puts "error connecting to server: #{$!}"
				end
			}
			connect_thread.join
			timeout_thread.kill rescue()

			if login_server
				login_server.puts "K\n"
				hashkey = login_server.gets
				if 'test'[0].class == String
					password = data[:password].split('').collect { |c| c.getbyte(0) }
					hashkey = hashkey.split('').collect { |c| c.getbyte(0) }
				else
					password = data[:password].split('').collect { |c| c[0] }
					hashkey = hashkey.split('').collect { |c| c[0] }
				end
				password.each_index { |i| password[i] = ((password[i]-32)^hashkey[i])+32 }
				password = password.collect { |c| c.chr }.join
				login_server.puts "A\t#{data[:user_id]}\t#{password}\n"
				password = nil
				response = login_server.gets
				login_key = /KEY\t([^\t]+)\t/.match(response).captures.first
				if login_key
					login_server.puts "M\n"
					response = login_server.gets
					if response =~ /^M\t/
						login_server.puts "F\t#{data[:game_code]}\n"
						response = login_server.gets
						if response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL/
							login_server.puts "G\t#{data[:game_code]}\n"
							login_server.gets
							login_server.puts "P\t#{data[:game_code]}\n"
							login_server.gets
							login_server.puts "C\n"
							char_code = login_server.gets.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/).find { |c| c.split("\t")[1] == data[:char_name] }.split("\t")[0]
							login_server.puts "L\t#{char_code}\tSTORM\n"
							response = login_server.gets
							if response =~ /^L\t/
								login_server.close unless login_server.closed?
								launch_data = response.sub(/^L\tOK\t/, '').split("\t")
								if data[:frontend] == 'wizard'
									launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, 'GAMEFILE=WIZARD.EXE').sub(/GAME=.+/, 'GAME=WIZ').sub(/FULLGAMENAME=.+/, 'FULLGAMENAME=Wizard Front End') }
								end
								if data[:custom_launch]
									launch_data.push "CUSTOMLAUNCH=#{data[:custom_launch]}"
									if data[:custom_launch_dir]
										launch_data.push "CUSTOMLAUNCHDIR=#{data[:custom_launch_dir]}"
									end
								end
							else
								login_server.close unless login_server.closed?
								$stdout.puts "error: unrecognized response from server. (#{response})"
								$stderr.puts "error: unrecognized response from server. (#{response})"
							end
						else
							login_server.close unless login_server.closed?
							$stdout.puts "error: unrecognized response from server. (#{response})"
							$stderr.puts "error: unrecognized response from server. (#{response})"
						end
					else
						login_server.close unless login_server.closed?
						$stdout.puts "error: unrecognized response from server. (#{response})"
						$stderr.puts "error: unrecognized response from server. (#{response})"
					end
				else
					login_server.close unless login_server.closed?
					$stdout.puts "Something went wrong... probably invalid user id and/or password.\nserver response: #{response}"
					$stderr.puts "Something went wrong... probably invalid user id and/or password.\nserver response: #{response}"
					reconnect_if_wanted.call
				end
			else
				$stdout.puts "error: failed to connect to server"
				$stderr.puts "error: failed to connect to server"
				reconnect_if_wanted.call
				$stderr.puts "info: exiting..."
				Gtk.queue { Gtk.main_quit } if HAVE_GTK
				exit
			end
		else
			$stdout.puts "error: failed to find login data for #{char_name}"
			$stderr.puts "error: failed to find login data for #{char_name}"
		end
	elsif HAVE_GTK and ARGV.empty?
		if File.exists?("#{$data_dir}entry.dat")
			entry_data = File.open("#{$data_dir}entry.dat", 'r') { |file|
				begin
					Marshal.load(file.read.unpack('m').first).sort { |a,b| a[:char_name] <=> b[:char_name] }
				rescue
					Array.new
				end
			}
		else
			entry_data = Array.new
		end
		save_entry_data = false
		done = false
		Gtk.queue {

			login_server = nil
			window = nil
			install_tab_loaded = false

			msgbox = proc { |msg|
				dialog = Gtk::MessageDialog.new(window, Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::QUESTION, Gtk::MessageDialog::BUTTONS_CLOSE, msg)
				dialog.run
				dialog.destroy
			}

			#
			# quick game entry tab
			#
			if entry_data.empty?
				box = Gtk::HBox.new
				box.pack_start(Gtk::Label.new('You have no saved login info.'), true, true, 0)
				quick_game_entry_tab = Gtk::VBox.new
				quick_game_entry_tab.border_width = 5
				quick_game_entry_tab.pack_start(box, true, true, 0)
			else
				quick_box = Gtk::VBox.new
				entry_data.each { |login_info|
					label = Gtk::Label.new("#{login_info[:char_name]} (#{login_info[:game_name]})")
					play_button = Gtk::Button.new('Play')
					remove_button = Gtk::Button.new('X')
					char_box = Gtk::HBox.new
					char_box.pack_start(label, false, false, 6)
					char_box.pack_end(remove_button, false, false, 0)
					char_box.pack_end(play_button, false, false, 0)
					quick_box.pack_start(char_box, false, false, 0)
					play_button.signal_connect('clicked') {
						play_button.sensitive = false
						begin
							login_server = nil
							connect_thread = Thread.new {
								login_server = TCPSocket.new('eaccess.play.net', 7900)
							}
							300.times {
								sleep 0.1
								break unless connect_thread.status
							}
							if connect_thread.status
								connect_thread.kill rescue()
								msgbox.call "error: timed out connecting to eaccess.play.net:7900"
							end
						rescue
							msgbox.call "error connecting to server: #{$!}"
							play_button.sensitive = true
						end
						if login_server
							login_server.puts "K\n"
							hashkey = login_server.gets
							if 'test'[0].class == String
								password = login_info[:password].split('').collect { |c| c.getbyte(0) }
								hashkey = hashkey.split('').collect { |c| c.getbyte(0) }
							else
								password = login_info[:password].split('').collect { |c| c[0] }
								hashkey = hashkey.split('').collect { |c| c[0] }
							end
							password.each_index { |i| password[i] = ((password[i]-32)^hashkey[i])+32 }
							password = password.collect { |c| c.chr }.join
							login_server.puts "A\t#{login_info[:user_id]}\t#{password}\n"
							password = nil
							response = login_server.gets
							login_key = /KEY\t([^\t]+)\t/.match(response).captures.first
							if login_key
								login_server.puts "M\n"
								response = login_server.gets
								if response =~ /^M\t/
									login_server.puts "F\t#{login_info[:game_code]}\n"
									response = login_server.gets
									if response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL/
										login_server.puts "G\t#{login_info[:game_code]}\n"
										login_server.gets
										login_server.puts "P\t#{login_info[:game_code]}\n"
										login_server.gets
										login_server.puts "C\n"
										char_code = login_server.gets.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/).find { |c| c.split("\t")[1] == login_info[:char_name] }.split("\t")[0]
										login_server.puts "L\t#{char_code}\tSTORM\n"
										response = login_server.gets
										if response =~ /^L\t/
											login_server.close unless login_server.closed?
											launch_data = response.sub(/^L\tOK\t/, '').split("\t")
											if login_info[:frontend] == 'wizard'
												launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, 'GAMEFILE=WIZARD.EXE').sub(/GAME=.+/, 'GAME=WIZ').sub(/FULLGAMENAME=.+/, 'FULLGAMENAME=Wizard Front End') }
											end
											if login_info[:custom_launch]
												launch_data.push "CUSTOMLAUNCH=#{login_info[:custom_launch]}"
												if login_info[:custom_launch_dir]
													launch_data.push "CUSTOMLAUNCHDIR=#{login_info[:custom_launch_dir]}"
												end
											end
											window.destroy
											done = true
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
							msgbox.call "error: failed to connect to server"
							play_button.sensitive = true
						end
					}
					remove_button.signal_connect('clicked') {
						entry_data.delete(login_info)
						save_entry_data = true
						char_box.visible = false
					}
				}

				adjustment = Gtk::Adjustment.new(0, 0, 1000, 5, 20, 500)
				quick_vp = Gtk::Viewport.new(adjustment, adjustment)
				quick_vp.add(quick_box)

				quick_sw = Gtk::ScrolledWindow.new
				quick_sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
				quick_sw.add(quick_vp)

				quick_game_entry_tab = Gtk::VBox.new
				quick_game_entry_tab.border_width = 5
				quick_game_entry_tab.pack_start(quick_sw, true, true, 5)
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

			liststore = Gtk::ListStore.new(String, String, String, String)
			liststore.set_sort_column_id(1, Gtk::SORT_ASCENDING)

			renderer = Gtk::CellRendererText.new
			renderer.background = 'white'

			treeview = Gtk::TreeView.new(liststore)
			treeview.height_request = 160

			col = Gtk::TreeViewColumn.new("Game", renderer, :text => 1, :background_set => 2)
			col.resizable = true
			treeview.append_column(col)

			col = Gtk::TreeViewColumn.new("Character", renderer, :text => 3, :background_set => 2)
			col.resizable = true
			treeview.append_column(col)

			sw = Gtk::ScrolledWindow.new
			sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
			sw.add(treeview)

			wizard_option = Gtk::RadioButton.new('Wizard')
			stormfront_option = Gtk::RadioButton.new(wizard_option, 'Stormfront')
			suks_option = Gtk::RadioButton.new(wizard_option, 'suks')

			frontend_box = Gtk::HBox.new(false, 10)
			frontend_box.pack_start(wizard_option, false, false, 0)
			frontend_box.pack_start(stormfront_option, false, false, 0)
			#frontend_box.pack_start(suks_option, false, false, 0)

			custom_launch_option = Gtk::CheckButton.new('Custom launch command')
			custom_launch_entry = Gtk::ComboBoxEntry.new()
			custom_launch_entry.child.text = "(enter custom launch command)"
			custom_launch_entry.append_text("Wizard.Exe /GGS /H127.0.0.1 /P%port% /K%key%")
			custom_launch_entry.append_text("Stormfront.exe /GGS /H127.0.0.1 /P%port% /K%key%")
			custom_launch_dir = Gtk::ComboBoxEntry.new()
			custom_launch_dir.child.text = "(enter working directory for command)"
			custom_launch_dir.append_text("../wizard")
			custom_launch_dir.append_text("../StormFront")

			make_quick_option = Gtk::CheckButton.new('Save this info for quick game entry')

			play_button = Gtk::Button.new(' Play ')
			play_button.sensitive = false

			play_button_box = Gtk::HBox.new
			play_button_box.pack_end(play_button, false, false, 5)

			game_entry_tab = Gtk::VBox.new
			game_entry_tab.border_width = 5
			game_entry_tab.pack_start(login_table, false, false, 0)
			game_entry_tab.pack_start(login_button_box, false, false, 0)
			game_entry_tab.pack_start(sw, true, true, 3)
			game_entry_tab.pack_start(frontend_box, false, false, 3)
			game_entry_tab.pack_start(custom_launch_option, false, false, 3)
			game_entry_tab.pack_start(custom_launch_entry, false, false, 3)
			game_entry_tab.pack_start(custom_launch_dir, false, false, 3)
			game_entry_tab.pack_start(make_quick_option, false, false, 3)
			game_entry_tab.pack_start(play_button_box, false, false, 3)

			custom_launch_option.signal_connect('toggled') {
				custom_launch_entry.visible = custom_launch_option.active?
				custom_launch_dir.visible = custom_launch_option.active?
			}

			connect_button.signal_connect('clicked') {
				connect_button.sensitive = false
				user_id_entry.sensitive = false
				pass_entry.sensitive = false
				iter = liststore.append
				iter[1] = 'working...'
				Gtk.queue {
					begin
						login_server = nil
						connect_thread = Thread.new {
							login_server = TCPSocket.new('eaccess.play.net', 7900)
						}
						300.times {
							sleep 0.1
							break unless connect_thread.status
						}
						if connect_thread.status
							connect_thread.kill rescue()
							msgbox.call "error: timed out connecting to eaccess.play.net:7900"
						end
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
						# pass_entry.text = String.new
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
								liststore.clear
								for game in response.sub(/^M\t/, '').scan(/[^\t]+\t[^\t^\n]+/)
									game_code, game_name = game.split("\t")
									login_server.puts "N\t#{game_code}\n"
									if login_server.gets =~ /STORM/
										login_server.puts "F\t#{game_code}\n"
										if login_server.gets =~ /NORMAL|PREMIUM|TRIAL|INTERNAL/
											login_server.puts "G\t#{game_code}\n"
											login_server.gets
											login_server.puts "P\t#{game_code}\n"
											login_server.gets
											login_server.puts "C\n"
											for code_name in login_server.gets.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
												char_code, char_name = code_name.split("\t")
												iter = liststore.append
												iter[0] = game_code
												iter[1] = game_name
												iter[2] = char_code
												iter[3] = char_name
											end
										end
									end
								end
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
			}
			treeview.signal_connect('cursor-changed') {
				if login_server
					play_button.sensitive = true
				end
			}
			disconnect_button.signal_connect('clicked') {
				disconnect_button.sensitive = false
				play_button.sensitive = false
				liststore.clear
				login_server.close unless login_server.closed?
				connect_button.sensitive = true
				user_id_entry.sensitive = true
				pass_entry.sensitive = true
			}
			play_button.signal_connect('clicked') {
				play_button.sensitive = false
				game_code = treeview.selection.selected[0]
				char_code = treeview.selection.selected[2]
				if login_server and not login_server.closed?
					login_server.puts "F\t#{game_code}\n"
					login_server.gets
					login_server.puts "G\t#{game_code}\n"
					login_server.gets
					login_server.puts "P\t#{game_code}\n"
					login_server.gets
					login_server.puts "C\n"
					login_server.gets
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
						elsif suks_option.active?
							launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, "GAMEFILE=WIZARD.EXE").sub(/GAME=.+/, "GAME=SUKS") }
						end
						if custom_launch_option.active?
							launch_data.push "CUSTOMLAUNCH=#{custom_launch_entry.child.text}"
							unless custom_launch_dir.child.text.empty? or custom_launch_dir.child.text == "(enter working directory for command)"
								launch_data.push "CUSTOMLAUNCHDIR=#{custom_launch_dir.child.text}"
							end
						end
						if make_quick_option.active?
							if wizard_option.active?
								frontend = 'wizard'
							else
								frontend = 'stormfront'
							end
							if custom_launch_option.active?
								custom_launch = custom_launch_entry.child.text
								if custom_launch_dir.child.text.empty? or custom_launch_dir.child.text == "(enter working directory for command)"
									custom_launch_dir = nil
								else
									custom_launch_dir = custom_launch_dir.child.text
								end
							else
								custom_launch = nil
								custom_launch_dir = nil
							end
							entry_data.push h={ :char_name => treeview.selection.selected[3], :game_code => treeview.selection.selected[0], :game_name => treeview.selection.selected[1], :user_id => user_id_entry.text, :password => pass_entry.text, :frontend => frontend, :custom_launch => custom_launch, :custom_launch_dir => custom_launch_dir }
							save_entry_data = true
						end
						user_id_entry.text = String.new
						pass_entry.text = String.new
						window.destroy
						done = true
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
			user_id_entry.signal_connect('activate') {
				pass_entry.grab_focus
			}
			pass_entry.signal_connect('activate') {
				connect_button.clicked
			}

			#
			# install tab
			#

			if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
				begin
					kernel32 = DL.dlopen('kernel32.dll')
					get_version_ex = kernel32['GetVersionEx', 'LP']

					os_version_info = DL.malloc(DL.sizeof('LLLLLC128'))
					os_version_info.struct!('LLLLLC128', :dwOSVersionInfoSize, :dwMajorVersion, :dwMinorVersion, :dwBuildNumber, :dwPlatformId, :szCSDVersion)
					os_version_info[:dwOSVersionInfoSize] = DL.sizeof('LLLLLC128')
					get_version_ex.call(os_version_info)

					if os_version_info[:dwMajorVersion] >= 6 # >= Vista
						get_current_process = kernel32['GetCurrentProcess', 'L']
						close_handle = kernel32['CloseHandle', 'LL']

						advapi32 = DL.dlopen('advapi32.dll')
						open_process_token = advapi32['OpenProcessToken', 'LLLP']
						get_token_information = advapi32['GetTokenInformation', 'LLLPLP']

						token_handle = DL.malloc(DL.sizeof('L')); token_handle.struct!('L', :handle)
						open_process_token.call(get_current_process.call[0], 8, token_handle) # 8 = TOKEN_QUERY

						token_information = DL.malloc(DL.sizeof('L')); token_information.struct!('L', :info)
						return_length = DL.malloc(DL.sizeof('L')); return_length.struct!('L', :length)
						get_token_information.call(token_handle[:handle], 20, token_information, DL.sizeof('L'), return_length) # 20 = TokenElevation
						close_handle.call(token_handle[:handle])
						if token_information[:info] == 0
							need_admin = true
						else
							need_admin = false
						end
					else
						need_admin = false
					end
				rescue
					need_admin = false
				end
			else
				need_admin = false
			end

			if need_admin
				refresh_button = nil
				install_tab_loaded = true
				restart_button = Gtk::Button.new('Restart Lich as Admin')
				box = Gtk::HBox.new
				box.pack_start(restart_button, true, false, 5)
				install_tab = Gtk::VBox.new
				install_tab.border_width = 5
				install_tab.pack_start(box, true, false, 5)
				restart_button.signal_connect('clicked') {
					begin
						shell32 = DL.dlopen('shell32.dll')
						shell_execute_ex = shell32['ShellExecuteEx', 'LP']

						shell_execute_info = DL.malloc(DL.sizeof('LLLSSSSLLLSLLLL'))
						shell_execute_info.struct!('LLLSSSSLLLSLLLL', :cbSize, :fMask, :hwnd, :lpVerb, :lpFile, :lpParameters, :lpDirectory, :nShow, :hInstApp, :lpIDList, :lpClass, :hkeyClass, :dwHotKey, :hIcon, :hProcess)
						shell_execute_info[:cbSize] = DL.sizeof('LLLSSSSLLLSLLLL')
						shell_execute_info[:fMask] = 0
						shell_execute_info[:hwnd] = 0
						shell_execute_info[:lpVerb] = "runas"
						if ENV['OCRA_EXECUTABLE']
							shell_execute_info[:lpFile] = ENV['OCRA_EXECUTABLE'].split(/\/|\\/).last
							shell_execute_info[:lpParameters] = ''
						else
							shell_execute_info[:lpFile] = 'rubyw.exe'
							shell_execute_info[:lpParameters] = $PROGRAM_NAME.split(/\/|\\/).last
						end
						shell_execute_info[:lpDirectory] = $lich_dir.sub(/\/$/, '').tr("/", "\\")
						shell_execute_info[:nShow] = 1
						shell_execute_info[:hInstApp] = 0
						shell_execute_info[:lpIDList] = 0
						shell_execute_info[:lpClass] = ""
						shell_execute_info[:hkeyClass] = 0
						shell_execute_info[:dwHotKey] = 0 
						shell_execute_info[:hIcon] =  0
						shell_execute_info[:hProcess] = 0

						shell_execute_ex.call(shell_execute_info)
						exit
					rescue
						msgbox.call($!)
					end
				}
			else
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
				install_tab.border_width = 5
				install_tab.pack_start(website_order_frame, false, false, 5)
				install_tab.pack_start(sge_order_frame, false, false, 5)
				install_tab.pack_start(refresh_box, false, false, 5)
				install_tab.pack_start(psinet_compatible_button, false, false, 5)
				install_tab.pack_start(install_table, false, false, 5)

				psinet_installstate = nil

				refresh_button.signal_connect('clicked') {
					install_tab_loaded = true
					launch_cmd = registry_get('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\').to_s
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
						website_order_entry_3.text = registry_get('HKEY_LOCAL_MACHINE\\Software\\Classes\\Simutronics.Autolaunch\\Shell\\Open\\command\\RealCommand').to_s
					else
						website_order_entry_3.visible = false
					end

					launch_cmd = registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\Directory').to_s
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
						sge_order_entry_3.text = registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\Launcher\\RealDirectory').to_s
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
					unless (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
						psinet_compatible_button.active = false
						psinet_compatible_button.visible = false
					end
				}
				install_button.signal_connect('clicked') {
					install_to_registry(psinet_compatible_button.active?)
					if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
						refresh_button.clicked
					else
						msgbox.call('WINE will take 5-30 seconds (maybe more) to update the registry.  Wait a while and click the refresh button.')
					end
				}
				uninstall_button.signal_connect('clicked') {
					uninstall_from_registry
					if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
						refresh_button.clicked
					else
						msgbox.call('WINE will take 5-30 seconds (maybe more) to update the registry.  Wait a while and click the refresh button.')
					end
				}
			end

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
			options_tab.border_width = 5
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
			# put it together and show the window
			#

			notebook = Gtk::Notebook.new
			notebook.append_page(quick_game_entry_tab, Gtk::Label.new('Quick Game Entry'))
			notebook.append_page(game_entry_tab, Gtk::Label.new('Game Entry'))
			notebook.append_page(install_tab, Gtk::Label.new('Install'))
			notebook.append_page(options_tab, Gtk::Label.new('Options'))
			notebook.signal_connect('switch-page') { |who,page,page_num|
				refresh_button.clicked if (page_num == 2) and not install_tab_loaded
			}

			window = Gtk::Window.new
			window.title = "Lich v#{$version}"
			window.border_width = 5
			window.add(notebook)
			window.signal_connect('delete_event') { window.destroy; done = true }

			window.show_all

			custom_launch_entry.visible = false
			custom_launch_dir.visible = false

			notebook.set_page(1) if entry_data.empty?
		}

		wait_until { done }

		if save_entry_data
			File.open("#{$data_dir}entry.dat", 'w') { |file|
				file.write([Marshal.dump(entry_data)].pack('m'))
			}
		end
		entry_data = nil

		unless launch_data
			Gtk.queue { Gtk.main_quit }
			Thread.kill
		end
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
	if launch_file
		begin
			launch_data = File.open(launch_file) { |file| file.readlines }.collect { |line| line.chomp }
		rescue
			$stdout.puts "error: failed to read launch_file: #{$!}"
			$stderr.puts "info: launch_file: #{launch_file}"
			$stderr.puts "error: failed to read launch_file: #{$!}"
			$stderr.puts $!.backtrace
			exit(1)
		end
	end
	if launch_data
		unless gamecode = launch_data.find { |line| line =~ /GAMECODE=/ }
			$stdout.puts "error: launch_data contains no GAMECODE info"
			$stderr.puts "error: launch_data contains no GAMECODE info"
			exit(1)
		end
		unless gameport = launch_data.find { |line| line =~ /GAMEPORT=/ }
			$stdout.puts "error: launch_data contains no GAMEPORT info"
			$stderr.puts "error: launch_data contains no GAMEPORT info"
			exit(1)
		end
		unless gamehost = launch_data.find { |opt| opt =~ /GAMEHOST=/ }
			$stdout.puts "error: launch_data contains no GAMEHOST info"
			$stderr.puts "error: launch_data contains no GAMEHOST info"
			exit(1)
		end
		unless game = launch_data.find { |opt| opt =~ /GAME=/ }
			$stdout.puts "error: launch_data contains no GAME info"
			$stderr.puts "error: launch_data contains no GAME info"
			exit(1)
		end
		if custom_launch = launch_data.find { |opt| opt =~ /CUSTOMLAUNCH=/ }
			custom_launch.sub!(/^.*?\=/, '')
			$stderr.puts "info: using custom launch command: #{custom_launch}"
		end
		if custom_launch_dir = launch_data.find { |opt| opt =~ /CUSTOMLAUNCHDIR=/ }
			custom_launch_dir.sub!(/^.*?\=/, '')
			$stderr.puts "info: using working directory for custom launch command: #{custom_launch_dir}"
		end
		if ARGV.include?('--without-frontend')
			$frontend = 'unknown'
			unless (game_key = launch_data.find { |opt| opt =~ /KEY=/ }) && (game_key = game_key.split('=').last.chomp)
				$stdout.puts "error: launch_data contains no KEY info"
				$stderr.puts "error: launch_data contains no KEY info"
				exit(1)
			end
		elsif game =~ /SUKS/i
			$frontend = 'suks'
			unless (game_key = launch_data.find { |opt| opt =~ /KEY=/ }) && (game_key = game_key.split('=').last.chomp)
				$stdout.puts "error: launch_data contains no KEY info"
				$stderr.puts "error: launch_data contains no KEY info"
				exit(1)
			end
		elsif custom_launch
			unless (game_key = launch_data.find { |opt| opt =~ /KEY=/ }) && (game_key = game_key.split('=').last.chomp)
				$stdout.puts "error: launch_data contains no KEY info"
				$stderr.puts "error: launch_data contains no KEY info"
				exit(1)
			end
		else
			unless launcher_cmd = get_real_launcher_cmd.call
				$stdout.puts 'error: failed to find the Simutronics launcher'
				$stderr.puts 'error: failed to find the Simutronics launcher'
				exit(1)
			end
		end
		gamecode = gamecode.split('=').last
		gameport = gameport.split('=').last
		gamehost = gamehost.split('=').last
		game     = game.split('=').last
		if (gamehost == '127.0.0.1') or (gamehost == 'localhost')
			$psinet = true
			if (game !~ /WIZ/i) and ( File.exists?('fakestormfront.txt') or ( registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\WIZ32\\Directory') and not registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\STORM32\\Directory') ) )
				launch_data.collect! { |line| line.sub(/GAMEFILE=.+/, 'GAMEFILE=WIZARD.EXE').sub(/GAME=.+/, 'GAME=WIZ').sub(/FULLGAMENAME=.+/, 'FULLGAMENAME=Wizard Front End') }
				game = 'WIZ'
			end
		else
			$psinet = false
		end
		if (gameport == '10121') or (gameport == '10124')
			$platinum = true
		else
			$platinum = false
		end
		$stderr.puts "info: gamehost: #{gamehost}"
		$stderr.puts "info: gameport: #{gameport}"
		$stderr.puts "info: game: #{game}"
		if ARGV.include?('--without-frontend')
			$_CLIENT_ = nil
		elsif $frontend == 'suks'
			nil
		else
			if game =~ /WIZ/i
				$frontend = 'wizard'
			elsif game =~ /STORM/i
				$frontend = 'stormfront'
			else
				$frontend = 'unknown'
			end
			begin
				listener = TCPServer.new('127.0.0.1', nil)
			rescue
				$stdout.puts "--- error: cannot bind listen socket to local port: #{$!}"
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
			if custom_launch
				sal_filename = nil
				launcher_cmd = custom_launch.sub(/\%port\%/, localport.to_s).sub(/\%key\%/, game_key.to_s)
				$stderr.puts "info: launcher_cmd: #{launcher_cmd}"
			else
				launch_data.collect! { |line| line.sub(/GAMEPORT=.+/, "GAMEPORT=#{localport}").sub(/GAMEHOST=.+/, "GAMEHOST=localhost") }
				sal_filename = "#{$temp_dir}lich#{rand(10000)}.sal"
				while File.exists?(sal_filename)
					sal_filename = "#{$temp_dir}lich#{rand(10000)}.sal"
				end
				File.open(sal_filename, 'w') { |f| f.puts launch_data }
				launcher_cmd = launcher_cmd.sub('%1', sal_filename)
				launcher_cmd = launcher_cmd.tr('/', "\\") if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
				launcher_cmd = "#{wine_bin} #{launcher_cmd}" if wine_bin
				$stderr.puts "info: launcher_cmd: #{launcher_cmd}"
				if get_process_list.call.any? { |line| line =~ /Launcher\.exe/i }
					$stderr.puts "info: waiting for launcher to exit..."
					20.times {
						sleep "0.5".to_f
						break unless get_process_list.call.any? { |line| line =~ /Launcher\.exe/i }
					}
				end
			end
			Thread.new {
				begin
					if custom_launch_dir
						Dir.chdir(custom_launch_dir)
					end
					system_win8fix.call(launcher_cmd)
				rescue
					$stderr.puts $!
				end
			}
			timeout_thr = Thread.new {
				sleep 30
				$stdout.puts "error: timeout waiting for client to connect"
				$stderr.puts "error: timeout waiting for client to connect"
				Dir.chdir($lich_dir)
				if sal_filename
					File.delete(sal_filename) rescue()
				end
				listener.close rescue()
				$_CLIENT_.close rescue()
				reconnect_if_wanted.call
				$stderr.puts "info: exiting..."
				Gtk.queue { Gtk.main_quit } if HAVE_GTK
				exit
			}
			$stderr.puts 'info: waiting for client to connect...'
			$_CLIENT_ = listener.accept
			$stderr.puts 'info: connected'
			Dir.chdir($lich_dir)
			if sal_filename
				File.delete(sal_filename) rescue()
			end
			begin
				timeout_thr.kill
				listener.close
			rescue
				$stderr.puts "error: #{$!}"
			end
		end
		gamehost, gameport = fix_game_host_port.call(gamehost, gameport)
		$stderr.puts "info: connecting to game server (#{gamehost}:#{gameport})"
		begin
			connect_thread = Thread.new {
				$_SERVER_ = TCPSocket.open(gamehost, gameport)
			}
			300.times {
				sleep 0.1
				break unless connect_thread.status
			}
			if connect_thread.status
				connect_thread.kill rescue()
				raise "error: timed out connecting to #{gamehost}:#{gameport}"
			end
		rescue
			$stderr.puts "error: #{$!}"
			gamehost, gameport = break_game_host_port.call(gamehost, gameport)
			$stderr.puts "info: connecting to game server (#{gamehost}:#{gameport})"
			begin
				connect_thread = Thread.new {
					$_SERVER_ = TCPSocket.open(gamehost, gameport)
				}
				300.times {
					sleep 0.1
					break unless connect_thread.status
				}
				if connect_thread.status
					connect_thread.kill rescue()
					raise "error: timed out connecting to #{gamehost}:#{gameport}"
				end
			rescue
				$stderr.puts "error: #{$!}"
				$_CLIENT_.close rescue()
				reconnect_if_wanted.call
				$stderr.puts "info: exiting..."
				Gtk.queue { Gtk.main_quit } if HAVE_GTK
				exit
			end
		end
		$stderr.puts 'info: connected'
	elsif game_host and game_port
		hosts_dir ||= find_hosts_dir
		unless hosts_dir and File.exists?(hosts_dir)
			$stdout.puts "error: hosts_dir does not exist: #{hosts_dir}"
			$stderr.puts "error: hosts_dir does not exist: #{hosts_dir}"
			exit
		end
		game_quad_ip = IPSocket.getaddress(game_host)
		error_count = 0
		begin
			listener = TCPServer.new('127.0.0.1', game_port)
			begin
				listener.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
			rescue
				$stderr.puts "warning: setsockopt with SO_REUSEADDR failed: #{$!}"
			end
		rescue
			sleep 1
			if (error_count += 1) >= 30
				$stdout.puts 'error: failed to bind to the proper port'
				$stderr.puts 'error: failed to bind to the proper port'
				exit!
			else
				retry
			end
		end

		hack_hosts(hosts_dir, game_host)

		$stdout.puts "Pretending to be #{game_host}"
		$stdout.puts "Listening on port #{game_port}"
		$stdout.puts "Waiting for the client to connect..."
		$stderr.puts "info: pretending to be #{game_host}"
		$stderr.puts "info: listening on port #{game_port}"
		$stderr.puts "info: waiting for the client to connect..."

		timeout_thread = Thread.new {
			sleep 120
			$stdout.puts 'error: timed out waiting for client to connect'
			$stderr.puts 'error: timed out waiting for client to connect'
			heal_hosts(hosts_dir)
			exit
		}
		$_CLIENT_ = listener.accept
		timeout_thread.kill
		$stdout.puts "Connection with the local game client is open."
		$stderr.puts "info: connection with the game client is open"
		heal_hosts(hosts_dir)
		if test_mode
			$_SERVER_ = $stdin
			$_CLIENT_.puts "Running in test mode: host socket set to stdin."
		else
			$stderr.puts 'info: connecting to the real game host...'
			game_host, game_port = fix_game_host_port.call(game_host, game_port)
			begin
				timeout_thread = Thread.new {
					sleep 30
					$stderr.puts "error: timed out connecting to #{game_host}:#{game_port}"
					$stdout.puts "error: timed out connecting to #{game_host}:#{game_port}"
					exit
				}
				begin
					$_SERVER_ = TCPSocket.open(game_host, game_port)
				rescue
					$stderr.puts "error: #{$!}"
					$stdout.puts "error: #{$!}"
					exit
				end
				timeout_thread.kill rescue()
				$stderr.puts 'info: connection with the game host is open'
			end
		end
	else
		#
		# offline mode
		#
		$stderr.puts "info: offline mode"

		$offline_mode = true
		unless $frontend == 'suks'
			begin
				listener = TCPServer.new('127.0.0.1', nil)
			rescue
				$stdout.puts "Cannot bind listening socket to local port: #{$!}"
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
				frontend_dir = registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\STORM32\\Directory')
				frontend_cmd = "\"#{frontend_dir}\\StormFront.exe\""
			else
				$frontend = 'wizard'
				frontend_dir = registry_get('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\WIZ32\\Directory')
				frontend_cmd = "\"#{frontend_dir}\\wizard.exe\""
			end
			frontend_cmd += " /GGS /H127.0.0.1 /P#{localport} /Kfake_login_key"
			frontend_cmd = "#{wine_bin} #{frontend_cmd}" if wine_bin
			$stderr.puts "info: frontend_cmd: #{frontend_cmd}"
			Thread.new {
				Dir.chdir(frontend_dir) rescue()
				system(frontend_cmd)
			}
			timeout_thr = Thread.new {
				sleep 30
				$stdout.puts "timeout waiting for connection"
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
			if $frontend =~ /^(?:wizard|avalon)$/
				$_CLIENT_.puts "\034GSB0000000000Lich\r\n\034GSA#{Time.now.to_i.to_s}GemStone IV\034GSD\r\n"
			end
		end
	end

	listener = timeout_thr = nil
	undef :hack_hosts

	#
	# drop superuser privileges
	#
	unless (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
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

	# backward compatibility
	if $frontend =~ /^(?:wizard|avalon)$/
		$fake_stormfront = true
	else
		$fake_stormfront = false
	end

	undef :exit!
	$_SERVER_.sync = true

	if ARGV.include?('--without-frontend')
		Thread.new {
			client_thread = nil
			#
			# send the login key
			#
			$_SERVER_.write("#{game_key}\r\n")
			game_key = nil
			#
			# send version string
			#
			client_string = "/FE:WIZARD /VERSION:1.0.1.22 /P:#{RUBY_PLATFORM} /XML\r\n"
			$_CLIENTBUFFER_.push(client_string.dup)
			$_SERVER_.write(client_string)
			#
			# tell the server we're ready
			#
			2.times {
				sleep "0.3".to_f
				$_CLIENTBUFFER_.push("<c>\r\n")
				$_SERVER_.write("<c>\r\n")
			}
			$login_time = Time.now
		}
	else
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

		$stdout = $_CLIENT_
		$_CLIENT_.sync = true

		client_thread = Thread.new {
			$login_time = Time.now

			if $offline_mode
				nil
			elsif $frontend =~ /^(?:wizard|avalon)$/
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
				2.times {
					sleep "0.3".to_f
					$_CLIENTBUFFER_.push("#{$cmd_prefix}\r\n")
					$_SERVER_.write("#{$cmd_prefix}\r\n")
				}
				#
				# set up some stuff
				#
				for client_string in [ "#{$cmd_prefix}_injury 2\r\n", "#{$cmd_prefix}_flag Display Inventory Boxes 1\r\n", "#{$cmd_prefix}_flag Display Dialog Boxes 0\r\n" ]
					$_CLIENTBUFFER_.push(client_string)
					$_SERVER_.write(client_string)
				end
				#
				# client wants to send "GOOD", xml server won't recognize it
				#
				$_CLIENT_.gets
			else
				inv_off_proc = proc { |server_string|
					if server_string =~ /^<(?:container|clearContainer|exposeContainer)/
						server_string.gsub!(/<(?:container|clearContainer|exposeContainer)[^>]*>/, '')
						server_string.gsub!(/<inv.*\/inv>/, '')
						if server_string.empty?
							nil
						else
							server_string
						end
					elsif server_string =~ /^<flag id="Display Inventory Boxes" status='on' desc="Display all inventory and container windows."\/>/
						server_string.sub("status='on'", "status='off'")
					elsif server_string =~ /^\s*<d cmd="flag Inventory off">Inventory<\/d>\s+ON/
						server_string.sub("flag Inventory off", "flag Inventory on").sub('ON', 'OFF')
					else
						server_string
					end
				}
				DownstreamHook.add('inventory_boxes_off', inv_off_proc)
				inv_toggle_proc = proc { |client_string|
					if client_string =~ /^(?:<c>)?_flag Display Inventory Boxes ([01])/
						if $1 == '1'
							DownstreamHook.remove('inventory_boxes_off')
							LichSettings[XMLData.player_id]['enable_inventory_boxes'] = true
							LichSettings.save
						else
							DownstreamHook.add('inventory_boxes_off', inv_off_proc)
							LichSettings[XMLData.player_id]['enable_inventory_boxes'] = false
							LichSettings.save
						end
						nil
					elsif client_string =~ /^(?:<c>)?\s*(?:set|flag)\s+inv(?:e|en|ent|ento|entor|entory)?\s+(on|off)/i
						if $1.downcase == 'on'
							DownstreamHook.remove('inventory_boxes_off')
							respond 'You have enabled viewing of inventory and container windows.'
							LichSettings[XMLData.player_id]['enable_inventory_boxes'] = true
							LichSettings.save
						else
							DownstreamHook.add('inventory_boxes_off', inv_off_proc)
							respond 'You have disabled viewing of inventory and container windows.'
							LichSettings[XMLData.player_id]['enable_inventory_boxes'] = false
							LichSettings.save
						end
						nil
					else
						client_string
					end
				}
				UpstreamHook.add('inventory_boxes_toggle', inv_toggle_proc)

				unless $offline_mode
					client_string = $_CLIENT_.gets
					$_SERVER_.write(client_string)
					client_string = $_CLIENT_.gets
					$_CLIENTBUFFER_.push(client_string.dup)
					$_SERVER_.write(client_string)
				end
			end

			begin
				while client_string = $_CLIENT_.gets
					client_string = "#{$cmd_prefix}#{client_string}" if $frontend =~ /^(?:wizard|avalon)$/
					begin
						$_IDLETIMESTAMP_ = Time.now
						if Alias.find(client_string)
							Alias.run(client_string)
						else
							do_client(client_string)
						end
					rescue
						respond "--- error: client_thread: #{$!}"
						respond $!.backtrace.first
						$stderr.puts "error: client_thread: #{$!}"
						$stderr.puts $!.backtrace
					end
				end
			rescue
				respond "--- error: client_thread: #{$!}"
				respond $!.backtrace.first
				$stderr.puts "error: client_thread: #{$!}"
				$stderr.puts $!.backtrace
				sleep "0.2".to_f
				retry unless $_CLIENT_.closed? or $_SERVER_.closed? or !server_thread.alive?
			end
			server_thread.kill rescue()
		}
	end

	# fixme: bare bones

	wait_while { $offline_mode }

	if $frontend == 'wizard'
		$link_highlight_start = "\207"
		$link_highlight_end = "\240"
		$speech_highlight_start = "\212"
		$speech_highlight_end = "\240"
	end

	last_server_thread_recv = Time.now
	server_thread = nil

	Thread.new {
		loop {
			if last_server_thread_recv + 300 < Time.now
				$stderr.puts "#{Time.now}: error: nothing recieved from server in 5 minutes"
				server_thread.kill rescue()
			end
			sleep (300 - (Time.now - last_server_thread_recv))
			sleep 1
		}
	}

	server_thread = Thread.new {
		begin
			while $_SERVERSTRING_ = $_SERVER_.gets
				last_server_thread_recv = Time.now
				begin
					$cmd_prefix = String.new if $_SERVERSTRING_ =~ /^\034GSw/
					# The Rift, Scatter is broken...
					if $_SERVERSTRING_ =~ /<compDef id='room text'><\/compDef>/
						$_SERVERSTRING_.sub!(/(.*)\s\s<compDef id='room text'><\/compDef>/)  { "<compDef id='room desc'>#{$1}</compDef>" }
					end
					# Cry For Help spell is broken...
					if $_SERVERSTRING_ =~ /<pushStream id="familiar" \/><prompt time="[0-9]+">&gt;<\/prompt>/
						$_SERVERSTRING_.sub!('<pushStream id="familiar" />', '')
					end
					$_SERVERBUFFER_.push($_SERVERSTRING_)
					if alt_string = DownstreamHook.run($_SERVERSTRING_)
						if $frontend =~ /^(?:wizard|avalon)$/
							alt_string = sf_to_wiz(alt_string)
						end
						$_CLIENT_.write(alt_string)
					end
					unless $_SERVERSTRING_ =~ /^<setting/
						begin
							REXML::Document.parse_stream($_SERVERSTRING_, XMLData)
							# XMLData.parse($_SERVERSTRING_)
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
							unless line =~ /^\s\*\s[A-Z][a-z]+ (?:returns home from a hard day of adventuring\.|joins the adventure\.|(?:is off to a rough start!  (?:H|She) )?just bit the dust!|was just incinerated!|was just vaporized!|has been vaporized!|has disconnected\.)$|^ \* The death cry of [A-Z][a-z]+ echoes in your mind!$|^\r*\n*$/
								Script.new_downstream(line) unless line.empty?
							end
						}
					end
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
		output      = "**\n"
		output.concat "** NOTICE:\n"
		output.concat "**\n"
		output.concat "** Lich is not intended to facilitate AFK scripting.\n"
		output.concat "** The authors do not condone violation of game policy,\n"
		output.concat "** nor are they in any way attempting to encourage it.\n"
		output.concat "**\n"
		output.concat "** (this notice probably won't repeat) \n"
		output.concat "**\n"
		respond output
		LichSettings['seen_notice'] = true
		LichSettings.save
	end

	server_thread.join
	client_thread.kill rescue()

	$stderr.puts 'info: stopping scripts...'
	Script.running.each { |script| script.kill }
	Script.hidden.each { |script| script.kill }
	100.times { sleep "0.1".to_f; break if Script.running.empty? and Script.hidden.empty? }
	$stderr.puts 'info: saving script data...'
	UserVariables.save
	Settings.save_all
	GameSettings.save_all
	CharSettings.save_all
	# sending quit seems to cause Lich to hang.  $_SERVER_.closed? is false even though it appears to be closed.
	# $_SERVER_.puts('quit') unless $_SERVER_.closed?
	$stderr.puts 'info: closing connections...'
	$_SERVER_.close rescue()
	$_CLIENT_.close rescue()
	reconnect_if_wanted.call
	$stderr.puts "info: exiting..."
	Gtk.queue { Gtk.main_quit } if HAVE_GTK
	exit
}

if HAVE_GTK
	Thread.current.priority = -10
	Gtk.main
else
	main_thread.join
	exit
end
