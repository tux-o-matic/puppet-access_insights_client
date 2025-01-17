# == Class: access_insights_client
#
# Full description of class access_insights_client here.
#
# === Parameters
#
# Change log level, valid options DEBUG, INFO, WARNING, ERROR, CRITICAL. 
# Default DEBUG
#loglevel=DEBUG
# Attempt to auto configure with Satellite server
#auto_config=True
# Change authentication method, valid options BASIC, CERT. Default BASIC
#authmethod=BASIC
# username to use when authmethod is BASIC
#username=
# password to use when authmethod is BASIC
#password=
#base_url=cert-api.access.redhat.com:443/r/insights
# URL for your proxy.  Example: http://user:pass@192.168.100.50:8080
#proxy=
# Location of the certificate chain for api.access.redhat.com used 
# for Certificate Pinning
#cert_verify=/etc/redhat-access-insights/cert-api.access.redhat.com.pem
#cert_verify=False
#cert_verify=True
# Enable/Disable GPG verification of dynamic configuration
#gpg=True
# Automatically update the dynamic configuration
#auto_update=True
# Obfuscate IP addresses
#obfuscate=False
# Obfuscate hostname
#obfuscate_hostname=False
#
# === Authors
#
# Lindani Phiri <lphiri@redhat.com>
# Dan Varga  <dvarga@redhat.com>
#
# === Copyright
#
# Copyright 2015 Red Hat Inc.
#
class access_insights_client(
    $log_level = undef,
    $auto_config = 'True',
    $authmethod = undef,
    $username = undef,
    String $package_ensure,
    String $package_name,
    $password = undef,
    $base_url = undef,
    $proxy = undef,
    $cert_verify = undef,
    $gpg = undef,
    $auto_update = undef,
    $obfuscate = undef,
    $obfuscate_hostname = undef,
    $upload_schedule = undef,
){
    package { $package_name:
      ensure   => $package_ensure,
    }

    file {'/etc/redhat-access-insights/redhat-access-insights.conf':
      ensure  => file,
      content => template('access_insights_client/redhat-access-insights.conf.erb'),
      require => Package[$package_name],
    }

    case $upload_schedule {
        daily: { file { '/etc/cron.daily/redhat-access-insights':
            ensure  => 'link',
            target  => '/etc/redhat-access-insights/redhat-access-insights.cron',
            require => Package[$package_name],
        }
        }
        weekly: { file { '/etc/cron.weekly/redhat-access-insights':
            ensure  => 'link',
            target  => '/etc/redhat-access-insights/redhat-access-insights.cron',
            require => Package[$package_name],
        }}
        default: { file { '/etc/cron.daily/redhat-access-insights':
            ensure  => 'link',
            target  => '/etc/redhat-access-insights/redhat-access-insights.cron',
            require => Package[$package_name],
        }}
    }
    if ($upload_schedule == 'weekly') {
        file { '/etc/cron.daily/redhat-access-insights':
            ensure => 'absent'
        }
    }elsif ($upload_schedule == 'daily') {
        file { '/etc/cron.weekly/redhat-access-insights':
            ensure => 'absent'
        }
    }else {
        file { '/etc/cron.weekly/redhat-access-insights':
            ensure => 'absent'
        }
    }
    exec { '/usr/bin/redhat-access-insights --register':
        creates => '/etc/redhat-access-insights/.registered',
        unless  => '/usr/bin/test -f /etc/redhat-access-insights/.unregistered',
        require => Package[$package_name]
    }
}
