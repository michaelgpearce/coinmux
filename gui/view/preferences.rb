class Gui::View::Preferences < Gui::View::Base
  NETWORK_CONFIG_KEYS = %w(mainnet testnet)
  NETWORK_CONFIG_KEYS.reverse! if Coinmux.env == 'development' # first element will be default

  DATA_STORE_NAME_MAP = {
    'P2P' => 'p2p',
    'Filesystem' => 'filesystem'
  } # first element will be default

  NETWORK_NAME_MAP = NETWORK_CONFIG_KEYS.each_with_object({}) do |network_key, map|
    map[Coinmux::Config[network_key].name] = network_key
  end

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

  def coin_join_uri
    Coinmux::CoinJoinUri.new(network: selected_data_store_key, params: selected_table_model_params)
  end

  def bitcoin_network
    selected_network_key
  end

  def add
    add_header("Preferences")

    add_form_row("Bitcoin Network", network_combo_box, 0, label_width: 140, tool_tip: "Mainnet is the standard Bitcoin network")

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

  protected

  def handle_show
    self.success = false
    save_button.setEnabled(application.current_view == :available_mixes)
  end

  private

  def close_preferences(success)
    self.success = success
    SwingUtilities.getWindowAncestor(root_panel).dispose
  end

  def network_combo_box
    @network_combo_box ||= JComboBox.new(NETWORK_NAME_MAP.keys.to_java(:string)).tap do |combo_box|
      combo_box.setVisible(Coinmux.env != 'production')
      combo_box.addActionListener() do |e|
        data_store_properties_table.setModel(selected_table_model)
      end
    end
  end

  def data_store_combo_box
    @data_store_combo_box ||= JComboBox.new(DATA_STORE_NAME_MAP.keys.to_java(:string)).tap do |combo_box|
      combo_box.addActionListener() do |e|
        data_store_properties_table.setModel(selected_table_model)
      end
    end
  end

  def data_store_properties_table
    @data_store_properties_table ||= JTable.new(selected_table_model)
  end

  def data_store_properties_model
    model = data_store_properties_table.getModel()
    model.getRowCount().times.each_with_object({}) do |row, params|
      value = model.getValueAt(row, 1)
      params[model.getValueAt(row, 0)] = value if value.present?
    end
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

  def table_models
    @table_models ||= NETWORK_CONFIG_KEYS.each_with_object({}) do |network_key, network_key_map|
      network_key_map[network_key] = DATA_STORE_NAME_MAP.values.each_with_object({}) do |data_store_key, data_store_key_map|
        coin_join_params = Coinmux::CoinJoinUri.parse(Coinmux::Config[network_key].coin_join_uris[data_store_key]).params
        data_store_key_map[data_store_key] = TModel.new(coin_join_params)
      end
    end
  end

  def selected_network_key
    NETWORK_NAME_MAP[network_combo_box.getSelectedItem().to_s]
  end

  def selected_data_store_key
    DATA_STORE_NAME_MAP[data_store_combo_box.getSelectedItem().to_s]
  end

  def selected_table_model
    table_model(selected_network_key, selected_data_store_key)
  end

  def selected_table_model_params
    selected_table_model.data.each_with_object({}) do |row, result|
      result[row[0].strip] = row[1].strip if row[0].try(:strip).present?
    end
  end

  def table_model(network_key, data_store_key)
    table_models[network_key][data_store_key]
  end

  class TModel < AbstractTableModel
    COLS = 2
    ROWS = 5

    attr_accessor :data

    def initialize(coin_join_params)
      super()

      self.data = Array.new(ROWS) { Array.new(COLS) }

      coin_join_params.each_with_index do |(key, value), index|
        data[index][0] = key
        data[index][1] = value
      end
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