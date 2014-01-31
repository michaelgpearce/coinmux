require 'java'

class Coinmux::DataStore::Tomp2p
  include Coinmux::Facades

  attr_accessor :coin_join_uri

  DEFAULT_BOOTSTRAP_HOST = "coinjoin.coinmux.com"
  DEFAULT_P2P_PORT = 14141
  
  import 'java.io.IOException'
  import 'java.net.InetAddress'
  import 'java.net.Inet4Address'
  import 'java.security.KeyPair'
  import 'java.util.Random'

  import 'net.tomp2p.futures.FutureBootstrap'
  import 'net.tomp2p.futures.FutureDiscover'
  import 'net.tomp2p.futures.FutureDHT'
  import 'net.tomp2p.p2p.Peer'
  import 'net.tomp2p.p2p.PeerMaker'
  import 'net.tomp2p.peers.Number160'
  import 'net.tomp2p.peers.PeerAddress'
  import 'net.tomp2p.storage.Data'

  def initialize(coin_join_uri)
    self.coin_join_uri = coin_join_uri
  end

  def coin_join_identifier
    @coin_join_identifier ||= (coin_join_uri.params["identifier"] || "coinjoins-#{Coinmux.env}")
  end

  def bootstrap_host
    @bootstrap_host ||= (coin_join_uri.params["bootstrap"] || DEFAULT_BOOTSTRAP_HOST).gsub(/:.*/, "")
  end

  def bootstrap_port
    @bootstrap_port ||= (
      port = (coin_join_uri.params["bootstrap"] || "").gsub(/.*:/, "").to_i
      port = DEFAULT_P2P_PORT if port == 0
      port
    )
  end

  def startup(&callback)
    address = Inet4Address.getByName(bootstrap_host)
    @peer = PeerMaker.new(Number160.new(Random.new)).setPorts(bootstrap_port).makeAndListen()
    peer_address = PeerAddress.new(Number160::ZERO, address, bootstrap_port, bootstrap_port)
    @peer.getConfiguration().setBehindFirewall(true)
    exec(@peer.discover().setPeerAddress(peer_address), callback) do |future|
      if future.isSuccess()
        @peer.bootstrap().start()
        info "My external address is #{future.getPeerAddress()}"
        Coinmux::Event.new(data: future.getPeerAddress())
      else
        info "Failed #{future.getFailedReason()}"
        Coinmux::Event.new(error: future.getFailedReason())
      end
    end
  end

  def shutdown(&callback)
    @peer.shutdown
  end

  def generate_identifier
    Number160.new(Random.new).toString()
  end

  def convert_to_request_only_identifier(identifier)
    # TODO: not sure how access control works
    identifier
  end

  def identifier_can_insert?(identifier)
    # TODO: not sure how access control works
    true
  end

  def identifier_can_request?(identifier)
    # TODO: not sure how access control works
    true
  end

  def insert(identifier, data, &callback)
    add_list(identifier, data, &callback)
  end
  
  def fetch_first(identifier, &callback)
    get_list(identifier) do |event|
      event.data = event.data.first if event.data
      yield(event)
    end
  end
  
  def fetch_last(identifier, &callback)
    get_list(identifier) do |event|
      event.data = event.data.last if event.data
      yield(event)
    end
  end
  
  def fetch_all(identifier, &callback)
    get_list(identifier, &callback)
  end
  
  # items should be in reverse inserted order, but data returned as an unordered set by Tomp2p
  def fetch_most_recent(identifier, max_items, &callback)
    get_list(identifier) do |event|
      event.data = (event.data[-1*max_items..-1] || event.data).reverse! if event.data
      yield(event)
    end
  end
  
  private

  def peer
    @peer
  end

  class FutureHandler < Java::NetTomp2pFutures::BaseFutureAdapter
    attr_accessor :callback

    def initialize(callback)
      super()
      self.callback = callback
    end

    def operationComplete(future)
      callback.call(future)
    end
  end

  def exec(startable, callback, &block)
    future = startable.start()
    if callback.nil?
      future.awaitUninterruptibly()
      event = block.call(future)

      raise Coinmux::Error, event.error if event.error
      event.data
    else
      handler_proc = lambda do |future|
        event = block.call(future)
        callback.call(event)
      end
      future.addListener(FutureHandler.new(handler_proc))
      nil
    end
  end

  def key_ttl
    2.hours
  end

  def current_key(key)
    "#{Time.now.to_i / key_ttl * key_ttl}:#{key}"
  end

  def previous_key(key)
    "#{Time.now.to_i / key_ttl * key_ttl - key_ttl}:#{key}"
  end

  def add_list(key, value, &callback)
    key = current_key(key)

    json = {
      timestamp: Time.now.to_i, # TODO: need to come up with something better than timestamps here
      value: value
    }.to_json

    exec(peer.add(create_hash(key)).setData(Data.new(json).set_ttl_seconds(11)).setRefreshSeconds(5).setDirectReplication(), callback) do |future|
      if future.isSuccess()
        Coinmux::Event.new(data: nil)
      else
        Coinmux::Event.new(error: future.getFailedReason())
      end
    end
  end

  # TODO: I don't know how to get items to expire in the set, so we'll use a new set every hour, to let the
  # old set expire.  But we'll also look at the previous set. This should be fun for computers with incorrect time setup.
  def get_list(key, &callback)
    do_get_list(current_key(key)) do |prev_event|
      do_get_list(previous_key(key)) do |current_event|
        result_event = Coinmux::Event.new
        if prev_event.data || current_event.data
          result_event.data = (prev_event.data || []) + (current_event.data || [])
        else
          result_event.error = prev_event.error || current_event.error
        end
        yield(result_event)
      end
    end
  end

  def do_get_list(key, &callback)
    exec(peer.get(create_hash(key)).setAll(), callback) do |future|
      if future.isSuccess()
        hashes = future.getDataMap().values().each_with_object([]) do |value, hashes|
          json = value.getObject().to_s
          if (hash = JSON.parse(json) rescue nil)
            if (timestamp = Time.at(hash['timestamp'].to_i).to_i rescue nil)
              if Time.now.to_i - timestamp < DATA_TIME_TO_LIVE
                hashes << hash
              end
            end
          end
        end.sort do |left, right|
          left_timestamp, right_timestamp = [left, right].collect do |hash|
            Time.at(hash['timestamp'].to_i)
          end

          left_timestamp <=> right_timestamp
        end

        data = hashes.collect { |hash| hash['value'].to_s }

        Coinmux::Event.new(data: data)
      elsif future.getFailedReason().to_s =~ /Expected >0 result, but got 0/
        Coinmux::Event.new(data: [])
      else
        Coinmux::Event.new(error: future.getFailedReason())
      end
    end
    nil
  end

  def create_hash(name)
    Number160.java_send(:createHash, [java.lang.String], name)
  end
end
