# Logstash Input Pulsar Plugin

This is a Ruby plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are free to use it however you want.

This input will read events from a Pulsar topic.

The version of this plugin x.y.z.m conforms to Pulsar x.y.z, while m is the patch version number. For broker compatibility, see the official Pulsar compatibility reference. If the compatibility wiki is not up-to-date, please contact Pulsar support/community to confirm compatibility.

If you require features not yet available in this plugin (including client version upgrades), please file an issue with details about what you need.

# Pulsar Input Configuration Options

This plugin supports these configuration options.

| Settings                      |                          Input type                          |     Default value | Required |
| ----------------------------- | :----------------------------------------------------------: | ----------------: | -------: |
| service_url                   |                            string                            |                 - |      Yes |
| topics or topics_pattern      |                            array                             |       ["topic-1"] |       No |
| subscription_name             |                            string                            |  "logstash-group" |       No |
| client_id                     |                            string                            | "logstash-client" |       No |
| subscription_type             | string, one of["Shared","Exclusive","Failover","Key_shared"] |          "Shared" |       No |
| subscription_initial_position |             string, one of["Latest","Earliest"]              |        "Earliest" |       No |
| codec                         |                            codec                             |           "plain" |       No |
| consumer_threads              |                            number                            |                 1 |       No |
| decorate_events               |                           boolean                            |             false |       No |
| commit_async                  |                           boolean                            |             false |       No |
| auth_plugin_class_name        |                            string                            |                 - |       No |
| auth_params                   |                           password                           |                 - |       No |

# Example

pulsar without tls & token

```
input{
  pulsar{
    service_url => "pulsar://127.0.0.1:6650"
    codec => "json"
    topics => [
        "persistent://public/default/topic1",
        "persistent://public/default/topic2"
    ]
    subscription_name => "my_consumer"
    subscription_type => "Shared"
    subscription_initial_position => "Earliest"
  }
}
```

pulsar with token

```
input{
  pulsar{
    service_url => "pulsar://127.0.0.1:6650"
    codec => "plain"
    topics => [
        "persistent://public/default/topic1",
        "persistent://public/default/topic2"
    ]
    subscription_name => "my_subscription"
    subscription_type => "Shared"
    subscription_initial_position => "Earliest"
    auth_plugin_class_name => "org.apache.pulsar.client.impl.auth.AuthenticationToken"
    auth_params => "token:${token}"
  }
}
```

# Installation

1. Install with gem file
```sh
   wget https://github.com/NiuBlibing/logstash-input-pulsar/releases/download/vx.y.z.m/logstash-input-pulsar-x.y.z.m.gem
bin/logstash-plugin install logstash-input-pulsar-x.y.z.m.gem
```

2. Install from rubygems

```
bin/logstash-plugin install logstash-input-pulsar
```

# Develop

1. Develop environment

- rvm
- jruby (**_Do not_** use ruby, it may fail to compile)
- gem
- bundler
- rake

2. Install dependencies

```sh
bundle install
rake install_jars
```

3. Build

```sh
gem build logstash-input-pulsar.gemspec
```
