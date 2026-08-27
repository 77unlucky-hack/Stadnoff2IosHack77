#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <substrate.h>

// ============ BUNDLE ID ДЛЯ STANDOFF 2 ============
#define BUNDLE_ID @"com.axelbolt.standof2"

// ============ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ============
static BOOL gAimbot = NO;
static BOOL gTriggerbot = NO;
static BOOL gESP = NO;
static BOOL gRadar = NO;
static BOOL gNoRecoil = NO;
static BOOL gUnlimitedAmmo = NO;
static NSInteger gFPSLimit = 60;

// ============ ЦВЕТА ============
static UIColor *L77Purple(void) {
    return [UIColor colorWithRed:0.63 green:0.20 blue:1.00 alpha:1.0];
}

static UIColor *L77LightPurple(void) {
    return [UIColor colorWithRed:0.76 green:0.40 blue:1.00 alpha:1.0];
}

static UIColor *L77Background(void) {
    return [UIColor colorWithRed:0.035 green:0.035 blue:0.060 alpha:0.97];
}

static UIColor *L77Panel(void) {
    return [UIColor colorWithRed:0.075 green:0.060 blue:0.110 alpha:0.95];
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
        _indicator.layer.borderColor = [UIColor colorWithWhite:0.55 alpha:0.35].CGColor;
        
        _label = [UILabel new];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.text = title;
        _label.textColor = UIColor.whiteColor;
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
    AudioServicesPlaySystemSound(self.on ? 1103 : 1104);
    
    [UIView animateWithDuration:0.15 animations:^{
        self.indicator.backgroundColor = self.on ? L77Purple() : UIColor.clearColor;
        self.indicator.layer.borderColor = (self.on ? L77LightPurple() : [UIColor colorWithWhite:0.55 alpha:0.35]).CGColor;
        self.indicator.transform = CGAffineTransformMakeScale(0.85, 0.85);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{
            self.indicator.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // Обновление глобальных флагов
    if ([self.key isEqualToString:@"aimbot"]) gAimbot = self.on;
    else if ([self.key isEqualToString:@"trigger"]) gTriggerbot = self.on;
    else if ([self.key isEqualToString:@"esp"]) gESP = self.on;
    else if ([self.key isEqualToString:@"radar"]) gRadar = self.on;
    else if ([self.key isEqualToString:@"recoil"]) gNoRecoil = self.on;
    else if ([self.key isEqualToString:@"ammo"]) gUnlimitedAmmo = self.on;
}

@end

// ============ ГЛАВНОЕ МЕНЮ ============
@interface Lucky77MenuViewController : UIViewController
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
@end

@implementation Lucky77MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.clearColor;
    self.view.userInteractionEnabled = YES;
    
    [self buildLauncherButton];
    [self buildMenu];
    [self buildIntro];
    [self startFPS];
    
    // Показываем интро при первом открытии
    [self showIntro];
}

- (void)dealloc {
    [self.displayLink invalidate];
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
    [self.launcherButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragLauncher:)];
    [self.launcherButton addGestureRecognizer:pan];
    
    [self.view addSubview:self.launcherButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.launcherButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10],
        [self.launcherButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [self.launcherButton.widthAnchor constraintEqualToConstant:44],
        [self.launcherButton.heightAnchor constraintEqualToConstant:44],
    ]];
}

- (void)dragLauncher:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        CGPoint touch = [gesture locationInView:self.view];
        CGPoint center = self.launcherButton.center;
        self.dragOffset = CGPointMake(center.x - touch.x, center.y - touch.y);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint touch = [gesture locationInView:self.view];
        self.launcherButton.center = CGPointMake(touch.x + self.dragOffset.x, touch.y + self.dragOffset.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
    }
}

