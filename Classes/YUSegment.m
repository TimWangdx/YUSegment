//
//  RDYSegmentedControl.m
//  Read
//
//  Created by 虞冠群 on 2016/11/12.
//  Copyright © 2016年 Yu Guanqun. All rights reserved.
//

#import "YUSegment.h"
#import "YULabel.h"
#import "YUImageView.h"
#import "YUImageTextView.h"
#import "YUIndicatorView.h"

static void *YUSegmentKVOCornerRadiusContext = &YUSegmentKVOCornerRadiusContext;

@interface YUSegment ()

/// @name Views

@property (nonatomic, strong) UIView                                 *containerView;
@property (nonatomic, strong) UIView                                 *selectedContainerView;
@property (nonatomic, strong) UIScrollView                           *scrollView;
@property (nonatomic, strong) YUIndicatorView                        *indicatorView;
@property (nonatomic, assign) BOOL                                   needsUpdateAppearance;

/// @name Constraints

@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *widthConstraints;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *leadingConstraints;

/// @name Contents

@property (nonatomic, strong) NSMutableArray <NSString *>    *internalTitles;
@property (nonatomic, strong) NSMutableArray <UIImage *>     *internalImages;
@property (nonatomic, strong) NSMutableArray <YULabel *>     *labels;
@property (nonatomic, strong) NSMutableArray <YUImageView *> *imageViews;
@property (nonatomic, strong) NSMutableArray <YULabel *>     *selectedLabels;
@property (nonatomic, strong) NSMutableArray <YUImageView *> *selectedImageViews;

/// @name Gesture

@property (nonatomic, assign) CGFloat panCorrection;

@end

@implementation YUSegment {
    CGFloat _segmentWidth;
}

@dynamic segmentWidth;

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithTitles:@[@"Left", @"Medium", @"Right"]];
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _internalTitles = [titles mutableCopy];
        _numberOfSegments = [titles count];
        [self commonInit];
        [self setupSegmentViewsWithTitles];
    }
    return self;
}

- (instancetype)initWithImages:(NSArray <UIImage *> *)images {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _internalImages = [images mutableCopy];
        _numberOfSegments = [images count];
        [self commonInit];
        [self setupSegmentViewsWithImages];
    }
    return self;
}

- (instancetype)initWithTitles:(NSArray <NSString *> *)titles forImages:(NSArray <UIImage *> *)images {
    NSAssert([titles count] == [images count], @"The count of titles should be equal to the count of images.");
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _internalTitles = [titles mutableCopy];
        _internalImages = [images mutableCopy];
        _numberOfSegments = [titles count];
        [self commonInit];
        [self setupSegmentViewsWithTitlesAndImages];
    }
    return self;
}

- (void)commonInit {
    NSLog(@"invoke commonInit");
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    _needsUpdateAppearance = NO;
    _selectedIndex = 0;
    _indicatorMargin = 3.0;
    _style = YUSegmentStyleSlider;
    [self setupContainerViewSelected:NO];
    [self setupContainerViewSelected:YES];
    [self setupIndicatorView];
    [self buildUI];
    [self addGesture];
    
    [self addObserver:self forKeyPath:@"layer.cornerRadius" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:YUSegmentKVOCornerRadiusContext];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSLog(@"Segment layoutSubviews");
    
    CGFloat segmentWidth = self.segmentWidth;
    switch (_style) {
        case YUSegmentStyleSlider: {
            CGFloat indicatorWidth = [self calculateIndicatorWidthPlusConstant];
            CGFloat x = segmentWidth * _selectedIndex + (segmentWidth - indicatorWidth) / 2.0;
            CGRect indicatorFrame = (CGRect){x, 0, indicatorWidth, CGRectGetHeight(self.frame)};
            _indicatorView.frame = indicatorFrame;
            break;
        }
        case YUSegmentStyleRounded: {
            CGRect indicatorFrame = (CGRect){segmentWidth * _selectedIndex, 0, segmentWidth, CGRectGetHeight(self.frame)};
            _indicatorView.frame = CGRectInset(indicatorFrame, _indicatorMargin, _indicatorMargin);
            break;
        }
    }
}

