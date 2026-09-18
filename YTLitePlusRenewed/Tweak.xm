#import <YTScript/YTScriptRuntime.h>
#import <objc/NSObjCRuntime.h>

@class YTIPivotBarRenderer;
@class YTBrowseViewController;
@class FlappyBirdViewController;

YT_PAGE("YTLitePlusRenewed")
YT_ICON("slider.horizontal.3")
YT_SECTION(@"Flappy Bird")
YT_SECTION_ICON(@"bird.fill")

YT_TOGGLE("Enable Flappy Bird", "This is a recreation of the OG game Flappy Bird which was played by billions ,maybe played in their earliest childhood. This game has 5 custom themes and the default one is the classic one. U can play this game as much as u want and the game is accessible from the YouTube Tab Bar. It has its own icon whatsoever. APP RESTART IS REQUIRED. Happy playing!🎮", NO)

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <YouTubeHeader/YTIIcon.h>


static BOOL kEnabledFlappy = YES;
static NSString * const kFlappyPivotID = @"FEFLAPPYBIRD";
static NSString * const kFlappyBestScoreKey = @"FEFlappyBirdBestScore";
static NSString * const kFlappyThemeKey = @"FEFlappyBirdTheme";
typedef NS_ENUM(NSInteger, FlappyTheme) {
    FlappyThemeClassic = 0,
    FlappyThemeStarryNight,
    FlappyThemeSunset,
    FlappyThemeForest,
    FlappyThemeOcean
};
// ============================================================
// YOUTUBE CLASS DECLARATIONS
// ============================================================

@class YTICommand;

@interface YTIPivotBarItemRenderer : NSObject
@property(nonatomic, copy) NSString *pivotIdentifier;
@property(nonatomic, strong) YTIIcon *icon;
@property(nonatomic, strong) YTICommand *navigationEndpoint;
@end
@interface YTIPivotBarSupportedRenderers : NSObject
@property(nonatomic, strong) YTIPivotBarItemRenderer *pivotBarItemRenderer;
@end
@interface YTIPivotBarRenderer : NSObject
@property(nonatomic, strong) NSMutableArray<YTIPivotBarSupportedRenderers *> *itemsArray;
+ (YTIPivotBarSupportedRenderers *)pivotSupportedRenderersWithBrowseId:(NSString *)browseID
                                                                 title:(NSString *)title
                                                              iconType:(int)iconType;
@end
@interface YTPivotBarView : UIView
- (void)selectItemWithPivotIdentifier:(id)pivotIdentifier;
@end
@interface YTPivotBarViewController : UIViewController
@property(nonatomic, copy) NSString *selectedPivotIdentifier;
- (void)selectItemWithPivotIdentifier:(id)pivotIdentifier;
- (YTPivotBarView *)pivotBarView;
@end

@class YTIBrowseEndpoint;

@interface YTICommand : NSObject
@property(nonatomic, strong) YTIBrowseEndpoint *browseEndpoint;
+ (id)watchNavigationEndpointWithVideoID:(NSString *)videoID;
@end

@interface YTIBrowseEndpoint : NSObject
@property(nonatomic, copy) NSString *browseId;
@end

