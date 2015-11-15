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

  def initialize git_remote_url, repo_directory, branch, message
    @repo_directory = repo_directory
    @branch = branch
    @message = message
    @git_remote_url = git_remote_url
  end

  # Returns an XcodeBumpStatus
  def bump_from_github_push_hook json
    # Check to make sure the push wasn't this script
    # Our pushes should always contain only one commit
    if (json['ref'] == "refs/heads/#{@branch}" &&
        json['commits'][0]['author']['username'] != GITHUB_USERNAME &&
        json['commits'][0]['message'] != @message)

      repo_name = json['repository']['full_name']

      return bump_branch(repo_name)
    else
      return XcodeBumpStatus::NOT_UPDATED
    end
  end

  # Returns an XcodeBumpStatus
  def bump_branch repo_name
    unless pull_branch repo_name
      return XcodeBumpStatus::ERROR
    end

    unless bump_version
      return XcodeBumpStatus::ERROR
    end

    return XcodeBumpStatus::UPDATED
  end

  def pull_branch repo_name
    directory = "#{@repo_directory}/#{repo_name}"
    
    if !Dir.exists?(directory)
      thing = FileUtils.mkdir_p directory

      unless system "git clone #{@git_remote_url} #{directory}"
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
    return 0
  end

end
