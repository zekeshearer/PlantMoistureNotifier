//
//  PTDIntelHex.m
//  Bean Loader
//
//  Created by Raymond Kampmeier on 3/18/14.
//  Copyright (c) 2014 Punch Through Design LLC. All rights reserved.
//

#import "PTDIntelHex.h"

typedef enum {
    IntelHexLineRecordType_Data                         = 00,
    IntelHexLineRecordType_EndOfFile                    = 01,
    IntelHexLineRecordType_ExtendedSegmentAddress       = 02,
    IntelHexLineRecordType_StartSegmentAddress          = 03,
    IntelHexLineRecordType_ExtendedLinearAddress        = 04,
    IntelHexLineRecordType_StartLinearAddress           = 05,
} IntelHexLineRecordType;

@interface IntelHexLine : NSObject
    @property (nonatomic) UInt8   byteCount;
    @property (nonatomic) UInt16  address;
    @property (nonatomic) IntelHexLineRecordType recordType;
    @property (nonatomic, strong) NSData* data;
    @property (nonatomic) UInt8   checksum;
@end
@implementation IntelHexLine @end


@implementation PTDIntelHex{
    NSMutableArray* lines;
}

-(id)initWithFileURL:(NSURL*)url{
    self = [super init];
    if (self) {
        _URL = url;
        
        NSString* tempName = [_URL lastPathComponent];
        NSRange range = [tempName rangeOfString:@"."];
        tempName = [tempName substringToIndex:range.location];
        _name = tempName;
        
        lines = [[NSMutableArray alloc] init];
        
        NSError *err;
        NSString *filecontents= [NSString stringWithContentsOfFile:url.path encoding:NSUTF8StringEncoding error:&err];
        if (![self parseFileContents:filecontents]){
            //TODO: Log this error. Invalid Hex file
            return nil;
        }
    }
    return self;
}

-(NSData*)bytes{
    NSMutableData* imageData = [[NSMutableData alloc] init];
    
    for (IntelHexLine* line in lines){
        if(line.recordType == IntelHexLineRecordType_Data){
            [imageData appendData:line.data];
        }
    }
    return [imageData copy];
}

-(BOOL)parseFileContents:(NSString*)filecontents{
    NSArray* rawlines = [filecontents componentsSeparatedByString:@"\n"];
    for (NSString* rawline in rawlines){
        if(rawline.length >= 11){
            if( ![[rawline substringWithRange:NSMakeRange(0, 1)] isEqual: @":"]){
                return FALSE;
            }
            IntelHexLine* line = [[IntelHexLine alloc] init];
            
            line.byteCount = (UInt8)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(1, 2)]];
            line.address = (UInt16)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(3, 4)]];
            line.recordType = (IntelHexLineRecordType)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(7, 2)]];
            line.data = [self bytesFromHexString:[rawline substringWithRange:NSMakeRange(9, line.byteCount*2)]];
            line.checksum = (UInt8)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(9+(line.byteCount*2), 2)]];
            
            [lines addObject:line];
            
            if(!line.data)return FALSE;
            if([line.data length] != line.byteCount)return FALSE;
        }
    }
  //  NSLog(@"Number of Lines: %lu",(unsigned long)lines.count);
  //  NSLog(@"Bytes: %@",[self bytes]);
    return TRUE;
}

-(unsigned)numberFromHexString:(NSString*)string{
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner scanHexInt:&result];
    return result;
}
-(NSData*)bytesFromHexString:(NSString*)string{
    NSMutableData* data = [NSMutableData data];
    for (int i = 0; i+2 <= string.length; i+=2) {
        NSString* hexByteStr = [string substringWithRange:NSMakeRange(i, 2)];
        NSScanner* scanner = [NSScanner scannerWithString:hexByteStr];
        unsigned int intValue;
        if ([scanner scanHexInt:&intValue])
            [data appendBytes:&intValue length:1];
    }
    return [data copy];
}
@end
