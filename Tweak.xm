#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// ============ BUNDLE ID ДЛЯ STANDOFF 2 ============
#define BUNDLE_ID @"com.axelbolt.standoff2"

// ============ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ============
static BOOL gAimbot = NO;
static BOOL gTriggerbot = NO;
static BOOL gESP = NO;
static BOOL gRadar = NO;
static BOOL gNoRecoil = NO;
static BOOL gUnlimitedAmmo = NO;
static NSInteger gFPSLimit = 60;
static BOOL gFirstOpen = YES;
static BOOL gDarkTheme = YES;

// ============ ЗВУКИ ============
static void PlayToggleSound(BOOL isOn) {
    @try {
        SystemSoundID soundID = isOn ? 1103 : 1104;
        AudioServicesPlaySystemSound(soundID);
    } @catch (NSException *exception) {}
}

// ============ ЦВЕТА ============
static UIColor *L77Background(void) {
    return gDarkTheme ?
        [UIColor colorWithRed:0.035 green:0.035 blue:0.060 alpha:0.97] :
        [UIColor colorWithRed:0.98 green:0.97 blue:1.00 alpha:0.97];
}

static UIColor *L77Panel(void) {
    return gDarkTheme ?
        [UIColor colorWithRed:0.075 green:0.060 blue:0.110 alpha:0.95] :
        [UIColor colorWithRed:0.94 green:0.92 blue:1.00 alpha:0.95];
}

static UIColor *L77Border(void) {
    return gDarkTheme ?
        [UIColor colorWithWhite:0.5 alpha:0.25] :
        [UIColor colorWithWhite:0.5 alpha:0.15];
}

static UIColor *L77TextPrimary(void) {
    return gDarkTheme ? UIColor.whiteColor : UIColor.blackColor;
}

static UIColor *L77TextSecondary(void) {
    return gDarkTheme ?
        [UIColor colorWithWhite:0.7 alpha:1] :
        [UIColor colorWithWhite:0.3 alpha:1];
}

static UIColor *L77Purple(void) {
    return [UIColor colorWithRed:0.63 green:0.20 blue:1.00 alpha:1.0];
}

static UIColor *L77LightPurple(void) {
    return [UIColor colorWithRed:0.76 green:0.40 blue:1.00 alpha:1.0];
}

// ============ КАСТОМНЫЙ TOGGLE ============
@interface L77Toggle : UIControl
@property(nonatomic,strong) UIView *indicator;
@property(nonatomic,strong) UILabel *label;
@property(nonatomic,assign) BOOL on;
@property(nonatomic,copy) NSString *key;
@end

@implementation L77Toggle

- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.key = key;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        _indicator = [UIView new];
        _indicator.translatesAutoresizingMaskIntoConstraints = NO;
        _indicator.layer.cornerRadius = 5;
        _indicator.layer.borderWidth = 1.5;
        _indicator.layer.borderColor = L77Border().CGColor;
        
        _label = [UILabel new];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.text = title;
        _label.textColor = L77TextPrimary();
        _label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        
        [self addSubview:_indicator];
        [self addSubview:_label];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.heightAnchor constraintEqualToConstant:34],
            [_indicator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_indicator.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_indicator.widthAnchor constraintEqualToConstant:19],
            [_indicator.heightAnchor constraintEqualToConstant:19],
            [_label.leadingAnchor constraintEqualToAnchor:_indicator.trailingAnchor constant:10],
            [_label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
        ]];
        
        [self addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)toggle {
    self.on = !self.on;
    PlayToggleSound(self.on);
    
    [UIView animateWithDuration:0.15 animations:^{
        self.indicator.backgroundColor = self.on ? L77Purple() : UIColor.clearColor;
        self.indicator.layer.borderColor = (self.on ? L77LightPurple() : L77Border()).CGColor;
        self.indicator.transform = CGAffineTransformMakeScale(0.85, 0.85);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{
            self.indicator.transform = CGAffineTransformIdentity;
        }];
    }];
    
    if ([self.key isEqualToString:@"aimbot"]) gAimbot = self.on;
    else if ([self.key isEqualToString:@"trigger"]) gTriggerbot = self.on;
    else if ([self.key isEqualToString:@"esp"]) gESP = self.on;
    else if ([self.key isEqualToString:@"radar"]) gRadar = self.on;
    else if ([self.key isEqualToString:@"recoil"]) gNoRecoil = self.on;
    else if ([self.key isEqualToString:@"ammo"]) gUnlimitedAmmo = self.on;
}

