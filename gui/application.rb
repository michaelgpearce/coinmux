class Gui::Application < Java::JavaxSwing::JFrame
  include Coinmux::Facades

  WIDTH = 600
  HEIGHT = 450
  MIXES_TABLE_REFRESH_SECONDS = 5

  attr_accessor :amount, :participants, :bitcoin_network, :coin_join_uri, :input_private_key, :output_address, :change_address, :current_view

  import 'java.awt.CardLayout'
  import 'java.awt.Dimension'
  import 'java.awt.Desktop'
  import 'java.net.URL'
  import 'java.net.URI'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.BoxLayout'
  import 'javax.swing.ImageIcon'
  import 'javax.swing.JDialog'
  import 'javax.swing.JFrame'
  import 'javax.swing.JOptionPane'
  import 'javax.swing.JPanel'

  def initialize
    super Coinmux::BANNER

    self.coin_join_uri = Coinmux::CoinJoinUri.new(network: 'p2p')
    self.bitcoin_network = :testnet
  end

  def start
    show_frame do
      root_panel.add(card_panel)

      {
        available_mixes: Gui::View::AvailableMixes,
        mix_settings: Gui::View::MixSettings,
        mixing: Gui::View::Mixing
      }.each do |key, view_class|
        views[key] = view = build_view(view_class)
        view.root_panel.setPreferredSize(Dimension.new(WIDTH, HEIGHT))
        card_panel.add(view.root_panel, key.to_s)
        view.add
      end

      if Coinmux.os == :macosx
        Java::ComAppleEawt::Application.new.tap do |app|
          app.addApplicationListener(AppleAdapter.new(self))
          app.setEnabledPreferencesMenu(true)
        end
      end

      show_view(:available_mixes)
    end

    Gui::EventQueue.instance.future_exec(2) do # show "loading" for a couple of seconds minimum
      data_store.connect do |event|
        if event.error
          show_error_dialog("Unable to connect to data store: #{event.error}")
        else
          refresh_mixes_table
        end
      end
    end
  end

  def open_webpage(url_string)
    Desktop.getDesktop().browse(URL.new(url_string).toURI()) rescue puts $!
  end

  def show_error_dialog(*error_messages)
    JOptionPane.showMessageDialog(
      self,
      error_messages.collect(&:to_s).to_java(:string),
      "Error",
      JOptionPane::ERROR_MESSAGE)
  end

  def show_view(view)
    self.current_view = view
    views[view].show
    card_panel.getLayout().show(card_panel, view.to_s)
  end

  def root_panel
    @root_panel ||= JPanel.new.tap do |panel|
      panel.setLayout(BoxLayout.new(panel, BoxLayout::PAGE_AXIS))
      panel.setBorder(BorderFactory.createEmptyBorder())
    end
  end

  def preferences_panel
    load_preferences_panel_and_view
    @preferences_panel
  end

  def preferences_view
    load_preferences_panel_and_view
    @preferences_view
  end

  def data_store
    @data_store ||= Coinmux::DataStore::Factory.build(coin_join_uri)
  end

  def show_preferences
    JDialog.new(self, "Coinmux", true).tap do |dialog|
      panel = JPanel.new
      panel.setBorder(create_frame_border)
      panel.add(preferences_panel)
      dialog.add(panel)
      dialog.pack
      dialog.setLocationRelativeTo(self)

      # show once part of dialog
      preferences_view.show

      dialog.show
    end
  end

  def show_about
    icon = ImageIcon.new(Coinmux::FileUtil.read_content_as_java_bytes('gui', 'assets', 'icon_80.png'))
    JOptionPane.showMessageDialog(root_panel, "Coinmux\nVersion: #{Coinmux::VERSION}", "About", JOptionPane::INFORMATION_MESSAGE, icon)
  end

  private

  def load_preferences_panel_and_view
    return if @preferences_panel.present? && @preferences_view.nil?

    @preferences_panel ||= JPanel.new.tap do |panel|
      panel.setLayout(BoxLayout.new(panel, BoxLayout::PAGE_AXIS))
      panel.setBorder(BorderFactory.createEmptyBorder())
    end

    @preferences_view ||= Gui::View::Preferences.new(self, @preferences_panel).tap do |preferences_view|
      preferences_view.add
    end
  end

  def update_mixes_table(coin_join_data)
    views[:available_mixes].update_mixes_table(coin_join_data)

    Gui::EventQueue.instance.future_exec(MIXES_TABLE_REFRESH_SECONDS) do
      refresh_mixes_table # refresh again
    end
  end

  def refresh_mixes_table
    Coinmux::Application::AvailableCoinJoins.new(data_store).find do |event|
      Gui::EventQueue.instance.future_exec do
        if event.error
          warn("Error refreshing mixes table: #{event.error}")
          update_mixes_table([])
        else
          update_mixes_table(event.data)
        end
      end
    end
  end

  def quit
    Java::JavaLang::System.exit(0)
    # clean_up_coin_join
  end

  def views
    @views ||= {}
  end

  def card_panel
    @card_panel ||= JPanel.new(CardLayout.new)
  end

  def build_view(view_class)
    panel = JPanel.new
    panel.setLayout(BoxLayout.new(panel, BoxLayout::PAGE_AXIS))
    panel.setBorder(create_frame_border)
    view_class.new(self, panel)
  end

  def create_frame_border
    BorderFactory.createEmptyBorder(10, 20, 20, 20)
  end

  def show_frame(&block)
    icon = ImageIcon.new(Coinmux::FileUtil.read_content_as_java_bytes("gui", "assets", "icon_320.png"))
    setIconImage(icon.getImage())
    getContentPane.add(root_panel)
    setDefaultCloseOperation JFrame::EXIT_ON_CLOSE
    setSize(Dimension.new(WIDTH, HEIGHT)) # even though pack() resizes, this helps start the window in the right location on screen
    setLocationRelativeTo(nil)

    yield

    pack
    setVisible(true)
    root_panel.revalidate() # OSX opening with no content about 20% of time. :(
  end

  if Coinmux.os == :macosx
    class AppleAdapter < Java::ComAppleEawt::ApplicationAdapter
      def initialize(application)
        @application = application
        super()
      end

      def handleAbout(e)
        e.setHandled(true)
        @application.send(:show_about)
      end

      def handlePreferences(e)
        @application.send(:show_preferences)
      end

      def handleQuit(e)
        @application.send(:quit)
      end
    end
  end
end
