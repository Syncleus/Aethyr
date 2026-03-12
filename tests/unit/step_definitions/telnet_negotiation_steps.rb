# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for Telnet Negotiation feature
#
# Tests TelnetScanner: IAC sequences, option negotiation (WILL/WONT/DO/DONT),
# subnegotiation, NAWS window-size, MSSP, and MCCP handling.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'yaml'

World(Test::Unit::Assertions)

# =============================================================================
# Mock objects
# =============================================================================

# A queue-based mock socket that simulates telnet byte-by-byte I/O.
# recv_nonblock(1, MSG_PEEK) peeks at the next byte; recv(1) consumes it.
class TelnetMockSocket
  attr_reader :sent_messages

  def initialize
    @queue = []
    @sent_messages = []
    @raise_ewouldblock = false
    @return_nil = false
  end

  def enqueue(byte_string)
    byte_string.each_byte { |b| @queue << b.chr }
  end

  def enqueue_byte(byte_val)
    @queue << byte_val.chr
  end

  def force_ewouldblock!
    @raise_ewouldblock = true
  end

  def force_nil!
    @return_nil = true
  end

  def recv_nonblock(len, flags = 0)
    raise Errno::EWOULDBLOCK if @raise_ewouldblock
    return nil if @return_nil
    return nil if @queue.empty?
    @queue.first
  end

  def recv(len)
    @queue.shift
  end

  def puts(data)
    @sent_messages << data
  end
end

# A mock display that records send_raw calls and resolution changes.
class TelnetMockDisplay
  attr_accessor :resolution
  attr_reader :raw_messages

  def initialize
    @raw_messages = []
    @resolution = nil
  end

  def send_raw(data)
    @raw_messages << data
  end
end

# =============================================================================
# World module – holds per-scenario state
# =============================================================================
module TelnetNegotiationWorld
  attr_accessor :telnet_scanner, :telnet_mock_socket, :telnet_mock_display,
                :telnet_iac_result
end
World(TelnetNegotiationWorld)

# =============================================================================
# Helpers for MSSP global stubs
# =============================================================================
module TelnetMSSPStubHelpers
  def setup_mssp_globals
    # Lightweight stand-ins for global objects that send_mssp references.
    @_saved_manager = $manager
    @_saved_version = $AETHYR_VERSION

    $AETHYR_VERSION = '1.0.0-test'

    mock_manager = Object.new
    def mock_manager.find_all(attr, klass)
      []
    end
    def mock_manager.uptime
      12345
    end
    $manager = mock_manager

    # Ensure ServerConfig responds to .port and .[]
    unless defined?(::ServerConfig)
      eval <<~RUBY, TOPLEVEL_BINDING
        module ServerConfig
          @data = {}
          class << self
            def [](k);       @data[k]; end
            def []=(k, v);   @data[k] = v; end
            def port;        4000; end
            def reset!;      @data.clear; end
          end
        end
      RUBY
    end

    # Add .port if missing
    unless ::ServerConfig.respond_to?(:port)
      ::ServerConfig.define_singleton_method(:port) { 4000 }
    end

    # Ensure :mccp key exists
    ::ServerConfig[:mccp] = false

    # Stub the Player/Room/Area constants that send_mssp references.
    Object.const_set(:Player, Class.new) unless defined?(::Player)
    Object.const_set(:Room,   Class.new) unless defined?(::Room)
    Object.const_set(:Area,   Class.new) unless defined?(::Area)
  end

  def teardown_mssp_globals
    $manager = @_saved_manager if defined?(@_saved_manager)
    $AETHYR_VERSION = @_saved_version if defined?(@_saved_version)
  end
end
World(TelnetMSSPStubHelpers)

After do
  teardown_mssp_globals if defined?(@_saved_manager)
  restore_mssp_yaml_stubs! if defined?(@_mssp_yaml_stubbed) && @_mssp_yaml_stubbed
end

