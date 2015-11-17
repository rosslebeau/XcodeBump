require 'xcodeproj'
require 'set'
require 'cfpropertylist'

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
    if (json['ref'] != "refs/heads/#{@branch}")
      return XcodeBumpStatus::NOT_UPDATED
    elsif (json['commits'] != nil && json['commits'].count > 0 && # The commits can be empty, e.g. in a forced push
          json['commits'][0]['author']['username'] == GITHUB_USERNAME && json['commits'][0]['message'] == @message)
      return XcodeBumpStatus::NOT_UPDATED
    else
      return bump_branch
    end
  end

  # Returns an XcodeBumpStatus
  def bump_branch
    unless pull_branch
      return XcodeBumpStatus::ERROR
    end

    unless bump_version
      return XcodeBumpStatus::ERROR
    end

    unless push_branch
      return XcodeBumpStatus::ERROR
    end

    return XcodeBumpStatus::UPDATED
  end

  def pull_branch
    if !Dir.exists?(@repo_directory)
      thing = FileUtils.mkdir_p @repo_directory

      unless system "git clone #{@git_remote_ssh_url} #{@repo_directory}"
        return false
      end
    end

    Dir.chdir(@repo_directory) do
      unless system "git fetch"
        return false
      end

      unless system "git checkout #{@branch}"
        return false
      end

      unless system "git reset --hard origin/#{@branch}"
        return false
      end
    end
    
    return true
  end

  def push_branch
    Dir.chdir(@repo_directory) do
      unless system "git add -A"
        return false
      end

      unless system "git com -m \"#{@message}\""
        return false
      end

      unless system "git push origin #{@branch}"
        return false
      end
    end

    return true
  end

  def bump_version
    proj_file = Dir.glob("#{@repo_directory}/**/*.xcodeproj").first
    unless proj_file
      return false
    end

    proj_file_dir = File.dirname proj_file

    proj = Xcodeproj::Project.open(proj_file)

    info_plists_set = Set.new

    proj.targets.each do |target|
      target.build_configurations.each do |build_config|
        info_plist_file_relative_xcodeproj = build_config.build_settings['INFOPLIST_FILE']
        info_plists_set << "#{proj_file_dir}/#{info_plist_file_relative_xcodeproj}"
      end
    end

    unless info_plists_set.count > 0
      return false
    end

    info_plists_set.each do |info_plist_file|
      info_plist_obj = CFPropertyList::List.new(:file => info_plist_file)
      info_plist_data = CFPropertyList.native_types(info_plist_obj.value)

      bundle_version = info_plist_data['CFBundleVersion'].to_i
      bundle_version = bundle_version + 1
      info_plist_data['CFBundleVersion'] = bundle_version.to_s

      info_plist_obj.value = CFPropertyList.guess(info_plist_data)
      info_plist_obj.save(info_plist_file, CFPropertyList::List::FORMAT_XML, {:formatted => true})
    end

    return true
  end

end
