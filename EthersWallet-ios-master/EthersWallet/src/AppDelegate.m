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

#import "AppDelegate.h"
//#import "SecureData.h"
@import NotificationCenter;



#import "AccountsViewController.h"
#import "ApplicationViewController.h"
#import "CloudView.h"
#import "ConfigNavigationController.h"
#import "GasPriceKeyboardView.h"
#import "ModalViewController.h"
#import "OptionsConfigController.h"
#import "PanelViewController.h"
#import "ScannerConfigController.h"
#import "SearchTitleView.h"
#import "SharedDefaults.h"
#import "SignedRemoteDictionary.h"
#import "UIColor+hex.h"
#import "Utilities.h"
#import "Wallet.h"
#import "WalletViewController.h"


#import "CloudKeychainSigner.h"




// The Canary is a signed payload living on the ethers.io web server, which allows the
// authors to notify users of critical issues with either the app or the Ethereum network
// The scripts/tools directory contains the code that generates a signed payload.
static NSString *CanaryAddress              = @"0x70C14080922f091fD7d0E891eB483C9f8464a527";
static NSString *CanaryUrl                  = @"https://ethers.io/canary.raw";

// Test URL - This URL triggers the canaray for testing purposes
//static NSString *CanaryUrl                  = @"https://ethers.io/canary-test.raw";


// The list of current applications come from a signed dictionary on the ethers.io web
// server. This will change in the future, but is used currently incase a problem
// occurs with the burned-in apps
static NSString *ApplicationsDataAddress    = @"0xbe1bB78F53f4FD218fb46FA0a565A1eC6a65666e";
static NSString *ApplicationsDataUrl        = @"https://ethers.io/applications-v2.raw";


static NSString *CanaryVersion = nil;

static NSDictionary *DefaultApplications = nil;

@interface AppDelegate () <AccountsViewControllerDelegate, PanelViewControllerDataSource, SearchTitleViewDelegate> {
    NSMutableArray<NSString*> *_applicationTitles;
    NSMutableArray<NSString*> *_applicationUrls;
    
    NSMutableArray<NSString*> *_customApplicationsTitles;
    NSMutableArray<NSString*> *_customApplicationsUrls;
}

@property (nonatomic, readonly) PanelViewController *panelViewController;
@property (nonatomic, readonly) WalletViewController *walletViewController;

@property (nonatomic, readonly) Wallet *wallet;

@end


@implementation AppDelegate {
    UIBarButtonItem *_addAccountsBarButton, *_addApplicationBarButton;
    SearchTitleView *_searchTitleView;
}

#pragma mark - Life-Cycle

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        CanaryVersion = [NSString stringWithFormat:@"%@/%@", [info objectForKey:@"CFBundleIdentifier"],
                         [info objectForKey:@"CFBundleShortVersionString"]];
        
        NSLog(@"Canary Version: %@", CanaryVersion);
        
        DefaultApplications = @{
                                @"titles": @[
                                        @"Welcome", @"CryptoKitties", @"Block Explorer",
                                        ],
                                @"urls": @[
                                        @"https://0x017355b3c9ad3345fc64555676f6c538c0f0454d.ethers.space/",
                                        @"https://www.cryptokitties.co/",
                                        @"https://c3fbbba629d27a348a2f3ccd3e8bdcdca9b1019e.ethers.space/",
                                        ],
                                @"testnetTitles": @[
                                        @"Welcome", @"Testnet Faucet", @"Block Explorer", @"Test Token"
                                        ],
                                @"testnetUrls": @[
                                        @"https://0x017355b3c9ad3345fc64555676f6c538c0f0454d.ethers.space/",
                                        @"https://0xa5681b1fbda76e0d4ab646e13460a94fdcd3c1c1.ethers.space/",
                                        @"https://0xc3fbbba629d27a348a2f3ccd3e8bdcdca9b1019e.ethers.space/",
                                        @"https://0x84db171b84950185431e76d6cd2aa5ce1cf853cf.ethers.space"
                                        ],
                                };

    });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