# =============================================================================
# MSSP YAML file stubbing
# =============================================================================
module TelnetMSSPYamlStubHelpers
  def stub_mssp_yaml_present
    @_mssp_yaml_stubbed = true
    file_singleton = class << File; self; end

    unless file_singleton.method_defined?(:__telnet_original_exist__)
      file_singleton.alias_method :__telnet_original_exist__, :exist?
    end
    unless file_singleton.method_defined?(:__telnet_original_open__)
      file_singleton.alias_method :__telnet_original_open__, :open
    end

    file_singleton.define_method(:exist?) do |path|
      if path == 'conf/mssp.yaml'
        true
      else
        __telnet_original_exist__(path)
      end
    end

    file_singleton.define_method(:open) do |path, *args, &blk|
      if path == 'conf/mssp.yaml'
        yaml_content = "NAME: TestMUD\nGAMETYPE: MUD\n"
        io = StringIO.new(yaml_content)
        blk ? blk.call(io) : io
      else
        __telnet_original_open__(path, *args, &blk)
      end
    end
  end

  def restore_mssp_yaml_stubs!
    file_singleton = class << File; self; end
    if file_singleton.method_defined?(:__telnet_original_exist__)
      file_singleton.alias_method :exist?, :__telnet_original_exist__
      file_singleton.remove_method :__telnet_original_exist__
    end
    if file_singleton.method_defined?(:__telnet_original_open__)
      file_singleton.alias_method :open, :__telnet_original_open__
      file_singleton.remove_method :__telnet_original_open__
    end
    @_mssp_yaml_stubbed = false
  end
end
World(TelnetMSSPYamlStubHelpers)

# =============================================================================
#                          S T E P   D E F I N I T I O N S
# =============================================================================

# ── Background ───────────────────────────────────────────────────────────

Given('I require the telnet negotiation library') do
  require 'aethyr/core/connection/telnet'
end

# ── Construction ─────────────────────────────────────────────────────────

When('I create a telnet negotiation scanner with a mock socket') do
  self.telnet_mock_socket  = TelnetMockSocket.new
  self.telnet_mock_display = TelnetMockDisplay.new
  self.telnet_scanner      = TelnetScanner.new(telnet_mock_socket, telnet_mock_display)
end

Then('the telnet negotiation scanner should exist') do
  assert_not_nil telnet_scanner
end

# ── Preamble ─────────────────────────────────────────────────────────────

When('I send the telnet negotiation preamble') do
  telnet_scanner.send_preamble
end

Then('the telnet negotiation mock socket should have received {int} messages') do |count|
  assert_equal count, telnet_mock_socket.sent_messages.length,
               "Expected #{count} messages, got #{telnet_mock_socket.sent_messages.length}"
end

# ── NAWS support flag ────────────────────────────────────────────────────

When('I set telnet negotiation NAWS support to true') do
  telnet_scanner.supports_naws(true)
end

When('I set telnet negotiation NAWS support to false') do
  telnet_scanner.supports_naws(false)
end

Then('the telnet negotiation NAWS flag should be true') do
  assert_equal true, telnet_scanner.instance_variable_get(:@supports_naws)
end

Then('the telnet negotiation NAWS flag should be false') do
  assert_equal false, telnet_scanner.instance_variable_get(:@supports_naws)
end

# ── MSSP ─────────────────────────────────────────────────────────────────

When('I stub telnet negotiation globals for MSSP') do
  setup_mssp_globals
end

When('I send telnet negotiation MSSP data') do
  telnet_scanner.send_mssp
end

When('I stub telnet negotiation MSSP yaml file with data') do
  stub_mssp_yaml_present
end

Then('the telnet negotiation display should have received raw MSSP data') do
  assert telnet_mock_display.raw_messages.length > 0,
         'Expected display to have received raw MSSP data'
  # Verify the MSSP data contains the expected IAC SB OPT_MSSP prefix
  data = telnet_mock_display.raw_messages.last
  assert data.start_with?(IAC + SB + OPT_MSSP),
         'Expected MSSP data to start with IAC SB OPT_MSSP'
  assert data.end_with?(IAC + SE),
         'Expected MSSP data to end with IAC SE'
end

Then('I restore telnet negotiation MSSP yaml stubs') do
  restore_mssp_yaml_stubs!
end

# ── process_iac: edge cases ──────────────────────────────────────────────

When('the telnet negotiation socket raises EWOULDBLOCK on peek') do
  telnet_mock_socket.force_ewouldblock!
end

When('the telnet negotiation socket returns nil on peek') do
  telnet_mock_socket.force_nil!
end

