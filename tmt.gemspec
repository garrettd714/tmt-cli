# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tmt/version"

Gem::Specification.new do |spec|
  spec.name          = "tmt"
  spec.license       = "MIT"
  spec.version       = Tmt::VERSION
  spec.authors       = ["Garrett Davis"]
  spec.email         = ["garrett.davis@protonmail.com"]

  spec.description   = %q{Trade Management and Tracking CLI App}
  spec.summary       = %q{Trade Management and Tracking CLI App in Ruby with a fluid interface for gathering trade info.}
  spec.homepage      = "https://github.com/garrettd714/tmt-cli"

  # manifest_path      = File.expand_path("tmt.manifest", __dir__)
  # spec.files         = Dir[*File.read(manifest_path).split]
  # spec.bindir        = "exe"
  # spec.executables   = ["tmt"]
  # spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "tty"
  spec.add_dependency "tty-font",     "~> 0.5.0"
  spec.add_dependency "tty-table" #,    "~> 0.11.0"
  spec.add_dependency "tty-spinner" #,  "~> 0.9"
  spec.add_dependency "activerecord", "~> 6.1.4.1"
  spec.add_dependency "sqlite3",      "~> 1.4.2"

  spec.add_development_dependency "pry",   "~> 0.14.1"
  spec.add_development_dependency "rspec", "~> 3.10.0"
  spec.add_development_dependency "rake"
end
