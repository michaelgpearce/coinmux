class Gui::EventQueue
  include Singleton

  import 'javax.swing.SwingUtilities'
  import 'javax.swing.Timer'

  def sync_exec(&callback)
    SwingUtilities.invokeAndWait(&callback)
  end
  
  def future_exec(seconds = 0, &callback)
    if seconds <= 0
      SwingUtilities.invokeLater(&callback)
    else
      Timer.new(seconds * 1000, lambda { |e|
        yield
      }).tap do |timer|
        timer.setRepeats(false)
        timer.start()
      end
    end
  end
end