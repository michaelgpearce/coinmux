# require 'swt'
# require 'glimmer'
# 
# class GlimmerExample
#   include Glimmer
# 
#   include_package 'org.eclipse.swt'
#   include_package 'org.eclipse.swt.widgets'
#   include_package 'org.eclipse.swt.layout'
#   include_package 'org.eclipse.jface.viewers'
#   
#   class Data
#     attr_accessor :first_name, :last_name, :email
#   end
#   
#   def results
#     @results ||= 3.times.collect { Data.new.tap {|d| d.first_name = 'a'; d.last_name ='b'; d.email = 'c'} }
#   end
#   
#   def data
#     @data ||= Data.new.tap {|d| d.first_name = 'a'; d.last_name ='b'; d.email = 'c'}
#   end
#   
#   def initialize
#     @shell = shell {
#       text "Coin2Coin - Mix your bitcoins"
#       @tab_folder = tab_folder {
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
#   
#   def home_tab_item
#     label {
#       text "CoinJoins allow you to anonimize your Bitcoins by combining them with other users on the Bitcoin network."
#       text "To do this, this application needs access to your private keys. This information is never sent over the Internet and is never even stored to disk."
#     }
#     text {
#       text bind(contact_manager_presenter, :first_name)
#     }
#     
#     button {
#       text "Create CoinJoin"
#     }
#   end
#   
#   def coinjoins_tab_item
#     composite {
#       composite {
#         layout GridLayout.new(2, false)
#         label {text "First &Name: "}
#         text {
#           text bind(data, :first_name)
#         }
#         label {text "&Last Name: "}
#         text {
#           text bind(data, :last_name)
#         }
#         label {text "&Email: "}
#         text {
#           text bind(data, :email)
#         }
#       }
#     
#       table {
#         layout_data GridData.new(:fill.swt_constant, :fill.swt_constant, true, true)
#         table_column {
#           text "First Name"
#           width 80
#         }
#         table_column {
#           text "Last Name"
#           width 80
#         }
#         table_column {
#           text "Email"
#           width 120
#         }
#         items bind(self, :results), column_properties(:first_name, :last_name, :email)
#       }
#     }
#   end
#   
#   def start
#     @shell.open
#   end
# end