When('I call telnet negotiation process_iac') do
  self.telnet_iac_result = telnet_scanner.process_iac
end

Then('the telnet negotiation result should be false') do
  assert_equal false, telnet_iac_result
end

Then('the telnet negotiation result should be true') do
  assert_equal true, telnet_iac_result
end

# ── Queuing bytes ────────────────────────────────────────────────────────

When('I queue telnet negotiation bytes {string}') do |str|
  telnet_mock_socket.enqueue(str)
end

When('I queue telnet negotiation raw byte IAC') do
  telnet_mock_socket.enqueue(IAC)
end

When('I queue telnet negotiation raw byte WILL') do
  telnet_mock_socket.enqueue(WILL)
end

When('I queue telnet negotiation raw byte WONT') do
  telnet_mock_socket.enqueue(WONT)
end

When('I queue telnet negotiation raw byte DO') do
  telnet_mock_socket.enqueue(DO)
end

When('I queue telnet negotiation raw byte DONT') do
  telnet_mock_socket.enqueue(DONT)
end

When('I queue telnet negotiation raw byte SB') do
  telnet_mock_socket.enqueue(SB)
end

When('I queue telnet negotiation raw byte SE') do
  telnet_mock_socket.enqueue(SE)
end

When('I queue telnet negotiation raw byte NOP') do
  telnet_mock_socket.enqueue(NOP)
end

When('I queue telnet negotiation raw byte OPT_BINARY') do
  telnet_mock_socket.enqueue(OPT_BINARY)
end

When('I queue telnet negotiation raw byte OPT_NAWS') do
  telnet_mock_socket.enqueue(OPT_NAWS)
end

When('I queue telnet negotiation raw byte OPT_LINEMODE') do
  telnet_mock_socket.enqueue(OPT_LINEMODE)
end

When('I queue telnet negotiation raw byte OPT_ECHO') do
  telnet_mock_socket.enqueue(OPT_ECHO)
end

When('I queue telnet negotiation raw byte OPT_SGA') do
  telnet_mock_socket.enqueue(OPT_SGA)
end

When('I queue telnet negotiation raw byte OPT_TTYPE') do
  telnet_mock_socket.enqueue(OPT_TTYPE)
end

When('I queue telnet negotiation raw byte OPT_COMPRESS2') do
  telnet_mock_socket.enqueue(OPT_COMPRESS2)
end

When('I queue telnet negotiation raw byte OPT_MSSP') do
  telnet_mock_socket.enqueue(OPT_MSSP)
end

When('I queue telnet negotiation byte value {int}') do |val|
  telnet_mock_socket.enqueue_byte(val)
end

# ── IAC state manipulation ───────────────────────────────────────────────

When('I set telnet negotiation IAC state to {string}') do |state_name|
  telnet_scanner.instance_variable_set(:@iac_state, state_name.to_sym)
end

Then('the telnet negotiation IAC state should be {string}') do |expected|
  actual = telnet_scanner.instance_variable_get(:@iac_state)
  assert_equal expected.to_sym, actual,
               "Expected IAC state :#{expected}, got :#{actual}"
end

# ── IAC_WILL response assertions ─────────────────────────────────────────

Then('the telnet negotiation mock socket should have sent DO OPT_BINARY') do
  assert telnet_mock_socket.sent_messages.include?(IAC + DO + OPT_BINARY),
         'Expected socket to have sent IAC DO OPT_BINARY'
end

Then('the telnet negotiation mock socket should have sent DONT OPT_ECHO') do
  assert telnet_mock_socket.sent_messages.include?(IAC + DONT + OPT_ECHO),
         'Expected socket to have sent IAC DONT OPT_ECHO'
end

Then('the telnet negotiation mock socket should have sent DO OPT_SGA') do
  assert telnet_mock_socket.sent_messages.include?(IAC + DO + OPT_SGA),
         'Expected socket to have sent IAC DO OPT_SGA'
end

Then('the telnet negotiation mock socket should have sent DONT OPT_TTYPE') do
  assert telnet_mock_socket.sent_messages.include?(IAC + DONT + OPT_TTYPE),
         'Expected socket to have sent IAC DONT OPT_TTYPE'
end

# ── IAC_WONT response assertions ────────────────────────────────────────

