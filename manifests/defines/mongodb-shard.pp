# Setup shard + replica-set
define mongodb::shard($replica=false, $priority=1) {
  include mongodb::disable
  include mongodb::params
  $prefix = $mongodb::params::prefix
  $baseport = $mongodb::params::shardport
  # if numbers are used in the replicaSet names, use them to determine unique
  # port numbers per mongod shard instance
  $namenum = regsubst($name, "[^0-9]+", "")
  if $namenum {
    #$port = inline_template("<%= baseport + namenum %>")
    $port = $mongodb::params::shardport + $namenum
  } else {
    # add the 4th octect of the ipaddress for this shards port#
    # this of course assumes all shards reside in the same subnet/submask
    $i4 = regsubst($ipaddress,'^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\4')
    $port = $mongodb::params::shardport + $i4
  }

  # scripts to help add/check shards/replicas
  # TODO convert to ruby
  if !defined(File["/usr/local/bin/add-shard"]) {
    file { "/usr/local/bin/add-replica":
      source => "puppet:///modules/mongodb/add-replica",
      mode => "755"
    }
    file { "/usr/local/bin/check-replica":
      source => "puppet:///modules/mongodb/check-replica",
      mode => "755"
    }
    file { "/usr/local/bin/check-primary":
      source => "puppet:///modules/mongodb/check-primary",
      mode => "755"
    }
    file { "/usr/local/bin/add-shard":
      source => "puppet:///modules/mongodb/add-shard",
      mode => "755"
    }
    file { "/usr/local/bin/add-shard-db":
      source => "puppet:///modules/mongodb/add-shard-db",
      mode => "755"
    }
    file { "/usr/local/bin/add-shard-collection":
      source => "puppet:///modules/mongodb/add-shard-collection",
      mode => "755"
    }
    file { "/usr/local/bin/check-shard":
      source => "puppet:///modules/mongodb/check-shard",
      mode => "755"
    }
    file { "/usr/local/bin/check-shard-db":
      source => "puppet:///modules/mongodb/check-shard-db",
      mode => "755"
    }
    file { "/usr/local/bin/check-shard-collection":
      source => "puppet:///modules/mongodb/check-shard-collection",
      mode => "755"
    }
  }

  file { "$prefix/$name":
    ensure => directory,
    mode => 755, owner => mongodb, group => mongodb,
    require => [File[$prefix], Package["mongodb"]]
  }

  file { "/etc/init/mongoshard-${name}.conf":
    content => template('mongodb/mongoshard.conf.erb')
  }

  # make sure the router connection settings are setup
  include mongodb::router::conf

  # stopping is required to use an updated /etc/init/mongoshard.conf file
  exec { "stop mongoshard-$name":
    command => "stop mongoshard-${name}",
    refreshonly => true,
    subscribe => File["/etc/init/mongoshard-${name}.conf"],
    before => Service["mongoshard-$name"]
  }

  service { "mongoshard-$name":
    ensure => running,
    provider => base,
    start => "start mongoshard-${name}",
    stop => "stop mongoshard-${name}",
    restart => "restart mongoshard-${name}",
    status => "status mongoshard-${name} | grep 'start/running'",
    require => [File["$prefix/$name"], Package["mongodb"], File["/etc/init/mongoshard-${name}.conf"], File["/etc/mongorouter.conf"]],
    subscribe => File["/etc/init/mongoshard-${name}.conf"]
  }

  if defined(Class["mongodb::router"]) {
    Service["mongorouter"] -> Service["mongoshard-$name"]
  }

  # setup sharded configuration
  include mongodb::shard::databases
  include mongodb::shard::collections
  Exec["add-shard-$name"] -> Class["mongodb::shard::databases"] -> Class["mongodb::shard::collections"]

  if $replica {
    $replicaSet = $name
  } else {
    $replicaSet = ""
  }

  exec { "add-shard-$name":
    command => "/usr/local/bin/add-shard $port $replicaSet",
    require => [File["/usr/local/bin/add-shard"], File["/usr/local/bin/check-shard"], Service["mongoshard-$name"]],
    unless => "/usr/local/bin/check-shard $port $replicaSet",
    logoutput => on_failure
  }

  # setup the replica set
  if $replica {
    mongodbb:replica{ $name: priority => $priority }
  }
}

# helper class to run shard-setup only once
class mongodb::shard::databases {
  include mongodb::params

  define add {
    exec { "add shard db $name":
      command => "/usr/local/bin/add-shard-db $name",
      unless => "/usr/local/bin/check-shard-db $name",
      require => [File["/usr/local/bin/add-shard-db"], File["/usr/local/bin/check-shard-db"]]
    }
  }

  if $mongodb::params::sharddb {
    add{ $mongodb::params::sharddb: }
  }
}

# helper class to run shard-setup only once
class mongodb::shard::collections {
  include mongodb::params
  $config = $mongodb::params::shards

  define add {
    $key = regsubst($config[$name], "(')", '\\\1', "G")
    exec { "add shard collection $name":
      command => "/usr/local/bin/add-shard-collection $name '$key'",
      unless => "/usr/local/bin/check-shard-collection $name",
      require => [File["/usr/local/bin/add-shard-collection"], File["/usr/local/bin/check-shard-collection"]]
    }
  }

  if $config {
    $collections = split(inline_template('<%= config.keys.join(",") %>'), ",")
    add { $collections: }
  }
}