@end

// ============ ГЛАВНОЕ МЕНЮ ============
@interface Lucky77OverlayView : UIView
@property(nonatomic,strong) UIView *menu;
@property(nonatomic,strong) UIView *intro;
@property(nonatomic,strong) UILabel *fpsLabel;
@property(nonatomic,strong) UIStackView *navStack;
@property(nonatomic,strong) UIStackView *contentStack;
@property(nonatomic,strong) NSArray<UIButton *> *navButtons;
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic,assign) CFTimeInterval lastTimestamp;
@property(nonatomic,assign) NSInteger frameCount;
@property(nonatomic,strong) UIButton *launcherButton;
@property(nonatomic,assign) BOOL isDragging;
@property(nonatomic,assign) CGPoint dragOffset;
@property(nonatomic,assign) BOOL introShown;
@property(nonatomic,strong) NSLayoutConstraint *leadingConstraint;
@property(nonatomic,strong) NSLayoutConstraint *topConstraint;
@property(nonatomic,strong) NSLayoutConstraint *menuLeadingConstraint;
@property(nonatomic,strong) NSLayoutConstraint *menuTopConstraint;
@end

@implementation Lucky77OverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.introShown = NO;
        
        // ============ ЖЕСТ: ТРОЙНОЕ КАСАНИЕ ТРЕМЯ ПАЛЬЦАМИ ============
        UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTripleTap:)];
        tripleTap.numberOfTapsRequired = 3;
        tripleTap.numberOfTouchesRequired = 3;
        tripleTap.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tripleTap];
        
        [self buildLauncherButton];
        [self buildMenu];
        [self buildIntro];
        [self startFPS];
    }
    return self;
}

- (void)dealloc {
    [self.displayLink invalidate];
}

// ============ ОБРАБОТЧИК ТРОЙНОГО КАСАНИЯ ============
- (void)handleTripleTap:(UITapGestureRecognizer *)gesture {
    NSLog(@"[Lucky77] 🔥 Triple tap detected!");
    
    if (self.menu.hidden) {
        self.userInteractionEnabled = YES;
        [self showIntroWithCompletion:^{
            self.menu.hidden = NO;
            self.menu.alpha = 0;
            self.launcherButton.hidden = YES;
            [UIView animateWithDuration:0.25 animations:^{
                self.menu.alpha = 1;
            }];
        }];
    } else {
        [UIView animateWithDuration:0.18 animations:^{
            self.menu.alpha = 0;
        } completion:^(BOOL finished) {
            self.menu.hidden = YES;
            self.menu.alpha = 1;
            self.launcherButton.hidden = NO;
            self.userInteractionEnabled = NO;
        }];
    }
}

// ============ КНОПКА-ЛАУНЧЕР ============
- (void)buildLauncherButton {
    self.launcherButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.launcherButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.launcherButton.backgroundColor = [L77Background() colorWithAlphaComponent:0.85];
    self.launcherButton.layer.cornerRadius = 14;
    self.launcherButton.layer.borderWidth = 1.5;
    self.launcherButton.layer.borderColor = L77Purple().CGColor;
    [self.launcherButton setTitle:@"⚡" forState:UIControlStateNormal];
    [self.launcherButton setTitleColor:L77LightPurple() forState:UIControlStateNormal];
    self.launcherButton.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.launcherButton.userInteractionEnabled = YES;
    self.launcherButton.hidden = NO;
    [self.launcherButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragLauncher:)];
    [self.launcherButton addGestureRecognizer:pan];
    
    [self addSubview:self.launcherButton];
    
    self.leadingConstraint = [self.launcherButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12];
    self.topConstraint = [self.launcherButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:12];
    
    [NSLayoutConstraint activateConstraints:@[
        self.leadingConstraint,
        self.topConstraint,
        [self.launcherButton.widthAnchor constraintEqualToConstant:48],
        [self.launcherButton.heightAnchor constraintEqualToConstant:48],
    ]];
    
    [self bringSubviewToFront:self.launcherButton];
}