@interface YTBrowseViewController : UIViewController
@end
// ============================================================
// COLOR UTILITIES
// ============================================================
static inline UIColor *FBColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}
static inline UIColor *FBSkyColor(FlappyTheme theme) {
    switch (theme) {
        case FlappyThemeStarryNight:
            return FBColor(0.04, 0.06, 0.14, 1.0);
        case FlappyThemeSunset:
            return FBColor(0.92, 0.44, 0.22, 1.0);
        case FlappyThemeForest:
            return FBColor(0.14, 0.32, 0.22, 1.0);
        case FlappyThemeOcean:
            return FBColor(0.06, 0.38, 0.62, 1.0);
        case FlappyThemeClassic:
        default:
            return FBColor(0.38, 0.75, 0.95, 1.0);
    }
}
// ============================================================
// PIPE MODEL
// ============================================================
@interface FlappyPipePair : NSObject
@property(nonatomic, assign) CGFloat x;
@property(nonatomic, assign) CGFloat gapY;
@property(nonatomic, assign) BOOL scored;
@end
@implementation FlappyPipePair
@end
// ============================================================
// GAME ENGINE
// ============================================================
@interface FlappyBirdGame : NSObject
@property(nonatomic, assign) CGFloat birdY;
@property(nonatomic, assign) CGFloat velocityY;
@property(nonatomic, assign) CGFloat gravity;
@property(nonatomic, assign) CGFloat flapVelocity;
@property(nonatomic, assign) CGFloat pipeSpeed;
@property(nonatomic, assign) CGFloat pipeWidth;
@property(nonatomic, assign) CGFloat pipeGap;
@property(nonatomic, assign) CGFloat groundHeight;
@property(nonatomic, assign) NSInteger score;
@property(nonatomic, assign) NSInteger bestScore;
@property(nonatomic, assign) BOOL started;
@property(nonatomic, assign) BOOL paused;
@property(nonatomic, assign) BOOL gameOver;
@property(nonatomic, assign) CGFloat worldWidth;
@property(nonatomic, assign) CGFloat worldHeight;
@property(nonatomic, strong) NSMutableArray<FlappyPipePair *> *pipes;
- (void)resetWithSize:(CGSize)size;
- (void)updateWorldSize:(CGSize)size;
- (void)flap;
- (void)update:(CGFloat)dt;
@end
@implementation FlappyBirdGame
- (instancetype)init {
    self = [super init];
    if (self) {
        _gravity = 1450.0;
        _flapVelocity = -460.0;
        _pipeSpeed = 230.0;
        _pipeWidth = 68.0;
        _pipeGap = 170.0;
        _groundHeight = 70.0;
        _pipes = [NSMutableArray array];
        _bestScore = [[NSUserDefaults standardUserDefaults] integerForKey:kFlappyBestScoreKey];
    }
    return self;
}
- (CGFloat)pipeSpacing {
    return 230.0;
}
- (CGFloat)randomGapY {
    CGFloat minY = 100.0;
    CGFloat maxY = self.worldHeight - self.groundHeight - 100.0;
    if (maxY < minY) {
        maxY = minY;
    }
    return minY + ((CGFloat)arc4random_uniform(10000) / 10000.0) * (maxY - minY);
}
- (FlappyPipePair *)newPipeAtX:(CGFloat)x {
    FlappyPipePair *pipe = [FlappyPipePair new];
    pipe.x = x;
    pipe.gapY = [self randomGapY];
    pipe.scored = NO;
    return pipe;
}
- (void)ensurePipesPopulated {
    if (self.worldWidth <= 0.0 || self.worldHeight <= 0.0) {
        return;
    }
    CGFloat spacing = [self pipeSpacing];
    CGFloat minRightX = self.worldWidth + spacing * 1.5;
    if (self.pipes.count == 0) {
        // Avoid long initial delays on iPad/wide displays
        CGFloat firstX = (self.worldWidth < 500.0) ? (self.worldWidth + 60.0) : 460.0;
        [self.pipes addObject:[self newPipeAtX:firstX]];
    }
    while (self.pipes.count > 0) {
        FlappyPipePair *last = self.pipes.lastObject;
        if (last.x < minRightX) {
            [self.pipes addObject:[self newPipeAtX:last.x + spacing]];
        } else {
            break;
        }
    }
}
- (void)resetWithSize:(CGSize)size {
    self.worldWidth = size.width;
    self.worldHeight = size.height;
    self.score = 0;
    self.started = NO;
    self.paused = NO;
    self.gameOver = NO;
    self.velocityY = 0.0;
    self.birdY = (size.height > 0.0) ? (size.height * 0.42) : 200.0;
    [self.pipes removeAllObjects];
    [self ensurePipesPopulated];
}
- (void)updateWorldSize:(CGSize)size {
    if (size.width <= 0.0 || size.height <= 0.0) {
        return;
    }
    self.worldWidth = size.width;
    self.worldHeight = size.height;
    [self ensurePipesPopulated];
}
- (void)flap {
    if (self.gameOver) {
        [self resetWithSize:CGSizeMake(self.worldWidth, self.worldHeight)];
        self.started = YES;
    } else if (!self.started) {
        self.started = YES;
    }
    if (self.paused) {
        return;
    }
    self.velocityY = self.flapVelocity;
}
- (void)update:(CGFloat)dt {
    if (!self.started || self.paused || self.gameOver) {
        return;
    }
    self.velocityY += self.gravity * dt;
    self.birdY += self.velocityY * dt;
    CGFloat birdX = 90.0;
    CGFloat birdRadius = 14.0;
    CGFloat groundY = self.worldHeight - self.groundHeight;
    // Ceiling & Ground Collisions
    if (self.birdY - birdRadius <= 0.0) {
        self.birdY = birdRadius;
        self.gameOver = YES;
    }
    if (self.birdY + birdRadius >= groundY) {
        self.birdY = groundY - birdRadius;
        self.gameOver = YES;
    }
    // Bird bounding box (including beak)
    CGRect birdRect = CGRectMake(birdX - birdRadius, self.birdY - birdRadius, birdRadius * 2.0 + 8.0, birdRadius * 2.0);
    for (FlappyPipePair *pipe in self.pipes) {
        pipe.x -= self.pipeSpeed * dt;
        if (!pipe.scored && pipe.x + self.pipeWidth < birdX) {
            pipe.scored = YES;
            self.score++;
            if (self.score > self.bestScore) {
                self.bestScore = self.score;
                [[NSUserDefaults standardUserDefaults] setInteger:self.bestScore forKey:kFlappyBestScoreKey];
            }
        }
        CGFloat topHeight = pipe.gapY - self.pipeGap * 0.5;
        CGFloat bottomY = pipe.gapY + self.pipeGap * 0.5;
        CGFloat bottomHeight = groundY - bottomY;
        // Accurate collision bounds matching visible graphics
        CGRect topShaft = CGRectMake(pipe.x, 0.0, self.pipeWidth, MAX(0.0, topHeight - 18.0));
        CGRect bottomShaft = CGRectMake(pipe.x, bottomY + 18.0, self.pipeWidth, MAX(0.0, bottomHeight - 18.0));
        CGRect topCap = CGRectMake(pipe.x - 5.0, MAX(0.0, topHeight - 18.0), self.pipeWidth + 10.0, 18.0);
        CGRect bottomCap = CGRectMake(pipe.x - 5.0, bottomY, self.pipeWidth + 10.0, 18.0);
        if (CGRectIntersectsRect(birdRect, topShaft) ||
            CGRectIntersectsRect(birdRect, bottomShaft) ||
            CGRectIntersectsRect(birdRect, topCap) ||
            CGRectIntersectsRect(birdRect, bottomCap)) {
            self.gameOver = YES;
        }
    }
    // Recycle pipes moving offscreen left
    CGFloat spacing = [self pipeSpacing];
    while (self.pipes.count > 0) {
        FlappyPipePair *first = self.pipes.firstObject;
        if (first.x + self.pipeWidth < -80.0) {
            FlappyPipePair *last = self.pipes.lastObject;
            CGFloat newX = last.x + spacing;
            [self.pipes removeObjectAtIndex:0];
            [self.pipes addObject:[self newPipeAtX:newX]];
        } else {
            break;
        }
    }
    // Ensure continuous buffer on the right
    [self ensurePipesPopulated];
}
@end
// ============================================================
// GAME VIEW
// ============================================================
@interface FlappyBirdGameView : UIView
@property(nonatomic, strong) FlappyBirdGame *game;
@property(nonatomic, assign) FlappyTheme theme;
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) CFTimeInterval lastFrameTime;
@property(nonatomic, strong) UIButton *themeButton;
@property(nonatomic, strong) UIButton *pauseButton;
@property(nonatomic, strong) UIButton *restartButton;
@property(nonatomic, strong) UILabel *scoreLabel;
@property(nonatomic, strong) UILabel *bestLabel;
@property(nonatomic, strong) UILabel *messageLabel;
- (void)startGameLoop;
- (void)stopGameLoop;
@end
@implementation FlappyBirdGameView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.blackColor;
        self.layer.drawsAsynchronously = YES;
        _game = [FlappyBirdGame new];
        NSInteger savedTheme = [[NSUserDefaults standardUserDefaults] integerForKey:kFlappyThemeKey];
        if (savedTheme < FlappyThemeClassic || savedTheme > FlappyThemeOcean) {
            savedTheme = FlappyThemeClassic;
        }
        _theme = (FlappyTheme)savedTheme;
        [self setupControls];
    }
    return self;
}
- (void)setupControls {
    self.scoreLabel = [[UILabel alloc] init];
    self.scoreLabel.textColor = UIColor.whiteColor;
    self.scoreLabel.font = [UIFont boldSystemFontOfSize:34.0];
    self.scoreLabel.textAlignment = NSTextAlignmentCenter;
    self.scoreLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.scoreLabel.layer.shadowOpacity = 0.5;
    self.scoreLabel.layer.shadowRadius = 2.0;
    self.scoreLabel.layer.shadowOffset = CGSizeMake(0, 1);
    [self addSubview:self.scoreLabel];
    self.bestLabel = [[UILabel alloc] init];
    self.bestLabel.textColor = UIColor.whiteColor;
    self.bestLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    self.bestLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.bestLabel];
    self.themeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.themeButton.backgroundColor = FBColor(0, 0, 0, 0.35);
    self.themeButton.layer.cornerRadius = 21.0;
    self.themeButton.tintColor = UIColor.whiteColor;
    [self.themeButton setTitle:@"🎨" forState:UIControlStateNormal];
    self.themeButton.titleLabel.font = [UIFont systemFontOfSize:19.0];
    [self.themeButton addTarget:self action:@selector(cycleTheme) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.themeButton];
    self.pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pauseButton.backgroundColor = FBColor(0, 0, 0, 0.35);
    self.pauseButton.layer.cornerRadius = 21.0;
    self.pauseButton.tintColor = UIColor.whiteColor;
    [self.pauseButton setTitle:@"⏸" forState:UIControlStateNormal];
    self.pauseButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [self.pauseButton addTarget:self action:@selector(togglePause) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.pauseButton];
    self.restartButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.restartButton.backgroundColor = FBColor(0, 0, 0, 0.35);
    self.restartButton.layer.cornerRadius = 21.0;
    self.restartButton.tintColor = UIColor.whiteColor;
    [self.restartButton setTitle:@"↻" forState:UIControlStateNormal];
    self.restartButton.titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
    [self.restartButton addTarget:self action:@selector(restartGame) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.restartButton];
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.textColor = UIColor.whiteColor;
    self.messageLabel.font = [UIFont boldSystemFontOfSize:24.0];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.messageLabel.layer.shadowOpacity = 0.6;
    self.messageLabel.layer.shadowRadius = 3.0;
    self.messageLabel.layer.shadowOffset = CGSizeMake(0, 2);
    [self addSubview:self.messageLabel];
}
- (void)updateControls {
    self.scoreLabel.text = [NSString stringWithFormat:@"%ld", (long)self.game.score];
    self.bestLabel.text = [NSString stringWithFormat:@"BEST %ld", (long)self.game.bestScore];
    NSString *pauseTitle = (self.game.paused || !self.game.started) ? @"▶︎" : @"⏸";
    [self.pauseButton setTitle:pauseTitle forState:UIControlStateNormal];
    if (self.game.gameOver) {
        self.messageLabel.text = [NSString stringWithFormat:@"GAME OVER\nScore: %ld", (long)self.game.score];
    } else if (!self.game.started) {
        self.messageLabel.text = @"TAP TO FLAP";
    } else if (self.game.paused) {
        self.messageLabel.text = @"PAUSED";
    } else {
        self.messageLabel.text = @"";
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    if (width <= 0.0 || height <= 0.0) {
        return;
    }
    // Safe area insets for all edges (Dynamic Island, notch, landscape side insets)
    CGFloat topInset = 16.0;
    CGFloat leftInset = 16.0;
    CGFloat rightInset = 16.0;
    if (@available(iOS 11.0, *)) {
        topInset = MAX(16.0, self.safeAreaInsets.top + 8.0);
        leftInset = MAX(16.0, self.safeAreaInsets.left + 8.0);
        rightInset = MAX(16.0, self.safeAreaInsets.right + 8.0);
    }
    self.themeButton.frame = CGRectMake(leftInset, topInset, 42.0, 42.0);
    self.pauseButton.frame = CGRectMake(width - rightInset - 90.0, topInset, 42.0, 42.0);
    self.restartButton.frame = CGRectMake(width - rightInset - 42.0, topInset, 42.0, 42.0);
    CGFloat scoreLabelX = leftInset + 48.0;
    CGFloat scoreLabelWidth = width - scoreLabelX - rightInset - 96.0;
    if (scoreLabelWidth < 60.0) {
        scoreLabelWidth = 60.0;
    }
    self.scoreLabel.frame = CGRectMake(scoreLabelX, topInset - 4.0, scoreLabelWidth, 36.0);
    self.bestLabel.frame = CGRectMake(scoreLabelX, topInset + 32.0, scoreLabelWidth, 18.0);
    self.messageLabel.frame = CGRectMake(30.0, height * 0.38, width - 60.0, 100.0);
    if (self.game.worldWidth <= 0.0 || self.game.worldHeight <= 0.0) {
        [self.game resetWithSize:self.bounds.size];
        [self updateControls];
        [self setNeedsDisplay];
    } else if (fabs(self.game.worldWidth - width) > 1.0 || fabs(self.game.worldHeight - height) > 1.0) {
        [self.game updateWorldSize:self.bounds.size];
        [self setNeedsDisplay];
    }
}
- (void)startGameLoop {
    [self stopGameLoop];
    if (!kEnabledFlappy) {
        return;
    }
    CGSize size = self.bounds.size;
    if (size.width > 0.0 && size.height > 0.0) {
        if (self.game.worldWidth <= 0.0 || self.game.worldHeight <= 0.0) {
            [self.game resetWithSize:size];
        }
    }
    [self updateControls];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(frameTick:)];
    if (@available(iOS 15.0, *)) {
        self.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(60, 60, 60);
    } else {
        self.displayLink.preferredFramesPerSecond = 60;
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.lastFrameTime = CACurrentMediaTime();
    [self setNeedsDisplay];
}
- (void)stopGameLoop {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}
- (void)frameTick:(CADisplayLink *)link {
    if (!kEnabledFlappy || self.hidden || (self.window == nil)) {
        [self stopGameLoop];
        return;
    }
    CFTimeInterval now = CACurrentMediaTime();
    CGFloat dt = (CGFloat)(now - self.lastFrameTime);
    self.lastFrameTime = now;
    dt = MIN(dt, 0.05);
    [self.game update:dt];
    [self updateControls];
    [self setNeedsDisplay];
}
- (void)cycleTheme {
    self.theme = (FlappyTheme)((self.theme + 1) % 5);
    [[NSUserDefaults standardUserDefaults] setInteger:self.theme forKey:kFlappyThemeKey];
    [self setNeedsDisplay];
}
- (void)togglePause {
    if (self.game.gameOver || !self.game.started) {
        return;
    }
    self.game.paused = !self.game.paused;
    self.lastFrameTime = CACurrentMediaTime();
    [self updateControls];
    [self setNeedsDisplay];
}
- (void)restartGame {
    if (self.bounds.size.width <= 0.0 || self.bounds.size.height <= 0.0) {
        return;
    }
    [self.game resetWithSize:self.bounds.size];
    self.lastFrameTime = CACurrentMediaTime();
    [self updateControls];
    [self setNeedsDisplay];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!kEnabledFlappy) {
        return;
    }
    UITouch *touch = touches.anyObject;
    if (!touch) {
        return;
    }
    CGPoint loc = [touch locationInView:self];
    if (CGRectContainsPoint(self.themeButton.frame, loc) ||
        CGRectContainsPoint(self.pauseButton.frame, loc) ||
        CGRectContainsPoint(self.restartButton.frame, loc)) {
        return;
    }
    if (self.game.paused) {
        return;
    }
    [self.game flap];
    [self updateControls];
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        return;
    }
    CGSize size = self.bounds.size;
    if (size.width <= 0.0 || size.height <= 0.0) {
        return;
    }
    // Sky
    CGContextSetFillColorWithColor(ctx, FBSkyColor(self.theme).CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
    // Theme Background Decorations
    [self drawThemeDecoration:ctx size:size];
    CGFloat groundY = size.height - self.game.groundHeight;
    // Pipes
    UIColor *pipeColor = FBColor(0.18, 0.72, 0.20, 1.0);
    UIColor *pipeHighlight = FBColor(0.35, 0.90, 0.30, 1.0);
    for (FlappyPipePair *pipe in self.game.pipes) {
        CGFloat topHeight = pipe.gapY - self.game.pipeGap * 0.5;
        CGFloat bottomY = pipe.gapY + self.game.pipeGap * 0.5;
        CGFloat bottomHeight = groundY - bottomY;
        CGRect topShaft = CGRectMake(pipe.x, 0, self.game.pipeWidth, MAX(0, topHeight - 18.0));
        CGRect bottomShaft = CGRectMake(pipe.x, bottomY + 18.0, self.game.pipeWidth, MAX(0, bottomHeight - 18.0));
        CGRect topCap = CGRectMake(pipe.x - 5.0, MAX(0, topHeight - 18.0), self.game.pipeWidth + 10.0, 18.0);
        CGRect bottomCap = CGRectMake(pipe.x - 5.0, bottomY, self.game.pipeWidth + 10.0, 18.0);
        CGContextSetFillColorWithColor(ctx, pipeColor.CGColor);
        CGContextFillRect(ctx, topShaft);
        CGContextFillRect(ctx, bottomShaft);
        CGContextFillRect(ctx, topCap);
        CGContextFillRect(ctx, bottomCap);
        // Pipe Highlights
        CGContextSetFillColorWithColor(ctx, pipeHighlight.CGColor);
        CGContextFillRect(ctx, CGRectMake(pipe.x + 6.0, 0, 6.0, MAX(0, topHeight - 18.0)));
        CGContextFillRect(ctx, CGRectMake(pipe.x + 6.0, bottomY + 18.0, 6.0, MAX(0, bottomHeight - 18.0)));
    }
    // Ground
    UIColor *ground = (self.theme == FlappyThemeStarryNight) ? FBColor(0.12, 0.10, 0.08, 1.0) : FBColor(0.73, 0.53, 0.25, 1.0);
    CGContextSetFillColorWithColor(ctx, ground.CGColor);
    CGContextFillRect(ctx, CGRectMake(0, groundY, size.width, self.game.groundHeight));
    CGContextSetFillColorWithColor(ctx, FBColor(0.30, 0.78, 0.25, 1.0).CGColor);
    CGContextFillRect(ctx, CGRectMake(0, groundY, size.width, 9.0));
    // Bird
    CGFloat birdX = 90.0;
    CGFloat birdR = 15.0;
    CGPoint bird = CGPointMake(birdX, self.game.birdY);
    // Body
    CGContextSetFillColorWithColor(ctx, FBColor(1.0, 0.82, 0.05, 1.0).CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(bird.x - birdR, bird.y - birdR, birdR * 2.0, birdR * 2.0));
    // Wing
    CGContextSetFillColorWithColor(ctx, FBColor(0.95, 0.62, 0.02, 1.0).CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(bird.x - 12.0, bird.y + 1.0, 13.0, 9.0));
    // Eye
    CGContextSetFillColorWithColor(ctx, UIColor.whiteColor.CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(bird.x + 3.0, bird.y - 8.0, 8.0, 8.0));
    CGContextSetFillColorWithColor(ctx, UIColor.blackColor.CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(bird.x + 6.0, bird.y - 6.0, 4.0, 4.0));
    // Beak
    CGContextSetFillColorWithColor(ctx, FBColor(0.95, 0.45, 0.05, 1.0).CGColor);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, bird.x + 14.0, bird.y - 2.0);
    CGContextAddLineToPoint(ctx, bird.x + 23.0, bird.y + 3.0);
    CGContextAddLineToPoint(ctx, bird.x + 14.0, bird.y + 7.0);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}
