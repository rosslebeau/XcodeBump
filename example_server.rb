# myapp.rb
require 'sinatra'
require 'json'
require 'fileutils'
require 'pry'
require 'pry-byebug'

require './xcode_bump'



post '/github_bump' do
  jsonBody = JSON.parse request.body.read
  #print jsonBody
  
  response.status = 204

  bump = XcodeBump.new('git@github.com:rosslebeau/buildnumbertest.git', '../xcbTest', 'master', 'Bump build number')
  bump_status = bump.bump_from_github_push_hook(jsonBody)

  if bump_status == XcodeBumpStatus::ERROR
    response.status = 500
  end
end


