#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <objc/runtime.h>

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
static NSInteger gLanguage = 0;

// ============ НАСТРОЙКИ АИМБОТА ============
static CGFloat gAimbotSpeed = 5.0;
static CGFloat gAimbotSharpness = 1.0;
static NSInteger gAimbotTarget = 0;
static CGFloat gAimbotFOV = 0.0;
static NSString *gAimbotTargetNames[] = {@"HEAD", @"NECK", @"BODY"};
static CGFloat gAimbotTargetOffsets[] = {1.6, 1.2, 0.8};

// ============ ЦВЕТА ДЛЯ ESP ============
static UIColor *gESPBoxColorVisible = nil;
static UIColor *gESPBoxColorInvisible = nil;
static UIColor *gESPLinesColor = nil;
static UIColor *gFOVCircleColor = nil;
static CGFloat gFOVRadius = 0.0;

static void InitColors(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gESPBoxColorVisible = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        gESPBoxColorInvisible = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.6];
        gESPLinesColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
        gFOVCircleColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.3];
        gFOVRadius = 0.0;
    });
}

// ============ ПУТЬ К КОНФИГУ ============
static NSString *GetConfigPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = paths.firstObject;
    return [documents stringByAppendingPathComponent:@"lucky77_config.plist"];
}

// ============ ЛОКАЛИЗАЦИЯ ============
static NSString* L(NSString *key) {
    static NSDictionary *en = nil;
    static NSDictionary *ru = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        en = @{
            @"settings": @"SETTINGS",
            @"theme": @"THEME",
            @"dark": @"🌙 Dark",
            @"light": @"☀️ Light",
            @"fps_limit": @"FPS LIMIT",
            @"esp_colors": @"ESP COLORS",
            @"visible_box": @"VISIBLE BOX",
            @"invisible_box": @"INVISIBLE BOX",
            @"lines_color": @"LINES COLOR",
            @"fov_color": @"FOV COLOR",
            @"developer": @"DEVELOPER",
            @"config": @"CONFIG",
            @"save_config": @"SAVE CONFIG",
            @"load_config": @"LOAD CONFIG",
            @"language": @"LANGUAGE",
            @"saved": @"✅ Config saved!",
            @"loaded": @"✅ Config loaded!",
            @"fail_save": @"❌ Failed to save config",
            @"fail_load": @"❌ Failed to load config",
            @"aimbot": @"AIMBOT",
            @"visuals": @"VISUALS",
        };
        ru = @{
            @"settings": @"НАСТРОЙКИ",
            @"theme": @"ТЕМА",
            @"dark": @"🌙 Тёмная",
            @"light": @"☀️ Светлая",
            @"fps_limit": @"ЛИМИТ FPS",
            @"esp_colors": @"ЦВЕТА ESP",
            @"visible_box": @"ВИДИМЫЙ БОКС",
            @"invisible_box": @"НЕВИДИМЫЙ БОКС",
            @"lines_color": @"ЦВЕТ ЛИНИЙ",
            @"fov_color": @"ЦВЕТ FOV",
            @"developer": @"РАЗРАБОТЧИК",
            @"config": @"КОНФИГ",
            @"save_config": @"СОХРАНИТЬ КОНФИГ",
            @"load_config": @"ЗАГРУЗИТЬ КОНФИГ",
            @"language": @"ЯЗЫК",
            @"saved": @"✅ Конфиг сохранён!",
            @"loaded": @"✅ Конфиг загружен!",
            @"fail_save": @"❌ Не удалось сохранить конфиг",
            @"fail_load": @"❌ Не удалось загрузить конфиг",
            @"aimbot": @"АИМБОТ",
            @"visuals": @"ВИЗУАЛ",
        };
    });
    return gLanguage == 0 ? en[key] : ru[key];
}

// ============ ЗВУКИ ============
static void PlayToggleSound(BOOL isOn) {
    @try {
        SystemSoundID soundID = isOn ? 1103 : 1104;
        AudioServicesPlaySystemSound(soundID);
    } @catch (NSException *exception) {}
}

// ============ ЦВЕТА ТЕМЫ ============
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
@property(nonatomic,assign) BOOL introShown;
@property(nonatomic,strong) NSLayoutConstraint *menuLeadingConstraint;
@property(nonatomic,strong) NSLayoutConstraint *menuTopConstraint;
@property(nonatomic,strong) UIButton *launcherButton;
@property(nonatomic,assign) BOOL isDragging;
@property(nonatomic,strong) NSLayoutConstraint *leadingConstraint;
@property(nonatomic,strong) NSLayoutConstraint *topConstraint;
@end

