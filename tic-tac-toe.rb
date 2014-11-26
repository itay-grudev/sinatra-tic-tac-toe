require 'sinatra'
require 'sinatra/reloader' if ARGV.include? 'dev'

enable :sessions

# Pops the game mode selection menu
get '/' do
  erb :index
end

# Implements the game mode selection and redirects to the game screen
get '/mode/:mode' do
  if params[:mode] == 'pvp'
    session[:mode] = :pvp
  else
    session[:mode] = :ai
  end

  redirect to('/game')
end

# Intializes the game
get '/game' do
  # Populates an empty matrix (no moves had been played yet)
  session[:matrix] = [ [nil, nil, nil], [nil, nil, nil], [nil, nil, nil] ]
  session[:first] = [true, false].sample # Generates a random bool
  session[:itterate] = false # Itterates over the players
  session[:error] = nil
  session[:game_end] = nil

  bot_do_if_modeai

  erb :game # renders the game screen
end

# Makes a move
get '/move/:row/:col' do
  session[:error] = nil

  # Invalid move checks
  row = params[:row].to_i
  col = params[:col].to_i
  # Check if row and col are in the range [0, 2]
  if 0 <= row  and row < 3 and 0 <= col and col < 3
    # Check if the hadn't been played alreadt
    if session[:matrix][row][col] == nil
      # If OK, commit move and change player
      session[:matrix][row][col] = session[:itterate]
      # Change the active player
      session[:itterate] = ! session[:itterate]

      bot_do_if_modeai unless check_win

      return erb :game
    end
  end

  session[:error] = 'Invalid move'

  erb :game
end

def bot_do_if_modeai
  return false if session[:mode] != :ai


  # Change the active player
  # session[:itterate] = ! session[:itterate]

  check_win
end

# Win conditions implemented here
def check_win
  matrix = session[:matrix]
  session[:winner] = nil

  # Itterate from 1 to 3-rd column
  (0...3).each do |i|
    # check by columns
    if matrix[i][0] == matrix[i][1] and matrix[i][1] == matrix[i][2] and matrix[i][0] != nil
      session[:winner] = matrix[i][0] # Either true or false - which player won
    end
    # check by rows
    if matrix[0][i] == matrix[1][i] and matrix[1][i] == matrix[2][i] and matrix[0][i] != nil
      session[:winner] = matrix[0][i]
    end
  end

  # Check primary diagonal
  if matrix[0][0] == matrix[1][1] and matrix[1][1] == matrix[2][2] and matrix[1][1] != nil
    session[:winner] = matrix[1][1]
  end
  
  # Check secondary diagonal
  if matrix[0][2] == matrix[1][1] and matrix[1][1] == matrix[2][0] and matrix[1][1] != nil
    session[:winner] = matrix[1][1]
  end

  session[:game_end] = :win if ! session[:winner].nil?
  session[:game_end] = :tie if matrix.all? { |v| v.all? { |p| p != nil } }

  return ! session[:game_end].nil?
end
