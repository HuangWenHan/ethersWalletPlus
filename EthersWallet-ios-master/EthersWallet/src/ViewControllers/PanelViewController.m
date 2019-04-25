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

#import "PanelViewController.h"

#import "UIColor+hex.h"
#import "Utilities.h"

@interface PanelViewController () <UITableViewDataSource, UITableViewDelegate> {
    BOOL _focusPanel;
    
    PanelController *_viewController;
    
    UITableView *_tableView;
    
    // The Application container view
    UIView *_transformView;
    UIView *_slideView;
    UIView *_tiltView;
    UIView *_shadowView;
    UIView *_panelView;
    UIView *_curtainView;
}

@end

@implementation PanelViewController

#pragma mark - View Live-Cycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewControllerIndex = -1;
        _focusPanel = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(notifyBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(notifyForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

    }
    return self;
}

- (void)notifyBackground {
    // Reset the background's children animations for the screen grab
    [_backgroundView removeFromSuperview];
    [self.view insertSubview:_backgroundView atIndex:0];
}

- (void)notifyForeground {
    // Restart any animations our background's children might be up to
    [_backgroundView removeFromSuperview];
    [self.view insertSubview:_backgroundView atIndex:0];
}

- (void)loadView {
    [super loadView];
    
    // The background view is added/removed in focusPanel
    _backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 50.0f;
    _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(64.0f, 0.0f, 0.0f, 0.0f);
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.rowHeight = 50.0f;
    [self.view addSubview:_tableView];

    _transformView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_transformView];
    
    _slideView = [[UIView alloc] initWithFrame:_transformView.bounds];
    [_transformView addSubview:_slideView];
    
    _tiltView = [[UIView alloc] initWithFrame:_transformView.bounds];
    [_slideView addSubview:_tiltView];
    
    _shadowView = [[UIView alloc] initWithFrame:_tiltView.bounds];
    _shadowView.backgroundColor = [UIColor blackColor];
    _shadowView.layer.shadowColor = _shadowView.backgroundColor.CGColor;
    _shadowView.layer.shadowRadius = 30.0f;
    _shadowView.layer.shadowOpacity = 0.7f;
    _shadowView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    [_tiltView addSubview:_shadowView];
    
    UIView *panelViewClipper = [[UIView alloc] initWithFrame:_tiltView.bounds];
    panelViewClipper.clipsToBounds = YES;
    [_tiltView addSubview:panelViewClipper];
    
    _panelView = [[UIView alloc] initWithFrame:panelViewClipper.bounds];
    _panelView.backgroundColor = [UIColor whiteColor];
    [panelViewClipper addSubview:_panelView];

    _curtainView = [[UIView alloc] initWithFrame:_transformView.bounds];
    _curtainView.backgroundColor = [UIColor clearColor];
    [_tiltView addSubview:_curtainView];
    [_curtainView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCurtainView)]];
    
    [self focusPanel:_focusPanel animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (_viewControllerIndex == -1 && [_dataSource panelViewControllerChildCount:self] > 0) {
        [self setViewControllerIndex:0];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

//    [_viewController updateTopMargin:(self.view.safeAreaInsets.top - 44.0f)
//                        bottomMargin:(self.view.safeAreaInsets.bottom)];

    [self focusPanel:_focusPanel animated:NO];
}

- (void)setViewControllerIndex:(NSInteger)viewControllerIndex {
    [self setViewControllerIndex:viewControllerIndex animated:NO];
}

- (void)reloadData {
    [_tableView reloadData];
    [self setViewControllerIndex:0];
}


// @TODO: be sane if they set this to -1. We don't currently need this functionality. The world will end if we do.
- (void)setViewControllerIndex:(NSInteger)index animated:(BOOL)animated {
    
    // Unhighlight (unbold) the old selected entry
    if (_viewControllerIndex >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_viewControllerIndex inSection:0];
        [_tableView cellForRowAtIndexPath:indexPath].textLabel.font = [UIFont fontWithName:FONT_NORMAL size:20.0f];
    }
    
    _viewControllerIndex = index;
    
    // Highlight (bold) the new selected entry
    if (_viewControllerIndex >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [_tableView cellForRowAtIndexPath:indexPath].textLabel.font = [UIFont fontWithName:FONT_BOLD size:20.0f];
    }
    
    // Get the new view controller
    PanelController *viewController = [_dataSource panelViewController:self viewControllerAtIndex:index];
    if (viewController == _viewController) { return; }
    
    // Add a button to bring unfocus it
    UIButton *button = [Utilities ethersButton:ICON_NAME_LOGO fontSize:40.0f color:0xffffff];
    [button addTarget:self action:@selector(tapEthers) forControlEvents:UIControlEventTouchUpInside];
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    PanelController *oldViewController = _viewController;
    
    UIEdgeInsets safeAreaInsets = self.view.safeAreaInsets;

    // Swap the view controllers as a container view controller
    void (^swapViewControllers)() = ^() {
        [oldViewController willMoveToParentViewController:nil];
        [viewController willMoveToParentViewController:self];

        [oldViewController removeFromParentViewController];
        [self addChildViewController:viewController];
        
        [oldViewController.view removeFromSuperview];
        [_panelView addSubview:viewController.view];
        
        [oldViewController didMoveToParentViewController:nil];
        [viewController didMoveToParentViewController:self];

        // Setup its margins (After it has been added to the view hierarchy)
        [viewController updateTopMargin:(safeAreaInsets.top - 44.0f)
                           bottomMargin:(safeAreaInsets.bottom)];

        oldViewController.navigationItem.leftBarButtonItem = nil;
        
        button.alpha = (_focusPanel ? 1.0f: 0.5f);
    };

    if (animated) {
        // Slide-out the old view controller
        void (^animateStep1)() = ^() {
            _slideView.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0.0f);
        };
        
        // Slide in the new view controller
        void (^animateStep2)() = ^() {
            _slideView.transform = CGAffineTransformIdentity;
        };
        
        // At this point, the panel view is off-screen
        void (^completeStep1)(BOOL) = ^(BOOL complete) {
            swapViewControllers();
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                             animations:animateStep2
                             completion:nil];
        };
        
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                         animations:animateStep1
                         completion:completeStep1];
        
    } else {
        swapViewControllers();
    }
    
    _viewController = viewController;
}