@implementation Lucky77OverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = YES;
        self.introShown = NO;
        
        InitColors();
        [self loadConfig];
        
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

// ============ ОТРИСОВКА КРУГА FOV ============
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!gAimbot || gAimbotFOV <= 0) {
        return;
    }
    
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    CGFloat radius = gAimbotFOV / 2.0;
    CGFloat maxRadius = MIN(self.bounds.size.width, self.bounds.size.height) / 2.5;
    radius = MIN(radius, maxRadius);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = gFOVCircleColor ?: [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.3];
    
    CGContextSetFillColorWithColor(context, [color colorWithAlphaComponent:0.15].CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.5);
    
    CGFloat dashPattern[] = {4, 3};
    CGContextSetLineDash(context, 0, dashPattern, 2);
    
    CGRect circleRect = CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2);
    CGContextAddEllipseInRect(context, circleRect);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGFloat crossSize = 6;
    CGContextSetLineDash(context, 0, NULL, 0);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGContextMoveToPoint(context, center.x - crossSize, center.y);
    CGContextAddLineToPoint(context, center.x + crossSize, center.y);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, center.x, center.y - crossSize);
    CGContextAddLineToPoint(context, center.x, center.y + crossSize);
    CGContextStrokePath(context);
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
    pan.cancelsTouchesInView = NO;
    pan.delaysTouchesBegan = NO;
    pan.delaysTouchesEnded = NO;
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
        CGFloat buttonSize = 48.0;
        CGFloat margin = 4.0;
        CGFloat maxX = MAX(margin, CGRectGetWidth(self.bounds) - buttonSize - margin);
        CGFloat maxY = MAX(margin, CGRectGetHeight(self.bounds) - buttonSize - margin);
        CGFloat newX = self.leadingConstraint.constant + translation.x;
        CGFloat newY = self.topConstraint.constant + translation.y;
        newX = MAX(margin, MIN(newX, maxX));
        newY = MAX(margin, MIN(newY, maxY));
        self.leadingConstraint.constant = newX;
        self.topConstraint.constant = newY;
        [gesture setTranslation:CGPointZero inView:self];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled ||
               gesture.state == UIGestureRecognizerStateFailed) {
        self.isDragging = NO;
    }
}

// ============ ПРОПУСК КАСАНИЙ ============
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.launcherButton &&
        !self.launcherButton.hidden &&
        self.launcherButton.alpha > 0.01) {
        CGPoint launcherPoint = [self convertPoint:point toView:self.launcherButton];
        if ([self.launcherButton pointInside:launcherPoint withEvent:event]) {
            return [self.launcherButton hitTest:launcherPoint withEvent:event];
        }
    }
    if (self.menu &&
        !self.menu.hidden &&
        self.menu.alpha > 0.01) {
        CGPoint menuPoint = [self convertPoint:point toView:self.menu];
        if ([self.menu pointInside:menuPoint withEvent:event]) {
            return [self.menu hitTest:menuPoint withEvent:event];
        }
    }
    return nil;
}

// ============ МЕНЮ ============
- (void)buildMenu {
    self.menu = [UIView new];
    self.menu.translatesAutoresizingMaskIntoConstraints = NO;
    self.menu.backgroundColor = L77Background();
    self.menu.layer.cornerRadius = 16;
    self.menu.layer.borderWidth = 1;
    self.menu.layer.borderColor = L77Border().CGColor;
    self.menu.clipsToBounds = YES;
    self.menu.hidden = YES;
    self.menu.userInteractionEnabled = NO;
    
    [self addSubview:self.menu];
    
    self.menuLeadingConstraint = [self.menu.centerXAnchor constraintEqualToAnchor:self.centerXAnchor];
    self.menuTopConstraint = [self.menu.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-20];
    
    [NSLayoutConstraint activateConstraints:@[
        self.menuLeadingConstraint,
        self.menuTopConstraint,
        [self.menu.widthAnchor constraintEqualToConstant:420],
        [self.menu.heightAnchor constraintEqualToConstant:320]
    ]];
    
    UIPanGestureRecognizer *dragMenu = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
    dragMenu.cancelsTouchesInView = NO;
    [self.menu addGestureRecognizer:dragMenu];
    
    [self buildHeader];
    [self buildBody];
}