//    Account *communityAccount = [Account accountWithMnemonicPhrase:@"swarm friend game tip welcome junior arch beef runway toilet install churn" slot:0];
//    [communityAccount encryptSecretStorageJSON:@"qwe" callback:^(NSString *json) {
//        NSLog(@"%@", json);
//    }];
//
//    // 这块用委员会的account试试发送交易 1,000,000,000
//    [AppDelegate account:communityAccount sendTransactionWithGaslimit:@"90000" GasPrice:@"71000000000" AndValue:@"1" ToAddress:@"0x13E37747648E2eCdf7B65F7718dDeA7D51C60436" finished:^(id result, NSError *error) {
//        NSLog(@"%@", result);
//    }];
    
    // Schedule us for background fetching
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    _customApplicationsTitles = [NSMutableArray array];
    _customApplicationsUrls = [NSMutableArray array];

    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    _wallet = [Wallet walletWithKeychainKey:@"io.ethers.sharedWallet"];
    _walletViewController = [[WalletViewController alloc] initWithWallet:_wallet];
    
    _searchTitleView = [[SearchTitleView alloc] init];
    _searchTitleView.delegate = self;
    
    _panelViewController = [[PanelViewController alloc] initWithNibName:nil bundle:nil];
    _panelViewController.dataSource = self;
    _panelViewController.navigationItem.titleView = _searchTitleView;
    _panelViewController.titleColor = [UIColor colorWithWhite:1.0f alpha:1.0f];

    // The Accounts button on the top-right
    {
        UIButton *button = [Utilities ethersButton:ICON_NAME_ACCOUNTS fontSize:33.0f color:0xffffff];
        [button addTarget:self action:@selector(tapAccounts) forControlEvents:UIControlEventTouchUpInside];
        _addAccountsBarButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    _panelViewController.navigationItem.leftBarButtonItem = _addAccountsBarButton;
    
    _addApplicationBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:self
                                                                             action:@selector(tapAddApplication)];
    
    // @TODO: We aren't ready for any app yet
    //_panelViewController.navigationItem.rightBarButtonItem = _addApplicationBarButton;

    {
        CloudView *cloudView = [[CloudView alloc] initWithFrame:_panelViewController.view.bounds];
        cloudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_panelViewController.backgroundView addSubview:cloudView];
    }
    
    UINavigationController *rootController = [[UINavigationController alloc] initWithRootViewController:_panelViewController];
    UIColor *navigationBarColor = [UIColor colorWithHex:ColorHexNavigationBar];
    [Utilities setupNavigationBar:rootController.navigationBar backgroundColor:navigationBarColor];

    [_panelViewController focusPanel:YES animated:NO];

    _window.rootViewController = rootController;
    
    [_window makeKeyAndVisible];
    
    // If the active account changed, we need to update the applications (e.g. testnet faucet for testnet accounts only)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyActiveAccountDidChange:)
                                                 name:WalletActiveAccountDidChangeNotification
                                               object:_wallet];
    
    // If an account was added, we may now have a different primary account
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyExtensions)
                                                 name:WalletAccountAddedNotification
                                               object:_wallet];

    // If an account was removed, we may now have a different primary account
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyExtensions)
                                                 name:WalletAccountRemovedNotification
                                               object:_wallet];

    // If an account was re-ordered, we may now have a different primary account
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyExtensions)
                                                 name:WalletAccountsReorderedNotification
                                               object:_wallet];

    // If the balance of the primary account changed, we need to update the widet
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyExtensions)
                                                 name:WalletAccountBalanceDidChangeNotification
                                               object:_wallet];

    NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
    if (url) {
        [self application:application openURL:url options:@{}];
    }
    
    [self notifyExtensions];
    
    [self setupApplications];
    
    [self checkCanary];
    
    //测试一下keystore好不好使
    
    // 新建一个账号 slot = 5
   // Account *testAccount = [Account randomMnemonicAccount];
    // 导出它的keystore
    
    // 再导入他的keysotre 看是否好使
    
//    // 这是随机生成的账户
//    Account *randomAccount = [Account randomMnemonicAccount];
//    // 随机账户私钥 s
//       // [randomAccount getPrivateKeyWithMnemonicPhrase:randomMainAccount.mnemonicPhrase Andslot:0];
//    SecureData *randomAccountPriKey = [randomAccount getPrivateKeyWithMnemonicPhrase:randomMainAccount.mnemonicPhrase Andslot:0];
//    // 随机账户公钥 S
//    [Account getPublicKeyWithPrivateKey:randomAccountPriKey.data];

    
    // 这是委员会
//     swarm friend game tip welcome junior arch beef runway toilet install churn
    Account *communityAccount = [Account accountWithMnemonicPhrase:@"swarm friend game tip welcome junior arch beef runway toilet install churn" slot:0];
