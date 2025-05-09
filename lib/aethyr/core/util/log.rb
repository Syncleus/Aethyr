#Simplistic logging with buffer and autodeletion of the log when it gets too big.
class Logger
  Ultimate = 3
  Medium = 2
  Normal = 1
  Important = 0

  def initialize(log_file = "logs/system.log", buffer_size = 45, buffer_time = 300, max_log_size = 50000000)
    ServerConfig[:log_level] ||= 1
    @last_dump = Time.now
    @entries = []
    @log_file = log_file
    @buffer_size = buffer_size
    @buffer_time = buffer_time
    @max_log_size = max_log_size
  end

  # Log an entry to the in-memory buffer and optionally force a buffer dump.
  #
  # Parameters
  # ----------
  # log_level : Integer
  #     The severity level of the log.  Higher values correspond to
  #     less-important messages.  The constants `Ultimate`, `Medium`,
  #     `Normal`, and `Important` provide convenient severity shortcuts.
  # msg : String, nil
  #     The formatted message to be logged.  If `nil` and a block is
  #     given, the block will be executed and the returned value will be
  #     used as the message.  If both are `nil`, the call is ignored.
  # progname : String, nil
  #     A short label generally indicating which subsystem produced the
  #     log entry.  Present only for compatibility with the standard
  #     Ruby ::Logger API – it is currently ignored by this implementation.
  # dump_log : Boolean
  #     When `true`, forces a call to `dump` immediately after the log
  #     entry is added.
  #
  # Notes
  # -----
  # This signature mirrors the standard Ruby `Logger#add` API to make it
  # easier for consumers and tooling to interoperate.  The additional
  # keyword `dump_log` provides explicit control over flushing behaviour
  # without overloading positional arguments.
  def add(log_level, msg = nil, progname = nil, dump_log: false)

    # Lazily evaluate the message from an optional block when not
    # explicitly supplied – keeping the call semantics consistent with
    # ::Logger#add.
    msg = yield if msg.nil? && block_given?

    # Guard against cases where no meaningful message was supplied even
    # after evaluating the block.
    return if msg.nil?

    if ServerConfig[:log_level] && log_level <= ServerConfig[:log_level]
      $stderr.puts msg

      @entries << msg

      if dump_log || @entries.length > @buffer_size || (Time.now - @last_dump > @buffer_time)
        self.dump
      end
    end
  end

  #Write buffered logs to disk, check if log file is too large.
  def dump
    unless @entries.empty?
      if File.exist?(@log_file) and File.size(@log_file) > @max_log_size
        @entries << "!!!DELETED LOG FILE - SIZE: #{File.size(@log_file)}"
        File.delete(@log_file)
      end

      File.open(@log_file, "a") do |f|
        f.puts @entries
      end
    end
    self.clear
  end

  #Empty buffer (assumes already wrote to disk).
  def clear
    num_entries = @entries.length
    @entries.clear
    @last_dump = Time.now
    GC.start
  end

  # Convenience operator so callers can use `$LOG << "message"` which
  # will log at the default `Normal` severity.
  def <<(msg)
    add(Normal, msg)
  end
end

unless Object.respond_to? :log, true

  class Object

    #Log a message and optionally force writing to disk.
    def log(msg, log_level = Logger::Normal, dump_log = false)
      # Construct a consistent timestamped log message.
      logmsg = "[#{Time.now.strftime("%x %X")} #{self.class}#{(defined? GameObject and self.is_a? GameObject) ? " #{self.name}" : ""}]: " + msg.to_s

      $LOG ||= Logger.new

      # The new signature expects the severity first followed by the
      # message.
      $LOG.add(log_level, logmsg, nil, dump_log: dump_log)
    end

    private :log
  end
end
