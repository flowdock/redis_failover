require 'ostruct'

module RedisFailover
  # Test stub for Redis.
  class RedisStub
    class Proxy
      def initialize(opts = {})
        @info = {'role' => 'master'}
        @config = {'slave-serve-stale-data' => 'yes'}
      end

      def echo(*args)
        if @info['master_sync_in_progress'] == '1' && @config['slave-serve-stale-data'] == 'no'
          raise Errno::ECONNREFUSED
        end
      end

      def del(*args)
      end

      def slaveof(host, port)
        if host == 'no' && port == 'one'
          @info['role'] = 'master'
          @info.delete('master_host')
          @info.delete('master_port')
        else
          @info['role'] = 'slave'
          @info['master_host'] = host
          @info['master_port'] = port.to_s
        end
      end

      def info
        @info.dup
      end

      def change_role_to(role)
        @info['role'] = role
      end

      def config(action, attribute)
        [action, @config[attribute]]
      end

      def force_sync_with_master(serve_stale_reads)
        @config['slave-serve-stale-data'] = serve_stale_reads ? 'yes' : 'no'
        @info['master_sync_in_progress'] = '1'
      end

      def force_sync_done
        @info['master_sync_in_progress'] = '0'
      end
    end

    attr_reader :host, :port, :available
    def initialize(opts = {})
      @host = opts[:host]
      @port = Integer(opts[:port])
      @proxy = Proxy.new(opts)
      @available = true
    end

    def method_missing(method, *args, &block)
      if @available
        @proxy.send(method, *args, &block)
      else
        raise Errno::ECONNREFUSED
      end
    end

    def change_role_to(role)
      @proxy.change_role_to(role)
    end

    def make_available!
      @available = true
    end

    def make_unavailable!
      @available = false
    end

    def to_s
      "#{@host}:#{@port}"
    end

    def client
      OpenStruct.new(:host => @host, :port => @port)
    end
  end

  module RedisStubSupport
    def redis
      @redis ||= RedisStub.new(:host => @host, :port => @port)
    end
    alias_method :new_client, :redis
  end
end
