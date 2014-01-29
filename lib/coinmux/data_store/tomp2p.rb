require 'java'

class Coinmux::DataStore::Tomp2p
  include Singleton, Coinmux::Facades

  BOOTSTRAP_HOST = "coinjoin.coinmux.com"
  P2P_PORT = 14141
  DATA_TIME_TO_LIVE = 1 * 60
  
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

  def startup(&callback)
    address = Inet4Address.getByName(BOOTSTRAP_HOST)
    @peer = PeerMaker.new(Number160.new(Random.new)).setPorts(P2P_PORT).makeAndListen()
    peer_address = PeerAddress.new(Number160::ZERO, address, P2P_PORT, P2P_PORT)
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

  def get_identifier_from_coin_join_uri(coin_join_uri)
    coin_join_uri.params['identifier']
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
  
  # items are in reverse inserted order
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

  def add_list(key, value, &callback)
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

  def get_list(key, &callback)
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
