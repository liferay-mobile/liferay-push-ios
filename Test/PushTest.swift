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
	var timeout: NSTimeInterval!

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

		timeout = NSString(string: settings["PUSH_TIMEOUT"]!).doubleValue
	}

	func testPushNotification() {
		let pushNotification = [
			"body": "message",
			"payload": "{\"hello\": \"world\"}"
		];

		let push = LRPush.withSession(session)
			.onPushNotification({
				let notification = $0 as [String: AnyObject]
				XCTAssertEqual("message", notification["body"] as String)

				let payload = notification["payload"] as [String: String]
				XCTAssertEqual("world", payload["hello"]!)
			})
			.onFailure({
				XCTFail("\($0.localizedDescription)")
			})

		push.didReceiveRemoteNotification(pushNotification)
	}

	func testRegisterDeviceToken() {
		var expectation = expectationWithDescription("register")

		let deviceToken = "token"

		let push = LRPush.withSession(session)
			.onSuccess({
				let device = $0 as [String: AnyObject]
				self.assertDevice(deviceToken, device: device)
				expectation.fulfill()
			})
			.onFailure({
				XCTFail("\($0.localizedDescription)")
				expectation.fulfill()
			})

		push.registerDeviceToken(deviceToken)

		waitForExpectationsWithTimeout(timeout) { (error) in
			if (error != nil) {
				XCTFail("timed out \(error.localizedDescription)")

				return
			}

			expectation = self.expectationWithDescription("unregister")

			push.unregisterDeviceToken(deviceToken)

			self.waitForExpectationsWithTimeout(self.timeout) { (error) in
				if (error != nil) {
					XCTFail("timed out \(error.localizedDescription)")
				}
			}
		}
	}

	private func assertDevice(deviceToken: String, device: [String: AnyObject]) {
		XCTAssertNotNil(device)
		XCTAssertEqual(deviceToken, device["token"]! as String)
		XCTAssertEqual("apple", device["platform"]! as String)
	}

}