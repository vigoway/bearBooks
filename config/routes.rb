BearBooks::Application.routes.draw do
  root :to => "home#index"
  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users
  post '/users/uploadBook' => 'users#uploadBook'
  post '/users/deleteBook' => 'users#deleteBook'
  post 'users/show' => 'users#show'
  get '/usersPool'  => 'users#usersPool'
  post 'users/likeBook' => 'users#likeBook'
  post 'users/addFriend' => 'users#addFriend'
  post 'users/deFriend' => 'users#deFriend'
  post 'acceptReq'=> 'users#acceptReq'
  post 'declineReq' => 'users#declineReq'
  post '/users/addComment' => 'users#addComment'
end