module Strength
  class PhasedRepetitionComponent < BaseComponent
    def initialize(current_player:, phase:)
      super(title: "Phased Repetition Training")
      @current_player = current_player
      @phase = phase
    end
    
    def template
      super do
        div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
          header("Phased Repetition Training") do
            back_button(strength_path)
          end
          
          card(title: "Learn This Athlete") do
            render_player_info
            render_phase_indicator
            render_navigation_buttons
          end
          
          info_box(title: "About Phased Repetition", type: :info) do
            p class: "mb-3" do
              text "Phased repetition is a scientifically-proven learning technique that helps you commit information to long-term memory."
            end
            
            ul class: "list-disc pl-5 text-blue-700 space-y-1" do
              li "Phase 1: Initial exposure to the athlete's name and information"
              li "Phase 2: Review after a short interval (30 minutes)"
              li "Phase 3: Review after a medium interval (1 day)"
              li "Phase 4: Review after a long interval (1 week)"
            end
          end
        end
      end
    end
    
    private
    
    def render_player_info
      div class: "flex flex-col md:flex-row items-center gap-6 mb-8" do
        # Player photo
        if @current_player.photo_urls.present?
          div class: "w-full md:w-1/3" do
            img src: @current_player.photo_urls.first, 
                alt: "Athlete photo", 
                class: "w-full h-auto object-cover rounded-lg shadow-md"
          end
        else
          div class: "w-full md:w-1/3 bg-gray-200 h-64 rounded-lg flex items-center justify-center" do
            span "No photo available", class: "text-gray-500 text-lg"
          end
        end
        
        # Player details
        div class: "w-full md:w-2/3" do
          h3 "#{@current_player.first_name} #{@current_player.last_name}", 
             class: "text-2xl font-bold text-gray-900 mb-3"
          
          if @current_player.team.present?
            div class: "mb-2" do
              span "Team: ", class: "font-medium text-gray-700"
              span @current_player.team.name, class: "text-gray-800"
            end
          end
          
          if @current_player.current_position.present?
            div class: "mb-2" do
              span "Position: ", class: "font-medium text-gray-700"
              span @current_player.current_position, class: "text-gray-800"
            end
          end
          
          if @current_player.debut_year.present?
            div class: "mb-2" do
              span "Debut Year: ", class: "font-medium text-gray-700"
              span @current_player.debut_year, class: "text-gray-800"
            end
          end
          
          if @current_player.birthdate.present?
            div class: "mb-2" do
              span "Age: ", class: "font-medium text-gray-700"
              span calculate_age(@current_player.birthdate), class: "text-gray-800"
            end
          end
        end
      end
    end
    
    def render_phase_indicator
      div class: "mb-8" do
        div class: "text-center mb-3" do
          span "Current Phase: ", class: "font-medium text-gray-700"
          span @phase, class: "text-lg font-bold text-blue-600"
        end
        
        div class: "w-full bg-gray-200 rounded-full h-2.5" do
          div class: "bg-blue-600 h-2.5 rounded-full", 
              style: "width: #{@phase * 25}%"
        end
      end
    end
    
    def render_navigation_buttons
      div class: "flex justify-between" do
        link_to strength_phased_repetition_path(phase: [@phase - 1, 1].max), 
                class: "py-2 px-4 bg-gray-200 hover:bg-gray-300 text-gray-800 rounded-md #{@phase <= 1 ? 'opacity-50 cursor-not-allowed' : ''}" do
          text "Previous Phase"
        end
        
        link_to strength_phased_repetition_path, 
                class: "py-2 px-4 bg-blue-600 hover:bg-blue-700 text-white rounded-md" do
          text "Next Athlete"
        end
        
        link_to strength_phased_repetition_path(phase: [@phase + 1, 4].min), 
                class: "py-2 px-4 bg-gray-200 hover:bg-gray-300 text-gray-800 rounded-md #{@phase >= 4 ? 'opacity-50 cursor-not-allowed' : ''}" do
          text "Next Phase"
        end
      end
    end
    
    def calculate_age(birthdate)
      return "Unknown" unless birthdate
      
      now = Time.now.utc.to_date
      age = now.year - birthdate.year
      age -= 1 if now < birthdate + age.years
      age
    end
  end
end
