# Load this file to require all event modules.
# This file serves as a centralized loader for all input handler modules,
# ensuring that all command processing capabilities are available to the system.
# By explicitly requiring each file individually, we maintain better control
# over the loading order and can more easily debug loading issues.

# Dir.foreach('lib/aethyr/commands') do |f|
#   if f[0,1] == '.' || f[0,1] == '~'
#     next
#   end
#
#   require "aethyr/commands/#{f[0..-4]}"
# end

# Core Input Handlers - Basic System Commands
# These handlers provide fundamental functionality required for player interaction
# and basic game operations. Each handler implements the Command Pattern with
# specific responsibilities following the Single Responsibility Principle.
require 'aethyr/core/input_handlers/command_handler'
require 'aethyr/core/input_handlers/help_handler'
require 'aethyr/core/input_handlers/help'

# Movement and Positioning Handlers
# Implementing state pattern for player position management and movement commands
require 'aethyr/core/input_handlers/move'
require 'aethyr/core/input_handlers/stand'
require 'aethyr/core/input_handlers/sit'
require 'aethyr/core/input_handlers/gait'

# Observation and Interaction Handlers
# These handlers manage player perception and interaction with the game world,
# utilizing the Observer pattern for environmental awareness
require 'aethyr/core/input_handlers/look'
require 'aethyr/core/input_handlers/listen'
require 'aethyr/core/input_handlers/feel'
require 'aethyr/core/input_handlers/taste'
require 'aethyr/core/input_handlers/smell'
require 'aethyr/core/input_handlers/map'

# Communication Handlers
# Implementing Chain of Responsibility pattern for message routing and delivery
require 'aethyr/core/input_handlers/say'
require 'aethyr/core/input_handlers/tell'
require 'aethyr/core/input_handlers/whisper'
require 'aethyr/core/input_handlers/pose'

# Inventory and Object Management Handlers
# These handlers manage object manipulation using Command pattern for undo/redo
# capability and State pattern for object state management
require 'aethyr/core/input_handlers/inventory'
require 'aethyr/core/input_handlers/get'
require 'aethyr/core/input_handlers/drop'
require 'aethyr/core/input_handlers/give'
require 'aethyr/core/input_handlers/put'
require 'aethyr/core/input_handlers/wear'
require 'aethyr/core/input_handlers/remove'
require 'aethyr/core/input_handlers/wield'
require 'aethyr/core/input_handlers/unwield'

# Container and Portal Interaction Handlers
# Implementing Strategy pattern for different container and portal behaviors
require 'aethyr/core/input_handlers/open'
require 'aethyr/core/input_handlers/close'
require 'aethyr/core/input_handlers/fill'
require 'aethyr/core/input_handlers/locking'
require 'aethyr/core/input_handlers/portal'

# Combat and Action Handlers
# Using State pattern for combat states and Command pattern for combat actions
require 'aethyr/core/input_handlers/punch'
require 'aethyr/core/input_handlers/kick'
require 'aethyr/core/input_handlers/slash'
require 'aethyr/core/input_handlers/block'
require 'aethyr/core/input_handlers/dodge'

# Player Status and Information Handlers
# Implementing Observer pattern for status monitoring and Mediator pattern
# for coordinating status updates across different subsystems
require 'aethyr/core/input_handlers/status'
require 'aethyr/core/input_handlers/health'
require 'aethyr/core/input_handlers/satiety'
require 'aethyr/core/input_handlers/skills'
require 'aethyr/core/input_handlers/who'
require 'aethyr/core/input_handlers/whereis'

# System and Utility Handlers
# These handlers provide essential system functionality and utilities
require 'aethyr/core/input_handlers/time'
require 'aethyr/core/input_handlers/date'
require 'aethyr/core/input_handlers/news'
require 'aethyr/core/input_handlers/more'
require 'aethyr/core/input_handlers/set'
require 'aethyr/core/input_handlers/quit'
require 'aethyr/core/input_handlers/deleteme'
require 'aethyr/core/input_handlers/issue'
require 'aethyr/core/input_handlers/write'

