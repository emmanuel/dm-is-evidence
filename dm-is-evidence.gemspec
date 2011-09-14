# -*- encoding: utf-8 -*-
require File.expand_path("../lib/data_mapper/is/evidence/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "dm-is-evidence"
  s.version     = DataMapper::Is::Evidence::VERSION
  s.authors     = ["Emmanuel Gomez"]
  s.email       = ["emmanuel.gomez@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Auditing and versioning for DataMapper (inspired by PaperTrail)}
  s.description = %q{Provides auditing and versioning for any DataMapper model(s).}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
