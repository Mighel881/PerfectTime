#import "DateUnderTime13.h"

#import <Cephei/HBPreferences.h>
#import "SparkColourPickerUtils.h"
#import "SparkAppList.h"

static UIFont *font1;
static UIFont *font2;

static NSDateFormatter *formatter1;
static NSDateFormatter *formatter2;

static NSMutableAttributedString *finalString;

static HBPreferences *pref;
static BOOL enabled;
static NSString *format1;
static long fontSize1;
static BOOL bold1;
static NSString *format2;
static long fontSize2;
static BOOL bold2;
static NSString *locale;
static long alignment;
static BOOL customTextColorEnabled;
static UIColor *customTextColor;
static BOOL enableDoubleTap;
static NSString *doubleTapIdentifier;
static BOOL enableHold;
static NSString *holdIdentifier;
static BOOL hideLocationIndicator;
static BOOL disableBreadcrumbs;
static BOOL showDateInSameLine;
static double width;

%hook _UIStatusBarStringView

- (void)layoutSubviews
{
	%orig;
	[self setUserInteractionEnabled: YES];

	if(![[self hasGestureRecognizer] isEqual: @YES])
	{
		if(enableDoubleTap)
		{
			UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(openDoubleTapApp)];
			[tapGestureRecognizer setNumberOfTapsRequired: 2];
			[self addGestureRecognizer: tapGestureRecognizer];
		}
		if(enableHold)
		{
			UILongPressGestureRecognizer *holdGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(openHoldApp)];
			[self addGestureRecognizer: holdGestureRecognizer];
		}
		[self setHasGestureRecognizer: @YES];
	}
}

%new
- (void)openDoubleTapApp
{
	[[UIApplication sharedApplication] launchApplicationWithIdentifier: doubleTapIdentifier suspended: NO];
}

%new
- (void)openHoldApp
{
	[[UIApplication sharedApplication] launchApplicationWithIdentifier: holdIdentifier suspended: NO];
}


%new
- (id)hasGestureRecognizer
{
	return objc_getAssociatedObject(self, @selector(hasGestureRecognizer));
}

