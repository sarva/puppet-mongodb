# setup a node to be a mongodb config server
class mongodb::config inherits mongodb::disable {
  include mongodb::params
  $prefix = $mongodb::params::prefix
  $port = $mongodb::params::configport

  file { "$prefix/config":
    ensure => directory,
    mode => 755, owner => mongodb, group => mongodb,
    require => [File[$prefix], Package["mongodb"]]
  }

  file { '/etc/init/mongoconfig.conf':
    content => template('mongodb/mongoconfig.conf.erb')
  }

  service { "mongoconfig":
    ensure => running,
    provider => base, # upstream jobs not supported in puppet yet
    start => "start mongoconfig",
    stop => "stop mongoconfig",
    restart => "restart mongoconfig",
    status => "status mongoconfig | grep 'start/running'",
    require => [Package["mongodb"], File["/etc/init/mongoconfig.conf"], File["$prefix/config"]],
  }

  # export the config server connection settings
  exportline{ "$fqdn:$port": file => "/etc/mongoconfig.conf" }
}

