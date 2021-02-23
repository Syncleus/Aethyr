require 'set'

module Lexicon
  module Gender
    MASCULINE = :masculine
    FEMININE = :feminine
    NEUTER = :neuter
  end
  GENDERS = Set[Gender::MASCULINE, Gender::FEMININE, Gender::NEUTER]
  GENDERS.freeze

  module Plurality
    PLURAL = :plural
    SINGULAR = :singular
  end
  PLURALITIES = Set[Plurality::PLURAL, Plurality::SINGULAR]
  PLURALITIES.freeze

  module GramaticalPerson
    FIRST_PERSON = :first_person
    SECOND_PERSON = :second_person
    THIRD_PERSON = :third_person
    INDIRECT = :indirect
    INTERROGATIVE = :interrogative
  end
  GRAMATICAL_PERSONS = Set[GramaticalPerson::FIRST_PERSON, GramaticalPerson::SECOND_PERSON, GramaticalPerson::THIRD_PERSON, GramaticalPerson::INDIRECT, GramaticalPerson::INTERROGATIVE]
  GRAMATICAL_PERSONS.freeze

  module Subjectivity
    OBJECTIVE = :objective
    SUBJECTIVE = :subjective
  end
  SUBJECTIVITIES = Set[Subjectivity::OBJECTIVE, Subjectivity::SUBJECTIVE]
  SUBJECTIVITIES.freeze

  module Relation
    REFLEXIVE = :reflexive
    POSSESSIVE = :possessive
  end
  RELATIONS = Set[Relation::REFLEXIVE, Relation::POSSESSIVE]
  RELATIONS.freeze

  module Quantifier
    ONE = :one
    ANY = :any
    SOME = :some
  end
  QUANTIFIERS = Set[Quantifier::ONE, Quantifier::ANY, Quantifier::SOME]
  QUANTIFIERS.freeze

  module Definitive
    DEFINITE = :definite
    INDEFINITE = :indefinite
  end
  DEFINITIVES = Set[Definitive::DEFINITE, Definitive::INDEFINITE]
  DEFINITIVES.freeze

  module Classifier
    PLURALITY = :plurality
    GRAMATICAL_PERSON = :gramatical_person
    RELATION = :relation
    SUBJECTIVITY = :subjectivity
    QUANTIFIER = :quantifier
    GENDER = :gender
  end
  CLASSIFIERS = {Classifier::PLURALITY => PLURALITIES, Classifier::GRAMATICAL_PERSON => GRAMATICAL_PERSONS, Classifier::RELATION => RELATIONS, Classifier::SUBJECTIVITY => SUBJECTIVITIES, Classifier::QUANTIFIER => QUANTIFIERS, Classifier::GENDER => GENDERS}
  CLASSIFIERS.freeze

  Pluralities = Struct.new(Plurality::SINGULAR, Plurality::PLURAL, keyword_init: true)
  GramaticalPersons = Struct.new(GramaticalPerson::FIRST_PERSON, GramaticalPerson::SECOND_PERSON, GramaticalPerson::THIRD_PERSON, GramaticalPerson::INDIRECT, GramaticalPerson::INTERROGATIVE, keyword_init: true)
  Relations = Struct.new(Relation::POSSESSIVE, Relation::REFLEXIVE, keyword_init: true)
  Subjectivities = Struct.new(Subjectivity::OBJECTIVE, Subjectivity::SUBJECTIVE, keyword_init: true)
  Quantifiers = Struct.new(Quantifier::ONE, Quantifier::ANY, Quantifier::SOME, keyword_init: true)
  Genders = Struct.new(Gender::MASCULINE, Gender::FEMININE, Gender::NEUTER, keyword_init: true)

  Vocab = Struct.new(:word, Classifier::PLURALITY, Classifier::GRAMATICAL_PERSON, Classifier::RELATION, Classifier::SUBJECTIVITY, Classifier::QUANTIFIER, Classifier::GENDER, keyword_init: true)
  PronounLexicon = Struct.new(Classifier::PLURALITY, Classifier::GRAMATICAL_PERSON, Classifier::RELATION, Classifier::SUBJECTIVITY, Classifier::QUANTIFIER, Classifier::GENDER, keyword_init: true)


  DEFAULT_VOCABULARY = [
    # First person, singular
    Vocab.new(word: 'I',             plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: :na,                  subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'me',            plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: :na,                  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'my',            plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'mine',          plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'myself',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    # Second person, singular/plural
    Vocab.new(word: 'you',                                           gramatical_person: GramaticalPerson::SECOND_PERSON, relation: :na,                                                          quantifier: :na),
    Vocab.new(word: 'your',                                          gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'yours',                                         gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'yourself',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'yourselves',    plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::SECOND_PERSON, relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    # Third person, singular, feminine
    Vocab.new(word: 'she',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: :na,                  subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na, gender: Gender::FEMININE),
    Vocab.new(word: 'her',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: :na,                  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na, gender: Gender::FEMININE),
    Vocab.new(word: 'her',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na, gender: Gender::FEMININE),
    Vocab.new(word: 'hers',          plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na, gender: Gender::FEMININE),
    Vocab.new(word: 'herself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na, gender: Gender::FEMININE),
    # Third person, singular, masculine
    Vocab.new(word: 'he',            plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: :na,                  subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na, gender: Gender::MASCULINE),
    Vocab.new(word: 'him',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: :na,                  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na, gender: Gender::MASCULINE),
    Vocab.new(word: 'his',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE,                                         quantifier: :na, gender: Gender::MASCULINE),
    Vocab.new(word: 'himself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na, gender: Gender::MASCULINE),
    # Third person, singular, neuter
    Vocab.new(word: 'it',            plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: :na,                                                          quantifier: :na, gender: Gender::NEUTER),
    Vocab.new(word: 'its',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE,                                         quantifier: :na, gender: Gender::NEUTER),
    Vocab.new(word: 'itself',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na, gender: Gender::NEUTER),
    #First person, plural
    Vocab.new(word: 'we',            plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: :na,                  subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'us',            plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: :na,                  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'our',           plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'ours',          plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'ourselves',     plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::FIRST_PERSON,  relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    # Third person, plural
    Vocab.new(word: 'they',          plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: :na,                  subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'them',          plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: :na,                  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'their',         plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'theirs',        plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'themselves',    plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::THIRD_PERSON,  relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    # Indirect person, singular, masculine
    Vocab.new(word: 'one',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::ONE,  gender: Gender::MASCULINE),
    Vocab.new(word: 'one\'s',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::ONE,  gender: Gender::MASCULINE),
    Vocab.new(word: 'ones',          plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ONE,  gender: Gender::MASCULINE),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ONE,  gender: Gender::MASCULINE),
    Vocab.new(word: 'someone',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::SOME, gender: Gender::MASCULINE),
    Vocab.new(word: 'someone\'s',    plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::SOME, gender: Gender::MASCULINE),
    Vocab.new(word: 'someones',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::SOME, gender: Gender::MASCULINE),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::SOME, gender: Gender::MASCULINE),
    Vocab.new(word: 'anyone',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::ANY,  gender: Gender::MASCULINE),
    Vocab.new(word: 'anyone\'s',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::ANY,  gender: Gender::MASCULINE),
    Vocab.new(word: 'anyones',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ANY,  gender: Gender::MASCULINE),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ANY,  gender: Gender::MASCULINE),
    # Indirect person, singular, feminine (same as masculine)
    Vocab.new(word: 'one',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::ONE,  gender: Gender::FEMININE),
    Vocab.new(word: 'one\'s',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::ONE,  gender: Gender::FEMININE),
    Vocab.new(word: 'ones',          plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ONE,  gender: Gender::FEMININE),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ONE,  gender: Gender::FEMININE),
    Vocab.new(word: 'someone',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::SOME, gender: Gender::FEMININE),
    Vocab.new(word: 'someone\'s',    plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::SOME, gender: Gender::FEMININE),
    Vocab.new(word: 'someones',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::SOME, gender: Gender::FEMININE),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::SOME, gender: Gender::FEMININE),
    Vocab.new(word: 'anyone',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::ANY,  gender: Gender::FEMININE),
    Vocab.new(word: 'anyone\'s',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::ANY,  gender: Gender::FEMININE),
    Vocab.new(word: 'anyones',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ANY,  gender: Gender::FEMININE),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ANY,  gender: Gender::FEMININE),
    # Indirect person, singular, neuter
    Vocab.new(word: 'one',           plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::ONE,  gender: Gender::NEUTER),
    Vocab.new(word: 'one\'s',        plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::ONE,  gender: Gender::NEUTER),
    Vocab.new(word: 'ones',          plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ONE,  gender: Gender::NEUTER),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ONE,  gender: Gender::NEUTER),
    Vocab.new(word: 'something',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::SOME, gender: Gender::NEUTER),
    Vocab.new(word: 'something\'s',  plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::SOME, gender: Gender::NEUTER),
    Vocab.new(word: 'somethings',    plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::SOME, gender: Gender::NEUTER),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::SOME, gender: Gender::NEUTER),
    Vocab.new(word: 'anything',      plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: Quantifier::ANY,  gender: Gender::NEUTER),
    Vocab.new(word: 'anything\'s',   plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: Quantifier::ANY,  gender: Gender::NEUTER),
    Vocab.new(word: 'anythings',     plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ANY,  gender: Gender::NEUTER),
    Vocab.new(word: 'oneself',       plurality: Plurality::SINGULAR, gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: Quantifier::ANY,  gender: Gender::NEUTER),
    # Indirect person, plural, feminine
    Vocab.new(word: 'everyone',      plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: :na,              gender: Gender::FEMININE),
    Vocab.new(word: 'everyone\'s',   plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na,              gender: Gender::FEMININE),
    Vocab.new(word: 'everyones',     plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na,              gender: Gender::FEMININE),
    Vocab.new(word: 'oneself',       plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na,              gender: Gender::FEMININE),
    # Indirect person, plural, masculine (same as feminine)
    Vocab.new(word: 'everyone',      plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: :na,              gender: Gender::MASCULINE),
    Vocab.new(word: 'everyone\'s',   plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na,              gender: Gender::MASCULINE),
    Vocab.new(word: 'everyones',     plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na,              gender: Gender::MASCULINE),
    Vocab.new(word: 'oneself',       plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na,              gender: Gender::MASCULINE),
    # Indirect person, plural, neuter
    Vocab.new(word: 'everything',    plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: :na,                                                          quantifier: :na,              gender: Gender::NEUTER),
    Vocab.new(word: 'everything\'s', plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na,              gender: Gender::NEUTER),
    Vocab.new(word: 'everythings',   plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na,              gender: Gender::NEUTER),
    Vocab.new(word: 'oneself',       plurality: Plurality::PLURAL,   gramatical_person: GramaticalPerson::INDIRECT,      relation: Relation::REFLEXIVE,  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na,              gender: Gender::NEUTER),
    # Interrogative person, singular/plural
    Vocab.new(word: 'who',                                           gramatical_person: GramaticalPerson::INTERROGATIVE, relation: :na,                  subjectivity: Subjectivity::OBJECTIVE,  quantifier: :na),
    Vocab.new(word: 'whom',                                          gramatical_person: GramaticalPerson::INTERROGATIVE, relation: :na,                  subjectivity: Subjectivity::SUBJECTIVE, quantifier: :na),
    Vocab.new(word: 'whose',                                         gramatical_person: GramaticalPerson::INTERROGATIVE, relation: Relation::POSSESSIVE,                                         quantifier: :na),
  ]

  def Lexicon.construct_pronoun_lexicon(vocabulary)
    lexicon = PronounLexicon.new(
      plurality: Pluralities.new(singular: Set[], plural: Set[]),
      gramatical_person: GramaticalPersons.new(first_person: Set[], second_person: Set[], third_person: Set[], indirect: Set[], interrogative: Set[]),
      relation: Relations.new(possessive: Set[], reflexive: Set[]),
      subjectivity: Subjectivities.new(objective: Set[], subjective: Set[]),
      quantifier: Quantifiers.new(one: Set[], some: Set[], any: Set[]),
      gender: Genders.new(masculine: Set[], feminine: Set[], neuter: Set[])
    )

    vocabulary.each do |vocab_word|
      word_text = vocab_word.word

      vocab_word.each_pair do |key, value|
        next if key == :word

        if value.nil?
          CLASSIFIERS[key].each do |inferred_value|
            lexicon[key][inferred_value].add(word_text)
          end
        else
          lexicon[key][value].add(word_text) if value != :na
        end
      end
    end

    lexicon.each do |classifier|
      classifier.each do |class_set|
        class_set.freeze
      end
      classifier.freeze
    end
    lexicon.freeze

    return lexicon
  end

  @@PRONOUN_LEXICON = Lexicon::construct_pronoun_lexicon(Lexicon::DEFAULT_VOCABULARY)

  def noun(proper = true, plurality: nil, gramatical_person: nil, relation: nil, subjectivity: nil, quantifier: nil)
    if proper
      final_noun = @name
      if plurality == Plurality::PLURAL
        final_noun += 's'
        final_noun += '\'' if relation == Relation::POSSESSIVE
      elsif relation == Relation::POSSESSIVE
        final_nount += '\'s'
      end
      return final_noun
    end

    noun_set = @@PRONOUN_LEXICON.gender[@gender]
    noun_set = noun_set.intersection(@@PRONOUN_LEXICON.plurality[plurality]) if not plurality.nil?
    noun_set = noun_set.intersection(@@PRONOUN_LEXICON.gramatical_person[gramatical_person]) if not gramatical_person.nil?
    noun_set = noun_set.intersection(@@PRONOUN_LEXICON.relation[relation]) if not relation.nil?
    noun_set = noun_set.intersection(@@PRONOUN_LEXICON.subjectivity[subjectivity]) if not subjectivity.nil?
    noun_set = noun_set.intersection(@@PRONOUN_LEXICON.quantifier[quantifier]) if not quantifier.nil?
    noun_set = noun_set.intersection(@@PRONOUN_LEXICON.relation[relation]) if not relation.nil?

    if relation.nil?
      RELATIONS.each do |subtract_relation|
        noun_set = noun_set.subtract(@@PRONOUN_LEXICON.relation[subtract_relation])
      end
    end

    if quantifier.nil?
      QUANTIFIERS.each do |subtract_quantifier|
        noun_set = noun_set.subtract(@@PRONOUN_LEXICON.quantifier[subtract_quantifier])
      end
    end

    if noun_set.size() != 1
      raise ArgumentError "filters applied to produce noun did not produce a single unique noun, possible nouns: #{noun_set}"
    end

    noun_set.each do |result|
      return result
    end
  end

  # For legacy purposes
  def pronoun(type = :normal)
    if type == :normal
      return noun(false, plurality: Plurality::Singular, gramatical_person: GramaticalPerson::THIRD_PERSON, subjectivity: Subjectivity::SUBJECTIVE )
    elsif type == :reflexive
      return noun(false, plurality: Plurality::Singular, gramatical_person: GramaticalPerson::THIRD_PERSON, relation: Relation::REFLEXIVE )
    elsif type == :possessive
      return noun(false, plurality: Plurality::Singular, gramatical_person: GramaticalPerson::THIRD_PERSON, relation: Relation::POSSESSIVE, subjectivity: Subjectivity::SUBJECTIVE )
    elsif type == :objective
      return noun(false, plurality: Plurality::Singular, gramatical_person: GramaticalPerson::THIRD_PERSON, subjectivity: Subjectivity::OBJECTIVE )
    elsif type == :obj_poss
      return noun(false, plurality: Plurality::Singular, gramatical_person: GramaticalPerson::THIRD_PERSON, relation: Relation::POSSESSIVE, subjectivity: Subjectivity::OBJECTIVE )
    else
      raise ArgumentError "Unrecognized typed #{type}"
    end
  end
end
