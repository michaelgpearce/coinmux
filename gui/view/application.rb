class Gui::View::Application < Java::JavaxSwing::JFrame
  
  import 'java.lang.System'
  import 'java.awt.Component'
  import 'java.awt.Dimension'
  import 'java.awt.FlowLayout'
  import 'java.awt.GridLayout'
  import 'java.awt.Font'
  import 'javax.swing.BorderFactory'
  import 'javax.swing.BoxLayout'
  import 'javax.swing.JButton'
  import 'javax.swing.JFrame'
  import 'javax.swing.JLabel'
  import 'javax.swing.JTextArea'
  import 'javax.swing.JPanel'
  import 'javax.swing.JProgressBar'
  import 'javax.swing.JScrollPane'
  import 'javax.swing.JSeparator'
  import 'javax.swing.JSpinner'
  import 'javax.swing.JTable'
  import 'javax.swing.SpinnerModel'
  import 'javax.swing.SpinnerNumberModel'
  import 'javax.swing.border.TitledBorder'
  import 'javax.swing.table.TableModel'
  import 'javax.swing.table.AbstractTableModel'


  def initialize
    super Coinmux::BANNER
  end

  def start
    show_frame do
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
          System.exit(0)
        end
        parent.add(join_button)

        create_button = JButton.new("Create New Mix")
        create_button.add_action_listener do |e|
          System.exit(0)
        end
        parent.add(create_button)
      end
    end
  end

      # add_row(border: component_border) do |panel|
      #   progress_bar = JProgressBar.new
      #   progress_bar.setAlignmentX(Component::CENTER_ALIGNMENT)
      #   progress_bar.setMaximumSize(Dimension.new(400, 20))
      #   progress_bar.setIndeterminate(true)
      #   panel.add(progress_bar)
      # end

      # add_row(border: component_border) do |panel|
      #   spinner = JSpinner.new(build_spinner_model)
      #   spinner.setMaximumSize(Dimension.new(400, 20))
      #   spinner.setAlignmentX(Component::CENTER_ALIGNMENT)
      #   panel.add(spinner)
      # end

  def build_spinner_model
    spinner_model_constructor = SpinnerNumberModel.java_class.constructor(Java::int, Java::int, Java::int, Java::int)
    spinner_model_constructor.new_instance(2, 2, 100, 1)
  end

  def root_panel
    @root_panel ||= JPanel.new.tap do |root_panel|
      root_panel.setLayout(BoxLayout.new(root_panel, BoxLayout::PAGE_AXIS))
      root_panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20))
    end
  end

  def show_frame(&block)
    getContentPane.add(root_panel)

    yield

    setDefaultCloseOperation JFrame::EXIT_ON_CLOSE
    setSize(Dimension.new(600, 400))
    setResizable(false)
    setLocationRelativeTo(nil)
    setVisible(true)
  end

  def add_row(options = {}, &block)
    panel = JPanel.new
    panel.setBorder(options[:border] || BorderFactory.createEmptyBorder(0, 0, 10, 0))
    panel.setLayout(GridLayout.new(0, 1))
    if options[:label]
      panel.setBorder(BorderFactory.createTitledBorder(
        BorderFactory.createEmptyBorder(), options[:label], TitledBorder::LEFT, TitledBorder::TOP))
    end
    root_panel.add(panel)

    yield(panel)
  end

  def add_button_row(&block)
    container = JPanel.new
    container.setBorder(BorderFactory.createEmptyBorder(10, 0, 0, 0))
    container.setLayout(GridLayout.new(0, 1))
    root_panel.add(container)

    container.add(JSeparator.new)

    panel = JPanel.new
    panel.setLayout(FlowLayout.new(FlowLayout::CENTER, 0, 0))
    container.add(panel)

    yield(panel)
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
# class Gui::View::Application
#   include Glimmer, Singleton
  
#   include_package 'org.eclipse.swt'
#   include_package 'org.eclipse.swt.widgets'
#   include_package 'org.eclipse.swt.layout'
#   include_package 'org.eclipse.jface.viewers'
  
