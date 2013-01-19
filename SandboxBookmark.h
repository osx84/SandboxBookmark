//
//  SandboxBookmark.h
//  ePic
//
//  Created by alexey on 08.01.13.
//  Copyright (c) 2013 Epicreal Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SandboxBookmark : NSObject
{
    BOOL    _blockPath;
    NSURL*  _scopedResource;
    NSData* _bookmarkData;
}

- (id) initWithURL : (NSURL*) resource;
- (id) initWithData : (NSData*) data;

- (BOOL) loadByNameOfSettings : (NSString*) name;
- (BOOL) validateByName : (NSString*) name;

- (BOOL) isValid;

- (BOOL) start;
- (BOOL) stop;

- (NSString*) path;
- (NSData*) data;
- (NSURL*) resource;

@end

@interface SandboxBookmarks : NSObject
{
    NSString*       _name;
    NSMutableArray* _bookmarks;
}

- (id) initWithName : (NSString*) name;

- (BOOL) synchronizeBookmark : (SandboxBookmark*) bookmark;
- (BOOL) synchronizeClear;

- (SandboxBookmark*) bookmarkAtIndex : (NSInteger) index;
- (SandboxBookmark*) bookmarkOfName : (NSString*) name;
- (NSInteger) indexOfBookmark : (SandboxBookmark*) bookmark;
- (NSInteger) count; 

- (BOOL) removeInvalidLinks;

@end
