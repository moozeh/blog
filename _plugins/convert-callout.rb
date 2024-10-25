Jekyll::Hooks.register :posts, :pre_render do |post|
  def convert_callouts(content)
    lines = content.split("\n")
    result = []
    in_callout = false
    current_callout = []

    lines.each do |line|
      # 콜아웃 시작 라인 매칭
      if match = line.match(/^\s*>\s*\[!(\w+)\](?:\s*(.+))?$/)
        in_callout = true
        type = match[1].downcase
        title = match[2] || type.capitalize

        # prompt 타입 결정
        prompt_type = case type
                      when 'note' then 'info'
                      when 'warning' then 'warning'
                      when 'danger' then 'danger'
                      when 'tip' then 'tip'
                      when 'important' then 'important'  # 추가
                      else 'info'
                      end

        current_callout = ["{: .prompt-#{prompt_type}}", "> **#{title}**", ">"]
        next
      end

      if in_callout
        if line.start_with?('>')
          # 빈 콜아웃 라인 처리
          if line.match?(/^\s*>\s*$/)
            current_callout << ">"
          else
            # 콜아웃 내용 처리
            content_line = line.sub(/^\s*>\s?/, '').rstrip
            current_callout << "> #{content_line}"
          end
        else
          # 콜아웃 종료
          in_callout = false
          result.concat(current_callout)
          result << line
        end
      else
        result << line
      end
    end

    # 마지막 콜아웃 처리
    result.concat(current_callout) if in_callout

    result.join("\n")
  end

  post.content = convert_callouts(post.content)
end