- (void)dragLauncher:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        CGFloat newX = self.leadingConstraint.constant + translation.x;
        CGFloat newY = self.topConstraint.constant + translation.y;
        newX = MAX(0, MIN(newX, self.bounds.size.width - 60));
        newY = MAX(0, MIN(newY, self.bounds.size.height - 60));
        self.leadingConstraint.constant = newX;
        self.topConstraint.constant = newY;
        [gesture setTranslation:CGPointZero inView:self];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
    }
}

// ============ МЕНЮ ============
- (void)buildMenu {
    self.menu = [UIView new];
    self.menu.translatesAutoresizingMaskIntoConstraints = NO;
    self.menu.backgroundColor = L77Background();
    self.menu.layer.cornerRadius = 0;
    self.menu.layer.borderWidth = 1;
    self.menu.layer.borderColor = L77Border().CGColor;
    self.menu.clipsToBounds = YES;
    self.menu.hidden = YES;
    self.menu.userInteractionEnabled = YES;
    
    [self addSubview:self.menu];
    
    self.menuLeadingConstraint = [self.menu.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:40];
    self.menuTopConstraint = [self.menu.topAnchor constraintEqualToAnchor:self.topAnchor constant:60];
    
    [NSLayoutConstraint activateConstraints:@[
        self.menuLeadingConstraint,
        self.menuTopConstraint,
        [self.menu.widthAnchor constraintEqualToConstant:420],
        [self.menu.heightAnchor constraintEqualToConstant:480]
    ]];
    
    UIPanGestureRecognizer *dragMenu = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
    [self.menu addGestureRecognizer:dragMenu];
    
    [self buildHeader];
    [self buildBody];
}

- (void)dragMenu:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        CGFloat newX = self.menuLeadingConstraint.constant + translation.x;
        CGFloat newY = self.menuTopConstraint.constant + translation.y;
        newX = MAX(0, MIN(newX, self.bounds.size.width - 420));
        newY = MAX(0, MIN(newY, self.bounds.size.height - 480));
        self.menuLeadingConstraint.constant = newX;
        self.menuTopConstraint.constant = newY;
        [gesture setTranslation:CGPointZero inView:self];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
    }
}

// ============ HEADER ============
- (void)buildHeader {
    UIView *header = [UIView new];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menu addSubview:header];
    
    self.fpsLabel = [UILabel new];
    self.fpsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fpsLabel.text = @"60 FPS";
    self.fpsLabel.textColor = L77LightPurple();
    self.fpsLabel.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightMedium];
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Lucky77";
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    title.textColor = L77TextPrimary();
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"77";
    logo.textColor = L77LightPurple();
    logo.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBlack];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:L77LightPurple() forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    [header addSubview:self.fpsLabel];
    [header addSubview:title];
    [header addSubview:logo];
    [header addSubview:closeBtn];
    
    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = L77Border();
    [self.menu addSubview:divider];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.menu.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.menu.trailingAnchor],
        [header.topAnchor constraintEqualToAnchor:self.menu.topAnchor],
        [header.heightAnchor constraintEqualToConstant:56],
        [self.fpsLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:16],
        [self.fpsLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [title.centerXAnchor constraintEqualToAnchor:header.centerXAnchor constant:-12],
        [title.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:6],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [closeBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-16],
        [closeBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [closeBtn.widthAnchor constraintEqualToConstant:36],
        [closeBtn.heightAnchor constraintEqualToConstant:36],
        [divider.leadingAnchor constraintEqualToAnchor:self.menu.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.menu.trailingAnchor],
        [divider.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [divider.heightAnchor constraintEqualToConstant:1]
    ]];
}