#pragma mark - Content Setting

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalTitles, @"You should use this method when the content of segment is `NSString` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    self.internalTitles[index] = title;
    [self updateViewWithTitle:title forSegmentAtIndex:index];
}

- (void)setImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalImages, @"You should use this method when the content of segment is `UImage` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    self.internalImages[index] = image;
    [self updateViewWithImage:image forSegmentAtIndex:index];
}

- (void)setTitle:(NSString *)title forImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalTitles && _internalImages, @"You should use this method when the content of segment includes title and image.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    self.internalTitles[index] = title;
    [self updateViewWithTitle:title forSegmentAtIndex:index];
    self.internalImages[index] = image;
    [self updateViewWithImage:image forSegmentAtIndex:index];
}

- (void)updateViewWithTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)index {
    YULabel *label = _labels[index];
    label.text = title;
    YULabel *selectedLabel = _selectedLabels[index];
    selectedLabel.text = title;
}

- (void)updateViewWithImage:(UIImage *)image forSegmentAtIndex:(NSUInteger)index {
    YUImageView *imageView = _imageViews[index];
    imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    YUImageView *selectedImage = _selectedImageViews[index];
    selectedImage.image = image;
}

#pragma mark - Content Getting

- (NSString *)titleForSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalTitles, @"You should use this method when the content of segment is `NSString` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    return _internalTitles[index];
}

- (UIImage *)imageForSegmentAtIndex:(NSUInteger)index {
    NSAssert(_internalImages, @"You should use this method when the content of segment is `UImage` object.");
    if (index > _numberOfSegments - 1) {
        index = _numberOfSegments - 1;
    }
    return _internalImages[index];
}

- (NSDictionary *)titleAndImageForSegmentAtIndex:(NSUInteger)index {
    NSAssert1(index < _numberOfSegments, @"Index should in the range of 0...%lu", _numberOfSegments - 1);
    NSDictionary *dic = @{@"title" : _internalTitles[index], @"image" : _internalImages[index]};
    return dic;
}

#pragma mark - Content Insert

- (void)addSegmentWithTitle:(NSString *)title {
    [self insertSegmentWithTitle:title atIndex:_numberOfSegments];
}

- (void)addSegmentWithImage:(UIImage *)image {
    [self insertSegmentWithImage:image atIndex:_numberOfSegments];
}

- (void)addSegmentWithTitle:(NSString *)title forImage:(UIImage *)image {
    [self insertSegmentWithTitle:title forImage:image atIndex:_numberOfSegments];
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)index {
    NSAssert(_internalTitles, @"You should use this method when the content of segment is `NSString` objcet.");
    if (index > _numberOfSegments) {
        index = _numberOfSegments;
    }
    [self.internalTitles insertObject:title atIndex:index];
    _numberOfSegments++;
}

- (void)insertSegmentWithImage:(UIImage *)image atIndex:(NSUInteger)index {
    NSAssert(_internalImages, @"You should use this method when the content of segment is `UIImage` objcet.");
    if (index > _numberOfSegments) {
        index = _numberOfSegments;
    }
    [self.internalImages insertObject:image atIndex:index];
    _numberOfSegments++;
}

- (void)insertSegmentWithTitle:(NSString *)title forImage:(UIImage *)image atIndex:(NSUInteger)index {
    NSAssert(_internalTitles && _internalImages, @"You should use this method when the content of the segment including `NSString` object and `UIImage` object.");
    if (index > _numberOfSegments) {
        index = _numberOfSegments;
    }
    [self.internalTitles insertObject:title atIndex:index];
    [self.internalImages insertObject:image atIndex:index];
    _numberOfSegments++;
}

- (void)insertViewWithTitle:(NSString *)title atIndex:(NSUInteger)index {
    // setup view
//    [self setupSegmentViewWithTitle:title selected:NO];
//    [self setupSegmentViewWithTitle:title selected:YES];
    // update c
//    [self updateConstraintsWithInsertSegmentView:segmentView atIndex:index];
}

- (void)insertViewWithImage:(UIImage *)image atIndex:(NSUInteger)index {
    
}

