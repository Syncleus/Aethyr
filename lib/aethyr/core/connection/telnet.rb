require 'socket'
require 'aethyr/core/connection/telnet_codes'

class TelnetScanner
  PREAMBLE = [IAC + DO + OPT_LINEMODE,
              IAC + SB + OPT_LINEMODE + OPT_ECHO + OPT_BINARY + IAC + SE,
              IAC + WILL + OPT_ECHO,
              IAC + WILL + OPT_MSSP,
              IAC + WONT + OPT_COMPRESS2,
              IAC + DO + OPT_NAWS]

  def initialize(socket, display)
    @socket = socket
    @display = display
    @linemode_supported = false
    @naws_supported = false
    @echo_supported = false
  end

  def send_preamble
    PREAMBLE.each do |line|
      @socket.puts line
    end
  end

  def supports_naws(does_it)
    if does_it
      @supports_naws = true
      log "Client supports NAWS"
    else
      @supports_naws = false
      log "Client does NOT support NAWS"
    end
  end

  def send_mssp
    log "sending mssp"
    mssp_options = nil
    options = IAC + SB + OPT_MSSP

    if File.exist? "conf/mssp.yaml"
      File.open "conf/mssp.yaml" do |f|
        mssp_options = YAML.load(f)
      end

      mssp_options.each do |k,v|
        options << (MSSP_VAR + k + MSSP_VAL + v.to_s)
      end
    end

    options << (MSSP_VAR + "PLAYERS" + MSSP_VAL + $manager.find_all("class", Player).length.to_s)
    options << (MSSP_VAR + "UPTIME" + MSSP_VAL + $manager.uptime.to_s)
    options << (MSSP_VAR + "ROOMS" + MSSP_VAL + $manager.find_all("class", Room).length.to_s)
    options << (MSSP_VAR + "AREAS" + MSSP_VAL + $manager.find_all("class", Area).length.to_s)
    options << (MSSP_VAR + "ANSI" + MSSP_VAL + "1")
    options << (MSSP_VAR + "FAMILY" + MSSP_VAL + "CUSTOM")
    options << (MSSP_VAR + "CODEBASE" + MSSP_VAL + "Aethyr " + $AETHYR_VERSION)
    options << (MSSP_VAR + "PORT" + MSSP_VAL + ServerConfig.port.to_s)
    options << (MSSP_VAR + "MCCP" + MSSP_VAL + (ServerConfig[:mccp] ? "1" : "0"))
    options << (IAC + SE)
    @display.send_raw options
  end

  def process_iac
    log "doing process_iac"

    iac_state = :none if iac_state.nil?
    while ch = @socket.recv(1, Socket::MSG_PEEK) do
      ch = ch.chr
      log "processing #{ch.ord}"
      if iac_state == :none && ch == IAC
        @socket.recv(1)
        iac_state = :IAC
        next
      elsif iac_state == :none
          return true
      elsif iac_state != :none
        @socket.recv(1) if iac_state != IAC || ch != IAC
        case iac_state

        when :IAC
          if ch == WILL
            iac_state = :IAC_WILL
          elsif ch == SB
            iac_state = :IAC_SB
          elsif ch == WONT
            iac_state = :IAC_WONT
          elsif ch == DONT
            iac_state = :IAC_DONT
          elsif ch == DO
            iac_state = :IAC_DO
          elsif ch == IAC
            iac_state = :none
            return true
          else
            iac_state = :none
          end

        when :IAC_WILL
          if OPT_BINARY == ch
            @socket.puts(IAC + DO + OPT_BINARY)
          elsif ch == OPT_NAWS
            supports_naws(true)
          elsif ch == OPT_LINEMODE
            @linemode_supported = true
          elsif OPT_ECHO == ch
            @socket.puts(IAC + DONT + OPT_ECHO)
          elsif OPT_SGA  == ch
            @socket.puts(IAC + DO + OPT_SGA)
          else
            @socket.puts(IAC + DONT + ch)
          end
          iac_state = :none

        when :IAC_WONT
          if ch == OPT_LINEMODE
            @linemode_supported = false
          elsif ch == OPT_NAWS
            supports_naws(false)
          else
            @socket.puts(IAC + DONT + ch)
          end
          iac_state = :none

        when :IAC_DO
          if ch == OPT_BINARY
            @socket.puts(IAC + WILL + OPT_BINARY)
          elsif ch == OPT_ECHO
            @echo_supported = true
          elsif ch == OPT_MSSP
            send_mssp
            @mssp_supported = true
          else
            @socket.puts(IAC + WONT + ch)
          end
          iac_state = :none

        when :IAC_DONT
          if ch == OPT_ECHO
            @echo_supported = false
          elsif ch == OPT_COMPRESS2
            #do nothing
          elsif ch == OPT_MSSP
            @mssp_supported = false
          else
            @socket.puts(IAC + WONT + ch)
          end
          iac_state = :none

        when :IAC_SB
          if ch == OPT_NAWS
            iac_state = :IAC_SB_NAWS
          else
            iac_state = :IAC_SB_SOMETHING
          end

        when :IAC_SB_NAWS
          lwidth = ch.ord
          iac_state = :IAC_SB_NAWS_LWIDTH
          if ch == IAC && @socket.getch != IAC
            log "escaped IAC expected but not found"
            break
          end

        when :IAC_SB_NAWS_LWIDTH
          hwidth = ch.ord
          iac_state = :IAC_SB_NAWS_LWIDTH_HWIDTH
          if ch == IAC && @socket.getch != IAC
            log "escaped IAC expected but not found"
            break
          end

        when :IAC_SB_NAWS_LWIDTH_HWIDTH
          lheight = ch.ord
          iac_state = :IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT
          if ch == IAC && @socket.getch != IAC
            log "escaped IAC expected but not found"
            break
          end

        when :IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT
          hheight = ch.ord
          iac_state = :IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT
          if ch == IAC && @socket.getch != IAC
            log "escaped IAC expected but not found"
            break
          end

        when :IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT
          if ch == IAC
            iac_state = :IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT_IAC
          else
            log "invalid IAC"
            iac_state = :none
          end

        when :IAC_SB_NAWS_LWIDTH_HWIDTH_LHEIGHT_HHEIGHT_IAC
          if ch == SE
            new_width = lwidth*256 + hwidth
            new_height = lheight*256 + hheight
            log "setting resolution #{new_width} #{new_height}"
            @display.resolution = [new_width, new_height]
          else
            log "invalid IAC"
          end
          iac_state = :none
        when :IAC_SB_SOMETHING
          iac_state = :IAC_SB_SOMETHING_IAC if ch == IAC

        when :IAC_SB_SOMETHING_IAC
          iac_state = :IAC_SB_SOMETHING if ch == IAC
          iac_state = :none if ch == SE
        else
          iac_state = :none
        end
      else
        log "Invalid IAC logic #{iac_state} #{ch}"
        return false
      end
    end

    return false
  end
end
