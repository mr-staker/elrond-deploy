require 'json'

def scp(file)
  sh "scp #{file} #{ENV['target']}:#{file}"
end

def ssh(cmd)
  sh "ssh #{ENV['target']} sudo #{cmd}"
end

def setup(cmd)
  ssh "sudo ./setup #{cmd}"
end

desc 'Sync setup script'
task :setup do
  scp 'setup'
  scp 'client.rb'
  ssh 'chmod +x setup'
  setup 'client_rb'
end

desc 'Install Cinc Client on remote target'
task cinc_install: %i[setup] do
  setup "install_cinc #{ENV['version']}"
  ssh 'sudo ln -sf /opt/cinc /opt/chef'
end

desc 'Invoke berks install'
task :install do
  sh 'berks install'
end

desc 'Invoke berks update'
task :update do
  sh 'berks update'
end

desc 'Builds cookbooks tarball'
task :build do
  sh 'berks vendor cookbooks && tar -czf cookbooks.tar.gz cookbooks'
  rm_rf 'cookbooks'
end

desc 'Sync cookbooks tarball to target host'
task sync: %i[setup build] do
  scp 'cookbooks.tar.gz'
  rm_f 'cookbooks.tar.gz'

  setup 'expand_cookbooks'
end

desc 'Run cinc-solo on remote target'
task run: %i[setup] do
  dna = {
    run_list: "role-#{ENV['role']}::default"
  }

  File.write 'dna.json', dna.to_json
  scp 'dna.json'
  File.delete 'dna.json'

  setup 'dna_json'
  ssh 'sudo cinc-solo --json-attributes /etc/cinc/dna.json'
end

desc 'Cleanup build artefacts'
task :clean do
  rm_f 'dna.json'
  rm_f 'cookbooks.tar.gz'
  rm_rf 'cookbooks'
end
