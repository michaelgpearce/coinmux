class Gui::View::Base
  attr_accessor :application, :root_panel

  import 'java.awt.Font'
  import 'java.awt.FlowLayout'
  import 'java.awt.GridLayout'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.JLabel'
  import 'javax.swing.JPanel'
  import 'javax.swing.JSeparator'
  import 'javax.swing.border.TitledBorder'

  def initialize(application, root_panel)
    @application = application
    @root_panel = root_panel
  end

  protected

  def add_header(text)
   add_row(layout: FlowLayout.new(FlowLayout::CENTER, 0, 0)) do |parent|
      label = JLabel.new(text)
      font = label.getFont()
      label.setFont(font.java_send(:deriveFont, [Java::float], font.size() * 1.5))
      parent.add(label)
    end
  end

  def add_row(options = {}, &block)
    panel = JPanel.new
    panel.setBorder(options[:border] || BorderFactory.createEmptyBorder(0, 0, 10, 0))
    panel.setLayout(options[:layout] || GridLayout.new(0, 1))
    if options[:label]
      panel.setBorder(BorderFactory.createTitledBorder(
        BorderFactory.createEmptyBorder(), options[:label], TitledBorder::LEFT, TitledBorder::TOP))
    end
    root_panel.add(panel)

    yield(panel)
  end

  def add_button_row(&block)
    container = JPanel.new
    container.setBorder(BorderFactory.createEmptyBorder(10, 0, 0, 0))
    container.setLayout(GridLayout.new(0, 1))
    root_panel.add(container)

    container.add(JSeparator.new)

    panel = JPanel.new
    panel.setLayout(FlowLayout.new(FlowLayout::CENTER, 0, 0))
    container.add(panel)

    yield(panel)
  end
  
end

