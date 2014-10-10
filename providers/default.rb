
def whyrun_supported?
  true
end

use_inline_resources if defined?(use_inline_resources)

action :run do


  chef_gem 'httparty' do
    version "0.11.0"
  end

  if new_resource.user == 'root'
    home_dir = "/root"
    Chef::Log.warn("Installing as root")
  else
    home_dir = "/home/#{new_resource.user}"
  end

    execute 'generate ssh key' do
      user new_resource.user
      creates "#{home_dir}/.ssh/id_rsa"
      command "ssh-keygen -t rsa -q -f #{home_dir}/.ssh/id_rsa -P ''"
      notifies :run, "execute[add_bitbucket_to_known_hosts]", :immediately
      notifies :run, "ruby_block[add_ssh_key_to_bitbucket]", :immediately
    end

    # add bitbucket.org to known hosts, so future deploys won't be interrupted
    execute "add_bitbucket_to_known_hosts" do
      action :nothing # only run when ssh key is created
      user new_resource.user
      command "ssh-keyscan -H bitbucket.org >> #{home_dir}/.ssh/known_hosts"
    end

    # send id_rsa.pub over to Bitbucket as a new deploy key
    
      ruby_block "add_ssh_key_to_bitbucket" do
        unless node['bitbucket'] && node['bitbucket']['deploy_key'] && node['bitbucket']['deploy_key']["#{new_resource.repo}"]
          action :create
        else
          action :nothing
        end
        block do
          require 'httparty'
          url = "https://api.bitbucket.org/1.0/repositories/meetupcall/#{new_resource.repo}/deploy-keys"
          response = HTTParty.post(url, {
            :basic_auth => {
              :username => node['bitbucket']['user'],
              :password => node['bitbucket']['pass']
            },
            :body => {
              :label => "#{new_resource.user}@" + node['fqdn'],
              :key => ::File.read("#{home_dir}/.ssh/id_rsa.pub")
            }
          })
          puts response.code
          unless response.code == 200 or response.code == 201
            Chef::Log.warn("Could not add deploy key to Bitbucket, response: #{response.body}")
            Chef::Log.warn("Add the key manually:")
            Chef::Log.info(::File.read('~/.ssh/id_rsa.pub'))
          else
            node.set['bitbucket']['deploy_key']["#{new_resource.repo}"] = response.body
            node.save
          end 
        end           
    end

    git new_resource.name do
        user new_resource.user
        retries 5
        retry_delay 5
        reference new_resource.branch
        repository "git@bitbucket.org:meetupcall/#{new_resource.repo}.git"
        action :sync
    end
end
