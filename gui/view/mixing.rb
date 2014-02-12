class Gui::View::Mixing < Gui::View::Base
  import 'java.awt.Component'
  import 'java.awt.Dimension'
  import 'java.awt.GridLayout'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.JOptionPane'
  import 'javax.swing.JPanel'
  import 'javax.swing.JProgressBar'
  import 'javax.swing.JButton'

  def add
    add_header("Mixing")

    add_row do |parent|
      container = JPanel.new(GridLayout.new(0, 1, 0, 10)).tap do |container|
        container.setBorder(BorderFactory.createEmptyBorder(0, 40, 0, 40))

        label = JLabel.new("Status: Waiting for Inputs", JLabel::CENTER)
        font = label.getFont()
        label.setFont(font.java_send(:deriveFont, [Java::float], font.size() * 1.6))
        container.add(label)

        progress_bar = JProgressBar.new
        progress_bar.setIndeterminate(true)
        container.add(progress_bar)
      end

      parent.add(container, build_grid_bag_constraints(fill: :horizontal, anchor: :center))
    end

    add_button_row(action_button)
  end

  private

  def action_button
    @action_button ||= JButton.new("Terminate").tap do |action_button|
      action_button.add_action_listener do |e|
        if action_button.getLabel() == "Terminate"
          result = JOptionPane.showConfirmDialog(application.root_panel, "Are you sure you want to terminate this mix?", "Coinmux", JOptionPane::YES_NO_OPTION, JOptionPane::WARNING_MESSAGE)
          if result == JOptionPane::YES_OPTION
            application.show_view(:available_mixes)
          end
        end
      end
    end
  end

end

