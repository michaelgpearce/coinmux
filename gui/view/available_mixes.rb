class Gui::View::AvailableMixes < Gui::View::Base
  include Coinmux::BitcoinUtil
  
  import 'java.awt.Dimension'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.ListSelectionModel'
  import 'javax.swing.JButton'
  import 'javax.swing.JTextArea'
  import 'javax.swing.JScrollPane'
  import 'javax.swing.JTable'
  import 'javax.swing.border.TitledBorder'
  import 'javax.swing.table.AbstractTableModel'
  import 'javax.swing.table.TableModel'

  def add
    add_header("Mix Your Bitcoins")

    add_row do |parent|
      label = JTextArea.new(<<-STRING)
Coinmux is the safe way to mix your bitcoins.
Your bitcoins are mixed with other Coinmux users on the Internet, but your private Bitcoin information never leaves your computer. You are always 100% in control of your bitcoins and you never need to trust a 3rd party - just like Bitcoin.
      STRING
      label.setEditable(false)
      label.setLineWrap(true)
      label.setWrapStyleWord(true)
      label.setBackground(parent.getBackground())
      parent.add(label, build_grid_bag_constraints(gridy: 0, fill: :horizontal, anchor: :north))
    end

    add_row do |parent|
      JPanel.new(Java::JavaAwt::GridLayout.new(1, 1)).tap do |panel|
        scroll_pane = JScrollPane.new(mixes_table)
        panel.setBorder(BorderFactory.createTitledBorder(
          BorderFactory.createEmptyBorder(), "Available Bitcoin Mixes", TitledBorder::LEFT, TitledBorder::TOP))

        panel.add(scroll_pane)
        parent.add(panel, build_grid_bag_constraints(gridy: 1, fill: :both, anchor: :center, weighty: 1000000))
      end
    end

    add_button_row(join_button, create_button)
  end

  def show
  end

  private

  class TModel < Java::JavaxSwingTable::AbstractTableModel
    def getColumnName(index)
      case index
      when 0; "Bitcoin Amount (BTC)"
      when 1; "Participants"
      end
    end

    def getColumnCount(); 2; end
    def getRowCount(); 10; end
    def getValueAt(row, col); col == 0 ? row * 3.3 : "#{row * 2} of 20" end
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
        selected_index = mixes_table.getSelectionModel().getMinSelectionIndex()
        application.amount = (mixes_table.getModel().getValueAt(selected_index, 0).to_f * SATOSHIS_PER_BITCOIN).to_i
        application.participants = mixes_table.getModel().getValueAt(selected_index, 1).to_i
        application.show_view(:mix_settings)
      end
    end
  end

  def mixes_table
    @mixes_table ||= JTable.new(TModel.new).tap do |mixes_table|
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
    enabled = !mixes_table.getSelectionModel().isSelectionEmpty() && mixes_table.getModel().getRowCount() > 0
    join_button.setEnabled(enabled)
  end
end

