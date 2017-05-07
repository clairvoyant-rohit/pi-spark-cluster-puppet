class defaults {
  exec { "apt-update": command => "/usr/bin/apt-get update" }

   package { 'vim': ensure => present }
   package { 'git-core': ensure => present }
   package { 'curl' : ensure => present }
   package { 'ntp' : ensure => present }

   alternatives { 'editor':
     path => '/usr/bin/vim.basic',
   }
}

node 'master' {

  include defaults

  network::interface { 'wlan0':
    wpa_ssid => '',
    wpa_psk => '',
    enable_dhcp => true
  }

  network::interface { 'eth0':
    ipaddress => '10.0.0.1',
    netmask   => '255.255.255.0',
  }

  class { 'dnsmasq':
    interface => 'eth0',
    listen_address => '10.0.0.1',
    domain  => 'spark',
    enable_tftp => false
  }

  dnsmasq::dhcp { 'dhcp':
    paramset => 'spark',
    dhcp_start => '10.0.0.10',
    dhcp_end => '10.0.0.20',
    netmask => '255.255.255.0',
    lease_time => '24h'
  }

  dnsmasq::dhcpstatic {
    'slave1': mac => 'b8:27:eb:cf:5e:3d', ip  => '10.0.0.2';
  }

  package {'iptables-persistent': ensure => present}

  firewall { '100 snat for network internal':
    chain    => 'POSTROUTING',
    jump     => 'MASQUERADE',
    proto    => 'all',
    outiface => 'wlan0',
    source   => '10.0.0.0/24',
    table    => 'nat'
  } ->
  exec { 'enable ip_forwarding': command => '/bin/echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf ; /sbin/sysctl -w net.ipv4.ip_forward="1"' }
}
