Jekyll::Hooks.register :posts, :pre_render do |post|
  def convert_code_blocks(content)
    content.gsub(/```(\w+):(.+?)\n(.*?)```/m) do |match|
      language = $1
      filename = $2.strip
      code = $3.strip

      <<~CODEBLOCK
        ```#{language}
        # File: #{filename}
        #{code}
        ```
      CODEBLOCK
    end
  end

  post.content = convert_code_blocks(post.content)
end
