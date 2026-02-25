#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class ScintillaView;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MPColorTheme) {
    MPColorThemeDefault = 0,    // Light
    MPColorThemeDark,
    MPColorThemeMonokai,
    MPColorThemeSolarizedLight,
    MPColorThemeSolarizedDark,
    MPColorThemeOneDarkPro,
    MPColorThemeDracula,
    MPColorThemeNord,
    MPColorThemeGruvboxDark,
    MPColorThemeGruvboxLight,
    MPColorThemeTomorrowNight,
    MPColorThemeCobalt2,
    MPColorThemeMaterialDark,
};

@interface SyntaxHighlighter : NSObject

+ (instancetype)sharedHighlighter;

- (void)applyLanguage:(NSString *)language toEditor:(ScintillaView *)editor;
- (void)applyTheme:(MPColorTheme)theme toEditor:(ScintillaView *)editor language:(NSString *)language;

- (NSArray<NSString *> *)allLanguageNames;
- (NSString *)displayNameForLanguage:(NSString *)language;

@property (nonatomic, assign) MPColorTheme currentTheme;

@end

NS_ASSUME_NONNULL_END
