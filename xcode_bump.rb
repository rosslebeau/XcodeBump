require 'xcodeproj'

require './github_info'

module XcodeBumpStatus
  UPDATED = 'UPDATED'
  NOT_UPDATED = 'NOT_UPDATED'
  ERROR = 'ERROR'
end

class XcodeBump

  attr_reader :projectName

  #@bump_branch = 'master'
  #bump_msg = 'Bump build number'

  def initialize git_remote_ssh_url, repo_directory, branch, message
    @git_remote_ssh_url = git_remote_ssh_url
    @repo_directory = repo_directory
    @branch = branch
    @message = message
  end

  # Returns an XcodeBumpStatus
  def bump_from_github_push_hook json
    # Check to make sure the push wasn't this script
    # Our pushes should always contain only one commit
    if (json['ref'] == "refs/heads/#{@branch}" &&
        json['commits'][0]['author']['username'] != GITHUB_USERNAME &&
        json['commits'][0]['message'] != @message)

      return bump_branch
    else
      return XcodeBumpStatus::NOT_UPDATED
    end
  end

  # Returns an XcodeBumpStatus
  def bump_branch
    directory = "#{@repo_directory}"

    unless pull_branch directory, @git_remote_ssh_url
      return XcodeBumpStatus::ERROR
    end

    unless bump_version directory
      return XcodeBumpStatus::ERROR
    end

    return XcodeBumpStatus::UPDATED
  end

  def pull_branch
    if !Dir.exists?(directory)
      thing = FileUtils.mkdir_p directory

      unless system "git clone #{@git_remote_ssh_url} #{directory}"
        return false
      end
    end

    Dir.chdir(directory) do
      unless system "git fetch"
        return false
      end

      unless system "git checkout #{@branch}"
        return false
      end

      unless system "git merge origin/#{@branch}"
        return false
      end
    end
    
    return true
  end

  def bump_version
    Dir.chdir(directory) do
  end

end