- (void)drawThemeDecoration:(CGContextRef)ctx size:(CGSize)size {
    switch (self.theme) {
        case FlappyThemeClassic: {
            CGContextSetFillColorWithColor(ctx, FBColor(1, 1, 1, 0.65).CGColor);
            for (NSInteger i = 0; i < 4; i++) {
                CGFloat x = 40.0 + i * 180.0;
                CGFloat y = 100.0 + (i % 2) * 80.0;
                CGContextFillEllipseInRect(ctx, CGRectMake(x, y, 65.0, 28.0));
                CGContextFillEllipseInRect(ctx, CGRectMake(x + 20.0, y - 14.0, 45.0, 42.0));
            }
            break;
        }
        case FlappyThemeStarryNight: {
            // Crescent Moon
            CGContextSetFillColorWithColor(ctx, FBColor(1.0, 0.93, 0.65, 1.0).CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(size.width - 95.0, 60.0, 50.0, 50.0));
            CGContextSetFillColorWithColor(ctx, FBSkyColor(FlappyThemeStarryNight).CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(size.width - 80.0, 52.0, 50.0, 50.0));
            // Stars
            CGContextSetFillColorWithColor(ctx, UIColor.whiteColor.CGColor);
            for (NSInteger i = 0; i < 35; i++) {
                CGFloat x = fmod((CGFloat)(i * 83 + 31), MAX(1.0, size.width));
                CGFloat y = fmod((CGFloat)(i * 47 + 23), MAX(1.0, size.height * 0.65));
                CGFloat r = (i % 3 == 0) ? 2.0 : 1.0;
                CGContextFillEllipseInRect(ctx, CGRectMake(x, y, r, r));
            }
            break;
        }
        case FlappyThemeSunset: {
            CGContextSetFillColorWithColor(ctx, FBColor(1.0, 0.84, 0.25, 0.90).CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(size.width * 0.5 - 40.0, size.height * 0.28, 80.0, 80.0));
            break;
        }
        case FlappyThemeForest: {
            CGContextSetFillColorWithColor(ctx, FBColor(0.06, 0.22, 0.12, 0.60).CGColor);
            CGFloat base = size.height - self.game.groundHeight;
            for (NSInteger i = 0; i < 12; i++) {
                CGFloat x = i * 85.0 - 20.0;
                CGFloat h = 100.0 + (i % 3) * 30.0;
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, x, base);
                CGContextAddLineToPoint(ctx, x + 42.0, base - h);
                CGContextAddLineToPoint(ctx, x + 85.0, base);
                CGContextClosePath(ctx);
                CGContextFillPath(ctx);
            }
            break;
        }
        case FlappyThemeOcean: {
            CGContextSetStrokeColorWithColor(ctx, FBColor(1, 1, 1, 0.25).CGColor);
            CGContextSetLineWidth(ctx, 2.0);
            for (NSInteger i = 0; i < 10; i++) {
                CGFloat x = fmod((CGFloat)(i * 91), MAX(1.0, size.width));
                CGFloat y = 90.0 + (i % 5) * 55.0;
                CGContextStrokeEllipseInRect(ctx, CGRectMake(x, y, 9.0, 9.0));
            }
            break;
        }
    }
}
@end
// ============================================================
// GAME VIEW CONTROLLER
// ============================================================
@interface FlappyBirdViewController : UIViewController
@property(nonatomic, strong) FlappyBirdGameView *gameView;
@property(nonatomic, weak) YTPivotBarViewController *pivotController;
@end
@implementation FlappyBirdViewController
- (void)loadView {
    self.gameView = [[FlappyBirdGameView alloc] initWithFrame:CGRectZero];
    self.view = self.gameView;
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.pivotController && self.view.superview) {
        CGFloat barHeight = self.pivotController.view.frame.size.height;
        if (barHeight <= 0.0) {
            CGFloat bottomInset = 0.0;
            if (@available(iOS 11.0, *)) {
                bottomInset = self.view.superview.safeAreaInsets.bottom;
            }
            barHeight = 49.0 + bottomInset;
        }
        CGRect expected = CGRectMake(0, 0, self.view.superview.bounds.size.width, self.view.superview.bounds.size.height - barHeight);
        if (!CGRectEqualToRect(self.view.frame, expected)) {
            self.view.frame = expected;
        }
    }
    self.gameView.frame = self.view.bounds;
}
- (void)dealloc {
    [self.gameView stopGameLoop];
}
@end
// ============================================================
// PIVOT BAR INTEGRATION & DESTINATION MANAGEMENT
// ============================================================
static CGFloat FlappyGetPivotBarHeight(YTPivotBarViewController *pivotController, UIViewController *parent) {
    CGFloat barHeight = pivotController.view.frame.size.height;
    if (barHeight <= 0.0) {
        CGFloat bottomInset = 0.0;
        if (@available(iOS 11.0, *)) {
            bottomInset = parent.view.safeAreaInsets.bottom;
        }
        barHeight = 49.0 + bottomInset;
    }
    return barHeight;
}
static void FlappyShowGame(YTPivotBarViewController *pivotController) {
    if (!kEnabledFlappy) {
        return;
    }
    UIViewController *parent = pivotController.parentViewController;
    if (!parent) {
        return;
    }
    CGFloat barHeight = FlappyGetPivotBarHeight(pivotController, parent);
    CGRect contentRect = CGRectMake(0, 0, parent.view.bounds.size.width, parent.view.bounds.size.height - barHeight);
    // Reuse existing game controller to preserve game state across tab switches
    for (UIViewController *child in parent.childViewControllers) {
        if ([child isKindOfClass:[FlappyBirdViewController class]]) {
            FlappyBirdViewController *existing = (FlappyBirdViewController *)child;
            existing.pivotController = pivotController;
            existing.view.frame = contentRect;
            existing.view.hidden = NO;
            [parent.view bringSubviewToFront:existing.view];
            [parent.view bringSubviewToFront:pivotController.view];
            [existing.gameView startGameLoop];
            return;
        }
    }
    // First presentation: instantiate and attach
    FlappyBirdViewController *game = [FlappyBirdViewController new];
    game.pivotController = pivotController;
    [parent addChildViewController:game];
    game.view.frame = contentRect;
    game.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [parent.view addSubview:game.view];
    [game didMoveToParentViewController:parent];
    [parent.view bringSubviewToFront:pivotController.view];
    [game.gameView startGameLoop];
}
static void FlappyHideGame(YTPivotBarViewController *pivotController) {
    UIViewController *parent = pivotController.parentViewController;
    if (!parent) {
        return;
    }
    for (UIViewController *child in parent.childViewControllers) {
        if ([child isKindOfClass:[FlappyBirdViewController class]]) {
            FlappyBirdViewController *game = (FlappyBirdViewController *)child;
            [game.gameView stopGameLoop];
            game.view.hidden = YES;
            return;
        }
    }
}
// ============================================================
// LOGOS HOOKS
// ============================================================

