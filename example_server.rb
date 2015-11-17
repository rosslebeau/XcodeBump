# myapp.rb
require 'sinatra'
require 'json'
require 'fileutils'
require 'pry'
require 'pry-byebug'

require './xcode_bump'



post '/github_bump' do
  json_body = JSON.parse request.body.read
  puts json_body
  
  response.status = 204

  repo_name = json_body['repository']['full_name']
  git_remote_ssh_url = json_body['repository']['ssh_url']

  bump = XcodeBump.new(git_remote_ssh_url, "../xcbTest/#{repo_name}", 'master', 'Bump build number')
  bump_status = bump.bump_from_github_push_hook(json_body)

  if bump_status == XcodeBumpStatus::ERROR
    response.status = 500
  end
end


