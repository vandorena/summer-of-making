module MarkdownHelper
  class CustomRender < Redcarpet::Render::HTML
    def link(link, title, content)
      "<a href='#{link}' title='#{title}' class='text-nice-blue underline'>#{content}</a>"
    end

    def autolink(link, link_type)
        "<a href='#{link}' class='text-nice-blue underline'>#{link}</a>"
    end

    def block_code(code, language)
      language ||= 'plaintext'
      "<pre class='bg-gray-900 p-4 text-forest overflow-x-auto'><code class='language-#{language}'>#{code}</code></pre>"
    end

    def codespan(code)
      "<code class='bg-gray-900 px-1 py-1 rounded-sm text-forest text-sm'>#{code}</code>"
    end
  end

  def markdown(text)
    return "" if text.blank?

    text = text.gsub(/\n\n/, "\n<br>\n")
    
    markdown = Redcarpet::Markdown.new(
      CustomRender.new(
        hard_wrap: true,
        filter_html: true,
        safe_links_only: true
      ),
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