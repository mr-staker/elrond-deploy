name 'role-host001'
maintainer 'Mr Staker'
maintainer_email 'hello@mr.staker.ltd'
version '1.0.0'
source_url 'https://github.com/mr-staker/cinc-deploy'
issues_url 'https://github.com/mr-staker/cinc-deploy/issues'
chef_version '>= 16'
%w[centos debian oracle redhat ubuntu].each do |os|
  supports os
end
license 'MIT'
description 'Role cookbook to setup Elrond node(s) server'

depends 'elrond'
