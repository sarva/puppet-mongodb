define exportline($file) {
  $tag = regsubst($file, "/", "-", "G")
  @@exec { "check $name":
    command => "/bin/true",
    unless => "grep '$name' $file",
    tag => "export$tag",
    notify => Exec["clear $file"]
  }
  @@exec { "set $name":
    command => "echo '$name' >> $file",
    refreshonly => true,
    subscribe => Exec["clear $file"],
    tag => "export$tag"
  }
}

define collectfile($trigger=false) {
  $tag = regsubst($name, "/", "-", "G")

  file {$name:
    ensure => file
  }
  exec { "clear $name":
    command => "echo '' |> $name",
    refreshonly => true
  }

  Exec<<| tag=="export$tag" |>> {
    before => File["$name"]
  }

  if $trigger {
    File["$name"] {
      notify => $trigger,
      before => $trigger
    }
  }
}
