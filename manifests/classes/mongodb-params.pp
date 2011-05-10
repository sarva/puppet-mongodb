# customize mongodb setup
class mongodb::params {
  if $mongodb_repository {
    $repository = $mongodb_repository
    $gpgkey = $mongodb_gpgkey
  } elsif !$repository {
    case $operatingsystem {
      "Ubuntu": {
        $repository = "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen"
        $gpgkey = "7F0CEB10"
      }
    }
  }

  if $mongodb_unstable {
    $package = "mongodb-10gen-unstable"
  } else {
    $package = "mongodb-10gen"
  }

  if $mongodb_prefix {
    $prefix = $mongodb_prefix
  } elsif !$prefix {
    $prefix = "/var/lib/mongodb"
  }

  if $mongodb_configport {
    $configport = $mongodb_configport
  } elsif !$configport {
    $configport = 20000
  }

  if $mongodb_routerport {
    $routerport = $mongodb_routerport
  } elsif !$routerport {
    $routerport = 27017
  }

  if $mongodb_shardport {
    $shardport = $mongodb_shardport
  } elsif !$shardport {
    $shardport = 30000
  }

  if $mongodb_sharddb {
    $sharddb = $mongodb_sharddb
  } elsif !$sharddb {
    $sharddb = false
  }

  if $mongodb_shards {
    $shards = $mongodb_shards
  } elsif !$mongodb {
    $shards = false
  }
}
