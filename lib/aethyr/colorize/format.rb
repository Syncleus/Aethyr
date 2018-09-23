#ANSI colors.
module Color
  module Formatting
    @@attributes = [
    [ :bold, "\e[1m"],  
    [ :dim, "\e[2m"],
    [ :underlined, "\e[4m"],
    [ :blink, "\e[5m"],
    [ :reverse, "\e[7m"]
    ]
    
    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end
    
    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end
    
    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end
  
  module Reset
    @@attributes = [
    [ :all, "\e[0m"],
    [ :bold, "\e[21m"],  
    [ :dim, "\e[22m"],
    [ :underlined, "\e[24m"],
    [ :blink, "\e[25m"],
    [ :reverse, "\e[27m"]
    ]
    
    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end
    
    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end
    
    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end
  
#  module Foreground_8
#    @@attributes = [
#    [ :black, "\e[30m"],
#    [ :red, "\e[31m"],
#    [ :green, "\e[32m"],
#    [ :yellow, "\e[33m"],
#    [ :blue, "\e[34m"],
#    [ :magenta, "\e[35m"],
#    [ :cyan, "\e[36m"],
#    [ :light_gray, "\e[37m"]
#    ]
#  end
#  
#  module Background_8
#    @@attributes = [
#    [ :black, "\e[40m"],
#    [ :red, "\e[41m"],
#    [ :green, "\e[42m"],
#    [ :yellow, "\e[43m"],
#    [ :blue, "\e[44m"],
#    [ :magenta, "\e[45m"],
#    [ :cyan, "\e[46m"],
#    [ :light_gray, "\e[47m"]
#    ]
#  end
#  
#  module Foreground_16
#    include Color::Foreground_8
#    @@attributes =[
#    [ :dark_gray, "\e[90m"],
#    [ :light_red, "\e[91m"],
#    [ :light_green, "\e[92m"],
#    [ :light_yellow, "\e[93m"],
#    [ :light_blue, "\e[94m"],
#    [ :light_magenta, "\e[95m"],
#    [ :light_cyan, "\e[96m"],
#    [ :white, "\e[97m"]
#    ]
#  end
#  
#  module Background_16
#    include Color::Background_8
#    @@attributes = [
#    [ :dark_gray, "\e[100m"],
#    [ :light_red, "\e[101m"],
#    [ :light_green, "\e[102m"],
#    [ :light_yellow, "\e[103m"],
#    [ :light_blue, "\e[104m"],
#    [ :light_magenta, "\e[105m"],
#    [ :light_cyan, "\e[106m"],
#    [ :white, "\e[107m"]
#    ]
#  end
  
  module Foreground
    @@attributes = [
    [ :magenta, "\e[35m"],
    [ :cyan, "\e[36m"],
    [ :light_gray, "\e[37m"],
    [ :dark_gray, "\e[90m"],
    [ :light_red, "\e[91m"],
    [ :light_green, "\e[92m"],
    [ :light_yellow, "\e[93m"],
    [ :light_blue, "\e[94m"],
    [ :light_magenta, "\e[95m"],
    [ :light_cyan, "\e[96m"],
    [ :black, "\e[38;5;0m"],
    [ :maroon, "\e[38;5;1m"],
    [ :green, "\e[38;5;2m"],
    [ :olive, "\e[38;5;3m"],
    [ :navy, "\e[38;5;4m"],
    [ :purple, "\e[38;5;5m"],
    [ :teal, "\e[38;5;6m"],
    [ :silver, "\e[38;5;7m"],
    [ :grey, "\e[38;5;8m"],
    [ :red, "\e[38;5;9m"],
    [ :lime, "\e[38;5;10m"],
    [ :yellow, "\e[38;5;11m"],
    [ :blue, "\e[38;5;12m"],
    [ :fuchsia, "\e[38;5;13m"],
    [ :aqua, "\e[38;5;14m"],
    [ :white, "\e[38;5;15m"],
    [ :grey_0, "\e[38;5;16m"],
    [ :navy_blue, "\e[38;5;17m"],
    [ :dark_blue, "\e[38;5;18m"],
    [ :blue_3, "\e[38;5;19m"],
    [ :blue_3, "\e[38;5;20m"],
    [ :blue_1, "\e[38;5;21m"],
    [ :dark_green, "\e[38;5;22m"],
    [ :deep_sky_blue_4, "\e[38;5;23m"],
    [ :deep_sky_blue_4, "\e[38;5;24m"],
    [ :deep_sky_blue_4, "\e[38;5;25m"],
    [ :dodger_blue_3, "\e[38;5;26m"],
    [ :dodger_blue_2, "\e[38;5;27m"],
    [ :green_4, "\e[38;5;28m"],
    [ :spring_green_4, "\e[38;5;29m"],
    [ :turquoise_4, "\e[38;5;30m"],
    [ :deep_sky_blue_3, "\e[38;5;31m"],
    [ :deep_sky_blue_3, "\e[38;5;32m"],
    [ :dodger_blue_1, "\e[38;5;33m"],
    [ :green_3, "\e[38;5;34m"],
    [ :spring_green_3, "\e[38;5;35m"],
    [ :dark_cyan, "\e[38;5;36m"],
    [ :light_sea_green, "\e[38;5;37m"],
    [ :deep_sky_blue_2, "\e[38;5;38m"],
    [ :deep_sky_blue_1, "\e[38;5;39m"],
    [ :green_3, "\e[38;5;40m"],
    [ :spring_green_3, "\e[38;5;41m"],
    [ :spring_green_2, "\e[38;5;42m"],
    [ :cyan_3, "\e[38;5;43m"],
    [ :dark_turquoise, "\e[38;5;44m"],
    [ :turquoise_2, "\e[38;5;45m"],
    [ :green_1, "\e[38;5;46m"],
    [ :spring_green_2, "\e[38;5;47m"],
    [ :spring_green_1, "\e[38;5;48m"],
    [ :medium_spring_green, "\e[38;5;49m"],
    [ :cyan_2, "\e[38;5;50m"],
    [ :cyan_1, "\e[38;5;51m"],
    [ :dark_red, "\e[38;5;52m"],
    [ :deep_pink_4, "\e[38;5;53m"],
    [ :purple_4, "\e[38;5;54m"],
    [ :purple_4, "\e[38;5;55m"],
    [ :purple_3, "\e[38;5;56m"],
    [ :blue_violet, "\e[38;5;57m"],
    [ :orange_4, "\e[38;5;58m"],
    [ :grey_37, "\e[38;5;59m"],
    [ :medium_purple_4, "\e[38;5;60m"],
    [ :slate_blue_3, "\e[38;5;61m"],
    [ :slate_blue_3, "\e[38;5;62m"],
    [ :royal_blue_1, "\e[38;5;63m"],
    [ :chartreuse_4, "\e[38;5;64m"],
    [ :dark_sea_green_4, "\e[38;5;65m"],
    [ :pale_turquoise_4, "\e[38;5;66m"],
    [ :steel_blue, "\e[38;5;67m"],
    [ :steel_blue_3, "\e[38;5;68m"],
    [ :cornflower_blue, "\e[38;5;69m"],
    [ :chartreuse_3, "\e[38;5;70m"],
    [ :dark_sea_green_4, "\e[38;5;71m"],
    [ :cadet_blue, "\e[38;5;72m"],
    [ :cadet_blue, "\e[38;5;73m"],
    [ :sky_blue_3, "\e[38;5;74m"],
    [ :steel_blue_1, "\e[38;5;75m"],
    [ :chartreuse_3, "\e[38;5;76m"],
    [ :pale_green_3, "\e[38;5;77m"],
    [ :sea_green_3, "\e[38;5;78m"],
    [ :aquamarine_3, "\e[38;5;79m"],
    [ :medium_turquoise, "\e[38;5;80m"],
    [ :steel_blue_1, "\e[38;5;81m"],
    [ :chartreuse_2, "\e[38;5;82m"],
    [ :sea_green_2, "\e[38;5;83m"],
    [ :sea_green_1, "\e[38;5;84m"],
    [ :sea_green_1, "\e[38;5;85m"],
    [ :aquamarine_1, "\e[38;5;86m"],
    [ :dark_slate_gray_2, "\e[38;5;87m"],
    [ :dark_red, "\e[38;5;88m"],
    [ :deep_pink_4, "\e[38;5;89m"],
    [ :dark_magenta, "\e[38;5;90m"],
    [ :dark_magenta, "\e[38;5;91m"],
    [ :dark_violet, "\e[38;5;92m"],
    [ :purple, "\e[38;5;93m"],
    [ :orange_4, "\e[38;5;94m"],
    [ :light_pink_4, "\e[38;5;95m"],
    [ :plum_4, "\e[38;5;96m"],
    [ :medium_purple_3, "\e[38;5;97m"],
    [ :medium_purple_3, "\e[38;5;98m"],
    [ :slate_blue_1, "\e[38;5;99m"],
    [ :yellow_4, "\e[38;5;100m"],
    [ :wheat_4, "\e[38;5;101m"],
    [ :grey_53, "\e[38;5;102m"],
    [ :light_slate_grey, "\e[38;5;103m"],
    [ :medium_purple, "\e[38;5;104m"],
    [ :light_slate_blue, "\e[38;5;105m"],
    [ :yellow_4, "\e[38;5;106m"],
    [ :dark_olive_green_3, "\e[38;5;107m"],
    [ :dark_sea_green, "\e[38;5;108m"],
    [ :light_sky_blue_3, "\e[38;5;109m"],
    [ :light_sky_blue_3, "\e[38;5;110m"],
    [ :sky_blue_2, "\e[38;5;111m"],
    [ :chartreuse_2, "\e[38;5;112m"],
    [ :dark_olive_green_3, "\e[38;5;113m"],
    [ :pale_green_3, "\e[38;5;114m"],
    [ :dark_sea_green_3, "\e[38;5;115m"],
    [ :dark_slate_gray_3, "\e[38;5;116m"],
    [ :sky_blue_1, "\e[38;5;117m"],
    [ :chartreuse_1, "\e[38;5;118m"],
    [ :light_green_1, "\e[38;5;119m"],
    [ :light_green_2, "\e[38;5;120m"],
    [ :pale_green_1, "\e[38;5;121m"],
    [ :aquamarine_1, "\e[38;5;122m"],
    [ :dark_slate_gray_1, "\e[38;5;123m"],
    [ :red_3, "\e[38;5;124m"],
    [ :deep_pink_4, "\e[38;5;125m"],
    [ :medium_violet_red, "\e[38;5;126m"],
    [ :magenta_3, "\e[38;5;127m"],
    [ :dark_violet, "\e[38;5;128m"],
    [ :purple, "\e[38;5;129m"],
    [ :dark_orange_3, "\e[38;5;130m"],
    [ :indian_red, "\e[38;5;131m"],
    [ :hot_pink_3, "\e[38;5;132m"],
    [ :medium_orchid_3, "\e[38;5;133m"],
    [ :medium_orchid, "\e[38;5;134m"],
    [ :medium_purple_2, "\e[38;5;135m"],
    [ :dark_goldenrod, "\e[38;5;136m"],
    [ :light_salmon_3, "\e[38;5;137m"],
    [ :rosy_brown, "\e[38;5;138m"],
    [ :grey_63, "\e[38;5;139m"],
    [ :medium_purple_2, "\e[38;5;140m"],
    [ :medium_purple_1, "\e[38;5;141m"],
    [ :gold_3, "\e[38;5;142m"],
    [ :dark_khaki, "\e[38;5;143m"],
    [ :navajo_white_3, "\e[38;5;144m"],
    [ :grey_69, "\e[38;5;145m"],
    [ :light_steel_blue_3, "\e[38;5;146m"],
    [ :light_steel_blue, "\e[38;5;147m"],
    [ :yellow_3, "\e[38;5;148m"],
    [ :dark_olive_green_3, "\e[38;5;149m"],
    [ :dark_sea_green_3, "\e[38;5;150m"],
    [ :dark_sea_green_2, "\e[38;5;151m"],
    [ :light_cyan_3, "\e[38;5;152m"],
    [ :light_sky_blue_1, "\e[38;5;153m"],
    [ :green_yellow, "\e[38;5;154m"],
    [ :dark_olive_green_2, "\e[38;5;155m"],
    [ :pale_green_1, "\e[38;5;156m"],
    [ :dark_sea_green_2, "\e[38;5;157m"],
    [ :dark_sea_green_1, "\e[38;5;158m"],
    [ :pale_turquoise_1, "\e[38;5;159m"],
    [ :red_3, "\e[38;5;160m"],
    [ :deep_pink_3, "\e[38;5;161m"],
    [ :deep_pink_3, "\e[38;5;162m"],
    [ :magenta_3, "\e[38;5;163m"],
    [ :magenta_3, "\e[38;5;164m"],
    [ :magenta_2, "\e[38;5;165m"],
    [ :dark_orange_3, "\e[38;5;166m"],
    [ :indian_red, "\e[38;5;167m"],
    [ :hot_pink_3, "\e[38;5;168m"],
    [ :hot_pink_2, "\e[38;5;169m"],
    [ :orchid, "\e[38;5;170m"],
    [ :medium_orchid_1, "\e[38;5;171m"],
    [ :orange_3, "\e[38;5;172m"],
    [ :light_salmon_3, "\e[38;5;173m"],
    [ :light_pink_3, "\e[38;5;174m"],
    [ :pink_3, "\e[38;5;175m"],
    [ :plum_3, "\e[38;5;176m"],
    [ :violet, "\e[38;5;177m"],
    [ :gold_3, "\e[38;5;178m"],
    [ :light_goldenrod_3, "\e[38;5;179m"],
    [ :tan, "\e[38;5;180m"],
    [ :misty_rose_3, "\e[38;5;181m"],
    [ :thistle_3, "\e[38;5;182m"],
    [ :plum_2, "\e[38;5;183m"],
    [ :yellow_3, "\e[38;5;184m"],
    [ :khaki_3, "\e[38;5;185m"],
    [ :light_goldenrod_2, "\e[38;5;186m"],
    [ :light_yellow_3, "\e[38;5;187m"],
    [ :grey_84, "\e[38;5;188m"],
    [ :light_steel_blue_1, "\e[38;5;189m"],
    [ :yellow_2, "\e[38;5;190m"],
    [ :dark_olive_green_1, "\e[38;5;191m"],
    [ :dark_olive_green_1, "\e[38;5;192m"],
    [ :dark_sea_green_1, "\e[38;5;193m"],
    [ :honeydew_2, "\e[38;5;194m"],
    [ :light_cyan_1, "\e[38;5;195m"],
    [ :red_1, "\e[38;5;196m"],
    [ :deep_pink_2, "\e[38;5;197m"],
    [ :deep_pink_1, "\e[38;5;198m"],
    [ :deep_pink_1, "\e[38;5;199m"],
    [ :magenta_2, "\e[38;5;200m"],
    [ :magenta_1, "\e[38;5;201m"],
    [ :orange_red_1, "\e[38;5;202m"],
    [ :indian_red_1, "\e[38;5;203m"],
    [ :indian_red_1, "\e[38;5;204m"],
    [ :hot_pink, "\e[38;5;205m"],
    [ :hot_pink, "\e[38;5;206m"],
    [ :medium_orchid_1, "\e[38;5;207m"],
    [ :dark_orange, "\e[38;5;208m"],
    [ :salmon_1, "\e[38;5;209m"],
    [ :light_coral, "\e[38;5;210m"],
    [ :pale_violet_red_1, "\e[38;5;211m"],
    [ :orchid_2, "\e[38;5;212m"],
    [ :orchid_1, "\e[38;5;213m"],
    [ :orange_1, "\e[38;5;214m"],
    [ :sandy_brown, "\e[38;5;215m"],
    [ :light_salmon_1, "\e[38;5;216m"],
    [ :light_pink_1, "\e[38;5;217m"],
    [ :pink_1, "\e[38;5;218m"],
    [ :plum_1, "\e[38;5;219m"],
    [ :gold_1, "\e[38;5;220m"],
    [ :light_goldenrod_2, "\e[38;5;221m"],
    [ :light_goldenrod_2, "\e[38;5;222m"],
    [ :navajo_white_1, "\e[38;5;223m"],
    [ :misty_rose_1, "\e[38;5;224m"],
    [ :thistle_1, "\e[38;5;225m"],
    [ :yellow_1, "\e[38;5;226m"],
    [ :light_goldenrod_1, "\e[38;5;227m"],
    [ :khaki_1, "\e[38;5;228m"],
    [ :wheat_1, "\e[38;5;229m"],
    [ :cornsilk_1, "\e[38;5;230m"],
    [ :grey_100, "\e[38;5;231m"],
    [ :grey_3, "\e[38;5;232m"],
    [ :grey_7, "\e[38;5;233m"],
    [ :grey_11, "\e[38;5;234m"],
    [ :grey_15, "\e[38;5;235m"],
    [ :grey_19, "\e[38;5;236m"],
    [ :grey_23, "\e[38;5;237m"],
    [ :grey_27, "\e[38;5;238m"],
    [ :grey_30, "\e[38;5;239m"],
    [ :grey_35, "\e[38;5;240m"],
    [ :grey_39, "\e[38;5;241m"],
    [ :grey_42, "\e[38;5;242m"],
    [ :grey_46, "\e[38;5;243m"],
    [ :grey_50, "\e[38;5;244m"],
    [ :grey_54, "\e[38;5;245m"],
    [ :grey_58, "\e[38;5;246m"],
    [ :grey_62, "\e[38;5;247m"],
    [ :grey_66, "\e[38;5;248m"],
    [ :grey_70, "\e[38;5;249m"],
    [ :grey_74, "\e[38;5;250m"],
    [ :grey_78, "\e[38;5;251m"],
    [ :grey_82, "\e[38;5;252m"],
    [ :grey_85, "\e[38;5;253m"],
    [ :grey_89, "\e[38;5;254m"],
    [ :grey_93, "\e[38;5;255m"]
    ]
    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end
    
    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end
    
    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end
  
  module Background
    @@attributes = [
    [ :magenta, "\e[45m"],
    [ :cyan, "\e[46m"],
    [ :light_gray, "\e[47m"],
    [ :dark_gray, "\e[100m"],
    [ :light_red, "\e[101m"],
    [ :light_green, "\e[102m"],
    [ :light_yellow, "\e[103m"],
    [ :light_blue, "\e[104m"],
    [ :light_magenta, "\e[105m"],
    [ :light_cyan, "\e[106m"],
    [ :black, "\e[48;5;0m"],
    [ :maroon, "\e[48;5;1m"],
    [ :green, "\e[48;5;2m"],
    [ :olive, "\e[48;5;3m"],
    [ :navy, "\e[48;5;4m"],
    [ :purple, "\e[48;5;5m"],
    [ :teal, "\e[48;5;6m"],
    [ :silver, "\e[48;5;7m"],
    [ :grey, "\e[48;5;8m"],
    [ :red, "\e[48;5;9m"],
    [ :lime, "\e[48;5;10m"],
    [ :yellow, "\e[48;5;11m"],
    [ :blue, "\e[48;5;12m"],
    [ :fuchsia, "\e[48;5;13m"],
    [ :aqua, "\e[48;5;14m"],
    [ :white, "\e[48;5;15m"],
    [ :grey_0, "\e[48;5;16m"],
    [ :navy_blue, "\e[48;5;17m"],
    [ :dark_blue, "\e[48;5;18m"],
    [ :blue_3, "\e[48;5;19m"],
    [ :blue_3, "\e[48;5;20m"],
    [ :blue_1, "\e[48;5;21m"],
    [ :dark_green, "\e[48;5;22m"],
    [ :deep_sky_blue_4, "\e[48;5;23m"],
    [ :deep_sky_blue_4, "\e[48;5;24m"],
    [ :deep_sky_blue_4, "\e[48;5;25m"],
    [ :dodger_blue_3, "\e[48;5;26m"],
    [ :dodger_blue_2, "\e[48;5;27m"],
    [ :green_4, "\e[48;5;28m"],
    [ :spring_green_4, "\e[48;5;29m"],
    [ :turquoise_4, "\e[48;5;30m"],
    [ :deep_sky_blue_3, "\e[48;5;31m"],
    [ :deep_sky_blue_3, "\e[48;5;32m"],
    [ :dodger_blue_1, "\e[48;5;33m"],
    [ :green_3, "\e[48;5;34m"],
    [ :spring_green_3, "\e[48;5;35m"],
    [ :dark_cyan, "\e[48;5;36m"],
    [ :light_sea_green, "\e[48;5;37m"],
    [ :deep_sky_blue_2, "\e[48;5;38m"],
    [ :deep_sky_blue_1, "\e[48;5;39m"],
    [ :green_3, "\e[48;5;40m"],
    [ :spring_green_3, "\e[48;5;41m"],
    [ :spring_green_2, "\e[48;5;42m"],
    [ :cyan_3, "\e[48;5;43m"],
    [ :dark_turquoise, "\e[48;5;44m"],
    [ :turquoise_2, "\e[48;5;45m"],
    [ :green_1, "\e[48;5;46m"],
    [ :spring_green_2, "\e[48;5;47m"],
    [ :spring_green_1, "\e[48;5;48m"],
    [ :medium_spring_green, "\e[48;5;49m"],
    [ :cyan_2, "\e[48;5;50m"],
    [ :cyan_1, "\e[48;5;51m"],
    [ :dark_red, "\e[48;5;52m"],
    [ :deep_pink_4, "\e[48;5;53m"],
    [ :purple_4, "\e[48;5;54m"],
    [ :purple_4, "\e[48;5;55m"],
    [ :purple_3, "\e[48;5;56m"],
    [ :blue_violet, "\e[48;5;57m"],
    [ :orange_4, "\e[48;5;58m"],
    [ :grey_37, "\e[48;5;59m"],
    [ :medium_purple_4, "\e[48;5;60m"],
    [ :slate_blue_3, "\e[48;5;61m"],
    [ :slate_blue_3, "\e[48;5;62m"],
    [ :royal_blue_1, "\e[48;5;63m"],
    [ :chartreuse_4, "\e[48;5;64m"],
    [ :dark_sea_green_4, "\e[48;5;65m"],
    [ :pale_turquoise_4, "\e[48;5;66m"],
    [ :steel_blue, "\e[48;5;67m"],
    [ :steel_blue_3, "\e[48;5;68m"],
    [ :cornflower_blue, "\e[48;5;69m"],
    [ :chartreuse_3, "\e[48;5;70m"],
    [ :dark_sea_green_4, "\e[48;5;71m"],
    [ :cadet_blue, "\e[48;5;72m"],
    [ :cadet_blue, "\e[48;5;73m"],
    [ :sky_blue_3, "\e[48;5;74m"],
    [ :steel_blue_1, "\e[48;5;75m"],
    [ :chartreuse_3, "\e[48;5;76m"],
    [ :pale_green_3, "\e[48;5;77m"],
    [ :sea_green_3, "\e[48;5;78m"],
    [ :aquamarine_3, "\e[48;5;79m"],
    [ :medium_turquoise, "\e[48;5;80m"],
    [ :steel_blue_1, "\e[48;5;81m"],
    [ :chartreuse_2, "\e[48;5;82m"],
    [ :sea_green_2, "\e[48;5;83m"],
    [ :sea_green_1, "\e[48;5;84m"],
    [ :sea_green_1, "\e[48;5;85m"],
    [ :aquamarine_1, "\e[48;5;86m"],
    [ :dark_slate_gray_2, "\e[48;5;87m"],
    [ :dark_red, "\e[48;5;88m"],
    [ :deep_pink_4, "\e[48;5;89m"],
    [ :dark_magenta, "\e[48;5;90m"],
    [ :dark_magenta, "\e[48;5;91m"],
    [ :dark_violet, "\e[48;5;92m"],
    [ :purple, "\e[48;5;93m"],
    [ :orange_4, "\e[48;5;94m"],
    [ :light_pink_4, "\e[48;5;95m"],
    [ :plum_4, "\e[48;5;96m"],
    [ :medium_purple_3, "\e[48;5;97m"],
    [ :medium_purple_3, "\e[48;5;98m"],
    [ :slate_blue_1, "\e[48;5;99m"],
    [ :yellow_4, "\e[48;5;100m"],
    [ :wheat_4, "\e[48;5;101m"],
    [ :grey_53, "\e[48;5;102m"],
    [ :light_slate_grey, "\e[48;5;103m"],
    [ :medium_purple, "\e[48;5;104m"],
    [ :light_slate_blue, "\e[48;5;105m"],
    [ :yellow_4, "\e[48;5;106m"],
    [ :dark_olive_green_3, "\e[48;5;107m"],
    [ :dark_sea_green, "\e[48;5;108m"],
    [ :light_sky_blue_3, "\e[48;5;109m"],
    [ :light_sky_blue_3, "\e[48;5;110m"],
    [ :sky_blue_2, "\e[48;5;111m"],
    [ :chartreuse_2, "\e[48;5;112m"],
    [ :dark_olive_green_3, "\e[48;5;113m"],
    [ :pale_green_3, "\e[48;5;114m"],
    [ :dark_sea_green_3, "\e[48;5;115m"],
    [ :dark_slate_gray_3, "\e[48;5;116m"],
    [ :sky_blue_1, "\e[48;5;117m"],
    [ :chartreuse_1, "\e[48;5;118m"],
    [ :light_green_1, "\e[48;5;119m"],
    [ :light_green_2, "\e[48;5;120m"],
    [ :pale_green_1, "\e[48;5;121m"],
    [ :aquamarine_1, "\e[48;5;122m"],
    [ :dark_slate_gray_1, "\e[48;5;123m"],
    [ :red_3, "\e[48;5;124m"],
    [ :deep_pink_4, "\e[48;5;125m"],
    [ :medium_violet_red, "\e[48;5;126m"],
    [ :magenta_3, "\e[48;5;127m"],
    [ :dark_violet, "\e[48;5;128m"],
    [ :purple, "\e[48;5;129m"],
    [ :dark_orange_3, "\e[48;5;130m"],
    [ :indian_red, "\e[48;5;131m"],
    [ :hot_pink_3, "\e[48;5;132m"],
    [ :medium_orchid_3, "\e[48;5;133m"],
    [ :medium_orchid, "\e[48;5;134m"],
    [ :medium_purple_2, "\e[48;5;135m"],
    [ :dark_goldenrod, "\e[48;5;136m"],
    [ :light_salmon_3, "\e[48;5;137m"],
    [ :rosy_brown, "\e[48;5;138m"],
    [ :grey_63, "\e[48;5;139m"],
    [ :medium_purple_2, "\e[48;5;140m"],
    [ :medium_purple_1, "\e[48;5;141m"],
    [ :gold_3, "\e[48;5;142m"],
    [ :dark_khaki, "\e[48;5;143m"],
    [ :navajo_white_3, "\e[48;5;144m"],
    [ :grey_69, "\e[48;5;145m"],
    [ :light_steel_blue_3, "\e[48;5;146m"],
    [ :light_steel_blue, "\e[48;5;147m"],
    [ :yellow_3, "\e[48;5;148m"],
    [ :dark_olive_green_3, "\e[48;5;149m"],
    [ :dark_sea_green_3, "\e[48;5;150m"],
    [ :dark_sea_green_2, "\e[48;5;151m"],
    [ :light_cyan_3, "\e[48;5;152m"],
    [ :light_sky_blue_1, "\e[48;5;153m"],
    [ :green_yellow, "\e[48;5;154m"],
    [ :dark_olive_green_2, "\e[48;5;155m"],
    [ :pale_green_1, "\e[48;5;156m"],
    [ :dark_sea_green_2, "\e[48;5;157m"],
    [ :dark_sea_green_1, "\e[48;5;158m"],
    [ :pale_turquoise_1, "\e[48;5;159m"],
    [ :red_3, "\e[48;5;160m"],
    [ :deep_pink_3, "\e[48;5;161m"],
    [ :deep_pink_3, "\e[48;5;162m"],
    [ :magenta_3, "\e[48;5;163m"],
    [ :magenta_3, "\e[48;5;164m"],
    [ :magenta_2, "\e[48;5;165m"],
    [ :dark_orange_3, "\e[48;5;166m"],
    [ :indian_red, "\e[48;5;167m"],
    [ :hot_pink_3, "\e[48;5;168m"],
    [ :hot_pink_2, "\e[48;5;169m"],
    [ :orchid, "\e[48;5;170m"],
    [ :medium_orchid_1, "\e[48;5;171m"],
    [ :orange_3, "\e[48;5;172m"],
    [ :light_salmon_3, "\e[48;5;173m"],
    [ :light_pink_3, "\e[48;5;174m"],
    [ :pink_3, "\e[48;5;175m"],
    [ :plum_3, "\e[48;5;176m"],
    [ :violet, "\e[48;5;177m"],
    [ :gold_3, "\e[48;5;178m"],
    [ :light_goldenrod_3, "\e[48;5;179m"],
    [ :tan, "\e[48;5;180m"],
    [ :misty_rose_3, "\e[48;5;181m"],
    [ :thistle_3, "\e[48;5;182m"],
    [ :plum_2, "\e[48;5;183m"],
    [ :yellow_3, "\e[48;5;184m"],
    [ :khaki_3, "\e[48;5;185m"],
    [ :light_goldenrod_2, "\e[48;5;186m"],
    [ :light_yellow_3, "\e[48;5;187m"],
    [ :grey_84, "\e[48;5;188m"],
    [ :light_steel_blue_1, "\e[48;5;189m"],
    [ :yellow_2, "\e[48;5;190m"],
    [ :dark_olive_green_1, "\e[48;5;191m"],
    [ :dark_olive_green_1, "\e[48;5;192m"],
    [ :dark_sea_green_1, "\e[48;5;193m"],
    [ :honeydew_2, "\e[48;5;194m"],
    [ :light_cyan_1, "\e[48;5;195m"],
    [ :red_1, "\e[48;5;196m"],
    [ :deep_pink_2, "\e[48;5;197m"],
    [ :deep_pink_1, "\e[48;5;198m"],
    [ :deep_pink_1, "\e[48;5;199m"],
    [ :magenta_2, "\e[48;5;200m"],
    [ :magenta_1, "\e[48;5;201m"],
    [ :orange_red_1, "\e[48;5;202m"],
    [ :indian_red_1, "\e[48;5;203m"],
    [ :indian_red_1, "\e[48;5;204m"],
    [ :hot_pink, "\e[48;5;205m"],
    [ :hot_pink, "\e[48;5;206m"],
    [ :medium_orchid_1, "\e[48;5;207m"],
    [ :dark_orange, "\e[48;5;208m"],
    [ :salmon_1, "\e[48;5;209m"],
    [ :light_coral, "\e[48;5;210m"],
    [ :pale_violet_red_1, "\e[48;5;211m"],
    [ :orchid_2, "\e[48;5;212m"],
    [ :orchid_1, "\e[48;5;213m"],
    [ :orange_1, "\e[48;5;214m"],
    [ :sandy_brown, "\e[48;5;215m"],
    [ :light_salmon_1, "\e[48;5;216m"],
    [ :light_pink_1, "\e[48;5;217m"],
    [ :pink_1, "\e[48;5;218m"],
    [ :plum_1, "\e[48;5;219m"],
    [ :gold_1, "\e[48;5;220m"],
    [ :light_goldenrod_2, "\e[48;5;221m"],
    [ :light_goldenrod_2, "\e[48;5;222m"],
    [ :navajo_white_1, "\e[48;5;223m"],
    [ :misty_rose_1, "\e[48;5;224m"],
    [ :thistle_1, "\e[48;5;225m"],
    [ :yellow_1, "\e[48;5;226m"],
    [ :light_goldenrod_1, "\e[48;5;227m"],
    [ :khaki_1, "\e[48;5;228m"],
    [ :wheat_1, "\e[48;5;229m"],
    [ :cornsilk_1, "\e[48;5;230m"],
    [ :grey_100, "\e[48;5;231m"],
    [ :grey_3, "\e[48;5;232m"],
    [ :grey_7, "\e[48;5;233m"],
    [ :grey_11, "\e[48;5;234m"],
    [ :grey_15, "\e[48;5;235m"],
    [ :grey_19, "\e[48;5;236m"],
    [ :grey_23, "\e[48;5;237m"],
    [ :grey_27, "\e[48;5;238m"],
    [ :grey_30, "\e[48;5;239m"],
    [ :grey_35, "\e[48;5;240m"],
    [ :grey_39, "\e[48;5;241m"],
    [ :grey_42, "\e[48;5;242m"],
    [ :grey_46, "\e[48;5;243m"],
    [ :grey_50, "\e[48;5;244m"],
    [ :grey_54, "\e[48;5;245m"],
    [ :grey_58, "\e[48;5;246m"],
    [ :grey_62, "\e[48;5;247m"],
    [ :grey_66, "\e[48;5;248m"],
    [ :grey_70, "\e[48;5;249m"],
    [ :grey_74, "\e[48;5;250m"],
    [ :grey_78, "\e[48;5;251m"],
    [ :grey_82, "\e[48;5;252m"],
    [ :grey_85, "\e[48;5;253m"],
    [ :grey_89, "\e[48;5;254m"],
    [ :grey_93, "\e[48;5;255m"]
    ]
    
    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "#{v}"
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m"
          result
        end
      }
    end
    
    module_function
    def attributes
      @@attributes.map { |c| c.first }
    end
    
    def attribute att
      @@attributes.each do |e|
        return e.last if e.first.eql? att
      end
      nil
    end
    extend self
  end
  
