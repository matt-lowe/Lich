#!/usr/bin/env ruby
=begin
 version 3.67
=end
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

if $version
	# This file is in the repository as lich-update.lic.  Someone will probably try to run it from within Lich.
	echo "Don't do that."
	exit
end

require 'time'
require 'socket'
include Socket::Constants
require 'rexml/document'
require 'rexml/streamlistener'
require 'zlib'
require 'stringio'
include REXML
begin
	require 'win32/registry'
	HAVE_REGISTRY = true
rescue LoadError
	HAVE_REGISTRY = false
rescue
	HAVE_REGISTRY = false
end

#
# start pqueue.rb
#

# Priority queue with array based heap.
#
# This is distributed freely in the sence of 
# GPL(GNU General Public License).
#
# K.Kodama 2005/09/01.  push_array, pop_array
# Rick Bradley 2003/02/02. patch for Ruby 1.6.5. Thank you!
# K.Kodama 2001/03/10. 1st version

class PQueue

	attr_accessor :qarray # format: [nil, e1, e2, ..., en]
	attr_reader :size # number of elements
	attr_reader :gt # compareProc
	
	def initialize(compareProc=lambda{|x,y| x>y})
		# By default, retrieves maximal elements first. 
		@qarray=[nil]; @size=0; @gt=compareProc; make_legal
	end
	private :initialize

	def upheap(k)
		k2=k.div(2); v=@qarray[k];
		while ((k2>0)and(@gt[v,@qarray[k2]]));
			@qarray[k]=@qarray[k2]; k=k2; k2=k2.div(2)
		end;
		@qarray[k]=v;
	end
	private :upheap

	def downheap(k)
		v=@qarray[k]; q2=@size.div(2)
		loop{
			if (k>q2); break; end;
			j=k+k; if ((j<@size)and(@gt[@qarray[j+1],@qarray[j]])); j=j+1; end;
			if @gt[v,@qarray[j]]; break; end;
			@qarray[k]=@qarray[j]; k=j;
		}
		@qarray[k]=v;
	end;
	private :downheap

	def make_legal
		for k in 2..@size do; upheap(k); end;
	end;

	def empty?
		return (0==@size)
	end

	def clear
		@qarray.replace([nil]); @size=0;
	end;

	def replace_array(arr=[])
		# Use push_array.
		@qarray.replace([nil]+arr); @size=arr.size; make_legal
	end;
	
	def clone
		q=new; q.qarray=@qarray.clone; q.size=@size; q.gt=@gt; return q;
	end;

	def push(v)
		@size=@size+1; @qarray[@size]=v; upheap(@size);
	end;

	def push_array(arr=[])
		@qarray[@size+1,arr.size]=arr; arr.size.times{@size+=1; upheap(@size)}
	end;

	def pop
		# return top element.  nil if queue is empty.
		if @size>0;
			res=@qarray[1]; @qarray[1]=@qarray[@size]; @size=@size-1;
			downheap(1);
			return res;
		else return nil
		end;
	end;

	def pop_array(n=@size)
		# return top n-element as an sorted array. (i.e. The obtaining array is decreasing order.)
		# See also to_a.
		a=[]
		n.times{a.push(pop)}
		return a
	end;
	
	def to_a
		# array sorted as increasing order.
		# See also pop_array.
		res=@qarray[1..@size];
		res.sort!{|x,y| if @gt[x,y]; 1;elsif @gt[y,x]; -1; else 0; end;}
		return res
	end

	def top
		# top element. not destructive.
		if @size>0; return @qarray[1]; else return nil; end;
	end;

	def replace_top_low(v)
		# replace top element if v<top element.
		if @size>0; @qarray[0]=v; downheap(0); return @qarray[0];
		else @qarray[1]=v; return nil;
		end;
	end;

	def replace_top(v)
		# replace top element
		if @size>0; res=@qarray[1]; @qarray[1]=v; downheap(1); return res;
		else @qarray[1]=v; return nil;
		end;
	end;

	def each_pop
		# iterate pop. destructive. Use as self.each_pop{|x| ... }. 
		while(@size>0); yield self.pop; end;
	end;

	def each_with_index
		# Not ordered. Use as self.each_with_index{|e,i| ... }. 
		for i in 1..@size do; yield @qarray[i],i; end;
	end

end # class pqueue
#
# end pqueue.rb
#

at_exit { [Script.running + Script.hidden].each { |script| script.kill }; Process.waitall }

# fixme: warlock
# fixme: terminal mode

$injuries = Hash.new; ['nsys','leftArm','rightArm','rightLeg','leftLeg','head','rightFoot','leftFoot','rightHand','leftHand','rightEye','leftEye','back','neck','chest','abdomen'].each { |area| $injuries[area] = { 'wound' => 0, 'scar' => 0 } }
$injury_mode = 0

$prepared_spell = 'None'

# $poisons = Array.new
# $diseases = Array.new

$indicator = Hash.new

$room_title = String.new
$room_description = String.new
$room_exits = Array.new

$familiar_room_title = String.new
$familiar_room_description = String.new
$familiar_room_exits = Array.new

$room_count = 0

$last_dir = String.new

$spellfront = Array.new

INFINITY = 1 << 32

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
	attr_accessor :max_shove_size
	def shove(line)
		@max_shove_size ||= 300
		self.push(line)
		self.delete_at(0) if self.length > @max_shove_size
	end
	def method_missing(*usersave)
		self
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

def make_wound_gsl
	$wound_gsl = sprintf("0b0%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b",$injuries['nsys']['wound'],$injuries['leftEye']['wound'],$injuries['rightEye']['wound'],$injuries['back']['wound'],$injuries['abdomen']['wound'],$injuries['chest']['wound'],$injuries['leftHand']['wound'],$injuries['rightHand']['wound'],$injuries['leftLeg']['wound'],$injuries['rightLeg']['wound'],$injuries['leftArm']['wound'],$injuries['rightArm']['wound'],$injuries['neck']['wound'],$injuries['head']['wound'])
end

def make_scar_gsl
	$scar_gsl = sprintf("0b0%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b%02b",$injuries['nsys']['scar'],$injuries['leftEye']['scar'],$injuries['rightEye']['scar'],$injuries['back']['scar'],$injuries['abdomen']['scar'],$injuries['chest']['scar'],$injuries['leftHand']['scar'],$injuries['rightHand']['scar'],$injuries['leftLeg']['scar'],$injuries['rightLeg']['scar'],$injuries['leftArm']['scar'],$injuries['rightArm']['scar'],$injuries['neck']['scar'],$injuries['head']['scar'])
end

class SF_XML
	include StreamListener
	@@bold ||= false
	@@active_tags ||= Array.new
	@@active_ids ||= Array.new
	@@current_stream ||= String.new
	@@current_style ||= String.new
	@@stow_container ||= nil
	@@obj_exist ||= nil
	@@obj_noun ||= nil
	@@player_dead ||= nil
	@@player_stunned ||= nil
	@@fam_mode ||= String.new
	@@room_window_disabled ||= false

	def tag_start(name, attributes)
		begin
			@@active_tags.push(name)
			@@active_ids.push(attributes['id'].to_s)
			if name == 'pushStream'
				$room_count += 1 if attributes['id'] == 'room'
				@@current_stream = attributes['id'].to_s
				GameObj.clear_inv if attributes['id'].to_s == 'inv'
			elsif name == 'popStream'
				@@current_stream = String.new
			elsif name == 'pushBold'
				@@bold = true
			elsif name == 'popBold'
				@@bold = false
			elsif name == 'style'
				@@current_style = attributes['id']
			elsif name == 'prompt'
				$server_time = attributes['time'].to_i
				$server_time_offset = (Time.now.to_i - $server_time)
				$_CLIENT_.puts "\034GSq#{sprintf('%010d', $server_time)}\r\n" if $send_fake_tags
			elsif (name == 'compDef') or (name == 'component')
				if attributes['id'] == 'room objs'
					GameObj.clear_loot
					GameObj.clear_npcs
				elsif attributes['id'] == 'room players'
					GameObj.clear_pcs
				elsif attributes['id'] == 'room exits'
					$room_exits = Array.new
					$room_exits_string = String.new
				elsif attributes['id'] == 'room desc'
					$room_description = String.new
					GameObj.clear_room_desc
				#elsif attributes['id'] == 'sprite'
				end
			elsif (name == 'a') or (name == 'right') or (name == 'left')
				@@obj_exist = attributes['exist']
				@@obj_noun = attributes['noun']
				if @@active_tags.include?('inv') and @@active_ids.include?('stow') and @@stow_container.nil?
					@@stow_container = attributes['exist']
					GameObj.clear_container(@@stow_container)
				end
			elsif (name == 'clearContainer') and (attributes['id'] == 'stow')
				@@stow_container = nil
			elsif name == 'progressBar'
				if attributes['id'] == 'pbarStance'
					$stance_text = attributes['text'].split.first
					$stance_value = attributes['value'].to_i
					$_CLIENT_.puts "\034GSg#{sprintf('%010d', $stance_value)}\r\n" if $send_fake_tags
				elsif attributes['id'] == 'mana'
					last_mana = $mana
					$mana, $max_mana = attributes['text'].scan(/-?\d+/)
					$mana = $mana.to_i
					$max_mana = $max_mana.to_i
					if $send_fake_tags
						difference = $mana - last_mana
						if (difference == noded_pulse) or (difference == unnoded_pulse) or ( ($mana == $max_mana) and (last_mana + noded_pulse > $max_mana) )
							$_CLIENT_.puts "\034GSZ#{sprintf('%010d',($mana+1))}\n"
							$_CLIENT_.puts "\034GSZ#{sprintf('%010d',$mana)}\n"
						end
						$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', $max_health, $health, $max_spirit, $spirit, $max_mana, $mana, $wound_gsl, $scar_gsl)}\r\n"
					end
				elsif attributes['id'] == 'stamina'
					$stamina, $max_stamina = attributes['text'].scan(/-?\d+/)
					$stamina = $stamina.to_i
					$max_stamina = $max_stamina.to_i
				elsif attributes['id'] == 'mindState'
					$mind_text = attributes['text']
					$mind_value = attributes['value'].to_i
					$_CLIENT_.puts "\034GSr#{MINDMAP[$mind_text]}\r\n" if $send_fake_tags
				elsif attributes['id'] == 'health'
					$health, $max_health = attributes['text'].scan(/-?\d+/)
					$health = $health.to_i
					$max_health = $max_health.to_i
					$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', $max_health, $health, $max_spirit, $spirit, $max_mana, $mana, $wound_gsl, $scar_gsl)}\r\n" if $send_fake_tags
				elsif attributes['id'] == 'spirit'
					$spirit, $max_spirit = attributes['text'].scan(/-?\d+/)
					$spirit = $spirit.to_i
					$max_spirit = $max_spirit.to_i
					$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', $max_health, $health, $max_spirit, $spirit, $max_mana, $mana, $wound_gsl, $scar_gsl)}\r\n" if $send_fake_tags
				elsif attributes['id'] == 'nextLvlPB'
					$next_level_value = attributes['value'].to_i
					$next_level_text = attributes['text']
				elsif attributes['id'] == 'encumlevel'
					$encumbrance_value = attributes['value'].to_i
					$encumbrance_text = attributes['text']
				end
			elsif name == 'roundTime'
				$roundtime_end = attributes['value'].to_i
				$_CLIENT_.puts "\034GSQ#{sprintf('%010d', $roundtime_end)}\r\n" if $send_fake_tags
			elsif name == 'castTime'
				$cast_roundtime_end = attributes['value'].to_i
			elsif name == 'indicator'
				$indicator[attributes['id']] = attributes['visible']
