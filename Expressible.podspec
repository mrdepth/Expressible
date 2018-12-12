Pod::Spec.new do |s|
  s.name         = "Expressible"
  s.version      = "1.0.0"
  s.summary      = "Expressible library helps you to fetch data from CoreData."
  s.homepage     = "https://github.com/mrdepth/Expressible"
  s.license      = "MIT"
  s.author       = { "Shimanski Artem" => "shimanski.artem@gmail.com" }
  s.source       = { :git => "https://github.com/mrdepth/Expressible.git", :branch => "master" }
  s.source_files = "Source/*.swift"
  s.platform     = :ios
  s.ios.deployment_target = "10.0"
  s.swift_version = "4.2"
end