#  module Foreground
#    include Color::Foreground_256
#    include Color::Foreground_16
#    include Color::Foreground_8
#  end
#  
#  module Background
#    include Color::Background_256
#    include Color::Background_16
#    include Color::Background_8
#  end
end

class FormatState
  attr_reader :parent
  
  def initialize(parent = nil, fg: nil, bg: nil, blink: nil, dim: nil, underlined: nil, bold: nil, reversed: nil)
    @parent = parent
    @fg = fg
    @bg = bg
    @blink = blink
    @dim = dim
    @underlined = underlined
    @bold = bold
    @reversed = reversed
  end
  
  def initialize(code, parent = nil)
    @parent = parent
    code_working = code.dup
    
    code_working.gsub!(/\s\s*/i) do |match|
      " "
    end
    
    fg_text = code_working[/fg\:([a-zA-Z0-9\_]*)\s*/i, 1].dup
    code_working.gsub!(/fg\:([a-zA-Z0-9\_]*)\s*/i) do |match|
      ""
    end
    
    bg_text = code_working[/bg\:([a-zA-Z0-9\_]*)\s*/i, 1].dup
    code_working.gsub!(/bg\:([a-zA-Z0-9\_]*)\s*/i) do |match|
      ""
    end
    
    formatting_text = code.strip.split(' ')
    
    @fg = Color::Foreground.attribute(fg_text.to_sym) unless fg_text.nil?
    @bg = Color::Background.attribute(bg_text.to_sym) unless bg_text.nil?
    formatting_text.each do |format|
      case format
      when "blink"
        @blink = true
      when "noblink"
        @blink = false
      when "dim"
        @dim = true
      when "nodim"
        @dim = false
      when "underline"
        @underline = true
      when "nounderline"
        @underline = false
      when "bold"
        @bold = true
      when "nobold"
        @bold = false
      when "reversed"
        @reversed = true
      when "noreversed"
        @reversed = false
      end
    end
  end
  
  def fg
    return @fg unless @fg.nil?
    return @parent.fg unless @parent.nil?
    nil  
  end
  
  def bg
    return @bg unless @bg.nil?
    return @parent.bg unless @parent.nil?
    nil 
  end
  
  def blink?
    return @blink unless @blink.nil?
    return @parent.blink? unless @parent.nil?
    nil 
  end
  
  def dim?
    return @dim unless @dim.nil?
    return @parent.dim? unless @parent.nil?
    nil 
  end
  
  def bold?
    return @bold unless @bold.nil?
    return @parent.bold? unless @parent.nil?
    nil 
  end
  
  def underlined?
    return @underlined unless @underlined.nil?
    return @parent.underlined? unless @parent.nil?
    nil 
  end
  
  def reversed?
    return @reversed unless @reversed.nil?
    return @parent.reversed? unless @parent.nil?
    nil 
  end
  
  def apply
    result = ""
    result += Color::Reset.all + Color::Reset.blink + Color::Reset.bold + Color::Reset.dim + Color::Reset.underlined + Color::Reset.reverse
    result += self.fg unless self.fg.nil?
    result += self.bg unless self.bg.nil?
    result += Color::Formatting.blink if self.blink?
    result += Color::Formatting.dim if self.dim?
    result += Color::Formatting.bold if self.bold?
    result += Color::Formatting.underlined if self.underlined?
    result += Color::Formatting.reversed if self.reversed?
    result
  end
  
  def revert
    return @parent.apply unless @parent.nil?
    return Color::Reset.all + Color::Reset.blink + Color::Reset.bold + Color::Reset.dim + Color::Reset.underlined + Color::Reset.reverse
  end
end
