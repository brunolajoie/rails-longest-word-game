Rails.application.routes.draw do
  get 'test/action1'

  get 'test/action2'


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "play#home"
  get "game", to: "play#game"
  get "score", to: "play#score"
end