static NSString * const kFlappyBrowseID = @"FE_FLAPPY_BIRD";

%hook YTPivotBarView


- (void)setRenderer:(YTIPivotBarRenderer *)renderer {
    if (!kEnabledFlappy) {
        %orig(renderer);
        return;
    }

NSMutableArray<YTIPivotBarSupportedRenderers *> *items = [renderer itemsArray];
if (items) {
    BOOL exists = NO;
    for (YTIPivotBarSupportedRenderers *item in items) {
        if ([item.pivotBarItemRenderer.pivotIdentifier isEqualToString:kFlappyPivotID] && [item.pivotBarItemRenderer.navigationEndpoint.browseEndpoint.browseId  isEqualToString:kFlappyBrowseID]) {
            exists = YES;
            break;
        }
    }


     if (!exists) {
            id PivotRenderer = NSClassFromString(@"YTIPivotBarRenderer");

            YTIPivotBarSupportedRenderers *flappy = nil;

            if (PivotRenderer) {
                flappy =
                    [PivotRenderer pivotSupportedRenderersWithBrowseId:kFlappyBrowseID
                                                                  title:@"Flappy Bird"
                                                               iconType:77];
            if (flappy) {
                flappy.pivotBarItemRenderer.pivotIdentifier = kFlappyPivotID;
                YTIIcon *customIcon = nil;
                if (NSClassFromString(@"YTIIcon")) {
                    customIcon = [%c(YTIIcon) new];
                    if (customIcon) {
                        customIcon.iconType = (YTIcon)44;
                        objc_setAssociatedObject(customIcon, "YHUICustomIcon", @"bird", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                        flappy.pivotBarItemRenderer.icon = customIcon;
                    }
                }
                [items addObject:flappy];
            }
        }
    }
    %orig(renderer);
}
}
%end



%hook YTPivotBarViewController
- (void)selectItemWithPivotIdentifier:(id)pivotIdentifier {
    if (!kEnabledFlappy) {
        %orig(pivotIdentifier);
        return;
    }
    if ([pivotIdentifier isEqualToString:kFlappyPivotID]) {
        self.selectedPivotIdentifier = kFlappyPivotID;
        // Update the visual selection state on the pivot bar view directly.
        // This calls -[YTPivotBarView selectItemWithPivotIdentifier:], which is
        // a DIFFERENT class than YTPivotBarViewController, so it does NOT recurse
        // back into this hook. This updates the icon tint, label color, and
        // indicator line to reflect the Flappy tab as visually selected,
        // and deselects whichever tab was previously highlighted.
        YTPivotBarView *barView = (YTPivotBarView *)self.view;
        if ([barView respondsToSelector:@selector(selectItemWithPivotIdentifier:)]) {
            [barView selectItemWithPivotIdentifier:kFlappyPivotID];
        }
        FlappyShowGame(self);
        return;
    }
    
    FlappyHideGame(self);
    %orig(pivotIdentifier);
}
%end

%hook YTBrowseViewController

- (void)viewDidLoad {
    %orig;

    if (!kEnabledFlappy) {
        return;
    }

    YTICommand *navEndpoint = nil;

    if (class_getInstanceVariable([self class], "_navEndpoint") != NULL) {
        navEndpoint = [self valueForKey:@"_navEndpoint"];
    }

    if (class_getInstanceVariable([self class], "_navigationEndpoint") != NULL) {
        navEndpoint = [self valueForKey:@"_navigationEndpoint"];
    }

    if (!navEndpoint) {
        return;
    }

    YTIBrowseEndpoint *browseEndpoint = navEndpoint.browseEndpoint;

    if (![browseEndpoint.browseId isEqualToString:kFlappyBrowseID]) {
        return;
    }

    FlappyBirdViewController *flappyVC = [FlappyBirdViewController new];

    [self addChildViewController:flappyVC];

    flappyVC.view.frame = self.view.bounds;
    flappyVC.view.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:flappyVC.view];

    [self.view endEditing:YES];

    [flappyVC didMoveToParentViewController:self];

    [flappyVC.gameView startGameLoop];
}

