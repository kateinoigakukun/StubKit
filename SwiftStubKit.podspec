Pod::Spec.new do |s|
  s.name           = "SwiftStubKit"
  s.module_name    = "StubKit"
  s.version        = "0.1.5"
  s.summary        = "A smart stubbing system."
  s.description    = "StubKit is a smart stubbing system."
  s.homepage       = "https://github.com/kateinoigakukun/StubKit"
  s.license        = "MIT"
  s.author         = { "Yuta Saito" => "kateinoigakukun@gmail.com" }
  s.source         = { :git => "https://github.com/kateinoigakukun/StubKit.git", :tag => "#{s.version}" }
  s.source_files   = ["Sources/**/*.swift"]
  s.swift_versions = ['4.2', '5.0', '5.1', '5.2']

  s.ios.deployment_target     = '10.0'
  s.tvos.deployment_target    = '13.3'
  s.osx.deployment_target     = '10.10'
  s.watchos.deployment_target = '6.2'

end
