#!/usr/bin/env ruby
require 'fileutils'
require 'digest/md5'
require 'optparse'
require 'ostruct'
include FileUtils

PROGRAM_VERSION = 1.0

$options = OpenStruct.new


def program_options
  [
    ['-f','--from FROM', "The directory to sync files from.",
      lambda { |value| 
        $options.from = value
      }
    ],
    ['-t','--to TO', "The directory to sync files to.",
      lambda { |value| 
        $options.to = value
      }
    ],
    ['-v','--[no]verbose', "Run verbosely",
      lambda { |value| 
        $options.verbose = true
      }
    ],
    ['-V','--version', "Display the program version.",
      lambda { |value|
          puts "merge_files : version #{PROGRAM_VERSION}"
            exit
        }
    ]
  ]
end

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: merge_files.rb [OPTIONS]"
  opts.separator ""
  opts.separator "Options are ..."
  opts.on_tail("-h", "--help", "-H", "Display this help message.") do
    puts opts
    exit
  end
  program_options.each { |args| opts.on(*args) }
end

begin
  option_parser.parse!
rescue OptionParser::ParseError => error
  puts error.message
  puts option_parser
  exit
end

if $options.to.nil? 
  puts option_parser
  exit
end  

if $options.from.nil? 
  puts option_parser
  exit
end  

def syncDirectories(syncFrom, syncTo)
  Dir.entries(syncFrom).each{|fileOrDir| 
    if (fileOrDir != '.' && fileOrDir != '..') then
      move_file_or_directory(syncFrom,syncTo,fileOrDir)
    end
  }  
end

def move_file_or_directory(syncFrom,syncTo,fileOrDir)
  fileAndDirectory = "#{syncFrom}#{fileOrDir}"

  if(!File.directory?(fileAndDirectory)) then
    move_file(syncFrom,syncTo,fileOrDir)
  else
    syncToDir = "#{syncTo}#{fileOrDir}"

    if(!Dir.exist?(syncToDir)) then
      Dir.mkdir(syncToDir)
    end

    syncDirectories("#{fileAndDirectory}/", "#{syncToDir}/")
  end
end

def move_file (syncFrom,syncTo,fileName)
  fileFrom = "#{syncFrom}#{fileName}"
  fileTo = "#{syncTo}#{fileName}"

  begin
    if(!fileName.start_with?('.'))
      if(!File.exist?(fileTo)) then
        copyFile(fileFrom, fileTo)
      else
        fileFromDigest = Digest::MD5.hexdigest(File.read(fileFrom.strip))
        fileToDigest = Digest::MD5.hexdigest(File.read(fileTo.strip))
      
        if(fileFromDigest == fileToDigest) then
          puts "Digest for #{fileFrom} matches #{fileTo} not updating" if $options.verbose
        else
          copyFile(fileFrom, fileTo)
        end
      end 
    else
      puts "Not copying hidden file #{fileName}" if $options.verbose
    end  
  rescue Exception => e
    puts "ERROR Copying #{fileFrom} to #{fileTo}"
    puts e.message
  end 
end

def copyFile(fileFrom,fileTo)
  cp(fileFrom,fileTo,:verbose => $options.verbose)
end

def getAbsolutePath(directory)

  absolutePath = nil

  if(Dir.exist?(directory)) then
  
    absolutePath =  "#{File.expand_path(directory)}/"
  end

  return absolutePath
end 

syncFrom = $options.from
syncTo = $options.to

syncFrom = getAbsolutePath(syncFrom)
syncTo = getAbsolutePath(syncTo)

puts "Syncing from: [#{syncFrom}] to [#{syncTo}]" if $options.verbose

if(syncFrom != nil && syncTo != nil) then
  syncDirectories(syncFrom,syncTo)
end