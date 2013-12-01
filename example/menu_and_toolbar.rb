# cribbed from www.java2s.com

require 'java'
require 'swt'
require 'rbconfig'

class MenuAndToolbarExample

  def initialize
    # see examples/button.rb for discussion of these steps
    @shell = Swt::Widgets::Shell.new
    @shell.text = "Menus and Toolbars Example"
    create_menu
    # create_toolbar
    @shell.set_size(600, 500)
    @shell.pack
    @shell.open
  end
  
  def foo
    display = Swt::Widgets::Display.get_current
    dialog_shell = Swt::Widgets::Shell.new(display, Swt::SWT::APPLICATION_MODAL)
    dialog_shell.open
    dialog_shell.set_size(600, 500)
    while !@shell.isDisposed
      display.sleep unless display.read_and_dispatch
    end
  end
  
  def create_menu
    toolbar = if RbConfig::CONFIG["host_os"] =~ /darwin/
      @shell.getToolBar
    else
      Swt::Widgets::ToolBar.new(@shell, Swt::SWT::FLAT | Swt::SWT::WRAP | Swt::SWT::RIGHT)
    end
    
    file_menu = Swt::Widgets::Menu.new(toolbar)
    itemDropDown = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::DROP_DOWN)
    
    #   itemDropDown.setText("DROP_DOWN")
    #   itemDropDown.setToolTipText("Click here to see a drop down menu ...")
    #   
    #   menu = Swt::Widgets::Menu.new(@shell, Swt::SWT::POP_UP)
    #   Swt::Widgets::MenuItem.new(menu, Swt::SWT::PUSH).setText("Menu item 1")
    # file_menu_item = Swt::Widgets::MenuItem.new(file_menu, Swt::SWT::CASCADE | Swt::SWT::DROP_DOWN)
    # file_menu_item.setMenu(file_menu)
    # file_menu_item.setText("File")
    
    puts "HERE", toolbar.get_item_count
    
    # s = Time.now
    # menu = Swt::Widgets::Menu.new(@shell, Swt::SWT::BAR)
    # 
    # fileItem = Swt::Widgets::MenuItem.new(menu, Swt::SWT::CASCADE)
    # fileItem.setText("File")
    # editItem = Swt::Widgets::MenuItem.new(menu, Swt::SWT::CASCADE)
    # editItem.setText("Edit")
    # viewItem = Swt::Widgets::MenuItem.new(menu, Swt::SWT::CASCADE)
    # viewItem.setText("View")
    # helpItem = Swt::Widgets::MenuItem.new(menu, Swt::SWT::CASCADE)
    # helpItem.setText("Help")
    # 
    # fileMenu = Swt::Widgets::Menu.new(menu)
    # fileItem.setMenu(fileMenu)
    # 
    # newItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::NONE)  
    # newItem.setText("New")  
    # openItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::NONE)  
    # openItem.setText("Open...")  
    # saveItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::NONE)  
    # saveItem.setText("Save")  
    # saveAsItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::NONE)  
    # saveAsItem.setText("Save As...")  
    # 
    # Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::SEPARATOR)  
    # 
    # pageSetupItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::NONE)  
    # pageSetupItem.setText("Page Setup...")  
    # printItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::NONE)  
    # printItem.setText("Print...")  
    # 
    # Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::SEPARATOR)  
    # 
    # exitItem = Swt::Widgets::MenuItem.new(fileMenu, Swt::SWT::NONE)  
    # exitItem.setText("Exit")  
    #   
    # editMenu = Swt::Widgets::Menu.new(menu)  
    # editItem.setMenu(editMenu)  
    # 
    # cutItem = Swt::Widgets::MenuItem.new(editMenu, Swt::SWT::NONE)  
    # cutItem.setText("Cut")  
    # pasteItem = Swt::Widgets::MenuItem.new(editMenu, Swt::SWT::NONE)  
    # pasteItem.setText("Paste")
    #   
    # viewMenu = Swt::Widgets::Menu.new(menu)
    # viewItem.setMenu(viewMenu)
    # 
    # toolItem = Swt::Widgets::MenuItem.new(viewMenu, Swt::SWT::NONE)  
    # toolItem.setText("ToolBars")
    # fontItem = Swt::Widgets::MenuItem.new(viewMenu, Swt::SWT::NONE)  
    # fontItem.setText("Font")
    # 
    # puts "took #{Time.now - s}s to create the menu items"
    # @shell.menu_bar = menu
  end

  # def create_toolbar
  #   s = Time.now
  # 
  #   if RbConfig::CONFIG["host_os"] =~ /darwin/
  #     toolbar = @shell.getToolBar
  #   else
  #     toolbar = Swt::Widgets::ToolBar.new(@shell, Swt::SWT::FLAT | Swt::SWT::WRAP | Swt::SWT::RIGHT)
  #   end
  #   
  #   # 20.times do
  #   #   itemPush = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::PUSH)
  #   #   puts File.expand_path("../alarm-clock--plus.png", __FILE__)
  #   #   icon = Swt::Graphics::Image.new(@shell.display, File.expand_path("../alarm-clock--plus.png", __FILE__))
  #   #   itemPush.setImage(icon)
  #   # end
  #   
  #   itemCheck = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::CHECK)
  #   itemCheck.setText("CHECK")
  #   
  #   itemRadio1 = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::RADIO)
  #   itemRadio1.setText("RADIO 1")
  #   
  #   itemRadio2 = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::RADIO)
  #   itemRadio2.setText("RADIO 2")
  #   
  #   itemSeparator = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::SEPARATOR)
  #   text = Swt::Widgets::Text.new(toolbar, Swt::SWT::BORDER | Swt::SWT::SINGLE)
  #   text.pack()
  #   itemSeparator.setWidth(text.bounds.width)
  #   itemSeparator.setControl(text)
  #   
  #   itemDropDown = Swt::Widgets::ToolItem.new(toolbar, Swt::SWT::DROP_DOWN)
  #   itemDropDown.setText("DROP_DOWN")
  #   itemDropDown.setToolTipText("Click here to see a drop down menu ...")
  #   
  #   menu = Swt::Widgets::Menu.new(@shell, Swt::SWT::POP_UP)
  #   Swt::Widgets::MenuItem.new(menu, Swt::SWT::PUSH).setText("Menu item 1")
  #   Swt::Widgets::MenuItem.new(menu, Swt::SWT::PUSH).setText("Menu item 2")
  #   Swt::Widgets::MenuItem.new(menu, Swt::SWT::SEPARATOR)
  #   Swt::Widgets::MenuItem.new(menu, Swt::SWT::PUSH).setText("Menu item 3")
  #   
  #   itemDropDown.addListener(Swt::SWT::Selection) do |event|
  #     if event.detail == Swt::SWT::ARROW
  #       bounds = itemDropDown.getBounds()
  #       point = toolbar.toDisplay(bounds.x, bounds.y + bounds.height)
  #       menu.setLocation(point)
  #       menu.setVisible(true)
  #     end
  #   end
  #   
  #   @shell.add_listener(Swt::SWT::Resize) do
  #     client_area = @shell.client_area
  #     toolbar.setSize(toolbar.computeSize(client_area.width, Swt::SWT::DEFAULT))
  #   end
  #   
  #   toolbar.pack
  #   puts "took #{Time.now - s}s to create the toolbar items"
  # end
  
  # See examples/button.rb for a discussion of this:
  def start
    display = Swt::Widgets::Display.get_current
    while !@shell.isDisposed
      display.sleep unless display.read_and_dispatch
    end

    display.dispose
  end
end

