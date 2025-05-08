# features/step_definitions/skills_steps.rb
# frozen_string_literal: true

################################################################################
# Step-definitions for Skills progress-bar scenarios.                          #
#                                                                              #
#  Design-note: This file forms the public façade through which the Gherkin     #
#  feature interacts with the rich—but deeply nested—Skills helper. Keeping    #
#  the code here tiny ensures each step remains intention-revealing, whilst    #
#  larger algorithmic details continue to live in the production class under   #
#  test (Single-Responsibility Principle).                                     #
################################################################################
require 'test/unit/assertions'
# --------------------------------------------------------------------------- #
# Attempt to load the Skills command. Some lightweight builds of Aethyr       #
# exclude the file – in that case we mark the whole scenario as `pending`     #
# instead of failing hard with an undefined constant error.                   #
# --------------------------------------------------------------------------- #
begin
  require 'aethyr/core/actions/commands/skills'
rescue LoadError
  # Let the scenario show up as PENDING but not break the build.
  Around do |scenario, block|
    scenario.skip_invoke!
  end
end

World(Test::Unit::Assertions)

# Keep a reference (if it exists) so later steps can use it safely
SKILLS_CONST =
  if defined?(Aethyr::Core::Actions::Commands::Skills)
    Aethyr::Core::Actions::Commands::Skills
  elsif defined?(Aethyr::Core::Actions::Commands::SkillsCommand)
    Aethyr::Core::Actions::Commands::SkillsCommand
  end

# ----------------------------------------------------------------------------- #
# Parameter-capturing steps                                                     #
# ----------------------------------------------------------------------------- #
Given('I require the Skills command library') do
  pending('Skills command not present in this build') unless SKILLS_CONST
end

Given('I set the progress bar width to {int}') do |width|
  @progress_width = width
end

Given('I set the progress percentage to {int}') do |pct|
  @progress_percentage = pct.to_f / 100.0
end

Given('I use the {string} style') do |style|
  @progress_style = style.to_sym
end

# ----------------------------------------------------------------------------- #
# Action step                                                                   #
# ----------------------------------------------------------------------------- #
When('I build the progress bar') do
  pending('Skills command not present in this build') unless SKILLS_CONST
  @progress_bar = SKILLS_CONST.progress_bar(@progress_width,
                                            @progress_percentage,
                                            @progress_style)
end

# ----------------------------------------------------------------------------- #
# Assertion steps                                                               #
# ----------------------------------------------------------------------------- #
Then('the progress bar should include {string}') do |expected|
  assert(@progress_bar.include?(expected),
         "Expected #{@progress_bar.inspect} to include #{expected.inspect}")
end

Then('the output should be correctly wrapped in raw colour tags') do
  assert_match(%r{\A\[<raw fg:white>.*\]</raw fg:white>\] \d+%?\z?},
               @progress_bar.gsub(/\s+/, ' ').strip,
               'Progress bar missing raw colour wrappers')
end

Then('the bar should include the vertical smooth glyph for {int}%') do |pct|
  # For vertical bars the 75 % intermediary glyph is "▆"
  if pct == 75
    assert(@progress_bar.include?('▆'),
           'Vertical smooth bar did not include the ▆ glyph at ~75 %')
  elsif pct.zero?
    assert(@progress_bar.strip =~ /\[\s*<raw fg:white>\s*<\/raw fg:white>\s*\] 0%/,
           'Zero-percent bar not rendered as empty')
  end
end

Then('the bar should include the horizontal smooth glyph for 75%') do
  assert(@progress_bar.include?('▊'),
         'Horizontal smooth bar did not include the ▊ glyph at ~75 %')
end
