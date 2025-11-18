# frozen_string_literal: true

module Micdrop
  ##
  # Takes a list of files, directory, or glob pattern as a source
  #
  # Records in a file source will have the following items available to `take`:
  # * :content (The full content of the file, lazy-loaded only if you `take` it)
  # * :stream (A file IO stream)
  # * :filename (The filename that was used to load the file, e.g. files/s.json)
  # * :basename (The basename of the name, e.g. x.json)
  # * :path (The full path to the file, e.g. /data/migration/files/x.json)
  # * Anything returned by File.stat (:ctime, :mtime, :size, etc...)
  class FilesSource
    def initialize(dir, files: nil, glob: nil, **file_opts)
      @dir = dir
      @files = if files.nil?
                 if glob.nil?
                   Dir.children(dir)
                 else
                   Dir.glob(glob, flags: File::FNM_EXTGLOB, base: dir)
                 end
               else
                 files
               end
      @file_opts = file_opts
    end

    def each_pair
      return enum_for :each_pair unless block_given?

      @files.each do |filename|
        path = File.join(@dir, filename)
        unless File.file? path
          warn format("%s is not a file and will be skipped", path)
          next
        end

        yield filename, FilesSourceRecord.new(path, @file_opts)
      end
    end
  end

  ##
  # Wrapper object to expose files as a source item
  class FilesSourceRecord
    def initialize(filename, file_opts)
      @filename = filename
      @file_opts = file_opts
      @stat = nil
    end

    def [](key)
      case key
      when :contents, :content
        File.read @filename, **@file_opts
      when :stream
        File.open @filename, @file_opts
      when :path
        File.absolute_path @filename
      when :basename
        File.basename @filename
      when :filename
        @filename
      else
        @stat = File.stat(@filename) if @stat.nil?
        @stat.method(key).call
      end
    end
  end
end