- (void)dragMenu:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        CGFloat newCenterX = self.menu.center.x + translation.x;
        CGFloat newCenterY = self.menu.center.y + translation.y;
        CGFloat halfWidth = 420 / 2;
        CGFloat halfHeight = 320 / 2;
        newCenterX = MAX(halfWidth, MIN(newCenterX, self.bounds.size.width - halfWidth));
        newCenterY = MAX(halfHeight + 20, MIN(newCenterY, self.bounds.size.height - halfHeight - 20));
        self.menuLeadingConstraint.constant = newCenterX - self.bounds.size.width / 2;
        self.menuTopConstraint.constant = newCenterY - self.bounds.size.height / 2 - 20;
        [gesture setTranslation:CGPointZero inView:self];
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
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    
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
        [header.heightAnchor constraintEqualToConstant:40],
        [self.fpsLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:14],
        [self.fpsLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [title.centerXAnchor constraintEqualToAnchor:header.centerXAnchor constant:-10],
        [title.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:6],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [closeBtn.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-14],
        [closeBtn.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [closeBtn.widthAnchor constraintEqualToConstant:32],
        [closeBtn.heightAnchor constraintEqualToConstant:32],
        [divider.leadingAnchor constraintEqualToAnchor:self.menu.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.menu.trailingAnchor],
        [divider.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [divider.heightAnchor constraintEqualToConstant:1]
    ]];
}