- (void)tapCurtainView {
    [self focusPanel:YES animated:YES];
}

- (void)tapEthers {
    [self focusPanel:NO animated:YES];
}

- (void)setupShadow: (BOOL)setupShadow {
    
    if (setupShadow) {
        
        // Add parallax effects to the shadow (we reset this every time we show it in case it gets off)
        // See: http://stackoverflow.com/questions/33612140/how-can-i-customise-uiinterpolatingmotioneffect-to-set-different-shadow-effects
        if (!UIAccessibilityIsReduceMotionEnabled()) {
            UIInterpolatingMotionEffectType vType = UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis;
            UIInterpolatingMotionEffect *vShift = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"layer.shadowOffset.height"
                                                                                                  type:vType];
            vShift.minimumRelativeValue = @(50.0f);
            vShift.maximumRelativeValue = @(-50.0f);
            
            
            UIInterpolatingMotionEffectType hType = UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis;
            UIInterpolatingMotionEffect *hShift = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"layer.shadowOffset.width"
                                                                                                  type:hType];
            hShift.minimumRelativeValue = @(50.0f);
            hShift.maximumRelativeValue = @(-50.0f);
            
            UIMotionEffectGroup *motionGroup = [[UIMotionEffectGroup alloc] init];
            motionGroup.motionEffects = @[vShift, hShift];
            
            [_shadowView addMotionEffect:motionGroup];
            
            
            hShift = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:hType];
            hShift.minimumRelativeValue = @(-30.0f);
            hShift.maximumRelativeValue = @(30.0f);
            
            vShift = [[UIInterpolatingMotionEffect alloc] initWithKeyPath: @"center.y" type:vType];
            vShift.minimumRelativeValue = @(-30.0f);
            vShift.maximumRelativeValue = @(30.0f);
            
            
            motionGroup = [[UIMotionEffectGroup alloc] init];
            motionGroup.motionEffects = @[vShift, hShift];
            
            [_tiltView addMotionEffect:motionGroup];
        }

        _shadowView.hidden = NO;

    } else {
        
        NSArray *motionEffects = _shadowView.motionEffects;
        for (NSInteger i = 0; i < motionEffects.count; i++) {
            [_shadowView removeMotionEffect:[motionEffects objectAtIndex:i]];
        }
        
        motionEffects = _tiltView.motionEffects;
        for (NSInteger i = 0; i < motionEffects.count; i++) {
            [_tiltView removeMotionEffect:[motionEffects objectAtIndex:i]];
        }

        _shadowView.hidden = YES;
    }

}


