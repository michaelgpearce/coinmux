class Gui::View::Mixing < Gui::View::Base
  import 'java.awt.Component'
  import 'java.awt.Dimension'
  import 'javax.swing.JProgressBar'

  def add
    add_row do |parent|
      progress_bar = JProgressBar.new
      progress_bar.setIndeterminate(true)
      parent.add(progress_bar)
    end
  end
  
  def show
  end

end

