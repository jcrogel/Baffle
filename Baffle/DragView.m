//
//  DragView.m
//  Baffle
//
//  Created by Juan Carlos Moreno on 2/11/15.
//  Copyright (c) 2015 Juan C Moreno. All rights reserved.
//





#import <Foundation/Foundation.h>
#import "DragView.h"
#import <CommonCrypto/CommonDigest.h>

@implementation DragView

-(instancetype) initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder: coder];
    if (self) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // set any NSColor for filling, say white:
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{

    return NSDragOperationGeneric;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        if ([files count])
        {
            if([[[files firstObject] pathExtension] isEqualToString:@"enc"])
            {
                //NSImage *img = [self decryptFile: [files firstObject]];
                
            }
            else
            {
            }
        }
    }
    return YES;
}

#pragma mark Decryption using OpenSSL
- (NSImage *) decryptFile:(NSString *)filePath {
    //FILE *pubkey = fopen([path cStringUsingEncoding:1], "r");
    //CMS_ContentInfo *SMIME_read_CMS(BIO *in, BIO **bcont);
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSData *myCertData = [NSData dataWithContentsOfFile: @"/Users/jcarlos/Desktop/Baffle/Baffle/keys/publiccert.pem"];
    
    SecCertificateRef myCert;
    myCert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)myCertData);
    NSDictionary *params = @{(id)kSecAttrKeyType:(id)kSecAttrKeyTypeAES};
    CFErrorRef *error;
    SecKeyRef myKey = SecKeyCreateFromData((__bridge CFDictionaryRef) params, (__bridge CFDataRef)data, error);
   
    
    size_t plainBufferSize = SecKeyGetBlockSize(myKey);
    uint8_t *plainBuffer = malloc(plainBufferSize);
    //NSData *incomingData = [NSData dataFromBase64String:cipherString];
    uint8_t *cipherBuffer = (uint8_t*)[data bytes];
    size_t cipherBufferSize = SecKeyGetBlockSize(myKey);
    SecKeyDecrypt(myKey,
                  kSecPaddingOAEPKey,
                  cipherBuffer,
                  cipherBufferSize,
                  plainBuffer,
                  &plainBufferSize);
    NSData *decryptedData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];

    NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    NSLog(@"Dec %@", decryptedString);
    //return decryptedString;
 
    
    NSImage *img;// = [[NSImage alloc] initWithData:data];
    
    
//    return data;
    return img;
}

- (void)decryptWithPrivateKey: (NSData *)dataToDecrypt
{
    OSStatus status = noErr;
    
    size_t cipherBufferSize = [dataToDecrypt length];
    uint8_t *cipherBuffer = (uint8_t *)[dataToDecrypt bytes];
    
    size_t plainBufferSize;
    uint8_t *plainBuffer;
    
    SecKeyRef privateKey = NULL;
    
    NSData * privateTag;// = [NSData dataWithBytes:privateKeyIdentifier
                        //                 length:strlen((const char *)privateKeyIdentifier)];
    
    NSMutableDictionary *queryPrivateKey = [[NSMutableDictionary alloc] init];
    
    // Set the private key query dictionary.
    [queryPrivateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPrivateKey setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPrivateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    // 1
    
    status = SecItemCopyMatching
    ((__bridge CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKey); // 2
    
    //  Allocate the buffer
    plainBufferSize = SecKeyGetBlockSize(privateKey);
    plainBuffer = malloc(plainBufferSize);
    
    if (plainBufferSize < cipherBufferSize) {
        // Ordinarily, you would split the data up into blocks
        // equal to plainBufferSize, with the last block being
        // shorter. For simplicity, this example assumes that
        // the data is short enough to fit.
        printf("Could not decrypt.  Packet too large.\n");
        return;
    }
    
    //  Error handling
    
    status = SecKeyDecrypt(    privateKey,
                           kSecPaddingPKCS1,
                           cipherBuffer,
                           cipherBufferSize,
                           plainBuffer,
                           &plainBufferSize
                           );                              // 3
    
    //  Error handling
    //  Store or display the decrypted text
    
    if(privateKey) CFRelease(privateKey);
}



@end