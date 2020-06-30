lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ia_to_ht_ingest_prep/version"

Gem::Specification.new do |spec|
  spec.name          = 'ia_to_ht_ingest_prep'
  spec.version       = IaToHtIngestPrep::VERSION
  spec.authors       = ["ldss-jm"]
  spec.email         = ["ldss-jm@users.noreply.github.com"]

  spec.summary       = "Prep"
  spec.homepage      = "https://github.com/UNC-Libraries/IA-to-HT-ingest-prep"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.3", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency 'sierra_postgres_utilities', '~> 0.3.0'
  spec.add_runtime_dependency 'sierra_postgres_utilities-derivatives', '~> 1.1.2'
end
