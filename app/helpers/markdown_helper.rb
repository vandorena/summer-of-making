# frozen_string_literal: true

module MarkdownHelper
  class CustomRender < Redcarpet::Render::HTML
    def link(link, title, content)
      "<a href='#{link}' title='#{title}' class='text-nice-blue underline' target='_blank'>#{content}</a>"
    end

    def autolink(link, _link_type)
      "<a href='#{link}' class='text-nice-blue underline' target='_blank'>#{link}</a>"
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
    return '' if text.blank?

    text = text.gsub(/(?<!~)~(?!~)(.*?)(?<!~)~(?!~)/, '~~\1~~')
    text = text.gsub(/\n{2,}/, "\n<br>\n")

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

    rendered = markdown.render(text)

    sanitize(rendered, tags: %w(a br code pre p em strong h1 h2 h3 h4 h5 h6 ul ol li blockquote span),
                       attributes: %w(href title class target))
  end
end
