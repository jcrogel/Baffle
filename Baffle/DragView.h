//
//  DragView.h/Users/jcarlos/Desktop/Baffle/Baffle/Baffle/ViewController.h
//  Baffle
//
//  Created by Juan Carlos Moreno on 2/11/15.
//  Copyright (c) 2015 Juan C Moreno. All rights reserved.
//

#ifndef Baffle_DragView_h
#define Baffle_DragView_h
#import <Cocoa/Cocoa.h>
#include <openssl/bio.h>

@interface DragView : NSView<NSDraggingDestination>

@property NSImageView *referenceView;

@end

#endif