- (void)insertViewWithTitle:(NSString *)title forImage:(UIImage *)image atIndex:(NSUInteger)index {
    
}

#pragma mark - Content Delete

- (void)removeAllItems {
    
}

- (void)removeLastItem {
    [self removeItemAtIndex:_numberOfSegments - 1];
}

- (void)removeItemAtIndex:(NSUInteger)index {
    NSAssert1(index < _numberOfSegments, @"Parameter index should in the range of 0...%lu", _numberOfSegments - 1);
}

#pragma mark - Views Setup

- (void)setupSegmentViewsWithTitles {
    for (int i = 0; i < _numberOfSegments; i++) {
        [self setupSegmentViewWithTitle:_internalTitles[i]];
    }
    [self setupConstraintsWithSegments:_labels toContainerView:_containerView];
    [self setupConstraintsWithSegments:_selectedLabels toContainerView:_selectedContainerView];
}

- (void)setupSegmentViewsWithImages {
    for (int i = 0; i < _numberOfSegments; i++) {
        [self setupSegmentViewWithImage:_internalImages[i]];
    }
    [self setupConstraintsWithSegments:_imageViews toContainerView:_containerView];
    [self setupConstraintsWithSegments:_selectedImageViews toContainerView:_selectedContainerView];
}

- (void)setupSegmentViewsWithTitlesAndImages {
    NSMutableArray *imageTextViews = [NSMutableArray array];
    NSMutableArray *selectedImageTextViews = [NSMutableArray array];
    for (int i = 0; i < _numberOfSegments; i++) {
        NSArray *views = [self setupSegmentViewWithTitle:_internalTitles[i] forImage:_internalImages[i]];
        [imageTextViews addObject:views[0]];
        [selectedImageTextViews addObject:views[1]];
    }
    [self setupConstraintsWithSegments:imageTextViews toContainerView:_containerView];
    [self setupConstraintsWithSegments:selectedImageTextViews toContainerView:_selectedContainerView];
}

- (void)setupSegmentViewWithTitle:(NSString *)title {
    YULabel *label = [[YULabel alloc] initWithText:title style:YULabelStyleBasic];
    [_containerView addSubview:label];
    [self.labels addObject:label];
    label = [[YULabel alloc] initWithText:title style:YULabelStyleSelected];
    [_selectedContainerView addSubview:label];
    [self.selectedLabels addObject:label];
}

- (void)setupSegmentViewWithImage:(UIImage *)image {
    YUImageView *imageView = [[YUImageView alloc] initWithImage:image style:YUImageViewStyleBasic];
    [_containerView addSubview:imageView];
    [self.imageViews addObject:imageView];
    imageView = [[YUImageView alloc] initWithImage:image style:YUImageViewStyleSelected];
    [_selectedContainerView addSubview:imageView];
    [self.selectedImageViews addObject:imageView];
}

- (NSArray <YUImageTextView *> *)setupSegmentViewWithTitle:(NSString *)title forImage:(UIImage *)image {
    YUImageTextView *imageTextView1 = [[YUImageTextView alloc] initWithTitle:title forImage:image style:YUImageTextViewStyleBasic];
    [_containerView addSubview:imageTextView1];
    [self.labels addObject:[imageTextView1 getLabel]];
    [self.imageViews addObject:[imageTextView1 getImageView]];
    YUImageTextView *imageTextView2 = [[YUImageTextView alloc] initWithTitle:title forImage:image style:YUImageTextViewStyleSelected];
    [_selectedContainerView addSubview:imageTextView2];
    [self.selectedLabels addObject:[imageTextView2 getLabel]];
    [self.selectedImageViews addObject:[imageTextView2 getImageView]];

    return @[imageTextView1, imageTextView2];
}

- (void)setupContainerViewSelected:(BOOL)selected {
    UIView *view = ({
        UIView *containerView = [UIView new];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:containerView];
        
        containerView;
    });
    [self setupConstraintsToSelfWithView:view];
    selected ? (_selectedContainerView = view) : (_containerView = view);
}