// ============ МЕНЮ ============
- (void)buildMenu {
    self.menu = [UIView new];
    self.menu.translatesAutoresizingMaskIntoConstraints = NO;
    self.menu.backgroundColor = L77Background();
    self.menu.layer.cornerRadius = 18;
    self.menu.layer.borderWidth = 1;
    self.menu.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.25].CGColor;
    self.menu.clipsToBounds = YES;
    self.menu.hidden = YES;
    
    [self.view addSubview:self.menu];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.menu.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.menu.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.menu.widthAnchor constraintEqualToConstant:320],
        [self.menu.heightAnchor constraintEqualToConstant:390]
    ]];
    
    [self buildHeader];
    [self buildBody];
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
    self.fpsLabel.font = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightMedium];
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Lucky77";
    title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    title.textColor = UIColor.whiteColor;
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:L77LightPurple() forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    [header addSubview:self.fpsLabel];
    [header addSubview:title];
    [header addSubview:closeBtn];
    
    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.20];
    [self.menu addSubview:divider];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.menu.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.menu.trailingAnchor],
        [header.topAnchor constraintEqualToAnchor:self.menu.topAnchor],
        [header.heightAnchor constraintEqualToConstant:45],
        [self.fpsLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:12],
        [self.fpsLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [title.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [title.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [closeBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-12],
        [closeBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [closeBtn.widthAnchor constraintEqualToConstant:30],
        [closeBtn.heightAnchor constraintEqualToConstant:30],
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
    sidebar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.18];
    [self.menu addSubview:sidebar];
    
    self.navStack = [UIStackView new];
    self.navStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.navStack.axis = UILayoutConstraintAxisVertical;
    self.navStack.spacing = 6;
    [sidebar addSubview:self.navStack];
    
    NSArray *titles = @[@"AIMBOT", @"VISUALS", @"SETTINGS"];
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = i;
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
        button.layer.cornerRadius = 7;
        if (i == 0) {
            button.backgroundColor = [L77Purple() colorWithAlphaComponent:0.30];
        }
        [button addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button.heightAnchor constraintEqualToConstant:44].active = YES;
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
    self.contentStack.spacing = 8;
    [scroll addSubview:self.contentStack];
    
    [self showTab:0];
    
    [NSLayoutConstraint activateConstraints:@[
        [sidebar.leadingAnchor constraintEqualToAnchor:self.menu.leadingAnchor constant:8],
        [sidebar.topAnchor constraintEqualToAnchor:self.menu.topAnchor constant:54],
        [sidebar.bottomAnchor constraintEqualToAnchor:self.menu.bottomAnchor constant:-8],
        [sidebar.widthAnchor constraintEqualToConstant:78],
        [self.navStack.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:5],
        [self.navStack.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-5],
        [self.navStack.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:8],
        [scroll.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:8],
        [scroll.trailingAnchor constraintEqualToAnchor:self.menu.trailingAnchor constant:-8],
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
            @"VISIBLE CHECK"
        ] keys:@[@"aimbot", @"trigger", @"smooth", @"visible"]];
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
    panel.layer.cornerRadius = 10;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = [UIColor colorWithWhite:0.50 alpha:0.25].CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 3;
    [panel addSubview:stack];
    
    for (NSInteger i = 0; i < titles.count && i < keys.count; i++) {
        L77Toggle *toggle = [[L77Toggle alloc] initWithTitle:titles[i] key:keys[i]];
        [stack addArrangedSubview:toggle];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-12],
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:10],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-10]
    ]];
    
    return panel;
}

// ============ SETTINGS ============
- (UIView *)settingsPanel {
    UIView *panel = [UIView new];
    panel.backgroundColor = L77Panel();
    panel.layer.cornerRadius = 10;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [panel addSubview:stack];
    
    UILabel *title = [UILabel new];
    title.text = @"SETTINGS";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    [stack addArrangedSubview:title];
    
    UILabel *fps = [UILabel new];
    fps.text = @"FPS LIMIT";
    fps.textColor = [UIColor colorWithWhite:0.75 alpha:1];
    fps.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:fps];
    
    UISegmentedControl *fpsSegment = [[UISegmentedControl alloc] initWithItems:@[@"30", @"60", @"90", @"120"]];
    fpsSegment.selectedSegmentIndex = 1;
    fpsSegment.tintColor = L77Purple();
    [fpsSegment addTarget:self action:@selector(fpsLimitChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:fpsSegment];
    
    UILabel *developer = [UILabel new];
    developer.text = @"@hack77ios";
    developer.textAlignment = NSTextAlignmentCenter;
    developer.textColor = L77LightPurple();
    developer.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    developer.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openTelegram)];
    [developer addGestureRecognizer:tap];
    [stack addArrangedSubview:developer];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-12],
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-12]
    ]];
    
    return panel;
}

