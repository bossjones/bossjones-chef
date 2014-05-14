
STACKS = {
  "bedeployserver" => [
   {
    :CHEF_HOST_NAME => "bedeployserver",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[bebase]","role[test]","recipe[bedeployserver::default]"],
    :IP_ADDRESS => "192.168.57.102",
    :MEMORY => "600",
    :APPCOOKBOOK => "bedeployserver"
   },
   {
    :CHEF_HOST_NAME => "served1", # dev7.be.lan
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "preprod",
    :CHEF_RUN_LIST => ["role[bebase]","role[test]","recipe[appserved]"],
    :IP_ADDRESS => "192.168.57.103",
    :MEMORY => "512",
    :APPCOOKBOOK => "appserved"
   }
  ],
  "bersyslogserver" => [
    {
    :CHEF_HOST_NAME => "bersyslogserver",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[bebase]", "role[test]", "recipe[bersyslog::default]", "recipe[bersyslog::server]"],
    :IP_ADDRESS => "192.168.57.102",
    :MEMORY => "800",
    :APPCOOKBOOK => "bersyslog"
   },
   {
    :CHEF_HOST_NAME => "rsyslog-node",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[bebase]", "role[test]"],
    :IP_ADDRESS => "192.168.57.103",
    :MEMORY => "600",
    :APPCOOKBOOK => "bebootstrap"
   }
  ],
  "belogstash" => [
    {
    :CHEF_HOST_NAME => "bersyslogserver",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[logstash-vagrant]","role[bebase]", "role[test]", "recipe[bersyslog::default]", "recipe[bersyslog::server]","role[logstash-agent]","recipe[belogstash]"],
    :IP_ADDRESS => "192.168.57.102",
    :MEMORY => "800",
    :APPCOOKBOOK => "bersyslog"
   },
   {
    :CHEF_HOST_NAME => "rsyslog-node",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[logstash-vagrant]","role[bebase]", "role[test]","recipe[bersyslog::client]"],
    :IP_ADDRESS => "192.168.57.103",
    :MEMORY => "500",
    :APPCOOKBOOK => "appdla"
  },
  {
    :CHEF_HOST_NAME => "lsredis",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[logstash-vagrant]","role[bebase]", "role[test]","recipe[beredis]"],
    :IP_ADDRESS => "192.168.57.104",
    :MEMORY => "500",
    :APPCOOKBOOK => "beredis"
 },
 {
    :CHEF_HOST_NAME => "indexer",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[logstash-vagrant]","role[bebase]", "role[test]","role[logstash-indexer]","recipe[belogstash]"],
    :IP_ADDRESS => "192.168.57.105",
    :MEMORY => "1024",
    :APPCOOKBOOK => "belogstash"
 },
 {
    :CHEF_HOST_NAME => "lselastic",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[logstash-vagrant]","role[bebase]", "role[test]","role[elasticsearch-logstash-vagrant]","role[elasticsearch-test]","role[logstash-web]","recipe[belogstash]"],
    :IP_ADDRESS => "192.168.57.106",
    :MEMORY => "1024",
    :APPCOOKBOOK => "beelasticsearch"
 },
  {
    :CHEF_HOST_NAME => "lselastic2",
    :CHEF_LOG_LEVEL => "info",
    :CHEF_ENVIRONMENT => "dev",
    :CHEF_RUN_LIST => ["role[logstash-vagrant]","role[bebase]", "role[test]","role[elasticsearch-logstash-vagrant]","role[elasticsearch-test]"],
    :IP_ADDRESS => "192.168.57.107",
    :MEMORY => "1024",
    :APPCOOKBOOK => "beelasticsearch"
 }
 ]
}

        
