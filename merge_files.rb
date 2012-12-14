#!/usr/bin/env ruby
require 'fileutils'
require 'digest/md5'
include FileUtils::Verbose

def move_file_or_directory(syncFrom,syncTo,fileOrDir)
  fileAndDirectory = "#{syncFrom}#{fileOrDir}"
  puts "Checking action for #{fileAndDirectory}"

  if(!File.directory?(fileAndDirectory)) then
    puts "Processing file #{fileOrDir}"
    move_file(syncFrom,syncTo,fileOrDir)
  else
    puts "Processing directory #{fileAndDirectory}"
    syncToDir = "#{syncTo}#{fileOrDir}"

    if(!Dir.exist?(syncToDir)) then
      puts "making directory #{syncToDir}"
      Dir.mkdir(syncToDir)
    end

    Dir.entries(fileAndDirectory).each{|subFileOrDir| 
      if (subFileOrDir != '.' && subFileOrDir != '..') then  
      puts "Copying file or directory [#{subFileOrDir}] from [#{fileAndDirectory}] to [#{syncToDir}]"
      move_file_or_directory("#{fileAndDirectory}/","#{syncToDir}/",subFileOrDir)
      end
    }
  end
end

def move_file (syncFrom,syncTo,fileName)
    puts "Copying #{syncFrom}#{fileName} to #{syncTo}#{fileName}"
    fileFrom = "#{syncFrom}#{fileName}"
    fileTo = "#{syncTo}#{fileName}"

    begin
    if(fileName != '.DS_Store')
      if(!File.exist?(fileTo)) then
      puts "File #{fileTo} does not exist copying"
      cp(fileFrom, fileTo)
    else
      puts "File #{fileTo} exists checking hash"
      fileFromDigest = Digest::MD5.hexdigest(File.read(fileFrom.strip))
      fileToDigest = Digest::MD5.hexdigest(File.read(fileTo.strip))
      
      if(fileFromDigest == fileToDigest) then
         puts "Digest match not updating"
      else
         puts "Digest differs copying"
         cp(fileFrom, fileTo)
      end
   end 
    else
      puts "Not copying hidden file"
    end  
  rescue Exception
    puts "ERROR Copying #{syncFrom}#{fileName} to #{syncTo}#{fileName}"
  end
    
end


syncFrom =ARGV[0]
syncTo =ARGV[1]
directoryExists = true
puts "Syncing from: #{syncFrom} to #{syncTo}"

if(Dir.exist?(syncFrom)) then
  puts "Found #{syncFrom} directory"
  syncFrom = "#{File.expand_path(syncFrom)}/"
  puts "Using absolute path #{syncFrom}"
else
  puts " #{syncFrom} directory not found not proceeding" 
  directoryExists = false
end

if(Dir.exist?(syncTo)) then
  puts "Found #{syncTo} directory"
  syncTo = "#{File.expand_path(syncTo)}/"
  puts "Using absolute path #{syncTo}"
else
  puts " #{syncTo} directory not found not proceeding" 
  directoryExists = false
end

if(directoryExists) then
  Dir.entries(syncFrom).each{|fileOrDir| 
    if (fileOrDir != '.' && fileOrDir != '..') then
      move_file_or_directory(syncFrom,syncTo,fileOrDir)
    end
  }
end