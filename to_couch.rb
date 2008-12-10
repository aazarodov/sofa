require 'rubygems'
require 'couchrest'

db = CouchRest.database! 'example-blog-import'

# you'll need to replace Post and Comment with whatever classes hold your data.

idmap = {};

# import all the posts
posts = Post.find :all

# to work with couchdb-example-blog, you need to keep the shape of the resulting 
# documents the same, although you are free to add new fields or omit others.

posts.each do |p|
  puts p.title
  post = {
    '_id' => p.permalink,
    :title => p.title,
    :textile => p.body,
    :html => p.description,
    :slug => p.permalink,
    :legacy_id => p.id,
    :author => {
      :email => p.user.email,
      :name => p.user.login
    },
    :updated_at => p.updated_at,
    :created_at => p.created_at
  }
  if p.section
    post[:tags] = [p.section.path]
  end
  couch_id = db.save(post)["id"]
  idmap[p.id] = couch_id
end

puts idmap.inspect

# import all the comments
comments = Comment.find :all
comments.each do |c|
  puts c.name
  post_couch_id = idmap[c.post_id]
  comment = {
    :author => {
      :name => c.name,
      :email => c.email,
      :url => c.link
    },
    :textile => c.body,
    :html => c.description,
    :post_id => post_couch_id,
    :updated_at => c.updated_at,
    :created_at => c.created_at
  }
  db.save(comment)
end