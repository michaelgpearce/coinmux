class Gui::View::Mixing < Gui::View::Base
  STATES = [:initializing, :waiting_for_other_inputs, :waiting_for_other_outputs, :waiting_for_completed, :completed]
  TERMINATE_TEXT = "Terminate"

  attr_accessor :director, :participant

  import 'java.awt.Component'
  import 'java.awt.Dimension'
  import 'java.awt.GridLayout'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.JButton'
  import 'javax.swing.JOptionPane'
  import 'javax.swing.JPanel'
  import 'javax.swing.JProgressBar'
  import 'javax.swing.JTextField'
  import 'javax.swing.UIManager'

  def add
    add_header("Mixing")

    add_row do |parent|
      container = JPanel.new(GridLayout.new(0, 1, 0, 10)).tap do |container|
        container.setBorder(BorderFactory.createEmptyBorder(0, 40, 0, 40))

        container.add(status_label)

        container.add(progress_bar)

        container.add(message_text_field)
      end

      parent.add(container, build_grid_bag_constraints(fill: :horizontal, anchor: :center))
    end

    add_button_row(action_button)
  end

  protected

  def handle_show
    reset_status
    action_button.setLabel(TERMINATE_TEXT)

    application.data_store.startup

    self.participant = build_participant
    participant.start(&notification_callback)
  end

  private

  def notification_callback
    @notification_callback ||= Proc.new do |event|
      debug "event queue event received: #{event.inspect}"
      if event.type == :failed
        self.director = self.participant = nil # end execution
      else
        if event.source == :participant
          handle_participant_event(event)
        elsif event.source == :director
          handle_director_event(event)
        else
          raise "Unknown event source: #{event.source}"
        end
      end

      if participant.nil? && director.nil?
        # we are done, so shut down the data store
        application.data_store.shutdown
      end
    end
  end

  def build_participant
    Coinmux::StateMachine::Participant.new(
      event_queue: Gui::EventQueue.instance,
      data_store: application.data_store,
      amount: application.amount,
      participants: application.participants,
      input_private_key: application.input_private_key,
      output_address: application.output_address,
      change_address: application.change_address)
  end

  def build_director
    Coinmux::StateMachine::Director.new(
      event_queue: Gui::EventQueue.instance,
      data_store: application.data_store,
      amount: application.amount,
      participants: application.participants)
  end

  def handle_participant_event(event)
    update_status(event.type, event.message) if STATES.include?(event.type)

    if [:no_available_coin_join].include?(event.type)
      if director.nil?
        # start our own Director since we couldn't find one
        self.director = build_director
        director.start(&notification_callback)
      end
    elsif [:input_not_selected, :transaction_not_found].include?(event.type)
      # TODO: try again
    elsif event.type == :completed
      self.participant = nil # done
      handle_success
    elsif event.type == :failed
      self.participant = nil # done
      handle_failure
    end
  end

  def handle_success
    progress_bar.setValue(progress_bar.getMaximum())
    action_button.setLabel("Done")
  end

  def handle_failure
    progress_bar.setValue(progress_bar.getMaximum())
    # TODO: clean_up_coin_join
  end

  def handle_director_event(event)
    if event.type == :waiting_for_inputs
      # our Director is now ready, so let's get started with a new participant
      self.participant = build_participant
      participant.start(&notification_callback)
    elsif event.type == :failed || event.type == :completed
      self.director = nil # done
    end
  end

  def reset_status
    update_status(:initializing)
  end

  def update_status(state, message = nil)
    index = STATES.index(state)

    progress_bar.setValue(index)
    status_label.setText(state.to_s.capitalize.gsub(/_/, ' '))
    message_text_field.setText(message.to_s)
  end

  def status_label
    @status_label ||= JLabel.new("", JLabel::CENTER).tap do |label|
      font = label.getFont()
      label.setFont(font.java_send(:deriveFont, [Java::float], font.size() * 1.6))
    end
  end

  def message_text_field
    @message_text_field ||= JTextField.new.tap do |text_field|
      text_field.setHorizontalAlignment(JTextField::CENTER)
      text_field.setEditable(false)
      text_field.setBorder(nil)
      text_field.setBackground(UIManager.getColor("Label.background"))
      text_field.setForeground(UIManager.getColor("Label.foreground"))
      text_field.setFont(UIManager.getFont("Label.font"))
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
      action_button.add_action_listener do |e|
        if action_button.getLabel() == TERMINATE_TEXT
          result = JOptionPane.showConfirmDialog(application.root_panel, "Are you sure you want to terminate this mix?", "Coinmux", JOptionPane::YES_NO_OPTION, JOptionPane::WARNING_MESSAGE)
          if result == JOptionPane::YES_OPTION
            application.show_view(:available_mixes)
          end
        end
      end
    end
  end

end

