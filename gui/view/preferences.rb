class Gui::View::Preferences < Gui::View::Base
  BITCOIN_NETWORKS = %w(Mainnet Testnet)
  DATA_STORES = %w(P2P Filesystem)

  attr_accessor :success

  import 'java.awt.Dimension'
  import 'java.awt.GridLayout'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.JButton'
  import 'javax.swing.JComboBox'
  import 'javax.swing.JScrollPane'
  import 'javax.swing.JTable'
  import 'javax.swing.SwingUtilities'
  import 'javax.swing.border.TitledBorder'
  import 'javax.swing.table.AbstractTableModel'
  import 'javax.swing.table.TableModel'

  def add
    add_header("Preferences")

    add_form_row("Bitcoin Network", bitcoin_network_combo_box, 0, label_width: 140, tool_tip: "Mainnet is the standard Bitcoin network")

    add_form_row("Data Store", data_store_combo_box, 1, label_width: 140, tool_tip: "P2P mixes your bitcoins other Coinmux users on the Internet")

    add_row do |parent|
      JPanel.new(GridLayout.new(1, 1)).tap do |panel|
        scroll_pane = JScrollPane.new(data_store_properties_table)
        scroll_pane.setPreferredSize(Dimension.new(200, 100))
        panel.setBorder(BorderFactory.createTitledBorder(
          BorderFactory.createEmptyBorder(), "Data Store Properties", TitledBorder::LEFT, TitledBorder::TOP))

        panel.add(scroll_pane)
        parent.add(panel, build_grid_bag_constraints(gridy: 2, fill: :both, anchor: :center, weighty: 1000000))
      end
    end

    add_button_row(save_button, cancel_button)
  end

  def show
    self.success = false
  end

  private

  def close_preferences(success)
    self.success = success
    SwingUtilities.getWindowAncestor(root_panel).dispose
  end

  def bitcoin_network_combo_box
    @bitcoin_network_combo_box ||= JComboBox.new(BITCOIN_NETWORKS.to_java(:string))
  end

  def data_store_combo_box
    @data_store_combo_box ||= JComboBox.new(DATA_STORES.to_java(:string))
  end

  def data_store_properties_table
    @data_store_properties_table ||= JTable.new(TModel.new)
  end

  def data_store_properties
    model = data_store_properties_table.getModel()
    model.getRowCount().times.each_with_object({}) do |row, params|
      value = model.getValueAt(row, 1)
      params[model.getValueAt(row, 0)] = value if value.present?
    end
  end

  def coin_join_uri
    Coinmux::CoinJoinUri.new(network: data_store_combo_box.getSelectedItem().downcase, params: data_store_properties)
  end

  def save_button
    @save_button ||= JButton.new("Save").tap do |save_button|
      save_button.addActionListener() do |e|
        close_preferences(true)
      end
    end
  end

  def cancel_button
    @cancel_button ||= JButton.new("Cancel").tap do |cancel_button|
      cancel_button.addActionListener() do |e|
        close_preferences(false)
      end
    end
  end

  class TModel < AbstractTableModel
    COLS = 2
    ROWS = 5

    attr_accessor :data

    def initialize
      self.data = Array.new(ROWS) { Array.new(COLS) }
    end

    def getColumnCount(); COLS; end
    def getRowCount(); data.size; end
    def isCellEditable(row, col); true; end
    def getColumnClass(col); Java::JavaLang::String; end
    def getColumnName(index); %w(Name Value)[index]; end

    def setValueAt(value, row, col); data[row][col] = value; end
    def getValueAt(row, col); data[row][col]; end
  end
end