- (void)closeMenu {
    if (self.menu.hidden) return;
    [UIView animateWithDuration:0.18 animations:^{
        self.menu.alpha = 0.0;
        self.menu.transform = CGAffineTransformMakeScale(0.96, 0.96);
    } completion:^(BOOL finished) {
        self.menu.hidden = YES;
        self.menu.alpha = 1.0;
        self.menu.transform = CGAffineTransformIdentity;
        self.menu.userInteractionEnabled = NO;
        self.launcherButton.hidden = NO;
        self.launcherButton.userInteractionEnabled = YES;
        [self bringSubviewToFront:self.launcherButton];
    }];
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
    self.navStack.spacing = 6;
    [sidebar addSubview:self.navStack];
    
    NSArray *titles = @[@"AIMBOT", @"VISUALS", @"SETTINGS"];
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (NSInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = i;
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button setTitleColor:L77TextPrimary() forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        button.layer.cornerRadius = 6;
        if (i == 0) {
            button.backgroundColor = [L77Purple() colorWithAlphaComponent:0.30];
        }
        [button addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button.heightAnchor constraintEqualToConstant:40].active = YES;
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
        [sidebar.leadingAnchor constraintEqualToAnchor:self.menu.leadingAnchor constant:10],
        [sidebar.topAnchor constraintEqualToAnchor:self.menu.topAnchor constant:50],
        [sidebar.bottomAnchor constraintEqualToAnchor:self.menu.bottomAnchor constant:-10],
        [sidebar.widthAnchor constraintEqualToConstant:85],
        [self.navStack.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:6],
        [self.navStack.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-6],
        [self.navStack.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:6],
        [scroll.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:10],
        [scroll.trailingAnchor constraintEqualToAnchor:self.menu.trailingAnchor constant:-10],
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
        content = [self aimbotPanel];
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
    panel.layer.cornerRadius = 8;
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

// ============ AIMBOT PANEL ============
- (UIView *)aimbotPanel {
    UIView *panel = [UIView new];
    panel.backgroundColor = L77Panel();
    panel.layer.cornerRadius = 8;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = L77Border().CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    [panel addSubview:stack];
    
    UILabel *title = [UILabel new];
    title.text = @"AIMBOT SETTINGS";
    title.textColor = L77TextPrimary();
    title.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    [stack addArrangedSubview:title];
    
    L77Toggle *aimbotToggle = [[L77Toggle alloc] initWithTitle:@"ENABLE AIMBOT" key:@"aimbot"];
    [stack addArrangedSubview:aimbotToggle];
    
    L77Toggle *triggerToggle = [[L77Toggle alloc] initWithTitle:@"TRIGGERBOT" key:@"trigger"];
    [stack addArrangedSubview:triggerToggle];
    
    UILabel *targetLabel = [UILabel new];
    targetLabel.text = @"TARGET";
    targetLabel.textColor = L77TextSecondary();
    targetLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:targetLabel];
    
    UISegmentedControl *targetSegment = [[UISegmentedControl alloc] initWithItems:@[@"HEAD", @"NECK", @"BODY"]];
    targetSegment.selectedSegmentIndex = gAimbotTarget;
    targetSegment.tintColor = L77Purple();
    [targetSegment addTarget:self action:@selector(targetChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:targetSegment];
    
    UILabel *speedLabel = [UILabel new];
    speedLabel.text = @"SPEED";
    speedLabel.textColor = L77TextSecondary();
    speedLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:speedLabel];
    
    UISlider *speedSlider = [UISlider new];
    speedSlider.minimumValue = 0.5;
    speedSlider.maximumValue = 20.0;
    speedSlider.value = gAimbotSpeed;
    speedSlider.minimumTrackTintColor = L77Purple();
    speedSlider.maximumTrackTintColor = L77Border();
    [speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:speedSlider];
    
    UILabel *speedValueLabel = [UILabel new];
    speedValueLabel.text = [NSString stringWithFormat:@"%.1f", gAimbotSpeed];
    speedValueLabel.textColor = L77TextSecondary();
    speedValueLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    speedValueLabel.tag = 300;
    [stack addArrangedSubview:speedValueLabel];
    
    UILabel *sharpnessLabel = [UILabel new];
    sharpnessLabel.text = @"SHARPNESS";
    sharpnessLabel.textColor = L77TextSecondary();
    sharpnessLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:sharpnessLabel];
    
    UISlider *sharpnessSlider = [UISlider new];
    sharpnessSlider.minimumValue = 0.1;
    sharpnessSlider.maximumValue = 1.0;
    sharpnessSlider.value = gAimbotSharpness;
    sharpnessSlider.minimumTrackTintColor = L77Purple();
    sharpnessSlider.maximumTrackTintColor = L77Border();
    [sharpnessSlider addTarget:self action:@selector(sharpnessChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:sharpnessSlider];
    
    UILabel *sharpnessValueLabel = [UILabel new];
    sharpnessValueLabel.text = [NSString stringWithFormat:@"%.2f", gAimbotSharpness];
    sharpnessValueLabel.textColor = L77TextSecondary();
    sharpnessValueLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    sharpnessValueLabel.tag = 301;
    [stack addArrangedSubview:sharpnessValueLabel];
    
    L77Toggle *smoothToggle = [[L77Toggle alloc] initWithTitle:@"SMOOTH AIM" key:@"smooth"];
    [stack addArrangedSubview:smoothToggle];
    
    L77Toggle *visibleToggle = [[L77Toggle alloc] initWithTitle:@"VISIBLE CHECK" key:@"visible"];
    [stack addArrangedSubview:visibleToggle];
    
    UILabel *fovLabel = [UILabel new];
    fovLabel.text = @"AIM FOV";
    fovLabel.textColor = L77TextSecondary();
    fovLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:fovLabel];
    
    UISlider *fovSlider = [UISlider new];
    fovSlider.minimumValue = 0;
    fovSlider.maximumValue = 360;
    fovSlider.value = gAimbotFOV;
    fovSlider.minimumTrackTintColor = L77Purple();
    fovSlider.maximumTrackTintColor = L77Border();
    [fovSlider addTarget:self action:@selector(aimFOVChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:fovSlider];
    
    UILabel *fovValueLabel = [UILabel new];
    fovValueLabel.text = [NSString stringWithFormat:@"%.0f°", gAimbotFOV];
    fovValueLabel.textColor = L77TextSecondary();
    fovValueLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    fovValueLabel.tag = 400;
    [stack addArrangedSubview:fovValueLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-12]
    ]];
    
    return panel;
}

