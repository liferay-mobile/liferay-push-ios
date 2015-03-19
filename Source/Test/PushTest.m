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

- (void)testPushNotification {
	NSDictionary *pushNotification = @{
		@"body": @"message",
		@"payload": @"{\"hello\": \"world\"}"
	};

	LRPush *push = [[[LRPush withSession:self.session]
		onPushNotification:^(NSDictionary *pushNotification) {
			XCTAssertEqualObjects(@"message", pushNotification[@"body"]);

			NSDictionary *payload = pushNotification[@"payload"];
			XCTAssertEqualObjects(@"world", payload[@"hello"]);
		}]
	 	onFailure:^(NSError *e) {
			XCTFail(@"Error: %@", [e localizedDescription]);
		}];

	[push didReceiveRemoteNotification:pushNotification];
}

- (void)testRegisterDeviceToken {
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

- (void)testRegisterDeviceTokenData {
	TRVSMonitor *monitor = [TRVSMonitor monitor];
	__block NSDictionary *device;
	__block NSError *error;

	NSString *deviceToken = @"<740f4707 bebcf74f 9b7c25d4 8e335894 5f6aa01d " \
		"a5ddb387 462c7eaf 61bb78ad>";

	NSData *deviceTokenData = [self _dataFromHexString:deviceToken];

	LRPush *push = [[[LRPush withSession:self.session]
		onSuccess:^(NSDictionary *result) {
			device = result;
			[monitor signal];
		}]
	 	onFailure:^(NSError *e) {
			error = e;
			[monitor signal];
		}];

	[push registerDeviceTokenData:deviceTokenData];
	[monitor wait];

	[self _assert:device
	  	deviceToken:@"740f4707bebcf74f9b7c25d48e3358945f6aa01d" \
	 		"a5ddb387462c7eaf61bb78ad"
		error:error];
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

- (NSData *)_dataFromHexString:(NSString *)string {
	string = [string lowercaseString];
	NSMutableData *data = [NSMutableData data];

	unsigned char whole_byte;
	char byte_chars[3] = {'\0','\0','\0'};
	int i = 0;

	while (i < string.length - 1) {
		char c = [string characterAtIndex:i++];

		if ((c < '0') || (c > '9' && c < 'a') || (c > 'f')) {
			continue;
		}

		byte_chars[0] = c;
		byte_chars[1] = [string characterAtIndex:i++];
		whole_byte = strtol(byte_chars, NULL, 16);

		[data appendBytes:&whole_byte length:1];
	}

	return data;
}

@end