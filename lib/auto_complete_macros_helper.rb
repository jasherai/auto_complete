module AutoCompleteMacrosHelper      
  #
  # Replace the original auto_complete_field method to output the correct 
  # jquery hooks in page (TODO: figure out how to extract that all out
  # to a javascript file)
  #
  def auto_complete_field(field_id, options = {})
    function =  "$(function() {\n"
    function << "$('input##{field_id}').autocomplete({ ajax: "
#    function << "'" + (options[:update] || "#{field_id}_auto_complete") + "', "
    function << "'#{url_for(options[:url])}' });\n"
    
    js_options = {}
    js_options[:tokens] = array_or_string_for_javascript(options[:tokens]) if options[:tokens]
    js_options[:callback]   = "function(element, value) { return #{options[:with]} }" if options[:with]
    js_options[:indicator]  = "'#{options[:indicator]}'" if options[:indicator]
    js_options[:select]     = "'#{options[:select]}'" if options[:select]
    js_options[:paramName]  = "'#{options[:param_name]}'" if options[:param_name]
    js_options[:frequency]  = "#{options[:frequency]}" if options[:frequency]
    js_options[:method]     = "'#{options[:method].to_s}'" if options[:method]
    js_options[:parameters]  = "'#{options[:parameters]}'" if options[:parameters]

    { :after_update_element => :afterUpdateElement, 
      :on_show => :onShow, :on_hide => :onHide, :min_chars => :minChars }.each do |k,v|
      js_options[v] = options[k] if options[k]
    end

   # function << (', ' + options_for_javascript(js_options) + ')')
    
    # End jquery main block
    function << "});"
    
    logger.info "#{function}"
    
    javascript_tag(function.html_safe)
  end
  
  # Use this method in your view to generate a return for the AJAX autocomplete requests.
  #
  # Example action:
  #
  #   def auto_complete_for_item_title
  #     @items = Item.find(:all, 
  #       :conditions => [ 'LOWER(description) LIKE ?', 
  #       '%' + request.raw_post.downcase + '%' ])
  #     render :inline => "<%= auto_complete_result(@items, 'description') %>"
  #   end
  #
  # The auto_complete_result can of course also be called from a view belonging to the 
  # auto_complete action if you need to decorate it further.
  def auto_complete_result(entries, method, phrase = nil)
    return unless entries
    items = entries.map { |entry| content_tag("li", phrase ? highlight(entry.send(method), phrase) : h(entry.send(method))) }
    content_tag("ul", items.uniq.join.html_safe)
  end
  
  # Wrapper for text_field with added AJAX autocompletion functionality.
  #
  # In your controller, you'll need to define an action called
  # auto_complete_for to respond the AJAX calls,
  # 
  def text_field_with_auto_complete(object, method, tag_options = {}, completion_options = {})
    auto_complete_field_with_style_and_script(object, method, tag_options, completion_options) do
      text_field(object, method, tag_options)
    end
  end

  def auto_complete_field_with_style_and_script(object, method, tag_options = {}, completion_options = {})
    #(completion_options[:skip_style] ? "" : auto_complete_stylesheet) +
    yield +
    content_tag("div", "", :id => "#{object}_#{method}_auto_complete", :class => "auto_complete") +
    auto_complete_field("#{object}_#{method}", { :url => { :action => "auto_complete_for_#{object}_#{method}" } }.update(completion_options))
  end

  private
    def auto_complete_stylesheet
      content_tag('style', <<-EOT, :type => Mime::CSS)
        div.auto_complete {
          width: 350px;
          background: #fff;
        }
        div.auto_complete ul {
          border:1px solid #888;
          margin:0;
          padding:0;
          width:100%;
          list-style-type:none;
        }
        div.auto_complete ul li {
          margin:0;
          padding:3px;
        }
        div.auto_complete ul li.selected {
          background-color: #ffb;
        }
        div.auto_complete ul strong.highlight {
          color: #800; 
          margin:0;
          padding:0;
        }
      EOT
    end

end   