//
//
//    // 这块用委员会的account试试发送交易
//    [AppDelegate account:communityAccount sendTransactionWithGaslimit:@"90000" GasPrice:@"1000000" AndValue:@"1" ToAddress:@"0x13E37747648E2eCdf7B65F7718dDeA7D51C60436" finished:^(id result, NSError *error) {
//        NSLog(@"%@", result);
//    }];
    
    // 委员会 私钥 b
    SecureData *communityPriKey = [communityAccount getPrivateKeyWithMnemonicPhrase:communityAccount.mnemonicPhrase Andslot:0];
    // 委员会 公钥 B
    [Account getPublicKeyWithPrivateKey:communityPriKey.data];
    
    
    // 这是主账户
    Account *randomMainAccount = [Account randomMnemonicAccount];
    // 主账户私钥 a
    // [randomMainAccount getPrivateKeyWithMnemonicPhrase:randomMainAccount.mnemonicPhrase Andslot:0];
    SecureData *mainAccountPriKey = [randomMainAccount getPrivateKeyWithMnemonicPhrase:randomMainAccount.mnemonicPhrase Andslot:0];
    // 主账户公钥 A
    [Account getPublicKeyWithPrivateKey:mainAccountPriKey.data];
    
    //privateKey 是委员会的私钥 mainAccountPriKey是主账户的私钥 hash(aB)
    SecureData *tempChildPriKey = [Account getChildKeyWithPrivateKey:communityPriKey.data AndOtherPriKey:mainAccountPriKey.data];
    
    // hash(aB)G
    [Account getPublicKeyWithPrivateKey:tempChildPriKey.data];
    NSLog(@"%@",  [Account getPublicKeyWithPrivateKey:tempChildPriKey.data]);
    
    
    // 到随机账号出场的时候了
    Account *randomAccount = [Account randomMnemonicAccount];
    // 随机账户私钥 s
    // [randomMainAccount getPrivateKeyWithMnemonicPhrase:randomMainAccount.mnemonicPhrase Andslot:0];
    SecureData *randomAccountPriKey = [randomAccount getPrivateKeyWithMnemonicPhrase:randomAccount.mnemonicPhrase Andslot:0];
    // 随机账户公钥 S
    [Account getPublicKeyWithPrivateKey:randomAccountPriKey.data];
    
    // 最后一步加法
    [Account pointAddWith:[Account getPublicKeyWithPrivateKey:tempChildPriKey.data] AndDesPoint:[Account getPublicKeyWithPrivateKey:randomAccountPriKey.data]];
    
    NSString *priStr = @"b8ea3e70d5123d3d6a894f39f68589e675ee8db4e78df6857a91cea4ab9d82ee";
    NSData *tempPriData = [priStr dataUsingEncoding:NSUTF8StringEncoding];
    SecureData *tempPrivateKey = [SecureData secureDataWithData:tempPriData];
    [Account getPublicKeyWithPrivateKey:tempPrivateKey.data];
    // 这个是私钥相加的算法
//    + (NSData *)privateKeyAddWith: (NSData *)priA AndPrivateKey: (NSData *)priB;
    // 这个私钥加法现在会崩溃
//    [Account privateKeyAddWith:tempChildPriKey.data AndPrivateKey:randomAccountPriKey.data];
//    [SecureData dataToHexString:[Account privateKeyAddWith:tempChildPriKey.data AndPrivateKey:randomAccountPriKey.data]];
    
    
//    NSString *xStr = @"0x03ff14d753a2e65cad5f4bf60ecb9c97c698d08becb94cc972ae2210cb73294e16";
//    NSData *xData = [xStr dataUsingEncoding:NSUTF8StringEncoding];

    SecureData *xSecureData = [SecureData secureDataWithHexString:@"0x03ff14d753a2e65cad5f4bf60ecb9c97c698d08becb94cc972ae2210cb73294e16"];
    SecureData *unCompressPubKeyData = [Account getUncompressedPubKeyWithX:xSecureData];
    SecureData *unCompressSecureData = [SecureData secureDataWithData:unCompressPubKeyData];
    NSLog(@"%@", unCompressSecureData);
    //-------------------------------------------------------------------------------------//

    
    
    
    
    
    
    
    
    
    
    
    
    

    
//        NSString *keystoreStr = @"{\"address\":\"99bd6e16f7e9418a0263d17274239422d9c27142\",\"id\":\"234abd95-e075-4902-9b6c-dd8d1733d2c3\",\"version\":3,\"crypto\":{\"cipher\":\"aes-128-ctr\",\"cipherparams\":{\"iv\":\"188955a8878b565e24aa15915e1af4aa\"},\"ciphertext\":\"43356913c31d955f34ec2caca8f4bc08d0e81a21104e98f27fec9a138ce67c2d\",\"kdf\":\"scrypt\",\"kdfparams\":{\"dklen\":32,\"n\":1024,\"p\":1,\"r\":8,\"salt\":\"e5e2a2fb95ae61fe64cb04e2e22b609fcb11a228f6004fd83d6dd5c891ee98f0\"},\"mac\":\"20bc15d3a8a41273cfb425223dd70703143486a787f410fa38faa0f06a26d0f1\"}}";
//
//    [Account decryptSecretStorageJSON:keystoreStr password:@"1234" callback:^(Account *account, NSError *NSError) {
//        // decryptSecretStorageJSON 方法中的slot现在是0 看是什么结果 似乎没有影响
//        NSLog(@"%@", account.address);
//        NSLog(@"%@", account.privateKey);
//        // 把privatekey传进去 先看恢复的地址对不对
//        [Account getPublicKeyWithPrivateKey:account.privateKey];
//        NSLog(@"%@", account.mnemonicPhrase);
//
//    }];
    
    
    SecureData *publicKey = [Account getPublicKeyWithPrivateKey:tempChildPriKey.data];
    NSString *tempStr = @"ciperText";
    NSData *tempData = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
