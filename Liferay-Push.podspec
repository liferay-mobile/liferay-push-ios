Pod::Spec.new do |s|
	s.name					= "Liferay-Push"
	s.module_name			= "LRPush"
	s.version				= "1.0.15"
	s.summary				= "Liferay Push iOS Client"
	s.homepage				= "https://github.com/liferay-mobile/liferay-push-ios"
	s.license				= {
								:type => "LPGL 2.1",
								:file => "copyright.txt"
							}
	s.authors				= {
								"Bruno Farache" => "bruno.farache@liferay.com"
							}
	s.platform				= :ios
    s.swift_version         = "5.0"
	s.ios.deployment_target	= "10.0"
	s.source				= {
								:git => "https://github.com/liferay-mobile/liferay-push-ios.git",
								:tag => "1.0.15"
							}
	s.source_files			= "{Core,Service}/**/*"
	s.dependency			"Liferay-iOS-SDK"
end