class Coinmux::DataStore
  include Singleton
  
  import 'java.io.IOException'
  import 'net.tomp2p.p2p.Peer'
  import 'net.tomp2p.p2p.PeerMaker'
  import 'net.tomp2p.peers.Number160'
  import 'java.util.Random'
  
  def startup
    @peer = PeerMaker.new(Number160.new(Random.new)).setPorts(14141).makeAndListen()
    @peer.getConfiguration().setBehindFirewall(true)
  end

  def shutdown
    @peer.shutdown if @peer
  end
end