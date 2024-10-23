# _plugins/obsidian_converter.rb

Jekyll::Hooks.register :posts, :pre_render do |post|
  def convert_callouts(content)
    # Obsidian callout 패턴 매칭
    content.gsub(/>\s*\[!(.*?)\]\s*(.*?)\n((?:>.*?\n)*)/) do |match|
      type = $1.downcase
      title = $2
      body = $3.gsub(/^>\s?/, '')  # '>' 제거

      # Chirpy 스타일로 변환
      case type
      when 'note'
        "{: .prompt-info }\n> **#{title}**\n> #{body}"
      when 'warning'
        "{: .prompt-warning }\n> **#{title}**\n> #{body}"
      when 'danger'
        "{: .prompt-danger }\n> **#{title}**\n> #{body}"
      when 'tip'
        "{: .prompt-tip }\n> **#{title}**\n> #{body}"
      else
        "{: .prompt-info }\n> **#{title}**\n> #{body}"
      end
    end
  end

  post.content = convert_callouts(post.content)
end
