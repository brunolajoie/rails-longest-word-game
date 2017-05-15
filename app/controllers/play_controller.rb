require 'open-uri'
require 'json'
require 'timeout'

class PlayController < ApplicationController
  def home
    session[:results] = []
  end

  def game
    @grid = generate_grid(9)
    @start_time = Time.now.to_i
  end

  def score
    @answer = params[:form_answer]
    @start_time = params[:start_time].to_i
    @end_time = Time.now.to_i
    @grid = params[:grid].split()
    @result = run_game(@answer, @grid, @start_time, @end_time)
    session[:results] << @result
  end

  private

  def generate_grid(grid_size)
    alphabet = ("A".."Z").to_a
    grid = []
    grid_size.times { grid << alphabet.sample }
    return grid
  end

  def translate(attempt, grid)
    # check if attempt(string) is part of the grid(array)
    attempt.upcase.chars.each do |letter|
      return "not in the grid" if attempt.upcase.chars.count(letter) > grid.count(letter)
    end
    # check if attempts has a translation. if yes, return the translated word, otherwise return nil
    begin
      Timeout::timeout(3) do
        url = "https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=a517dce0-e4b2-4104-9f56-133797c508a2&input=#{attempt}"
        api_hash = JSON.parse(open(url).read)
        translation = api_hash["outputs"][0]["output"]
        translation.downcase == attempt.downcase ? nil : translation
      end
    rescue
      return "API error" # use the dictionnary method instead
    end
  end

  def scoring(time, translation, grid)
    return 0 if translation.nil? || translation == "not in the grid"
    time_score = time < 30 ? 1 - (time / 30) : 0 # 30 seconds max, linear scale.
    word_score = translation.length.to_f / grid.length # best if max size. linear scale.
    return 0.3 * time_score + 0.7 * word_score
  end

  def messaging(translation)
    if translation.nil?
      return "not an english word"
    elsif translation == "not in the grid"
      return "not in the grid"
    elsif translation = "API error"
      return "API error"
    else
      return "well done"
    end
  end

  def run_game(attempt, grid, start_time, end_time)
    # TODO: runs the game and return detailed hash of result
    time = end_time - start_time
    translation = translate(attempt, grid)
    score = scoring(time, translation, grid)
    message = messaging(translation)
    return { time: time, translation: translation, score: score, message: message }
  end
end

