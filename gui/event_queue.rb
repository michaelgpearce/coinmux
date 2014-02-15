class Gui::EventQueue
  include Singleton

  import 'javax.swing.SwingUtilities'
  import 'javax.swing.Timer'

  def sync_exec(&callback)
    if SwingUtilities.isEventDispatchThread()
      yield
    else
      SwingUtilities.invokeAndWait(create_callback_with_error_handling(&callback))
    end
  end
  
  def future_exec(seconds = 0, &callback)
    if seconds <= 0
      SwingUtilities.invokeLater(create_callback_with_error_handling(&callback))
    else
      Timer.new(seconds * 1000, lambda { |e|
        create_callback_with_error_handling(&callback).call
      }).tap do |timer|
        timer.setRepeats(false)
        timer.start()
      end
    end
  end

  private

  def create_callback_with_error_handling(&callback)
    Proc.new do
      begin
        yield
      rescue Exception => e
        puts "Unhandled error in event dispatch thread: #{e}", *e.backtrace
      end
    end
  end
end