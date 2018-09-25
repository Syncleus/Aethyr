class Command
  attr_reader :name
  
  def initialize(name, *args)
    super()
    @name = name
  end
  
  def handle(input, player)
      false
  end
end