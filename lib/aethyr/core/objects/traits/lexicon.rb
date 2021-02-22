module Lexicon
  Genders = Struct(:male, :female, :neuter, keyword_init: true)
  Plurality = Struct(:singular, :plural, keyword_init: true)
  Subjectivity = Struct(:subjective, :objective, :reflective, keyword_init: true)
  Posessiveness = Struct(:posessive, :nonposessive)
  Determiners = Struct(:articles, :demonstratives, :posessive, :quantifier, keyword_init: true)
  Parts = Struct(:adjective, :pronoun, :noun, :verb, :adverb, :conjunction, :interjection, :preposition, keyword_init: true)
  Directness = Struct(:direct, :indirect, keyword_init: true)
  GramaticalPerson = Struct(:first_person, :second_person, :third_person, :fourth_person)

  GramaticalPerson.new(
    first_person: Subjectivity.new(
      subjective: Plurality.new(
        singular: 'I',
        plural: 'we'
      ),
      objective: Plurality.new(
        singular: 'me',
        plural: 'us'
      ),
      reflexive: Plurality.new(
        singular: 'myself',
        plural: 'ourselves'
      )
    )
  )

  module Gender
    MASCULIN = :masculin
    FEMANINE = :femanine
    NEUTER = :neuter
  end

  module Plurality
    PLURAL = :plural
    SINGULAR = :singular
    NONE = :none
  end

  module GramaticalPerson
    FIRST_PERSON = :first_person
    SECOND_PERSON = :second_person
    THIRD_PERSON = :third_person
    FOURTH_PERSON = :fourth_person
  end

  module Subjectivity
    OBJECTIVE = :objective
    SUBJECTIVE = :subjective
  end

  module Reference
    REFLECTIVE = :reflective
    POSSESSIVE = :possessive
    INTERROGATIVE = :interrogative
    INDEFINITE = :indefinite
  end

  Vocab = Struct.new(:word, :gender, :plurality, :gramatical_person, :subjectivity, keyword_init: true)

  def construct_lexicon(vocabulary)
  end

  construct_lexicon([Vocab.new(word: 'I', plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,
end

# interrogative pronounds:who, what, why, where, when, whatever
# indefinate pronounds: anything, anybody, anyone, something, somebody, someone, nothing, nobody, none, no one
# someone, something
# direct-reflexive-pronoun: himself
# indirect-reflective-pronoun: me

# reflexive pronouns: myself, yourself, himself, herself, itself, ourselves, yourselves, themselves.
# possessive adjective/determiner: my, your, his, her, its, our, their
# possessive pronoun: mine, yours, his, hers, its, ours, theirs
# objective pronoun: me, us, you, him, her, it, them, and whom
# subjective pronoun:  I, you, we, he, she, it, they, and who

# Determiners: this, the, my
# Determiners: articles (definite: the, indefinite: a/an), demonstratives(this, that), possessive determines (my, their), quantifiers (many, all, no. every).
