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

import UIKit
import UserNotifications
import LRPush

let server = "http://localhost:8080"
let user = "test@liferay.com"
let password = "test"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

	var window: UIWindow?

	// MARK: UIApplicationDelegate

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		registerForRemoteNotifications()

		return true
	}

	func application(
		_ application: UIApplication,
		didReceiveRemoteNotification userInfo: [AnyHashable : Any],
		fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

		print("Remote notification \(userInfo)")
	}

	func application(
		_ application: UIApplication,
		didFailToRegisterForRemoteNotificationsWithError error: Error) {

		print("error registering \(error)")
	}

	func application(
		_ application: UIApplication,
		didRegisterForRemoteNotificationsWithDeviceToken
		deviceToken: Data) {

		let session = LRSession(
			server: server,
			authentication: LRBasicAuthentication(username: user, password: password))

		LRPush.withSession(session!)
			.withPortalVersion(70)
			.onSuccess {
				print("Success: \(String(describing: $0))")
			}
			.onFailure {
				print("Error \(String(describing: $0))")
			}
			.registerDeviceTokenData(deviceToken)
	}

	// MARK: UNUserNotificationCenterDelegate

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		willPresent notification: UNNotification,
		withCompletionHandler completionHandler: @escaping (_ options:UNNotificationPresentationOptions) -> Void) {

		print("Handle push from foreground")
		print("\(notification.request.content.userInfo)")

		completionHandler(.alert)
	}

	// MARK: Private methods

	func registerForRemoteNotifications() {
		if #available(iOS 10, *) {
			registerWithUserNotification()
		}
		else {
			let types: UIUserNotificationType = [.badge, .sound, .alert]
			let settings = UIUserNotificationSettings.init(
				types: types, categories: nil)

			UIApplication.shared.registerUserNotificationSettings(settings);
			UIApplication.shared.registerForRemoteNotifications()
		}
	}

	func registerWithUserNotification() {
		let center = UNUserNotificationCenter.current()
		center.delegate = self

		center.getNotificationSettings { settings in
			if settings.authorizationStatus == .authorized {
				// Calling this everytime because the token can change

				DispatchQueue.main.async {
					UIApplication.shared.registerForRemoteNotifications()
				}
			}
			else {
				center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
					if granted {
						print("granted")
						DispatchQueue.main.async {
							UIApplication.shared.registerForRemoteNotifications()
						}
					}
					else {
						print("Error requesting push authorization \(String(describing: error))")
					}
				}
			}
		}
	}
}


