module MarkdownHelper
  def markdown(text)
    return "" if text.blank?

    text = text.gsub(/\n\n/, "\n<br>\n")

    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      filter_html: true,
      safe_links_only: true
    )
    
    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true
    )
    
    markdown.render(text).html_safe
  end
end 