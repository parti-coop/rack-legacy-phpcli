PHP 코드를 [Rake](http://rack.github.io/) 서버에서 작동시키는 Rack handler입니다.

이미 [rack-legacy](https://github.com/eric1234/rack-legacy)에서 동일한 기능을 제공합니다. 다만 Rack::ReverseProxy를 통해 PHP built-in server를 사용하는데, 이 방식은 Permalink 설정이 된 [Wordpress](http://wordpress.org)를 동작시키기에 적당하지 않습니다. 왜냐하면 PATH_INFO나 REQUEST_URI를 제어하기 어렵기 때문입니다. 그래서, php-cgi 등을 직접 호출하는 방식으로 다시 개발하였습니다.

만일 [rack-legacy](https://github.com/eric1234/rack-legacy)을 이용하여 Permalink 설정이 된 [Wordpress](http://wordpress.org)를 동작시키는 방법을 아시면 dali@ufofactory.org로 메일 부탁드립니다.

# 설치방법

Gemfile에 아래와 같이 기록하고 bundler를 통해 설치합니다.
```ruby
gem 'rack-legacy-phpcli', git: 'git@bitbucket.org:ufofactory/rack-legacy-phpcli.git'
```

# 예제

Permalink 설정이 된 [Wordpress](http://wordpress.org)를 [Rake](http://rack.github.io/) 서버에 붙여 봅니다.

Gemfile은 아래와 같이 적습니다.

```ruby
source 'https://rubygems.org'

gem 'rake'
gem 'rack-legacy'
gem 'rack-rewrite'
gem 'rack-legacy-phpcli', git: 'git@bitbucket.org:ufofactory/rack-legacy-phpcli.git'
```

config.ru파일은 아래와 같이 작성합니다.

```ruby
require 'rubygems'
require 'bundler'
Bundler.setup

require 'rack'
require 'rack/showexceptions'
require 'rack-legacy'
require 'rack-legacy-phpcli'
require 'rack-rewrite'

INDEXES = ['index.html','index.php', 'index.cgi']
ENV['SERVER_PROTOCOL'] = "HTTP/1.1"

use Rack::Rewrite do
  # Rewrite rule for WordPress Multi Site
  rewrite %r{.*/files/(.+)}, 'wp-includes/ms-files.php?file=$1'

  # redirect /foo to /foo/ - emulate the canonical WP .htaccess rewrites
  r301 %r{(^.*/[\w\-_]+$)}, '$1/'

  rewrite %r{(.*/$)}, lambda {|match, rack_env|
    rack_env['CUSTOM_REQUEST_URI'] = rack_env['PATH_INFO']

    if !File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO']))
      return '/index.php'
    end

    to_return = rack_env['PATH_INFO']
    INDEXES.each do |index|
      if File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO'], index))
        to_return = File.join(rack_env['PATH_INFO'], index)
      end
    end
    to_return
  }

  # also rewrite /?p=1 type requests
  rewrite %r{(.*/\?.*$)}, lambda {|match, rack_env|
    rack_env['CUSTOM_REQUEST_URI'] = rack_env['PATH_INFO']
    query = match[1].split('?').last

    if !File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO']))
      return '/index.php?' + query
    end

    to_return = rack_env['PATH_INFO'] + '?' + query
    INDEXES.each do |index|
      if File.exists?(File.join(Dir.getwd, rack_env['PATH_INFO'], index))
        to_return = File.join(rack_env['PATH_INFO'], index) + '?' + query
      end
    end
    to_return
  }
end

use Rack::ShowExceptions
use Rack::Legacy::Index
use Rack::Legacy::PhpCli
run Rack::File.new Dir.getwd
```

Rack::Legacy::PhpCli는 두 개의 추가 옵션을 받을 수 있습니다. 첫 번째는 웹 루트 디렉토리입니다. 기본값은 현재 디렉토리입니다. 두 번째는 php-cgi 명령어입니다. 기본값은 'php-cgi'입니다.

```ruby
use Rack::Legacy::PhpCli, 'public', 'php5-cgi'
```

