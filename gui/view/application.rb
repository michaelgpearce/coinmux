class Gui::View::Application < Java::JavaxSwing::JFrame
  
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

      card_panel.add(build_card_panel(Gui::View::AvailableMixes), 'available_mixes')
      card_panel.add(build_card_panel(Gui::View::MixSettings), 'mix_settings')
      card_panel.add(build_card_panel(Gui::View::Mixing), 'mixing')

      show_view('available_mixes')
    end
  end

  def show_view(view)
    card_panel.getLayout().show(card_panel, view.to_s)
  end

  private

  def card_panel
    @card_panel ||= JPanel.new(CardLayout.new)
  end

  def build_card_panel(view_class)
    JPanel.new.tap do |panel|
      panel.setLayout(BoxLayout.new(panel, BoxLayout::PAGE_AXIS))
      panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20))
      view_class.new(self, panel).add
    end
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
    setSize(Dimension.new(600, 400))
    setResizable(false)
    setLocationRelativeTo(nil)

    yield

    setVisible(true)
  end
end
