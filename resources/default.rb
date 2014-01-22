actions :run
default_action :run

attribute :repo,    :kind_of => String 
attribute :branch,  :kind_of => String, :default => 'master'
attribute :user,    :kind_of => String, :default => 'root'