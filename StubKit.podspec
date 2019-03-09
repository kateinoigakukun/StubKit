Pod::Spec.new do |s|
  s.name         = "StubKit"
  s.version      = "0.0.1"
  s.summary      = "A smart stubbing system."
  s.description  = "StubKit is a smart stubbing system."
  s.homepage     = "https://github.com/kateinoigakukun/StubKit"
  s.license      = "MIT"
  s.author             = { "Yuta Saito" => "kateinoigakukun@gmail.com" }
  s.source       = { :git => "https://github.com/kateinoigakukun/StubKit", :tag => "#{s.version}" }
  s.source_files  = ["Sources/**/*.swift"]
end
