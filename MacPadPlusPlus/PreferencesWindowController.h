#import <Cocoa/Cocoa.h>
#import "SyntaxHighlighter.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const MPPrefFontName;
extern NSString *const MPPrefFontSize;
extern NSString *const MPPrefTabWidth;
extern NSString *const MPPrefUseSpacesForTabs;
extern NSString *const MPPrefWordWrap;
extern NSString *const MPPrefShowLineNumbers;
extern NSString *const MPPrefShowWhitespace;
extern NSString *const MPPrefShowIndentGuides;
extern NSString *const MPPrefShowFolding;
extern NSString *const MPPrefHighlightCurrentLine;
extern NSString *const MPPrefColorTheme;
extern NSString *const MPPrefRecentFiles;

@interface PreferencesWindowController : NSWindowController

+ (instancetype)sharedController;
- (void)showPreferences;

@end

NS_ASSUME_NONNULL_END