- (void)setupIndicatorView {
    _indicatorView = [YUIndicatorView new];
    [self insertSubview:_indicatorView atIndex:1];
    _selectedContainerView.layer.mask = _indicatorView.maskView.layer;
}

- (void)buildUI {
    switch (_style) {
        case YUSegmentStyleSlider: {
            if (self.backgroundColor) {
                [self configureIndicatorWithBackgroundColor:self.backgroundColor];
            } else {
                self.backgroundColor = [UIColor whiteColor];
            }
            break;
        }
        case YUSegmentStyleRounded: {
//            if (!self.backgroundColor) {
//                self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
//            }
            self.layer.cornerRadius = 5.0;
            _indicatorView.cornerRadius = 5.0;
            break;
        }
    }
}

- (void)configureIndicatorWithBackgroundColor:(UIColor *)color {
    if (![color isEqual:[UIColor clearColor]]) {
        _indicatorView.backgroundColor = color;
    } else {
        _indicatorView.backgroundColor = [UIColor whiteColor];
    }
}

#pragma mark - Views Update

- (void)rebuildUI {
    switch (_style) {
        case YUSegmentStyleSlider: {
            _containerView.backgroundColor = self.backgroundColor ?: [UIColor whiteColor];
            break;
        }
        case YUSegmentStyleRounded: {
            _containerView.backgroundColor = self.backgroundColor ?: [UIColor colorWithWhite:0.9 alpha:1.0];
            _containerView.layer.cornerRadius = [self getCornerRadius] ?: 5.0;
            _indicatorMargin = self.indicatorMargin ?: 2.0;
            _indicatorView.cornerRadius = [self getCornerRadius] ?: 5.0;
            break;
        }
    }
}

- (void)updateTitleWithColor:(UIColor *)color {
    if (!_labels) {
        return;
    }
    for (int i = 0; i < _numberOfSegments; i++) {
        _labels[i].textColor = color;
    }
}

- (void)updateTitleWithSelectedColor:(UIColor *)color {
    if (!_selectedLabels) {
        return;
    }
    for (int i = 0; i < _numberOfSegments; i++) {
        _selectedLabels[i].textColor = color;
    }
}

- (void)updateTitleWithFont:(UIFont *)font {
    if (!_labels) {
        return;
    }
    for (int i = 0; i < _numberOfSegments; i++) {
        _labels[i].font = font;
    }
}

- (void)updateTitleWithSelectedFont:(UIFont *)font {
    if (!_selectedLabels) {
        return;
    }
    for (int i = 0; i < _numberOfSegments; i++) {
        _selectedLabels[i].font = font;
    }
}

- (CGFloat)getCornerRadius {
    return self.layer.cornerRadius;
}

- (void)updateViewHierarchy {
    // Add container to scroll view
    [_containerView removeFromSuperview];
    [self.scrollView addSubview:_containerView];
    // Add indicator to scroll view
    [_indicatorView removeFromSuperview];
    [_scrollView addSubview:_indicatorView];
    // Add selected container to scroll view
    [_selectedContainerView removeFromSuperview];
    [_scrollView addSubview:_selectedContainerView];
    
    // Setup constraints
    [self setupConstraintsToScrollViewWithView:_containerView];
    [self setupConstraintsToScrollViewWithView:_selectedContainerView];
    [self updateWidthConstraintsForSegments];
}

- (void)makeCurrentSegmentCenterInSelf {
    CGFloat finalOffset = self.segmentWidth * (_selectedIndex + 0.5) - CGRectGetWidth(self.frame) / 2;
    CGFloat maxOffset = _scrollView.contentSize.width - CGRectGetWidth(self.frame);
    CGPoint contentOffset = _scrollView.contentOffset;
    if (finalOffset <= 0) {
        contentOffset.x = 0;
    }
    else if (finalOffset >= maxOffset) {
        contentOffset.x = maxOffset;
    }
    else {
        contentOffset.x = finalOffset;
    }
    _scrollView.contentOffset = contentOffset;
}

#pragma mark - Event Response

- (void)addGesture {
    if (_style == YUSegmentStyleRounded) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:pan];
    }
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
}

