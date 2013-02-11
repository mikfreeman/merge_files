#!/usr/bin/env ruby
require 'fileutils'
require 'digest/md5'
include FileUtils::Verbose

def move_file_or_directory(syncFrom,syncTo,fileOrDir)
  fileAndDirectory = "#{syncFrom}#{fileOrDir}"

  if(!File.directory?(fileAndDirectory)) then
    move_file(syncFrom,syncTo,fileOrDir)
  else
    syncToDir = "#{syncTo}#{fileOrDir}"

    if(!Dir.exist?(syncToDir)) then
      Dir.mkdir(syncToDir)
    end

    Dir.entries(fileAndDirectory).each{|subFileOrDir| 
      if (subFileOrDir != '.' && subFileOrDir != '..') then  
        move_file_or_directory("#{fileAndDirectory}/","#{syncToDir}/",subFileOrDir)
      end
    }
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
          puts "Digest for #{fileFrom} matches #{fileTo} not updating"
        else
          copyFile(fileFrom, fileTo)
        end
      end 
    else
      puts "Not copying hidden file #{fileName}"
    end  
  rescue Exception
    puts "ERROR Copying #{fileFrom} to #{fileTo}"
  end 
end

def copyFile(fileFrom,fileTo)
  puts "Copying #{fileFrom} to #{fileTo}"
  cp(fileFrom,fileTo)
end

def getAbsolutePath(directory)

  absolutePath = nil

  if(Dir.exist?(directory)) then
  
    absolutePath =  "#{File.expand_path(directory)}/"
  end

  return absolutePath
end 

syncFrom =ARGV[0]
syncTo =ARGV[1]

syncFrom = getAbsolutePath(syncFrom)
syncTo = getAbsolutePath(syncTo)

puts "Syncing from: #{syncFrom} to #{syncTo}"

if(syncFrom != nil && syncTo != nil) then
  Dir.entries(syncFrom).each{|fileOrDir| 
    if (fileOrDir != '.' && fileOrDir != '..') then
      move_file_or_directory(syncFrom,syncTo,fileOrDir)
    end
  }
end