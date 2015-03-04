require 'capistrano/notifier'

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
    IO.popen("#{curl_command} #{curl_url} #{curl_options}", 'w') do |io|
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
    template = ''
    (cap.notifier_kibana_options[:curl_option_templates] || {}).each do |key, val|
      template += " -d '#{key}=#{val.gsub("'", "\\'")}'"
    end
    ERB.new(template).result(binding)
  end

  def curl_body
    ERB.new(cap.notifier_kibana_options[:curl_body_template] || '').result(binding)
  end
end

if Capistrano::Configuration.instance
  Capistrano::Notifier::Kibana.load_into(Capistrano::Configuration.instance)
end
