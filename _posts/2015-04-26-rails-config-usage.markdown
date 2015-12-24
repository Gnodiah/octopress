---
layout: post
title: "rails_config的正确使用姿势"
date: 2015-04-26
author: Hayden Wei
comments: true
categories: [Rails,技术]
tags: [Rails,rails_config,Settings]
duoshuo_thhead_key: 5

---

*本文内容基于 rails_config 0.3.1版本，目前 rails_config 的最新稳定版为0.4.2。虽然版本有所升级，但核心设计应该不会有变化。如有疑问，欢迎指出并留言讨论。*

还记得我们在很多 Rails 项目中，将配置信息写到 config/settings.yml 文件，然后在代码中使用类似于 `Settings.service.host` 这样的用法来读取配置文件的情景吗？咋一看还以为这是 Rails 本身提供的特性，其实并不是，而是 [rails_config][rails_config] 这个 gem 包提供给我们的。虽然 Settings 看起来是一个常量(*因为以大写字母开头*)，但实际上它是 RailsConfig::Options 类的一个实例对象，包含了当前项目中所有 settings 文件中配置的 key-value 对。

它有两种使用方式：

* Settings.key(.sub_key)
* Settings[:key][:sub_key] 或 Settings['key']['sub_key']

### Settings使用姿势说明

rails_config 默认的 settings 文件有 6 个，分别为:

* config/settings.yml
* config/settings.local.yml
* config/settings/#{Rails.env}.yml
* config/settings/#{Rails.env}.local.yml
* config/environments/#{Rails.env}.yml
* config/environments/#{Rails.env}.local.yml

因此，在使用 Settings 过程中会存在两个问题：

1. 同一个 setting 文件的内容是如何被解析的？
2. 不同 settings 文件的内容是如何被解析和合并的？

我们先来看结果：

1、同一个 setting 文件中的相同 key 之间是 **覆盖关系**。(后者会直接整个覆盖掉前者，不会对子节点 key 进行合并)

``` ruby config/settings.yml linenos:false
change_pwd_switch: 1
change_pwd_switch: 2

solr:
  host: http://127.0.0.1
  port: 8983
solr:
  host: 192.168.100.46

# Settings.change_pwd_switch #=> 2
# Settings.solr.host #=> 192.168.100.46
# Settings.solr.port #=> nil
```

2、同一个 setting 文件与其 .local 文件中相同 key 之间是 **合并关系**。（.local 文件优先级更高）

``` ruby config/settings.yml linenos:false
solr:
  host: http://127.0.0.1
  port: 8983
```

``` ruby config/settings.local.yml linenos:false
solr:
  username: 'Hayden'
  port: 12121

# Settings.solr.host #=> "http://127.0.0.1"
# Settings.solr.port #=> 12121
# Settings.solr.username #=> "Hayden"
```

3、不同 settings 文件的 key 之间的关系是 **合并关系**。且优先级关系从高到低依次为:

``` linenos:false
config/environments/#{Rails.env}.local.yml >
config/settings/#{Rails.env}.local.yml >
config/settings.local.yml >
config/environments/#{Rails.env}.yml >
config/settings/#{Rails.env}.yml >
config/settings.yml
```

4、不同 settings 文件的相同 key 在合并过程中的原则是：

- 如果 key 对应的 value 是不同类型或不可合并的类型时，对 value 进行覆盖；
- 如果 key 对应的 value 是可以合并的类型(比如数组)时，则对 value 进行合并。

``` ruby config/settings.yml linenos:false
change_pwd_switch: [11, 88]
```

``` ruby config/settings.loca.yml linenos:false
change_pwd_switch: [23, 45]

# Settings.change_pwd_switch #=> [11, 88, 23, 45]
```

5、在第 4 点中，如果中途被打断，则还是会对 value 进行覆盖操作，而不是合并。

``` ruby config/settings.yml linenos:false
change_pwd_switch: [11, 88]
```

``` ruby config/settings/development.yml linenos:false
change_pwd_switch: 2   # 这里中途被不同类型的value打断
```

