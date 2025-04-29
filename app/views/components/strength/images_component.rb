module Strength
  class ImagesComponent < BaseComponent
    def initialize(current_player:)
      super(title: "Image Recognition Training")
      @current_player = current_player
    end
    
    def template
      super do
        div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
          header("Image Recognition Training") do
            back_button(strength_path)
          end
          
          card(title: "Match the Image to the Name") do
            render_player_images
            render_player_name
            render_navigation
          end
          
          info_box(title: "Image Recognition Tips", type: :info) do
            ul class: "list-disc pl-5 text-blue-700 space-y-1" do
              li "Focus on distinctive facial features"
              li "Notice jersey numbers and team colors when visible"
              li "Create mental associations between the face and name"
              li "Try to recall the player's position and team while viewing"
            end
          end
        end
      end
    end
    
    private
    
    def render_player_images
      if @current_player.photo_urls.present? && @current_player.photo_urls.length > 0
        div class: "grid grid-cols-1 md:grid-cols-2 gap-4 mb-6" do
          @current_player.photo_urls.take(4).each do |photo_url|
            div class: "aspect-square rounded-lg overflow-hidden shadow-md" do
              img src: photo_url, 
                  alt: "Athlete photo", 
                  class: "w-full h-full object-cover"
            end
          end
        end
      else
        div class: "flex justify-center mb-6 bg-gray-200 h-64 rounded-lg flex items-center justify-center" do
          span "No photos available", class: "text-gray-500 text-lg"
        end
      end
    end
    
    def render_player_name
      div class: "text-center mb-8" do
        h3 "#{@current_player.first_name} #{@current_player.last_name}", 
           class: "text-3xl font-bold text-gray-900 mb-2"
        
        if @current_player.team.present?
          div class: "text-lg text-gray-600" do
            text "#{@current_player.team.name}"
            if @current_player.current_position.present?
              text " • #{@current_player.current_position}"
            end
          end
        end
      end
    end
    
    def render_navigation
      div class: "flex justify-center" do
        link_to strength_images_path, 
                class: "py-2 px-6 bg-purple-600 hover:bg-purple-700 text-white font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-colors" do
          text "Next Athlete"
        end
      end
    end
  end
end
