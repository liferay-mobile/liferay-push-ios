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

#import "BaseTest.h"

#import "LRBasicAuthentication.h"

/**
 * @author Bruno Farache
 */
@implementation BaseTest

- (void)setUp {
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];

	NSBundle *bundle = [NSBundle
		bundleWithIdentifier:@"com.liferay.mobile.sdk.Liferay-Push"];

	NSString *path = [bundle pathForResource:@"settings" ofType:@"plist"];

	if (path) {
		NSDictionary *settingsFile = [[NSDictionary alloc]
			initWithContentsOfFile:path];

		settings = [NSMutableDictionary dictionaryWithDictionary:settingsFile];
	}

	NSDictionary *environmentVariables = [[NSProcessInfo processInfo]
		environment];

	[settings addEntriesFromDictionary:environmentVariables];

	self.settings = [NSDictionary dictionaryWithDictionary:settings];

	NSString *server = self.settings[@"PUSH_SERVER"];

	id<LRAuthentication> authentication = [[LRBasicAuthentication alloc]
		initWithUsername:self.settings[@"PUSH_USERNAME"]
		password:self.settings[@"PUSH_PASSWORD"]];

	self.session = [[LRSession alloc] initWithServer:server
		authentication:authentication];
}

@end