- (void)focusPanel: (BOOL)focusPanel animated:(BOOL)animated {
    _focusPanel = focusPanel;

    // Nothing to layout yet (loadView will call this again)
    if (!_panelView) { return; }

    PanelController *viewController = _viewController;

    [viewController updateTopMargin:(self.view.safeAreaInsets.top - 44.0f)
                       bottomMargin:(self.view.safeAreaInsets.bottom)];

    if (focusPanel) {
        
        void (^animate)() = ^() {
            // Make the panel full screen
            _transformView.transform = CGAffineTransformIdentity;
            _panelView.transform = CGAffineTransformIdentity;
            
            // Slide the navigation bar up off the screen
            self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0.0f, -88.0f);
            
            // Move and hide the table view off the left hand side
            _tableView.alpha = 0.0f;
            _tableView.transform = CGAffineTransformMakeTranslation(-140.0f, 0.0f);

            viewController.navigationItem.leftBarButtonItem.customView.alpha = 1.0f;

            [self setupShadow:NO];
        };
        
        void (^complete)(BOOL) = ^(BOOL complete) {
            _curtainView.hidden = YES;
            [_backgroundView removeFromSuperview];
        };
        
        if (animated) {
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseOut
                                animations:animate
                             completion:complete];
        } else {
            animate();
            complete(YES);
        }

    } else {
        _curtainView.hidden = NO;
        [self.view insertSubview:_backgroundView atIndex:0];

        [self setupShadow:YES];

        void (^animate)() = ^() {
            // Shrink the panel view
            _transformView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(140.0f, 0.0f), 0.5f, 0.5f);
            
            // Show the navigation bar (was above the screen)
            self.navigationController.navigationBar.transform = CGAffineTransformIdentity;
            
            // Show the table (was off-screen to the left)
            _tableView.alpha = 1.0f;
            _tableView.transform = CGAffineTransformIdentity;

            // Scale and offset the panel view to trim off the extra header and footer
            UIEdgeInsets edges = self.view.safeAreaInsets;

            // iphone 7 - 64 0 => 20
            // iphone X - 88 34 => 12
            CGSize size = self.view.frame.size;
            CGFloat scale = (size.height) / (size.height - edges.top - edges.bottom + 44.0f);
            CGFloat offsetX = (scale * size.width - size.width) / 2.0f;
            CGFloat offsetY = -(scale * (edges.top - 44.0f - edges.bottom)) / 2;
            _panelView.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(offsetX, offsetY), scale, scale);

            // Fade the Ethers button
            viewController.navigationItem.leftBarButtonItem.customView.alpha = 0.5f;
        };
        
        if (animated) {
            [UIView animateWithDuration:0.3f delay:0.1f options:UIViewAnimationOptionCurveEaseOut animations:animate completion:nil];
        } else {
            animate();
        }
    }
}


#pragma mark - UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataSource panelViewControllerChildCount:self];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = @"row";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = _titleColor;
    }
    
    cell.textLabel.font = [UIFont fontWithName:((indexPath.row == _viewControllerIndex) ? FONT_BOLD: FONT_NORMAL) size:20.0f];
    cell.textLabel.text = [_dataSource panelViewController:self titleAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _viewControllerIndex) { return; }
    [self setViewControllerIndex:indexPath.row animated:YES];
}

@end
