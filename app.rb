require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

configure do
  enable :sessions
  
  # ОТКРЫТЬ ЕСЛИ НЕТ ФАЙЛА С БД
  
  # db = get_db
  # db.execute 'CREATE TABLE IF NOT EXISTS 
  #             "Users"(
  #             "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
  #             "username" TEXT, 
  #             "phone" TEXT, 
  #             "datestamp" TEXT, 
  #             "barber" TEXT, 
  #             "color" TEXT)'
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Профиль'
  end
end

before '/secure/*' do
  unless session[:identity]
     session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/about' do
  erb :about
end

get '/visit' do
  erb :visit
end

post '/visit' do

  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @color = params[:color]

  hh = {
    :username => 'Введите имя', 
    :phone => 'Введите телефон', 
    :datetime => 'Введите дату и время'
  }

  # Вывод ошибки по каждому input за раз
  
  # hh.each do |key, value|
  #   if params[key] == ''
  #     @error = hh[key]
  #     return  erb :visit
  #   end
  # end

  @error = hh.select {|key,_| params[key] == ""}.values.join(", ")

  if @error != ''
    return erb :visit
  end

  db = get_db
  db.execute 'insert into
              Users(
                username,
                phone,
                datestamp,
                barber,
                color)
              values(?,?,?,?,?)', [@username, @phone, @datetime, @barber, @color]

  erb "Ok, usernameis #{@username}, #{@phone}, #{@datetime}, #{@barber}, #{@color}"

end

get '/contacts' do
  erb :contacts
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end

get '/showusers' do
  erb :showusers
end

# Экземпляр объекта нужно обязательно вернуть так как в configure код будет выполнен 1 раз при инициализации (Когда изменили код)
def get_db
  db = SQLite3::Database.new 'barberschop.db'
  db.results_as_hash = true
  return db
end
