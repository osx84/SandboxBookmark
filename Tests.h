//
//  Tests.h
//  DeallocTest
//
//  Created by alexey on 19.01.13.
//  Copyright (c) 2013 alexey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tests : NSObject

- (BOOL) appendLocalFolderBookrmark;
- (BOOL) isFolderHaveImages : (NSString*) folder;
- (BOOL) performDragOperation : (id<NSDraggingInfo>) sender;

@end
