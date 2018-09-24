module TextUtil

  #Only use if there is no line height
  def wrap(message, width = 80)
    return [message] if message.length < width
    
    message = message.dup
    
    escape_regex = /\A\e\[\d+[\;]{0,1}\d*[\;]{0,1}\d*m/
    
    lines = []
    line = ""
    buffer = ""
    buffer_count = 0
    line_count = 0
    while message.length > 0
      if message =~ escape_regex
        message.gsub!(escape_regex) do |match|
          buffer += match
          ""
        end
        next
      end
      
      if (message.start_with? "\r\n") or (message.start_with? "\n\r")
        lines << line + buffer
        line = ""
        buffer = ""
        line_count = 0
        buffer_count = 0;
        message[0] = ""
        message[0] = ""
        next
      elsif (message.start_with? "\r") or (message.start_with? "\n")
        lines << line + buffer
        line = ""
        buffer = ""
        line_count = 0
        buffer_count = 0;
        message[0] = ""
        next
      end
      
      buffer += shift(message)
      buffer_count += 1
      
      if buffer.end_with? " "
        line += buffer
        line_count += buffer_count
        
        buffer = ""
        buffer_count = 0
      end
      
      if ((line_count + buffer_count) > width) and (line_count > 0)
        lines << line
        line = ""
        line_count = 0
      end
      
      if buffer_count == width
        lines << buffer
        buffer = ""
        buffer_count = 0
      end
    end
    
    lines << (line + buffer)
    return lines
  end
  
  private
  def shift(message)
    result = message[0]
    message[0] = ""
    result
  end
end