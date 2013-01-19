//
//  Tests.m
//  DeallocTest
//
//  Created by alexey on 19.01.13.
//  Copyright (c) 2013 alexey. All rights reserved.
//

#import "Tests.h"
#include "SandboxBookmark.h"

@implementation Tests

- (BOOL) appendLocalFolderBookrmark
{
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
    {
        NSOpenPanel* dialog = [NSOpenPanel openPanel];
        if (dialog)
        {
            [dialog setCanChooseDirectories : YES];
            [dialog setAllowsMultipleSelection : NO];
            [dialog setResolvesAliases : YES];
            [dialog setCanChooseFiles : NO];
            
            if (NSOKButton == [dialog runModal])
            {
                NSURL* folder                       =   [[dialog URLs] objectAtIndex:0];
                if (folder)
                {
                    SandboxBookmark* bookmark       =   [[SandboxBookmark alloc] initWithURL : folder];
                    if (bookmark)
                    {
                        SandboxBookmarks* bookmarks =   [[SandboxBookmarks alloc] initWithName : @"LocalFolders"];
                        if (bookmarks)
                        {
                            if (-1 == [bookmarks indexOfBookmark : bookmark])
                            {
                                if ([bookmarks synchronizeBookmark : bookmark])
                                {
                                    [bookmark release];
                                    [bookmarks release];
                                    return YES;
                                }
                            }
                            
                            [bookmarks release];
                        }
                        
                        [bookmark release];
                    }
                }
            }
        }
    }
    
    return NO;
}

- (BOOL) isFolderHaveImages : (NSString*) folder
{
	NSFileManager* fileManager          =   [[NSFileManager alloc] init];
    if (fileManager)
    {
        SandboxBookmarks* bookmarks     =   [[SandboxBookmarks alloc] initWithName : @"LocalFolders"];
        if (bookmarks)
        {
            SandboxBookmark* bookmark   =   [bookmarks bookmarkOfName : folder];        //  IF (nil==bookmark) cant't find bookmark with this path
            if (bookmark)
            {
                [bookmark start];
                
                NSArray* keys = [NSArray arrayWithObject:NSURLIsRegularFileKey];
                NSDirectoryEnumerator* enumerator = [fileManager enumeratorAtURL : [bookmark resource]
                                                      includingPropertiesForKeys : keys
                                                                         options : NSDirectoryEnumerationSkipsHiddenFiles
                                                                    errorHandler : nil];
                for (NSURL* fileLink in enumerator)
                {
                    NSString* fileName  =   [fileLink path];
                    NSString* extension =   [[fileName pathExtension] lowercaseString];
                    
                    if ([extension isEqualToString : @"jpg"] || [extension isEqualToString : @"bmp"] || [extension isEqualToString : @"png"])
                    {
                        if (NSNotFound == [fileName rangeOfString:@".thumbnails"].location)
                        {
                            [bookmark stop];
                            [bookmarks release];
                            [fileManager release];
                            
                            return YES;
                        }
                    }
                }
                
                [bookmark stop];
            }
            
            [bookmarks release];
        }
        
        [fileManager release];
    }
    
    return NO;
}

#pragma mark -
#pragma mark drag&drop to application

- (BOOL) performDragOperation : (id<NSDraggingInfo>) sender
{
    NSPasteboard* pboard            =   [sender draggingPasteboard];
	
	if ([[pboard types] containsObject : NSFilenamesPboardType])
	{
        NSArray* files = [pboard propertyListForType:NSFilenamesPboardType];
		if (files.count > 0)
		{
			NSString* file  =   [files objectAtIndex : 0];
            
			NSError* error  =   nil;
			NSArray* array  =   [[NSFileManager defaultManager] contentsOfDirectoryAtPath : file error : &error];
			if (nil == array)
			{
				// FILE LINK
                
                // ....
                
				return YES;
			}
            
            // DIRECTORY LINK
            
            NSURL* folder                       =   [NSURL fileURLWithPath : file isDirectory:YES];
            if (folder)
            {
                SandboxBookmark* bookmark       =   [[SandboxBookmark alloc] initWithURL : folder];
                if (bookmark)
                {
                    SandboxBookmarks* bookmarks =   [[SandboxBookmarks alloc] initWithName : @"LocalFolders"];
                    if (bookmarks)
                    {
                        if (-1 == [bookmarks indexOfBookmark : bookmark])
                        {
                            [bookmarks synchronizeBookmark : bookmark];
                            
                            // ... UPDATE YOU APPLICATION OR SEND NOTIFICATION EVENT
                        }
                        
                        [bookmarks release];
                    }
                    
                    [bookmark release];
                }
            }
		}
    }
	
	return YES;
}

@end
