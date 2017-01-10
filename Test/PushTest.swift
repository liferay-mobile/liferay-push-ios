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
	var timeout: TimeInterval!
	var failureCompletionHandler : XCWaitCompletionHandler!

	override func setUp() {
		super.setUp()

		var settings: [String: String] = [:]
		let bundle = Bundle(identifier: "com.liferay.mobile.sdk.Liferay-Push")
		let path = bundle?.path(forResource: "settings", ofType: "plist")

		failureCompletionHandler = { error in
			self.failed(error as? NSError)
		}

		if (path != nil) {
			settings = NSDictionary(contentsOfFile: path!) as! [String: String]
		}

		let env = ProcessInfo.processInfo.environment

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
				XCTAssertEqual("message", notification["body"] as? String)

				let payload = notification["payload"] as! [String: String]
				XCTAssertEqual("world", payload["hello"]!)
			})
			.onFailure({ error in
				self.failed(error as? NSError)
			})

		push.didReceiveRemoteNotification(
			pushNotification as [String : AnyObject])
	}

	func testRegisterDeviceToken() {
		var expectation = self.expectation(description: "register")
		let deviceToken = "token"

		let push = LRPush.withSession(session)
			.onSuccess({
				let device = $0 as [String: AnyObject]!
				self.assertDevice(deviceToken, device: device!)
				expectation.fulfill()
			})
			.onFailure({ error in
				self.failed(error as? NSError)
				expectation.fulfill()
			})

		push.registerDeviceToken(deviceToken)

		waitForExpectations(timeout: timeout) { (error) in
			if (error != nil) {
				self.failed(error as NSError?)
			}
		}

		expectation = self.expectation(description: "unregister")

		push.unregisterDeviceToken(deviceToken)

		waitForExpectations(
			timeout: timeout, handler: failureCompletionHandler)
	}

	func testRegisterDeviceTokenData() {
		let expectation = self.expectation(description: "register")

		let deviceToken = "<740f4707 bebcf74f 9b7c25d4 8e335894 5f6aa01d " +
			"a5ddb387 462c7eaf 61bb78ad>"

		let deviceTokenData = toData(deviceToken)

		let push = LRPush.withSession(session)
			.onSuccess({
				let device = $0 as [String: AnyObject]!
				self.assertDevice(
					"740F4707BEBCF74F9B7C25D48E3358945F6AA01DA5DDB387462C7EAF" +
						"61BB78AD",
					device: device!)

				expectation.fulfill()
			})
			.onFailure({ error in
				self.failed(error as? NSError)
				expectation.fulfill()
			})

		push.registerDeviceTokenData(deviceTokenData!)

		waitForExpectations(
			timeout: timeout, handler: failureCompletionHandler)
	}

	func testSendPushNotification() {
		let expectation = self.expectation(
			description: "send push notification")

		let push = LRPush.withSession(session)
			.onSuccess({ result in
				expectation.fulfill()
			})
			.onFailure({ error in
				self.failed(error as? NSError)
				expectation.fulfill()
			})

		push.sendToUserId(0, notification: ["message": "hello!" as AnyObject])

		waitForExpectations(
			timeout: timeout, handler: failureCompletionHandler)
	}

	fileprivate func assertDevice(
		_ deviceToken: String, device: [String: AnyObject]) {

		XCTAssertNotNil(device)
		XCTAssertEqual(deviceToken, device["token"] as? String)
		XCTAssertEqual("apple", device["platform"] as? String)
	}

	fileprivate func failed(_ error: NSError?) {
		if (error != nil) {
			XCTFail(error!.localizedDescription)
		}
	}

	fileprivate func toData(_ deviceToken: String) -> Data? {
		let trim = deviceToken
			.trimmingCharacters(
				in: CharacterSet(charactersIn: "<> "))
			.replacingOccurrences(of: " ", with: "")

		let data = NSMutableData(capacity: trim.characters.count / 2)

		var i = trim.startIndex;
		while (i < trim.endIndex) {

			let newEndIndex = trim.index(after: trim.index(after: i))

			let range = Range<String.Index>(
				uncheckedBounds: (lower: i, upper: newEndIndex))

			let byteString = trim.substring(with: range)

			var num = byteString.withCString { strtoul($0, nil, 16) } as UInt
			data!.append(&num, length: 1)

			i = newEndIndex
		}

		return data as Data?
	}

}