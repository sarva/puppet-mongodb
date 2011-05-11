define mongodb::replica($priority=1) {
  include mongodb

  # setup all hosts to save all replica connection strings
  exportline{"$name $fqdn:$port": file => "/etc/mongoreplicas.conf" }
  if !defined(Collectfile["/etc/mongoreplicas.conf"]) {
    collectfile{"/etc/mongoreplicas.conf": }
  }

  exec { "add-replica-$name":
    command => "/usr/local/bin/add-replica $name $port",
    require => [Service["mongoshard-${name}"], File["/usr/local/bin/add-replica"], File["/usr/local/bin/check-replica"], File["/etc/mongoreplicas.conf"]],
    unless => "/usr/local/bin/check-replica $port",
    logoutput => on_failure
  }

  # replica must be set first
  Exec["add-replica-$name"] -> Exec["add-shard-$name"]

  # check that this replica-set has a sane primary based on this setup that can have multiple
  # replica-sets on a single node. the purpose being to spread replica-set primaries onto
  # their own node while there may be multiple secondaries on a single node
  if $priority {
    exec {"check-primary-$name":
      command => "/usr/local/bin/check-primary $name $port",
      unless => "echo 'rs.isMaster();' | mongo $fqdn:$port --quiet | grep '\"ismaster\" : true'",
      require => [Exec["add-replica-$name"], File["/usr/local/bin/check-primary"]],
      logoutput => on_failure
    }
  }
}

