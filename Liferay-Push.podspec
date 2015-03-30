Pod::Spec.new do |s|
	s.name					= "Liferay-Push"
	s.version				= "1.0.2"
	s.summary				= "Liferay Push iOS Client"
	s.homepage				= "https://github.com/brunofarache/liferay-push-ios"
	s.license				= {
								:type => "LPGL 2.1",
								:file => "copyright.txt"
							}
	s.authors				= {
								"Bruno Farache" => "bruno.farache@liferay.com"
							}
	s.platform				= :ios
	s.ios.deployment_target	= '8.0'
	s.source				= {
								:git => "https://github.com/brunofarache/liferay-push-ios.git",
								:tag => "1.0.2"
							}
	s.source_files			= "{Core,Service}/**/*"
	s.dependency			"Liferay-iOS-SDK", "6.2.0.14"
end