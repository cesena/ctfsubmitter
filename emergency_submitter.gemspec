require File.expand_path('../lib/esub/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'emergency_submitter'
  gem.version       = ESub::VERSION
  gem.summary       = %q{Emergency submitter.}
  gem.description   = %q{
    Emergency submitter.
  }
  gem.license       = 'GPLv2'
  gem.authors       = ['anesec team']
  gem.email         = 'molari.luca@gmail.com'
  gem.homepage      = 'https://bitbucket.org/LMolr/emergency_submitter'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ['lib']

  gem.add_dependency             'pinchoff'
  gem.add_dependency             'deadline'
  gem.add_dependency             'net_tcp_client'
  gem.add_dependency             'hashie',           '~> 3.3'
  gem.add_dependency             'redis',            '~> 3.2'
  gem.add_dependency             'rack',             '~> 1.5'
  gem.add_dependency             'thin',             '~> 1.6'
  gem.add_dependency             'sinatra',          '~> 1.4'
  gem.add_dependency             'awesome_print',    '~> 1.2'

  gem.add_development_dependency 'bundler',    '~> 1.7'
  gem.add_development_dependency 'rake',       '~> 10.3'
  gem.add_development_dependency 'yard',       '~> 0.8'
  gem.add_development_dependency 'rspec',      '~> 3.1'
  gem.add_development_dependency 'pry',        '~> 0.10'
  gem.add_development_dependency 'pry-byebug', '~> 2.0'
  gem.add_development_dependency 'kramdown',   '~> 1.5'

end
