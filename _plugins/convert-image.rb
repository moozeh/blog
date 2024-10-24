Jekyll::Hooks.register :posts, :pre_render do |post|
  def convert_image_syntax(content)
    # 이미지 패턴 매칭 개선
    content.gsub(/!\[\[(.*?)\|?(\d*)\]\]/) do |match|
      file_name = $1.strip
      size = $2.strip

      if size.empty?
        "![#{file_name}](/assets/img/#{file_name})"
      else
        "![#{file_name}](/assets/img/#{file_name}){: width=\"#{size}px\"}"
      end
    end
  end

  # 변환된 내용을 post.content에 적용
  post.content = convert_image_syntax(post.content)
end
