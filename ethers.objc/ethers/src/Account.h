/**
 *  MIT License
 *
 *  Copyright (c) 2017 Richard Moore <me@ricmoo.com>
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included
 *  in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

/**
 *   Account
 *
 *   An Ethereum account encapsulates a private key which can be used for signing
 *   transactions and from which the address can be computed from the derived
 *   public key.
 */


#import <Foundation/Foundation.h>

#import "Address.h"
#import "Signature.h"
#import "Transaction.h"
#import "SecureData.h"

#pragma mark - Errors

#define kAccountErrorJSONInvalid                             -1
#define kAccountErrorJSONUnsupportedVersion                  -2
#define kAccountErrorJSONUnsupportedKeyDerivationFunction    -3
#define kAccountErrorJSONUnsupportedCipher                   -4
#define kAccountErrorJSONInvalidParameter                    -5

#define kAccountErrorMnemonicMismatch                        -6

#define kAccountErrorWrongPassword                           -10


#define kAccountErrorCancelled                               -20

#define kAccountErrorUnknownError                            -50


#pragma mark -
#pragma mark - Cancellable

@interface Cancellable : NSObject

- (void)cancel;

@end


#pragma mark -
#pragma mark - Account

@interface Account : NSObject

+ (instancetype)accountWithPrivateKey: (NSData*)privateKey;
// 扩展这个方法 通过传不同的slot达到地址不同的目的
+ (instancetype)accountWithMnemonicPhrase: (NSString*)phrase
                                                                            slot:(int)slot;
+ (instancetype)accountWithMnemonicData: (NSData*)data
                                                                            slot:(int)slot;

+ (instancetype)randomMnemonicAccount;
    
    // 用助记词获取私钥
- (instancetype)getPrivateKeyWithMnemonicPhrase: (NSString*)mnemonicPhrase
                                                                                    Andslot:(int)slot;
// 用私钥获取公钥
+ (instancetype)getPublicKeyWithPrivateKey: (NSData *)privateKey;

+ (Cancellable*)decryptSecretStorageJSON: (NSString*)json
                                password: (NSString*)password
                                callback: (void (^)(Account *account, NSError *NSError))callback;

- (Cancellable*)encryptSecretStorageJSON: (NSString*)password
                                callback: (void (^)(NSString *json))callback;

//+ (BOOL)isCrowdsaleJSON: (NSString*)json;
//+ (instancetype)decryptCrowdsaleJSON: (NSString*)json password: (NSString*)password;


@property (nonatomic, readonly) Address *address;

@property (nonatomic, readonly) NSData *privateKey;

@property (nonatomic, readonly) NSString *mnemonicPhrase;
@property (nonatomic, readonly) NSData *mnemonicData;


- (Signature*)signDigest: (NSData*)digestData;
- (void)sign: (Transaction*)transaction;

- (Signature*)signMessage: (NSData*)message;
+ (Address*)verifyMessage: (NSData*)message signature: (Signature*)signature;

+ (Signature*)signatureWithMessage: (NSData*)message r: (NSData*)r s: (NSData*)s address: (Address*)address;

+ (BOOL)isValidMnemonicPhrase: (NSString*)phrase;
+ (BOOL)isValidMnemonicWord: (NSString*)word;

//privateKey 是委员会的私钥 mainAccountPriKey是主账户的私钥 hash(aB)
+ (instancetype)getChildKeyWithPrivateKey: (NSDate *)privateKey AndOtherPriKey: (NSData *)mainAccountPriKey;


//// cp2 = cp1 + cp2
//void point_add(const ecdsa_curve *curve, const curve_point *cp1, curve_point *cp2)

// + S 传进来两个公钥 做加法
+ (NSData *)pointAddWith: (NSData *)sourcePoint AndDesPoint: (NSData *)desPoint;

// + s 传进来两个私钥 s
+ (NSData *)privateKeyAddWith: (NSData *)priA AndPrivateKey: (NSData *)priB;

// 这个方法是传进来一个x恢复ys并返回整个公钥的函数
+(instancetype)getUncompressedPubKeyWithX: (NSData *)x;


+ (instancetype)pointFromPublic: (NSData *)sourcePublicKey mainAccountPrivateKey: (NSData *)mainAccountPrivateKey;

@end
