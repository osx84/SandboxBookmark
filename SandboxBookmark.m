//
//  SandboxBookmark.m
//  ePic
//
//  Created by alexey on 08.01.13.
//  Copyright (c) 2013 Epicreal Team. All rights reserved.
//

#import "SandboxBookmark.h"

@implementation SandboxBookmark

- (id) init
{
    self = [super init];
    
    if (self)
    {
        _blockPath      =   NO;
        _scopedResource =   nil;
        _bookmarkData   =   nil;
    }
    
	return self;
}

- (id) initWithURL : (NSURL*) resource
{
    self = [super init];
    
    if (self)
    {
        _blockPath      =   NO;
        _scopedResource =   nil;
        _bookmarkData   =   nil;
        
        if (resource)
        {
            [resource retain];
            _scopedResource =  resource;

            NSError* error  =   nil;
            _bookmarkData   =   [_scopedResource bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
            if (error || (_bookmarkData == nil))
            {
#ifdef _DEBUG
                NSLog(@"Secure bookmark creation of %@ failed with error: %@",[_scopedResource path], [error localizedDescription]);
#endif
            }
            else
            {
                [_bookmarkData retain];
            }            
        }
    }
    
    return self;
}

- (id) initWithData : (NSData*) data
{
    self = [super init];
    
    if (self)
    {
        _blockPath          =   NO;
        _scopedResource     =   nil;
        _bookmarkData       =   nil;
        
        if (data)
        {
            [data retain];
            _bookmarkData   =   data;
        }
        
        if ((nil != _bookmarkData))
        {
            NSError* error          =   nil;
            BOOL bookmarkIsStale    =   NO;
            _scopedResource         =   [NSURL URLByResolvingBookmarkData : _bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL : nil bookmarkDataIsStale : &bookmarkIsStale error : &error];
            if (bookmarkIsStale || (error != nil))
            {
#ifdef _DEBUG
                NSLog(@"Secure bookmark was failed with error: %@",[error localizedDescription]);
#endif
            }
            else
            {
                [_scopedResource retain];
            }
        }
    }
    
    return self;  
}

- (void) dealloc
{
	[self stop];
    
    if (_bookmarkData)
    {
        [_bookmarkData release];
        _bookmarkData = nil;
    }
    
	[super dealloc];
}

- (BOOL) loadByNameOfSettings : (NSString*) name
{
    if (_scopedResource)
    {
        [_scopedResource release];
        _scopedResource = nil;
    }    
    
    NSData* bookmark            =   [[NSUserDefaults standardUserDefaults] objectForKey : [NSString stringWithFormat:@"%@Data", name]];
    NSString* bookmarkPath      =   [[NSUserDefaults standardUserDefaults] objectForKey : name];
    if ((nil != bookmark) && (nil != bookmarkPath))
    {
        NSError* error          =   nil;
        BOOL bookmarkIsStale    =   NO;
        _scopedResource         =   [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&bookmarkIsStale error:&error];
        if (bookmarkIsStale || (error != nil))
        {
#ifdef _DEBUG
            NSLog(@"Secure bookmark was pruned, resolution of %@ failed with error: %@",bookmarkPath,[error localizedDescription]);
#endif
        }
        else
        {
            [_scopedResource retain];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) validateByName : (NSString*) name
{
    NSString* bookmarkPath      =   [[NSUserDefaults standardUserDefaults] objectForKey : name];
    if (nil == bookmarkPath)
        return NO;
    
    NSData* bookmark            =   [[NSUserDefaults standardUserDefaults] objectForKey : [NSString stringWithFormat:@"%@Data", name]];
    if (nil == bookmark)
        return NO;
    
    return YES;  
}

- (BOOL) isValid
{
    BOOL readable   =   YES;
    
#ifdef IS_MAS
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
    {        
        [self start];        
       
        readable    =   [[NSFileManager defaultManager] isReadableFileAtPath:[_scopedResource path]];
       
        [self stop];
    }
#endif
    
    return readable;
}

- (BOOL) start
{
#ifdef IS_MAS
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
    {
        if (_blockPath)     
            return YES;
        
        if (_scopedResource)
        {
            _blockPath  =   YES;
            
            if ([_scopedResource query])
                [_scopedResource startAccessingSecurityScopedResource];
            
#ifdef _DEBUG
            if (NO == [[NSFileManager defaultManager] isReadableFileAtPath:[_scopedResource path]])
                NSLog(@"[Sandbox] - Access denied to %@ %@",[_scopedResource path],[_scopedResource query]);
#endif
            return YES;
        }
        
    }
#endif
    
    return NO;
}

- (BOOL) stop
{
#ifdef IS_MAS
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
    {
        if (_blockPath)
        {
            _blockPath  =   NO;
            
            if (_scopedResource)
            {
                if ([_scopedResource query])
                    [_scopedResource stopAccessingSecurityScopedResource];
            }
        }
        
        if (_scopedResource)
        {
            [_scopedResource release];
            _scopedResource = nil;
        }
    }
#endif
    
    return NO;
}

- (NSURL*) resource
{
    return  _scopedResource;
}

- (NSData*) data
{
    if (nil==_bookmarkData)
    {
        NSError* error  =   nil;
        _bookmarkData   =   [_scopedResource bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
        if ((nil==_bookmarkData) || (error != nil))
        {
#ifdef _DEBUG
            NSLog(@"Secure bookmark was failed with error: %@",[error localizedDescription]);
#endif
        }
        else
        {
            [_bookmarkData retain];
        }
    }
    
    return _bookmarkData;
}

- (NSString*) path
{
    if (_scopedResource)
        return [_scopedResource path];
    
    return @"";
}

@end

@implementation SandboxBookmarks

- (id) init
{
    self = [super init];
    
    if (self)
    {
        _name       =   nil;
        _bookmarks  =   [[NSMutableArray array] retain];
    }
    
	return self;
}

- (void) dealloc
{
    if (_bookmarks)
    {
        for (NSInteger i = 0; i < _bookmarks.count; ++i)
        {
            SandboxBookmark* bookmark = [_bookmarks objectAtIndex:i];
            if (bookmark)
                [bookmark release];
        }
        
        [_bookmarks release];
        _bookmarks = nil;
    }
    
    if (_name)
    {
        [_name release];
        _name = nil;
    }
    
	[super dealloc];
}

- (id) initWithName : (NSString*) name
{
    self = [super init];
    
    if (self)
    {
        _name       =   nil;
        _bookmarks  =   nil;
        
        if (name)
        {
            [name retain];
            _name       =   name;
            
            _bookmarks  =   [[NSMutableArray alloc] init];
            
            NSUserDefaults* defaults                =   [NSUserDefaults standardUserDefaults];
            if (defaults)
            {
                id obj                              =   [defaults objectForKey : name];
                if (obj)
                {
                    NSMutableArray* array           =   [NSMutableArray arrayWithArray:[defaults objectForKey : name]];
                    for (NSData* data in array)
                    {
                        SandboxBookmark* bookmark   =   [[SandboxBookmark alloc] initWithData : data];
                        if (bookmark)
                        {
                            [_bookmarks addObject : bookmark];
                        }
                    }
                }
                
                /*
                 
                 NSMutableDictionary* dict          =   [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey : _name]];
                 if (dict)
                 {
                    for (NSString *key in dict)
                    {
                        SandboxBookmark* bookmark   =   [[SandboxBookmark alloc] initWithData : [dict objectForKey:key]];
                        if (bookmark)
                        {
                            [_bookmarks addObject : bookmark];
                        }
                    }
                 }
                 
                 */
            }
        }
    }
    
    return self;
}

- (BOOL) synchronizeClear
{
    if (_name)
    {
        if (_bookmarks)
        {
            for (NSInteger i = 0; i < _bookmarks.count; ++i)
            {
                SandboxBookmark* bookmark = [_bookmarks objectAtIndex:i];
                if (bookmark)
                    [bookmark release];
            }
            
            [_bookmarks removeAllObjects];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject : nil forKey : _name];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        return YES;
    }
    
    return NO;
}

- (BOOL) synchronizeBookmark : (SandboxBookmark*) bookmark
{
    if (bookmark)
    {
        NSUserDefaults* defaults    =   [NSUserDefaults standardUserDefaults];
        if (defaults)
        {
            NSMutableArray* array   =   [NSMutableArray arrayWithArray:[defaults objectForKey:_name]];
            if (array)
            {
                [array addObject : [bookmark data]];
                [defaults setObject : array forKey : _name];
                [defaults synchronize];
                
                [bookmark retain];
                [_bookmarks addObject:bookmark];
                
                return YES;
            }
            
            /*
             
            NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey : _name]];
            if (dict)
            {
                [dict setObject : [bookmark data] forKey : [bookmark  path]];
                [defaults setObject : dict forKey : _name];
                [defaults synchronize];
                
                [bookmark retain];
                [_bookmarks addObject:bookmark];
                
                return YES;
            }
            
            */
        }
    }
    
    return NO;
}

- (SandboxBookmark*) bookmarkAtIndex : (NSInteger) index
{
    if (_bookmarks)
    {
        if (index < _bookmarks.count)
        {
            return [_bookmarks objectAtIndex:index];
        }
    }
    
    return nil;
}

- (SandboxBookmark*) bookmarkOfName : (NSString*) name
{
    if (_bookmarks)
    {
        for (NSInteger i = 0; i < _bookmarks.count; ++i)
        {
            SandboxBookmark* bookmark   =   (SandboxBookmark*)[_bookmarks objectAtIndex:i];
            if (bookmark)
            {
                if ([name isEqualToString:[bookmark path]])
                    return bookmark;
            }            
        }
    }
    
    return nil;
}

- (NSInteger) indexOfBookmark : (SandboxBookmark*) bookmark
{
    if ((nil != _bookmarks) && (nil != bookmark))
    {
        NSString* path = [bookmark path];
        for (NSInteger i = 0; i < _bookmarks.count; ++i)
        {
            SandboxBookmark* bookmark   =   (SandboxBookmark*)[_bookmarks objectAtIndex:i];
            if (bookmark)
            {
                if ([path isEqualToString:[bookmark path]])
                    return i;
            }
        }
    }
    
    return -1;
}

- (NSInteger) count
{
    if (_bookmarks)
        return _bookmarks.count;
   
    return 0;
}

- (BOOL) removeInvalidLinks
{
    if (_name)
    {
        if (_bookmarks)
        {
            NSMutableArray* array           =   [NSMutableArray array];
            
            for (NSInteger i = 0; i < _bookmarks.count; ++i)
            {
                SandboxBookmark* bookmark   =   [_bookmarks objectAtIndex:i];
                if (bookmark)
                {
                    if ([bookmark isValid])
                        [array addObject:[bookmark data]];
                }
            }
            
            if (_bookmarks.count != array.count)
            {
                NSUserDefaults* defaults    =   [NSUserDefaults standardUserDefaults];
                if (defaults)
                {
                    [defaults setObject : array forKey : _name];
                    [defaults synchronize];
                    
                    return YES;
                }
            }
        }
    }
    
    return NO;
}
@end