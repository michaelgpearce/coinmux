class Gui::View::Application < Java::JavaxSwing::JFrame
  WIDTH = 600
  HEIGHT = 500

  attr_accessor :amount, :participants

  import 'java.awt.CardLayout'
  import 'java.awt.Dimension'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.BoxLayout'
  import 'javax.swing.JFrame'
  import 'javax.swing.JPanel'

  def initialize
    super Coinmux::BANNER
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

      show_view(:available_mixes)
    end
  end

  def show_view(view)
    views[view].show
    card_panel.getLayout().show(card_panel, view.to_s)
  end

  private

  def views
    @views ||= {}
  end

  def card_panel
    @card_panel ||= JPanel.new(CardLayout.new)
  end

  def build_view(view_class)
    panel = JPanel.new
    panel.setLayout(BoxLayout.new(panel, BoxLayout::PAGE_AXIS))
    panel.setBorder(BorderFactory.createEmptyBorder(10, 20, 20, 20))
    view_class.new(self, panel)
  end

  def root_panel
    @root_panel ||= JPanel.new.tap do |panel|
      panel.setLayout(BoxLayout.new(panel, BoxLayout::PAGE_AXIS))
      panel.setBorder(BorderFactory.createEmptyBorder())
    end
  end

  def show_frame(&block)
    getContentPane.add(root_panel)
    setDefaultCloseOperation JFrame::EXIT_ON_CLOSE
    setSize(Dimension.new(WIDTH, HEIGHT)) # even though pack() resizes, this helps start the window in the right location on screen
    setLocationRelativeTo(nil)

    yield

    pack
    setVisible(true)
    root_panel.revalidate() # OSX opening with no content about 20% of time. :(
  end
end
