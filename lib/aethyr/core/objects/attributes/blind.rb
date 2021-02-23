require 'aethyr/core/objects/attributes/attribute'
require 'aethyr/core/objects/living'
require 'aethyr/core/objects/traits/lexicon'

class Blind < Attribute
  def initialize(attach_to)
    if not attach_to.is_a? LivingObject
      raise ArgumentError.new "Can only attach the Blind attribute to LivingObjects"
    end

    super(attach_to)

    @attached_to.subscribe(self)
  end

  def pre_look(data)
    data[:can_look] = false

    you_subj = @attached_to.noun(false, plurality: Lexicon::Plurality::SINGULAR, gramatical_person: Lexicon::GramaticalPerson::SECOND_PERSON, subjectivity: Lexicon::Subjectivity::SUBJECTIVE).capitalize
    you_obj = @attached_to.noun(false, plurality: Lexicon::Plurality::SINGULAR, gramatical_person: Lexicon::GramaticalPerson::SECOND_PERSON, subjectivity: Lexicon::Subjectivity::OBJECTIVE)
    data[:reason] = "#{you_subj} cannot see while #{you_obj} are blind"
  end
end