``` ruby config/settings.local.yml linenos:false
change_pwd_switch: [23, 45]

# Settings.change_pwd_switch #=> [23, 45]
```

6、在 development 模式下，每一次页面请求都会调用 `Settings.reload!` 来重新加载和解析所有的 settings 文件，因此理论上修改了 settings 文件后不需要重启 Rails。
7、在 settings 文件中是允许内嵌 ruby 代码的，这在某些情况下很有用。例如：

```ruby config/settings.yml linenos:false
size: 2
computed: <%= 1 + 2 + 3 %>

# Settings.computed #=> 6
```

### 追根溯源

我们先来了解下 rails_config 在 Rails 启动过程中做了什么：

1、加载 config/initializers/rails_config.rb 文件，该文件是 rails_config 的自定义文件。例如，如果你不想使用默认的 Settings 来引用配置文件，就可以在该文件中进行修改其常量名称：

```ruby
RailsConfig.setup do |config|
  config.const_name = "MySettings"
end
```

2、加载所有默认的 settings 配置文件，将其解析为一个 RailsConfig::Options (继承自[OpenStruct](http://ruby-doc.org/stdlib-2.1.1/libdoc/ostruct/rdoc/OpenStruct.html)，是一个类似于 Hash 的数据结构)对象，并将该对象赋值给 Settings 常量，以便我们通过 `Settings.xxx` 的方式来调用。

----

**Q1: 上面所说的 6 个 settings 文件是有优先级的，为什么必须是这样的顺序呢？**

**A1:** 没有其他原因，仅仅是因为 rails_config 的代码中是这样定义死的，源码如下：

```ruby lib/rails_config/integration/rails.rb
RailsConfig.load_and_set_settings(
  Rails.root.join("config", "settings.yml").to_s,
  Rails.root.join("config", "settings", "#{Rails.env}.yml").to_s,
  Rails.root.join("config", "environments", "#{Rails.env}.yml").to_s,

  Rails.root.join("config", "settings.local.yml").to_s,
  Rails.root.join("config", "settings", "#{Rails.env}.local.yml").to_s,
  Rails.root.join("config", "environments", "#{Rails.env}.local.yml").to_s
)
```

不难看出，方法传入的是一个数组参数，在用 `each` 遍历时，后者必然会覆盖前者，因而自然就产生了如上所说的优先级顺序。

**Q2: 我不想使用默认的优先级顺序，我想在运行时改变它们之间的顺序；我还想加入自己的 yml 配置文件...可以吗？**

**A2:** 完全没有问题。

1、如果想在默认的6个 settings 配置文件基础上加入自己的 yml 配置文件，你可以在程序中任何需要的地方加入如下代码片段：

```ruby
Settings.add_source!("/path/to/my_settings.yml")
Settings.reload!
```

此时你的 my_settings.yml 文件中的配置就可以直接用 `Settings.xxx` 来调用了，而且你的 my_settings.yml 文件拥有最高的优先级。

2、如果你想完全自定义需要加载的 settings 文件及其顺序，可以在程序中任何需要的地方加入如下代码片段：

```ruby
Settings.reload_from_files(
  Rails.root.join("config", "settings.local.yml").to_s,
  Rails.root.join("config", "my_settings.yml").to_s,
)
```

这样 Settings 中就只包含了 settings.local.yml 和 my_settings.yml 中的配置。

**Q3: 我很好奇它的解析和合并算法，它是怎么实现的呢？**

**A3:** 这是 rails_config 中最核心和最重要的部分了，其实现封装在 `DeepMerge` 这个 module 中。如有兴趣可以直接阅读源码来了解它的实现，[源码传送门在这里][deep-merge-source]。即使不想阅读源码，但了解它的存在也是有必要的。因为如果以后你自己的项目中遇到要解析和合并多个yml文件的内容时，可以直接拿来使用，或者参考它的实现，毕竟我们还是要把时间用在更有意义的地方，避免重复造轮子。

[rails_config]: https://github.com/railsconfig/rails_config
[deep-merge-source]: https://github.com/railsconfig/rails_config/blob/master/lib/rails_config/vendor/deep_merge.rb
