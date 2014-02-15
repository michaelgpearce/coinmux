class Gui::View::Mixing < Gui::View::Base
  STATES = [:initializing, :waiting_for_other_inputs, :waiting_for_other_outputs, :waiting_for_completed, :completed]
  TERMINATE_TEXT = "Terminate"

  attr_accessor :director, :participant, :transaction_url

  import 'java.awt.Color'
  import 'java.awt.Component'
  import 'java.awt.Cursor'
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

        JPanel.new.tap do |panel|
          panel.add(show_transaction_button)
          container.add(panel)
        end
      end

      parent.add(container, build_grid_bag_constraints(fill: :horizontal, anchor: :center))
    end

    add_button_row(action_button)
  end

  protected

  def handle_show
    transaction_url = nil
    show_transaction_button.setVisible(false)
    reset_status
    action_button.setLabel(TERMINATE_TEXT)

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
    Gui::EventQueue.instance.sync_exec do
      do_handle_participant_event(event)
    end
  end

  def do_handle_participant_event(event)
    update_status(event.type, event.options) if STATES.include?(event.type)

    if [:no_available_coin_join].include?(event.type)
      if director.nil?
        # start our own Director since we couldn't find one
        self.director = build_director
        director.start(&notification_callback)
      end
    elsif [:input_not_selected, :transaction_not_found].include?(event.type)
      # TODO: try again
    elsif event.type == :completed
      handle_success(event.options[:transaction_id])
      self.participant = nil # done
    elsif event.type == :failed
      handle_failure
      self.participant = nil # done
    end
  end

  def handle_success(transaction_id)
    progress_bar.setValue(progress_bar.getMaximum())
    action_button.setLabel("Done")
    self.transaction_url = Coinmux::Config.instance.show_transaction_url % transaction_id
    show_transaction_button.setVisible(true)
  end

  def handle_failure
    progress_bar.setValue(progress_bar.getMaximum())
    # TODO: clean_up_coin_join
  end

  def handle_director_event(event)
    Gui::EventQueue.instance.sync_exec do
      do_handle_director_event(event)
    end
  end

  def do_handle_director_event(event)
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
    @show_transaction_button ||= JButton.new.tap do |button|
      button.setBorderPainted(false)
      button.setText("View transaction")
      button.setCursor(Cursor.getPredefinedCursor(Cursor::HAND_CURSOR))
      button.setBackground(UIManager.getColor("Label.background"))
      button.setForeground(Color.blue)
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
            application.show_view(:available_mixes)
            # TODO: clean_up_coin_join
          end
        else
          application.show_view(:available_mixes)
        end
      end
    end
  end

end

