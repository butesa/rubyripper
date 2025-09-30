#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
#    Copyright (C) 2016 BleskoDev (bleskodev@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubyripper/metadata/data'
require 'rubyripper/metadata/freedb/freedbRecordGenerator'
require 'rubyripper/metadata/freedb/saveFreedbRecord'
require 'rubyripper/disc/scanDiscCdinfo'

# This class is a 'fake' provider (used when all other providers have failed).
# It simply fills the  metadata's tracklist with default track names.
# When requested to save, it will save its content to local freedb record.
class NoProvider
  attr_reader :status

  def initialize(disc, metadata=nil, generator=nil, save=nil, prefs=nil)
    @disc = disc
    @md = metadata ? metadata : Metadata::Data.new()
    @generator = generator ? generator : FreedbRecordGenerator.new()
    @save = save ? save : SaveFreedbRecord.new()
    @prefs = prefs ? prefs : Preferences::Main.instance
    
    @cdtext = nil
    if @prefs.useCdText
      # TODO: Do not use class check
      if @disc.advancedTocScanner.is_a?(ScanDiscCdinfo)
        @cdtext = @disc.advancedTocScanner
      else
        puts 'cd-info is not found on your system. Cd text fallback is not available'
      end
    end
  end

  # get metadata for the disc
  def get()
    if @cdtext
      # use the cd text of the disc
      @cdtext.scan
      
      @md.album = @cdtext.album if @cdtext.album
      @md.artist = @cdtext.artist if @cdtext.artist
      
      # check for various artists
      various = false
      (1..@disc.audiotracks).each do |track|
        trackArtist = @cdtext.getVarArtist(track)
        if trackArtist && trackArtist != @md.artist
          various = true 
          break
        end
      end
      
      (1..@disc.audiotracks).each do |track|
        trackname = @cdtext.getTrackname(track)
        # default track name as fallback
        @md.setTrackname(track, trackname ? trackname : @md.trackname(track))
        
        if various
          artist = @cdtext.getVarArtist(track)
          @md.setVarArtist(track, artist ? artist : @md.artist)
        end
      end
    else
      # generate default track list (using default track names)
      (1..@disc.audiotracks).each do |track|
        @md.setTrackname(track, @md.trackname(track))
      end
    end
    @status = 'ok'
  end

  # convert metadata content to freedb record and save it localy
  def save()
    freedbRecord = @generator.generate(@disc)
    @save.save(freedbRecord, @md.genre, @disc.freedbDiscid, force=true)
  end

  private
  
  # if the method is not found try to look it up in the data object
  def method_missing(name, *args)
    @md.send(name, *args)
  end
end