// ============ SETTINGS PANEL ============
- (UIView *)settingsPanel {
    UIView *panel = [UIView new];
    panel.backgroundColor = L77Panel();
    panel.layer.cornerRadius = 8;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = L77Border().CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    [panel addSubview:stack];
    
    UILabel *title = [UILabel new];
    title.text = L(@"settings");
    title.textColor = L77TextPrimary();
    title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [stack addArrangedSubview:title];
    
    // ЯЗЫК
    UILabel *langLabel = [UILabel new];
    langLabel.text = L(@"language");
    langLabel.textColor = L77TextSecondary();
    langLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:langLabel];
    
    UISegmentedControl *langSegment = [[UISegmentedControl alloc] initWithItems:@[@"English", @"Русский"]];
    langSegment.selectedSegmentIndex = gLanguage;
    langSegment.tintColor = L77Purple();
    [langSegment addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:langSegment];
    
    // ТЕМА
    UILabel *themeLabel = [UILabel new];
    themeLabel.text = L(@"theme");
    themeLabel.textColor = L77TextSecondary();
    themeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:themeLabel];
    
    UISegmentedControl *themeSegment = [[UISegmentedControl alloc] initWithItems:@[L(@"dark"), L(@"light")]];
    themeSegment.selectedSegmentIndex = gDarkTheme ? 0 : 1;
    themeSegment.tintColor = L77Purple();
    [themeSegment addTarget:self action:@selector(themeChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:themeSegment];
    
    // FPS
    UILabel *fpsLabel = [UILabel new];
    fpsLabel.text = L(@"fps_limit");
    fpsLabel.textColor = L77TextSecondary();
    fpsLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:fpsLabel];
    
    UISegmentedControl *fpsSegment = [[UISegmentedControl alloc] initWithItems:@[@"30", @"60", @"90", @"120"]];
    fpsSegment.selectedSegmentIndex = 1;
    fpsSegment.tintColor = L77Purple();
    [fpsSegment addTarget:self action:@selector(fpsLimitChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:fpsSegment];
    
    // ESP COLORS
    UILabel *espColorLabel = [UILabel new];
    espColorLabel.text = L(@"esp_colors");
    espColorLabel.textColor = L77TextSecondary();
    espColorLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:espColorLabel];
    
    UIStackView *visibleColorRow = [self colorRowWithTitle:L(@"visible_box") color:gESPBoxColorVisible tag:100];
    [stack addArrangedSubview:visibleColorRow];
    
    UIStackView *invisibleColorRow = [self colorRowWithTitle:L(@"invisible_box") color:gESPBoxColorInvisible tag:101];
    [stack addArrangedSubview:invisibleColorRow];
    
    UIStackView *linesColorRow = [self colorRowWithTitle:L(@"lines_color") color:gESPLinesColor tag:102];
    [stack addArrangedSubview:linesColorRow];
    
    UIStackView *fovColorRow = [self colorRowWithTitle:L(@"fov_color") color:gFOVCircleColor tag:103];
    [stack addArrangedSubview:fovColorRow];
    
    // КОНФИГ
    UILabel *configLabel = [UILabel new];
    configLabel.text = L(@"config");
    configLabel.textColor = L77TextSecondary();
    configLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:configLabel];
    
    UIStackView *configButtons = [UIStackView new];
    configButtons.axis = UILayoutConstraintAxisHorizontal;
    configButtons.spacing = 8;
    configButtons.distribution = UIStackViewDistributionFillEqually;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveBtn setTitle:L(@"save_config") forState:UIControlStateNormal];
    saveBtn.backgroundColor = L77Purple();
    saveBtn.layer.cornerRadius = 6;
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [saveBtn addTarget:self action:@selector(saveConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:saveBtn];
    
    UIButton *loadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadBtn setTitle:L(@"load_config") forState:UIControlStateNormal];
    loadBtn.backgroundColor = L77Purple();
    loadBtn.layer.cornerRadius = 6;
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadBtn.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [loadBtn addTarget:self action:@selector(loadConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:loadBtn];
    
    [stack addArrangedSubview:configButtons];
    
    // DEVELOPER
    UILabel *devLabel = [UILabel new];
    devLabel.text = L(@"developer");
    devLabel.textColor = L77TextSecondary();
    devLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [stack addArrangedSubview:devLabel];
    
    UIButton *devBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [devBtn setTitle:@"@hack77ios" forState:UIControlStateNormal];
    [devBtn setTitleColor:L77LightPurple() forState:UIControlStateNormal];
    devBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [devBtn addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:devBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-14],
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-12]
    ]];
    
    return panel;
}

