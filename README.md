# fluent-plugin-http-client

[Fluentd](https://fluentd.org/) plugin that provides http client.

## Configuration

You can generate configuration template:

```
$ fluent-plugin-config-format input http-client
```

You can copy and paste generated documents here.

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


## ToDo

### add Basic Auth

### add Token Id auth

- simple token
- token renewal

### get request time

example:
- http://dpsk.github.io/blog/2013/10/01/track-request-time-with-the-faraday/
- https://github.com/lostisland/awesome-faraday

### allow header injection

### request header to add in event

- manage a whitelist ?
- manage a blacklist ?

### response header to add in event

- manage a whitelist ?
- manage a blacklist ?

## Copyright

* Copyright(c) 2022- Thomas Tych
* License
  * Apache License, Version 2.0
