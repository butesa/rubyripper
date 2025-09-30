class AdditionalLog
  # The name of the logfile
  attr_accessor :filename

  # The ontent of the logfile
  attr_accessor :content
  
  def initialize(filename)
    @filename = filename
  end
end