// ============ COLOR ROW ============
- (UIStackView *)colorRowWithTitle:(NSString *)title color:(UIColor *)color tag:(NSInteger)tag {
    UIStackView *row = [UIStackView new];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 10;
    row.alignment = UIStackViewAlignmentCenter;
    row.distribution = UIStackViewDistributionFill;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel *label = [UILabel new];
    label.text = title;
    label.textColor = L77TextPrimary();
    label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [row addArrangedSubview:label];
    
    UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    colorBtn.backgroundColor = color ?: UIColor.whiteColor;
    colorBtn.layer.cornerRadius = 10;
    colorBtn.layer.borderWidth = 1;
    colorBtn.layer.borderColor = L77Border().CGColor;
    colorBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [colorBtn.widthAnchor constraintEqualToConstant:20].active = YES;
    [colorBtn.heightAnchor constraintEqualToConstant:20].active = YES;
    colorBtn.tag = tag;
    [colorBtn addTarget:self action:@selector(colorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [row addArrangedSubview:colorBtn];
    
    objc_setAssociatedObject(colorBtn, "color", color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return row;
}

// ============ ОБРАБОТЧИКИ ============
- (void)targetChanged:(UISegmentedControl *)sender {
    gAimbotTarget = sender.selectedSegmentIndex;
}

- (void)speedChanged:(UISlider *)sender {
    gAimbotSpeed = sender.value;
    UILabel *speedLabel = (UILabel *)[self viewWithTag:300];
    if (speedLabel) speedLabel.text = [NSString stringWithFormat:@"%.1f", gAimbotSpeed];
}

- (void)sharpnessChanged:(UISlider *)sender {
    gAimbotSharpness = sender.value;
    UILabel *sharpnessLabel = (UILabel *)[self viewWithTag:301];
    if (sharpnessLabel) sharpnessLabel.text = [NSString stringWithFormat:@"%.2f", gAimbotSharpness];
}

- (void)aimFOVChanged:(UISlider *)sender {
    gAimbotFOV = sender.value;
    UILabel *fovValueLabel = (UILabel *)[self viewWithTag:400];
    if (fovValueLabel) fovValueLabel.text = [NSString stringWithFormat:@"%.0f°", gAimbotFOV];
    [self setNeedsDisplay];
}

- (void)colorButtonTapped:(UIButton *)sender {
    NSInteger tag = sender.tag;
    
    NSArray *colors = @[
        @{@"name": @"Red", @"color": [UIColor redColor]},
        @{@"name": @"Green", @"color": [UIColor greenColor]},
        @{@"name": @"Blue", @"color": [UIColor blueColor]},
        @{@"name": @"Yellow", @"color": [UIColor yellowColor]},
        @{@"name": @"Orange", @"color": [UIColor orangeColor]},
        @{@"name": @"Purple", @"color": [UIColor purpleColor]},
        @{@"name": @"Cyan", @"color": [UIColor cyanColor]},
        @{@"name": @"White", @"color": [UIColor whiteColor]},
        @{@"name": @"Black", @"color": [UIColor blackColor]},
    ];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Color" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSDictionary *item in colors) {
        UIColor *color = item[@"color"];
        NSString *name = item[@"name"];
        [alert addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            sender.backgroundColor = color;
            objc_setAssociatedObject(sender, "color", color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (tag == 100) gESPBoxColorVisible = color;
            else if (tag == 101) gESPBoxColorInvisible = color;
            else if (tag == 102) gESPLinesColor = color;
            else if (tag == 103) gFOVCircleColor = [color colorWithAlphaComponent:0.3];
            [self setNeedsDisplay];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIViewController *rootVC = [self window].rootViewController;
    if (rootVC) [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)languageChanged:(UISegmentedControl *)sender {
    gLanguage = sender.selectedSegmentIndex;
    [self refreshSettingsTab];
}

- (void)refreshSettingsTab {
    // Обновляем заголовки вкладок
    NSArray *titles = @[@"AIMBOT", @"VISUALS", @"SETTINGS"];
    for (NSInteger i = 0; i < self.navButtons.count && i < titles.count; i++) {
        UIButton *btn = self.navButtons[i];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
    }
    [self showTab:2];
}

- (void)themeChanged:(UISegmentedControl *)sender {
    gDarkTheme = (sender.selectedSegmentIndex == 0);
    [self rebuildUI];
}

- (void)rebuildUI {
    CGPoint oldCenter = self.menu.center;
    BOOL wasVisible = !self.menu.hidden;
    
    [self.menu removeFromSuperview];
    self.menu = nil;
    [self.contentStack removeFromSuperview];
    self.contentStack = nil;
    [self.navStack removeFromSuperview];
    self.navStack = nil;
    
    [self buildMenu];
    
    if (wasVisible) {
        self.menu.center = oldCenter;
        self.menu.hidden = NO;
        self.menu.alpha = 1.0;
        self.menu.userInteractionEnabled = YES;
    }
    [self setNeedsDisplay];
}

- (void)fpsLimitChanged:(UISegmentedControl *)sender {
    NSArray *values = @[@30, @60, @90, @120];
    gFPSLimit = [values[sender.selectedSegmentIndex] integerValue];
    self.displayLink.preferredFramesPerSecond = gFPSLimit;
}

// ============ КОНФИГ ============
- (void)saveConfig {
    NSDictionary *config = @{
        @"aimbot": @(gAimbot),
        @"trigger": @(gTriggerbot),
        @"esp": @(gESP),
        @"radar": @(gRadar),
        @"recoil": @(gNoRecoil),
        @"ammo": @(gUnlimitedAmmo),
        @"fps": @(gFPSLimit),
        @"darkTheme": @(gDarkTheme),
        @"language": @(gLanguage),
        @"aimbotSpeed": @(gAimbotSpeed),
        @"aimbotSharpness": @(gAimbotSharpness),
        @"aimbotTarget": @(gAimbotTarget),
        @"aimbotFOV": @(gAimbotFOV),
    };
    [config writeToFile:GetConfigPath() atomically:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅" message:L(@"saved") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = [self window].rootViewController;
    if (rootVC) [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)loadConfig {
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:GetConfigPath()];
    if (!config) return;
    
    if (config[@"aimbot"]) gAimbot = [config[@"aimbot"] boolValue];
    if (config[@"trigger"]) gTriggerbot = [config[@"trigger"] boolValue];
    if (config[@"esp"]) gESP = [config[@"esp"] boolValue];
    if (config[@"radar"]) gRadar = [config[@"radar"] boolValue];
    if (config[@"recoil"]) gNoRecoil = [config[@"recoil"] boolValue];
    if (config[@"ammo"]) gUnlimitedAmmo = [config[@"ammo"] boolValue];
    if (config[@"fps"]) gFPSLimit = [config[@"fps"] integerValue];
    if (config[@"darkTheme"]) gDarkTheme = [config[@"darkTheme"] boolValue];
    if (config[@"language"]) gLanguage = [config[@"language"] integerValue];
    if (config[@"aimbotSpeed"]) gAimbotSpeed = [config[@"aimbotSpeed"] floatValue];
    if (config[@"aimbotSharpness"]) gAimbotSharpness = [config[@"aimbotSharpness"] floatValue];
    if (config[@"aimbotTarget"]) gAimbotTarget = [config[@"aimbotTarget"] integerValue];
    if (config[@"aimbotFOV"]) gAimbotFOV = [config[@"aimbotFOV"] floatValue];
    [self setNeedsDisplay];
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

// ============ INTRO ============
- (void)buildIntro {
    self.intro = [UIView new];
    self.intro.translatesAutoresizingMaskIntoConstraints = NO;
    self.intro.backgroundColor = L77Background();
    self.intro.layer.cornerRadius = 22;
    self.intro.hidden = YES;
    self.intro.userInteractionEnabled = NO;
    [self addSubview:self.intro];
    
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
        [self.intro.widthAnchor constraintEqualToConstant:280],
        [self.intro.heightAnchor constraintEqualToConstant:250],
        [logo.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [logo.topAnchor constraintEqualToAnchor:self.intro.topAnchor constant:30],
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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

// ============ УПРАВЛЕНИЕ МЕНЮ ============
- (void)toggleMenu {
    if (!self.menu.hidden) {
        [self closeMenu];
        return;
    }
    self.launcherButton.userInteractionEnabled = NO;
    [self showIntroWithCompletion:^{
        self.menu.hidden = NO;
        self.menu.alpha = 0.0;
        self.menu.userInteractionEnabled = YES;
        self.menu.transform = CGAffineTransformMakeScale(0.94, 0.94);
        self.launcherButton.hidden = YES;
        [UIView animateWithDuration:0.25 animations:^{
            self.menu.alpha = 1.0;
            self.menu.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.launcherButton.userInteractionEnabled = YES;
            [self setNeedsDisplay];
        }];
    }];
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
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            mainWindow = UIApplication.sharedApplication.keyWindow;
            #pragma clang diagnostic pop
        }
        
        if (!mainWindow) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            mainWindow = UIApplication.sharedApplication.windows.firstObject;
            #pragma clang diagnostic pop
        }
        
        if (mainWindow) {
            ShowLucky77Overlay(mainWindow);
        } else {
            NSLog(@"[Lucky77] ❌ No window found");
        }
    });
}