=begin
				# fixme: This seems to work, but sends health too often, not just on the initial poison or disease
				if (attributes['id'] == 'IconPOISONED' or attributes['id'] == 'IconDISEASED') and (attributes['visible'] == 'y')
					action = proc { |server_string|
						if $poison_tracker_active
							if server_string =~ /<output class=['"]['"]\/>/
								$poison_tracker_active = false
								DownstreamHook.remove('poison')
								return server_string
							elsif server_string =~ /^Poisoned!  Taking ([0-9]+) damage per round.  Dissipating ([0-9]+) per round\./
								$poisons.push([$1,$2,Time.now.to_i])
								return nil
							elsif server_string =~ /^Diseased!  Taking ([0-9]+) damage per round.  Dissipating ([0-9]+) per round\./
								$diseases.push([$1,$2,Time.now.to_i])
								return nil
							else
								return nil
							end
						else
							if server_string =~ /<output class=['"]mono['"]\/>/
								$poison_tracker_active = true
								$poisons = Array.new
								$diseases = Array.new
							end
							return server_string
						end
					}
					$poison_tracker_active = false
					DownstreamHook.add('poison', action)
					$_SERVER_.puts "<c>health\n"
				end
=end
				if $send_fake_tags
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
						gsl_prompt = String.new; ICONMAP.keys.each { |icon| gsl_prompt += ICONMAP[icon] if $indicator[icon] == 'y' }
						$_CLIENT_.puts "\034GSP#{sprintf('%-30s', gsl_prompt)}\r\n"
					end
				end
			elsif name == 'image'
				if $injuries.keys.include?(attributes['id'])
					if attributes['name'] =~ /Injury/i
						$injuries[attributes['id']]['wound'] = attributes['name'].slice(/\d/).to_i
					elsif attributes['name'] =~ /Scar/i
						$injuries[attributes['id']]['wound'] = 0
						$injuries[attributes['id']]['scar'] = attributes['name'].slice(/\d/).to_i
					elsif attributes['name'] =~ /Nsys/i
						rank = attributes['name'].slice(/\d/).to_i
						if rank == 0
							$injuries['nsys']['wound'] = 0
							$injuries['nsys']['scar'] = 0
						elsif ($injuries['nsys']['wound'] == 0) and ($injuries['nsys']['scar'] == 0)
							$injuries['nsys']['wound'] = rank
						elsif $injuries['nsys']['wound'] > 1
							$injuries['nsys']['wound'] = rank
						elsif $injuries['nsys']['wound'] == 1
							$injuries['nsys']['wound'] = 0
							$injuries['nsys']['scar'] = rank
						else
							$injuries['nsys']['scar'] = rank
						end
					else
						$injuries[attributes['id']]['wound'] = 0
						$injuries[attributes['id']]['scar'] = 0
					end
				end
				$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', $max_health, $health, $max_spirit, $spirit, $max_mana, $mana, make_wound_gsl, make_scar_gsl)}\r\n" if $send_fake_tags
			elsif (name == 'streamWindow') and (attributes['id'] == 'main') and attributes['subtitle']
				$room_title = '[' + attributes['subtitle'][3..-1] + ']'
			elsif name == 'compass'
				if @@current_stream == 'familiar'
					@@fam_mode = String.new
				elsif @@room_window_disabled
					$room_exits = Array.new
					#$room_exits_string = String.new
				end
			elsif @@room_window_disabled and (name == 'dir') and @@active_tags.include?('compass')
				$room_exits.push(LONGDIR[attributes['value']])
				#$room_exits_string.concat(LONGDIR[attributes['value']] + ', ')
			elsif name == 'radio'
				if attributes['id'] == 'injrRad'
					$injury_mode = 0 if attributes['value'] == '1'
				elsif attributes['id'] == 'scarRad'
					$injury_mode = 1 if attributes['value'] == '1'
				elsif attributes['id'] == 'bothRad'
					$injury_mode = 2 if attributes['value'] == '1'
				end
			elsif name == 'label'
				if attributes['id'] == 'yourLvl'
					Stats.level = attributes['value'].slice(/\d+/).to_i
				elsif attributes['id'] == 'encumblurb'
					$encumbrance_full_text = attributes['value']
				end
			elsif name == 'app'
				Char.init(attributes['char']) if attributes['char'] and !attributes['char'].strip.empty?
				if $fake_stormfront
					# fixme: game name hardcoded as Gemstone IV; maybe doesn't make any difference to the client.
					if Char.name
						$_CLIENT_.puts "\034GSB0000000000#{Char.name}\r\n\034GSA#{Time.now.to_i.to_s}GemStone IV\034GSD\r\n"
					else
						$_CLIENT_.puts "\034GSB0000000000Noname}\r\n\034GSA#{Time.now.to_i.to_s}GemStone IV\034GSD\r\n"
					end
					# Sending fake GSL tags to the Wizard FE is disabled until now, because it doesn't accept the tags and just gives errors until initalized with the above line
					$send_fake_tags = true
					# Send all the tags we missed out on
					$_CLIENT_.puts "\034GSV#{sprintf('%010d%010d%010d%010d%010d%010d%010d%010d', $max_health, $health, $max_spirit, $spirit, $max_mana, $mana, make_wound_gsl, make_scar_gsl)}\r\n"
					$_CLIENT_.puts "\034GSg#{sprintf('%010d', $stance_value)}\r\n"
					$_CLIENT_.puts "\034GSr#{MINDMAP[$mind_text]}\r\n"
					gsl_prompt = String.new
					$indicator.keys.each { |icon| gsl_prompt += ICONMAP[icon] if $indicator[icon] == 'y' }
					$_CLIENT_.puts "\034GSP#{sprintf('%-30s', gsl_prompt)}\r\n"
					gsl_prompt = nil
					gsl_exits = String.new
					$room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
					$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
					gsl_exits = nil
					$_CLIENT_.puts "\034GSn#{sprintf('%-14s', $prepared_spell)}\r\n"
					$_CLIENT_.puts "\034GSm#{sprintf('%-45s', GameObj.right_hand.name)}\r\n"
					$_CLIENT_.puts "\034GSl#{sprintf('%-45s', GameObj.left_hand.name)}\r\n"
					$_CLIENT_.puts "\034GSq#{sprintf('%010d', $server_time)}\r\n"
					$_CLIENT_.puts "\034GSQ#{sprintf('%010d', $roundtime_end)}\r\n"
				end

			end
		rescue
			respond "--- Lich: error in parser_thread (#{$!})"
			$stderr.puts $!.backtrace.join("\r\n")
			sleep 0.1
		end
	end
	def text(text)
		begin
			if @@active_tags.include?('prompt')
				$prompt = text
			elsif @@active_tags.include?('right')
				GameObj.new_right_hand(@@obj_exist, @@obj_noun, text)
				$_CLIENT_.puts "\034GSm#{sprintf('%-45s', text)}\r\n" if $send_fake_tags
			elsif @@active_tags.include?('left')
				GameObj.new_left_hand(@@obj_exist, @@obj_noun, text)
				$_CLIENT_.puts "\034GSl#{sprintf('%-45s', text)}\r\n" if $send_fake_tags
			elsif @@active_tags.include?('spell')
				$prepared_spell = text
				$_CLIENT_.puts "\034GSn#{sprintf('%-14s', text)}\r\n" if $send_fake_tags
			elsif @@active_tags.include?('compDef') or @@active_tags.include?('component')
				if @@active_ids.include?('room objs')
					if @@active_tags.include?('a')
						if @@bold
							GameObj.new_npc(@@obj_exist, @@obj_noun, text)
						else
							GameObj.new_loot(@@obj_exist, @@obj_noun, text)
						end
					elsif (text =~ /that (?:is|appears) ([\w\s]+)(?:,| and|\.)/) or (text =~ / \(([^\(]+)\)/)
						GameObj.npcs[-1].status = $1
					end
				elsif @@active_ids.include?('room players')
					if @@active_tags.include?('a')
						GameObj.new_pc(@@obj_exist, @@obj_noun, @@player_title.to_s + text)
						GameObj.pcs[-1].status = 'dead' if @@player_dead
						GameObj.pcs[-1].status = 'stunned' if @@player_stunned
					else
						if (text =~ /^ who (?:is|appears) ([\w\s]+)(?:,| and|\.|$)/) or (text =~ / \(([\w\s]+)\)/)
							GameObj.pcs[-1].status = $1 unless @@player_dead or @@player_stunned
						end
						if text =~ /(?:^Also here: |, )(the body of )?(a stunned )?([\w\s]+)?$/
							@@player_dead = $1
							@@player_stunned = $2
							@@player_title = $3
						end
					end
				elsif @@active_ids.include?('room desc')
					if text == '[Room window disabled at this location.]'
						#respond '[Room window disabled at this location.]'
						@@room_window_disabled = true
					else
						@@room_window_disabled = false
						$room_description.concat(text)
						if @@active_tags.include?('a')
							GameObj.new_room_desc(@@obj_exist, @@obj_noun, text)
						end
					end
				elsif @@active_ids.include?('room exits')
					$room_exits_string.concat(text)
					$room_exits.push(text) if @@active_tags.include?('d')
				end
			elsif @@active_tags.include?('a') and @@active_tags.include?('inv') and @@active_ids.include?('stow') and not @@stow_container.nil? and @@stow_container != @@obj_exist
				obj = GameObj.new_inv(@@obj_exist, @@obj_noun, text, @@stow_container)
			elsif @@current_stream == 'spellfront'
				$spellfront = text.split("\n")
			elsif @@current_stream == 'bounty'
				$bounty_task = text.strip
			elsif @@current_stream == 'society'
				$society_task = text
			elsif (@@current_stream == 'inv') and @@active_tags.include?('a')
				GameObj.new_inv(@@obj_exist, @@obj_noun, text, nil)
			elsif @@current_stream == 'familiar'
				# fixme: familiar room tracking does not (can not?) auto update, status of pcs and npcs isn't tracked at all, titles of pcs aren't tracked
				if @@current_style == 'roomName'
					$familiar_room_title = text
					$familiar_room_description = String.new
					$familiar_room_exits = Array.new
					GameObj.clear_fam_room_desc
					GameObj.clear_fam_loot
					GameObj.clear_fam_npcs
					GameObj.clear_fam_pcs
					@@fam_mode = String.new
				elsif @@current_style == 'roomDesc'
					$familiar_room_description.concat(text)
					if @@active_tags.include?('a')
						GameObj.new_fam_room_desc(@@obj_exist, @@obj_noun, text)
					end
				elsif text =~ /^You also see/
					@@fam_mode = 'things'
				elsif text =~ /^Also here/
					@@fam_mode = 'people'
				elsif text =~ /Obvious (?:paths|exits)/
					@@fam_mode = 'paths'
				elsif @@fam_mode == 'things'
					if @@active_tags.include?('a')
						if @@bold
							GameObj.new_fam_npc(@@obj_exist, @@obj_noun, text)
						else
							GameObj.new_fam_loot(@@obj_exist, @@obj_noun, text)
						end
					end
					# respond 'things: ' + text
				elsif @@fam_mode == 'people' and @@active_tags.include?('a')
					GameObj.new_fam_pc(@@obj_exist, @@obj_noun, text)
					# respond 'people: ' + text
				elsif (@@fam_mode == 'paths') and @@active_tags.include?('a')
					$familiar_room_exits.push(text)
				end
			elsif @@room_window_disabled
				if @@current_style == 'roomDesc'
					$room_description.concat(text)
					if @@active_tags.include?('a')
						GameObj.new_room_desc(@@obj_exist, @@obj_noun, text)
					end
				elsif text =~ /^Obvious (?:paths|exits): $/
					$room_exits_string = text.strip
				end
			end
		rescue
			respond "--- Lich: error in parser_thread (#{$!})"
			$stderr.puts $!.backtrace.join("\r\n")
			sleep 0.1
		end
	end
	def tag_end(name)
		begin
			if $send_fake_tags and (@@active_ids.last == 'room exits')
				gsl_exits = String.new
				$room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
				$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
				gsl_exits = nil
			elsif @@room_window_disabled and (name == 'compass')
				@@room_window_disabled = false
				$room_description = $room_description.strip
				$room_exits_string = $room_exits_string + ' ' + $room_exits.join(', ')
				gsl_exits = String.new
				$room_exits.each { |exit| gsl_exits.concat(DIRMAP[SHORTDIR[exit]].to_s) }
				$_CLIENT_.puts "\034GSj#{sprintf('%-20s', gsl_exits)}\r\n"
				gsl_exits = nil
			end
			@@active_tags.pop
			@@active_ids.pop
		rescue
			respond "--- Lich: error in parser_thread (#{$!})"
			$stderr.puts $!.backtrace.join("\r\n")
			sleep 0.1
		end
	end
end

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
			client_string = @@upstream_hooks[key].call(client_string)
			return nil if client_string.nil?
		end
		return client_string
	end
	def UpstreamHook.remove(name)
		@@upstream_hooks.delete(name)
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
			server_string = @@downstream_hooks[key].call(server_string)
			return nil if server_string.nil?
		end
		return server_string
	end
	def DownstreamHook.remove(name)
		@@downstream_hooks.delete(name)
	end
end

class Alias
	@@regex_string ||= String.new
	@@alias_hash ||= Hash.new
	def Alias.add(trigger, target)
		@@alias_hash[trigger.downcase] = target
		@@regex_string = @@alias_hash.keys.join('|')
	end
	def Alias.delete(trigger)
		which = @@alias_hash.keys.find { |key| key == trigger.downcase }
		@@alias_hash.delete(which) if which
		@@regex_string = @@alias_hash.keys.join('|')
	end
	def Alias.find(trigger)
		return nil if (trigger == nil) or trigger.empty? or @@regex_string.empty?
		/^(?:<c>)?(#{@@regex_string})\b/i.match(trigger).captures.first
	end
	def Alias.list
		@@alias_hash.dup
	end
	def Alias.run(trig)
		/^(?:<c>)?(#{@@regex_string})\b(?:\s*)?(.*)$/i.match(trig)
		trigger, extra = $1, $2
		unless target = @@alias_hash[trigger].dup
			respond '--- Lich: tried to run unkown alias (' + trig.to_s + ')'
			return false
		end
		unless extra.empty?
			if target.include?('\?')
				target.gsub!('\?', extra)
			else
				target.concat(' ' + extra)
			end
		end
		target.gsub!('\?', '')
		target.split('\r').each { |str| do_client(str.chomp + "\n") }
	end
end

class Script
	@@running ||= Array.new
	attr_reader :name, :thread_group, :vars, :safe, :labels, :file_name, :label_order
	attr_accessor :quiet_exit, :no_echo, :jump_label, :current_label, :want_downstream, :want_downstream_xml, :want_upstream, :dying_procs, :hidden, :paused, :silent, :no_pause_all, :no_kill_all, :downstream_buffer, :upstream_buffer, :unique_buffer, :die_with, :match_stack_labels, :match_stack_strings
	def initialize(file_name, cli_vars=[])
		@name = /.*[\/\\]+([^\.]+)\./.match(file_name).captures.first
		@file_name = file_name
		@vars = Array.new
		unless cli_vars.empty?
			cli_vars.each_index { |idx| @vars[idx+1] = cli_vars[idx] }
			@vars[0] = @vars[1..-1].join(' ')
			cli_vars = nil
		end
		if vars.include?('quiet')
			vars.delete('quiet')
			@quiet_exit = true
		else
			@quiet_exit = false
		end
		@downstream_buffer = Array.new
		@want_downstream = true
		@want_downstream_xml = false
		@upstream_buffer = Array.new
		@want_upstream = false
		@unique_buffer = Array.new
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
		@@running.push(self)
		@label_order = Array.new
		@labels = Hash.new
		begin
			crit = Thread.critical
			Thread.critical = true
			begin
				file = nil
				file = Zlib::GzipReader.open(file_name)
			rescue
				file.close rescue()
				file = File.open(file_name)
			end
			if file.gets =~ /^[\t\s]*#?[\t\s]*(?:quiet|hush)\r?$/i
				@quiet_exit = true
			end
			file.rewind
			ary = ("\n" + file.read).split(/\r?\n([\d_\w]+:)\s*\r?\n/)
		ensure	
			file.close
			file = nil
			Thread.critical = crit
		end
		@current_label = '~start'
		@label_order.push(@current_label)
		for line in ary
			if line =~ /^([\d_\w]+):$/
				@current_label = $1
				@label_order.push(@current_label)
			else
				@labels[@current_label] = line
			end
		end
		@current_label = @label_order[0]
		@thread_group = ThreadGroup.new
		return self
	end
	def add_thread(the_thread)
		@thread_group.add(the_thread)
	end
	def kill
		Thread.new {
			@thread_group.add(Thread.current)
			@paused = false
			script = Script.self
			dying_procs = @dying_procs.dup
			@dying_procs.clear
			@dying_procs = nil
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
			die_with = @die_with.dup
			@die_with = nil
			die_with.each { |script_name| stop_script script_name }
			@thread_group.list.each { |thr|
				if (thr != Thread.current) and thr.alive?
					thr.kill rescue()
				end
			}
			@downstream_buffer.clear
			@downstream_buffer = nil
			@upstream_buffer.clear
			@upstream_buffer = nil
			@match_stack_labels.clear
			@match_stack_labels = nil
			@match_stack_strings.clear
			@match_stack_strings = nil
			@@running.delete(self)
			respond("--- Lich: #{@name} has exited.") unless @quiet_exit
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
		while script.paused; sleep 0.2; end
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
			script.downstream_buffer.shove(line.chomp) if script.want_downstream
		end
	end
	def Script.new_downstream_xml(line)
		for script in @@running
			script.downstream_buffer.shove(line.chomp) if script.want_downstream_xml
		end
	end
	def Script.new_upstream(line)
		for script in @@running
			script.upstream_buffer.shove(line.chomp) if script.want_upstream
		end
	end
	def gets
		if @want_downstream or @want_downstream_xml
			sleep 0.05 while @downstream_buffer.length < 1
			@downstream_buffer.shift
		else
			echo 'this script is set as unique but is waiting for game data...'
			sleep 2
			false
		end
	end
	def upstream_gets
		sleep 0.05 while @upstream_buffer.length < 1
		@upstream_buffer.shift
	end
	def unique_gets
		sleep 0.05 while @unique_buffer.length < 1
		@unique_buffer.shift
	end
	def safe?
		@safe
	end
	# for backwards compatability
	def Script.namescript_incoming(line)
		Script.new_downstream(line)
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
		@downstream_buffer = Array.new
		@want_downstream = true
		@want_downstream_xml = false
		@upstream_buffer = Array.new
		@want_upstream = false
		@dying_procs = Array.new
		@hidden = false
		@paused = false
		@silent = false
		@quiet_exit = quiet
		@safe = false
		@no_echo = false
		@thread_group = ThreadGroup.new
		@unique_buffer = Array.new
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

# fixme: class WizardScript<Script

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
			if File.exists?($script_dir + script.to_s + ".sav")
				File.rename($script_dir + script.to_s + ".sav",
				            $data_dir + script.to_s + ".sav")
			end
			file = File.open($data_dir + script.to_s + '.sav', 'wb')
			file.write(Marshal.dump(if @@hash[script.to_s] then @@hash[script.to_s] else {} end))
			file.close
		else
			raise Exception.exception("SettingsError"), "The script trying to save its data cannot be identified!"
		end
	end
	def Settings.autoload
		if File.exists?($script_dir + Script.self.to_s + ".sav")
			File.rename($script_dir + Script.self.to_s + ".sav",
			            $data_dir + Script.self.to_s + ".sav")
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
			unless who.include?(".")
				who += ".sav"
			end
			begin
				if File.exists?($script_dir + who)
					File.rename($script_dir + who, $data_dir + who)
				end
				file = File.open($data_dir + who, 'rb')
				@@hash[who.sub(/\..*/, '')] = Marshal.load(file.read)
			rescue
				$stderr.puts $!
				$stderr.puts $!.backtrace
			ensure
				file.close unless file.closed?
			end
			return
		end
		if script = Script.self
			if File.exists?($script_dir + script.to_s + '.sav')
				File.rename($script_dir + script.to_s + ".sav",
				            $data_dir + script.to_s + ".sav")
			end
			if File.exists?($data_dir + script.to_s + ".sav")
				begin
					file = File.open($data_dir + script.to_s + '.sav', 'rb')
					data = Marshal.load(file.read)
					file.close
					@@hash[script.to_s] = data
				rescue
					puts $!
				ensure
					file.close unless file.closed?
				end
			else
				nil
			end
		else
			raise Exception.exception("SettingsError"), "The script trying to load data cannot be identified!"
		end
	end
	def Settings.clear
		unless script = Script.self then raise Exception.exception("SettingsError"), "The script trying to access settings cannot be identified!" end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s].clear
	end
	def Settings.[](val)
		Settings.autoload if @@auto
		unless script = Script.self then raise Exception.exception("SettingsError"), "The script trying to access settings cannot be identified!" end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s][val]
	end
	def Settings.[]=(setting, val)
		unless script = Script.self then raise Exception.exception("SettingsError"), "The script trying to access settings cannot be identified!" end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s][setting] = val
		Settings.save if @@auto
		@@hash[script.to_s][setting]
	end
	def Settings.to_hash
		unless script = Script.self then raise Exception.exception("SettingsError"), "The script trying to access settings cannot be identified!" end
		unless @@hash[script.to_s] then @@hash[script.to_s] = {} end
		@@hash[script.to_s]
	end
end

class String
	def split_as_list
		string = self
		string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
		string.sub('.','').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str|
			str.strip.empty?
		}.collect { |str| str.lstrip }
	end
end
	
class Char
	@@cha ||= nil
	@@name ||= nil
	private_class_method :new
	def Char.init(name)
		@@name = name.strip if @@name == nil or @@name.strip.empty?
		start_script('favs.lic', [ 'load' ]) if File.exists?($script_dir + 'favs.lic')
	end
	def Char.name
		if (!@@name or @@name.strip.empty?)
			appline = $_SERVERBUFFER_.find { |line| line =~ /<app char=['"][^'"]+['"]/i }
			appline =~ /char=['"]([^'"]+)['"]/i
			@@name = $1
		end
		@@name
	end
	def Char.name=(name)
		@@name = name
	end
	def Char.health(*args)
		checkhealth(*args)
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
		save = Thread.critical
		begin
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
		ensure
			Thread.critical = save
		end
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
		(Spellsong.duration - (Time.now - @@renewed)) / 60.00
	end
	def Spellsong.serialize
		Spellsong.timeleft
	end
	def Spellsong.load_serialized=(old)
		Thread.new {
			n = 0
			while Stats.level == 0
				sleep 0.25
				n += 1
				break if n >= 4
			end
			unless n >= 4
				@@renewed = Time.at(Time.now.to_f - (Spellsong.duration - old * 60.00))
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
		10 + (Spells.bard / 2).round
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
		if val == "1" then "Minor Spirit"
		elsif val == "2" then "Major Spirit"
		elsif val == "3" then "Cleric"
		elsif val == "4" then "Minor Elemental"
		elsif val == "5" then "Major Elemental"
		elsif val == "6" then "Ranger"
		elsif val == "7" then "Sorcerer"
		elsif val == "9" then "Wizard"
		elsif val == "10" then "Bard"
		elsif val == "11" then "Empath"
		elsif val == "16" then "Paladin"
		elsif val == "66" then "Death"
		elsif val == "65" then "Imbedded Enchantment"
		elsif val == "96" then "Combat Maneuvers"
		elsif val == "97" then "Guardians of Sunfist"
		elsif val == "98" then "Order of Voln"
		elsif val == "99" then "Council of Light"
		elsif val == "cm" then "Combat Maneuvers"
		elsif val == "mi" then "Miscellaneous"
		else 'Unknown Circle' end
	end
	def Spells.active
		Spell.active
	end
	def Spells.known
		ary = []
		Spell.list.each { |sp_obj|
			circlename = Spells.get_circle_name(sp_obj.circle)
			sym = circlename.delete("\s").downcase
			ranks = Spells.send(sym).to_i rescue()
			next unless ranks.nonzero?
			num = sp_obj.num.to_s[-2..-1].to_i
			ary.push sp_obj if ranks >= num
		}
		ary
	end
	def Spells.serialize
		[@@minorelemental,@@majorelemental,@@minorspiritual,@@majorspiritual,@@wizard,@@sorcerer,@@ranger,@@paladin,@@empath,@@cleric,@@bard]
	end
	def Spells.load_serialized=(val)
		@@minorelemental,@@majorelemental,@@minorspiritual,@@majorspiritual,@@wizard,@@sorcerer,@@ranger,@@paladin,@@empath,@@cleric,@@bard = val
	end
end

class Spell
	@@active ||= Array.new
	@@list ||= Array.new
	@@active_loaded ||= false
	attr_reader :timestamp, :num, :name, :duration, :timeleft, :msgup, :msgdn, :stacks, :circle, :circlename, :selfonly, :manaCost, :spiritCost, :staminaCost, :boltAS, :physicalAS, :boltDS, :physicalDS, :elementalCS, :spiritCS, :sorcererCS, :elementalTD, :spiritTD, :sorcererTD, :strength, :dodging, :active, :type
	def initialize(num,name,type,duration,manaCost,spiritCost,staminaCost,stacks,selfonly,msgup,msgdn,boltAS,physicalAS,boltDS,physicalDS,elementalCS,spiritCS,sorcererCS,elementalTD,spiritTD,sorcererTD,strength,dodging)
		@name,@type,@duration,@manaCost,@spiritCost,@staminaCost,@stacks,@selfonly,@msgup,@msgdn,@boltAS,@physicalAS,@boltDS,@physicalDS,@elementalCS,@spiritCS,@sorcererCS,@elementalTD,@spiritTD,@sorcererTD,@strength,@dodging = name,type,duration,manaCost,spiritCost,staminaCost,stacks,selfonly,msgup,msgdn,boltAS,physicalAS,boltDS,physicalDS,elementalCS,spiritCS,sorcererCS,elementalTD,spiritTD,sorcererTD,strength,dodging
		if num.to_i.nonzero? then @num = num.to_i else @num = num end
		@timestamp = Time.now
		@active = false
		@timeleft = 0
		@msgup = msgup
		@msgdn = msgdn
		@circle = (num.to_s.length == 3 ? num.to_s[0..0] : num.to_s[0..1])
		@circlename = Spells.get_circle_name(@circle)
		@@list.push(self) unless @@list.find { |spell| spell.name == @name }
	end
	def Spell.load(filename="#{$script_dir}spell-list.xml.txt")
		begin
			@@active.clear
			@@list.clear
			File.open(filename) { |file|
				file.read.split(/<\/spell>.*?<spell>/m).each { |spell_data| 
					spell = Hash.new
					spell_data.split("\n").each { |line| if line =~ /<(number|name|type|duration|manaCost|spiritCost|staminaCost|stacks|selfonly|msgup|msgdown|boltAS|physicalAS|boltDS|physicalDS|elementalCS|spiritCS|sorcererCS|elementalTD|spiritTD|sorcererTD|strength|dodging)[^>]*>([^<]*)<\/\1>/ then spell[$1] = $2 end }
					Spell.new(spell['number'],spell['name'],spell['type'],spell['duration'],(spell['manaCost'] || '0'),(spell['spiritCost'] || '0'),(spell['staminaCost'] || '0'),(if spell['stacks'] and spell['stacks'] != 'false' then true else false end),(if spell['selfonly'] and spell['selfonly'] != 'false' then true else false end),spell['msgup'],spell['msgdown'],(spell['boltAS'] || '0'),(spell['physicalAS'] || '0'),(spell['boltDS'] || '0'),(spell['physicalDS'] || '0'),(spell['elementalCS'] || '0'),(spell['spiritCS'] || '0'),(spell['sorcererCS'] || '0'),(spell['elementalTD'] || '0'),(spell['spiritTD'] || '0'),(spell['sorcererTD'] || '0'),(spell['strength'] || '0'),(spell['dodging'] || '0'))
				}
			}
			return true
		rescue
			respond "--- Failed to load #{filename}"
			respond $!
			return false
		end
	end
	def Spell.serialize
		spell = nil; @@active.each { |spell| spell.touch }
		@@active
	end
	def Spell.active
		@@active
	end
	def Spell.load_active=(data)
		data.each { |oldobject|
			spell = @@list.find { |newobject| oldobject.name == newobject.name }
			unless @@active.include?(spell)
				spell.timeleft = oldobject.timeleft
				spell.active = true
				@@active.push(spell)
			end
		}
	end
	def Spell.load_detailed=(data)
		@@detailed = data
	end
	def Spell.detailed?
		@@detailed
	end
	def Spell.increment_detailed
		@@detailed = !@@detailed
	end
	def active=(val)
		@active = val
	end
	def Spell.active
		@@active
	end
	def Spell.list
		@@list
	end
	def Spell.upmsgs
		@@list.collect { |spell| spell.msgup }
	end
	def Spell.dnmsgs
		@@list.collect { |spell| spell.msgdn }
	end
	def timeleft
		# this is just a copy and paste of the "touch" function.  For some reason, just calling touch here does not work correctly.
		if @duration.to_s == "Spellsong.timeleft"
			@timeleft = Spellsong.timeleft
		else
			@timeleft = @timeleft - ((Time.now - @timestamp) / 60.00)
			if @timeleft.to_f <= 0
				self.putdown
				return 0.0
			end
		end
		@timestamp = Time.now
		@timeleft
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
			@timeleft = @timeleft - ((Time.now - @timestamp) / 60.00)
			if @timeleft.to_f <= 0
				self.putdown
				return 0.0
			end
		end
		@timestamp = Time.now
		@timeleft
	end
	def Spell.[](val)
		if val.class == Spell
			val
		elsif val.class == Fixnum
			@@list.find { |spell| spell.num == val }
		else
			if ret = @@list.find { |spell| spell.name =~ /^#{val}$/i } then ret
			elsif ret = @@list.find { |spell| spell.name =~ /^#{val}/i } then ret
			else @@list.find { |spell| spell.msgup =~ /#{val}/i or spell.msgdn =~ /#{val}/i } end
		end
	end
	def Spell.active?(val)
		Spell[val].active?
	end
	def active?
		touch
		@active
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
		@@active.push(self) unless @@active.include?(self)
		@active = true
	end
	def putdown
		@active = false
		@timeleft = 0
		@timestamp = Time.now
		@@active.delete(self)
	end
	def remaining
		self.touch.as_time
	end
	def cost
		@manaCost
	end
	def affordable?
		 checkmana(@manaCost) and checkspirit(@spiritCost.to_i) and checkstamina(@staminaCost)
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
	@@began ||= Time.now
	@@timer ||= 0
	@@running ||= false
	@@stopwatch ||= Time.now
	@@tracked ||= false
	def Gift.serialize
		[@@began,@@timer]
	end
	def Gift.load_serialized=(array)
		@@tracked = true
		@@began,@@timer = array
	end
	def Gift.touch
		over = @@began + 604800
		if Time.now > over
			@@timer = 0
			@@running = false
			@@stopwatch = Time.now
		end
		Gift.stopwatch
	end
	def Gift.stopwatch
		if $mind_value.to_i == 0
			if @@running then @@timer += (Time.now.to_f - @@stopwatch.to_f) end
			@@running = false
		else
			if @@running
				@@timer += (Time.now.to_f - @@stopwatch.to_f)
			end
			@@running = true
			@@stopwatch = Time.now
		end
	end
	def Gift.remaining
		Gift.touch
		unless @@tracked then return 0 end
		21600 - @@timer
	end
	def Gift.restarts_on
		@@began + 604800
	end
	def Gift.ended
		@@timer = 21601
	end
	def Gift.started
		@@began = Time.now
		@@timer = 0
		@@stopwatch = Time.now
		Gift.stopwatch
	end
end

class Lich
	@@settings ||= Hash.new
	def Lich.method_missing(arg1, arg2='')
		if arg1.to_s.split('')[-1] == '='
			@@settings[arg1.to_s.chop] = arg2
		else
			@@settings[arg1.to_s]
		end
	end
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

class Wounds
	def Wounds.method_missing(arg)
		arg = arg.to_s
		fix_injury_mode
		fix_name = { 'nerves' => 'nsys', 'lleg' => 'leftLeg', 'rleg' => 'rightLeg', 'rarm' => 'rightArm', 'larm' => 'leftArm', 'rhand' => 'rightHand', 'lhand' => 'leftHand', 'reye' => 'rightEye', 'leye' => 'leftEye', 'abs' => 'abdomen' }
		if $injuries[arg]['wound']
			$injuries[arg]['wound']
		elsif $injuries[fix_name[arg]]['wound']
			$injuries[fix_name[arg]]['wound']
		else
			echo 'Wounds: Invalid area, try one of these: arms, limbs, torso, ' + $injuries.keys.join(', ')
			nil
		end
	end
	def Wounds.arms
		fix_injury_mode
		[$injuries['leftArm']['wound'],$injuries['rightArm']['wound'],$injuries['leftHand']['wound'],$injuries['rightHand']['wound']].max
	end
	def Wounds.limbs
		fix_injury_mode
		[$injuries['leftArm']['wound'],$injuries['rightArm']['wound'],$injuries['leftHand']['wound'],$injuries['rightHand']['wound'],$injuries['leftLeg']['wound'],$injuries['rightLeg']['wound']].max
	end
	def Wounds.torso
		fix_injury_mode
		[$injuries['rightEye']['wound'],$injuries['leftEye']['wound'],$injuries['chest']['wound'],$injuries['abdomen']['wound'],$injuries['back']['wound']].max
	end
end

class Scars
	def Scars.method_missing(arg)
		arg = arg.to_s
		fix_injury_mode
		fix_name = { 'nerves' => 'nsys', 'lleg' => 'leftLeg', 'rleg' => 'rightLeg', 'rarm' => 'rightArm', 'larm' => 'leftArm', 'rhand' => 'rightHand', 'lhand' => 'leftHand', 'reye' => 'rightEye', 'leye' => 'leftEye', 'abs' => 'abdomen' }
		if $injuries[arg]['scar']
			$injuries[arg]['scar']
		elsif $injuries[fix_name[arg]]['scar']
			$injuries[fix_name[arg]]['scar']
		else
			echo 'Scars: Invalid area, try one of these: arms, limbs, torso, ' + $injuries.keys.join(', ')
			nil
		end
	end
	def Scars.arms
		fix_injury_mode
		[$injuries['leftArm']['scar'],$injuries['rightArm']['scar'],$injuries['leftHand']['scar'],$injuries['rightHand']['scar']].max
	end
	def Scars.limbs
		fix_injury_mode
		[$injuries['leftArm']['scar'],$injuries['rightArm']['scar'],$injuries['leftHand']['scar'],$injuries['rightHand']['scar'],$injuries['leftLeg']['scar'],$injuries['rightLeg']['scar']].max
	end
	def Scars.torso
		fix_injury_mode
		[$injuries['rightEye']['scar'],$injuries['leftEye']['scar'],$injuries['chest']['scar'],$injuries['abdomen']['scar'],$injuries['back']['scar']].max
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
	@@containers ||= Hash.new
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
		@name = name
		@status = status
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
			@@containers[container].push(obj)
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
	def contents
		@@containers[@id]
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
	def to_s
		@noun
	end
	def empty?
		false
	end
	def GameObj
		@noun
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
		@@containers[container_id] = Array.new
	end
	def GameObj.add_to_container(container_id, obj)
		@@containers[container_id].push(obj)
	end
	def GameObj.containers
		@@containers.dup
	end
	def GameObj.dead
		dead_list = Array.new
		for obj in @@npcs
			dead_list.push(obj) if obj.status == "dead"
		end
		return nil if dead_list.empty?
		return dead_list
	end
end

class RoomObj < GameObj
end

class MapXML

	include StreamListener

	@@current_tag = String.new
	@@current_attributes = Hash.new
	@@room_id = nil
	@@room_title = String.new
	@@room_description = String.new
	@@room_paths = String.new
	@@room_wayto = Hash.new
	@@room_timeto = Hash.new

	def tag_start(name, attributes)
		@@current_tag = name
		@@current_attributes = attributes
		if name == 'room'
			@@room_id = attributes['id'].to_i
		end
	end

	def text(text)
		text = text.gsub('&gt;', '>').gsub('&lt;', '<')
		if @@current_tag == 'title'
			@@room_title = text
		elsif @@current_tag == 'description'
			@@room_description = text
		elsif @@current_tag == 'paths'
			@@room_paths = text
		elsif @@current_tag == 'exit'
			if @@current_attributes['cost']
				@@room_timeto[@@current_attributes['target']] = @@current_attributes['cost'].to_f
			else
				@@room_timeto[@@current_attributes['target']] = 0.2
			end
			if @@current_attributes['type'] == 'Proc'
				@@room_wayto[@@current_attributes['target']] = StringProc.new(text)
			elsif @@current_attributes['type'] == 'String'
				@@room_wayto[@@current_attributes['target']] = text
			end
		end
	end

	def tag_end(name)
		@@current_tag = String.new
		@@current_attributes = Hash.new
		if name == 'room'
			Room.new(@@room_id, @@room_title, @@room_description, @@room_paths, @@room_wayto, @@room_timeto)
			@@room_id = nil
			@@room_title = String.new
			@@room_description = String.new
			@@room_paths = String.new
			@@room_wayto = Hash.new
			@@room_timeto = Hash.new
		end
	end
end

class Map
	@@list ||= Array.new

	attr_reader :id
	attr_accessor :title, :desc, :paths, :wayto, :timeto, :pause, :geo, :realcost, :searched, :nadj, :adj, :parent
	def initialize(id, title, desc, paths, wayto={}, timeto={}, geo=nil, pause = nil)
		@id, @title, @desc, @paths, @wayto, @timeto, @geo, @pause = id, title, desc, paths, wayto, timeto, geo, pause
		@@list[@id] = self
	end
	def Map.get_free_id
		free_id = 0
		free_id += 1 until @@list[free_id].nil?
		free_id
	end
	def outside?
		@paths =~ /Obvious paths:/
	end
	def to_i
		@id
	end
	def Map.clear
		@@list.clear
	end
	def Map.uniq_new(id, title, desc, paths, wayto={}, timeto={}, geo=nil)
		chkre = /#{desc.strip.chop.gsub(/\.(?:\.\.)?/, '|')}/
		unless duplicate = @@list.find { |obj| obj.title == title and obj.desc =~ chkre and obj.paths == paths }
			return Map.new(id, title, desc, paths, wayto, timeto, geo)
		end
		return duplicate
	end
	def Map.uniq!
		deleted_rooms = Array.new
		@@list.each { |room|
			chkre = /#{desc.strip.chop.gsub(/\.(?:\.\.)?/, '|')}/
			@@list.each { |duproom|
				if duproom.desc =~ chkre and room.title == duproom.title and room.paths == duproom.paths and room.id != duproom.id
					deleted_rooms.push(duproom.id)
					duproom = nil
				end
			}
		}
		return nil if deleted_rooms.empty?
		return deleted_rooms
	end
	def Map.list
		@@list
	end
	def Map.[](val)
		if (val.class == Fixnum) or (val.class == Bignum) or val =~ /^[0-9]+$/
			@@list[val.to_i]
		else
			chkre = /#{val.strip.sub(/\.$/, '').gsub(/\.(?:\.\.)?/, '|')}/i
			chk = /#{Regexp.escape(val.strip)}/i
			@@list.find { |room| room.title =~ chk } or @@list.find { |room| room.desc =~ chk } or @@list.find { |room| room.desc =~ chkre }
		end
	end
	def Map.current
		ctitle = checkroom
		cdescre = /#{Regexp.escape(checkroomdescrip.strip.chop).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
		@@list.find { |room| room.desc =~ cdescre and room.title == ctitle and $room_exits_string.chomp == room.paths }
	end
	def Map.current_or_new
		Map.current || Map.new(Map.get_free_id, $room_title, $room_description, $room_exits_string)
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
	end
	def Map.load_xml(file=($script_dir.to_s + "map.xml"))
		unless File.exists?(file)
			raise Exception.exception("MapDatabaseError"), "Fatal error: file `#{file}' does not exist!"
		end
		fd = File.open(file, 'r')
		begin
			REXML::Document.parse_stream(fd, MapXML.new)
		rescue
			respond "--- Lich: error loading map database. (#{$!})"
		end
		fd.close
		fd = nil
		GC.start
	end
	def Map.load_unique(file=($script_dir.to_s + 'unique_map_movements.txt'))
		Map.load if @@list.empty?
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
				file.write "<room id=\"#{room.id}\">\n	<title>#{room.title.gsub('<', '&lt;').gsub('>', '&gt;')}</title>\n	<description>#{room.desc.gsub('<', '&lt;').gsub('>', '&gt;')}</description>\n	<paths>#{room.paths}</paths>\n"
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
	def get_wayto(int)
		# fixme
		echo 'get_wayto called, doing nothing'
=begin
		dir = @wayto[int.to_s]
		if dir =~ /^\s*(?:n|north)\s*$/i then return N
		elsif dir =~ /^\s*(?:ne|northeast)\s*$/i then return NE
		elsif dir =~ /^\s*(?:e|east)\s*$/i then return E
		elsif dir =~ /^\s*(?:se|southeast)\s*$/i then return SE
		elsif dir =~ /^\s*(?:s|south)\s*$/i then return S
		elsif dir =~ /^\s*(?:sw|southwest)\s*$/i then return SW
		elsif dir =~ /^\s*(?:w|west)\s*$/i then return W
		elsif dir =~ /^\s*(?:nw|northwest)$\s*/i then return NW
		else return NODIR
		end
=end
	end
	def to_s
		"##{@id}:\n#{@title}\n#{@desc}\n#{@paths}"
	end
	def inspect
		self.instance_variables.collect { |var| var.to_s + "=" + self.instance_variable_get(var).inspect }.join("\n")
	end
	def cinspect
		inspect
	end
	def Map.findpath(source, destination)
		Map.load if @@list.empty?
		previous, shortest_distances = Map.dijkstra_quick(source, destination)
		return nil unless previous[destination]
		path = [ destination ]
		path.push(previous[path[-1]]) until previous[path[-1]] == source
		path.reverse!
		path.pop
		return path
	end
	def Map.dijkstra(source)
		Map.load if @@list.empty?
		n = @@list.length
		source = source.to_i

		visited = Array.new
		shortest_distances = Array.new
		previous = Array.new
		pq = PQueue.new(proc {|x,y| shortest_distances[x] < shortest_distances[y]})
		
		pq.push(source)
		visited[source] = true
		shortest_distances[source] = 0

		while pq.size != 0
			v = pq.pop
			visited[v] = true
			@@list[v].wayto.keys.each { |adj_room|
				adj_room_i = adj_room.to_i
				nd = shortest_distances[v] + (@@list[v].timeto[adj_room] || 0.2)
				if !visited[adj_room.to_i] and (shortest_distances[adj_room_i].nil? or shortest_distances[adj_room_i] > nd)
					shortest_distances[adj_room_i] = nd
					previous[adj_room_i] = v
					pq.push(adj_room_i)
				end
			}
		end

		# shortest_distances is 5 times larger than the real estimate
		return previous, shortest_distances
	end
	def Map.dijkstra_quick(source, destination)
		Map.load if @@list.empty?
		n = @@list.length
		source = source.to_i
		destination = destination.to_i

		visited = Array.new
		shortest_distances = Array.new
		previous = Array.new
		pq = PQueue.new(proc {|x,y| shortest_distances[x] < shortest_distances[y]})
		
		pq.push(source)
		visited[source] = true
		shortest_distances[source] = 0

		while pq.size != 0
			v = pq.pop
			break if v == destination
			visited[v] = true
			@@list[v].wayto.keys.each { |adj_room|
				adj_room_i = adj_room.to_i
				nd = shortest_distances[v] + (@@list[v].timeto[adj_room] || 0.2)
				if !visited[adj_room.to_i] and (shortest_distances[adj_room_i].nil? or shortest_distances[adj_room_i] > nd)
					shortest_distances[adj_room_i] = nd
					previous[adj_room_i] = v
					pq.push(adj_room_i)
				end
			}
		end
		return previous, shortest_distances
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
	$! = JUMP
	raise $!
end

def start_script(script_name,cli_vars=[],force=false)
	file_name = nil
	if File.exists?($script_dir + script_name + '.lic')
		file_name = $script_dir + script_name + '.lic'
	else
		file_list = Dir.entries($script_dir)[2..-1]
		unless file_name = file_list.find { |val| val =~ /^#{script_name}\.(?:lic|rbw?)(?:\.gz|\.Z)?$/i } or 
		       file_name = file_list.find { |val| val =~ /^#{script_name}[^.]+\.(?i:lic|rbw?)(?:\.gz|\.Z)?$/ } or 
		       file_name = file_list.find { |val| val =~ /^#{script_name}[^.]+\.(?:lic|rbw?)(?:\.gz|\.Z)?$/i } or 
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
		new_script = Script.new(file_name, cli_vars)
	rescue
		respond("--- Lich: error reading script file: #{$!}")
	end
	Thread.new {
		new_script.add_thread(Thread.current)
		script = Script.self
		Thread.current.priority = 1
		respond("--- Lich: #{script.name} active.") unless script.quiet_exit
		begin
			while Script.self.current_label
				eval(Script.self.labels[Script.self.current_label].to_s)
				Script.self.get_next_label
			end
			Script.self.kill
		rescue SystemExit
			Script.self.kill
		rescue SyntaxError
			respond("--- SyntaxError: #{$!}")
			respond($!.backtrace[0..2]) if $LICH_DEBUG
			respond("--- Lich: cannot execute #{Script.self.name}, aborting.")
			Script.self.kill
		rescue ScriptError
			respond("--- ScriptError: #{$!}")
			respond($!.backtrace[0..2]) if $LICH_DEBUG
			Script.self.kill
		rescue
			respond("--- Error: #{Script.self.name}: #{$!}")
			respond($!.backtrace[0..2]) if $LICH_DEBUG
			Script.self.kill
		rescue NoMemoryError
			respond("--- NoMemoryError: #{$!}")
			respond($!.backtrace[0..2]) if $LICH_DEBUG
			Script.self.kill
		rescue Exception
			if $! == JUMP
				retry if Script.self.get_next_label != JUMP_ERROR
				respond("--- Label Error: `#{Script.self.jump_label}' was not found, and no `LabelError' label was found!")
				respond($!.backtrace[0..2]) if $LICH_DEBUG
				Script.self.kill
			else
				respond("--- Exception: #{$!}")
				respond($!.backtrace[0..2]) if $LICH_DEBUG
				Script.self.kill
			end
		end
	}
end

def start_scripts(*script_names)
	script_names.flatten.each { |script_name|
		start_script(script_name)
		sleep 0.02
	}
end

def force_start_script(script_name,cli_vars=[])
	start_script(script_name,cli_vars,true)
end

def start_exec_script(cmd_data, quiet=false)
	new_script = ExecScript.new(cmd_data, quiet)
	Thread.new {
		new_script.add_thread(Thread.current)
		script = Script.self
		Thread.current.priority = 1
		respond("--- Lich: #{script.name} active.") unless script.quiet_exit
		begin
			eval(cmd_data, nil, script.name.to_s, -1)
			Script.self.kill
		rescue SyntaxError
			respond("--- Lich SyntaxError: #{$!}")
			Script.self.kill
		rescue SystemExit
			Script.self.kill
		rescue SecurityError
			respond("--- Lich SecurityError: #{$!}")
			Script.self.kill
		rescue ThreadError
			respond("--- Lich: ThreadError: #{$!}")
			Script.self.kill
		rescue Exception
			respond("--- Exception: #{$!}")
			Script.self.kill
		rescue ScriptError
			respond("--- ScriptError: #{$!}")
			Script.self.kill
		rescue
			respond("--- Lich Error: #{$!}")
			Script.self.kill
		end
	}
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
	unless $injury_mode == 2
		put '_injury 2'
		30.times { sleep 0.1; break if $injury_mode == 2 }
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
	until $roundtime_end > $server_time
		sleep 0.1
	end
	if $server_time >= $roundtime_end then return end
	sleep(($roundtime_end.to_f - (Time.now.to_f - $server_time_offset.to_f) + 0.6).abs)
end

def waitrt?
	if $roundtime_end > $server_time then waitrt end
end

def waitcastrt
	until $cast_roundtime_end > $server_time
		sleep 0.1
	end
	if $server_time >= $cast_roundtime_end then return end
	sleep(($cast_roundtime_end.to_f - (Time.now.to_f - $server_time_offset.to_f) + 0.6).abs)
end

def waitcastrt?
	if $cast_roundtime_end > $server_time then waitcastrt end
end

def maxhealth
	$max_health.to_i
end

def maxmana
	$max_mana.to_i
end

def maxspirit
	$max_spirit.to_i
end

def checkpoison
	$indicator['IconPOISONED'] == 'y'
end

def checkdisease
	$indicator['IconDISEASED'] == 'y'
end

def checksitting
	$indicator['IconSITTING'] == 'y'
end

def checkkneeling
	$indicator['IconKNEELING'] == 'y'
end

def checkstunned
	$indicator['IconSTUNNED'] == 'y'
end

def checkbleeding
	$indicator['IconBLEEDING'] == 'y'
end

def checkgrouped
	$indicator['IconJOINED'] == 'y'
end

def checkdead
	$indicator['IconDEAD'] == 'y'
end

def checkreallybleeding
	# fixme: What the hell does W stand for?
	# checkbleeding and !$_TAGHASH_['GSP'].include?('W')
	checkbleeding
end

def muckled?
	checkwebbed or checkdead or checkstunned
end

def checkhidden
	$indicator['IconHIDDEN'] == 'y'
end

def checkwebbed
	$indicator['IconWEBBED'] == 'y'
end

def checkprone
	$indicator['IconPRONE'] == 'y'
end

def checknotstanding
	$indicator['IconSTANDING'] == 'n'
end

def checkstanding
	$indicator['IconSTANDING'] == 'y'
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
	loot = GameObj.loot.collect { |item| item.noun }
	if loot.empty?
		return nil
	else
		loot
	end
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
	success = success.to_a if success.kind_of? String
	failure = failure.to_a if failure.kind_of? String
	raise ArgumentError, "usage is: selectput(game_command,success_array,failure_array[,timeout_in_secs])" if
		!string.kind_of?(String) or !success.kind_of?(Array) or
		!failure.kind_of?(Array) or timeout && !timeout.kind_of?(Numeric)

	success.flatten!
	failure.flatten!
	regex = /#{(success + failure).join('|')}/i
	successre = /#{success.join('|')}/i
	failurere = /#{failure.join('|')}/i
	thr = Thread.current

	timethr = Thread.new {
		timeout -= sleep(0.1) until timeout <= 0
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
	# fixme: no xml for poison rate
	return true
	if checkpoison
		rate,dissipation = checkpoison
	else
		return true
	end
	health = checkhealth
	n = 0
	until rate <= 0
		health -= rate
		rate -= dissipation
		n += 1
		if health <= 0 then return false end
	end
	true
end

def survivedisease?
	# fixme: no xml for disease rate
	return true
	if checkdisease
		rate,dissipation = checkdisease
	else
		return true
	end
	health = checkhealth
	n = 0
	deadat = 0
	until rate <= 0
		health -= rate
		rate -= dissipation
		n += 1
		if health <= 0 then return false end
	end
	true
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
		values[1..-1].each { |val| script.downstream_buffer.shove(val) }
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
		values[1..-1].each { |val| script.unique_buffer.shove(val) }
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

def send_lichnet_string(string)
	if lichnet = (Script.running + Script.hidden).find { |script| script.name =~ /lichnet/i }
		lichnet.unique_buffer.shove(string)
	else
		respond("You aren't running the `LichNet' client script! Type `#{$clean_lich_char}lichnet' to start it.")
	end
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

def move(dir='none')
	attempts = 0
	if dir == 'none'
		echo('Error! Move without a direction to move in!')
		return false
	else
		roomcount = $room_count
		clear
		moveflag = true
		put(dir)
		while feed = get
			if feed =~ /can't go there|Where are you trying to go|What were you referring to\?| appears to be closed\.|I could not find what you were referring to\.|You can't climb that\./
				echo("Error, can't go in the direction specified!")
				Script.self.downstream_buffer.unshift(feed)
				return false
			elsif feed =~ /^You grab [A-Z][a-z]+ and try to drag h(?:im|er), but s?he is too heavy\.$/
				sleep(1)
				waitrt?
				put(dir)
				next
			elsif feed =~ /Sorry, you may only type ahead/
				sleep(1)
				clear
				put(dir)
				next
			elsif feed =~ /will have to stand up first|must be standing first/
				clear
				put("stand")
				while feed = get
					if feed =~ /struggle.+stand/
						clear
						put("stand")
						next
					elsif feed =~ /stand back up|You scoot your chair back and stand up\./
						clear
						put("#{dir}")
						break
					elsif feed =~ /\.\.\.wait /
						wait = $'.split.first.to_i
						sleep(wait)
						clear
						put("stand")
						next
					elsif feed =~ /Sorry, you may only type ahead/
						sleep(1)
						clear
						put("stand")
						next
					elsif feed =~ /can't do that while|can't seem to|don't seem|stunned/
						sleep(1)
						clear
						put("stand")
						next
					elsif feed =~ /are already standing/
						clear
						put("#{dir}")
						break
					else
						stand_attempts = 0 if stand_attempts.nil?
						if stand_attempts >= 10
							echo("Error! #{stand_attempts} unrecognized responses, assuming a script hang...")
							Script.self.downstream_buffer.unshift(feed)
							return false
						end
						stand_attempts += 1
						sleep(1)
						clear
						put("stand")
						next
					end
				end
			elsif feed =~ /\.\.\.wait |Wait /
				wait_time = $'.split.first.to_i
				sleep(wait_time)
				clear
				put("#{dir}")
				next
			elsif feed =~ /stunned/
				wait_while { stunned? }
				clear
				put("#{dir}")
				next
			elsif feed =~ /can't do that|can't seem to|don't seem /
				sleep(1)
				clear
				put("#{dir}")
				next
			elsif feed =~ /Please rephrase that command/
				echo("error! Cannot go '#{dir}', game did not understand the command.")
				Script.self.downstream_buffer.unshift(feed)
				return false
			elsif feed =~ /seems as though all the tables here are/
				sleep 1
				clear
				put("#{dir}")
				next
			elsif feed =~ /You head over to the .+ Table/
				Script.self.downstream_buffer.unshift(feed)
				return feed
			elsif feed =~ /Running heedlessly through the icy terrain, you slip on a patch of ice and flail uselessly as you land on your rear!/
				waitrt?
				fput('stand') unless standing?; waitrt?; fput(dir); next
			else
				if attempts >= 35
					echo("#{attempts} unrecognized lines, assuming a script hang; move command has exited.")
					Script.self.downstream_buffer.unshift(feed)
					return false
				else
					if $room_count > roomcount
						Script.self.downstream_buffer.unshift(feed)
						return feed
					else
						attempts += 1; next
					end
				end
			end
		end
	end
end

def fetchloot(userbagchoice=Lich.lootsack)
	if GameObj.loot.empty?
		return false
	end
	if Lich.excludeloot.empty?
		regexpstr = nil
	else
		regexpstr = Lich.excludeloot.join('|')
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
		fput("take my #{stowed} from my #{Lich.lootsack}")
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
	Thread.current.priority = -10
	unless announce.nil? or yield
		respond(announce)
	end
	until yield
		sleep 0.25
	end
	Thread.current.priority = priosave
end

def wait_while(announce=nil)
	priosave = Thread.current.priority
	Thread.current.priority = -10
	unless announce.nil? or !yield
		respond(announce)
	end
	while yield
		sleep 0.25
	end
	Thread.current.priority = priosave
end

def checkpaths(dir="none")
	if dir == "none"
		if $room_exits.empty?
			return false
		else
			return $room_exits.collect { |dir| dir = SHORTDIR[dir] }
		end
	else
		$room_exits.include?(dir) || $room_exits.include?(SHORTDIR[dir])
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

def checkfried
	checkmind(8) or checkmind(9)
end

def checkencumbrance(string=nil)
	if string == nil
		return $encumbrance_text
	else
		if string.to_i <= $encumbrance_value
			return true
		else
			return false
		end
	end
end

def check_mind(string=nil)
	if string.nil?
		return $mind_text
	elsif (string.class == String) and (string.to_i == 0)
		if string =~ /#{$mind_text}/i
			return true
		else
			return false
		end
	elsif string.to_i.between?(0,100)
		return string.to_i <= $mind_value.to_i
	else
		echo("check_mind error! You must provide an integer ranging from 0-100, the common abbreviation of how full your head is, or provide no input to have check_mind return an abbreviation of how filled your head is.") ; sleep 1
		return false
	end
end

def checkmind(string=nil)
	if string.nil?
		return $mind_text
	elsif string.class == String and string.to_i == 0
		if string =~ /#{$mind_text}/i
			return true
		else
			return false
		end
	elsif string.to_i.between?(1,9)
		mind_state = ['clear as a bell','fresh and clear','clear','muddled','becoming numbed','numbed','must rest','saturated']
		if mind_state.index($mind_text)
			mind = mind_state.index($mind_text) + 1
			return string.to_i <= mind
		else
			echo "Bad string in checkmind: mind_state"
			nil
		end
	else
		echo("Checkmind error! You must provide an integer ranging from 1-9 (7 is fried, 8 is 100% fried, 9 is extremely rare and is impossible through normal means to reach but does exist), the common abbreviation of how full your head is, or provide no input to have checkmind return an abbreviation of how filled your head is.") ; sleep 1
		return false
	end
end

def checkarea(*strings)
	strings.flatten! ; if strings.empty? then return $room_title.split(',').first.sub('[','') end
	$room_title.split(',').first =~ /#{strings.join('|')}/i
end

def checkroom(*strings)
	strings.flatten! ; if strings.empty? then return $room_title.chomp end
	$room_title =~ /#{strings.join('|')}/i
end

def outside?
	$room_exits_string =~ /Obvious paths:/
end

def checkfamarea(*strings)
	strings.flatten!
	if strings.empty? then return $familiar_room_title.split(',').first.sub('[','') end
	$familiar_room_title.split(',').first =~ /#{strings.join('|')}/i
end

def checkfampaths(dir="none")
	if dir == "none"
		if $familiar_room_exits.empty?
			return false
		else
			return $familiar_room_exits.to_a
		end
	else
		$familiar_room_exits.include?(dir)
	end
end

def checkfamroom(*strings)
	strings.flatten! ; if strings.empty? then return $familiar_room_title.chomp end
	$familiar_room_title =~ /#{strings.join('|')}/i
end

def checkfamnpcs(*strings)
	parsed = Array.new
	$familiar_npcs.each { |val| parsed.push(val.split.last) }
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
	$familiar_pcs.to_s.gsub(/Lord |Lady |Great |High |Renowned |Grand |Apprentice |Novice |Journeyman /,'').split(',').each { |line| familiar_pcs.push(line.slice(/[A-Z][a-z]+/)) }
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

def percentstamina(num=nil)
	unless num.nil?
		((checkstamina.to_f / maxstamina.to_f) * 100).to_i >= num.to_i
	else
		((checkstamina.to_f / maxstamina.to_f) * 100).to_i >= num.to_i
	end
end

def percenthealth(num=nil)
	unless num.nil?
		((checkhealth.to_f / maxhealth.to_f) * 100).to_i >= num.to_i
	else
		((checkhealth.to_f / maxhealth.to_f) * 100).to_i
	end
end

def percentmana(num=nil)
	unless num.nil? then ((checkmana.to_f / maxmana.to_f) * 100).to_i >= num.to_i
	else ((checkmana.to_f / maxmana.to_f) * 100).to_i end
end

def percentspirit(num=nil)
	unless num.nil? then ((checkspirit.to_f / maxspirit.to_f) * 100).to_i >= num.to_i
	else ((checkspirit.to_f / maxspirit.to_f) * 100).to_i end
end

def checkmana(num=nil)
	if num.nil?
		$mana.to_i
	else
		$mana.to_i >= num.to_i
	end
end

def checkroomdescrip(*val)
	val.flatten!
	if val.empty?
		return $room_description
	else
		return $room_description =~ /#{val.join('|')}/i
	end
end

def checkfamroomdescrip(*val)
	val.flatten!
	if val.empty?
		return $familiar_room_description
	else
		return $familiar_room_description =~ /#{val.join('|')}/i
	end
end

def checkstance(num=nil)
	if num.nil?
		$stance_text
	elsif (num.class == String && num.to_i == 0)
		if num =~ /off/i then stance == 00
		elsif num =~ /adv/i then $stance_value.between?(01, 20)
		elsif num =~ /for/i then $stance_value.between?(21, 40)
		elsif num =~ /neu/i then $stance_value.between?(41, 60)
		elsif num =~ /gua/i then $stance_value.between?(61, 80)
		elsif num =~ /def/i then $stance_value == 100
		else echo('checkstance: Unrecognized stance! Must be off/adv/for/neu/gua/def'); nil end
	else
		echo('checkstance: Warning, checkstance was passed an argument of unknown type, assuming type integer and comparing...')
		$stance_value == num.to_i
	end
end

def checkspell(*spells)
	spells.flatten!
	if Spell.active.empty? then return false end
	spells.each { |spell|
		unless Spell[spell].active? then return false end
	}
	true
end

def checkprep(spell=nil)
	if spell.nil?
		$prepared_spell
	elsif spell.class != String
		echo("Checkprep error, spell # not implemented!  You must use the spell name")
		false
	else
		$prepared_spell =~ /^#{spell}/i
	end
end

def checkspirit(num=nil)
	if num.nil? then $spirit.to_i else $spirit.to_i >= num.to_i end
end

def checkhealth(num=nil)
	if num.nil? then $health.to_i else $health.to_i >= num.to_i end
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
	if $bounty_task
		return $bounty_task
	else
		return nil
	end
end

def checkstamina(num=nil)
	if $stamina.nil? then echo("Stamina tracking is only functional when you're using StormFront!"); nil elsif num.nil? then $stamina.to_i else $stamina.to_i >= num.to_i end
end

def variable
	unless script = Script.self then echo 'variable: cannot identify calling script.'; return nil; end
	script.vars
end

def maxstamina(num=0)
	if num.zero?
		$max_stamina.to_i
	else
		$max_stamina.to_i >= num.to_i
	end
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

def cast(spell,*targets)
	pushback_ary = []
	regex = Regexp.new(["Spell Hindrance for",
		"(?:Cast|Sing) Roundtime [0-9]+ Seconds",
		"You don't have a spell prepared!",
		"You already have a spell readied!",
		"The searing pain in your throat makes that impossible",
	].join('|'), "i")

	if !Spell[spell.to_i].nil?
		cost = eval(Spell[spell.to_i].cost)
	elsif spell == 1030
		if targets.empty?
			cost = 20
		else
			cost = 15
		end
	else
		cost = spell.to_s[-2..-1].to_i
	end
	if targets.empty?
		while mana?(cost)
			fput "incant #{spell}"
			chk = ""
			while chk !~ regex
				chk = get
				pushback_ary.push chk
			end
			unless chk =~ /spell hindrance for|The searing pain in your throat makes that impossible|don't have a spell prep/i
				sleep(3)
				Script.self.downstream_buffer.unshift(pushback_ary).flatten!
				return true
			end
		end
		return false
	else
		last = 0
		targets.each_with_index { |target,idx|
			while mana?(cost)
				fput "prep #{spell}"
				fput "cast at #{target}"
				chk = ""
				while chk !~ regex
					chk = get
					pushback_ary.push chk
				end
				unless chk =~ /spell hindrance for|The searing pain in your throat makes that impossible|don't have a spell prep/i
					sleep(3)
					last = idx
					break
				end
			end
		}
		Script.self.downstream_buffer.unshift(pushback_ary).flatten!
		if mana?(cost) and targets.length.eql?((last + 1))
			return true
		else
			return false
		end
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
	unless (secs.class == Float || secs.class == Fixnum) then echo('matchtimeout error! You appear to have given it a string, not a #! Syntax:  matchtimeout(30, "You stand up")') ; return false end
	match_string = false
	strings.flatten!
	if strings.empty? then echo("matchtimeout without any strings to wait for!") ; sleep 1 ; return false end
	regexpstr = strings.join('|')
	end_time = Time.now.to_f + secs

	loop {
		clear.each { |line|
			if line =~ /#{regexpstr}/i
				match_string = line
				break
			end
		}
		if match_string or (Time.now.to_f > end_time)
			break
		else
			sleep 0.1
		end
	}

	return match_string
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
# fixme
#	if script.wizard and strings.length == 1 and strings.first.strip == '>'
#		return script.gets
#	end
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

def reget(*lines)
	lines.flatten!
	if caller.find { |c| c =~ /regetall/ }
		history = ($_SERVERBUFFER_.history + $_SERVERBUFFER_)
	else
		history = $_SERVERBUFFER_.dup
	end
	unless Script.status_scripts.include?(Script.self)
		if $stormfront
			history.collect! { |line|
				line = line.strip.gsub(/<[^>]+>/, '')
				line.empty? ? nil : line
			}.compact!
		else
			history.collect! { |line|
				line = line.strip.gsub(/\034.*/, '')
				line.empty? ? nil : line
			}.compact!
		end
	end
	if lines.first.kind_of? Numeric or lines.first.to_i.nonzero?
		num = lines.shift.to_i
	else
		num = history.length
	end
	unless lines.empty?
		regex = /#{lines.join('|')}/i
		history = history[-num..-1].find_all { |line| line =~ regex }
	end
	history.empty? ? nil : history
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
				Script.self.downstream_buffer.unshift(string)
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
	messages.each { |message|
		message.chomp!
		unless scr = Script.self then scr = "(script unknown)" end
		$_CLIENTBUFFER_.shove("[#{scr}]#{$SEND_CHARACTER}<c>#{message}\r\n")
		respond("[#{scr}]#{$SEND_CHARACTER}#{message}\r\n") unless scr.silent
		$_SERVER_.write("<c>#{message}\n")
		$_LASTUPSTREAM_ = "[#{scr}]#{$SEND_CHARACTER}#{message}"
	}
end

def quiet_exit
	script = Script.self
	script.quiet_exit = !(script.quiet_exit)
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
		Script.namescript_incoming(message)
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
	snames.each { |checking| (return false) unless (Script.running.find { |lscr| lscr.name =~ /^#{checking}$/i } || Script.running.find { |lscr| lscr.name =~ /^#{checking}/i }) }
	true
end

def dump_to_log(log_dir)
	begin
		file = File.open("#{log_dir}lich-log.txt", "w")
		file.print("--- Dump of the up- and down-streams of data as seen by the Lich (this includes all status lines, etc.) ---\r\n")
		file.print("\tLich v#{$version}  " + Time.now.to_s)
		file.print("\r\n\r\n\r\n===========\r\nFrom the Game Host to Your Computer\r\n==========\r\n\r\n")
		file.puts($_SERVERBUFFER_.history + $_SERVERBUFFER_)
		file.print("\r\n\r\n\r\n\r\n==========\r\nFrom Your Computer to the Game Host\r\n==========\r\n\r\n")
		file.puts($_CLIENTBUFFER_.history + $_CLIENTBUFFER_)
		respond("--- Lich: '#{log_dir}lich-log.txt' written successfully.  If you want to keep it, don't forget to rename it or next time it'll be overwritten!")
	rescue
		$stderr.puts("--- Lich encountered an error and cannot write to log; message was:\n--- #{$!}")
	ensure
	 	psinet_log = nil
		simu_log = nil
		file.close
	end
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
		$_CLIENT_.puts(str)
	rescue
		puts $!.to_s if $LICH_DEBUG
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

begin
	undef :abort
	alias :mana :checkmana
	alias :mana? :checkmana
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
	STDERR.puts($!)
	STDERR.puts($!.backtrace)
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
			return nil
			# puts "--- error: (#{$!})"
			# $stderr.puts $!.backtrace.join("\r\n")
		end
	else
		if ENV['WINEPREFIX']
			wine_dir = ENV['WINEPREFIX']
		elsif ENV['HOME']
			wine_dir = ENV['HOME'] + '/.wine'
		else
			return false
		end
		if File.exists?(wine_dir) and File.exists?(wine_dir + '/system.reg')
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
			# respond "--- error: (#{$!})"
			# $stderr.puts $!.backtrace.join("\r\n")
		end
	else
		if ENV['WINEPREFIX']
			wine_dir = ENV['WINEPREFIX']
		elsif ENV['HOME']
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
				sleep 0.2
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

def hack_hosts(hosts_dir, simu_ip)
	hosts_dir += File::Separator unless hosts_dir[-1..-1] =~ /\/\\/
	at_exit { heal_hosts(hosts_dir) }
	begin
		begin
			unless File.exists?("%shosts.bak" % hosts_dir)
				File.open("%shosts" % hosts_dir) { |file|
					File.open("%shosts.sav" % $lich_dir, 'w') { |f|
						f.write(file.read)
					}
				}
			end
		rescue
			File.unlink("#{$lich_dir}hosts.sav") if File.exists?("#{$lich_dir}hosts.sav")
		end
		if File.exists?("%shosts.bak" % hosts_dir)
			sleep 1
			if File.exists?("%shosts.bak" % hosts_dir)
				heal_hosts(hosts_dir)
			end
		end
		File.open("%shosts" % hosts_dir) { |file|
			File.open("%shosts.bak" % hosts_dir, 'w') { |f|
				f.write(file.read)
			}
		}
		File.open("%shosts" % hosts_dir, 'w') { |file|
			file.puts "127.0.0.1\t\tlocalhost\r\n127.0.0.1\t\t%s" % simu_ip
		}
	rescue SystemCallError
		$stderr.puts $!
		$stderr.puts $!.backtrace
		exit(1)
	end
end

def heal_hosts(hosts_dir)
	hosts_dir += File::Separator unless hosts_dir[-1..-1] =~ /\/\\/
	begin
		if File.exists? "%shosts.bak" % hosts_dir
			File.open("%shosts.bak" % hosts_dir) { |file|
				File.open("%shosts" % hosts_dir, 'w') { |f|
					f.write(file.read)
				}
			}
			File.unlink "%shosts.bak" % hosts_dir
		end
	rescue
		$stderr.puts $!
		$stderr.puts $!.backtrace
		exit(1)
	end
end

$link_highlight_start = "\207"
$link_highlight_end = "\240"

def sf_to_wiz(line)
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
			$_CLIENT_.puts "\034GSw00005\r\nhttps://www.play.net${$1}\r\n"
		end
		if line =~ /<pushStream id="thoughts"[^>]*><a[^>]*>([A-Z][a-z]+)<\/a>(.*?)<popStream\/>/m
			line = line.sub(/<pushStream id="thoughts"[^>]*><a[^>]*>[A-Z][a-z]+<\/a>.*?<popStream\/>/m, "You hear the faint thoughts of #{$1} echo in your mind:\r\n#{$2}")
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
		$_CLIENT_.puts('Error in sf_to_wiz')
		$_CLIENT_.puts('$_SERVERSTRING_: ' + $_SERVERSTRING_.to_s)
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

def install_to_registry
	Dir.chdir(File.dirname($PROGRAM_NAME))
	launch_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\')
	launch_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory')
	unless launch_cmd or launch_dir
		$stderr.puts 'Failed to read registry.'
		return false
	end
	if RUBY_PLATFORM =~ /win/i
		if ruby_dir = registry_get('HKEY_LOCAL_MACHINE\Software\RubyInstaller\DefaultPath')
			lich_launch_cmd = "#{ruby_dir.tr('/', "\\")}\\bin\\rubyw.exe \"#{Dir.pwd.tr('/', "\\")}\\lich.rb\" %1"
			lich_launch_dir = "#{ruby_dir.tr('/', "\\")}\\bin\\rubyw.exe \"#{Dir.pwd.tr('/', "\\")}\\lich.rb\" "
		else
			$stderr.puts 'Failed to find Ruby directory.'
			return false
		end
	else
		lich_launch_cmd = "#{Dir.pwd}/lich.rb %1"
		lich_launch_dir = "#{Dir.pwd}/lich.rb "
	end
	result = true
	if launch_cmd
		if launch_cmd =~ /lich/i
			$stderr.puts 'Lich appears to already be installed to the registry.'
			$stderr.puts 'launch_cmd: ' + launch_cmd
		else
			registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\RealCommand', launch_cmd) || result = false
			registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\', lich_launch_cmd) || result = false
		end
	end
	if launch_dir
		if launch_dir =~ /lich/i
			$stderr.puts 'Lich appears to already be installed to the registry.'
			$stderr.puts 'launch_dir: ' + launch_dir
		else
			registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\RealDirectory', launch_dir) || result = false
			registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory', lich_launch_dir) || result = false
		end
	end
	unless RUBY_PLATFORM =~ /win/i
		wine = `which wine`.strip
		if File.exists?(wine)
			registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Wine', wine)
		end
	end
	return result
end

def uninstall_from_registry
	real_launch_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\RealCommand')
	real_launch_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\RealDirectory')
	unless (real_launch_cmd and not real_launch_cmd.empty?) or (real_launch_dir and not real_launch_dir.empty?)
		$stderr.puts 'Lich does not appear to be installed to the registry.'
		return false
	end
	result = true
	if real_launch_cmd and not real_launch_cmd.empty?
		registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\', real_launch_cmd) || result = false
		registry_put('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\\RealCommand', '') || result = false
	end
	if real_launch_dir and not real_launch_dir.empty?
		registry_put('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory', real_launch_dir) || result = false
		registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\RealDirectory', '') || result = false
	end
	return result
end

sock_keepalive_proc = proc { |sock|
	err_msg = proc { |err|
		err ||= $!
		$stderr.puts Time.now
		$stderr.puts err
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



















$version = '3.67'

cmd_line_help = <<_HELP_
Usage:  lich [OPTION]

Options are:
  -h, --help          Display this list.
  -V, --version       Display the program version number and credits.

  -d, --directory     Set the main Lich program directory.
      --script-dir    Set the directoy where Lich looks for scripts.
      --data-dir      Set the directory where Lich will store script data.

  -w, --wizard        Run in Wizard mode (default)
  -s, --stormfront    Run in StormFront mode.

      --gemstone      Connect to the Gemstone IV Prime server (default).
      --platinum      Connect to the Gemstone IV Platinum server.
      --dragonrealms  Connect to the DragonRealms server.
  -g, --game          Set the IP address and port of the game.  See example below.

      --bare          Perform no data-scanning, just pass all game lines directly to scripts.  For maximizing efficiency w/ non-Simu MUDs.
  -c, --compressed    Do compression/decompression of the I/O data using Zlib (this is for MCCP, Mud Client Compression Protocol).
      --debug         Mainly of use in Windows; redirects the program's STDERR & STDOUT to the '/lich_err.txt' file.
      --uninstall     Restore the hosts backup (and in Windows also launch the uninstall application).

      --test
      --stderr

The majority of Lich's built-in functionality was designed and implemented with Simutronics MUDs in mind (primarily Gemstone IV): as such, many options/features provided by Lich may not be applicable when it is used with a non-Simutronics MUD.  In nearly every aspect of the program, users who are not playing a Simutronics game should be aware that if the description of a feature/option does not sound applicable and/or compatible with the current game, it should be assumed that the feature/option is not.  This particularly applies to in-script methods (commands) that depend heavily on the data received from the game conforming to specific patterns (for instance, it's extremely unlikely Lich will know how much "health" your character has left in a non-Simutronics game, and so the "health" script command will most likely return a value of 0).

The level of increase in efficiency when Lich is run in "bare-bones mode" (i.e. started with the --bare argument) depends on the data stream received from a given game, but on average results in a moderate improvement and it's recommended that Lich be run this way for any game that does not send "status information" in a format consistent with Simutronics' GSL or XML encoding schemas.


Examples:
  lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir '/usr/bin/lich/' as the program's home)
  lich -g gs3.simutronics.net:4000   (run Lich using the IP address 'gs3.simutronics.net' and the port number '4000')
  lich --script-dir /mydir/scripts   (run Lich with its script directory set to '/mydir/scripts')
  lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to 'skotos.net:5555')

_HELP_


cmd_line_version = <<_VERSION_
The Lich, version #{$version}
 (an implementation of the Ruby interpreter by Yukihiro Matsumoto designed to be a `script engine' for text-based MUDs)

- The Lich program and all material collectively referred to as "The Lich project" is copyright (C) 2005-2006 Murray Miron.
- The Gemstone IV and DragonRealms games are copyright (C) Simutronics Corporation.
- The Wizard front-end and the StormFront front-end are also copyrighted by the Simutronics Corporation.
- Ruby is (C) Yukihiro `Matz' Matsumoto.
- Inno Setup Compiler 5 is (C) 1997-2005 Jordan Russell (used for the Windows installation package).

Thanks to all those who've reported bugs and helped me track down problems on both Windows and Linux.
_VERSION_


Dir.chdir(File.dirname($PROGRAM_NAME))

if RUBY_PLATFORM =~ /win/i
	wine_dir = nil
	wine_bin = nil
else
	if ENV['WINEPREFIX'] and File.exists?(ENV['WINEPREFIX'])
		wine_dir = ENV['WINEPREFIX']
	elsif ENV['HOME'] and File.exists?(ENV['HOME'] + '/.wine')
		wine_dir = ENV['HOME'] + '/.wine'
	else
		wine_dir = nil
	end
	wine_bin = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Wine')
	unless wine_bin and File.exists?(wine_bin)
		wine_bin = nil
	end
end

# Get the debug-mode STDERR redirection in place so there's a record of any errors (in Windows, the program has no STDOUT or STDERR)
if ARGV.find { |arg| arg =~ /^--debug$/ }
	$stderr = File.open('lich_debug.txt','a')
	$stdout = $stderr
	$stderr.sync = true
	$stdout.sync = true
	ARGV.delete_if { |arg| arg =~ /^--debug$/ }
elsif RUBY_PLATFORM =~ /win/i
	$stderr = File.open(File.join(File.dirname($PROGRAM_NAME), 'lich_debug.txt'),'w')
	$stdout = $stderr
	$stderr.sync = true
	$stdout.sync = true
end


$fake_stormfront = false
 $send_fake_tags = false
     $stormfront = false
       $platinum = false
   $dragonrealms = false
         simu_ip = nil
       simu_port = nil
       launch_file = nil
             sge = nil
       $lich_dir = nil
     $script_dir = nil
       $data_dir = nil
       hosts_dir = nil
    $ZLIB_STREAM = false
 $SEND_CHARACTER = '>'

args = ARGV.dup
while arg = args.shift
	if (arg == '-h') or (arg == '--help')
		$stdout.puts(cmd_line_help)
		exit
	elsif (arg == '-v') or (arg == '--version')
		$stdout.puts(cmd_line_version)
		exit
	elsif (arg == '-d') or (arg == '--directory')
		dir = args.shift
		if File.exists?(dir)
			$lich_dir = dir
			$lich_dir += File::Separator unless $lich_dir[-1..-1] == File::Separator
			$stdout.puts("Lich directory set to '#{$lich_dir}'.")
		else
			$stderr.puts("Cannot set Lich directory to '#{dir}', does not exist.")
		end
		dir = nil
	elsif arg == '--script-dir'
		dir = args.shift
		if File.exists?(dir)
			$script_dir = dir
			$script_dir += File::Separator unless $script_dir[-1..-1] == File::Separator
			$stdout.puts("Script directory set to '#{script_dir}'.")
		else
			$stderr.puts("Cannot set script directory to '#{dir}', does not exist.")
		end
		dir = nil
	elsif arg == '--data-dir'
		dir = args.shift
		if File.exists?(dir)
			$data_dir = dir
			$data_dir += File::Separator unless $data_dir[-1..-1] == File::Separator
			$stdout.puts("Data directory set to '#{data_dir}'.")
		else
			$stderr.puts("Cannot set data directory to '#{dir}', does not exist.")
		end
		dir = nil
	elsif arg == '--hosts-dir'
		dir = args.shift
		if File.exists?(dir)
			hosts_dir = dir
			hosts_dir += File::Separator unless hosts_dir[-1..-1] == File::Separator
			$stdout.puts("Hosts directory set to '#{hosts_dir}'.")
		else
			$stderr.puts("Error: Cannot set hosts directory to '#{dir}', does not exist.")
			exit
		end
		dir = nil
	elsif arg == '--sge'
		file = args.shift
		if File.exists?(file)
			sge = file
			$stdout.puts("Using '#{sge}' as SGE.")
		else
			$stderr.puts("Error: Cannot use '#{file}' as SGE, does not exist.")
			exit
		end
		file = nil
	elsif (arg == '-g') or (arg == '--game')
		simu_ip,simu_port = ARGV[ARGV.index(arg)+1].split(':')
		simu_port = simu_port.to_i
		ARGV.delete_at(ARGV.index(arg)+1)
		$stdout.puts("Game information being used:  #{simu_ip}:#{simu_port}")
	elsif (arg == '-w') or (arg == '--wizard')
		$stormfront = true
		$fake_stormfront = true
	elsif (arg == '-s') or (arg == '--stormfront')
		$stormfront = true
		$fake_stormfront = false
	elsif arg == '--platinum'
		$platinum = true
	elsif arg == '--dragonrealms'
		$dragonrealms = true
	elsif arg =~ /\.sal|Gse\.~xt/i
		launch_file = arg
		unless File.exists?(launch_file)
			$stderr.puts 'launch file does not exist: ' + launch_file
			launch_file = /[A-Z]:\\.+\.(?:~xt|sal)/i.match(ARGV.join(' ')).to_s
			unless File.exists?(launch_file)
				$stderr.puts 'launch file does not exist: ' + launch_file
				if wine_dir
					launch_file = wine_dir + "/drive_c/" + launch_file[3..-1].split('\\').join('/')
					unless File.exists?(launch_file)
						$stderr.puts 'launch file does not exist: ' + launch_file
						exit
					end
				end
			end
		end
		$stderr.puts 'launch file: ' + launch_file
	elsif arg =~ /launcher.exe/i
		# passed by the SGE before the Gse.~xt file, ignore it
		nil
	elsif arg == '--bare'
		$BARE_BONES = true
		$stdout.puts('Running in bare-bones mode.')
	elsif arg == '--install'
		if install_to_registry
			$stdout.puts 'Install was successful.'
		else
			$stdout.puts 'Install failed.'
		end
		exit
	elsif arg == '--uninstall'
		if uninstall_from_registry
			$stdout.puts 'Uninstall was successful.'
		else
			$stdout.puts 'Uninstall failed.'
		end
		exit
	elsif arg  =~ /^--?c(?:ompressed)$/i
		$ZLIB_STREAM = true
		trace_var :$_SERVER_, proc { |server_socket|
			$_SERVER_ = ZlibStream.wrap(server_socket) if $ZLIB_STREAM
		}
		trace_var :$_CLIENT_, proc { |client_socket|
			$_CLIENT_ = ZlibStream.wrap(client_socket) if $ZLIB_STREAM
		}
	else
		$stderr.puts("Unrecognized command line option: #{arg}")
	end
end
args = nil


unless $lich_dir
	file_name = "#{ENV['HOME']}/.lich.cfg"
	if File.exists?(file_name)
		file = File.open(file_name)
		dir = file.readlines.first.chomp
		file.close
		file = nil
		if File.exists?(dir)
			$lich_dir = dir
			Dir.chdir($lich_dir)
			$lich_dir += File::Separator unless $lich_dir[-1..-1] == File::Separator
		else
			$stderr.puts "Lich directory in '#{file_name}' does not exist (#{dir})."
		end
		dir = nil
	else
		$stderr.puts "#{file_name} does not exist."
	end
	unless $lich_dir
		$lich_dir = Dir.pwd
		$lich_dir += File::Separator unless $lich_dir[-1..-1] == File::Separator
		$stderr.puts "Lich directory set to program directory: #{$lich_dir}"
	end
end

unless $script_dir
	$script_dir = $lich_dir + 'scripts' + File::Separator
	unless File.exists?($script_dir)
		$stderr.puts "Creating script directory: #{$script_dir}"
		Dir.mkdir($script_dir)
	end
end

unless $data_dir
	$data_dir = $lich_dir + 'data' + File::Separator
	unless File.exists?($data_dir)
		$stderr.puts "Creating data directory: #{$data_dir}"
		Dir.mkdir($data_dir)
	end
end

trace_var(:$_CLIENT_, sock_keepalive_proc)
trace_var(:$_SERVER_, sock_keepalive_proc)

Socket.do_not_reverse_lookup = true

# fixme: no $_TA_BUFFER_

# fixme: not using CachedArray
$_SERVERBUFFER_ = Array.new
$_CLIENTBUFFER_ = Array.new

if launch_file
	unless launcher_cmd = registry_get('HKEY_LOCAL_MACHINE\Software\Classes\Simutronics.Autolaunch\Shell\Open\command\RealCommand')
		$stderr.puts "Oh shit!"
		exit
	end
	if launch_file =~ /SGE\.sal/i
		launcher_cmd = wine_bin + ' ' + launcher_cmd if wine_bin
		system(launcher_cmd.sub('%1', launch_file))
		exit
	end
	begin
		data = File.open(launch_file) { |file| file.readlines }.collect { |line| line.chomp }
	rescue
		$stderr.puts "Error opening ${launch_file}: #{$!}"
		exit(1)
	end
	unless gamecode = data.find { |line| line =~ /GAMECODE=/ }
		$stderr.puts "file contains no GAMECODE info"
		exit(1)
	end
	unless gameport = data.find { |line| line =~ /GAMEPORT=/ }
		$stderr.puts "file contains no GAMEPORT info"
		exit(1)
	end
	unless gamehost = data.find { |opt| opt =~ /GAMEHOST=/ }
		$stderr.puts "file contains no GAMEHOST info"
		exit(1)
	end
	unless game = data.find { |opt| opt =~ /GAME=/ }
		$stderr.puts "file contains no GAME info"
		exit(1)
	end
	gamecode = gamecode.split('=').last
	gameport = gameport.split('=').last
	gamehost = gamehost.split('=').last
	game = game.split('=').last
	$stderr.puts sprintf("gamehost: %s   gameport: %s   game: %s", gamehost, gameport, game)
	begin
		listener = TCPServer.new("localhost", nil)
	rescue
		$stderr.puts "Cannot bind listening socket to local port: #{$!}"
		$stderr.puts sprintf("HOST: %s   PORT: %s   GAME: %s", gamehost, gameport, game)
		$stderr.puts launch_file
		exit(1)
	end
	begin
		listener.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
	rescue
		$stderr.puts "Cannot set SO_REUSEADDR sockopt"
	end
	localport = listener.addr[1]
	mod_data = []
	$stormfront = true
	if (gamehost == '127.0.0.1') or (gamehost == 'localhost')
		$psinet = true
		if registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\STORM32\Directory') and not File.exists?('fakestormfront.txt')
			$fake_stormfront = false
			data.each { |line| mod_data.push line.sub(/GAMEPORT=.+/, "GAMEPORT=#{localport}").sub(/GAMEHOST=.+/, "GAMEHOST=localhost") }
		else
			$fake_stormfront = true
			data.each { |line| mod_data.push line.sub(/GAMEPORT=.+/, "GAMEPORT=#{localport}").sub(/GAMEHOST=.+/, "GAMEHOST=localhost").sub(/GAMEFILE=.+/, "GAMEFILE=WIZARD.EXE").sub(/GAME=.+/, "GAME=WIZ") }
		end
	else
		$psinet = false
		data.each { |line| mod_data.push line.sub(/GAMEPORT=.+/, "GAMEPORT=#{localport}").sub(/GAMEHOST=.+/, "GAMEHOST=localhost") }
		if game =~ /STORM/i
			$fake_stormfront = false
		else
			$fake_stormfront = true
		end
	end
	File.open($lich_dir + "lich.sal", "w") { |f| f.puts mod_data }
	launcher_cmd = launcher_cmd.sub('%1', $lich_dir + 'lich.sal')
	launcher_cmd = wine_bin + ' ' + launcher_cmd if wine_bin
	$stderr.puts 'launcher_cmd: ' + launcher_cmd
	Thread.new { system(launcher_cmd) }
	timeout_thr = Thread.new {
		sleep 30
		$stderr.puts "timeout waiting for connection."
		exit(1)
	}
	$_CLIENT_ = listener.accept
	begin
		timeout_thr.kill
		listener.close
	rescue
		$stderr.puts $!
	end
	simu_ip = 'storm.gs4.game.play.net'
	if (gameport == '10121') or (gameport == '10124')
		$platinum = true
		simu_port = 10124
	else
		$platinum = false
		simu_port = 10024
	end
	if $psinet
		$_SERVER_ = TCPSocket.open(gamehost, gameport)
	else
		$_SERVER_ = TCPSocket.open(simu_ip, simu_port)
	end
else
	unless hosts_dir || (hosts_dir = find_hosts_dir)
		$stderr.puts('Error: Your local hosts file cannot be located!')
		exit
	end
	unless File.exists?(hosts_dir)
		$stderr.puts("Error: Hosts directory does not exist. (#{hosts_dir})")
		exit
	end
	unless simu_ip and simu_port
		if $fake_stormfront and $platinum
			simu_ip = 'gs-plat.simutronics.net'
			simu_port = 10121
		elsif $fake_stormfront and $dragonrealms
			simu_ip = 'dr.simutronics.net'
			simu_port = 4901
		elsif $fake_stormfront
			simu_ip = 'gs3.simutronics.net'
			simu_port = 4900
		elsif $stormfront and $platinum
			simu_ip = 'storm.gs4.game.play.net'
			simu_port = 10124
		elsif $stormfront and $dragonrealms
			# fixme
			$stderr.puts 'ip and port for dragonrealms is unknown.'
			exit
		elsif $stormfront
			simu_ip = 'storm.gs4.game.play.net'
			simu_port = 10024
		elsif File.exists?('/Gse.~xt') or File.exists?(ENV['HOME'] + '/.wine/drive_c/Gse.~xt')
			begin
				$stderr.puts 'No game/front-end input found, auto-detecting...'
				if File.exists?('/Gse.~xt')
					file = File.open('/Gse.~xt')
				else
					file = File.open(ENV['HOME'] + '/.wine/drive_c/Gse.~xt')
				end
				guessdata = file.readlines.collect { |line| line.strip }
				file.close
				file = nil
				simu_ip = guessdata.find { |line| line =~ /^GAMEHOST/ }.split('=').last.strip
				if simu_ip == '127.0.0.1'
					$stormfront = true
					$fake_stormfront = true
					simu_ip = 'gs3.simutronics.net'
					simu_port = 4900
					$stderr.puts " ...PsiNet alteration of file detected; configuring for Wizard.\n"
				else
					simu_port = guessdata.find { |line| line =~ /^GAMEPORT/ }.split('=').last.strip.to_i
					fe = guessdata.find { |line| line =~ /^GAMEFILE/ }.split('=').last.strip
					if fe == 'WIZARD.EXE'
						$stderr.puts " ...configuring for Wizard.\n"
						$stormfront = true
						$fake_stormfront = true
					else
						$stormfront = true
						$stderr.puts " ...configuring for StormFront.\n"
					end
				end
			rescue
				$stderr.puts "Unrecoverable error during read of 'Gse.~xt' file! Falling back on defaults..."
				$stderr.puts $!
				$stormfront = true
				$fake_stormfront = true
				simu_ip = 'gs3.simutronics.net'
				simu_port = 4900
			end
		else
			$stormfront = true
			$fake_stormfront = true
			simu_ip = 'gs3.simutronics.net'
			simu_port = 4900
		end
	end
	$stdout.puts "ip: #{simu_ip}, port: #{simu_port}"
	simu_quad_ip = IPSocket.getaddress(simu_ip)
	begin
		listener = TCPServer.new('localhost', simu_port)
		begin
			listener.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
		rescue
			$stderr.puts "Error during setsockopt, aborting setting of SO_REUSEADDR: #{$!}"
		end
	rescue
		$temp_error ||= 0
		$temp_error += 1
		sleep 1
		retry unless $temp_error >= 30
		$stderr.puts 'Lich cannot bind to the proper port, aborting execution.'
		exit!
	end
	$temp_error = nil
	hack_hosts(hosts_dir, simu_ip)
	# fixme: needs testing
	sge_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\SGE32\Directory')
	launch_dir = registry_get('HKEY_LOCAL_MACHINE\Software\Simutronics\Launcher\Directory')
	if File.exists?("#{$lich_dir}nosge.txt") or (launch_dir =~ /lich/i) or not sge_dir
		sge_file = File.join(sge_dir, 'SGE.exe')
		sge_file = wine_dir + '/drive_c/' + sge_file[3..-1].split('\\').join('/') if wine_dir
		if File.exists(sge_file)
			sge_file = wine_bin + ' ' + sge_file if wine_bin
			system(sge_file)
		end

	end
	timeout_thread = Thread.new { sleep 120 ; $stderr.puts("Timeout, restoring backup and exiting.") ; heal_hosts(hosts_dir); exit 1 }
	puts "Pretending to be the game host, and waiting for game client to connect to us..."
	$_CLIENT_ = listener.accept
	puts "Connection with the local game client is open."
	timeout_thread.kill
	timeout_thread = nil
	Process.wait rescue()
	heal_hosts(hosts_dir)
end

unless RUBY_PLATFORM =~ /win/i
	begin
		Process.uid = `id -ru`.strip.to_i
		Process.gid = `id -rg`.strip.to_i
		Process.egid = `id -rg`.strip.to_i
		Process.euid = `id -ru`.strip.to_i
	rescue SecurityError
		$stderr.puts "Error dropping superuser privileges: #{$!}"
	rescue SystemCallError
		$stderr.puts "Error dropping superuser privileges: #{$!}"
	rescue
		$stderr.puts "Error dropping superuser privileges: #{$!}"
	end
end

errtimeout = 1
# We've connected with the game client... so shutdown the listening socket (open it up for use by other progs, etc.)
begin
	# Somehow... for some ridiculous reason... Windows doesn't let us close the socket if we shut it down first...
	# listener.shutdown
	listener.close unless listener.closed?
rescue
	$stderr.puts "error closing listener socket: #{$!}"
	errtimeout += 1
	if errtimeout > 20 then $stderr.puts("error appears unrecoverable, aborting") end
	sleep 0.05
	retry unless errtimeout > 20
end
errtimeout = nil

if ARGV.find { |arg| arg =~ /^--test|^-t/ }
	$_SERVER_ = $stdin
	$_CLIENT_.puts "Running in test mode: host socket set to stdin."
elsif !$_SERVER_
	$stdout.puts 'Connecting to the real game host...'
	if $fake_stormfront and $platinum
		$_SERVER_ = TCPSocket.open('storm.gs4.game.play.net', 10124)
	elsif $fake_stormfront and $dragonrealms
		# fixme
		$stderr.puts 'Error: ip and port for dragonrealms is unknown.'
		exit
	elsif $fake_stormfront
		$_SERVER_ = TCPSocket.open('storm.gs4.game.play.net', 10024)
	else
		$_SERVER_ = TCPSocket.open(simu_quad_ip, simu_port)
	end
	$stdout.puts 'Connection with the game host is open.'
end

listener = timeout_thr = nil

if File.exists?($lich_dir + 'lich-char.txt')
	file = File.open($lich_dir + 'lich-char.txt')
	arr = file.readlines; arr = arr.find_all { |line| line !~ /^#/ }
	$clean_lich_char = arr.last.strip
	file.close
	file = nil
else
	$clean_lich_char = ';'
end

$lich_char = Regexp.escape("#{$clean_lich_char}")

undef :exit!

client_thread = Thread.new {
	$login_time = Time.now

	def do_client(client_string)
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
							script.downstream_buffer.shove(msg)
						else
							script.unique_buffer.shove(msg)
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
			else
				script_name = Regexp.escape(cmd.split.first.chomp)
				vars = cmd.split[1..-1].join(' ').scan(/"[^"]+"|[^"\s]+/).collect { |val| val.gsub(/(?!\\)?"/,'') }
				start_script(script_name, vars)
			end
		else
			$_SERVER_.puts client_string
			$_CLIENTBUFFER_.shove client_string
		end
		Script.new_upstream(client_string)
	end

	if $fake_stormfront
		#
		# send the login key
		#
		client_string = $_CLIENT_.gets
		$_CLIENTBUFFER_.shove(client_string.dup)
		$_SERVER_.write(client_string)
		#
		# take the version string from the client, ignore it, and ask the server for xml
		#
		$_CLIENT_.gets
		client_string = "/FE:WIZARD /VERSION:1.0.1.22 /P:#{RUBY_PLATFORM} /XML\r\n"
		$_CLIENTBUFFER_.shove(client_string.dup)
		$_SERVER_.write(client_string)
		#
		# tell the server we're ready
		#
		sleep 0.3
		client_string = "<c>\r\n"
		$_CLIENTBUFFER_.shove(client_string)
		$_SERVER_.write(client_string)
		sleep 0.3
		client_string = "<c>\r\n"
		$_CLIENTBUFFER_.shove(client_string)
		$_SERVER_.write(client_string)
		#
		# ask the server for both wound and scar information
		#
		client_string = "<c>_injury 2\r\n"
		$_CLIENTBUFFER_.shove(client_string)
		$_SERVER_.write(client_string)
		#
		# client wants to send "GOOD", xml server won't recognize it
		#
		$_CLIENT_.gets
	else
		2.times {
			client_string = $_CLIENT_.gets
			$_CLIENTBUFFER_.shove(client_string.dup)
			$_SERVER_.write(client_string)
		}
	end

	begin	
		while client_string = $_CLIENT_.gets
			begin
				$_IDLETIMESTAMP_ = Time.now
				client_string = UpstreamHook.run(client_string)
				next if client_string.nil?
				if Alias.find(client_string)
					Alias.run(client_string)
				else
					do_client(client_string)
				end
			rescue
				$stderr.puts "error in client thread: #{$!}"
				$stderr.puts $!.backtrace.join("\r\n")
			end
		end
	rescue
		$stderr.puts "error in client thread: #{$!}"
		$stderr.puts $!.backtrace.join("\r\n")
		sleep 0.5
		retry if not $_CLIENT_.closed? and not $_SERVER_.closed?
	end
	[Script.running + Script.hidden].each { |script| script.kill }
	$_SERVER_.puts('quit') unless $_SERVER_.closed?
	$_SERVER_.close unless $_SERVER_.closed?
	$_CLIENT_.close unless $_CLIENT_.closed?
	sleep 0.1
	exit
}
#
# End of client thread
#

# fixme: bare bones

#
# Server thread for Stormfront and fake Stormfront
#
server_thread = Thread.new {
	SF_Listener = SF_XML.new
	begin
		while $_SERVERSTRING_ = $_SERVER_.gets
			begin
				$_SERVERBUFFER_.shove($_SERVERSTRING_)
				$_SERVERSTRING_ = DownstreamHook.run($_SERVERSTRING_)
				next unless $_SERVERSTRING_
				if $fake_stormfront
					$_CLIENT_.write(sf_to_wiz($_SERVERSTRING_))
				else
					$_CLIENT_.write($_SERVERSTRING_)
				end
				REXML::Document.parse_stream($_SERVERSTRING_, SF_Listener)
				Script.new_downstream_xml($_SERVERSTRING_)
				stripped_server = strip_xml($_SERVERSTRING_)
				stripped_server.split("\r\n").each { |line|
					unless line =~ /^\s\*\s[A-Z][a-z]+ (?:returns home from a hard day of adventuring|joins the adventure|just bit the dust)|^\r*\n*$/
						Script.new_downstream(line) unless line.empty?
					end
				}
			rescue
				$stderr.puts "error in server thread: #{$!}"
				$stderr.puts $!.backtrace.join("\r\n")
			end
		end
	rescue Exception
		if $!.to_s =~ /invalid argument/oi
			respond("Lich #{$version}: the file descriptor for Lich's game socket is no longer recognized by Windows as a valid connection; either the game has crashed or you were dropped for inactivity and Lich wasn't notified that the socket has been closed.  There isn't much I can do to get around this random quirk in Windows.") if $LICH_DEBUG
			respond($!.to_s) if $LICH_DEBUG
			respond($!.backtrace.join("\r\n")) if $LICH_DEBUG
		else
			$stderr.puts "error in server thread: #{$!}"
			$stderr.puts $!.backtrace.join("\r\n")
			sleep 0.5
			retry if not $_CLIENT_.closed? and not $_SERVER_.closed?
		end
	rescue
		$stderr.puts "error in server thread: #{$!}"
		$stderr.puts $!.backtrace.join("\r\n")
		sleep 0.5
		retry if not $_CLIENT_.closed? and not $_SERVER_.closed?
	end
	respond("--- Lich's connection to the game has been closed.\r\n\r\n") if $LICH_DEBUG and !$_CLIENT_.closed?
	[Script.running + Script.hidden].each { |script| script.kill }
	$_CLIENT_.close unless $_CLIENT_.closed?
	$_SERVER_.puts("<c>quit") unless $_SERVER_.closed?
	$_SERVER_.close unless $_SERVER_.closed?
	sleep 0.1
	exit
}

server_thread.priority = 4
client_thread.priority = 3

if ARGV.find { |arg| arg =~ /^--debug$/ }
	$stderr.close unless $stderr.closed?
end
$stdout = $_CLIENT_
unless ARGV.find { |arg| arg =~ /^--stderr$/ }
	$stderr = $_CLIENT_
else
	$stderr.puts "$stderr will not be redirected."
end

$_CLIENT_.sync = true
$_SERVER_.sync = true

$_CLIENT_.write("--- Lich v#{$version} caught the connection and is active. Type #{$clean_lich_char}help for usage info.\r\n\r\n")

until $_SERVERBUFFER_.find { |line| line =~ /Welcome to GemStone/i } or $_SERVERBUFFER_.to_a.length > 5
	sleep 1
end
sleep 1

# Overwrite the user's encrypted login key before loading the favorites list (make sure it's gone before a script could possibly start and snag it)
$_CLIENTBUFFER_[0] = "*** (encrypted login key would be here, but it is erased by Lich immediately after use) ***"

# Call the garbage collector to make as certain as possible the key is gone forever (it's overkill, but it can't hurt...)
begin
	GC.start
rescue
	echo "Error starting garbage collector. (4)"
end

def show_notice
	unless $stormfront and not $fake_stormfront
		respond("\034GSL")
	else
#		respond('<output class="mono"/>')
#		respond('<pushBold/>')
	end
	respond
	respond("** NOTICE:")
	respond("** Lich is not intended to facilitate AFK scripting.")
	respond("** The author does not condone violation of game policy,")
	respond("** nor is he in any way attempting to encourage it.")
	respond
	if $stormfront and not $fake_stormfront
		respond("** (this notice will never repeat, it's one-time-only)")
	else
		respond("** (this notice will never repeat, it's one-time-only)\034GSM")
#		respond('<popBold/>')
#		respond('<output class=""/>')
	end
	respond("\r\n")
end

unless File.exists?("#{$lich_dir}notfirst.txt") or !$_SERVERBUFFER_.find { |line| line =~ /GemStone|DragonRealm/i }
	begin
		show_notice
		file = File.open("#{$lich_dir}notfirst.txt", "w"); file.puts("just tracks if this is your first run or not"); file.close; file = nil
	rescue
		respond("There's been an unknown error recording that you've seen this notice. I'm sorry, but it appears Lich will")
		respond("have to repeat this notice every login: #{$!.chomp}.")
	end
end

undef :hack_hosts

begin
	server_thread.join
rescue Exception
	$_LICHERRCNT_ += 1
	if server_thread.alive? and !$_CLIENT_.closed? and !$_SERVER_.closed?
		respond "Exception bug: #{$!}" if $LICH_DEBUG
		respond $!.backtrace.join("\r\n") if $LICH_DEBUG
		retry
	end
	respond "Fatal (non-recoverable) error during execution: #{$!}" if $LICH_DEBUG
	respond $!.backtrace.join("\r\n") if $LICH_DEBUG
rescue SystemExit
	$_LICHERRCNT_ += 1
	if server_thread.alive? and !$_CLIENT_.closed? and !$_SERVER_.closed?
		respond "SystemExit bug: #{$!}" if $LICH_DEBUG
		respond $!.backtrace.join("\r\n") if $LICH_DEBUG
		retry
	end
	respond "Fatal (non-recoverable) error during execution: #{$!}" if $LICH_DEBUG
	respond $!.backtrace.join("\r\n") if $LICH_DEBUG
rescue
	$_LICHERRCNT_ += 1
	if server_thread.alive? and !$_CLIENT_.closed? and !$_SERVER_.closed?
		respond "StandardError bug: #{$!}" if $LICH_DEBUG
		respond $!.backtrace.join("\r\n") if $LICH_DEBUG
		retry
	end
	respond "Fatal (non-recoverable) error during execution: #{$!}" if $LICH_DEBUG
	respond $!.backtrace.join("\r\n") if $LICH_DEBUG
end


[Script.running + Script.hidden].each { |script| script.kill }
sleep 0.1
exit
