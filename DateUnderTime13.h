@interface _UIStatusBarStringView : UILabel
@property(nullable, nonatomic, copy) NSString *text;
@property(nonatomic) NSTextAlignment textAlignment;
@property(nonatomic) NSInteger numberOfLines;
@property(nullable, nonatomic, copy) NSAttributedString *attributedText;
- (id)hasGestureRecognizer;
- (void)setHasGestureRecognizer:(id)arg;
- (void)openDoubleTapApp;
- (void)openHoldApp;
@end

@interface UIApplication ()
- (BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end
