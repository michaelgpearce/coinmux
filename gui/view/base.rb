class Gui::View::Base
  attr_accessor :application, :root_panel

  import 'java.awt.Dimension'
  import 'java.awt.Font'
  import 'java.awt.FlowLayout'
  import 'java.awt.GridBagLayout'
  import 'java.awt.GridBagConstraints'
  import 'java.awt.GridLayout'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.BoxLayout'
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

  def add_form_row(label_text, component, options = {})
    add_row do |parent|
      container = JPanel.new
      container.setLayout(BoxLayout.new(container, BoxLayout::LINE_AXIS))
      parent.add(container)

      label = JLabel.new(label_text, JLabel::RIGHT)
      label.setBorder(BorderFactory.createEmptyBorder(0, 0, 0, 20))
      label.setToolTipText(options[:tool_tip]) if options[:tool_tip]
      label.setPreferredSize(Dimension.new(200, 0))
      container.add(label)

      component.setToolTipText(options[:tool_tip]) if options[:tool_tip]
      if options[:width]
        component_container = JPanel.new(GridBagLayout.new)
        component_container.add(component, GridBagConstraints.new.tap do |c|
          c.gridx = c.gridy = 0
          c.gridwidth = c.gridheight = 1
          c.weightx = c.weighty = 1.0
          c.fill = GridBagConstraints::VERTICAL
          c.anchor = GridBagConstraints::WEST
        end)
        component.setPreferredSize(Dimension.new(options[:width], component.getPreferredSize().height))
        container.add(component_container)
      else
        container.add(component)
      end
    end
  end

  def add_button_row(primary_button, secondary_button)
    container = JPanel.new
    container.setBorder(BorderFactory.createEmptyBorder(10, 0, 0, 0))
    container.setLayout(GridLayout.new(0, 1))
    root_panel.add(container)

    container.add(JSeparator.new)

    panel = JPanel.new
    panel.setLayout(FlowLayout.new(FlowLayout::CENTER, 0, 0))
    container.add(panel)

    buttons = [primary_button, secondary_button]
    buttons.reverse! if Coinmux.os == :macosx

    buttons.each do |button|
      panel.add(button)
    end
  end
  
end

