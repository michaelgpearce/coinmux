class Gui::View::Base
  attr_accessor :application, :root_panel, :primary_button

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

  # subclasses should not override, override handle_show instead
  def show
    root_panel.getRootPane().setDefaultButton(primary_button)

    handle_show
  end

  protected

  def handle_show
    # override in subclass
  end

  def add_header(text)
    label = JLabel.new(text, JLabel::CENTER)
    font = label.getFont()
    label.setFont(font.java_send(:deriveFont, [Java::float], font.size() * 1.5))
    header.add(label, build_grid_bag_constraints(fill: :horizontal, anchor: :center))
  end

  def add_row(&block)
    yield(body)
  end

  def add_button_row(primary_button, secondary_button = nil)
    container = JPanel.new
    container.setBorder(BorderFactory.createEmptyBorder(10, 0, 0, 0))
    container.setLayout(GridLayout.new(0, 1))
    footer.add(container, build_grid_bag_constraints(fill: :horizontal))

    container.add(JSeparator.new)

    panel = JPanel.new
    panel.setLayout(FlowLayout.new(FlowLayout::CENTER, 0, 0))
    container.add(panel)

    buttons = [primary_button, secondary_button].compact
    self.primary_button = buttons.first
    buttons.reverse! if Coinmux.os == :macosx

    buttons.each do |button|
      panel.add(button)
    end
  end

  def add_form_row(label_text, component, index, options = {})
    options = {
      last: false,
      width: nil,
      label_width: 160
    }.merge(options)

    add_row do |parent|
        # parent.add(panel, build_grid_bag_constraints(gridy: 1, fill: :both, anchor: :center, weighty: 1000000))
      container = JPanel.new
      container.setLayout(BoxLayout.new(container, BoxLayout::LINE_AXIS))
      parent.add(container, build_grid_bag_constraints(
        fill: options[:last] ? :horizontal : :horizontal,
        weighty: options[:last] ? 1000000 : 0,
        anchor: :north,
        insets: Insets.new(0, 0, 10, 0),
        gridy: index))

      label = JLabel.new(label_text, JLabel::RIGHT)
      label.setBorder(BorderFactory.createEmptyBorder(0, 0, 0, 20))
      label.setToolTipText(options[:tool_tip]) if options[:tool_tip]
      label.setPreferredSize(Dimension.new(options[:label_width], 0))
      container.add(label)

      if options[:width]
        component_container = JPanel.new(GridBagLayout.new)
        component_container.add(component, build_grid_bag_constraints(fill: :vertical, anchor: :west))
        component.setPreferredSize(Dimension.new(options[:width], component.getPreferredSize().height))
        container.add(component_container)
      else
        container.add(component)
      end
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