- (void)tap:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint location = [gestureRecognizer locationInView:_containerView];
    NSUInteger fromIndex = self.selectedIndex;
    self.selectedIndex = [self nearestIndexOfSegmentAtXCoordinate:location.x];
    if (fromIndex != self.selectedIndex) {
        [self moveIndicatorFromIndex:fromIndex toIndex:_selectedIndex animated:YES];
    }
}

- (void)pan:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            _panCorrection = [gestureRecognizer locationInView:_indicatorView].x - CGRectGetWidth(_indicatorView.frame) / 2;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint panLocation = [gestureRecognizer locationInView:_containerView];
            [self.indicatorView setCenterX:(panLocation.x - _panCorrection)];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            CGFloat indicatorCenterX = [_indicatorView getCenterX];
            NSUInteger fromIndex = self.selectedIndex;
            self.selectedIndex = [self nearestIndexOfSegmentAtXCoordinate:indicatorCenterX];
            [self moveIndicatorFromIndex:fromIndex toIndex:_selectedIndex animated:YES];
        }
        default:
            break;
    }
}

- (NSUInteger)nearestIndexOfSegmentAtXCoordinate:(CGFloat)x {
    NSUInteger index = x / self.segmentWidth;
    return index < _numberOfSegments ? index : _numberOfSegments - 1;
}

