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

#import "LRPush.h"

#import "LRPushNotificationsDeviceService_v62.h"

NSString *const IOS = @"ios";

/**
 * @author Bruno Farache
 */
@interface LRPush ()

@property (nonatomic, copy) LRFailureBlock failure;
@property (nonatomic, copy) LRSuccessBlock success;

@end

@implementation LRPush

+ (instancetype)withSession:(LRSession *)session {
	return [[LRPush alloc] initWithSession:session];
}

- (id)initWithSession:(LRSession *)session {
	self = [super init];

	if (self) {
		self.session = [[LRSession alloc] initWithSession:session];

		[self.session
			onSuccess:^(id result) {
				if (self.success) {
					self.success(result);
				}
			}
			onFailure:^(NSError *error) {
				[self _onFailure:error];
			}
		];
	}

	return self;
}

- (instancetype)onFailure:(LRFailureBlock)failure {
	self.failure = failure;

	return self;
}

- (instancetype)onSuccess:(LRSuccessBlock)success {
	self.success = success;

	return self;
}

- (void)registerDevice {
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
		(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)
	];
}

- (void)registerDeviceToken:(NSString *)deviceToken {
	NSError *error;

	[[self _getService] addPushNotificationsDeviceWithToken:deviceToken
		platform:IOS error:&error];

	if (error) {
		[self _onFailure:error];
	}
}

- (void)registerDeviceTokenData:(NSData *)deviceTokenData {
	const unsigned *bytes = [deviceTokenData bytes];

	NSString *deviceToken = [NSString
		stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
		ntohl(bytes[0]), ntohl(bytes[1]), ntohl(bytes[2]), ntohl(bytes[3]),
		ntohl(bytes[4]), ntohl(bytes[5]), ntohl(bytes[6]), ntohl(bytes[7])];

	[self registerDeviceToken:deviceToken];
}

- (void)sendToUserId:(long long)userId
		notification:(NSDictionary *)notification {

	[self sendToUserIds:@[@(userId)] notification:notification];
}

- (void)sendToUserIds:(NSArray *)userIds
		notification:(NSDictionary *)notification {

	NSError *error;

	NSData *data = [NSJSONSerialization dataWithJSONObject:notification
		options:0 error:&error];

	NSString *payloadString = [[NSString alloc] initWithData:data
		encoding:NSUTF8StringEncoding];

	if (error) {
		[self _onFailure:error];
	}

	[[self _getService] sendPushNotificationWithToUserIds:userIds
		payload:payloadString error:&error];

	if (error) {
		[self _onFailure:error];
	}
}

- (void)unregisterDeviceToken:(NSString *)deviceToken {
	NSError *error;

	[[self _getService] deletePushNotificationsDeviceWithToken:deviceToken
		error:&error];

	if (error) {
		[self _onFailure:error];
	}
}

- (LRPushNotificationsDeviceService_v62 *)_getService {
	return [[LRPushNotificationsDeviceService_v62 alloc]
		initWithSession:self.session];
}

- (void)_onFailure:(NSError *)error {
	if (self.failure) {
		self.failure(error);
	}
}

@end