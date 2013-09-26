#!/usr/bin/env ruby

Logging.configure do
  # Default logging level should be debug, write to stdout & log file
  logger(:root) do
    level :debug
    appenders %w(my_stdout)
  end

  # But we don't want to see :debug messages in stdout
  appender('my_stdout') do
    type 'Stdout'
    level :info
    layout do
      type 'Pattern'
      pattern "%d %-5l %c: %m\n"
      #date_pattern "%F %T %z"
    end
  end
end