# Administrative Command Handlers
# These handlers provide administrative functionality using Decorator pattern
# for privilege checking and Command pattern for audit logging
require 'aethyr/core/input_handlers/admin/admin_handler'
require 'aethyr/core/input_handlers/admin/awho'
require 'aethyr/core/input_handlers/admin/astatus'
require 'aethyr/core/input_handlers/admin/awatch'
require 'aethyr/core/input_handlers/admin/ashow'
require 'aethyr/core/input_handlers/admin/aset'
require 'aethyr/core/input_handlers/admin/asave'
require 'aethyr/core/input_handlers/admin/areload'
require 'aethyr/core/input_handlers/admin/areas'
require 'aethyr/core/input_handlers/admin/areact'
require 'aethyr/core/input_handlers/admin/aput'
require 'aethyr/core/input_handlers/admin/alook'
require 'aethyr/core/input_handlers/admin/alog'
require 'aethyr/core/input_handlers/admin/alist'
require 'aethyr/core/input_handlers/admin/alearn'
require 'aethyr/core/input_handlers/admin/ateach'
require 'aethyr/core/input_handlers/admin/ainfo'
require 'aethyr/core/input_handlers/admin/ahide'
require 'aethyr/core/input_handlers/admin/ahelp'
require 'aethyr/core/input_handlers/admin/aforce'
require 'aethyr/core/input_handlers/admin/adesc'
require 'aethyr/core/input_handlers/admin/adelete'
require 'aethyr/core/input_handlers/admin/acroom'
require 'aethyr/core/input_handlers/admin/acreate'
require 'aethyr/core/input_handlers/admin/acprop'
require 'aethyr/core/input_handlers/admin/acportal'
require 'aethyr/core/input_handlers/admin/aconfig'
require 'aethyr/core/input_handlers/admin/acomment'
require 'aethyr/core/input_handlers/admin/acomm'
require 'aethyr/core/input_handlers/admin/acexit'
require 'aethyr/core/input_handlers/admin/acdoor'
require 'aethyr/core/input_handlers/admin/acarea'
require 'aethyr/core/input_handlers/admin/terrain'
require 'aethyr/core/input_handlers/admin/restart'
require 'aethyr/core/input_handlers/admin/deleteplayer'

# Emote System Handlers
# Implementing Template Method pattern for consistent emote behavior
# and Strategy pattern for different emote rendering approaches
require 'aethyr/core/input_handlers/emotes/emote_handler'
require 'aethyr/core/input_handlers/emotes/emote'

# Positive Emotion Emotes
# These emotes express positive emotions and reactions
require 'aethyr/core/input_handlers/emotes/yes'
require 'aethyr/core/input_handlers/emotes/wave'
require 'aethyr/core/input_handlers/emotes/smile'
require 'aethyr/core/input_handlers/emotes/skip'
require 'aethyr/core/input_handlers/emotes/nod'
require 'aethyr/core/input_handlers/emotes/laugh'
require 'aethyr/core/input_handlers/emotes/hug'
require 'aethyr/core/input_handlers/emotes/hi'
require 'aethyr/core/input_handlers/emotes/grin'
require 'aethyr/core/input_handlers/emotes/cheer'
require 'aethyr/core/input_handlers/emotes/bow'
require 'aethyr/core/input_handlers/emotes/blush'
require 'aethyr/core/input_handlers/emotes/back'
require 'aethyr/core/input_handlers/emotes/agree'

# Neutral Emotion Emotes
# These emotes express neutral emotions and general interactions
require 'aethyr/core/input_handlers/emotes/yawn'
require 'aethyr/core/input_handlers/emotes/uh'
require 'aethyr/core/input_handlers/emotes/snicker'
require 'aethyr/core/input_handlers/emotes/shrug'
require 'aethyr/core/input_handlers/emotes/sigh'
require 'aethyr/core/input_handlers/emotes/ponder'
require 'aethyr/core/input_handlers/emotes/poke'
require 'aethyr/core/input_handlers/emotes/pet'
require 'aethyr/core/input_handlers/emotes/huh'
require 'aethyr/core/input_handlers/emotes/hm'
require 'aethyr/core/input_handlers/emotes/er'
require 'aethyr/core/input_handlers/emotes/eh'
require 'aethyr/core/input_handlers/emotes/curtsey'
require 'aethyr/core/input_handlers/emotes/bye'
require 'aethyr/core/input_handlers/emotes/brb'

# Negative Emotion Emotes
# These emotes express negative emotions and reactions
require 'aethyr/core/input_handlers/emotes/no'
require 'aethyr/core/input_handlers/emotes/frown'
require 'aethyr/core/input_handlers/emotes/ew'
require 'aethyr/core/input_handlers/emotes/cry'

# Extension Input Handlers
# These handlers provide extended functionality through the plugin system
# Currently empty as indicated by the .keep file, but structured for future expansion
# Extensions follow the same architectural patterns as core handlers
# Note: The extensions directory only contains a .keep file, indicating no current extensions
