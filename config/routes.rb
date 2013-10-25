Xmls::Application.routes.draw do
  resources :responsexmls
  resources :requestxmls
  post 'requestxmls/receive_xml'
end
