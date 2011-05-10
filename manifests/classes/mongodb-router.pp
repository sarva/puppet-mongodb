class mongodb::router inherits mongodb::disable {
  include mongodb::params
  $port = $mongodb::params::routerport

  file { '/etc/init/mongorouter.conf':
    content => template('mongodb/mongorouter.conf.erb')
  }

  # setup config server connection
  collectfile{ "/etc/mongoconfig.conf": }
  #Exec<<| tag=="mongodb-config" |>> {
  #  before => Service["mongorouter"]
  #}

  service { "mongorouter":
    ensure => running,
    provider => base, # upstream provider not available in puppet yet
    start => "start mongorouter",
    stop => "stop mongorouter",
    restart => "restart mongorouter",
    status => "status mongorouter | grep 'start/running'",
    require => [Package["mongodb"], File["/etc/init/mongorouter.conf"], File["/etc/mongoconfig.conf"]],
    subscribe => [Service["mongoconfig"], File["/etc/init/mongorouter.conf"]]
  }

  if defined(Class["mongodb::config"]) {
    Service["mongoconfig"] -> Service["mongorouter"]
  }

  # export router connection settings for shards/replicaSets
  exportline{ "$fqdn:$port": file => "/etc/mongorouter.conf" }
  #@@exec { "clear mongorouter.conf":
  #  command => "echo '' |> /etc/mongorouter.conf",
  #  unless => "grep '$fqdn:$port' /etc/mongorouter.conf",
  #  tag => "mongodb-router"
  #}
  #@@exec { "$hostname mongodb router connection settings":
  #  command => "echo '$fqdn:$port' >> /etc/mongorouter.conf",
  #  refreshonly => true,
  #  subscribe => Exec["clear mongorouter.conf"],
  #  tag => "mongodb-router"
  #}
}

class mongodb::router::conf {
  collectfile{ "/etc/mongorouter.conf": }
}
