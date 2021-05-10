## About

This is a template project demonstrating how to deploy Elrond nodes using our [elrond-cookbook](https://github.com/mr-staker/elrond-cookbook). It uses `cinc-solo`, so no Chef server is required (it's slow and expensive anyway). It also demonstrates the usage of thin wrapper cookbooks to fulfil a role (i.e role cookbooks). While Chef/Cinc have native support for roles, role cookbooks are more flexible, can be versioned, and can even be tested on their own. It also leads to much simpler JSON attributes file on the server itself as all of the code lives in a git repository, so it's part of your development history.

Running `cinc-solo` is probably the easiest to get started. It can either work in push mode (Ansible-style) where the cookbooks are pushed from your machine and run on the target server. This is the model demonstrated by this repository.

Alternatively, you can push your code to an object storage service (such as AWS S3) and have your server pull the cookbooks from object storage, expand, and invoke `cinc-solo`. In pull mode, `chef-solo` can run from cron. Having your server pull the cookbooks from object storage is very scalable, but it requires the initial setup to be done via something like `cloud-init`.

None of these deployment models require `chef-solo` to run as an agent.

## Deploy procedure

This repository has a suite of rake tasks to automate the deployment steps. To list the tasks:

```bash
rake -T
rake build         # Builds cookbooks tarball
rake cinc_install  # Install Cinc Client on remote target
rake clean         # Cleanup build artefacts
rake default       # Chain build, sync, run tasks
rake install       # Invoke berks install
rake run           # Run cinc-solo on remote target
rake setup         # Sync setup script
rake sync          # Sync cookbooks tarball to target host
rake update        # Invoke berks update
```

### Install Cinc on target server

This must be run once. Installs Cinc Client on your target server. This can be done with the `cinc_install` task:

```bash
rake cinc_install version=16.11.7 target=server
```

`target` either the full specification of a ssh endpoint e.g user@host or it can be a Host per SSH config file, so in that example `Host server` is assumed to be specified in `~/.ssh/config` with appropriate values.

### Install cookbooks

This must be run once. Pulls down cookbooks from Supermarket / GitHub.

```bash
rake install
```

From this point onwards, the `update` task keeps them in sync.

### Run the deployment procedure

```bash
rake target=server role=host001
```

This runs the `role-host001` example role cookbook against the target server. If you look at the default set of attributes, it is configured to deploy a single observer node on testnet.

## Pactical example

A Vagrantfile is included in this repository so you can kick the tyres and follow along. This uses Oracle Linux 8.3 as base OS. You need Vagrant and Virtualbox as prerequisites to use this.

```bash
vagrant up # to spin up a VM
vagrant ssh-config > .vagrant/config # export Vagrant SSH config
```

This should provide an empty box to deploy some cookbooks. Start with cinc_install:

```bash
rake cinc_install target=default version=16.11.7 config=.vagrant/config
```

`default` is defined as `Host default` by the SSH config exported by `vagrant ssh-config`. `config` indicates a custom SSH config instead of the default `~/.ssh/config` file. It should produce something like our [example-cinc-install.log](/example-logs/example-cinc-install.log).

The next step, is to do the actual config run:

```bash
rake target=default config=.vagrant/config role=host001
```

You get the gist by now. The output should be like in our [example-run.log](/example-logs/example-run.log).

To inspect things around, you can:

```bash
vagrant ssh
```

To get rid of the Vagrant VM:

```bash
rake clean
```

## Deploying validators

The validator nodes require a functioning Hashicorp Vault. A token is necessary for the first config run to seed the node keys or for subsequent runs if new nodes are added to your role cookbook. `vault_token` isn't necessary for anything else (e.g updating a node version).

A one time use token can be created using something like:

```bash
vault login -address=https://vault.example.com:8200 # followed by supported auth method
vault token create -address=https://vault.example.com:8200 -use-limit=1
```

This expands on the run procedure:

```bash
rake target=server role=host001 vault_token=y
```

This instructs the task to prompt for an input token, thus avoiding this token to be saved into your shell history. Please note that the input is not reflected for security reasons, so paste the token and hit return.

To [setup a validator node](https://docs.elrond.com/validators/staking/staking/) on the Elrond network:

```bash
# n.b https://api.elrond.com - mainnet proxy address!
rake validator id=0 keystore=/path/to/keystore.json target=server proxy=https://api.elrond.com
```

This requires `erdpy` to be properly installed in $PATH e.g via [erdpy-up.py](https://docs.elrond.com/sdk-and-tools/erdpy/installing-erdpy/).

The `validator` task wraps `erdpy` and it does the following:

 * Takes node ID and keystore path as arguments (specified as environment variables, see example).
 * Prompts for keystore password.
 * Prepares temporary passfile where the keystore password is stored. This is automatically removed after this task runs.
 * Pulls down node key from remote server for the specified node ID. This is automatically removed after this task runs.
 * Builds validators file to reference the node key pulled from remote. This is automatically removed after this task runs.

Essentially, this wrapper has been created to ensure that no secrets (node key, passfile) are left exposed after `erdpy` runs.
