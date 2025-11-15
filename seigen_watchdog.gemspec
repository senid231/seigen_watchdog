# frozen_string_literal: true

require_relative 'lib/seigen_watchdog/version'

Gem::Specification.new do |spec|
  spec.name = 'seigen_watchdog'
  spec.version = SeigenWatchdog::VERSION
  spec.authors = ['Denis Talakevich']
  spec.email = ['senid231@gmail.com']

  spec.summary = 'Monitors and gracefully terminates a Ruby application based on configurable memory usage,' \
    'execution time, iteration count, or custom conditions'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/senid231/seigen_watchdog'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'get_process_mem', '~> 1.0'
  spec.add_dependency 'logger', '~> 1.7'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