%end


%hook YTIIcon
- (UIImage *)iconImageWithColor:(UIColor *)color {
    NSString *tag = objc_getAssociatedObject(self, "YHUICustomIcon");
    if (tag) {
        if (@available(iOS 13.0, *)) {
            UIImage *img = [UIImage systemImageNamed:tag];
            if (img) {
                if (color) img = [img imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
                return img;
            }
        }
    }
    return %orig;
}

- (UIImage *)iconImageWithSelected:(BOOL)selected {
    NSString *tag = objc_getAssociatedObject(self, "YHUICustomIcon");
    if (tag) {
        if (@available(iOS 13.0, *)) {
            NSString *fillTag = [NSString stringWithFormat:@"%@.fill", tag];
            UIImage *img = selected ? [UIImage systemImageNamed:fillTag] : [UIImage systemImageNamed:tag];
            if (!img) img = [UIImage systemImageNamed:tag];
            if (img) return img;
        }
    }
    return %orig;
}
%end
// ============================================================
// CONSTRUCTOR
// ============================================================
%ctor {
    %init;
}

YT_END_TOGGLE
YT_SECTION_END



YT_SECTION(@"YTLocalQueueReborn")
YT_SECTION_ICON(@"list.bullet.indent")

YT_TOGGLE("Enable YTLocalQueueReborn", "This is an updated YTLocalQueue feature that tries to bring back the features of the og YTLocalQueue as much as possible. APP RESTART IS REQUIRED", NO)

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/NSObjCRuntime.h>
#import <MediaPlayer/MediaPlayer.h>


@class YTPlayerViewController;
@class YTQTMButton;
@class YTMainAppControlsOverlayView;
@class YTAutoplayAutonavController;
@class YTICommand;

@interface YTMainAppVideoPlayerOverlayView : UIView
@end

@interface YTPlayerViewController : UIViewController
@property (nonatomic, readonly) NSString *contentVideoID;
@end


@interface YTQTMButton : UIButton
@end

@interface YTMainAppVideoPlayerOverlayViewController : UIViewController
@property (nonatomic, readonly) YTMainAppVideoPlayerOverlayView *videoPlayerOverlayView;
@end

@interface YTMainAppControlsOverlayView : UIView

@property (nonatomic, strong, readwrite) YTPlayerViewController *playerViewController;
@property (nonatomic, readonly) NSURL *videoURL;
@property (nonatomic, readonly) NSURL *URL;

- (YTQTMButton *)buttonWithImage:(UIImage *)image accessibilityLabel:(NSString *)accessibilityLabel verticalContentPadding:(CGFloat)verticalContentPadding;
- (NSMutableArray *)topButtonControls;
- (NSMutableArray *)topControls;
- (void)addVideoToQueue:(id)sender withTitle:(NSString *)videoTitle;
- (void)playNextVideoInQueue:(id)playNext withURL:(NSURL *)URL;
@end

@interface YTHUDMessage : NSObject
+ (instancetype)messageWithText:(NSString *)text;
@end

@interface GOOHUDManagerInternal : NSObject
+ (instancetype)sharedInstance;
- (void)showMessageMainThread:(YTHUDMessage *)message;
@end

@interface YTAutoplayAutonavController : NSObject

- (id)initWithParentResponder:(id)responder;
- (void)playNext;
- (id)nextEndpointForAutonav;
- (id)nextEndpointForAutoplay;

@end

// ================================================================
// The Menu part where the queue is
// ================================================================

@interface YTLQRQueueViewController : UITableViewController
@end


// ================================================================
// Static helpers
// ================================================================

static NSMutableArray *YTLQRQueue;


static void YTLQRLoadQueue(void) {

    NSArray *saved =
        [[NSUserDefaults standardUserDefaults]
            arrayForKey:@"YTLQRQueue"];

    YTLQRQueue =
        saved.mutableCopy ?: [NSMutableArray array];
}


static void YTLQRSaveQueue(void) {

    [[NSUserDefaults standardUserDefaults]
        setObject:YTLQRQueue
        forKey:@"YTLQRQueue"];
}

static BOOL YTLQRAddItem(NSURL *URL, NSString *title) {

    if (!URL)
        return NO;

    if (!YTLQRQueue)
        YTLQRLoadQueue();

    [YTLQRQueue addObject:@{
        @"url": URL.absoluteString ?: @"",
        @"title": title ?: @""
    }];

    YTLQRSaveQueue();

    return YES;
}


// ================================================================
// Creating the menu
// ================================================================

@implementation YTLQRQueueViewController

- (instancetype)init {

    self =
        [super initWithStyle:UITableViewStyleInsetGrouped];

    if (self) {

        self.title = @"Queue";

        self.navigationItem.rightBarButtonItem =
            self.editButtonItem;
    }

    return self;
}


- (void)viewDidLoad {

    [super viewDidLoad];

    YTLQRLoadQueue();

    self.tableView.rowHeight = 60;
}


- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    return YTLQRQueue.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"YTLQRCell"];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:@"YTLQRCell"];
    }

    NSDictionary *item =
        YTLQRQueue[indexPath.row];

    cell.textLabel.text =
        item[@"title"];

    cell.detailTextLabel.text =
        item[@"url"];

    return cell;
}


- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return YES;
}


- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle ==
        UITableViewCellEditingStyleDelete) {

        [YTLQRQueue removeObjectAtIndex:indexPath.row];

        YTLQRSaveQueue();

        [tableView
            deleteRowsAtIndexPaths:@[indexPath]
            withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (BOOL)tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {

    return YES;
}


- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)source
toIndexPath:(NSIndexPath *)destination {

    NSDictionary *item =
        YTLQRQueue[source.row];

    [YTLQRQueue
        removeObjectAtIndex:source.row];

    [YTLQRQueue
        insertObject:item
        atIndex:destination.row];

    YTLQRSaveQueue();
}

@end


// ================================================================
// The two Default features:
// Add video to queue button & Play Next in Queue
// ================================================================


// Get video title & videoId

static NSString *YTLQRVideoTitle;
static NSString *YTLQRVideoId;


%hook YTIVideoDetails

- (NSString *)title {

    NSString *title = %orig;

    YTLQRVideoTitle = [title copy];

    return title;
}

- (NSString *)videoId {

    NSString *videoId = %orig;
    YTLQRVideoId = [videoId copy];
    return videoId;
}

%end


// ================================================================
// YTLQR top buttons
// ================================================================

static NSMutableArray *YTLQRTopButtons;


static void YTLQRCreateTopButtons(
    YTMainAppControlsOverlayView *view
) {

    if (!view)
        return;

    if (YTLQRTopButtons)
        return;

    YTLQRTopButtons =
        [NSMutableArray array];


    // ------------------------------------------------------------
    // Add to Queue
    // ------------------------------------------------------------

    YTQTMButton *addButton =
        [view
            buttonWithImage:
                [UIImage systemImageNamed:
                    @"text.badge.plus"]
            accessibilityLabel:@"Add to Queue"
            verticalContentPadding:0];

    addButton.hidden = YES;
    addButton.alpha = 0.0;
    addButton.tintColor = [UIColor whiteColor];


    [addButton addAction:
        [UIAction actionWithHandler:
            ^(__kindof UIAction *action) {

                [view
                    addVideoToQueue:addButton
                    withTitle:YTLQRVideoTitle];
            }]
        forControlEvents:UIControlEventTouchUpInside];


    // ------------------------------------------------------------
    // Play Next
    // ------------------------------------------------------------

    YTQTMButton *nextButton =
        [view
            buttonWithImage:
                [UIImage systemImageNamed:
                    @"chevron.forward.2"]
            accessibilityLabel:@"Play Next"
            verticalContentPadding:0];

    nextButton.hidden = YES;
    nextButton.alpha = 0.0;
    nextButton.tintColor = [UIColor whiteColor];


    [nextButton addAction:
        [UIAction actionWithHandler:
            ^(__kindof UIAction *action) {

                [view
                    playNextVideoInQueue:nextButton
                    withURL:nil];
            }]
        forControlEvents:UIControlEventTouchUpInside];


    // ------------------------------------------------------------
    // Open Queue
    // ------------------------------------------------------------

    YTQTMButton *queueButton =
        [view
            buttonWithImage:
                [UIImage systemImageNamed:
                    @"list.bullet.indent"]
            accessibilityLabel:@"Open Queue"
            verticalContentPadding:0];

    queueButton.hidden = YES;
    queueButton.alpha = 0.0;
    queueButton.tintColor = [UIColor whiteColor];


    __weak YTMainAppControlsOverlayView *weakView =
        view;


    [queueButton addAction:
        [UIAction actionWithHandler:
            ^(__kindof UIAction *action) {

                YTLQRQueueViewController *queueVC =
                    [[YTLQRQueueViewController alloc] init];

                UINavigationController *navigationController =
                    [[UINavigationController alloc]
                        initWithRootViewController:queueVC];

                UIViewController *presentingViewController =
                    nil;

                UIResponder *responder =
                    weakView;

                while (responder) {

                    if ([responder
                            isKindOfClass:
                                [UIViewController class]]) {

                        presentingViewController =
                            (UIViewController *)responder;

                        break;
                    }

                    responder =
                        [responder nextResponder];
                }

                if (!presentingViewController)
                    return;

                [presentingViewController
                    presentViewController:
                        navigationController
                    animated:YES
                    completion:nil];
            }]
        forControlEvents:UIControlEventTouchUpInside];


    [YTLQRTopButtons addObject:addButton];
    [YTLQRTopButtons addObject:nextButton];
    [YTLQRTopButtons addObject:queueButton];


    UIView *container =
        [view
            valueForKey:
                @"_topControlsAccessibilityContainerView"];

    if (container) {

        [container addSubview:addButton];
        [container addSubview:nextButton];
        [container addSubview:queueButton];
    }
}

// ================================================================
// Hooks & Helpers for the Play Next in Queue feature
// ================================================================

static __weak YTAutoplayAutonavController *
    YTLQRCurrentAutonavController;

static NSString *YTLQRCurrentNextVideoID;

// ================================================================
// Queue auto-advance support
// ================================================================

static BOOL YTLQRManualQueueAdvance = NO;
static NSUInteger YTLQRNativeTransitionDepth = 0;


static NSString *YTLQRVideoIDFromQueueItem(NSDictionary *item) {

    NSString *urlString =
        item[@"url"];

    if (urlString.length == 0)
        return nil;

    NSURLComponents *components =
        [NSURLComponents
            componentsWithURL:
                [NSURL URLWithString:urlString]
            resolvingAgainstBaseURL:NO];

    for (NSURLQueryItem *queryItem
         in components.queryItems) {

        if ([queryItem.name
                isEqualToString:@"v"] &&
            queryItem.value.length > 0) {

            return queryItem.value;
        }
    }

    return nil;
}


static NSString *YTLQRFirstQueuedVideoID(void) {

    if (!YTLQRQueue)
        YTLQRLoadQueue();

    if (YTLQRQueue.count == 0)
        return nil;

    return YTLQRVideoIDFromQueueItem(
        YTLQRQueue.firstObject
    );
}


static BOOL YTLQRPrepareNextQueuedVideo(void) {

    // The existing manual Play Next button already did this work.
    if (YTLQRCurrentNextVideoID.length > 0)
        return YES;

    NSString *videoID =
        YTLQRFirstQueuedVideoID();

    if (videoID.length == 0)
        return NO;

    YTLQRCurrentNextVideoID =
        [videoID copy];

    [YTLQRQueue removeObjectAtIndex:0];

    YTLQRSaveQueue();

    return YES;
}

%hook YTAutoplayAutonavController

- (id)initWithParentResponder:(id)responder {
    id result = %orig;

    YTLQRCurrentAutonavController = result;

    return result;
}


- (void)playAutonav {

    BOOL outermostTransition =
        (YTLQRNativeTransitionDepth++ == 0);

    if (outermostTransition) {

        // The old pending ID belongs to the video that just finished.
        YTLQRCurrentNextVideoID = nil;

        YTLQRPrepareNextQueuedVideo();
    }

    %orig;

    YTLQRNativeTransitionDepth--;
}


- (void)playAutoplay {

    BOOL outermostTransition =
        (YTLQRNativeTransitionDepth++ == 0);

    if (outermostTransition) {

        YTLQRCurrentNextVideoID = nil;

        YTLQRPrepareNextQueuedVideo();
    }

    %orig;

    YTLQRNativeTransitionDepth--;
}

- (id)nextEndpointForAutonav {

    if (YTLQRCurrentNextVideoID.length > 0) {

        NSString *videoID =
            YTLQRCurrentNextVideoID;

        YTLQRCurrentNextVideoID = nil;

        return [%c(YTICommand)
            watchNavigationEndpointWithVideoID:
                videoID];
    }

    NSString *videoID =
        YTLQRFirstQueuedVideoID();

    if (videoID.length > 0) {

        return [%c(YTICommand)
            watchNavigationEndpointWithVideoID:
                videoID];
    }

    return %orig;
}


- (id)nextEndpointForAutoplay {

    if (YTLQRCurrentNextVideoID.length > 0) {

        NSString *videoID =
            YTLQRCurrentNextVideoID;

        YTLQRCurrentNextVideoID = nil;

        return [%c(YTICommand)
            watchNavigationEndpointWithVideoID:
                videoID];
    }

    NSString *videoID =
        YTLQRFirstQueuedVideoID();

    if (videoID.length > 0) {

        return [%c(YTICommand)
            watchNavigationEndpointWithVideoID:
                videoID];
    }

    return %orig;
}

- (id)autonavEndpoint {

    NSString *videoID =
        YTLQRCurrentNextVideoID ?:
        YTLQRFirstQueuedVideoID();

    if (videoID.length > 0) {

        return [%c(YTICommand)
            watchNavigationEndpointWithVideoID:
                videoID];
    }

    return %orig;
}


- (id)autoplayEndpoint {

    NSString *videoID =
        YTLQRCurrentNextVideoID ?:
        YTLQRFirstQueuedVideoID();

    if (videoID.length > 0) {

        return [%c(YTICommand)
            watchNavigationEndpointWithVideoID:
                videoID];
    }

    return %orig;
}


- (void)playNext {

    // Native Forward button: discard the old transition ID, then choose
    // the current first queue item. If the queue is empty, %orig continues
    // with YouTube's normal next-video behavior.
    if (!YTLQRManualQueueAdvance &&
        YTLQRNativeTransitionDepth == 0) {

        YTLQRCurrentNextVideoID = nil;

        YTLQRPrepareNextQueuedVideo();
    }

    %orig;
}

%end

// ================================================================
// Overlay
// ================================================================


%hook YTMainAppControlsOverlayView

%property (nonatomic, readonly) NSURL *videoURL;
%property (nonatomic, readonly) NSURL *URL;


%new

- (void)addVideoToQueue:(id)sender
              withTitle:(NSString *)videoTitle {

    NSURL *videoURL =
        [NSURL URLWithString:
            [NSString stringWithFormat:
                @"youtube://www.youtube.com/watch?v=%@",
                YTLQRVideoId]];

    BOOL added =
        YTLQRAddItem(
            videoURL,
            YTLQRVideoTitle
        );

    if (added) {

        [[%c(GOOHUDManagerInternal) sharedInstance]
            showMessageMainThread:
                [%c(YTHUDMessage)
                    messageWithText:
                        @"✅ This video was successfully added to local queue"]];

    } else {

        [[%c(GOOHUDManagerInternal) sharedInstance]
            showMessageMainThread:
                [%c(YTHUDMessage)
                    messageWithText:
                        @"❌ This video could not be added to local queue"]];
    }
}

%new
- (void)playNextVideoInQueue:(id)playNext
                     withURL:(NSURL *)URL {

    if (!YTLQRQueue)
        YTLQRLoadQueue();

    if (YTLQRQueue.count == 0)
        return;

    if (!YTLQRCurrentAutonavController)
        return;

    NSDictionary *item =
        YTLQRQueue.firstObject;

    NSString *urlString =
        item[@"url"];

    if (urlString.length == 0)
        return;

    NSURL *queueURL =
        [NSURL URLWithString:urlString];

    if (!queueURL)
        return;

    NSURLComponents *components =
        [NSURLComponents
            componentsWithURL:queueURL
            resolvingAgainstBaseURL:NO];

    NSString *videoID = nil;

    for (NSURLQueryItem *queryItem
         in components.queryItems) {

        if ([queryItem.name
                isEqualToString:@"v"] &&
            queryItem.value.length > 0) {

            videoID =
                queryItem.value;

            break;
        }
    }

    if (videoID.length == 0)
        return;

    YTLQRCurrentNextVideoID =
        [videoID copy];

    [YTLQRQueue
        removeObjectAtIndex:0];

    YTLQRSaveQueue();

    YTLQRManualQueueAdvance = YES;

   [YTLQRCurrentAutonavController
      playNext];

YTLQRManualQueueAdvance = NO;

}


- (id)initWithDelegate:(id)delegate {

    self = %orig;

    if (self)
        YTLQRCreateTopButtons(self);

    return self;
}


- (id)initWithDelegate:(id)delegate
autoplaySwitchEnabled:(BOOL)autoplaySwitchEnabled {

    self = %orig;

    if (self)
        YTLQRCreateTopButtons(self);

    return self;
}


- (NSMutableArray *)topButtonControls {

    NSMutableArray *controls =
        %orig;

    if (!YTLQRTopButtons)
        YTLQRCreateTopButtons(self);

    for (YTQTMButton *button
         in [YTLQRTopButtons reverseObjectEnumerator]) {

        [controls insertObject:button atIndex:0];
    }

    return controls;
}


- (NSMutableArray *)topControls {

    NSMutableArray *controls =
        %orig;

    if (!YTLQRTopButtons)
        YTLQRCreateTopButtons(self);

    for (YTQTMButton *button
         in [YTLQRTopButtons reverseObjectEnumerator]) {

        [controls insertObject:button atIndex:0];
    }

    return controls;
}


- (void)setTopOverlayVisible:(BOOL)visible
      isAutonavCanceledState:(BOOL)canceledState {

    %orig;

    CGFloat alpha =
        (visible && !canceledState)
            ? 1.0
            : 0.0;

    for (YTQTMButton *button
         in YTLQRTopButtons) {

        button.alpha = alpha;
    }
}

%end


// ================================================================
// Top-right button availability
// ================================================================

%hook YTMainAppVideoPlayerOverlayViewController

- (void)updateTopRightButtonAvailability {

    %orig;

    YTMainAppVideoPlayerOverlayView *videoPlayerOverlayView =
        [self videoPlayerOverlayView];

    YTMainAppControlsOverlayView *controls =
        [videoPlayerOverlayView
            valueForKey:@"_controlsOverlayView"];

    if (!controls)
        return;

    if (!YTLQRTopButtons)
        YTLQRCreateTopButtons(controls);

    for (YTQTMButton *button
         in YTLQRTopButtons) {

        button.hidden = NO;
    }

    [controls setNeedsLayout];
}

%end

YT_END_TOGGLE
YT_SECTION_END

