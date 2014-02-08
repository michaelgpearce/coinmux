class Gui::View::AvailableMixes < Gui::View::Base
  import 'java.awt.Dimension'
  import 'java.awt.Font'
  import 'javax.swing.JButton'
  import 'javax.swing.JLabel'
  import 'javax.swing.JTextArea'
  import 'javax.swing.JScrollPane'
  import 'javax.swing.JTable'
  import 'javax.swing.table.TableModel'
  import 'javax.swing.table.AbstractTableModel'

  def add
    add_row do |parent|
      label = JLabel.new("Mix Your Bitcoins")
      font = label.getFont()
      label.setFont(font.java_send(:deriveFont, [Java::float], font.size() * 1.5))
      parent.add(label)
    end

    add_row do |parent|
      label = JTextArea.new(<<-STRING)
Coinmux is the safe way to mix your bitcoins.
Your coins are mixed with others on the Internet, but you never send any private information. You are always 100% in control of your coins and you never need to place your trust in a 3rd party - just like Bitcoin.
      STRING
      label.setEditable(false)
      label.setLineWrap(true)
      label.setWrapStyleWord(true)
      label.setBackground(parent.getBackground())
      parent.add(label)
    end

    add_row(label: "Available Bitcoin Mixes") do |parent|
      table = JTable.new(TModel.new)
      scrollpane = JScrollPane.new(table)
      scrollpane.setMaximumSize(Dimension.new(0, 150))
      parent.add(scrollpane)
    end

    add_button_row do |parent|
      join_button = JButton.new("Join Available Mix")
      join_button.add_action_listener do |e|
        application.show_view(:mix_settings)
      end
      parent.add(join_button)

      create_button = JButton.new("Create New Mix")
      create_button.add_action_listener do |e|
        application.show_view(:mixing)
      end
      parent.add(create_button)
    end
  end

  class TModel < Java::JavaxSwingTable::AbstractTableModel
    def getColumnName(index)
      case index
      when 0; "Bitcoin Amount (BTC)"
      when 1; "Participants"
      end
    end

    def getColumnCount(); 2; end
    def getRowCount(); 10; end
    def getValueAt(row, col); "foo #{row} - #{col}"; end
  end
end

