# general setup information
default['elrond']['network'] = 'test'
default['elrond']['version'] = '1.1.53'
default['elrond']['node']['log_level'] = '*:INFO'
default['elrond']['staking']['agency'] = 'MrStaker'
default['elrond']['keybase']['identity'] = 'mrstaker'

# node specific configuration
default['elrond']['nodes'] = [
  {
    # basically, this is a testnet observer
    id: 0,
  },
]
