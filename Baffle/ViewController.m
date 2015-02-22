//
//  ViewController.m
//  Baffle
//
//  Created by Juan Carlos Moreno on 2/11/15.
//  Copyright (c) 2015 Juan C Moreno. All rights reserved.
//

/*
 Trying to emulate these commands
 

 openssl req -x509 -out public_key.der -outform der -new -newkey rsa:1024 -keyout private_key.pem -days 365
 

 
 openssl pkcs12 -export -inkey private_key.pem -out private_key.p12
 
 
--- Encrypt decrypt

openssl smime -encrypt -binary -aes256 -in plain.txt -outform DER -out plain.txt.enc  ../Baffle/keys/publiccert.pem
openssl smime -decrypt -binary -in Passport.jpeg.enc -inform DER -out PassportDec.jpeg -inkey ../Baffle/keys/privkey.pem

 */

#import "ViewController.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    [[self dragview] setReferenceView:[self previewImage]];

    
    NSString *inputString = @"Hello World";
    
    NSData *encoded = [self encodeSMIMEString: inputString];
    NSString *decoded = [self stringDecodeSMIMEData: encoded];
    assert([inputString isEqualToString:decoded]);
    NSLog(@"SMime Passed");
    
    NSData *pkEncoded = [self publicKeyEncodeString:inputString];
    NSString *pkDecoded = [self stringPrivateKeyDecryptData:pkEncoded];
    assert([inputString isEqualToString:pkDecoded]);
    NSLog(@"pk Passed");
    
 /*
    NSString *inputImage = @"IMAGE TO ENCRYPT";
    NSData *toEncodeImage = [NSData dataWithContentsOfFile:inputImage];
    
    NSString *outputImage = @"IMAGE ENCRYPTED";

    NSData *encodedImage = [self encodeSMIMEData: toEncodeImage];
    [encodedImage writeToFile:outputImage atomically:NO];
    
    
    //NSData *encodedImage = [NSData dataWithContentsOfFile:outputImage];
     
  
    NSData *decodedImage = [self dataDecodeSMIMEData: encodedImage];
    NSImage *image = [[NSImage alloc] initWithData:decodedImage];
    
    [[self previewImage] setImage:image];
    */
    
}

