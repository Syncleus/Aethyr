require 'aethyr/core/errors'

#The purpose of this module is simply to clean up the PlayerConnection class a little.
#Provides all the methods that deal with the server menu and logging in/creating a character,
#
#Unfortunately, this means it also contains the receive_data method, which handles all input from the Player.
#So it does more than just the login stuff.
module Login

  #Get input from io connection and process it
  def receive_data
    return false if closed?
    data = @display.recv
    return false if data.nil?
    return false if data == ''

    if data[-1,1] != "\n"
      @in_buffer << data
      return true
    elsif not @in_buffer.empty?
      data = @in_buffer.join + data
      @in_buffer.clear
    end

    if data.strip == ''
      data.gsub!(/\n/, " \n")
    else
      data.strip!
    end

    data.split("\n").each do |d|
      if @expect_callback
        cb = @expect_callback
        @expect_callback = nil
        cb[d]
      elsif @editing
        editor_input d
      elsif @player
        @player.handle_input d
      else
        case @state
        when :initial
          show_resolution_prompt
        when :resolution
          do_resolution d
        when :server_menu
          do_server_menu d
        when :login_name
          login_name d
        when :login_password
          login_password d
        when :new_name
          new_name d
        when :new_password
          new_password d
        when :new_sex
          new_sex d
        when :new_color
          new_color d
        else
          log "wut"
        end
      end
    end
    return true
  end

  def show_initial
    show_resolution_prompt
  end

  #Show login menu
  def show_resolution_prompt
    output "Would you like color (Y/n)? "
    @state = :resolution
  end

  def do_resolution(data)
    data.strip!
    log "resolution getting done: #{data}"
    case data
    when  /([nNyY]{1})/
      display.init_colors if $1.downcase.eql? "y"
      show_server_menu
    when  ""
      display.init_colors
      show_server_menu
    else
      show_resolution_prompt
    end
  end

  #Show login menu
  def show_server_menu
    @state = :server_menu
    output "Please select an option or enter character name to login:"
    ["1. Login", "2. Create New Character", "3. Quit"].each do |x| output(x) end
  end

  #Handles menu input for main menu
  def do_server_menu(data)
    data.strip!
    case data
    when "1"
      self.print "Character name: ", false, false
      @state = :login_name
    when "2"
      ask_new_name
    when "3"
      output "Farewell!"
      close_connection_after_writing
    when  /[a-zA-Z]+/
      login_name(data)
    else
      show_server_menu
    end
  end

  #Checks login name and moves on to password if name is valid
  def login_name(name)
    name.strip!
    if name =~ /^[a-zA-Z]+$/ and $manager.player_exist? name
      @login_name = name
      self.print "Password: ", false, false
      @state = :login_password
    else
      self.output "Sorry, no such character."
      show_server_menu
    end
  end

  #Checks password AND tries to load character.
  def login_password(password)
    password.strip!

    begin
      player = $manager.load_player(@login_name, password)
    rescue MUDError::UnknownCharacter
      output "That character does not appear to exist."
      show_server_menu
      return
    rescue MUDError::BadPassword
      output "Incorrect password."
      @password_attempts += 1
      if @password_attempts > 3
        output "Too many incorrect passwords."
        close
      end
      login_name(@login_name)
      return
    rescue MUDError::CharacterAlreadyLoaded
      output "Character is already logged in."
      show_server_menu
      return
    end

    if player.nil?
      output "An error occurred when loading this character: #{@login_name.inspect}"
      show_server_menu
      return
    end

    @word_wrap = player.word_wrap
    player.set_connection(self)
    $manager.add_object(player)

    @player = player

    File.open("logs/player.log", "a") { |f| f.puts "#{Time.now} - #{@player.name} logged in from #{@ip_address}." }

    log "#{@player.name} logged in from #{@ip_address}"

    if @player.name.downcase == ServerConfig.admin.downcase
      @player.instance_variable_set(:@admin, true)
    end

    if File.exist? "motd.txt"
      @player.output("News:\n" << File.read("motd.txt"))
    end
  end

  #Asks for name of new character.
  def ask_new_name
    print "Desired character name:", false, false
    @state = :new_name
  end

  #Checks new name and moves on to sex
  def new_name(data)
    data.strip!
    if data.nil?
      ask_new_name
      return
    end

    data.capitalize!
    if $manager.player_exist? data
      output "A character with that name already exists, please choose another."
      ask_new_name
      return
    elsif data.length > 20 or data.length < 3
      output "Please choose a name less than 20 letters long but longer than 2 letters."
      ask_new_name
      return
    elsif data !~ /^[A-Z][a-z]+$/
      output "Only letters a to z, please."
      ask_new_name
      return
    end

    @new_name = data
    ask_sex
  end

  #Asks for sex of new character
  def ask_sex
    print 'Sex (M or F):', false, false
    @state = :new_sex
  end

  #Checks sex and moves on the password
  def new_sex(data)
    data.downcase.strip!
    unless data =~ /^(m|f)/i
      ask_sex
      return
    end

    @sex = data[0..1].downcase

    ask_password
  end

  #Asks password for new character.
  def ask_password
    @display.echo_off
    print 'Enter password (6 - 20 characters): ', false, false
    @state = :new_password
  end

  #Checks new password and moves on to color
  def new_password(data)
    data.strip!
    unless data =~ /^\w{6,20}$/
      ask_password
      return
    end
    @display.echo_on
    @new_password = data
    ask_color
  end

  #Asks color
  def ask_color
    print 'Use color (y/n): ', false, false
    @state = :new_color
  end

  #Checks color and moves on to create_new_player
  def new_color(data)
    data.strip!
    case data
    when /^y/i
      @use_color = true
    when /^n/i
      @use_color = false
    else
      ask_color
      return
    end

    create_new_player
  end

  #Creates a new player
  # TODO: This whole bit needs to be pulled out into extensions somehow since it depends on things in extensions
  def create_new_player
    @player = Aethyr::Core::Objects::Player.new(self, nil, ServerConfig.start_room, @new_name, [], "a typical person", "This is a normal, everyday kind of person.", "person", @sex)
    @player.word_wrap = nil

    # TODO remove following lines
    require 'aethyr/extensions/objects/clothing_items' #why not
    require 'aethyr/extensions/objects/sword'
    shirt = Aethyr::Extensions::Objects::Shirt.new
    pants = Aethyr::Extensions::Objects::Pants.new
    undies = Aethyr::Extensions::Objects::Underwear.new
    sword = Aethyr::Extensions::Objects::Sword.new

    $manager.add_object(shirt)
    $manager.add_object(undies)
    $manager.add_object(pants)
    $manager.add_object(sword)

    @player.inventory << shirt
    @player.inventory << pants
    @player.inventory << undies
    @player.inventory << sword

    @player.wear(undies)
    @player.wear(pants)
    @player.wear(shirt)

    if @player.name.downcase == ServerConfig.admin.downcase
      @player.instance_variable_set(:@admin, true)
    end

    $manager.add_player(@player, @new_password)

    File.open("logs/player.log", "a") { |f| f.puts "#{Time.now} - #{@player.name} logged in." }

    @state = nil

    output("Type HELP HELP for help.")
  end
end
