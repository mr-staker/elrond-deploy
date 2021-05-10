require 'json'
require 'tmpdir'
require 'io/console'

def require_env(name)
  return unless ENV[name].nil?

  warn "Error: missing '#{name}' environment variable"
  Kernel.exit 1
end

def scp(file)
  require_env 'target'
  config = ''
  config = "-F #{ENV['config']}" if ENV['config']
  sh "scp #{config} #{file} #{ENV['target']}:#{file}"
end

def ssh(cmd, options = {})
  require_env 'target'
  config = ''
  config = "-F #{ENV['config']}" if ENV['config']

  sh "ssh #{config} #{ENV['target']} sudo #{cmd}", options
end

def setup(cmd, token = nil)
  options = if token.nil?
              {}
            else
              { verbose: false }
            end

  ssh "#{token} ./setup #{cmd}", options
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
  require_env 'version'
  setup "install_cinc #{ENV['version']}"
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
  require_env 'role'

  if ENV['vault_token'] == 'y'
    puts 'Please supply your Hasicorp Vault token to seed the node keys:'
    token = $stdin.noecho(&:gets).strip
  end

  scp 'dna'
  ssh 'chmod +x dna'
  setup "dna_json #{ENV['role']}", "VAULT_TOKEN=#{token}"
  ssh 'cinc-solo --json-attributes /etc/cinc/dna.json'
end

desc 'Cleanup build artefacts'
task :clean do
  rm_f 'cookbooks.tar.gz'
  rm_rf 'cookbooks'
  sh 'vagrant destroy -f'
  rm_rf '.vagrant'
end

desc 'Setup a validator node'
task :validator do
  require_env 'id'
  require_env 'keystore'

  id = ENV['id']
  tmp = Dir.mktmpdir

  proxy = ''
  proxy = "--proxy=#{ENV['proxy']}" if ENV['proxy']

  puts 'Please provide Elrond wallet keystore password:'
  password = $stdin.noecho(&:gets).strip

  begin
    Dir.chdir tmp do
      File.write 'passfile', password
      ssh "cat /opt/etc/elrond/keyvault/#{id}.pem > #{id}.pem"
      File.write('validators.json', {
        validators: [
          {
            pemFile: "#{id}.pem"
          },
        ],
      }.to_json)

      sh "erdpy validator stake --keyfile=#{ENV['keystore']} "\
        '--value=2500000000000000000000 --estimate-gas --recall-nonce '\
        '--validators-file=validators.json --passfile=passfile '\
        "#{proxy}"
    end
  ensure
    rm_rf tmp
  end
end

desc 'Run cookstyle'
task :lint do
  sh 'cookstyle'
end

desc 'Chain update, build, sync, run tasks'
task default: %i[update build sync run]
