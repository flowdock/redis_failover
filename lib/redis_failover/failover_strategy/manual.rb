module RedisFailover
  class FailoverStrategy
    # Failover strategy that does nothing and relies on someone performing a manual failover
    class Manual < FailoverStrategy
      # @see RedisFailover::FailoverStrategy#find_candidate
      def find_candidate(snapshots)
        nil
      end
    end
  end
end
