Jekyll::Hooks.register :posts, :pre_render do |post|
  doc = post.content
  # 이미지 크기 조정 문법 매칭 (탭이나 공백을 포함한 패턴)
  matches = doc.scan(/!\[\[(.*?)\s*\|?\s*(\d*)\]\]/)
  matches.each do |match|
    file_name = match[0]
    size = match[1]

    if size.empty?
      # 크기가 지정되지 않은 경우
      post.content = doc.gsub(
        "![[#{file_name}]]",
        "![#{file_name}](/assets/img/#{file_name})"
      )
    else
      # 크기가 지정된 경우
      post.content = doc.gsub(
        /!\[\[#{Regexp.escape(file_name)}\s*\|\s*#{size}\]\]/,
        "![#{file_name}](/assets/img/#{file_name}){: width=\"#{size}px\"}"
      )
    end
  end
end
