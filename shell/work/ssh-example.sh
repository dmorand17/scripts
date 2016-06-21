#!/usr/bin/expect -f
spawn ssh -p 2222 vagrant@localhost

expect "password: "
send "vagrant"

expect "$ "
send "ll"