#   def sync_exec(&block)
#     @shell.display.sync_exec(&block)
#   end
  
#   def future_exec(seconds = 0, &block)
#     if seconds == 0
#       @shell.display.async_exec(&async_block)
#     else
#       Thread.new do
#         sleep(seconds)
#         @shell.display.sync_exec(&block)
#       end
#     end
#   end
  
#   def interval_exec(seconds, &block)
#     interval_id = rand.to_s
#     @intervals << interval_id
    
#     Thread.new do
#       while @intervals.include?(interval_id)
#         sleep(seconds)
#         if @intervals.include?(interval_id)
#           @shell.display.sync_exec do
#             block.call(interval_id)
#           end
#         end
#       end
#     end
    
#     interval_id
#   end
  
#   def clear_interval(interval_id)
#     @intervals.delete(interval_id)
#   end
  
#   def initialize
#     @intervals = Set.new
    
#     @shell = shell {
#       text Coinmux::BANNER
      
#       tab_folder {
#         tab_item {
#           text "Home"
#           home_tab_item
#         }
#         tab_item {
#           text "CoinJoins"
#           coinjoins_tab_item
#         }
#       }
#     }
#   end
  
#   def current_coin_join
#     @current_coin_join ||= Gui::Model::CoinJoin.new
#   end
  
#   def home_tab_item
#     composite {
#       label {
#         text "CoinJoins allow you to anonimize your Bitcoins by\ncombining them with other users on the Bitcoin network."
#       }
#       label {
#         text "To do this, this application needs access to your\nprivate keys. This information is never sent over the\nInternet and is never stored to disk."
#       }
#     }
#     composite {
#       layout GridLayout.new(2, false)
#       label {
#         text "Add Bitcoin Inputs"
#       }
#     }
#     coin_join_transaction
#   end
  
#   def new_input
#     @new_input ||= Gui::Model::Input.new
#   end
  
#   def coin_join_transaction
#     group {
#       text "CoinJoin Transaction"
#       layout_data build_fill_grid_data
      
#       group {
#         text "New Inputs"
#         layout_data build_fill_grid_data
#         composite {
#           layout_data build_fill_grid_data
#           layout GridLayout.new(3, false)
#           label { text "Private Key" }
#           text {
#             layout_data build_fill_grid_data
#             text bind(new_input, :private_key)
#           }
#           button {
#             text "Add"
#             on_widget_selected {
#               input = Gui::Model::Input.find_by_private_key(new_input.private_key)
#               if input.valid?
#                 current_coin_join.inputs << input
                
#                 new_input.bitcoin_address = nil
#                 new_input.private_key = nil
#                 new_input.public_key = nil
#               else
#                 raise "TODO"
#               end
#             }
#           }
#         }
#       }
#       composite {
#         table {
#           grid_data = GridData.new(:fill.swt_constant, :fill.swt_constant, true, true)
#           grid_data.heightHint = 100
#           layout_data grid_data
#           table_column {
#             text "Bitcoin Address"
#             width 360
#           }
#           table_column {
#             text "Amount"
#             width 80
#           }
#           items bind(current_coin_join, :inputs), column_properties(:bitcoin_address, :amount)
#         }
#       }
#     }
#     button {
#       text "Create CoinJoin (Needs to be big and have image)"
#       enabled bind(current_coin_join, :valid)
#     }
#   end
  
#   def coinjoins_tab_item
#   end
  
#   def start
#     @shell.widget.open
#     until @shell.widget.isDisposed
#       @shell.display.sleep unless @shell.display.readAndDispatch
#     end
#     @shell.display.dispose
#     @shell = nil
#   end
  
#   private
  
#   def build_fill_grid_data
#     grid_data = GridData.new
#     grid_data.horizontalAlignment = SWT::FILL
#     grid_data.grabExcessHorizontalSpace = true
    
#     grid_data
#   end
  
# end
