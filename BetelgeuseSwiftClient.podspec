Pod::Spec.new do |s|
s.name = 'BetelgeuseSwiftClient'
s.version = '0.0.6'
s.license = { :type => 'MIT', :file => 'LICENCE' }
s.summary = 'Betelgeuse Swift Client'

s.homepage = 'https://github.com/GabrielCTroia/betelgeuse-swift-client.git'
s.author = { name: 'Gabriel C. Troia', 'email' => 'catalin.troia@gmail.com' }

s.source = { :git => 'https://github.com/GabrielCTroia/betelgeuse-swift-client.git', :tag => "v#{s.version}" }
s.source_files = "BetelgeuseSwiftSDK/**/*.{swift}"

s.ios.deployment_target = '8.0'
# s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }

end