- (void)moveIndicatorFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            [_indicatorView setCenterX:self.segmentWidth * (0.5 + toIndex)];
        } completion:^(BOOL finished) {
            if (finished) {
                [self sendActionsForControlEvents:UIControlEventValueChanged];
                [self makeCurrentSegmentCenterInSelf];
            }
        }];
    }
    else {
        [_indicatorView setCenterX:self.segmentWidth * (0.5 + toIndex)];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
        [self makeCurrentSegmentCenterInSelf];
    }
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == YUSegmentKVOCornerRadiusContext) {
        _indicatorView.cornerRadius = [self getCornerRadius];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (CGFloat)calculateIndicatorWidthPlusConstant {
    CGFloat maxWidth = 0.0;
    CGFloat width;
    if (_internalTitles && _internalImages) {
        maxWidth = _selectedImageViews[0].intrinsicContentSize.width;
        for (YULabel *label in _selectedLabels) {
            width = label.intrinsicContentSize.width;
            if (width > maxWidth) {
                maxWidth = width;
            }
        }
    }
    else if (_internalImages) {
        maxWidth = _selectedImageViews[0].intrinsicContentSize.width;
    }
    else {
        for (YULabel *label in _selectedLabels) {
            width = label.intrinsicContentSize.width;
            if (width > maxWidth) {
                maxWidth = width;
            }
        }
    }
    maxWidth += 32.0;
    CGFloat segmentWidth = self.segmentWidth;
    if (maxWidth > segmentWidth) {
        maxWidth = segmentWidth;
    }
    return maxWidth;
}

#pragma mark - Setters

- (void)setTitles:(NSArray <NSString *> *)titles forImages:(NSArray <UIImage *> *)images {
    if (titles) {
        self.internalTitles = [titles mutableCopy];
        _numberOfSegments = [titles count];
        if (images) {
            self.internalImages = [images mutableCopy];
            [self setupSegmentViewsWithTitlesAndImages];
        } else {
            [self setupSegmentViewsWithTitles];
        }
        if (_needsUpdateAppearance) {
            if (_textColor) {
                [self updateTitleWithColor:_textColor];
            }
            if (_font) {
                [self updateTitleWithFont:_font];
            }
            if (_selectedTextColor) {
                [self updateTitleWithSelectedColor:_selectedTextColor];
            }
            if (_selectedFont) {
                [self updateTitleWithSelectedFont:_font];
            }
        }
    }
    else if (images) {
        self.internalImages = [images mutableCopy];
        _numberOfSegments = [images count];
        [self setupSegmentViewsWithImages];
    }
}

- (void)setRoundedStyle:(BOOL)roundedStyle {
    roundedStyle ? [self setStyle:YUSegmentStyleRounded] : [self setStyle:YUSegmentStyleSlider];
}

- (void)setStyle:(YUSegmentStyle)style {
    if (_style == style) {
        return;
    }
    _style = style;
    [_indicatorView updateIndicatorStyle:(YUIndicatorViewStyle)style];
    [self buildUI];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    NSAssert(backgroundColor, @"The color should not be nil.");
    [super setBackgroundColor:backgroundColor];
    if (_indicatorView) {
        [self configureIndicatorWithBackgroundColor:backgroundColor];
    }
}

- (void)setSegmentWidth:(CGFloat)segmentWidth {
    if (segmentWidth < 1.0 || _segmentWidth == segmentWidth) {
        return;
    }
    _segmentWidth = segmentWidth;
    [self updateViewHierarchy];
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    NSAssert(indicatorColor, @"The color should not be nil.");
    if (indicatorColor != _indicatorColor && ![indicatorColor isEqual:_indicatorColor]) {
        _indicatorColor = indicatorColor;
        _indicatorView.indicatorColor = indicatorColor;
    }
}

- (void)setTextColor:(UIColor *)textColor {
    NSAssert(textColor, @"The color should not be nil.");
    if (textColor != _textColor && ![textColor isEqual:_textColor]) {
        _textColor = textColor;
        if (_numberOfSegments) {
            [self updateTitleWithColor:textColor];
        } else {
            _needsUpdateAppearance = YES;
        }
    }
}

- (void)setSelectedTextColor:(UIColor *)selectedTextColor {
    NSAssert(selectedTextColor, @"The color should not be nil.");
    if (selectedTextColor != _selectedTextColor && ![selectedTextColor isEqual:_selectedTextColor]) {
        _selectedTextColor = selectedTextColor;
        if (_numberOfSegments) {
            [self updateTitleWithSelectedColor:selectedTextColor];
        } else {
            _needsUpdateAppearance = YES;
        }
    }
}

- (void)setFont:(UIFont *)font {
    NSAssert(font, @"The font should not be nil.");
    _font = font;
    if (_numberOfSegments) {
        [self updateTitleWithFont:font];
    } else {
        _needsUpdateAppearance = YES;
    }
}

- (void)setSelectedFont:(UIFont *)selectedFont {
    NSAssert(selectedFont, @"The font should not be nil.");
    _selectedFont = selectedFont;
    if (_numberOfSegments) {
        [self updateTitleWithSelectedFont:selectedFont];
    } else {
        _needsUpdateAppearance = YES;
    }
}

#pragma mark - Getters

- (CGFloat)segmentWidth {
    if (!_segmentWidth) {
        return CGRectGetWidth(self.bounds) / _numberOfSegments;
    }
    return _segmentWidth;
}

- (UIScrollView *)scrollView {
    if (_scrollView) {
        return _scrollView;
    }
    _scrollView = ({
        UIScrollView *scrollView = [UIScrollView new];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:scrollView];
        
        scrollView;
    });
    [self setupConstraintsToSelfWithView:_scrollView];
    
    return _scrollView;
}

- (NSMutableArray <NSLayoutConstraint *> *)leadingConstraints {
    if (_leadingConstraints) {
        return _leadingConstraints;
    }
    _leadingConstraints = [NSMutableArray array];
    return _leadingConstraints;
}

- (NSMutableArray <NSLayoutConstraint *> *)widthConstraints {
    if (_widthConstraints) {
        return _widthConstraints;
    }
    _widthConstraints = [NSMutableArray array];
    return _widthConstraints;
}

- (NSMutableArray <YULabel *> *)labels {
    if (_labels) {
        return _labels;
    }
    _labels = [NSMutableArray array];
    return _labels;
}

- (NSMutableArray <YUImageView *> *)imageViews {
    if (_imageViews) {
        return _imageViews;
    }
    _imageViews = [NSMutableArray array];
    return _imageViews;
}

- (NSMutableArray <YULabel *> *)selectedLabels {
    if (_selectedLabels) {
        return _selectedLabels;
    }
    _selectedLabels = [NSMutableArray array];
    return _selectedLabels;
}

