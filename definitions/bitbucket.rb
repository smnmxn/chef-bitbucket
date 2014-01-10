
define :bitbucket, :action => :enable, :repo => nil, :branch => 'master', :user => 'root' do

  include_recipe 'ssh_known_hosts'
  chef_gem 'httparty' do
    version "0.11.0"
  end

  if params[:action] == :enable
    # create their ssh key
    execute 'generate ssh key' do
      user params[:user]
      creates "/home/#{params[:user]}/.ssh/id_rsa"
      command "ssh-keygen -t rsa -q -f /home/#{params[:user]}/.ssh/id_rsa -P ''"
      notifies :create, "ruby_block[add_ssh_key_to_bitbucket]", :immediately
      notifies :run, "execute[add_bitbucket_to_known_hosts]", :immediately
    end

    # add bitbucket.org to known hosts, so future deploys won't be interrupted
    execute "add_bitbucket_to_known_hosts" do
      action :nothing # only run when ssh key is created
      user params[:user]
      command "ssh-keyscan -H bitbucket.org >> /home/#{params[:user]}/.ssh/known_hosts"
    end

    # send id_rsa.pub over to Bitbucket as a new deploy key
    ruby_block "add_ssh_key_to_bitbucket" do
      action :nothing # only run when ssh key is created
  
      block do
        require 'httparty'
        url = "https://api.bitbucket.org/1.0/repositories/#{node['bitbucket']['user']}/#{params[:repo]}/deploy-keys"
        response = HTTParty.post(url, {
          :basic_auth => {
            :username => node['bitbucket']['user'],
            :password => node['bitbucket']['pass']
          },
          :body => {
            :label => "#{params[:user]}@" + node['fqdn'],
            :key => File.read("/home/#{params[:user]}/.ssh/id_rsa.pub")
          }
        })

        puts response.code

        unless response.code == 200 or response.code == 201
          Chef::Log.warn("Could not add deploy key to Bitbucket, response: #{response.body}")
          Chef::Log.warn("Add the key manually:")
          Chef::Log.info(File.read('~/.ssh/id_rsa.pub'))
        end 
      end       
    end

     git params[:name] do
        user params[:user]
        retries 5
        retry_delay 5
        reference params[:branch]
        repository "git@bitbucket.org:#{node['bitbucket']['user']}/#{params[:repo]}.git"
        action :sync
    end
  end
end