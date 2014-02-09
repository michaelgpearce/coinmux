class Gui::View::Base
  attr_accessor :application, :root_panel

  import 'java.awt.Dimension'
  import 'java.awt.Font'
  import 'java.awt.FlowLayout'
  import 'java.awt.GridBagLayout'
  import 'java.awt.GridBagConstraints'
  import 'java.awt.GridLayout'
  import 'java.awt.Insets'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.BoxLayout'
  import 'javax.swing.JLabel'
  import 'javax.swing.JPanel'
  import 'javax.swing.JSeparator'

  def initialize(application, root_panel)
    @application = application
    @root_panel = root_panel

    root_panel.add(container)
  end

  protected

  def add_header(text)
    label = JLabel.new(text, JLabel::CENTER)
    font = label.getFont()
    label.setFont(font.java_send(:deriveFont, [Java::float], font.size() * 1.5))
    header.add(label, build_grid_bag_constraints(fill: :horizontal, anchor: :center))
  end

  def add_row(&block)
    yield(body)
  end

  def add_button_row(primary_button, secondary_button)
    container = JPanel.new
    container.setBorder(BorderFactory.createEmptyBorder(10, 0, 0, 0))
    container.setLayout(GridLayout.new(0, 1))
    footer.add(container, build_grid_bag_constraints(fill: :horizontal))

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

  def build_grid_bag_constraints(attributes)
    attributes = {
      gridx: 0,
      gridy: 0,
      gridwidth: 1,
      gridheight: 1,
      ipadx: 0,
      ipady: 0,
      weightx: 1.0,
      weighty: 1.0,
      fill: :both,
      anchor: :center
    }.merge(attributes)

    GridBagConstraints.new.tap do |c|
      attributes.each do |key, value|
        c.send("#{key}=", value.is_a?(Symbol) ? GridBagConstraints.const_get(value.to_s.upcase) : value)
      end
    end
  end

  private

  def container
    @container ||= JPanel.new(GridBagLayout.new)
  end

  def header
    @header ||= JPanel.new(GridBagLayout.new).tap do |header|
      container.add(header, build_grid_bag_constraints(
        gridy: 0,
        fill: :horizontal,
        insets: Insets.new(0, 0, 10, 0),
        anchor: :north))
    end
  end

  def body
    @body ||= JPanel.new(GridBagLayout.new).tap do |body|
      container.add(body, build_grid_bag_constraints(
        gridy: 1,
        weighty: 1000000, # take up all space with body
        fill: :both,
        anchor: :center))
    end
  end

  def footer
    @footer ||= JPanel.new(GridBagLayout.new).tap do |footer|
      container.add(footer, build_grid_bag_constraints(
        gridy: 2,
        fill: :horizontal,
        anchor: :south))
    end
  end
end

