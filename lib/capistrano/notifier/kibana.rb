require 'capistrano/notifier'
require 'json'

class Capistrano::Notifier::Kibana < Capistrano::Notifier::Base
  def self.load_into(configuration)
    configuration.load do
      namespace :deploy do
        namespace :notify do
          desc 'Send a post deployment notification via http.'
          task :kibana do
            Capistrano::Notifier::Kibana.new(configuration).perform
          end
        end
      end

      after 'deploy:restart', 'deploy:notify:kibana'
    end
  end

  def perform
    IO.popen("#{curl_command} -XPOST -H 'Content-type: text/json' #{curl_url} -d '#{curl_options}'", 'w') do |io|
      io.puts curl_body
    end
  end

  private

  def curl_command
    cap.notifier_kibana_options[:command] || 'curl'
  end

  def curl_url
    cap.notifier_kibana_options[:url]
  end

  def curl_options
    options = (cap.notifier_kibana_options[:curl_option_templates] || {})
    template = JSON.generate(options)
    ERB.new(template).result(binding)
  end

  def curl_body
    ERB.new(cap.notifier_kibana_options[:curl_body_template] || '').result(binding)
  end
end

if Capistrano::Configuration.instance
  Capistrano::Notifier::Kibana.load_into(Capistrano::Configuration.instance)
end