// ============ BODY ============
- (void)buildBody {
    UIView *sidebar = [UIView new];
    sidebar.translatesAutoresizingMaskIntoConstraints = NO;
    sidebar.backgroundColor = gDarkTheme ?
        [UIColor colorWithWhite:0 alpha:0.18] :
        [UIColor colorWithWhite:1 alpha:0.18];
    [self.menu addSubview:sidebar];
    
    self.navStack = [UIStackView new];
    self.navStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.navStack.axis = UILayoutConstraintAxisVertical;
    self.navStack.spacing = 8;
    [sidebar addSubview:self.navStack];
    
    NSArray *titles = @[@"AIMBOT", @"VISUALS", @"SETTINGS"];
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = i;
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button setTitleColor:L77TextPrimary() forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        button.layer.cornerRadius = 0;
        if (i == 0) {
            button.backgroundColor = [L77Purple() colorWithAlphaComponent:0.30];
        }
        [button addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button.heightAnchor constraintEqualToConstant:48].active = YES;
        [self.navStack addArrangedSubview:button];
        [buttons addObject:button];
    }
    self.navButtons = buttons;
    
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [self.menu addSubview:scroll];
    
    self.contentStack = [UIStackView new];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 10;
    [scroll addSubview:self.contentStack];
    
    [self showTab:0];
    
    [NSLayoutConstraint activateConstraints:@[
        [sidebar.leadingAnchor constraintEqualToAnchor:self.menu.leadingAnchor constant:12],
        [sidebar.topAnchor constraintEqualToAnchor:self.menu.topAnchor constant:68],
        [sidebar.bottomAnchor constraintEqualToAnchor:self.menu.bottomAnchor constant:-12],
        [sidebar.widthAnchor constraintEqualToConstant:100],
        [self.navStack.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:8],
        [self.navStack.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-8],
        [self.navStack.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:12],
        [scroll.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:12],
        [scroll.trailingAnchor constraintEqualToAnchor:self.menu.trailingAnchor constant:-12],
        [scroll.topAnchor constraintEqualToAnchor:sidebar.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:sidebar.bottomAnchor],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [self.contentStack.topAnchor constraintEqualToAnchor:scroll.topAnchor],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor],
        [self.contentStack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor]
    ]];
}

// ============ TABS ============
- (void)tabTapped:(UIButton *)sender {
    for (UIButton *button in self.navButtons) {
        button.backgroundColor = UIColor.clearColor;
    }
    sender.backgroundColor = [L77Purple() colorWithAlphaComponent:0.30];
    [self showTab:sender.tag];
}

- (void)showTab:(NSInteger)index {
    NSArray *oldViews = [self.contentStack.arrangedSubviews copy];
    for (UIView *view in oldViews) {
        [self.contentStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    UIView *content = nil;
    if (index == 0) {
        content = [self togglePanel:@[
            @"ENABLE AIMBOT",
            @"TRIGGERBOT",
            @"SMOOTH AIM",
            @"VISIBLE CHECK",
            @"AIM FOV"
        ] keys:@[@"aimbot", @"trigger", @"smooth", @"visible", @"fov"]];
    } else if (index == 1) {
        content = [self togglePanel:@[
            @"ESP BOX",
            @"ESP NAME",
            @"ESP HEALTH",
            @"SNAP LINES",
            @"RADAR HACK",
            @"NO RECOIL",
            @"UNLIMITED AMMO"
        ] keys:@[@"esp", @"name", @"health", @"lines", @"radar", @"recoil", @"ammo"]];
    } else {
        content = [self settingsPanel];
    }
    [self.contentStack addArrangedSubview:content];
}

// ============ TOGGLE PANEL ============
- (UIView *)togglePanel:(NSArray<NSString *> *)titles keys:(NSArray<NSString *> *)keys {
    UIView *panel = [UIView new];
    panel.backgroundColor = L77Panel();
    panel.layer.cornerRadius = 0;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = L77Border().CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;
    [panel addSubview:stack];
    
    for (NSInteger i = 0; i < titles.count && i < keys.count; i++) {
        L77Toggle *toggle = [[L77Toggle alloc] initWithTitle:titles[i] key:keys[i]];
        [stack addArrangedSubview:toggle];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16],
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:14],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-14]
    ]];
    
    return panel;
}

