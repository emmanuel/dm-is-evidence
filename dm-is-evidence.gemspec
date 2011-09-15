# -*- encoding: utf-8 -*-
require File.expand_path("../lib/data_mapper/model/is/evidence/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "dm-is-evidence"
  s.version     = DataMapper::Model::Is::Evidence::VERSION
  s.authors     = ["Emmanuel Gomez"]
  s.email       = ["emmanuel.gomez@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Auditing and versioning for DataMapper (inspired by PaperTrail)}
  s.description = %q{Provides auditing and versioning for any DataMapper model(s).}

  s.add_runtime_dependency(%q<dm-core>,       ["~> 1"])
  s.add_runtime_dependency(%q<dm-types>,      ["~> 1"])

  s.add_development_dependency(%q<rake>,      ["~> 0.9"])
  s.add_development_dependency(%q<minitest>,  ["~> 2"])

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
