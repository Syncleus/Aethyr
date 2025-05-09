# frozen_string_literal: true
#------------------------------------------------------------------------------
#  Ncurses Stub
#------------------------------------------------------------------------------
#  This file neutralises the hard dependency on the native `ncursesw` library
#  which is difficult to satisfy in containerised CI environments.  It should
#  be loaded *before* any library attempts to `require 'ncursesw'`.
#
#  Strategy: Monkey-patch `Kernel.require` so that when the name `ncursesw`
#  appears we instead inject a minimal shim module that answers *any* method
#  call with a benign default.  This fully isolates the network/server logic
#  that the integration tests exercise from the display subsystem.
#------------------------------------------------------------------------------
module Kernel
  alias_method :__orig_require__, :require unless method_defined?(:__orig_require__)

  def require(name)
    return false if name == 'ncursesw' && defined?(::Ncurses)

    if name == 'ncursesw'
      # ----------------------------------------------------------------------
      #  Dynamically create a lightweight ::Ncurses replacement that answers to
      #  any call.  Defining a constant via Object.const_set circumvents the
      #  parser restriction that forbids opening modules inside method bodies
      #  on Ruby ≥3.4.
      # ----------------------------------------------------------------------

      unless Object.const_defined?(:Ncurses)
        Object.const_set(:Ncurses, Module.new)
      end

      nc = ::Ncurses

      # DummyWindow swallows all method calls – returned for any undefined
      # factory method.
      unless nc.const_defined?(:DummyWindow)
        dummy = Class.new do
          def method_missing(*) = nil
          def respond_to_missing?(*_) = true
        end
        nc.const_set(:DummyWindow, dummy)
      end

      # Patch singleton to return DummyWindow for any missing call.
      sc = nc.singleton_class
      unless sc.method_defined?(:method_missing)
        sc.define_method(:method_missing) { |_name, *_| nc::DummyWindow.new }
        sc.define_method(:respond_to_missing?) { |_n, _| true }
      end

      # Define harmless constants once.
      constants_map = {
        A_BLINK: 0, A_DIM: 0, A_BOLD: 0, A_UNDERLINE: 0,
        A_REVERSE: 0, A_STANDOUT: 0, COLORS: 1,
        KEY_LEFT: 260, KEY_RIGHT: 261, KEY_UP: 259, KEY_DOWN: 258
      }
      constants_map.each { |k, v| nc.const_set(k, v) unless nc.const_defined?(k) }

      true # signal successful 'require'
    else
      __orig_require__(name)
    end
  end
end 