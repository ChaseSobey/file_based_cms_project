require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(file_path)
  content = File.read(file_path)
  extension = File.extname(file_path)
  
  case extension
  when '.md'
    erb render_markdown(content)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  end
end

root = File.expand_path('..', __FILE__)

get '/' do
  @files = Dir.glob(root + '/data/*').map do |file|
    File.basename(file)
  end
  
  erb :index
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  if params[:username] == 'admin' && params[:password] == 'secret'
    session[:username] = params[:username]
    session[:message] = 'Welcome!'
  else
    session[:message] = 'Invalid credentials'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:message] = 'You have been signed out.'
  redirect '/'
end

post '/create' do
  filename = params[:filename].to_s
  
  if filename.size == 0
    session[:message] = 'A name is required'
    status 422
    erb :new
  else
    file_path = File.join(root, 'data', filename)
    File.write(file_path, '')
    session[:message] = "#{params[:filename]} has been created."
    
    redirect '/'
  end
end

get '/:filename/edit' do
  file_path = root + '/data/' + params[:filename]
  
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit
end

post '/:filename/delete' do
  file_path = root + '/data/' + params[:filename]
  File.delete(file_path)
  
  session[:message] = "#{params[:filename]} has been deleted."
  redirect '/'
end

post '/:filename' do
  file_path = root + '/data/' + params[:filename]
  
  File.write(file_path, params[:content])
  
 session[:message] = "#{params[:filename]} has been updated."
 redirect "/"
end

get '/new' do
  erb :new, layout: :layout
end

get '/:filename' do
  path = root + '/data/' + params[:filename]
  
  if File.file?(path)
    load_file_content(path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end
