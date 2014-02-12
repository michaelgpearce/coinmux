class Gui::View::AvailableMixes < Gui::View::Base
  import 'java.awt.Dimension'
  import 'java.awt.GridLayout'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.ListSelectionModel'
  import 'javax.swing.JButton'
  import 'javax.swing.JTextArea'
  import 'javax.swing.JScrollPane'
  import 'javax.swing.JTable'
  import 'javax.swing.event.TableModelEvent'
  import 'javax.swing.border.TitledBorder'
  import 'javax.swing.table.AbstractTableModel'
  import 'javax.swing.table.TableModel'

  def add
    add_header("Mix Your Bitcoins")

    add_row do |parent|
      label = JTextArea.new(<<-STRING)
Coinmux is the safe way to mix your bitcoins.
Your bitcoins are mixed with other Coinmux users on the Internet, but your private Bitcoin information never leaves your computer. You are always 100% in control of your bitcoins and you never need to trust a 3rd party.
      STRING
      label.setEditable(false)
      label.setLineWrap(true)
      label.setWrapStyleWord(true)
      label.setBackground(parent.getBackground())
      parent.add(label, build_grid_bag_constraints(gridy: 0, fill: :horizontal, anchor: :north))
    end

    add_row do |parent|
      JPanel.new(GridLayout.new(1, 1)).tap do |panel|
        scroll_pane = JScrollPane.new(mixes_table)
        panel.setBorder(BorderFactory.createTitledBorder(
          BorderFactory.createEmptyBorder(), "Available Bitcoin Mixes", TitledBorder::LEFT, TitledBorder::TOP))

        panel.add(scroll_pane)
        parent.add(panel, build_grid_bag_constraints(gridy: 1, fill: :both, anchor: :center, weighty: 1000000))
      end
    end

    add_button_row(join_button, create_button)
  end

  def update_mixes_table(mixes_data)
    mixes_table.setMixesData(mixes_data)
  end

  private

  class MixesTable < JTable
    include Coinmux::BitcoinUtil

    def initialize
      super(TModel.new)
      getModel().setData([["Loading...", ""]])
    end

    def setMixesData(mixes_data)
      data = if mixes_data.blank?
        [["Nothing available", ""]]
      else
        mixes_data.collect do |mix_data|
          [mix_data[:amount].to_f / SATOSHIS_PER_BITCOIN, "#{mix_data[:waiting_participants]} of #{mix_data[:total_participants]}"]
        end
      end

      getModel().setData(data)
    end

    def hasMixes()
      # we sometimes put some text in [0][0], not the bitcoin amount
      getModel().getData()[0][0].to_f != 0
    end

    def tableChanged(event)
      return super(event) unless hasMixes() && (selected_index = getSelectedIndex()) >= 0

      previous_amount = getAmountFromData(selected_index, event.getPreviousData())
      previous_participants = getParticipantsFromData(selected_index, event.getPreviousData())

      super(event)

      selectAmountAndParticipants(previous_amount, previous_participants)
    end

    def getSelectedIndex()
      getSelectionModel().getMinSelectionIndex()
    end

    def getAmount(row_index)
      getAmountFromData(row_index)
    end

    def getParticipants(row_index)
      getParticipantsFromData(row_index)
    end

    private

    def getAmountFromData(row_index, data = getModel().getData())
      (data[row_index][0].to_f * SATOSHIS_PER_BITCOIN).to_i
    end

    def getParticipantsFromData(row_index, data = getModel().getData())
      data[row_index][1].gsub(/.* /, '').to_i
    end

    def selectAmountAndParticipants(amount, participants)
      getModel().getRowCount().times do |row_index|
        if amount == getAmount(row_index) && participants == getParticipants(row_index)
          setRowSelectionInterval(row_index, row_index)
          break
        end
      end
    end
  end

  class TModelEvent < TableModelEvent
    def initialize(source, previous_data, current_data)
      super(source)

      @previous_data = previous_data
      @current_data = current_data
    end

    def getPreviousData(); @previous_data; end
    def getCurrentData(); @current_data; end
  end

  class TModel < AbstractTableModel
    def getData()
      data
    end

    def setData(data)
      self.data = data
    end

    def getColumnCount(); 2; end
    def getRowCount(); data.size; end

    def getColumnName(index)
      ["Bitcoin Amount (BTC)", "Participants"][index]
    end

    def getValueAt(row, col)
      data[row].try(:[], col)
    end

    def setValueAt(value, row, col)
      if value.nil? && row >= data.size
        self.data = data[0...row]
      else
        data[row] ||= []
        data[row][col] = value
      end
    end

    private

    def data
      @data ||= []
    end

    def data=(data)
      previous_data = @data
      @data = data

      if previous_data != data
        fireTableChanged(TModelEvent.new(self, previous_data, data))
      end
    end
  end

  def join_button
    @join_button ||= JButton.new("Join Available Mix").tap do |join_button|
      join_button.add_action_listener do |e|
        application.show_view(:mix_settings)
      end
    end
  end

  def create_button
    @create_button ||= JButton.new("Create New Mix").tap do |create_button|
      create_button.add_action_listener do |e|
        application.amount = nil
        application.participants = nil
        application.show_view(:mix_settings)
      end
    end
  end

  def join_button
    @join_button ||= JButton.new("Join Available Mix").tap do |join_button|
      join_button.setEnabled(false)
      join_button.add_action_listener do |e|
        selected_index = mixes_table.getSelectedIndex()
        application.amount = mixes_table.getAmount(selected_index)
        application.participants = mixes_table.getParticipants(selected_index)
        application.show_view(:mix_settings)
      end
    end
  end

  def mixes_table
    @mixes_table ||= MixesTable.new.tap do |mixes_table|
      mixes_table.setSelectionMode(ListSelectionModel::SINGLE_SELECTION)
      mixes_table.getSelectionModel().addListSelectionListener do |e|
        update_join_enabled
      end

      mixes_table.getModel().addTableModelListener do |e|
        update_join_enabled
      end
    end
  end

  def update_join_enabled
    enabled = !mixes_table.getSelectionModel().isSelectionEmpty() && mixes_table.hasMixes()
    join_button.setEnabled(enabled)
  end
end

