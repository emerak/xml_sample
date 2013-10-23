Xmls::Application.routes.draw do
  resources :responsexmls
  get 'requestxmls/receive_xml'
end
