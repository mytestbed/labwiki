require 'eventmachine'
require 'eventmachine-tail'

module LabWiki
  module Plugin
    module Experiment
      class LogFileWatcher < EventMachine::FileGlobWatch
        def initialize(pathglob, interval = 3, &block)
          super(pathglob, interval)
          @block = block
        end

        def file_found(path)
          # Read current file content
          IO.foreach(path) do |line|
            @block.call(line)
          end
          # Monitor future content written to file
          LogFileReader.new(path) do |line|
            @block.call(line)
          end
        end
      end

      class LogFileReader < EventMachine::FileTail
        def initialize(path, startpos = -1, &block)
          super(path, startpos)
          @buffer = BufferedTokenizer.new
          @block = block
        end

        def receive_data(data)
          @buffer.extract(data).each do |line|
            @block.call(line)
          end
        end
      end
    end
  end
end

