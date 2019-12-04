require 'sinatra'

helpers do
  def is_logged_in?
    (params["token"] == 'fake-token-0')? true : false
  end
end

get '/health' do
  status 200
  body ''
end

post '/users/sign_in' do
  if params["username"] == "tenpo" && params["password"] == "tenpotenpo"
    # access_token = JWT.encode ...
    token = 'fake-token-0'
    # session["access_token"] = access_token
    headers['token'] = token
    # Successfuly logged in
    redirect to("/"), 302
  else
    status 403
    body "Wrong username or password"
  end
end

# curl -X POST "http://localhost/users/signup" -d "username=asd&password=213213" -sv
# curl -X POST "http://localhost/users/signup" -sv
post '/users/signup' do
  # routine to create a registered user
  username = params["username"]
  password = params["password"]
  if username.nil? || username.empty?
    status 401
    body "Username / Password validation failed"
  else
    body "User with #{username} created."
  end
end

# curl -X POST "http://localhost/users/sign_out" -d "token=2131231" -sv
# curl -X POST "http://localhost/users/sign_out" -d "token=fake-token-0" -sv
post '/users/sign_out' do
  # token = request.env["token"] || request["token"] || params["token"]
  if is_logged_in?
    # session["access_token"] = nil
    body "Logged Out."
    redirect to("/"), 302
  else
    status 401
  end
end

# curl -X GET http://localhost/1000/history
get '/:user_id/history' do
  # user     = User.find()
  # @history = user.history
  body "History for Bob (#{[params[:user_id]]}): ..." # history.erb
end

# curl -X GET "http://localhost/sum?a=10&b=1000222" -sv
# curl -X GET "http://localhost/sum?a=333&b=1&token=fake-token-0 -sv
get '/sum' do
  if is_logged_in?
    begin
      a = request["a"].to_i
      b = request["b"].to_i
      body "#{a + b}"
    rescue Exception => e
      "Bad math expression: #{e.message}."
    end
  else
    status 401
  end
end

run Sinatra::Application
