class Gui::EventQueue
  include Singleton

  import 'javax.swing.SwingUtilities'

  def sync_exec(&callback)
    SwingUtilities.invokeAndWait(&callback)
  end
  
  def future_exec(seconds = 0, &callback)
    if seconds <= 0
      SwingUtilities.invokeLater(&callback)
    else
      Thread.new do
        sleep(seconds)
        SwingUtilities.invokeLater(&callback)
      end
    end
  end
end