// ============ SETTINGS ============
- (UIView *)settingsPanel {
    UIView *panel = [UIView new];
    panel.backgroundColor = L77Panel();
    panel.layer.cornerRadius = 0;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = L77Border().CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    [panel addSubview:stack];
    
    UILabel *title = [UILabel new];
    title.text = @"SETTINGS";
    title.textColor = L77TextPrimary();
    title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [stack addArrangedSubview:title];
    
    // ТЕМА
    UILabel *themeLabel = [UILabel new];
    themeLabel.text = @"THEME";
    themeLabel.textColor = L77TextSecondary();
    themeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [stack addArrangedSubview:themeLabel];
    
    UISegmentedControl *themeSegment = [[UISegmentedControl alloc] initWithItems:@[@"🌙 Dark", @"☀️ Light"]];
    themeSegment.selectedSegmentIndex = gDarkTheme ? 0 : 1;
    themeSegment.tintColor = L77Purple();
    [themeSegment addTarget:self action:@selector(themeChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:themeSegment];
    
    // FPS
    UILabel *fpsLabel = [UILabel new];
    fpsLabel.text = @"FPS LIMIT";
    fpsLabel.textColor = L77TextSecondary();
    fpsLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [stack addArrangedSubview:fpsLabel];
    
    UISegmentedControl *fpsSegment = [[UISegmentedControl alloc] initWithItems:@[@"30", @"60", @"90", @"120"]];
    fpsSegment.selectedSegmentIndex = 1;
    fpsSegment.tintColor = L77Purple();
    [fpsSegment addTarget:self action:@selector(fpsLimitChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:fpsSegment];
    
    // DEVELOPER
    UILabel *devLabel = [UILabel new];
    devLabel.text = @"DEVELOPER";
    devLabel.textColor = L77TextSecondary();
    devLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [stack addArrangedSubview:devLabel];
    
    UIButton *devBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [devBtn setTitle:@"@hack77ios" forState:UIControlStateNormal];
    [devBtn setTitleColor:L77LightPurple() forState:UIControlStateNormal];
    devBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [devBtn addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:devBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16],
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:14],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-14]
    ]];
    
    return panel;
}

// ============ ТЕМА ============
- (void)themeChanged:(UISegmentedControl *)sender {
    gDarkTheme = (sender.selectedSegmentIndex == 0);
    [self rebuildUI];
}

- (void)rebuildUI {
    [self.menu removeFromSuperview];
    self.menu = nil;
    [self.contentStack removeFromSuperview];
    self.contentStack = nil;
    [self.navStack removeFromSuperview];
    self.navStack = nil;
    [self buildMenu];
    if (!self.menu.hidden) {
        self.menu.hidden = NO;
        self.menu.alpha = 1;
    }
}

// ============ INTRO ============
- (void)buildIntro {
    self.intro = [UIView new];
    self.intro.translatesAutoresizingMaskIntoConstraints = NO;
    self.intro.backgroundColor = L77Background();
    self.intro.layer.cornerRadius = 0;
    self.intro.hidden = YES;
    self.intro.userInteractionEnabled = NO;
    [self addSubview:self.intro];
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"77";
    logo.font = [UIFont systemFontOfSize:90 weight:UIFontWeightBlack];
    logo.textColor = L77LightPurple();
    logo.textAlignment = NSTextAlignmentCenter;
    logo.layer.shadowColor = L77LightPurple().CGColor;
    logo.layer.shadowOpacity = 0.9;
    logo.layer.shadowRadius = 30;
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Lucky77";
    title.font = [UIFont systemFontOfSize:38 weight:UIFontWeightBold];
    title.textColor = L77TextPrimary();
    title.textAlignment = NSTextAlignmentCenter;
    
    UILabel *version = [UILabel new];
    version.translatesAutoresizingMaskIntoConstraints = NO;
    version.text = @"v0.1";
    version.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    version.textColor = L77TextSecondary();
    version.textAlignment = NSTextAlignmentCenter;
    
    [self.intro addSubview:logo];
    [self.intro addSubview:title];
    [self.intro addSubview:version];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.intro.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.intro.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.intro.widthAnchor constraintEqualToConstant:320],
        [self.intro.heightAnchor constraintEqualToConstant:280],
        [logo.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [logo.topAnchor constraintEqualToAnchor:self.intro.topAnchor constant:35],
        [title.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:8],
        [version.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [version.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4]
    ]];
}

