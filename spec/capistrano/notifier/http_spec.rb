require 'spec_helper'
require 'capistrano/notifier/http'

describe Capistrano::Notifier::Http::Post do
  let(:configuration) { Capistrano::Configuration.new }
  subject { described_class.new configuration }

  before :each do
    configuration.load do |configuration|
      set :bitbucket, 'example/example'
      set :notifier_http_options, {
        url: 'http://example.com',
        method: 'POST',
        curl_option_templates: {
          :chat => '1234567890',
          :msg => '<%= ERB::Util.url_encode(text) %>',
          :md5 => '<%= Digest::MD5.hexdigest("1234567890" + text + "foo") %>',
        }
      }

      set :application, 'example'
      set :branch,      'master'
      set :stage,       'test'

      set :current_revision,  '12345670000000000000000000000000'
      set :previous_revision, '890abcd0000000000000000000000000'
    end

    subject.stub(:git_log).and_return <<-LOG.gsub(/^ {6}/, '')
      1234567 This is the current commit (John Doe)
      890abcd This is the previous commit (John Doe)
    LOG
    subject.stub(:user_name).and_return "John Doe"
  end

  it { subject.send(:bitbucket).should     == 'example/example' }
  it { subject.send(:curl_command).should  == 'curl'}
  it { subject.send(:curl_url).should      == 'http://example.com'}
  it { subject.send(:curl_options).should  =~ /^ -d 'chat=1234567890' -d 'msg=/ }
end