//
//    NSString *domain = @"com.MyCompany.MyApplication.ErrorDomain";
//    NSString *desc = NSLocalizedString(@"Unable to…", @"");
//    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
//
//    NSError *error = [NSError errorWithDomain:domain
//                                         code:-101
//                                     userInfo:userInfo];
//    [CloudKeychainSigner useSecureEnclaveKeyData:tempData encrypt:YES publicKey: publicKey.data error:nil];
    CloudKeychainSigner *tempSigner = [CloudKeychainSigner new];

    

   // [tempSigner classUseSecureEnclaveKeyData:tempData encrypt:YES error:nil];
    [tempSigner classUseSecureEnclaveKeyData:tempData PublicKey:publicKey.data encrypt:YES error:nil];
//    NSData *cipherTest =  [tempSigner objectUseSecureEnclaveKeyData:tempData encrypt:false publicKey:publicKey.data error:nil];
//    NSData *cipherTest = [tempSigner objectUseSecureEnclaveKeyData:tempData encrypt:YES publicKey:publicKey.data privateKey:tempChildPriKey.data error:nil];
//    NSData *cipherTest = [tempSigner secondObjectUseSecureEnclaveKeyData:tempData encrypt:YES publicKey:publicKey.data privateKey:tempChildPriKey.data error:nil];
//    NSData *cipherTest = [tempSigner objectUseSecureEnclaveKeyData:tempData encrypt:NO publicKey:nil privateKey:randomAccountPriKey.data error:nil];
    
    
    
    
    
  //   CFErrorRef error = NULL;
//        SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
//                                                                        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
//                                                                        kSecAccessControlTouchIDAny | kSecAccessControlPrivateKeyUsage, &error);
//    if (sacObject == NULL || error != NULL) {
//        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
//    }
    
//    NSDictionary *parameters = @{
//                                 (id)kSecAttrTokenID: (id)kSecAttrTokenIDSecureEnclave,
//                                 (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
//                                 (id)kSecAttrKeySizeInBits: @256,
//                                 (id)kSecAttrLabel: @"my-se-key",
//                                 (id)kSecPrivateKeyAttrs: @{
//                                         (id)kSecAttrAccessControl: (__bridge_transfer id)sacObject,
//                                         (id)kSecAttrIsPermanent: @YES,
//                                         }};
    // 官方文档说 这两个是必须的(kSecAttrKeyType,kSecAttrKeySizeInBits) 其他可选
    // 加kSecAttrTokenIDSecureEnclave 就出问题 表示使用SecureEnclave来保存密钥
    // 可能因为是模拟器的缘故 因为模拟器没有touchids所以加了这个参数 就无法生成私钥了
    // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/key_generation_attributes
//    NSDictionary *parameters = @{
//                                 (__bridge id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
//                                 (__bridge id)kSecAttrKeySizeInBits: @256,
//                                 (__bridge id)kSecAttrLabel: @"my-se-key",
//                                 (__bridge id)kSecPrivateKeyAttrs: @{
//                                          (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject,
//                                          (__bridge id)kSecAttrIsPermanent: @YES,
//                                          }
//                                 };
//    NSError *gen_error = nil;
//    id privateKey = CFBridgingRelease(SecKeyCreateRandomKey((__bridge CFDictionaryRef)parameters, (void *)&gen_error));
//    NSLog(@"%@", privateKey);

    
    // 我的公钥
    //0x04343c17dc976cd8b076011d0bdf3d4a4a1ad2d8ff63d8f160f88c2028157803bb68056fae2ffb070ea6a45a3704b135140309f80ba2a579213ccf04fccbbdb5e4
    // 我的私钥
    // 0xca6bdd4207050afce8f5ea6082443feeac4e488df963f9f6dff861d388d41ba4
    
    // 他的公钥
    // 0x04a7a94b0e85d484fde7698a4dce92e529afd21c3b6bc5408e260cb0158c865f573cf3675d70021eb4d10b91af739201d27758cd5609fe01f7d121c47fc53f445b
    // 他的私钥
   // 0x3fbcd815b836d647e4a8d8f747f92583aea1f01fd48fbe4825520779edaac8de
    
    //+ (NSData *)pointFromPublic: (NSData *)sourcePublicKey mainAccountPrivateKey: (NSData *)mainAccountPrivateKey
    
    SecureData *testCommunityPublickey = [SecureData secureDataWithHexString:@"0x04ff5b1be6f98ae391da65bb1e453d68b39565ca05f998994b996035879bdd5e920c853ee5930c191a6ca5361b11e450cf7cb49401cb3fc2146bf3de7b9970fc49"];


    // 主账号
    Account *tempAcccount = [Account randomMnemonicAccount];
    NSLog(@"%@", tempAcccount.mnemonicPhrase);
//    Account *mainTestAccount = [Account accountWithMnemonicPhrase:@"trust limit what gown squirrel cat size rebel sand weird embrace hawk" slot:0];
//        Account *mainTestAccount = [Account accountWithMnemonicPhrase:@"exile draw demand use divide labor certain half hold despair night chalk" slot:0];
    //test3
//            Account *mainTestAccount = [Account accountWithMnemonicPhrase:@"find club monitor zoo dove lobster oven olympic page industry party furnace" slot:0];
    // test4
