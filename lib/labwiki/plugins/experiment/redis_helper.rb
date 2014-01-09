require "redis"

module LabWiki::Plugin::Experiment
  REDIS_NS = 'omf_ec_s'

  module RedisHelper
    def redis
      @@redis ||= Redis.new(host: ENV['REDIS_HOST'])
    end

    def ns(*keys)
      "#{REDIS_NS}:#{keys.join(':')}"
    end
  end
end
