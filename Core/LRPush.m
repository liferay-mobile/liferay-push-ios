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

#import "LRError.h"
#import "LRPushNotificationsDeviceService_v62.h"

NSString *const APPLE = @"apple";
NSString *const PAYLOAD = @"payload";

/**
 * @author Bruno Farache
 */
@interface LRPush ()

@property (nonatomic, copy) LRPushNotificationFailureBlock failure;
@property (nonatomic, copy) LRPushNotificationSuccessBlock pushNotification;
@property (nonatomic, copy) LRPushNotificationSuccessBlock success;

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

- (void)didReceiveRemoteNotification:(NSDictionary *)pushNotification {
	NSError *error;

	NSDictionary *payload = [self _parse:pushNotification[PAYLOAD]
		error:&error];

	if (error) {
		self.failure(error);

		return;
	}

	NSMutableDictionary *mutablePushNotification = [NSMutableDictionary
		dictionaryWithDictionary:pushNotification];

	mutablePushNotification[PAYLOAD] = payload;

	self.pushNotification(mutablePushNotification);
}

- (instancetype)onFailure:(LRFailureBlock)failure {
	self.failure = failure;

	return self;
}

- (instancetype)onPushNotification:(
		LRPushNotificationSuccessBlock)pushNotification {

	self.pushNotification = pushNotification;

	return self;
}

- (instancetype)onSuccess:(LRPushNotificationSuccessBlock)success {
	self.success = success;

	return self;
}

- (void)registerDevice {
	UIApplication *application = [UIApplication sharedApplication];

	if ([application respondsToSelector:
			@selector(registerForRemoteNotifications)]) {

		UIUserNotificationType types = (UIUserNotificationTypeAlert |
			UIUserNotificationTypeBadge | UIUserNotificationTypeSound);

		UIUserNotificationSettings *settings = [UIUserNotificationSettings
			settingsForTypes:types categories:nil];

		[application registerUserNotificationSettings:settings];
		[application registerForRemoteNotifications];
	}
	else {
		[application registerForRemoteNotificationTypes:
			(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |
				UIRemoteNotificationTypeSound)
		];
	}
}

- (void)registerDeviceToken:(NSString *)deviceToken {
	NSError *error;

	[[self _getService] addPushNotificationsDeviceWithToken:deviceToken
		platform:APPLE error:&error];

	if (error) {
		[self _onFailure:error];
	}
}

- (void)registerDeviceTokenData:(NSData *)deviceTokenData {
	const uint64_t *bytes = [deviceTokenData bytes];

	NSString *deviceToken = [NSString
		stringWithFormat:@"%016llx%016llx%016llx%016llx",
		ntohll(bytes[0]), ntohll(bytes[1]), ntohll(bytes[2]), ntohll(bytes[3])];

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

- (NSDictionary *)_parse:(NSString *)payload error:(NSError **)error {
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	NSError *parseError;
	
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0
		error:&parseError];

	if (parseError) {
		NSDictionary *userInfo = @{
			NSUnderlyingErrorKey: parseError
		};

		*error = [LRError errorWithCode:LRErrorCodeParse
			description:@"json-parsing-error" userInfo:userInfo];
	}

	if (*error) {
		return nil;
	}

	return json;
}

@end