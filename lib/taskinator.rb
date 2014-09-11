require 'json'
require 'yaml'
require 'securerandom'
require 'workflow'

require 'taskinator/version'

require 'taskinator/complete_on'
require 'taskinator/redis_connection'
require 'taskinator/logger'

require 'taskinator/definition'

require 'taskinator/visitor'
require 'taskinator/persistence'

require 'taskinator/task'
require 'taskinator/tasks'
require 'taskinator/process'

require 'taskinator/task_worker'
require 'taskinator/process_worker'

require 'taskinator/executor'
require 'taskinator/queues'

require 'taskinator/api'

module Taskinator

  NAME = "Taskinator"
  LICENSE = 'See LICENSE.txt for licensing details.'

  DEFAULTS = {
  }

  class << self
    def options
      @options ||= DEFAULTS.dup
    end
    def options=(opts)
      @options = opts
    end

    ##
    # Configuration for Taskinator client, use like:
    #
    #   Taskinator.configure_client do |config|
    #     config.redis = { :namespace => 'myapp', :pool_size => 1, :url => 'redis://myhost:8877/0' }
    #     config.queue_config = { :process_queue => 'processes', :task_queue => 'tasks' }
    #   end
    #
    def configure
      yield self if block_given?
    end

    def redis(&block)
      raise ArgumentError, "requires a block" unless block_given?
      redis_pool.with(&block)
    end

    def redis_pool
      @redis ||= Taskinator::RedisConnection.create
    end

    def redis=(hash)
      @redis = Taskinator::RedisConnection.create(hash)
    end

    def logger
      Taskinator::Logging.logger
    end

    def logger=(log)
      Taskinator::Logging.logger = log
    end

    # the queue adapter to use
    # supported adapters include
    # :delayed_job, :redis and :sidekiq
    # NOTE: ensure that the respective gem is included
    attr_reader :queue_adapter

    def queue_adapter=(adapter)
      @queue_adapter = adapter
      @queue = nil
    end

    # configuration, usually a hash, which will be passed
    # to the configured queue adapter
    attr_reader :queue_config

    def queue_config=(config)
      @queue_config = config
      @queue = nil
    end

    def queue
      adapter = self.queue_adapter || :resque
      config = queue_config || {}
      @queue ||= Taskinator::Queues.create_adapter(adapter, config)
    end
  end
end