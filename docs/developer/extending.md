---
id: extending
slug: /developer/extending
title: Hands-on Extension Tutorial
sidebar_label: Extending
sidebar_position: 2
---

# Hands-on Extension Tutorial

This guided tutorial walks you through implementing a **new skill**, **custom command**, and **bespoke emote**—all leveraging the extension framework shipped in `lib/aethyr/extensions`.

---

## 1. Creating a New Skill – *Alchemy*

### 1.1 Directory Layout

```text
lib/aethyr/extensions/skills/alchemy/
├── handler.rb      # Skill logic & XP table
└── manifest.rb     # Registration metadata
```

### 1.2 `manifest.rb`

```ruby
aethyr_extension do |e|
  e.name        = 'Alchemy'
  e.version     = '1.0.0'
  e.dependencies = []
end
```

### 1.3 `handler.rb`

```ruby
class Alchemy < Aethyr::Extend::Skill
  def attempt(caster, reagent)
    difficulty = 30 - caster.skills.level(:alchemy)
    if caster.check_skill(:alchemy, difficulty)
      # Success ➜ craft healing potion
      potion = create_potion(reagent)
      caster.inventory.add(potion)
      caster.output 'You brew a restorative potion.'
    else
      caster.output 'The mixture fizzles into useless sludge.'
    end
  end
end
```

The **Template Method Pattern** allows you to override only `#attempt`, while reuse durability checks & XP gain.

---

## 2. Adding a Command Alias – `brew`

```ruby title="lib/aethyr/extensions/actions/commands/brew.rb"
class BrewCommand < Aethyr::Extend::CommandAction
  self.command_names = %w[brew mix]
  def action
    if self[:with]
      reagent = @player.inventory.find(self[:with])
      Alchemy.new.attempt(@player, reagent)
    else
      @player.output 'Syntax: brew <reagent>'
    end
  end
end
```

*Conforms to the **Command Pattern**—every verb is encapsulated in its own object.*

---

## 3. Registering an Emote

Emotes live under `lib/aethyr/extensions/actions/commands/emotes`.

```ruby
class GrinEmote < Aethyr::Extend::Emote
  self.command_names = %w[grin]
  self.regex = /^grin(?:\s+(?<target>\w+))?$/i

  transmit :self,    ->(actor, data) { 'You grin broadly.' }
  transmit :target,  ->(actor, data) { "#{actor.name} grins at you." }, if: :target?
  transmit :others,  ->(actor, data) { "#{actor.name} grins." }
end
```

The DSL uses the **Strategy Pattern** via lambdas—each audience receives its own rendering logic.

---

## 4. Packaging Your Extension

Run the built-in Rake task:

```bash
$ bundle exec rake extensions:package NAME=alchemy VERSION=1.0.0
```

This creates `pkg/aethyr-alchemy-1.0.0.gem` which you can `gem install` on any Aethyr server.

---

## 5. Integration Tests

Add a *Cucumber* feature under `tests/integration` and execute only that file:

```bash
$ bundle exec rake integration FEATURE=tests/integration/alchemy.feature
```

Remember to commit the *feature*, *step definitions*, and any helper modules.

---

Proceed to **[Player Guide](../player/commands)** to see your new features from a player's perspective. 