//                Account *mainTestAccount = [Account accountWithMnemonicPhrase:@"prize saddle rhythm casual mistake digital ball fresh sustain peace powder dismiss" slot:0];
    // test5
//                    Account *mainTestAccount = [Account accountWithMnemonicPhrase:@"review disorder marriage scale hollow fabric market twin furnace crawl type cause" slot:0];
    // test6
            Account *mainTestAccount = [Account accountWithMnemonicPhrase:@"protect humble law almost believe six derive sight sugar behave impulse height" slot:0];
//        Account *mainTestAccount = [Account accountWithMnemonicPhrase:@"piece unable thank wave ticket memory also stamp turn impulse school rigid" slot:0];

//    SecureData *communityPriKey = [communityAccount getPrivateKeyWithMnemonicPhrase:communityAccount.mnemonicPhrase Andslot:0];
    // 主账号私钥
    SecureData *mainTestAccountPriKey = [mainTestAccount getPrivateKeyWithMnemonicPhrase:mainTestAccount.mnemonicPhrase Andslot:0];
    // 主账号公钥
    [Account getPublicKeyWithPrivateKey:mainTestAccountPriKey.data];
    // hash(aB)
    //[Account pointFromPublic:testCommunityPublickey.data mainAccountPrivateKey:mainTestAccountPriKey.data]
    // hash(aB)G
//    [Account getPublicKeyWithPrivateKey: [Account pointFromPublic:testCommunityPublickey.data mainAccountPrivateKey:mainTestAccountPriKey.data]];

    SecureData *tempTestChildPubKey = [Account getPublicKeyWithPrivateKey: [Account pointFromPublic:testCommunityPublickey.data mainAccountPrivateKey:mainTestAccountPriKey.data]];
    //[Account getPublicKeyWithPrivateKey:tempTestChildPriKey.data];
   // NSLog(@"%@", [Account getPublicKeyWithPrivateKey:tempTestChildPriKey.data]);
    NSLog(@"%@", tempTestChildPubKey.hexString);
    return YES;
}

+(void)account:(Account *)account sendTransactionWithGaslimit:(NSString *)gaslimit GasPrice:(NSString *)gasPrice AndValue:(NSString *)value ToAddress:(NSString *)address finished:(void (^)(id result, NSError *error))finished {
    NSString *toAddress = address;
//    InfuraProvider *provider = [[InfuraProvider alloc] initWithTestnet:NO accessToken:@"uSjnFOfWwzf9edKibZ0V"];
    InfuraProvider  *provider = [[InfuraProvider alloc] initWithChainId:ChainIdHomestead accessToken:@""];
    Transaction *transaction = [[Transaction alloc] init];
    //nonce处理一下
    NSString *fromAddress = [NSString stringWithFormat:@"%@", account.address];
    
            NSNumber *nonce = [NSNumber numberWithInt:4];
            int intNonce = [nonce intValue];
            transaction.nonce = intNonce;
            transaction.gasLimit = [BigNumber bigNumberWithDecimalString:gaslimit];
            transaction.gasPrice = [BigNumber bigNumberWithDecimalString:gasPrice];
            transaction.toAddress = [Address addressWithString:toAddress];
            transaction.value = [Payment parseEther:value];
            NSNumber *flag = [NSNumber numberWithInt:0];
            int intFlag = [flag intValue];
            transaction.flag = intFlag;
            transaction.chainId = ChainIdMorden;
            [account sign:transaction];
            NSData *signedTransaction = [transaction serialize];
            SecureData *hexTransaction = [SecureData dataToHexString:signedTransaction];

//            [[provider sendTransaction:signedTransaction] onCompletion:^(HashPromise *promise) {
//                if (promise.error) {
//                    finished(nil, promise.error);
//                } else {
//                    finished(promise.result, nil);
//                }
//            }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// iban://0x05ABcF02682E2b3fB6e38840Cd57d2ea77edd41F
// https://ethers.io/app-link/#!debug



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self checkCanary];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    [self notifyExtensions];

}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - SearchTitleViewDelegate

- (void)tapAddApplication {
    [_panelViewController.navigationItem setLeftBarButtonItem:nil animated:YES];
    [_panelViewController.navigationItem setRightBarButtonItem:nil animated:YES];
    [_searchTitleView setWidth:_panelViewController.view.frame.size.width animated:YES];
    [_searchTitleView becomeFirstResponder];
}

- (void)untapAddApplication {
    [_panelViewController.navigationItem setLeftBarButtonItem:_addAccountsBarButton animated:YES];
    [_panelViewController.navigationItem setRightBarButtonItem:_addApplicationBarButton animated:YES];
    [_searchTitleView setWidth:SEARCH_TITLE_HIDDEN_WIDTH animated:YES];
}

- (void)searchTitleViewDidCancel:(SearchTitleView *)searchTitleView {
    [self untapAddApplication];
}

