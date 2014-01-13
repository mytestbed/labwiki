#!/usr/bin/env ruby

Logging.configure do
  # Default logging level should be debug, write to stdout & log file
  logger(:root) do
    level :info
    appenders %w(my_stdout my_file)
  end

  # But we don't want to see :debug messages in stdout
  appender('my_stdout') do
    type 'Stdout'
    layout do
      type 'Pattern'
      pattern "%d %l %m\n"
    end
  end

  appender('my_file') do
    type 'File'
    filename "/tmp/#{OmfEc.experiment.id}.log"
    layout do
      type 'Pattern'
      pattern "%d %l %m\n"
    end
  end
end
