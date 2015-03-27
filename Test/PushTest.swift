/**
* Copyright (c) 2000-present Liferay, Inc. All rights reserved.
*
* This library is free software; you can redistribute it and/or modify it under
* the terms of the GNU Lesser General Public License as published by the Free
* Software Foundation; either version 2.1 of the License, or (at your option)
* any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
* details.
*/

import XCTest

/**
* @author Bruno Farache
*/
class PushTest: XCTestCase {

	var session: LRSession!

	override func setUp() {
		super.setUp()

		var settings: [String: String] = [:]
		let bundle = NSBundle(identifier: "com.liferay.mobile.sdk.Liferay-Push")
		let path = bundle?.pathForResource("settings", ofType: "plist")

		if (path != nil) {
			settings = NSDictionary(contentsOfFile: path!) as [String: String]
		}

		let env = NSProcessInfo.processInfo().environment as [String: String]

		for (k, v) in env {
			settings[k] = v
		}

		let auth = LRBasicAuthentication(
			username: settings["PUSH_USERNAME"],
			password: settings["PUSH_PASSWORD"])

		session = LRSession(
			server: settings["PUSH_SERVER"], authentication: auth)
	}

	func testPushNotification() {
		let pushNotification = [
			"body": "message",
			"payload": "{\"hello\": \"world\"}"
		];

		let push = LRPush.withSession(session)
			.onPushNotification({
				let notification = $0 as [NSString: AnyObject]

				XCTAssertEqual("message", notification["body"] as String)

				let payload = notification["payload"] as [String: String]
				XCTAssertEqual("world", payload["hello"]!)
			})
			.onFailure({
				XCTFail("\($0.localizedDescription)")
			})

		push.didReceiveRemoteNotification(pushNotification)
	}

}