module Jekyll
  class DraftFilter < Generator
    safe true
    priority :highest

    def generate(site)
      # 모든 posts에서 draft: true인 항목 제거
      site.posts.docs = site.posts.docs.reject { |post| post.data['draft'] == true }

      # 다른 collections에서도 draft: true인 항목 제거
      site.collections.each do |_, collection|
        next if collection.label == 'posts'
        collection.docs = collection.docs.reject { |doc| doc.data['draft'] == true }
      end
    end
  end
end
