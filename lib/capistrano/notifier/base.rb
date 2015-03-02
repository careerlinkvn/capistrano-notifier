class Capistrano::Notifier::Base
  def initialize(capistrano)
    @cap = capistrano
  end

  private

  def application
    cap.application
  end

  def branch
    cap.respond_to?(:branch) ? cap.branch : 'master'
  end

  def cap
    @cap
  end

  def git_current_revision
    cap.current_revision.try(:[], 0,7) if cap.respond_to?(:current_revision)
  end

  def git_log
    return unless git_range

    `git log --stat #{git_range} --no-merges --format=format:"%h: %s (%an)"`
  end

  def git_previous_revision
    cap.previous_revision.try(:[], 0,7) if cap.respond_to?(:previous_revision)
  end

  def git_range
    return unless git_previous_revision && git_current_revision

    "#{git_previous_revision}..#{git_current_revision}"
  end

  def git_compare_params
    return '' unless git_range

    return git_range.gsub('..', '...') if github
    return git_range.split('..').reverse.join('..') + '#diff' if bitbucket
  end

  def git_commit_prefix
    "#{git_prefix}/commit"
  end

  def git_compare_prefix
    return "#{git_prefix}/compare" if github
    return "#{git_prefix}/branches/compare" if bitbucket
  end

  def git_prefix
    return giturl if giturl
    return "https://github.com/#{github}" if github
    return "https://bitbucket.org/#{bitbucket}" if bitbucket
  end

  def github
    cap.github if cap.respond_to? :github
  end

  def bitbucket
    cap.bitbucket if cap.respond_to? :bitbucket
  end

  def giturl
    cap.giturl if cap.respond_to? :giturl
  end

  def now
    @now ||= Time.now
  end

  def stage
    return cap.webistrano_stage if cap.respond_to? :webistrano_stage
    return cap.stage if cap.respond_to? :stage
  end

  def hosts
    cap.find_servers_for_task(cap.current_task).map {|server|
      server.host
    }.join(',')
  end

  def user_name
    return user = cap.webistrano_user if cap.respond_to? :webistrano_user
    return user = ENV['DEPLOYER'] if user.nil?
    return user = `git config --get user.name`.strip if user.nil?
  end
end

# Band-aid for issue with Capistrano
# https://github.com/capistrano/capistrano/issues/168#issuecomment-4144687
Capistrano::Configuration::Namespaces::Namespace.class_eval do
  def capture(*args)
    parent.capture *args
  end
end
