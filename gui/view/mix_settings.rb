class Gui::View::MixSettings < Gui::View::Base
  include Coinmux::BitcoinUtil

  DEFAULT_PARTICIPANTS = 5
  DEFAULT_AMOUNT = 1.0 * SATOSHIS_PER_BITCOIN
  MAX_PARTICIPANTS = 100

  import 'java.awt.Component'
  import 'java.awt.Dimension'
  import 'java.awt.Insets'
  import 'javax.swing.JButton'
  import 'javax.swing.JLabel'
  import 'javax.swing.JOptionPane'
  import 'javax.swing.JPanel'
  import 'javax.swing.JPasswordField'
  import 'javax.swing.JSpinner'
  import 'javax.swing.JTextField'
  import 'javax.swing.SpinnerModel'
  import 'javax.swing.SpinnerNumberModel'
  import 'javax.swing.SwingWorker'

  def add
    add_header("Mix Settings")

    add_form_row("Bitcoin Amount (BTC)", amount, 0, width: 100, tool_tip: "Bitcoin amount mixed with other participants and sent to the output address")

    add_form_row("Number of Participants", participants, 1, width: 100, tool_tip: "More participants adds security, but will take more time to complete")

    add_form_row("Input Private Key", input_private_key, 2, tool_tip: "See your wallet software's documentation for exporting private keys")

    add_form_row("Output Address", output_address, 3, tool_tip: "Mixed bitcoin amount will be sent to this address")

    add_form_row("Change Address", change_address, 4, tool_tip: "Un-mixed funds in your wallet sent to this address", last: true)

    add_button_row(start_button, cancel_button)
  end

  def show
    bitcoin_amount = (application.amount || DEFAULT_AMOUNT).to_f / SATOSHIS_PER_BITCOIN
    amount.setText(bitcoin_amount.to_s)
    amount.setEnabled(application.amount.nil?)
    participants.setValue(application.participants || DEFAULT_PARTICIPANTS)
    participants.setEnabled(application.participants.nil?)
    input_private_key.setText("")
  end

  private

  class ValidationWorker < SwingWorker
    include Coinmux::BitcoinUtil

    attr_accessor :mix_settings, :input_errors

    def initialize(mix_settings)
      super()

      self.mix_settings = mix_settings
    end

    def doInBackground
      input_validator = Coinmux::Application::InputValidator.new(
        data_store: mix_settings.application.data_store,
        input_private_key: mix_settings.send(:input_private_key).getText(),
        amount: (mix_settings.send(:amount).getText().to_f * SATOSHIS_PER_BITCOIN).to_i,
        participants: mix_settings.send(:participants).getValue(),
        change_address: mix_settings.send(:change_address).getText(),
        output_address: mix_settings.send(:output_address).getText())

      self.input_errors = input_validator.validate
    end

    def done
      mix_settings.send(:start_button).setEnabled(true)
      mix_settings.send(:start_button).setLabel("Start Mixing")

      if input_errors.present?
        JOptionPane.showMessageDialog(
          mix_settings.application,
          input_errors.collect(&:to_s).to_java(:string),
          "Input Errors",
          JOptionPane::ERROR_MESSAGE)
      else
        mix_settings.application.show_view(:mixing)
      end
    end
  end

  def change_address
    @change_address ||= JTextField.new
  end

  def output_address
    @output_address ||= JTextField.new
  end

  def input_private_key
    @input_private_key ||= JPasswordField.new
  end

  def start_button
    @start_button ||= JButton.new("Start Mixing").tap do |start_button|
      start_button.add_action_listener do |e|
        start_button.setEnabled(false)
        start_button.setLabel("Validating...")
        ValidationWorker.new(self).execute()
      end
    end
  end

  def cancel_button
    @cancel_button ||= JButton.new("Back").tap do |cancel_button|
      cancel_button.add_action_listener do |e|
        application.show_view(:available_mixes)
      end
    end
  end

  def amount
    @amount ||= JTextField.new
  end

  def participants
    @participants ||= JSpinner.new(build_spinner_model).tap do |participants|
      if participants.getEditor().respond_to?(:getTextField)
        participants.getEditor().getTextField().setHorizontalAlignment(JTextField::LEFT)
      end
      participants.setValue(DEFAULT_PARTICIPANTS)
    end
  end

  def build_spinner_model
    spinner_model_constructor = SpinnerNumberModel.java_class.constructor(Java::int, Java::int, Java::int, Java::int)
    spinner_model_constructor.new_instance(DEFAULT_PARTICIPANTS, 2, MAX_PARTICIPANTS, 1)
  end
end

