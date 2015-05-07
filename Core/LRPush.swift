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

/**
* @author Bruno Farache
*/
public class LRPush {

	let apple = "apple"
	var failure: (NSError -> ())?
	let payload = "payload"
	var pushNotification: ([String: AnyObject] -> ())?
	let session: LRSession
	var success: ([String: AnyObject]? -> ())?

	public class func withSession(session: LRSession) -> LRPush {
		return LRPush(session: session)
	}

	init(session: LRSession) {
		self.session = LRSession(session: session)

		self.session
			.onSuccess({ result -> () in
				if let callback = self.success {
					callback(result as? [String: AnyObject])
				}
			},
			onFailure: { error -> () in
				if let callback = self.failure {
					callback(error)
				}
			})
	}

	public func didReceiveRemoteNotification(
		pushNotification: [String: AnyObject]) {

		var error: NSError?

		let payload = parse(
			pushNotification[self.payload] as! String, error: &error)

		if let e = error {
			failure?(e)

			return
		}

		var temp = pushNotification

		temp[self.payload] = payload

		self.pushNotification?(temp)
	}

	public func onFailure(failure: (NSError -> ())) -> Self {
		self.failure = failure

		return self
	}

	public func onPushNotification(
		pushNotification: ([String: AnyObject] -> ()))-> Self {

		self.pushNotification = pushNotification

		return self
	}

	public func onSuccess(success: ([String: AnyObject]? -> ())) -> Self {
		self.success = success

		return self
	}

	public func registerDevice() {
		let application = UIApplication.sharedApplication()

		let types: UIUserNotificationType = (.Badge | .Sound | .Alert)
		let settings: UIUserNotificationSettings =
			UIUserNotificationSettings(forTypes: types, categories: nil)

		application.registerUserNotificationSettings(settings);
		application.registerForRemoteNotifications()
	}

	public func registerDeviceTokenData(deviceTokenData: NSData) {
		var deviceToken = ""
		let bytes = UnsafePointer<CUnsignedChar>(deviceTokenData.bytes)

		for (var i = 0; i < deviceTokenData.length; i++) {
			deviceToken += String(format: "%02X", bytes[i])
		}

		self.registerDeviceToken(deviceToken)
	}

	public func registerDeviceToken(deviceToken: String) {
		var error: NSError?

		self.getService().addPushNotificationsDeviceWithToken(
			deviceToken, platform: apple, error: &error)

		if let e = error {
			failure?(e)
		}
	}

	public func sendToUserId(userId: Int, notification: [String: AnyObject]) {
		sendToUserId([userId], notification: notification)
	}

	public func sendToUserId(
		userIds: [Int], notification: [String: AnyObject]) {

		var error: NSError?
		let data = NSJSONSerialization.dataWithJSONObject(
			notification, options: NSJSONWritingOptions.allZeros, error: &error)

		if let e = error {
			failure?(e)

			return
		}

		let payload = NSString(data: data!, encoding: NSUTF8StringEncoding)
			as! String

		self.getService().sendPushNotificationWithToUserIds(
			userIds, payload: payload, error: &error)

		if let e = error {
			failure?(e)
		}
	}

	public func unregisterDeviceToken(deviceToken: String) {
		var error: NSError?

		self.getService().deletePushNotificationsDeviceWithToken(
			deviceToken, error: &error)

		if let e = error {
			failure?(e)
		}
	}

	private func getService() -> LRPushNotificationsDeviceService_v62 {
		return LRPushNotificationsDeviceService_v62(session: self.session)
	}

	private func parse(payload: String, error: NSErrorPointer)
		-> [String: AnyObject]? {

		let data = payload.dataUsingEncoding(NSUTF8StringEncoding)!

		var json = NSJSONSerialization.JSONObjectWithData(
			data, options: NSJSONReadingOptions.MutableContainers,
			error: error) as! [String: AnyObject]

		if (error.memory != nil) {
			return nil
		}

		return json;
	}

}