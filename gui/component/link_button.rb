class Gui::Component::LinkButton < Java::JavaxSwing::JButton
  import 'java.awt.Color'
  import 'java.awt.Cursor'
  import 'java.awt.Insets'
  import 'javax.swing.UIManager'

  def initialize(label = nil)
    super(label.to_s)
    setBorderPainted(false)
    setBorder(nil)
    setMargin(Insets.new(0, 0, 0, 0))
    setCursor(Cursor.getPredefinedCursor(Cursor::HAND_CURSOR))
    setOpaque(false)
    setContentAreaFilled(false)
    setForeground(Color.blue)
  end
end
