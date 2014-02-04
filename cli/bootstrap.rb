require 'fileutils'

class Cli::Bootstrap
  DEFAULT_PORT = 14141

  attr_accessor :port

  import 'java.io.IOException'
  import 'java.util.Random'
  import 'net.tomp2p.p2p.Peer'
  import 'net.tomp2p.p2p.PeerMaker'
  import 'net.tomp2p.peers.Number160'
  import 'net.tomp2p.storage.StorageDisk'
  import 'net.tomp2p.storage.StorageGeneric'
  
  def initialize(options = {})
    options.assert_keys!(optional: :port)

    self.port = options[:port].try(:to_i) || DEFAULT_PORT
  end

  def startup
    @peer = PeerMaker.new(Number160.new(Random.new)).setPorts(port).makeAndListen()
    @peer.getPeerBean().setStorage(StorageDisk.new(storage_path));
    @peer.getConfiguration().setBehindFirewall(true)

    # blocks current thread
  end

  private

  def storage_path
    begin
      FileUtils.mkdir_p(path = File.join(Coinmux.root, 'tmp', 'bootstrap_storage'))
    rescue
      FileUtils.mkdir_p(path = File.join('.', 'tmp', 'bootstrap_storage'))
    end

    path
  end
end
