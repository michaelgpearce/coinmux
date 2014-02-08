class Gui::View::MixSettings < Gui::View::Base
  import 'java.awt.Component'
  import 'java.awt.Dimension'
  import 'javax.swing.JSpinner'
  import 'javax.swing.SpinnerModel'
  import 'javax.swing.SpinnerNumberModel'

  def add
    add_row do |parent|
      spinner = JSpinner.new(build_spinner_model)
      parent.add(spinner)
    end
  end

  private

  def build_spinner_model
    spinner_model_constructor = SpinnerNumberModel.java_class.constructor(Java::int, Java::int, Java::int, Java::int)
    spinner_model_constructor.new_instance(2, 2, 100, 1)
  end
end

