class Gui::View::Mixing < Gui::View::Base
  STATES = [:initializing, :waiting_for_other_inputs, :waiting_for_other_outputs, :waiting_for_completed, :completed]
  TERMINATE_TEXT = "Terminate"

  attr_accessor :director, :participant, :transaction_url, :mixer

  import 'java.awt.Component'
  import 'java.awt.Dimension'
  import 'java.awt.GridLayout'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.JButton'
  import 'javax.swing.JOptionPane'
  import 'javax.swing.JPanel'
  import 'javax.swing.JProgressBar'

  protected

  def handle_add
    add_header("Mixing")

    add_row do |parent|
      container = JPanel.new(GridLayout.new(0, 1, 0, 10)).tap do |container|
        container.setBorder(BorderFactory.createEmptyBorder(0, 40, 0, 40))

        container.add(status_label)

        container.add(progress_bar)

        JPanel.new.tap do |panel|
          panel.add(show_transaction_button)
          container.add(panel)
        end
      end

      parent.add(container, build_grid_bag_constraints(fill: :horizontal, anchor: :center))
    end

    add_button_row(action_button)
  end

  def handle_show
    transaction_url = nil
    show_transaction_button.setVisible(false)
    reset_status
    action_button.setLabel(TERMINATE_TEXT)

    (self.mixer = build_mixer).start do |event|
      if event.source == :participant && STATES.include?(event.type)
        Gui::EventQueue.instance.sync_exec do
          update_status(event.type, event.options)

          if event.type == :completed
            handle_success(event.options[:transaction_id])
          elsif event.type == :failed
            handle_failure
          end
        end
      end
    end
  end

  private

  def build_mixer
    Coinmux::Application::Mixer.new(
      event_queue: Gui::EventQueue.instance,
      data_store: application.data_store,
      amount: application.amount,
      participants: application.participants,
      input_private_key: application.input_private_key,
      output_address: application.output_address,
      change_address: application.change_address)
  end

  def handle_success(transaction_id)
    progress_bar.setValue(progress_bar.getMaximum())
    action_button.setLabel("Done")
    self.transaction_url = Coinmux::Config.instance.show_transaction_url % transaction_id
    show_transaction_button.setVisible(true)
  end

  def handle_failure
    progress_bar.setValue(progress_bar.getMaximum())
  end

  def reset_status
    update_status(:initializing)
  end

  def update_status(state, options = {})
    index = STATES.index(state)

    progress_bar.setValue(index)
    status_label.setText(state.to_s.capitalize.gsub(/_/, ' '))
  end

  def status_label
    @status_label ||= JLabel.new("", JLabel::CENTER).tap do |label|
      font = label.getFont()
      label.setFont(Font.new(font.getName(), Font::PLAIN, (font.getSize() * 1.6).to_i))
    end
  end

  def show_transaction_button
    @show_transaction_button ||= Gui::Component::LinkButton.new("View transaction").tap do |button|
      button.addActionListener do |e|
        application.open_webpage(transaction_url)
      end
    end
  end

  def progress_bar
    @progress_bar ||= JProgressBar.new.tap do |progress_bar|
      progress_bar.setMinimum(0)
      progress_bar.setMaximum(STATES.size - 1)
    end
  end

  def action_button
    @action_button ||= JButton.new(TERMINATE_TEXT).tap do |action_button|
      action_button.addActionListener() do |e|
        if action_button.getLabel() == TERMINATE_TEXT
          result = JOptionPane.showConfirmDialog(application.root_panel, "Are you sure you want to terminate this mix?", "Coinmux", JOptionPane::YES_NO_OPTION, JOptionPane::WARNING_MESSAGE)
          if result == JOptionPane::YES_OPTION
            mixer.cancel do
              application.show_view(:available_mixes)
            end
          end
        else
          application.show_view(:available_mixes)
        end
      end
    end
  end

end

