require 'capistrano/notifier'

# Requiring ERB...
begin
  require 'action_mailer'
rescue LoadError
  require 'actionmailer'
end

module Capistrano::Notifier::Http
  def self.load_into(configuration)
    configuration.load do
      namespace :deploy do
        namespace :notify do
          desc 'Send a pre deployment notification via http.'
          task :pre_http do
            Capistrano::Notifier::Http::Pre.new(configuration).perform
          end

          desc 'Send a post deployment notification via http.'
          task :post_http do
            Capistrano::Notifier::Http::Post.new(configuration).perform
          end
        end
      end

      before 'deploy', 'deploy:notify:pre_http'
      after 'deploy:restart', 'deploy:notify:post_http'
    end
  end

  module Common
    private

    def curl_command
      cap.notifier_http_options[:command] || 'curl'
    end

    def curl_url
      cap.notifier_http_options[:url]
    end

    def curl_options
      template = ''
      (cap.notifier_http_options[:curl_option_templates] || {}).each do |key, val|
        template += " -d '#{key}=#{val.gsub("'", "\\'")}'"
      end
      ERB.new(template).result(binding)
    end

    def curl_body
      ERB.new(cap.notifier_http_options[:curl_body_template] || '').result(binding)
    end

    def template(template_name)
      config_file = "#{templates_path}/#{template_name}"

      unless File.exists?(config_file)
        config_file = File.join(File.dirname(__FILE__), "templates/#{template_name}")
      end

      ERB.new(File.read(config_file), nil, '-').result(binding)
    end

    def templates_path
      cap.notifier_http_options[:templates_path] || 'config/deploy/templates'
    end

    def text
      template(body_template)
    end
  end

  class Pre < Capistrano::Notifier::Base
    include Capistrano::Notifier::Http::Common

    def perform
      IO.popen("#{curl_command} #{curl_url} #{curl_options}", 'w') do |io|
        io.puts curl_body
      end
    end

    def body_template
      cap.notifier_http_options[:template] || "http.pre.body.erb"
    end
  end

  class Post < Capistrano::Notifier::Base
    include Capistrano::Notifier::Http::Common

    def perform
      IO.popen("#{curl_command} #{curl_url} #{curl_options}", 'w') do |io|
        io.puts curl_body
      end
    end

    def body_template
      cap.notifier_http_options[:template] || "http.post.body.erb"
    end
  end

end

if Capistrano::Configuration.instance
  Capistrano::Notifier::Http.load_into(Capistrano::Configuration.instance)
end
