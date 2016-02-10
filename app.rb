#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end

# => before вызывается каждый раз при перезагрузке любой страницы

before do
	# => Инициализация БД
	init_db
end

# => configure вызывается каждый раз при конфигурвции приложения:
# => когда изменился код программы или\и перезагрузилась страница

configure do
	# => Инициализация БД
	init_db
	# => создает таблицу, если таблица не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts
	 (
	 	id INTEGER PRIMARY KEY AUTOINCREMENT,
	 	created_date DATE,
	 	content TEXT
	 	)'

	 # => создает таблицу, если таблица не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS Comments
	 (
	 	id INTEGER PRIMARY KEY AUTOINCREMENT,
	 	created_date DATE,
	 	content TEXT,
	 	post_id INTEGER
	 	)'
end

# => обработчик get-запроса /new (браузер получает страницу с сервера)

get '/' do
	# => выбираем список постов из БД

	@results = @db.execute 'select * from Posts order by id desc'

	erb :index

end

get '/new' do
	erb :new
end

# => обработчик post-запроса /new (браузер отправляет данные на сервер)

post '/new' do
	# => получаем переменную из post-запроса
  content = params[:content]
  if content.length <= 0
  	@error = "Type post text"
  	return erb :new
  end
	# => Сохранение данных в БД
	@db.execute 'insert into Posts (content, created_date) values (?, datetime())', [content]

	# => Перенаправление на главную страницу

	redirect to '/'

end

# => Вывод информации о посте

get '/details/:post_id' do

	# => Получаем переменную из url'a
	post_id = params[:post_id]


	# => Получаем список постов (у нас будет только один пост)

	results = @db.execute 'select * from Posts where id = ?', [post_id]

	# => Выбираем этот один пост в переменную @row
	@row = results[0]

	# => Выбираем комментарии для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]

	# => Возвращаем представление details.erb
	erb :details
end

# => Обработчик post-запроса /details/...
# => (браузер отправляет данные на сервер)

post '/details/:post_id' do
	# => Получаем переменную из url'a
	post_id = params[:post_id]

	# => получаем переменную из post-запроса
	content = params[:content]

	# => Сохранение данных в БД
	@db.execute 'insert into Comments
	(
		content,
		created_date,
		post_id
	)
		values 
	(
		?,
		datetime(),
		?
	)', [content, post_id]

	# => Перенаправление на главную страницу поста

	redirect to ('/details/'+ post_id)
end
