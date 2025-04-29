module Strength
  class BaseComponent < Phlex::HTML
    include Phlex::Rails::Helpers::LinkTo
    include Phlex::Rails::Helpers::FormWith
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::ContentFor
    include Phlex::Rails::Helpers::FormTagHelper
    
    def initialize(title: nil)
      @title = title
    end
    
    def template
      if @title
        content_for :title, @title
      end
      
      yield
    end
    
    def back_button(path, text = "Back to Training Hub")
      link_to path, class: "text-blue-600 hover:text-blue-800 flex items-center" do
        svg xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5 mr-1", viewbox: "0 0 20 20", fill: "currentColor" do
          path fill_rule: "evenodd", d: "M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z", clip_rule: "evenodd"
        end
        text text
      end
    end
    
    def header(title)
      div class: "flex items-center justify-between mb-8" do
        h1 title, class: "text-3xl font-bold text-gray-900"
        yield if block_given?
      end
    end
    
    def card(title: nil, classes: "")
      div class: "bg-white shadow-lg rounded-lg overflow-hidden mb-8 #{classes}" do
        div class: "p-6" do
          h2 title, class: "text-xl font-semibold text-gray-800 mb-4" if title
          yield
        end
      end
    end
    
    def info_box(title: nil, type: :info)
      bg_color = case type
                 when :info then "bg-blue-50 border-blue-200 text-blue-700"
                 when :success then "bg-green-50 border-green-200 text-green-700"
                 when :warning then "bg-yellow-50 border-yellow-200 text-yellow-700"
                 when :error then "bg-red-50 border-red-200 text-red-700"
                 end
      
      div class: "#{bg_color} border rounded-lg p-6" do
        h3 title, class: "text-lg font-semibold mb-2" if title
        yield
      end
    end
    
    def notice_box(notice)
      return unless notice.present?
      
      is_success = notice.to_s.include?("Correct")
      bg_color = is_success ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"
      
      div class: "#{bg_color} p-4 rounded-md mb-6" do
        text notice
      end
    end
  end
end
