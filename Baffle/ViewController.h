//
//  ViewController.h
//  Baffle
//
//  Created by Juan Carlos Moreno on 2/11/15.
//  Copyright (c) 2015 Juan C Moreno. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <resolv.h>
#import <Security/Security.h>
#import <openssl/ssl.h>
#import "DragView.h"


@interface ViewController : NSViewController

@property (weak) IBOutlet DragView *dragview;
@property (weak) IBOutlet NSImageView *previewImage;


@end

