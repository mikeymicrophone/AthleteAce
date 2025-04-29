module Strength
  class CiphersComponent < BaseComponent
    def initialize(current_player:, scrambled_name:)
      super(title: "Name Ciphers Training")
      @current_player = current_player
      @scrambled_name = scrambled_name
    end
    
    def template
      super do
        div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
          header("Name Ciphers Training") do
            back_button(strength_path)
          end
          
          card(title: "Unscramble the Athlete's Name") do
            render_scrambled_name
            render_player_hints
            render_solution_section
            render_navigation
          end
          
          info_box(title: "Cipher Training Benefits", type: :info) do
            p class: "mb-3" do
              text "Unscrambling names helps you:"
            end
            
            ul class: "list-disc pl-5 text-blue-700 space-y-1" do
              li "Develop letter-by-letter familiarity with athlete names"
              li "Strengthen spelling recognition"
              li "Build mental flexibility when processing names"
              li "Improve recall by engaging with the name in a challenging way"
            end
          end
        end
      end
    end
    
    private
    
    def render_scrambled_name
      div class: "text-center mb-8" do
        h3 "Scrambled Name:", class: "text-lg font-medium text-gray-700 mb-2"
        
        div class: "flex flex-wrap justify-center gap-2" do
          @scrambled_name.chars.each do |char|
            if char == " "
              div class: "w-6 h-10"
            else
              div class: "w-10 h-10 bg-orange-100 border border-orange-300 rounded-md flex items-center justify-center font-bold text-orange-800 text-xl" do
                text char
              end
            end
          end
        end
      end
    end
    
    def render_player_hints
      div class: "bg-gray-100 rounded-lg p-4 mb-6" do
        h4 "Hints:", class: "font-semibold text-gray-800 mb-2"
        
        div class: "grid grid-cols-1 md:grid-cols-2 gap-4" do
          div do
            p class: "text-gray-700" do
              span "Team: ", class: "font-medium"
              if @current_player.team.present?
                text @current_player.team.name
              else
                text "Unknown"
              end
            end
          end
          
          div do
            p class: "text-gray-700" do
              span "Position: ", class: "font-medium"
              if @current_player.current_position.present?
                text @current_player.current_position
              else
                text "Unknown"
              end
            end
          end
          
          if @current_player.debut_year.present?
            div do
              p class: "text-gray-700" do
                span "Debut Year: ", class: "font-medium"
                text @current_player.debut_year
              end
            end
          end
          
          div do
            p class: "text-gray-700" do
              span "Name Length: ", class: "font-medium"
              text "#{@current_player.first_name.length + @current_player.last_name.length + 1} characters (including space)"
            end
          end
        end
      end
    end
    
    def render_solution_section
      div class: "mb-6", data_controller: "cipher" do
        button "Reveal Solution", 
               class: "mb-4 py-2 px-4 bg-gray-200 hover:bg-gray-300 text-gray-800 rounded-md",
               data_action: "click->cipher#toggleSolution"
        
        div class: "hidden", data_cipher_target: "solution" do
          p class: "text-center text-xl font-bold text-gray-900 mb-2" do
            text "#{@current_player.first_name} #{@current_player.last_name}"
          end
          
          if @current_player.photo_urls.present?
            div class: "flex justify-center" do
              img src: @current_player.photo_urls.first, 
                  alt: "Athlete photo", 
                  class: "h-48 w-48 object-cover rounded-lg shadow-md"
            end
          end
        end
      end
    end
    
    def render_navigation
      div class: "flex justify-center" do
        link_to strength_ciphers_path, 
                class: "py-2 px-6 bg-orange-600 hover:bg-orange-700 text-white font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500 transition-colors" do
          text "Next Cipher"
        end
      end
    end
  end
end
