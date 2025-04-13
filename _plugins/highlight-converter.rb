Jekyll::Hooks.register :posts, :pre_render do |post|
  def convert_highlights(content)
    # == 로 감싸진 텍스트를 하이라이트로 변환
    # 정규표현식: ==텍스트== 패턴을 찾아 HTML span으로 변환
    content.gsub(/==(.+?)==/) do |match|
      "<span class=\"highlight\">#{$1}</span>"
    end
  end

  post.content = convert_highlights(post.content)
end
