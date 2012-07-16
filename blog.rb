require 'sinatra'
require 'haml'
require 'data_mapper'
require 'dm-postgres-adapter'
require 'pg'

DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/blogdb')

class Post
  include DataMapper::Resource

  property :id, Serial
  property :subject, String
  property :content, Text
  property :created, DateTime, :default => Time.now
  property :permalink, String

  before :valid?, :set_permalink

  private
    def set_permalink
      self.permalink = id
    end
end

DataMapper.finalize
Post.auto_upgrade!

class NewestPost
  attr_accessor :subject, :content

  def initialize
    @subject = ''
    @content = ''
  end
end

def render_blogs(subject = '', content = '', error = '')
  blog_listing = Post.all(:order => :created.desc)
  haml :blogs, :locals => {:subject => subject, :content => content, :error => error, :blog_listing => blog_listing}
end

newest_post = NewestPost.new

get '/blog' do
  render_blogs(newest_post.subject, newest_post.content, params[:error])
end

post '/blog/newpost' do
  newest_post.subject = params[:subject]
  newest_post.content = params[:content]
  error = ''

  if newest_post.subject.length > 0 && newest_post.content.length > 0
    post = Post.create(:subject => params[:subject], :content => params[:content])
    redirect '/blog/' + post.id.to_s
  else
    error = 'Add missing subject and/or content!'
    render_blogs(params[:subject], params[:content], error)
  end
end

get '/blog/:permalink' do |permalink|
  perma_post = Post.first(:id => permalink)
  if perma_post == nil
    render_blogs('', '', 'That post does not exist!!')
  else
    haml :post, :locals => {:subject => perma_post.subject, :content => perma_post.content}
    #render_blogs(perma_post.subject, perma_post.content, '')
  end
end