- (void)showIntroWithCompletion:(void (^)(void))completion {
    if (!gFirstOpen) {
        if (completion) completion();
        return;
    }
    
    gFirstOpen = NO;
    self.intro.hidden = NO;
    self.intro.alpha = 0;
    self.intro.transform = CGAffineTransformMakeScale(0.5, 0.5);
    
    [UIView animateWithDuration:0.8 delay:0.2 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.intro.alpha = 1;
        self.intro.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.6 animations:^{
                self.intro.alpha = 0;
                self.intro.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished2) {
                self.intro.hidden = YES;
                if (completion) completion();
            }];
        });
    }];
}

// ============ FPS ============
- (void)startFPS {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fpsTick:)];
    self.displayLink.preferredFramesPerSecond = gFPSLimit;
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)fpsTick:(CADisplayLink *)link {
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
        return;
    }
    self.frameCount++;
    CFTimeInterval elapsed = link.timestamp - self.lastTimestamp;
    if (elapsed >= 0.5) {
        double fps = self.frameCount / elapsed;
        self.fpsLabel.text = [NSString stringWithFormat:@"%.0f FPS", fps];
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

- (void)fpsLimitChanged:(UISegmentedControl *)sender {
    NSArray *values = @[@30, @60, @90, @120];
    gFPSLimit = [values[sender.selectedSegmentIndex] integerValue];
    self.displayLink.preferredFramesPerSecond = gFPSLimit;
}

// ============ УПРАВЛЕНИЕ МЕНЮ ============
- (void)toggleMenu {
    if (self.menu.hidden) {
        self.userInteractionEnabled = YES;
        [self showIntroWithCompletion:^{
            self.menu.hidden = NO;
            self.menu.alpha = 0;
            self.launcherButton.hidden = YES;
            [UIView animateWithDuration:0.25 animations:^{
                self.menu.alpha = 1;
            }];
        }];
    } else {
        [UIView animateWithDuration:0.18 animations:^{
            self.menu.alpha = 0;
        } completion:^(BOOL finished) {
            self.menu.hidden = YES;
            self.menu.alpha = 1;
            self.launcherButton.hidden = NO;
            self.userInteractionEnabled = NO;
        }];
    }
}

- (void)openTelegram {
    NSURL *url = [NSURL URLWithString:@"https://t.me/hack77ios"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end

// ============ ТОЧКА ВХОДА ============
static void ShowLucky77Overlay(UIWindow *targetWindow) {
    if (!targetWindow) {
        NSLog(@"[Lucky77] ❌ Target window is nil");
        return;
    }
    
    Lucky77OverlayView *overlay = [[Lucky77OverlayView alloc] initWithFrame:targetWindow.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [UIColor clearColor];
    overlay.userInteractionEnabled = NO;
    
    [targetWindow addSubview:overlay];
    [targetWindow bringSubviewToFront:overlay];
    
    NSLog(@"[Lucky77] ✅ Overlay attached to window: %@", targetWindow);
}

__attribute__((constructor)) void init() {
    NSLog(@"[Lucky77] ⏳ init() called");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *mainWindow = nil;
        
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:UIWindowScene.class] &&
                    scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            mainWindow = window;
                            break;
                        }
                    }
                    if (mainWindow) break;
                }
            }
        }
        
        if (!mainWindow) {
            mainWindow = UIApplication.sharedApplication.keyWindow;
        }
        
        if (!mainWindow) {
            mainWindow = UIApplication.sharedApplication.windows.firstObject;
        }
        
        if (mainWindow) {
            ShowLucky77Overlay(mainWindow);
        } else {
            NSLog(@"[Lucky77] ❌ No window found");
        }
    });
}