- (void)setRepresentedObject:(id)representedObject {
        [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}



#pragma maek - Decruytption using S/Mime
- (NSString *) stringPrivateKeyDecryptData: (NSData *) toDecrypt
{
    return [[NSString alloc] initWithData:[self dataPrivateKeyDecryptData:toDecrypt] encoding:NSUTF8StringEncoding];
}

- (NSData *) dataPrivateKeyDecryptData: (NSData *) toDecrypt {
    
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* pkpath = [myBundle pathForResource:@"private_key" ofType:@"p12"];

    NSData *myCertData  = [NSData dataWithContentsOfFile:pkpath];
    
    SecKeyRef myKey = NULL;
    SecIdentityRef myIdentity;
    SecTrustRef myTrust;
    
    OSStatus status = extractIdentityAndTrust((__bridge CFDataRef)myCertData, &myIdentity, &myTrust);
    
    status = SecIdentityCopyPrivateKey ( myIdentity, &myKey );
    
    if ( status != 0 )
    {
        NSLog( @"Key reteival failed %d", status );
        return nil;
    }
    
    size_t cipherLen = SecKeyGetBlockSize(myKey);
    void *cipher = malloc(cipherLen);
    
    status = SecKeyDecrypt(myKey, kSecPaddingPKCS1, [toDecrypt bytes], [toDecrypt length], cipher, &cipherLen);
    
    if ( status != 0 )
    {
        NSLog( @"SecKeyDecrypt failed %d", status );
        free(cipher);
        return nil;
    }

    NSData *decodedOut = [NSData dataWithBytes:cipher length:cipherLen];
    free(cipher);
    return decodedOut;
}

-(NSData *) publicKeyEncodeString: (NSString *) toEncrypt
{
    NSData *data = [toEncrypt dataUsingEncoding:NSUTF8StringEncoding];
    return [self publicKeyEncodeData:data];
}


-(NSData *) publicKeyEncodeData: (NSData *) data
{
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* certPath = [myBundle pathForResource:@"certificate" ofType:@"cer"];
    NSData *myCertData = [NSData dataWithContentsOfFile: certPath];
    
    SecCertificateRef certificate = SecCertificateCreateWithData(kCFAllocatorDefault, ( __bridge CFDataRef)myCertData);
    if (certificate == nil) {
        NSLog(@"Can not read certificate from certificate.cer");
        return nil;
    }

    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust;
    OSStatus returnCode = SecTrustCreateWithCertificates(certificate, policy, &trust);
    if (returnCode != 0) {
        NSLog(@"SecTrustCreateWithCertificates fail. Error Code: %d", (int)returnCode);
        return nil;
    }
    
    SecTrustResultType trustResultType;
    returnCode = SecTrustEvaluate(trust, &trustResultType);
    if (returnCode != 0) {
        return nil;
    }
    
    SecKeyRef myKey = nil;
    OSStatus status = SecCertificateCopyPublicKey(certificate, &myKey);
    if ( status != 0 )
    {
        NSLog( @"SecCertCopyPubKey failed %d", status );
        return nil;
    }
    
    size_t cipherLen = SecKeyGetBlockSize(myKey);
    void *cipher = malloc(cipherLen);
    
    status = SecKeyEncrypt(myKey, kSecPaddingPKCS1, [data bytes], [data length], cipher, &cipherLen);
    
    if ( status != 0 )
    {
        NSLog( @"SecKeyEncrypt failed %d", status );
        free(cipher);
        return nil;
    }

    NSData *encryptedData = [NSData dataWithBytes:cipher length:cipherLen];
    free(cipher);
    return encryptedData;
}

#pragma mark - SMime Encryption

-(NSString *) stringDecodeSMIMEData: (NSData *) encoded
{
    return [[NSString alloc] initWithData:[self dataDecodeSMIMEData:encoded] encoding:NSUTF8StringEncoding];
}

-(NSData *) dataDecodeSMIMEData: (NSData *) encoded
{
    CMSDecoderRef cmsDecoderOut = NULL;
    OSStatus status = CMSDecoderCreate(&cmsDecoderOut);
    if (status != 0 )
    {
        NSLog(@"Error creating decoder %d", status);
        return nil;
    }

    CFDataRef decodedContentOutCF = NULL;
    status = CMSDecoderUpdateMessage(cmsDecoderOut, [encoded bytes], [encoded length]);
    if (status != 0 )
    {
        NSLog(@"Error Decoding %d", status);
        // Second try Compress, turn below into a function
        /*
        NSData *myCertData  = [NSData dataWithContentsOfFile:@"/Users/jcarlos/Desktop/Baffle/Baffle/keys/private_key.p12"];
        SecKeyRef myKey = NULL;
        SecIdentityRef myIdentity;
        SecTrustRef myTrust;
        
        OSStatus status = extractIdentityAndTrust((__bridge CFDataRef)myCertData, &myIdentity, &myTrust);
        
        status = SecIdentityCopyPrivateKey ( myIdentity, &myKey );
        
        if ( status != 0 )
        {
            NSLog( @"Key reteival failed %d", status );
            return nil;
        }
        // End second try
        status = CMSDecoderUpdateMessage(cmsDecoderOut, [encoded bytes], [encoded length]);
         */
        
        if (status != 0 )
        {
            NSLog(@"Fatal");
           return nil;
        }
    }

    status = CMSDecoderFinalizeMessage (cmsDecoderOut);
    if (status != 0 )
    {
        NSLog(@"Error Finalizing message %d", status);
        return nil;
    }

    status = CMSDecoderCopyContent(cmsDecoderOut, &decodedContentOutCF);
    if (status != 0 )
    {
        NSLog(@"Error copying content %d", status);
        return nil;
    }
    
    NSData *decodedOut = (__bridge NSData *)(decodedContentOutCF);
    
    return decodedOut;
}

-(NSData *) encodeSMIMEString: (NSString *) f
{
    return [self encodeSMIMEData:[f dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSData *) encodeSMIMEData: (NSData *) data
{
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* pkpath = [myBundle pathForResource:@"private_key" ofType:@"p12"];
    NSString* cert = [myBundle pathForResource:@"certificate" ofType:@"cer"];
    NSData *inP12data  = [NSData dataWithContentsOfFile: pkpath];
    
    SecCertificateRef certificateCA = nil;
    NSData *caData = [[NSData alloc] initWithContentsOfFile:cert];
    CFDataRef inPEMData = (__bridge CFDataRef)caData;
    certificateCA = SecCertificateCreateWithData(nil, inPEMData);
    
    SecIdentityRef myIdentity;
    SecTrustRef myTrust;

    OSStatus status = extractIdentityAndTrust((__bridge CFDataRef)inP12data, &myIdentity, &myTrust);
    
    CFDataRef encodedContentOutCF = NULL;

    status = CMSEncodeContent ( myIdentity, certificateCA, CFSTR("1.2.840.113549.1.7.1"), FALSE, 0, [data bytes], [data length], &encodedContentOutCF );

    if (status != 0 )
    {
        NSLog(@"Error Encoding Data %d", status);
        return nil;
    }
    
    NSData *encodedOut = (__bridge NSData *)(encodedContentOutCF);
    
    return encodedOut;

}

#pragma mark - Utilities

OSStatus extractIdentityAndTrust(CFDataRef inP12data, SecIdentityRef *identity, SecTrustRef *trust)
{
    OSStatus securityError = errSecSuccess;
    
    CFStringRef password = CFSTR("testing");
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inP12data, options, &items);
    
    if (securityError == 0) {
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemTrust);
        *trust = (SecTrustRef)tempTrust;
    }
    
    if (options) {
        CFRelease(options);
    }
    
    return securityError;
}


@end
