module Strength
  class IndexComponent < BaseComponent
    include Phlex::Rails::Helpers::CollectionSelect
    
    def initialize(sports:, leagues:, teams:)
      super(title: "Athlete Name Training")
      @sports = sports
      @leagues = leagues
      @teams = teams
    end
    
    def template
      super do
        div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
          # Header section
          div class: "text-center mb-10" do
            h1 "Strengthen Your Athlete Name Knowledge", class: "text-4xl font-extrabold text-gray-900 mb-4"
            p class: "text-lg text-gray-600 max-w-3xl mx-auto" do
              text "Choose a training method below to improve your ability to recognize and recall athlete names."
            end
          end
          
          # Training methods grid
          render_training_methods
          
          # Filters section
          render_filters
          
          # Info section
          render_info_section
        end
      end
    end
    
    private
    
    def render_training_methods
      div class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12" do
        training_method(
          path: strength_multiple_choice_path,
          color: "blue",
          emoji: "🎯",
          title: "Multiple Choice",
          description: "Test your knowledge with multiple choice questions about athletes."
        )
        
        training_method(
          path: strength_phased_repetition_path,
          color: "green",
          emoji: "🔄",
          title: "Phased Repetition",
          description: "Learn names through spaced repetition for better long-term retention."
        )
        
        training_method(
          path: strength_images_path,
          color: "purple",
          emoji: "🖼️",
          title: "Image Recognition",
          description: "Match athlete faces with their names to build visual recognition."
        )
        
        training_method(
          path: strength_ciphers_path,
          color: "orange",
          emoji: "🔍",
          title: "Name Ciphers",
          description: "Decode scrambled athlete names to strengthen your recall."
        )
      end
    end
    
    def training_method(path:, color:, emoji:, title:, description:)
      link_to path, class: "bg-#{color}-600 hover:bg-#{color}-700 text-white rounded-lg shadow-md overflow-hidden transition duration-300 transform hover:scale-105" do
        div class: "p-6 text-center" do
          div emoji, class: "text-3xl mb-2"
          h2 title, class: "text-xl font-bold mb-2"
          p description, class: "text-#{color}-100"
        end
      end
    end
    
    def render_filters
      div class: "bg-gray-100 rounded-lg p-6 mb-8" do
        h2 "Filter Your Training", class: "text-2xl font-bold text-gray-800 mb-4"
        
        form_with url: strength_path, method: :get, class: "space-y-4" do
          div class: "grid grid-cols-1 md:grid-cols-3 gap-4" do
            div do
              label "Sport", for: "sport_id", class: "block text-sm font-medium text-gray-700 mb-1"
              collection_select :sport_id, @sports, :id, :name, 
                { include_blank: "All Sports" }, 
                { class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" }
            end
            
            div do
              label "League", for: "league_id", class: "block text-sm font-medium text-gray-700 mb-1"
              collection_select :league_id, @leagues, :id, :name, 
                { include_blank: "All Leagues" }, 
                { class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" }
            end
            
            div do
              label "Team", for: "team_id", class: "block text-sm font-medium text-gray-700 mb-1"
              collection_select :team_id, @teams, :id, :name, 
                { include_blank: "All Teams" }, 
                { class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" }
            end
          end
          
          div class: "flex items-center" do
            check_box_tag :include_inactive, "true", false, 
              class: "h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            label_tag :include_inactive, "Include inactive players", 
              class: "ml-2 block text-sm text-gray-700"
          end
          
          div class: "flex justify-end" do
            submit_tag "Apply Filters", 
              class: "inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          end
        end
      end
    end
    
    def render_info_section
      div class: "bg-blue-50 border border-blue-200 rounded-lg p-6" do
        h2 "Why Train Your Name Recognition?", class: "text-2xl font-bold text-blue-800 mb-2"
        p class: "text-blue-700 mb-4" do
          text "Recognizing athletes by name enhances your enjoyment of sports and deepens your connection to the games you love. Regular practice helps you:"
        end
        
        ul class: "list-disc pl-5 text-blue-700 space-y-2" do
          li "Follow games more easily when commentators mention players"
          li "Engage in more meaningful conversations with other fans"
          li "Appreciate player achievements and career trajectories"
          li "Build a stronger connection to your favorite teams"
        end
      end
    end
  end
end
