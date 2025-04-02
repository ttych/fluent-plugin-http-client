# fluent-plugin-http-client

[Fluentd](https://fluentd.org/) plugin that provides http client.

## input : http-client

The plugin fetch data in json.

It implements basic auth only for the moment.

It allows to distinct between request status and response data.

### parameters

Here are the parameter details :

| Parameter                   | Type    | Default                   | Purpose                                                         |
|-----------------------------|---------|---------------------------|-----------------------------------------------------------------|
| tag                         | string  |                           | default tag to emit data on                                     |
| tag_status                  | string  | `tag`                     | default tag to emit status on                                   |
| interval                    | time    | 60                        | interval in seconds between request                             |
| url                         | string  |                           | url to request                                                  |
| http_method                 | enum    | get                       | http verb for the request                                       |
| timeout                     | integer | 5                         | request timeout                                                 |
| verify_ssl                  | bool    | true                      | verify ssl when using https                                     |
| ca_path                     | string  |                           | directory where multiple CA are stored                          |
| ca_file                     | string  |                           | specific CA file path to use                                    |
| user_agent                  | string  | fluent-plugin-http-client | define user-agent in request header                             |
| user                        | string  |                           | user for basic auth                                             |
| password                    | string  |                           | password for basic auth                                         |
| enable_status               | bool    | true                      | generate status events                                          |
| status_with_response_data   | bool    | true                      | add response data in status event                               |
| enable_response_data        | bool    | false                     | generate response data events                                   |
| split_response_data         | bool    | false                     | split reponse data in multiple events when an array             |
| enable_failed_response_data | bool    | false                     | generate response data events even in a failed response context |


### configuration example

Example of configuration to :
- generate request every 30 seconds
- request is a GET http://localhost:4567/status
- emit status events on tag api_status
- emit response data events on tag api_status_data
- set user agent during request to monitoring
- use basic auth
- split response data event to multiple events when returned data is an array

``` text
<source>
  @type http_client

  interval 30
  url http://localhost:4567/status

  tag api_status_data
  tag_status api_status

  user_agent monitoring

  user api_user
  password api_password

  enable_response_data true
  split_response_data true
</source>

```

### configuration template

You can generate configuration template:

```
$ fluent-plugin-config-format input http-client
```


## Installation

### RubyGems

```
$ gem install fluent-plugin-http-client
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-http-client"
```

And then execute:

```
$ bundle
```

## Copyright

* Copyright(c) 2022- Thomas Tych
* License
  * Apache License, Version 2.0