%new
- (void)setHasGestureRecognizer: (id)arg
{
	objc_setAssociatedObject(self, @selector(hasGestureRecognizer), arg, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setTextColor: (UIColor*)color
{
	if(customTextColorEnabled && ([[self text] containsString: @"\n"] || [[self text] containsString: @":"] || [[self text] containsString: @"."]))
		%orig(customTextColor);
	else %orig;
}

- (void)setFont: (UIFont*)arg1
{
	if(!([[self text] containsString: @"\n"] || [[self text] containsString: @":"] || [[self text] containsString: @"."]))
		%orig;
}

- (void)setText: (NSString*)text
{
	if([text containsString: @":"] || [text containsString: @"."])
	{
		@autoreleasepool
		{
			NSDate *nowDate = [NSDate date];

			[finalString setAttributedString: [[NSAttributedString alloc] initWithString: [formatter1 stringFromDate: nowDate] attributes: @{ NSFontAttributeName: font1 }]];
			[finalString appendAttributedString: [[NSAttributedString alloc] initWithString: [formatter2 stringFromDate: nowDate] attributes: @{ NSFontAttributeName: font2 }]];

			if(showDateInSameLine) [self setNumberOfLines: 1];
			else [self setNumberOfLines: 2];
			[self setTextAlignment: alignment];
			[self setAdjustsFontSizeToFitWidth: YES];
			[self setAttributedText: finalString];

			if([self frame].size.width != width)
			{
				CGRect frame = [self frame];
				frame.size.width = width;
				[self setFrame: frame];
			}
		}
	}
	else %orig;
}

%end

%group hideLocationIndicatorGroup

	%hook _UIStatusBarIndicatorLocationItem

	- (id)applyUpdate: (id)arg1 toDisplayItem: (id)arg2
	{
		return nil;
	}

	%end

%end

%group disableBreadcrumbsGroup

	%hook SBDeviceApplicationSceneStatusBarBreadcrumbProvider

	+ (BOOL)_shouldAddBreadcrumbToActivatingSceneEntity: (id)arg1 sceneHandle: (id)arg2 withTransitionContext: (id)arg3
	{
		return NO;
	}

	%end

%end

%ctor
{
	@autoreleasepool
	{
		pref = [[HBPreferences alloc] initWithIdentifier: @"com.johnzaro.dateundertime13prefs"];
		[pref registerDefaults:
		@{
			@"enabled": @NO,
			@"format1": @"HH:mm",
			@"fontSize1": @14,
			@"bold1": @NO,
			@"format2": @"E dd/MM",
			@"fontSize2": @10,
			@"bold2": @NO,
			@"locale": @"en_US",
			@"alignment": @1,
			@"customTextColorEnabled": @NO,
			@"enableDoubleTap": @NO,
			@"enableHold": @NO,
			@"hideLocationIndicator": @NO,
			@"disableBreadcrumbs": @NO,
			@"showDateInSameLine": @NO,
			@"width": @100
    	}];

		enabled = [pref boolForKey: @"enabled"];
		if(enabled)
		{
			format1 = [pref objectForKey: @"format1"];
			fontSize1 = [pref integerForKey: @"fontSize1"];
			bold1 = [pref boolForKey: @"bold1"];
			format2 = [pref objectForKey: @"format2"];
			fontSize2 = [pref integerForKey: @"fontSize2"];
			bold2 = [pref boolForKey: @"bold2"];
			locale = [pref objectForKey: @"locale"];
			alignment = [pref integerForKey: @"alignment"];
			customTextColorEnabled = [pref boolForKey: @"customTextColorEnabled"];
			enableDoubleTap = [pref boolForKey: @"enableDoubleTap"];
			enableHold = [pref boolForKey: @"enableHold"];
			hideLocationIndicator = [pref boolForKey: @"hideLocationIndicator"];
			disableBreadcrumbs = [pref boolForKey: @"disableBreadcrumbs"];
			showDateInSameLine = [pref boolForKey: @"showDateInSameLine"];
			width = [pref doubleForKey: @"width"];

			if(customTextColorEnabled)
			{
				NSDictionary *preferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/com.johnzaro.dateundertime13prefs.colors.plist"];
				customTextColor = [SparkColourPickerUtils colourWithString: [preferencesDictionary objectForKey: @"customTextColor"] withFallback: @"#FF9400"];
			}

			if(enableDoubleTap)
			{
				NSArray *doubleTapApp = [SparkAppList getAppListForIdentifier: @"com.johnzaro.dateundertime13prefs.gestureApps" andKey: @"doubleTapApp"];
				if(doubleTapApp && [doubleTapApp count] == 1)
					doubleTapIdentifier = doubleTapApp[0];
			}

			if(enableHold)
			{
				NSArray *holdApp = [SparkAppList getAppListForIdentifier: @"com.johnzaro.dateundertime13prefs.gestureApps" andKey: @"holdApp"];
				if(holdApp && [holdApp count] == 1)
					holdIdentifier = holdApp[0];
			}

			formatter1 = [[NSDateFormatter alloc] init];
			[formatter1 setLocale: [[NSLocale alloc] initWithLocaleIdentifier: locale]];
			[formatter1 setTimeStyle: NSDateFormatterNoStyle];

			if(showDateInSameLine) [formatter1 setDateFormat: [NSString stringWithFormat:@"%@ ", format1]];
			else [formatter1 setDateFormat: [NSString stringWithFormat:@"%@\n", format1]];

			if(bold1) font1 = [UIFont boldSystemFontOfSize: fontSize1];
			else font1 = [UIFont systemFontOfSize: fontSize1];

			formatter2 = [[NSDateFormatter alloc] init];
			[formatter2 setLocale: [[NSLocale alloc] initWithLocaleIdentifier: locale]];
			[formatter2 setTimeStyle: NSDateFormatterNoStyle];
			[formatter2 setDateFormat: format2];

			if(bold2) font2 = [UIFont boldSystemFontOfSize: fontSize2];
			else font2 = [UIFont systemFontOfSize: fontSize2];

			finalString = [[NSMutableAttributedString alloc] init];

			%init;
			if(disableBreadcrumbs) %init(disableBreadcrumbsGroup);
			if(hideLocationIndicator) %init(hideLocationIndicatorGroup);
		}
	}
}