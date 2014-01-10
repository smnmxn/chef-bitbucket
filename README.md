Chef bitbucket LWRP
==================
Chef LWRP for deploying bitbucket repositories in your chef recipes.

Generates SSH keys, submits to the bitbucket API and deploys the repository.

Requirements
------------

Git - Git is required to pull repos from bitbucket
ssh_known_hosts - Required for generating SSH keys


Attributes
------------

The following attributes are required to use this provider:

* `node['bitbucket']['user']` - Your Bitbucket username
* `node['bitbucket']['pass']` - Your Bitbucket password


Usage
------------

Install this cookbook, add dependancy to metadata.rb and in your recipe add `include_recipe "bitbucket"`.  You can then access the provider as detailed below.


#### Attribute Parameters
`repo` - Name of the bitbucket repository
`branch` - Branch to checkout
`user` - Runs as this user (defaults to root) 


#### Examples
```ruby
  #Checkout code from bitbucket
  bitbucket '/path/to/deploy' do
    repo myrepo
  end
```

```ruby
  #Checkout develop branch from bitbucket
  bitbucket '/path/to/deploy' do
    repo myrepo
    branch develop
  end
```


License and Authors
-------------------
Authors: Simon Moxon

Credits: Original idea and code borrowed from @clarkdave: http://clarkdave.net/2013/02/send-deploy-keys-to-bitbucket-in-a-chef-recipe/