- (NSMutableArray <YUImageView *> *)selectedImageViews {
    if (_selectedImageViews) {
        return _selectedImageViews;
    }
    _selectedImageViews = [NSMutableArray array];
    return _selectedImageViews;
}

#pragma mark - Constraints

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)setupConstraintsWithSegments:(NSArray *)segments toContainerView:(UIView *)containerView {
    UIView *lastView;
    for (UIView *view in segments) {
        [NSLayoutConstraint constraintWithItem:view
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:containerView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:8.0
         ].active = YES;
        
        [NSLayoutConstraint constraintWithItem:view
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:containerView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:-8.0
         ].active = YES;
        
        if (lastView) {
            NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:view
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:lastView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0.0];
            leading.active = YES;
//            [self.leadingConstraints addObject:leading];
            
            NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:view
                                         attribute:NSLayoutAttributeWidth
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:lastView
                                         attribute:NSLayoutAttributeWidth
                                        multiplier:1.0
                                          constant:0.0
             ];
            width.active = YES;
            [self.widthConstraints addObject:width];
        }
        else {
            NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:view
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:containerView
                                                                       attribute:NSLayoutAttributeLeading
                                                                      multiplier:1.0
                                                                        constant:0.0];
            leading.active = YES;
//            [self.leadingConstraints addObject:leading];
        }
        
        lastView = view;
    }
    [NSLayoutConstraint constraintWithItem:containerView
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:lastView
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
}

- (void)setupConstraintsToSelfWithView:(UIView *)view {
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
}

- (void)setupConstraintsToScrollViewWithView:(UIView *)view {
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
    
    [NSLayoutConstraint constraintWithItem:_scrollView
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeHeight
                                multiplier:1.0
                                  constant:0.0
     ].active = YES;
}

- (void)updateWidthConstraintsForSegments {
    for (NSLayoutConstraint *width in _widthConstraints) {
        width.active = NO;
    }
    [self.widthConstraints removeAllObjects];
    for (UIView *view in _containerView.subviews) {
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:_segmentWidth];
        width.active = YES;
        [self.widthConstraints addObject:width];
    }
    for (UIView *view in _selectedContainerView.subviews) {
        NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:_segmentWidth];
        width.active = YES;
        [self.widthConstraints addObject:width];
    }
}

- (void)updateConstraintsWithInsertSegmentView:(UIView *)segmentView atIndex:(NSUInteger)index {
    if (_leadingConstraints) {
        NSLayoutConstraint *oldLeading = _leadingConstraints[index];
        id item = oldLeading.firstItem;
        id toItem = oldLeading.secondItem;
        oldLeading.active = NO;
        
        NSLayoutConstraint *newLeading = [NSLayoutConstraint constraintWithItem:segmentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:toItem
                                                                      attribute:NSLayoutAttributeTrailing
                                                                     multiplier:1.0
                                                                       constant:8.0];
        newLeading.active = YES;
        [self.leadingConstraints insertObject:newLeading atIndex:index];
        
        oldLeading = [NSLayoutConstraint constraintWithItem:item
                                                  attribute:NSLayoutAttributeLeading
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:segmentView
                                                  attribute:NSLayoutAttributeTrailing
                                                 multiplier:1.0
                                                   constant:8.0];
        oldLeading.active = YES;
        self.leadingConstraints[index + 1] = oldLeading;
        
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:segmentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
        widthConstraint.active = YES;
        
        [self layoutIfNeeded];
        
        [NSLayoutConstraint constraintWithItem:segmentView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:_containerView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0.0
         ].active = YES;
        
        [NSLayoutConstraint constraintWithItem:segmentView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:_containerView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:0.0
         ].active = YES;
        
        widthConstraint.active = NO;
        widthConstraint = [NSLayoutConstraint constraintWithItem:segmentView
                                                       attribute:NSLayoutAttributeWidth
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:toItem
                                                       attribute:NSLayoutAttributeWidth
                                                      multiplier:1.0
                                                        constant:0.0
                           ];
        widthConstraint.active = YES;
        
        [UIView animateWithDuration:3 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

- (void)updateConstraintsWithDeleteSegmentViewAtIndex:(NSUInteger)index {
    
}

@end