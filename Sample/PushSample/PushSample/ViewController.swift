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
import LRMobileSDK
import LRPush

class ViewController: UIViewController {

	@IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var sendPushButton: UIButton!
	@IBOutlet weak var pushBodyTextField: UITextField!

	private var userId: Int?

	override func viewDidLoad() {
		super.viewDidLoad()

		loadingActivityIndicator.startAnimating()
		sendPushButton.isEnabled = false

		getUserId()
	}

	@IBAction func sendPushClicked() {
		guard let userId = userId else {
			return
		}

		let body = pushBodyTextField.text ?? ""

		LRPush.withSession(getSession())
			.withPortalVersion(70)
			.sendToUserId(userId, notification: ["body": body as AnyObject])
	}

	private func getUserId() {
		let session = getSession()

		session.callback = LRBlockCallback(success: { response in
			guard let userAttrs = response as? [String: AnyObject] else {
				return
			}

			self.userId = userAttrs["userId"]?.intValue

			self.loadingActivityIndicator.stopAnimating()
			self.loadingActivityIndicator.isHidden = true
			self.sendPushButton.isEnabled = true
		}, failure: { failure in
			print("Failure getting the user")
		})

		let service = LRUserService_v7(session: session)

		_ = try? service?.getCurrentUser()
	}

	func getSession() -> LRSession {
		return LRSession(
			server: server,
			authentication: LRBasicAuthentication(username: user, password: password))!
	}
}


