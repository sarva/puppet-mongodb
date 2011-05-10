class mongodb {
  include mongodb::params
  
  exec { "apt-repo":
    command => "echo '${mongodb::params::repository}' >> /etc/apt/sources.list",
    unless => "grep '${mongodb::params::repository}' /etc/apt/sources.list"
  }
  
  #if ${mongodb::params::gpgkey} {
    exec { "apt-key":
      path => "/bin:/usr/bin",
      command => "apt-key adv --keyserver keyserver.ubuntu.com --recv ${mongodb::params::gpgkey}",
      unless => "apt-key list | grep ${mongodb::params::gpgkey}",
      require => Exec["apt-repo"],
      before => Exec["update-apt"]
    }
  #}
  
  exec { "update-apt":
    command => "apt-get update",
    unless => "ls /usr/bin | grep mongo",
    require => Exec["apt-repo"]
  }

  package { $mongodb::params::package:
    alias => mongodb,
    ensure => installed,
    require => Exec["update-apt"],
  }
  
  service { "mongodb":
    enable => true,
    ensure => running,
    status => "status mongodb | grep 'start/running'",
    require => Package["mongodb"]
  }
}

# running shards/config servers/routers should disable the standard mongodb connection
class mongodb::disable inherits mongodb {
  Service["mongodb"] {
    enable => false,
    ensure => stopped
  }
}

