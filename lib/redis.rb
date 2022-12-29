require 'connection_pool'
require 'redis'

$redis = ConnectionPool::Wrapper.new(size: 6, timeout: 3) { Redis.new }