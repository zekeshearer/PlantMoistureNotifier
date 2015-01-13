//
//  PTDIntelHex.h
//  Bean Loader
//
//  Created by Raymond Kampmeier on 3/18/14.
//  Copyright (c) 2014 Punch Through Design LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PTDIntelHex : NSObject

@property (nonatomic, strong) NSURL* URL;
@property (nonatomic, strong) NSString* name;

-(id)initWithFileURL:(NSURL*)url;

-(NSData*)bytes;

@end
