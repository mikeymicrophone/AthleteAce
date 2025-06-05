module SearchFormHelper
  # UNUSED
  # Creates an auto-submitting select field for search forms
  # @param form [ActionView::Helpers::FormBuilder] The form builder
  # @param attribute [Symbol] The attribute to search on (ransack predicate)
  # @param options_source [Symbol or Array] Either a symbol referring to @filter_options key or direct collection
  # @param label_text [String] Label for the field
  # @return [String] HTML for the select field
  def ransack_auto_submit_select(form, attribute, options_source, label_text = nil)
    # Set defaults
    label_text ||= attribute.to_s.humanize.gsub(/_[^_]*$/, '')  # Remove predicate suffixes like _cont, _eq
    
    # Get collection either from filter_options or directly
    collection = get_filter_collection(options_source)
    return "" if collection.blank?
    
    # Format for select dropdown
    select_options = [["-- Select #{label_text} --", nil]] + 
                     collection.map { |item| [item.name, item.id] }
    
    # Create the field with tag builder
    tag.div class: "filter-field mb-4" do
      form.label(attribute, label_text, class: "form-field-label") +
      form.select(attribute, 
            select_options, 
            {}, 
            { class: "form-field-input w-full p-2 border rounded", 
              onchange: "this.form.submit();" })
    end
  end
  
  # UNUSED
  # Creates a search text field with label
  # @param form [ActionView::Helpers::FormBuilder] The form builder
  # @param attribute [Symbol] The attribute to search on (ransack predicate)
  # @param label_text [String] Label for the field
  # @return [String] HTML for the search field
  def ransack_search_field(form, attribute, label_text = nil)
    # Set defaults
    label_text ||= attribute.to_s.humanize.gsub(/_[^_]*$/, '')  # Remove predicate suffixes
    
    tag.div class: "filter-field mb-4" do
      form.label(attribute, label_text, class: "form-field-label") +
      form.search_field(attribute, 
                      class: "form-field-input w-full p-2 border rounded", 
                      placeholder: "Search by #{label_text.downcase}...")
    end
  end
  
  # UNUSED
  # Creates a collapsible section for advanced filters
  # @param title [String] Title for the advanced filters section
  # @param &block [Block] Block containing the advanced filter fields
  # @return [String] HTML for the advanced filters section
  def collapsible_filters_section(title = "Advanced Filters", &block)
    tag.div class: "filter-section" do
      toggle = tag.div class: "filter-toggle flex items-center text-blue-600 mb-3 cursor-pointer",
                      data: { controller: "collapse", action: "click->collapse#toggle" } do
        tag.span title, class: "mr-2" 
        tag.i class: "#{icon_for_resource :chevron_down}"
      end
      
      content = tag.div class: "filter-content hidden", 
                        data: { collapse_target: "content" } do
        capture(&block) if block_given?
      end
      
      toggle + content
    end
  end
  
  # UNUSED
  # Creates a complete search form with basic and advanced filters
  # @param search [Object] The Ransack search object
  # @param url [String] URL for the form
  # @param basic_filters [Block] Block containing basic filter fields
  # @param advanced_filters [Block] Block containing advanced filter fields
  # @return [String] HTML for the complete search form
  def model_search_form(search, url, &block)
    form_for search, url: url, method: :get, html: { class: "search-form" } do |f|
      capture do
        yield(f) if block_given?
      end
    end
  end
  
  private
  
  # Get collection from filter_options or direct array
  def get_filter_collection(options_source)
    if options_source.is_a?(Symbol) && defined?(@filter_options)
      @filter_options[options_source]
    elsif options_source.is_a?(Array)
      options_source
    else
      []
    end
  end
end