- (BOOL)launchApplication: (NSString*)url {
    NSURL *check = [NSURL URLWithString:url];
    if (check && check.host.length > 0) {
        [_customApplicationsTitles addObject:check.host];
        [_customApplicationsUrls addObject:url];
        
        [self setupApplications];

        [_panelViewController reloadData];
        _panelViewController.viewControllerIndex = 1;
        
        return YES;
    }
    return NO;
}

- (void)searchTitleViewDidConfirm:(SearchTitleView *)searchTitleView {
    BOOL valid = [self launchApplication:searchTitleView.searchText];
    if (valid) {
        [self untapAddApplication];
    }
}

#pragma mark - AccountsViewControllerDelegate

- (void)tapAccounts {
    AccountsViewController *accountsViewController = [[AccountsViewController alloc] initWithWallet:_wallet];
    accountsViewController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:accountsViewController];
    UIColor *navigationBarColor = [UIColor colorWithHex:ColorHexNavigationBar];
    [Utilities setupNavigationBar:navigationController.navigationBar backgroundColor:navigationBarColor];
    [ModalViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)accountsViewControllerDidCancel:(AccountsViewController *)accountsViewController {
    [accountsViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)accountsViewController:(AccountsViewController *)accountsViewController didSelectAccountIndex:(NSInteger)accountIndex {
    _wallet.activeAccountIndex = accountIndex;
}

#pragma mark - Applications

- (void)notifyActiveAccountDidChange: (NSNotification*)note {
    [self setupApplications];
}



+ (SignedRemoteDictionary*)signedApplicationsDictionary {
    
    return [SignedRemoteDictionary dictionaryWithUrl:ApplicationsDataUrl
                                             address:[Address addressWithString:ApplicationsDataAddress]
                                         defaultData:DefaultApplications];
}

+ (NSDictionary*)checkApplications {
    NSDictionary<NSString*, NSArray<NSString*>*> *data = [AppDelegate signedApplicationsDictionary].currentData;
    for (NSString *key in @[@"titles", @"urls", @"testnetTitles", @"testnetUrls"]) {
        if (![[data objectForKey:key] isKindOfClass:[NSArray class]]) {
            NSLog(@"AppDelegate - invalid application array: %@", key);
            return DefaultApplications;
        }
        
        if ([data objectForKey:key].count == 0) {
            NSLog(@"AppDelegate - zero items: %@", key);
            return DefaultApplications;
        }
        
        for (NSString *value in [data objectForKey:key]) {
            if (![value isKindOfClass:[NSString class]]) {
                NSLog(@"AppDelegate - invalid applcation value: %@", value);
                return DefaultApplications;
            }
        }
    }

    if ([data objectForKey:@"titles"].count != [data objectForKey:@"urls"].count) {
        NSLog(@"AppDelegate - titles/urls mismatch");
        return DefaultApplications;
    }
    
    if ([data objectForKey:@"testnetTitles"].count != [data objectForKey:@"testnetUrls"].count) {
        NSLog(@"AppDelegate - testnet titles/urls mismatch");
        return DefaultApplications;
    }

    return data;
}

- (void)setupApplications {
    NSDictionary *data = [AppDelegate checkApplications];
    if (_wallet.activeAccountProvider.chainId == ChainIdRopsten) {
        _applicationTitles = [[data objectForKey:@"testnetTitles"] mutableCopy];
        _applicationUrls = [[data objectForKey:@"testnetUrls"] mutableCopy];
    } else {
        _applicationTitles = [[data objectForKey:@"titles"] mutableCopy];
        _applicationUrls = [[data objectForKey:@"urls"] mutableCopy];
    }
    
    for (NSInteger i = _customApplicationsTitles.count - 1; i >= 0; i--) {
        [_applicationUrls insertObject:[_customApplicationsUrls objectAtIndex:i] atIndex:0];
        [_applicationTitles insertObject:[_customApplicationsTitles objectAtIndex:i] atIndex:0];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TEMP_ALLOW_APPS"]) {
        _panelViewController.navigationItem.rightBarButtonItem = _addApplicationBarButton;
    } else {
        _panelViewController.navigationItem.rightBarButtonItem = nil;
    }

    [_panelViewController reloadData];
}


#pragma mark - Canary

- (BOOL)matchesCanaryVersion: (NSString*)version {
    return [CanaryVersion isEqual:version];
}

- (void)checkCanary {
    
    // Might as well check and possibly update the gas prices
    [GasPriceKeyboardView checkForUpdatedGasPrices];
    
    // Also lets check for updted Application list
    [[[AppDelegate signedApplicationsDictionary] data] onCompletion:^(DictionaryPromise *promise) {
        NSLog(@"Finished checking for applications: %@", promise.value);
    }];
    
    // Check for canary data. This is an emergency broadcast system, in case there is
    // either an Ethers Wallet or Ethereum-wide notification we need to send out
    SignedRemoteDictionary *canary = [SignedRemoteDictionary dictionaryWithUrl:CanaryUrl
                                                                       address:[Address addressWithString:CanaryAddress]
                                                                   defaultData:@{}];
    [canary.data onCompletion:^(DictionaryPromise *promise) {
        
        if (![[promise.value objectForKey:@"version"] isEqual:@"0.2"]) { return; }
        
        NSArray *alerts = [promise.value objectForKey:@"alerts"];
        if (![alerts isKindOfClass:[NSArray class]]) { return; }
        
        for (NSDictionary *alert in alerts) {
            if ([alerts isKindOfClass:[NSDictionary class]]) { continue; }
            
            NSArray *affectedVersions = [alert objectForKey:@"affectedVersions"];
            if (![affectedVersions isKindOfClass:[NSArray class]]) { continue; }
            
            BOOL affected = NO;
            for (NSString *affectedVersion in affectedVersions) {
                if ([self matchesCanaryVersion:affectedVersion]) {
                    affected = YES;
                    continue;
                }
            }
            
            // DEBUG!
            //affected = YES;
            
            if (!affected) { continue; }
            
            NSString *heading = [alert objectForKey:@"heading"];
            if (![heading isKindOfClass:[NSString class]]) { continue; }
            
            NSArray *messages = [alert objectForKey:@"text"];
            if (![messages isKindOfClass:[NSArray class]]) { continue; }
            BOOL validText = YES;
            for (NSString *text in messages) {
                if (![text isKindOfClass:[NSString class]]) {
                    validText = NO;
                    break;
                }
            }
            if (!validText) { continue; }
            
            NSString *button = [alert objectForKey:@"button"];
            if (![button isKindOfClass:[NSString class]]) { continue; }
            
            OptionsConfigController *config = [OptionsConfigController configWithHeading:heading
                                                                              subheading:@""
                                                                                messages:messages
                                                                                 options:@[button]];
            
            config.onLoad = ^(ConfigController *configController) {
                configController.navigationItem.leftBarButtonItem = nil;
            };
            
            config.onOption = ^(OptionsConfigController *configController, NSUInteger index) {
                [(ConfigNavigationController*)configController.navigationController dismissWithNil];
            };
            
            [ModalViewController presentViewController:[ConfigNavigationController configNavigationController:config]
                                              animated:YES
                                            completion:nil];
            break;
        }

    }];
}


#pragma mark - PanelViewControllerDataSource

- (NSUInteger)panelViewControllerPinnedChildCound: (PanelViewController*)panelViewController {
    return 1;
}

- (NSUInteger)panelViewControllerChildCount: (PanelViewController*)panelViewController {
    return 1 + _applicationTitles.count;
}

- (NSString*)panelViewController: (PanelViewController*)panelViewController titleAtIndex: (NSUInteger)index {
    if (index == 0) {
        return @"Wallet";
    }
    
    return [_applicationTitles objectAtIndex:index - 1];
}

- (UIViewController*)panelViewController: (PanelViewController*)panelViewController viewControllerAtIndex: (NSUInteger)index {
    
    if (index == 0) {
        return _walletViewController;
    }
    
    return [[ApplicationViewController alloc] initWithApplicationTitle:[_applicationTitles objectAtIndex:index - 1]
                                                                   url:[NSURL URLWithString:[_applicationUrls objectAtIndex:index - 1]]
                                                                wallet:_wallet];
}


#pragma mark - Scanner

- (void)showScanner {
    [ModalViewController dismissAllCompletionCallback:^() {
        if (_wallet.activeAccountAddress) {
            [_wallet scan:^(Transaction *transaction, NSError *error) {
                NSLog(@"Scan complete: %@ %@", transaction, error);
            }];

        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Accounts"
                                                                           message:@"You must create an account before scanner QR codes."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [ModalViewController presentViewController:alert animated:NO completion:nil];
        }
    }];
}


#pragma mark - External launching

typedef enum ExternalAction {
    ExternalActionNone = 0,
    ExternalActionScan,
    ExternalActionWallet,
    ExternalActionSend,
    ExternalActionConfig,
    ExternalActionFireflyConfig,
} ExternalAction;

- (BOOL)handleAction: (ExternalAction)action payment: (Payment*)payment {
    if (action == ExternalActionNone) { return NO; }
    
    [self.walletViewController scrollToTopAnimated:NO];
    
    if (action == ExternalActionWallet) {
        [self.panelViewController setViewControllerIndex:0 animated:NO];
        [self.panelViewController focusPanel:YES animated:NO];
    }
    
    __weak AppDelegate *weakSelf = self;
    [ModalViewController dismissAllCompletionCallback:^() {
        if (action == ExternalActionScan) {
            [weakSelf showScanner];
        
        } else if (action == ExternalActionSend) {
            [weakSelf.wallet sendPayment:payment callback:^(Transaction *transaction, NSError *error) {
                NSLog(@"AppDelegate: Sent transaction=%@ error=%@", transaction, error);
            }];
        
        } else if (action == ExternalActionConfig) {
            [weakSelf.wallet showDebuggingOptions:WalletOptionsTypeDebug callback:^() {
                NSLog(@"AppDelegate: Done config");
                [self setupApplications];
            }];
        
        } else if (action == ExternalActionFireflyConfig) {
            [weakSelf.wallet showDebuggingOptions:WalletOptionsTypeFirefly callback:^() {
                NSLog(@"AppDelegate: Done Firefly config");
                [self setupApplications];
            }];

        }
    }];
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    ExternalAction action = ExternalActionNone;
    Payment *payment = nil;
    
    if ([url.host isEqualToString:@"scan"]) {
        action = ExternalActionScan;

    } else if ([url.host isEqualToString:@"wallet"]) {
        action = ExternalActionWallet;

    } else if ([url.host isEqualToString:@"config"]) {
        action = ExternalActionConfig;

    } else if ([url.host isEqualToString:@"firefly"]) {
        action = ExternalActionFireflyConfig;

    } else {
        payment = [Payment paymentWithURI:[url absoluteString]];
        if (payment) {
            action = ExternalActionSend;
        }
    }
    
    return [self handleAction:action payment:payment];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    
    BOOL handled = NO;
    
    if ([shortcutItem.type isEqualToString:@"io.ethers.scan"]) {
        handled = [self handleAction:ExternalActionScan payment:nil];
    } else if ([shortcutItem.type isEqualToString:@"io.ethers.wallet"]) {
        handled = [self handleAction:ExternalActionWallet payment:nil];
    }
    
    completionHandler(handled);
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    
    BOOL handled = NO;
    
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSLog(@"Handle: %@", userActivity.webpageURL);
        
        // Make sure we are at a URL we expect
        if (![userActivity.webpageURL.scheme isEqualToString:@"https"]) { return NO; }
        if (![userActivity.webpageURL.host isEqualToString:@"ethers.io"]) { return NO; }
        if ([userActivity.webpageURL.path hasPrefix:@"/app-link"]) {
            if ([userActivity.webpageURL.fragment hasPrefix:@"!debug"] || [userActivity.webpageURL.fragment hasPrefix:@"!config"]) {
                handled = [self handleAction:ExternalActionConfig payment:nil];

            } else if ([userActivity.webpageURL.fragment hasPrefix:@"!firefly"]) {
                handled = [self handleAction:ExternalActionFireflyConfig payment:nil];

            } else if ([userActivity.webpageURL.fragment hasPrefix:@"!scan"]) {
                handled = [self handleAction:ExternalActionScan payment:nil];

            } else if ([userActivity.webpageURL.fragment hasPrefix:@"!wallet"]) {
                handled = [self handleAction:ExternalActionWallet payment:nil];
            }
        
        } else if ([userActivity.webpageURL.fragment hasPrefix:@"!/app-link/"]) {
            NSString *url = [NSString stringWithFormat:@"https://%@", [userActivity.webpageURL.fragment substringFromIndex:11]];
            NSUInteger index = [_applicationUrls indexOfObject:url];
            if (index == NSNotFound) {
                [self launchApplication:url];
            } else {
                _panelViewController.viewControllerIndex = index + 1;
            }
        }
    }
    
    return handled;
}


