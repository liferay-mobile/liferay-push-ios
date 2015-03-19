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
#import "LRPush.h"
#import "TRVSMonitor.h"

/**
 * @author Bruno Farache
 */
@interface PushTest : BaseTest
@end

@implementation PushTest

- (void)testRegister {
	TRVSMonitor *monitor = [TRVSMonitor monitor];
	__block NSDictionary *device;
	__block NSError *error;

	NSString *deviceToken = @"token";

	LRPush *push = [[[LRPush withSession:self.session]
		onSuccess:^(NSDictionary *result) {
			device = result;
			[monitor signal];
		}]
	 	onFailure:^(NSError *e) {
			error = e;
			[monitor signal];
		}];

	[push registerDeviceToken:deviceToken];
	[monitor wait];

	[self _assert:device deviceToken:deviceToken error:error];

	[push unregisterDeviceToken:deviceToken];
	[monitor wait];

	[self _assert:device deviceToken:deviceToken error:error];
}

- (void)testSendPushNotification {
	TRVSMonitor *monitor = [TRVSMonitor monitor];
	__block NSError *error;

	LRPush *push = [[[LRPush withSession:self.session]
		onSuccess:^(NSDictionary *result) {
			[monitor signal];
		}]
	 	onFailure:^(NSError *e) {
			error = e;
			[monitor signal];
		}];

	[push sendToUserId:0 notification:@{@"message": @"hello!"}];
	[monitor wait];

	XCTAssertNil(error);
}

- (void)_assert:(NSDictionary *)device deviceToken:(NSString *)deviceToken
		error:(NSError *)error {

	XCTAssertNil(error);
	XCTAssertNotNil(device);

	XCTAssertEqualObjects(deviceToken, device[@"token"]);
	XCTAssertEqualObjects(@"ios", device[@"platform"]);
}

@end