Then('the telnet negotiation mock socket should have sent DONT OPT_TTYPE response') do
  # WONT handler also sends IAC DONT for unknown options
  assert telnet_mock_socket.sent_messages.include?(IAC + DONT + OPT_TTYPE),
         'Expected socket to have sent IAC DONT OPT_TTYPE in WONT response'
end

# ── IAC_DO response assertions ──────────────────────────────────────────

Then('the telnet negotiation mock socket should have sent WILL OPT_BINARY') do
  assert telnet_mock_socket.sent_messages.include?(IAC + WILL + OPT_BINARY),
         'Expected socket to have sent IAC WILL OPT_BINARY'
end

Then('the telnet negotiation mock socket should have sent WONT OPT_TTYPE') do
  assert telnet_mock_socket.sent_messages.include?(IAC + WONT + OPT_TTYPE),
         'Expected socket to have sent IAC WONT OPT_TTYPE'
end

# ── IAC_DONT response assertions ────────────────────────────────────────

Then('the telnet negotiation mock socket should have sent WONT OPT_TTYPE response') do
  assert telnet_mock_socket.sent_messages.include?(IAC + WONT + OPT_TTYPE),
         'Expected socket to have sent IAC WONT OPT_TTYPE in DONT response'
end

# ── Flag assertions ──────────────────────────────────────────────────────

Then('the telnet negotiation linemode flag should be true') do
  assert_equal true, telnet_scanner.instance_variable_get(:@linemode_supported)
end

Then('the telnet negotiation linemode flag should be false') do
  assert_equal false, telnet_scanner.instance_variable_get(:@linemode_supported)
end

Then('the telnet negotiation echo flag should be true') do
  assert_equal true, telnet_scanner.instance_variable_get(:@echo_supported)
end

Then('the telnet negotiation echo flag should be false') do
  assert_equal false, telnet_scanner.instance_variable_get(:@echo_supported)
end

Then('the telnet negotiation MSSP flag should be true') do
  assert_equal true, telnet_scanner.instance_variable_get(:@mssp_supported)
end

Then('the telnet negotiation MSSP flag should be false') do
  assert_equal false, telnet_scanner.instance_variable_get(:@mssp_supported)
end

# ── Full NAWS sequence ──────────────────────────────────────────────────

When('I feed a telnet negotiation full NAWS sequence for width {int} and height {int}') do |w, h|
  # Width and height are 16-bit: high-byte * 256 + low-byte
  lwidth  = w / 256
  hwidth  = w % 256
  lheight = h / 256
  hheight = h % 256

  # Build the full sequence: IAC SB OPT_NAWS lw hw lh hh IAC SE
  bytes = [IAC, SB, OPT_NAWS,
           lwidth.chr, hwidth.chr,
           lheight.chr, hheight.chr,
           IAC, SE]

  bytes.each do |b|
    telnet_mock_socket.enqueue(b)
    telnet_scanner.process_iac
  end
end

Then('the telnet negotiation display resolution should be {int} by {int}') do |w, h|
  assert_not_nil telnet_mock_display.resolution,
                 'Expected display resolution to be set'
  assert_equal [w, h], telnet_mock_display.resolution,
               "Expected resolution [#{w}, #{h}], got #{telnet_mock_display.resolution.inspect}"
end

# ── NAWS dimension pre-setting (for SE completion test) ──────────────────

When('I set telnet negotiation NAWS dimensions to lw {int} hw {int} lh {int} hh {int}') do |lw, hw, lh, hh|
  telnet_scanner.instance_variable_set(:@lwidth,  lw)
  telnet_scanner.instance_variable_set(:@hwidth,  hw)
  telnet_scanner.instance_variable_set(:@lheight, lh)
  telnet_scanner.instance_variable_set(:@hheight, hh)
end

# ── Error assertions ─────────────────────────────────────────────────────

Then('calling telnet negotiation process_iac should raise {string}') do |message|
  error = assert_raises(RuntimeError) { telnet_scanner.process_iac }
  assert_match(/#{Regexp.escape(message)}/, error.message,
               "Expected error message to include '#{message}', got '#{error.message}'")
end

Then('calling telnet negotiation process_iac should raise an error') do
  raised = false
  begin
    telnet_scanner.process_iac
  rescue => e
    raised = true
  end
  assert raised, 'Expected process_iac to raise an error'
end
