ActionController::Routing::Routes.draw do |map|
  map.connect "/user_messenger", :controller => "user_messenger", :action => "index"
end
