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
  end

  module GramaticalPerson
    FIRST_PERSON = :first_person
    SECOND_PERSON = :second_person
    THIRD_PERSON = :third_person
    FOURTH_PERSON = :fourth_person
    INTERROGATIVE = : :interrogative
  end

  module Subjectivity
    OBJECTIVE = :objective
    SUBJECTIVE = :subjective
  end

  module Relation
    NONE = :none
    REFLECTIVE = :reflective
    POSSESSIVE = :possessive
  end

  module Definitive
    DEFINITE = :definite
    INDEFINITE = :indefinite
  end

  Vocab = Struct.new(:word, :gender, :plurality, :gramatical_person, :subjectivity, keyword_init: true)

  def construct_lexicon(vocabulary)
  end

  construct_lexicon([
                     Vocab.new(word: 'I',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::NONE,       subjectivity: Subjectivity::SUBJECTIVE),
                     Vocab.new(word: 'me',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::NONE,       subjectivity: Subjectivity::OBJECTIVE),
                     Vocab.new(word: 'my',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE),
                     Vocab.new(word: 'mine',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE),
                     Vocab.new(word: 'myself',   plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE),
                     Vocab.new(word: 'you',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::NONE),
                     Vocab.new(word: 'your',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE),
                     Vocab.new(word: 'yours',    plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE),
                     Vocab.new(word: 'yourself', plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::REFLECTIVE, subjectivity: Subjectivity::OBJECTIVE),
                     Vocab.new(word: 'she',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::NONE,       subjectivity: Subjectivity::SUBJECTIVE, gender: Gender::FEMANINE),
                     Vocab.new(word: 'her',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::NONE,       subjectivity: Subjectivity::OBJECTIVE,  gender: Gender::FEMANINE),
                     Vocab.new(word: 'her',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, gender: Gender::FEMANINE),
                     Vocab.new(word: 'hers',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  gender: Gender::FEMANINE),
                     Vocab.new(word: 'herself',  plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::REFLECTIVE, subjectivity: Subjectivity::OBJECTIVE,  gender: Gender::FEMANINE),
                     Vocab.new(word: 'he',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::NONE,       subjectivity: Subjectivity::SUBJECTIVE, gender: Gender::MASCULIN),
                     Vocab.new(word: 'him',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::NONE,       subjectivity: Subjectivity::OBJECTIVE,  gender: Gender::MASCULIN),
                     Vocab.new(word: 'his',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE,                                         gender: Gender::MASCULIN),
                     Vocab.new(word: 'himself',  plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::REFLECTIVE, subjectivity: Subjectivity::OBJECTIVE,  gender: Gender::MASCULIN),
                     Vocab.new(word: 'one',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FOURTH_PERSON, relation: Relation::NONE,       subjectivity: Subjectivity::SUBJECTIVE),
                     Vocab.new(word: 'oneself',  plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FOURTH_PERSON, relation: Relation::REFLECTIVE, subjectivity: Subjectivity::OBJECTIVE),
                     Vocab.new(word: 'who',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INTERROGATIVE, relation: Relation::NONE,       subjectivity: Subjectivity::OBJECTIVE),
                     Vocab.new(word: 'whom',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INTERROGATIVE, relation: Relation::NONE,       subjectivity: Subjectivity::SUBJECTIVE),
                     Vocab.new(word: 'whose',    plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INTERROGATIVE, relation: Relation::POSSESSIVE),
                    ])
end

# interrogative [subjective] pronounds:who, what, why, where, when, whatever
# interrogative [objective] pronounds:whom, what, why, where, when, whatever
# indefinate pronounds: anything, anybody, anyone, something, somebody, someone, nothing, nobody, none, no one
# someone, something
# direct-reflexive-pronoun: himself
# indirect-reflective-pronoun: me

# reflexive [objective] pronouns: myself, yourself, himself, herself, itself, ourselves, yourselves, themselves.
# possessive [subjective] adjective/determiner: my, your, his, her, its, our, their
# possessive [objective]  pronoun: mine, yours, his, hers, its, ours, theirs
# objective pronoun: me, us, you, him, her, it, them, and whom
# subjective pronoun:  I, you, we, he, she, it, they, and who

# Determiners: this, the, my
# Determiners: articles (definite: the, indefinite: a/an), demonstratives(this, that), possessive determines (my, their), quantifiers (many, all, no. every).
