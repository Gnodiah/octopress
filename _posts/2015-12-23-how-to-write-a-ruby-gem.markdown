---
layout: post
title: "书写并发布自己的Ruby Gem"
date: 2015-12-23
author: Hayden Wei
comments: true
categories: [Ruby Gem]
tags: [Ruby Gem]
duoshuo_thhead_key: 6

---

关于 gem 是什么，其实不用多说，每一个 Rubyist 都不会感到陌生。无论是纯 Ruby 开发还是 Rails 等框架开发，我们都在享受着 gem 带给我们开发的便利，[RubyGems](https://rubygems.org/) 上已经有数不清的 gem 了 。所以，简而言之呢，一个 gem 就是一系列 Ruby 代码的组合，它实现了某种或某些特定的功能。打包成 gem 是为了更好地重用代码，或分享给他人使用，而不再需要直接粗暴地 copy 一份代码。

学习 gem 最好的资料是 [RubyGems Guides](http://guides.rubygems.org/) ，它详细介绍了有关 gem 的很多信息，包括如何创建一个自己的 gem 。所以，我建议你把它完整地读一遍，这对你更深层次地理解 gem 有很大的好处。但 RubyGems Guides 中介绍的是如何一步一步地手动创建 gem，需要你从一个空目录开始创建所有需要的文件和子目录，太繁琐了！怎么办呢？有没有方法能够快速地生成一个 gem 包的框架，而我们只需要在此基础上完成该 gem 所要提供的功能就好了呢？

这就要请出我们这篇文章所要使用的 `bundle gem` 命令了。下面我们会以创建一个名为 elklogger 的 gem 来理解书写和发布 gem 的整个过程。该 gem 提供了日志统一格式化的功能，也就是说，在引入了该 gem 的所有项目中，使用 gem 包提供的方法生成的日志的格式都是一致的。

### 生成 gem 包框架

`bundle gem` 命令是由 [bundler](http://bundler.io/) 这个 gem 包提供的，它用于创建一个 gem 包所需的框架，而不用你一个一个文件去添加。要使用这个命令，首先需要确认是否已经安装好 bundler ，可使用 `bundle version` 查看本机 bundler 的版本，结果类似于：

``` linenos:false
Bundler version 1.11.2
```

如果本机没有安装，则使用 `gem install bundler` 来安装它。

安装好 bundler 之后，就可以使用它来创建一个空白的 gem 包框架了。用法非常简单：

``` ruby linenos:false
bundle gem GEM_NAME
```

第一次使用该命令创建 gem 包时，会询问你是否创建测试目录以及是否创建 LICENSE.txt 文件等信息，该配置会保存在 ~/.bundle/config 文件中，以后再使用该命令创建 gem 包时会默认使用该配置。给 gem 添加测试代码是个好习惯，所以建议你在上面的询问信息时选择其中的一个测试框架，也可以直接给 `bundle gem` 命令添加 -t 参数来指定使用默认的 rspec 作为测试框架（更多关于该命令的参数可以 `bundle help gem` 来[查看](http://bundler.io/v1.11/bundle_gem.html)）：


``` ruby linenos:false
bundle gem GEM_NAME -t
```

或使用 --test 参数来指定所要使用的测试框架：

``` ruby linenos:false
bundle gem GEM_NAME --test=minitest
```

该命令做了3件事：

- 创建指定的 gem 包目录并初始化 gem 包的基本结构
- 使用 `git init` 命令初始化新建的 gem 包目录
- 提供了一些帮助你开发 gem 包的 rake 命令（可进入目录后使用 `rake -T` 查看这些 rake 命令）

本例中我们使用 `bundle gem elklogger -t` 命令生成的 elklogger gem 框架结构如下：

``` linenos:false
bin/
  console*
  setup*
lib/
  elklogger/
    version.rb
  elklogger.rb
spec/
  elklogger_spec.rb
  spec_helper.rb
elklogger.gemspec
Gemfile
LICENSE.txt
Rakefile
README.md
```

### 理解 gem 包目录结构

如上面生成的框架结构所示，看起来有点让人摸不着头脑，让人觉得不知道该如何组织文件结构。但我来告诉你，其实这很简单，我们在开发一个 gem 时，通常主要关心和修改的是如下几个部分：

- **lib 目录**

  lib 目录用于存放 gem 包所要实现的功能的源代码。而且在 lib 根目录下必须有一个与 gem 包名字一样的 .rb 文件，这是 gem 包的入口文件（如本例中的 lib/elklogger.rb）。其它的源代码可以在 lib 下按需组织目录结构，然后再 require 到 gem 包的入口文件中即可。

- **spec 目录或 test 目录**

  这是书写和存放 gem 包测试代码的目录。根据你选择的测试框架不同会分别是 spec 目录或 test 目录。

- **.gemspec 文件**

  这是 gem 包最重要的一个文件，它定义了 gem 包的所有元数据（metadata），包括 gem 包的作者、Email、gem 包的功能描述信息、开发模式下所依赖的其它 gem 包等等一切信息。可以去[这里](http://guides.rubygems.org/specification-reference/)进行更全面更深入的了解和学习。

- **README.md 文件**

  该文件用于书写 gem 包的使用说明文档。

除此之外的其它文件或目录保持原样就可以了，或者后期有需要再去酌情修改。

### 实现 gem 包功能

下面我们就来完成该gem包的功能。

#### 完善 .gemspec 文件

在书写 lib 源代码和 rspec 测试代码完成功能之前，我们先来完善一下 .gemspec 文件。上面说过，此文件是非常重要的一个文件，它描述了该 gem 包的所有信息。但目前我们不需要去了解它的全部，只关注前面几项即可，即 name ~ license 之间的信息，按需修改即可，其它项保持不变。修改后的内容为：

``` ruby elklogger.gemspec
Gem::Specification.new do |spec|
  ......
  spec.summary       = %q{Specific formatted logger for ELK-stack.}
  spec.description   = %q{Write formatted log infos to log file, used by ELK-stack.}
  spec.homepage      = ""
  ......
  spec.metadata['allowed_push_host'] = "https://rubygems.org"
  ......
end
```

#### 测试驱动开发：完成功能

elklogger gem 包的功能是将日志内容按照指定的格式进行格式化后输出，我们期望的格式为：

``` linenos:false
I, [2015-12-23#8255]  INFO -- : message\n
```

为此，我们采用 **测试驱动开发** 的方式，先添加 rspec 代码。打开 spec/elklogger_spec.rb 文件，添加如下代码：

``` ruby spec/elklogger_spec.rb
describe Elklogger do
  it 'has a formmatted output' do
    filename = '/tmp/elklogger_test.log.elk'
    logger = Elklogger.new(filename)
    logger.info 'hello test!'
    logger.close

    file = File.open(filename)
    reg = /I, \[#{Time.now.strftime('%Y-%m-%d')}#\d+\]  INFO -- : hello test!\n/
    result = file.readlines.last =~ reg
    file.close

    expect(result).not_to be nil
  end
end
```

运行 `rake spec`，出现测试未通过。这是正常的，因为我们还没有实现功能：

``` linenos:false
Failures:

  1) Elklogger has a formmatted output
     Failure/Error: expect(result).not_to be nil

       expected not #<NilClass:8> => nil
                got #<NilClass:8> => nil

       Compared using equal?, which compares object identity.
     # ./spec/elklogger_spec.rb:19:in `block (2 levels) in <top (required)>'

Finished in 0.00251 seconds (files took 0.0868 seconds to load)
2 examples, 1 failure
```

现在我们来实现 **红变绿** 的过程。在 lib/elklogger.rb 中实现功能：

``` ruby lib/elklogger.rb
class Elklogger
  def format_message(severity, datetime, progname, msg)
    Formatter::Format % [severity[0..0], datetime.strftime('%Y-%m-%d'), $$, severity, progname, msg]
  end
end
```

lib/elklogger/version.rb 则为这样：

```ruby lib/elklogger/version.rb
require 'logger'

class Elklogger < Logger
  VERSION = "0.0.1"
end
```

那么再运行 `rake spec` ，发现测试通过了！

``` linenos:false
Elklogger
  has a version number
  has a formmatted output
 
Finished in 0.00119 seconds (files took 0.07839 seconds to load)
2 examples, 0 failures
```

#### 完善 README.md 文件

OK，功能已经完成了，那么现在需要告诉别人如何使用。我们把它写在 README.md 中（限于篇幅，此例中就不贴文件内容了）。

### 本地测试 gem 包

本地测试 gem 包有几种方式，

- bin/console

bundler 提供了 bin/console 这个工具，它加载了 gem 中 lib 目录下的所有源代码，你可以用它来以 irb 交互的方式自测 gem 包所提供的功能是否正常。

- 使用 :path 或 :git 参数

在 Gemfile 中，除了使用 `gem 'mysql2'` 这样的语法直接在 source 源中查找相应的 gem 包外，`gem` 命令还提供了 :path 和 :git 两种参数。前者允许你将其指向本地的 gem 包源代码目录，后者允许你将其指向一个 git 网络路径。这样，我们就可以运用 :path 参数在其他项目中对 gem 包进行本地测试了，而不用每次改动后都打包成 gem 包再安装。

对于本例，我们在一个项目的 Gemfile 文件中添加如下一行：

``` ruby linenos:false
gem 'elklogger', :path => '/home/path/to/elklogger'
```
然后再 `bundle install` 就可以在项目中使用了。

- `rake install:local`

前面提过，`bundle gem` 命令附带提供了一些有助于开发 gem 的 rake 命令， `rake install:local` 就是其中之一，该命令会打包为 .gem 文件放在 pkg 目录并安装到当前的 gemset 中，也就是 `rake build` 和 `gem install`这两个命令的合体。在本例中，运行该命令后会生成 pkg/elklogger-0.0.1.gem 文件，同时也会被安装到当前的 gemset 中，可使用 `gem list | grep elklogger` 查找到。如果想将该 gem 包安装到指定的 gemset 的话，在执行 `rake install:local` 之前你需要先 `rvm use` 来切换到对应的 gemset 去。

安装好以后，就可以在该 gemset 环境中的 ruby 文件中通过 `require 'elklogger'` 得到 Elklogger 对象，从而使用该 gem 包提供的功能了。

**NOTE:** 注意这种方式不适用于类似 Rails 等项目，因为 Rails 项目使用的是 Gemfile 中定义的 gem 包依赖关系，而不是当前 gemset 中的所有包。要想在 Rails 中使用，就必须在 Gemfile 中声明，这种情况下可以使用第 2 种方式。

### 打包并发布 gem 包

如果只是想单独打包并不发布该 gem，可使用 `rake build` ，执行该命令后会在 pkg 目录下生成打包后的文件。例如 elklogger-0.0.1.gem。

如果想打包并且同时发布出去，也很简单，使用 `rake release` 即可将打包后的 gem 包发布到 RubyGems 供他人下载和安装。但在发布之前，我们需要先提交我们的代码，由于当初 `bundle gem` 初始化 git 仓库时并没有添加源，所以我们先去 github 上新建一个仓库，然后将其作为我们 gem 包的远端源添加进去再提交代码：

``` ruby linenos:false
git remote add origin https://github.com/Gnodiah/elklogger.git
git add .
git commit -m 'finish develop'
```

再来运行 `rake release` ，输入用户名和密码后即发布成功了。此命令做了 3 件事：

- 运行 `rake build` 打包 gem
- 以当前 gem 版本在 git 分支上打一个 tag 标签
- 发布上传 gem 包到 RubyGems

OK，到目前为止，elklogger gem 包已经完成并发布到 RubyGems 了，此时就可以使用 `gem install elklogger` 直接安装了（如果当前源没有，记得加上 --source 'https://rubygems.org'）。

最后的最后，别忘了 push 源代码到 git 仓库：

``` ruby linenos:false
git push origin master
```

### 弦外之音

1. 与 `bundle gem` 功能类似的还有 [jeweler](https://github.com/technicalpickles/jeweler)，可以去了解一下。但现在可能没有 bundler 这么流行，Github 上也很久没有更新了。
2. Github 上大家也总结了这么一篇文章： [Developing a RubyGem using Bundler](https://github.com/radar/guides/blob/master/gem-development.md)，值得一看。
