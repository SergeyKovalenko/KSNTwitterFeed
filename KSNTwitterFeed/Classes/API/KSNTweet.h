//
// Created by Sergey Kovalenko on 6/24/16.
//

#import <Foundation/Foundation.h>
@import CoreData;

@class FEMMapping;

/*
 * {
	"created_at": "Sun Oct 21 09:36:54 +0000 2012",
	"id": 259951384286334976,
	"id_str": "259951384286334976",
	"text": "\u043a\u0443\u043a\u0443",
	"truncated": false,
	"entities": {
		"hashtags": [],
		"symbols": [],
		"user_mentions": [],
		"urls": []
	},
	"source": "\u003ca href=\"http:\/\/twitter.com\" rel=\"nofollow\"\u003eTwitter Web Client\u003c\/a\u003e",
	"in_reply_to_status_id": null,
	"in_reply_to_status_id_str": null,
	"in_reply_to_user_id": null,
	"in_reply_to_user_id_str": null,
	"in_reply_to_screen_name": null,
	"user": {
		"id": 430984851,
		"id_str": "430984851",
		"name": "Julia",
		"screen_name": "DJuliaKovalenko",
		"location": "",
		"description": "",
		"url": null,
		"entities": {
			"description": {
				"urls": []
			}
		},
		"protected": false,
		"followers_count": 3,
		"friends_count": 2,
		"listed_count": 0,
		"created_at": "Wed Dec 07 19:52:09 +0000 2011",
		"favourites_count": 0,
		"utc_offset": null,
		"time_zone": null,
		"geo_enabled": false,
		"verified": false,
		"statuses_count": 2,
		"lang": "ru",
		"contributors_enabled": false,
		"is_translator": false,
		"is_translation_enabled": false,
		"profile_background_color": "C0DEED",
		"profile_background_image_url": "http:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png",
		"profile_background_image_url_https": "https:\/\/abs.twimg.com\/images\/themes\/theme1\/bg.png",
		"profile_background_tile": false,
		"profile_image_url": "http:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_3_normal.png",
		"profile_imag
 e_url_https": "https:\/\/abs.twimg.com\/sticky\/default_profile_images\/default_profile_3_normal.png",
		"profile_link_color": "0084B4",
		"profile_sidebar_border_color": "C0DEED",
		"profile_sidebar_fill_color": "DDEEF6",
		"profile_text_color": "333333",
		"profile_use_background_image": true,
		"has_extended_profile": false,
		"default_profile": true,
		"default_profile_image": true,
		"following": false,
		"follow_request_sent": false,
		"notifications": false
	},
	"geo": null,
	"coordinates": null,
	"place": null,
	"contributors": null,
	"is_quote_status": false,
	"retweet_count": 0,
	"favorite_count": 0,
	"favorited": false,
	"retweeted": false,
	"lang": "ru"
}*/


@protocol KSNTweet <NSObject>

@property (nonatomic, readonly) int64_t tweetID;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *createdDate;
@end


@interface KSNTweet : NSManagedObject <KSNTweet>

+ (FEMMapping *)tweetMapping;
+ (NSManagedObjectModel *)managedObjectModel;

@end
