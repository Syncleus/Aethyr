class Flag
  attr_reader :name, :affected, :affect_desc, :help_desc
  
  def initialize(affected, name, affect_desc, help_desc, flags_to_negate = nil)
    @affected = affected
    @name = name
    @affect_desc = affect_desc
    @help_desc = help_desc
    @flags_to_negate = flags_to_negate
  end
  
  def can_see? (player)
    true
  end
  
  def negate_flags (other_flags)
    return other_flags if @flags_to_negate.nil? or @flags_to_negate.empty?
    @flags_to_negate.each do |f|
      other_flags.delete(f)
    end
  end
end
