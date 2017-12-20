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

open class LRPushNotificationServiceWrapper {

	var service62: LRPushNotificationsDeviceService_v62?
	var service70: LRPushNotificationsDeviceService_v7?

	init(session: LRSession, _ portalVersion: Int) {
		if (portalVersion == 62) {
			self.service62 = LRPushNotificationsDeviceService_v62(session: session)
		} else {
			self.service70 = LRPushNotificationsDeviceService_v7(session: session)
		}
	}

	func addPushNotificationsDevice(
		withToken deviceToken: String, platform: String) throws -> Dictionary<AnyHashable, Any>? {
		if (self.service62 != nil) {
			return try self.service62?.addPushNotificationsDevice(withToken: deviceToken, platform: platform);
		}
		return try self.service70?.addPushNotificationsDevice(withToken: deviceToken, platform: platform)
	}
	

	func deletePushNotificationsDevice(
		withToken deviceToken: String) throws -> Dictionary<AnyHashable, Any>? {
		if (self.service62 != nil) {
			return try self.service62?.deletePushNotificationsDevice(withToken: deviceToken);
		}
		return try self.service70?.deletePushNotificationsDevice(withToken: deviceToken)
	}

	func sendPushNotificationWith(
		toUserIds userIds: [Int], payload: String, error: NSErrorPointer) throws {
		if (self.service62 != nil) {
			try self.service62?.sendPushNotificationWith(toUserIds: userIds, payload: payload, error: error);
			return
		}
		try self.service70?.sendPushNotificationWith(toUserIds: userIds, payload: payload, error: error)
	}

}
