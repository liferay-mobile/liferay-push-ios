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

	public static let PAYLOAD = "payload"

	var failure: (NSError -> ())?
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
				self.success?(result as? [String: AnyObject])
			},
			onFailure: { error -> () in
				self.failure?(error)
			})
	}

	public func didReceiveRemoteNotification(
		pushNotification: [String: AnyObject]) {

		var mutablePushNotification = pushNotification

		do {
			let payload = try parse(pushNotification[LRPush.PAYLOAD] as! String)
			mutablePushNotification[LRPush.PAYLOAD] = payload
			self.pushNotification?(mutablePushNotification)
		}
		catch let error as NSError {
			failure?(error)
		}
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

		let types: UIUserNotificationType = [.Badge, .Sound, .Alert]
		let settings: UIUserNotificationSettings =
			UIUserNotificationSettings(forTypes: types, categories: nil)

		application.registerUserNotificationSettings(settings);
		application.registerForRemoteNotifications()
	}

	public func registerDeviceTokenData(deviceTokenData: NSData) {
		var deviceToken = ""
		let bytes = UnsafePointer<CUnsignedChar>(deviceTokenData.bytes)

		for i in 0 ..< deviceTokenData.length {
			deviceToken += String(format: "%02X", bytes[i])
		}

		registerDeviceToken(deviceToken)
	}

	public func registerDeviceToken(deviceToken: String) {
		do {
			try getService().addPushNotificationsDeviceWithToken(
				deviceToken, platform: _APPLE)
		}
		catch {
		}
	}

	public func sendToUserId(userId: Int, notification: [String: AnyObject]) {
		sendToUserId([userId], notification: notification)
	}

	public func sendToUserId(
		userIds: [Int], notification: [String: AnyObject]) {

		do {
			let data = try NSJSONSerialization.dataWithJSONObject(
				notification, options: NSJSONWritingOptions())

			let payload = NSString(data: data, encoding: NSUTF8StringEncoding)
				as! String

			var error: NSError?

			getService().sendPushNotificationWithToUserIds(
				userIds, payload: payload, error: &error)
		}
		catch let error as NSError {
			failure?(error)
		}
	}

	public func unregisterDeviceToken(deviceToken: String) {
		do {
			try getService().deletePushNotificationsDeviceWithToken(deviceToken)
		}
		catch {
		}
	}

	private func getService() -> LRPushNotificationsDeviceService_v62 {
		return LRPushNotificationsDeviceService_v62(session: session)
	}

	private func parse(payload: String) throws
		-> [String: AnyObject] {

		let data = payload.dataUsingEncoding(NSUTF8StringEncoding)!

		return try NSJSONSerialization.JSONObjectWithData(
			data, options: NSJSONReadingOptions.MutableContainers)
			as! [String: AnyObject]
	}

	private let _APPLE = "apple"

}