// ============ INTRO ============
- (void)buildIntro {
    self.intro = [UIView new];
    self.intro.translatesAutoresizingMaskIntoConstraints = NO;
    self.intro.backgroundColor = L77Background();
    self.intro.layer.cornerRadius = 22;
    self.intro.hidden = YES;
    [self.view addSubview:self.intro];
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"77";
    logo.font = [UIFont systemFontOfSize:80 weight:UIFontWeightBlack];
    logo.textColor = L77LightPurple();
    logo.textAlignment = NSTextAlignmentCenter;
    logo.layer.shadowColor = L77LightPurple().CGColor;
    logo.layer.shadowOpacity = 0.9;
    logo.layer.shadowRadius = 30;
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Lucky77";
    title.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    title.textColor = UIColor.whiteColor;
    title.textAlignment = NSTextAlignmentCenter;
    
    [self.intro addSubview:logo];
    [self.intro addSubview:title];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.intro.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.intro.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.intro.widthAnchor constraintEqualToConstant:280],
        [self.intro.heightAnchor constraintEqualToConstant:250],
        [logo.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [logo.topAnchor constraintEqualToAnchor:self.intro.topAnchor constant:32],
        [title.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [title.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:12]
    ]];
}

- (void)showIntro {
    self.intro.hidden = NO;
    self.intro.alpha = 0;
    self.intro.transform = CGAffineTransformMakeScale(0.5, 0.5);
    
    [UIView animateWithDuration:0.8 delay:0.2 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.intro.alpha = 1;
        self.intro.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.6 animations:^{
                self.intro.alpha = 0;
                self.intro.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished2) {
                self.intro.hidden = YES;
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
        self.menu.hidden = NO;
        self.menu.alpha = 0;
        self.launcherButton.hidden = YES;
        
        [UIView animateWithDuration:0.2 animations:^{
            self.menu.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{
            self.menu.alpha = 0;
        } completion:^(BOOL finished) {
            self.menu.hidden = YES;
            self.menu.alpha = 1;
            self.launcherButton.hidden = NO;
        }];
    }
}

- (void)openTelegram {
    NSURL *url = [NSURL URLWithString:@"https://t.me/hack77ios"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end

// ============ ТОЧКА ВХОДА ДЛЯ TWEAK (.xm) ============
%ctor {
    // Ждём полной загрузки игры (5 секунд)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) {
                            window = w;
                            break;
                        }
                    }
                    if (window) break;
                }
            }
        }
        if (!window) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }
        if (!window) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = [UIApplication sharedApplication].windows.firstObject;
            #pragma clang diagnostic pop
        }
        
        UIViewController *root = window.rootViewController;
        if (root) {
            Lucky77MenuViewController *menuVC = [Lucky77MenuViewController new];
            menuVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [root presentViewController:menuVC animated:NO completion:nil];
            NSLog(@"[Lucky77] ✅ Injected into Standoff 2!");
        } else {
            NSLog(@"[Lucky77] ❌ No root view controller");
        }
    });
}

// ============ ХУКИ ДЛЯ STANDOFF 2 ============
// Здесь будут добавляться хуки для функций игры
// (ESP, Aimbot, No Recoil, Unlimited Ammo и т.д.)

%hook GamePlayer

// Пример хука для бесконечных патронов
- (int)getAmmo {
    if (gUnlimitedAmmo) {
        return 999;
    }
    return %orig;
}

%end

%hook WeaponController

// Пример хука для отключения отдачи
- (float)getRecoil {
    if (gNoRecoil) {
        return 0.0f;
    }
    return %orig;
}

%end
