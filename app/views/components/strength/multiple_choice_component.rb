module Strength
  class MultipleChoiceComponent < BaseComponent
    def initialize(correct_player:, options:, notice: nil)
      super(title: "Multiple Choice Training")
      @correct_player = correct_player
      @options = options
      @notice = notice
    end
    
    def template
      super do
        div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
          header("Multiple Choice Training") do
            back_button(strength_path)
          end
          
          notice_box(@notice)
          
          card(title: "Who is this athlete?") do
            render_player_photo
            render_player_info
            render_quiz_form
          end
          
          info_box(title: "Training Tips", type: :info) do
            ul class: "list-disc pl-5 text-blue-700 space-y-1" do
              li "Look for visual cues that might help you remember the athlete"
              li "Associate the athlete with their team colors or logo"
              li "Try to recall recent news or achievements about the athlete"
              li "Practice regularly to build long-term memory"
            end
          end
        end
      end
    end
    
    private
    
    def render_player_photo
      if @correct_player.photo_urls.present?
        div class: "flex justify-center mb-6" do
          img src: @correct_player.photo_urls.first, 
              alt: "Athlete photo", 
              class: "h-64 w-64 object-cover rounded-lg shadow-md"
        end
      else
        div class: "flex justify-center mb-6 bg-gray-200 h-64 w-64 mx-auto rounded-lg flex items-center justify-center" do
          span "No photo available", class: "text-gray-500 text-lg"
        end
      end
    end
    
    def render_player_info
      div class: "text-center mb-6" do
        if @correct_player.team.present?
          div class: "text-lg font-medium text-gray-600 mb-1" do
            text "Team: #{@correct_player.team.name}"
          end
        end
        
        if @correct_player.current_position.present?
          div class: "text-md text-gray-500" do
            text "Position: #{@correct_player.current_position}"
          end
        end
      end
    end
    
    def render_quiz_form
      form_with url: check_answer_path, method: :post, class: "space-y-4" do
        input type: "hidden", name: "player_id", value: @correct_player.id
        
        div class: "grid grid-cols-1 gap-3" do
          @options.each do |player|
            label class: "relative flex items-center justify-between p-4 bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-lg cursor-pointer transition-colors" do
              input type: "radio", 
                   name: "selected_id", 
                   value: player.id, 
                   class: "h-5 w-5 text-blue-600 focus:ring-blue-500 border-gray-300"
              
              span class: "ml-3 block text-lg font-medium text-gray-700 flex-grow" do
                text "#{player.first_name} #{player.last_name}"
              end
            end
          end
        end
        
        div class: "flex justify-center mt-6" do
          button type: "submit", 
                 class: "py-2 px-6 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors" do
            text "Submit Answer"
          end
        end
      end
    end
  end
end
