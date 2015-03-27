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
				self.failed($0)
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
				self.failed($0)
				expectation.fulfill()
			})

		push.registerDeviceToken(deviceToken)

		waitForExpectationsWithTimeout(timeout) { (error) in
			if (error != nil) {
				self.failed(error)

				return
			}

			expectation = self.expectationWithDescription("unregister")

			push.unregisterDeviceToken(deviceToken)

			self.waitForExpectationsWithTimeout(
				self.timeout, handler: self.failed)
		}
	}

	func testRegisterDeviceTokenData() {
		var expectation = expectationWithDescription("register")

		let deviceToken = "<740f4707 bebcf74f 9b7c25d4 8e335894 5f6aa01d " +
			"a5ddb387 462c7eaf 61bb78ad>"

		let deviceTokenData = self.toData(deviceToken)

		let push = LRPush.withSession(session)
			.onSuccess({
				let device = $0 as [String: AnyObject]
				self.assertDevice(
					"740f4707bebcf74f9b7c25d48e3358945f6aa01da5ddb387462c7eaf" +
						"61bb78ad",
					device: device)

				expectation.fulfill()
			})
			.onFailure({
				self.failed($0)
				expectation.fulfill()
			})

		push.registerDeviceTokenData(deviceTokenData)

		waitForExpectationsWithTimeout(timeout, handler:failed)
	}

	func testSendPushNotification() {
		var expectation = expectationWithDescription("send push notification")

		let push = LRPush.withSession(self.session)
			.onFailure({
				self.failed($0)
				expectation.fulfill()
			})

		push.sendToUserId(0, notification: ["message": "hello!"])

		expectation.fulfill()

		waitForExpectationsWithTimeout(timeout, handler: failed)
	}

	private func assertDevice(deviceToken: String, device: [String: AnyObject]) {
		XCTAssertNotNil(device)
		XCTAssertEqual(deviceToken, device["token"]! as String)
		XCTAssertEqual("apple", device["platform"]! as String)
	}

	private func failed(error: NSError?) {
		if (error != nil) {
			XCTFail(error!.localizedDescription)
		}
	}

	private func toData(deviceToken: String) -> NSData? {
		let trim = deviceToken
			.stringByTrimmingCharactersInSet(
				NSCharacterSet(charactersInString: "<> "))
			.stringByReplacingOccurrencesOfString(" ", withString: "")

		let data = NSMutableData(capacity: countElements(trim) / 2)

		var i = trim.startIndex;

		for (; i < trim.endIndex; i = i.successor().successor()) {
			let byteString = trim.substringWithRange(
				Range<String.Index>(start: i, end: i.successor().successor()))

			let num = Byte(byteString.withCString { strtoul($0, nil, 16) })

			data!.appendBytes([num] as [Byte], length: 1)
		}

		return data
	}

}