#pragma mark - Background fetching

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [_wallet refresh:^(BOOL updated) {
        if (updated) {
            [self notifyExtensions];
            completionHandler(UIBackgroundFetchResultNewData);
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }];
}


#pragma mark - Extensions

- (void)notifyExtensions {
    SharedDefaults *sharedDefaults = [SharedDefaults sharedDefaults];
    
    BigNumber *totalBalance = [BigNumber constantZero];
    
    BOOL hasContent = NO;
    if (_wallet.numberOfAccounts == 0) {
        hasContent = YES;

        if (sharedDefaults.address) {
            sharedDefaults.address = nil;
        }
    
        NSLog(@"AppDelegate: Disable extension");
              
    } else {
        hasContent = YES;
        
        // Address of first account
        Address *address = [_wallet addressForIndex:0];
        if (![sharedDefaults.address isEqualToAddress:address]) {
            sharedDefaults.address = address;
        }
        
        // Balance for first account
        BigNumber *balance = [_wallet balanceForIndex:0];
        if (![sharedDefaults.balance isEqual:balance]) {
            sharedDefaults.balance = balance;
        }
        
        // Sum total balance of all (mainnet) accounts
        for (NSUInteger i = 0; i < _wallet.numberOfAccounts; i++) {
            if ([_wallet chainIdForIndex:i] != ChainIdHomestead) { continue; }
            totalBalance = [totalBalance add:[_wallet balanceForIndex:i]];
        }
        
        NSLog(@"AppDelegate: Update extension - address=%@ totalBalance=%@ price=%.02f", address.checksumAddress, [Payment formatEther:totalBalance], _wallet.etherPrice);
    }
    
    // Total balance
    sharedDefaults.totalBalance = totalBalance;
    
    // Ether price
    sharedDefaults.etherPrice = _wallet.etherPrice;
    
    
    [[NCWidgetController widgetController] setHasContent:hasContent
                           forWidgetWithBundleIdentifier:@"io.ethers.app.TodayExtension"];
}


@end
