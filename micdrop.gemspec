# frozen_string_literal: true

require_relative "lib/micdrop/version"

Gem::Specification.new do |spec|
  spec.name = "micdrop"
  spec.version = Micdrop::VERSION
  spec.authors = ["Dominick Johnson"]
  spec.email = ["dominick.johnson@tylertech.com"]

  spec.summary = "Utility library for application data migrations, imports, and conversions"
  spec.description = "Migrate data from a legacy application to a new application, write scripts "\
    "to import data from third-party applications, or convert data into the format your application "\
    "expects--all in a flexible, declaritive syntax. Works with tabular data, such as CSV or "\
    "database tables, with support for structured formats such as JSON as well."
  spec.homepage = "https://github.com/dmjohnsson23/micdrop-ruby"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dmjohnsson23/micdrop-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/dmjohnsson23/micdrop-ruby/commits/main/"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
