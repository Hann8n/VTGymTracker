#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"Hannon.Gym-Tracker--RC-.GymTrackerWidget";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "BorderColor" asset catalog color resource.
static NSString * const ACColorNameBorderColor AC_SWIFT_PRIVATE = @"BorderColor";

/// The "CardBackground" asset catalog color resource.
static NSString * const ACColorNameCardBackground AC_SWIFT_PRIVATE = @"CardBackground";

/// The "CustomGreen" asset catalog color resource.
static NSString * const ACColorNameCustomGreen AC_SWIFT_PRIVATE = @"CustomGreen";

/// The "CustomMaroon" asset catalog color resource.
static NSString * const ACColorNameCustomMaroon AC_SWIFT_PRIVATE = @"CustomMaroon";

/// The "CustomOrange" asset catalog color resource.
static NSString * const ACColorNameCustomOrange AC_SWIFT_PRIVATE = @"CustomOrange";

/// The "SecondaryBackground" asset catalog color resource.
static NSString * const ACColorNameSecondaryBackground AC_SWIFT_PRIVATE = @"SecondaryBackground";

/// The "WidgetBorderColor" asset catalog color resource.
static NSString * const ACColorNameWidgetBorderColor AC_SWIFT_PRIVATE = @"WidgetBorderColor";

/// The "WidgetCardBackground" asset catalog color resource.
static NSString * const ACColorNameWidgetCardBackground AC_SWIFT_PRIVATE = @"WidgetCardBackground";

/// The "WidgetCustomGreen" asset catalog color resource.
static NSString * const ACColorNameWidgetCustomGreen AC_SWIFT_PRIVATE = @"WidgetCustomGreen";

/// The "WidgetCustomMaroon" asset catalog color resource.
static NSString * const ACColorNameWidgetCustomMaroon AC_SWIFT_PRIVATE = @"WidgetCustomMaroon";

/// The "WidgetCustomOrange" asset catalog color resource.
static NSString * const ACColorNameWidgetCustomOrange AC_SWIFT_PRIVATE = @"WidgetCustomOrange";

/// The "WidgetSecondaryBackground" asset catalog color resource.
static NSString * const ACColorNameWidgetSecondaryBackground AC_SWIFT_PRIVATE = @"WidgetSecondaryBackground";

/// The "Bluesky_Logo" asset catalog image resource.
static NSString * const ACImageNameBlueskyLogo AC_SWIFT_PRIVATE = @"Bluesky_Logo";

/// The "Close" asset catalog image resource.
static NSString * const ACImageNameClose AC_SWIFT_PRIVATE = @"Close";

/// The "Gear" asset catalog image resource.
static NSString * const ACImageNameGear AC_SWIFT_PRIVATE = @"Gear";

/// The "GitHub_Logo" asset catalog image resource.
static NSString * const ACImageNameGitHubLogo AC_SWIFT_PRIVATE = @"GitHub_Logo";

/// The "LinkedIn_Logo" asset catalog image resource.
static NSString * const ACImageNameLinkedInLogo AC_SWIFT_PRIVATE = @"LinkedIn_Logo";

/// The "VTGymApp_Logo" asset catalog image resource.
static NSString * const ACImageNameVTGymAppLogo AC_SWIFT_PRIVATE = @"VTGymApp_Logo";

#undef AC_SWIFT_PRIVATE
