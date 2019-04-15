require 'socket'
require 'aethyr/core/connection/telnet_codes'

class TelnetScanner

  def initialize(socket, display)
    @socket = socket
    @display = display
  end

  def supports_naws(does_it)
    if does_it
      log "Client supports NAWS"
    else
      log "Client does NOT support NAWS"
    end
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
          if ch == OPT_NAWS
            supports_naws(true)
          end
          iac_state = :none

        when :IAC_WONT
          if ch == OPT_NAWS
            supports_naws(false)
          end
          iac_state = :none

        when :IAC_SB
          if ch == OPT_NAWS
            iac_state = :IAC_SB_NAWS
          else
            iac_state = :IAC_SB_SOMETHING
          end

        when :IAC_DO
          iac_state = :none

        when :IAC_DONT
          iac_state = :none

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
