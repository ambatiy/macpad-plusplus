#import "PreferencesWindowController.h"

NSString *const MPPrefFontName           = @"fontName";
NSString *const MPPrefFontSize           = @"fontSize";
NSString *const MPPrefTabWidth           = @"tabWidth";
NSString *const MPPrefUseSpacesForTabs   = @"useSpacesForTabs";
NSString *const MPPrefWordWrap           = @"wordWrap";
NSString *const MPPrefShowLineNumbers    = @"showLineNumbers";
NSString *const MPPrefShowWhitespace     = @"showWhitespace";
NSString *const MPPrefShowIndentGuides   = @"showIndentGuides";
NSString *const MPPrefShowFolding        = @"showFolding";
NSString *const MPPrefHighlightCurrentLine = @"highlightCurrentLine";
NSString *const MPPrefColorTheme         = @"colorTheme";
NSString *const MPPrefRecentFiles        = @"recentFiles";

static PreferencesWindowController *sSharedController = nil;

@interface PreferencesWindowController ()
@property (nonatomic, strong) NSTabView      *tabView;
// Editor tab
@property (nonatomic, strong) NSPopUpButton  *fontPopup;
@property (nonatomic, strong) NSTextField    *fontSizeField;
@property (nonatomic, strong) NSStepper      *fontSizeStepper;
@property (nonatomic, strong) NSTextField    *tabWidthField;
@property (nonatomic, strong) NSButton       *useSpacesCheck;
@property (nonatomic, strong) NSButton       *wordWrapCheck;
@property (nonatomic, strong) NSButton       *showLineNumCheck;
@property (nonatomic, strong) NSButton       *showWhitespaceCheck;
@property (nonatomic, strong) NSButton       *showIndentGuidesCheck;
@property (nonatomic, strong) NSButton       *showFoldingCheck;
@property (nonatomic, strong) NSButton       *highlightLineCheck;
// Appearance tab
@property (nonatomic, strong) NSPopUpButton  *themePopup;
// For Cancel restore
@property (nonatomic, strong) NSDictionary   *savedPrefsSnapshot;
@end

@implementation PreferencesWindowController

+ (instancetype)sharedController {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSWindow *window = [[NSWindow alloc]
                            initWithContentRect:NSMakeRect(0, 0, 480, 400)
                            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                            backing:NSBackingStoreBuffered
                            defer:NO];
        window.title = @"MacPad++ Preferences";
        [window center];

        sSharedController = [[PreferencesWindowController alloc] initWithWindow:window];
        [sSharedController setupUI];
        [sSharedController registerDefaults];
    });
    return sSharedController;
}

- (void)registerDefaults {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        MPPrefFontName:             @"Menlo",
        MPPrefFontSize:             @12,
        MPPrefTabWidth:             @4,
        MPPrefUseSpacesForTabs:     @NO,
        MPPrefWordWrap:             @NO,
        MPPrefShowLineNumbers:      @YES,
        MPPrefShowWhitespace:       @NO,
        MPPrefShowIndentGuides:     @YES,
        MPPrefShowFolding:          @YES,
        MPPrefHighlightCurrentLine: @YES,
        MPPrefColorTheme:           @0,
        MPPrefRecentFiles:          @[],
    }];
}

- (void)setupUI {
    NSView *content = self.window.contentView;

    _tabView = [[NSTabView alloc] initWithFrame:NSMakeRect(12, 50, 456, 340)];
    _tabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    // -- Editor tab --
    NSTabViewItem *editorTab = [[NSTabViewItem alloc] initWithIdentifier:@"editor"];
    editorTab.label = @"Editor";
    NSView *editorView = editorTab.view;

    CGFloat y = 270;
    CGFloat labelX = 20, fieldX = 170;

    // Font
    [editorView addSubview:[self labelAt:NSMakePoint(labelX, y) text:@"Font:"]];
    _fontPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(fieldX, y - 2, 180, 24)];
    NSArray *fonts = @[@"Menlo", @"Monaco", @"Courier New", @"SF Mono", @"Fira Code",
                       @"JetBrains Mono", @"Inconsolata", @"Source Code Pro"];
    for (NSString *f in fonts) [_fontPopup addItemWithTitle:f];
    [_fontPopup setTarget:self]; [_fontPopup setAction:@selector(prefsChanged:)];
    [editorView addSubview:_fontPopup];

    y -= 32;
    [editorView addSubview:[self labelAt:NSMakePoint(labelX, y) text:@"Font Size:"]];
    // Number-validated text field
    _fontSizeField = [[NSTextField alloc] initWithFrame:NSMakeRect(fieldX, y - 2, 52, 22)];
    _fontSizeField.delegate = (id<NSTextFieldDelegate>)self;
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    fmt.numberStyle = NSNumberFormatterDecimalStyle;
    fmt.minimum = @6; fmt.maximum = @72;
    fmt.maximumFractionDigits = 0;
    _fontSizeField.formatter = fmt;
    [editorView addSubview:_fontSizeField];
    // Stepper paired with the field
    _fontSizeStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(fieldX + 54, y - 2, 20, 22)];
    _fontSizeStepper.minValue = 6; _fontSizeStepper.maxValue = 72;
    _fontSizeStepper.increment = 1; _fontSizeStepper.valueWraps = NO;
    [_fontSizeStepper setTarget:self]; [_fontSizeStepper setAction:@selector(fontSizeStepperChanged:)];
    [editorView addSubview:_fontSizeStepper];

    y -= 32;
    [editorView addSubview:[self labelAt:NSMakePoint(labelX, y) text:@"Tab Width:"]];
    _tabWidthField = [[NSTextField alloc] initWithFrame:NSMakeRect(fieldX, y - 2, 60, 22)];
    _tabWidthField.delegate = (id<NSTextFieldDelegate>)self;
    [editorView addSubview:_tabWidthField];

    y -= 32;
    _useSpacesCheck = [NSButton checkboxWithTitle:@"Insert spaces instead of tabs" target:self action:@selector(prefsChanged:)];
    _useSpacesCheck.frame = NSMakeRect(labelX, y, 260, 20);
    [editorView addSubview:_useSpacesCheck];

    y -= 28;
    _wordWrapCheck = [NSButton checkboxWithTitle:@"Enable word wrap" target:self action:@selector(prefsChanged:)];
    _wordWrapCheck.frame = NSMakeRect(labelX, y, 220, 20);
    [editorView addSubview:_wordWrapCheck];

    y -= 28;
    _showLineNumCheck = [NSButton checkboxWithTitle:@"Show line numbers" target:self action:@selector(prefsChanged:)];
    _showLineNumCheck.frame = NSMakeRect(labelX, y, 220, 20);
    [editorView addSubview:_showLineNumCheck];

    y -= 28;
    _showWhitespaceCheck = [NSButton checkboxWithTitle:@"Show whitespace characters" target:self action:@selector(prefsChanged:)];
    _showWhitespaceCheck.frame = NSMakeRect(labelX, y, 260, 20);
    [editorView addSubview:_showWhitespaceCheck];

    y -= 28;
    _showIndentGuidesCheck = [NSButton checkboxWithTitle:@"Show indentation guides" target:self action:@selector(prefsChanged:)];
    _showIndentGuidesCheck.frame = NSMakeRect(labelX, y, 240, 20);
    [editorView addSubview:_showIndentGuidesCheck];

    y -= 28;
    _showFoldingCheck = [NSButton checkboxWithTitle:@"Show code folding margin" target:self action:@selector(prefsChanged:)];
    _showFoldingCheck.frame = NSMakeRect(labelX, y, 240, 20);
    [editorView addSubview:_showFoldingCheck];

    y -= 28;
    _highlightLineCheck = [NSButton checkboxWithTitle:@"Highlight current line" target:self action:@selector(prefsChanged:)];
    _highlightLineCheck.frame = NSMakeRect(labelX, y, 220, 20);
    [editorView addSubview:_highlightLineCheck];

    [_tabView addTabViewItem:editorTab];

    // -- Appearance tab --
    NSTabViewItem *appearanceTab = [[NSTabViewItem alloc] initWithIdentifier:@"appearance"];
    appearanceTab.label = @"Appearance";
    NSView *appearView = appearanceTab.view;

    y = 270;
    [appearView addSubview:[self labelAt:NSMakePoint(labelX, y) text:@"Color Theme:"]];
    _themePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(fieldX, y - 2, 220, 24)];
    [_themePopup addItemsWithTitles:@[
        @"Default (Light)",
        @"Dark",
        @"Monokai",
        @"Solarized Light",
        @"Solarized Dark",
        @"One Dark Pro",
        @"Dracula",
        @"Nord",
        @"Gruvbox Dark",
        @"Gruvbox Light",
        @"Tomorrow Night",
        @"Cobalt2",
        @"Material Dark",
    ]];
    [_themePopup setTarget:self]; [_themePopup setAction:@selector(prefsChanged:)];
    [appearView addSubview:_themePopup];

    [_tabView addTabViewItem:appearanceTab];
    [content addSubview:_tabView];

    // Buttons
    NSButton *okBtn = [NSButton buttonWithTitle:@"OK" target:self action:@selector(closePrefs:)];
    okBtn.frame = NSMakeRect(380, 12, 80, 28);
    okBtn.keyEquivalent = @"\r";
    [content addSubview:okBtn];

    NSButton *cancelBtn = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancel:)];
    cancelBtn.frame = NSMakeRect(292, 12, 80, 28);
    [content addSubview:cancelBtn];

    [self loadCurrentPrefs];
}

- (NSTextField *)labelAt:(NSPoint)pt text:(NSString *)text {
    NSTextField *lbl = [NSTextField labelWithString:text];
    lbl.frame = NSMakeRect(pt.x, pt.y, 145, 20);
    lbl.alignment = NSTextAlignmentRight;
    return lbl;
}

- (void)loadCurrentPrefs {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSString *fontName = [d stringForKey:MPPrefFontName] ?: @"Menlo";
    [_fontPopup selectItemWithTitle:fontName];

    double sz = [d doubleForKey:MPPrefFontSize] ?: 12;
    _fontSizeField.stringValue = [NSString stringWithFormat:@"%.0f", sz];
    _fontSizeStepper.doubleValue = sz;

    _tabWidthField.stringValue = [NSString stringWithFormat:@"%ld", (long)([d integerForKey:MPPrefTabWidth] ?: 4)];
    _useSpacesCheck.state   = [d boolForKey:MPPrefUseSpacesForTabs]     ? NSControlStateValueOn : NSControlStateValueOff;
    _wordWrapCheck.state    = [d boolForKey:MPPrefWordWrap]              ? NSControlStateValueOn : NSControlStateValueOff;
    _showLineNumCheck.state = [d boolForKey:MPPrefShowLineNumbers]       ? NSControlStateValueOn : NSControlStateValueOff;
    _showWhitespaceCheck.state   = [d boolForKey:MPPrefShowWhitespace]   ? NSControlStateValueOn : NSControlStateValueOff;
    _showIndentGuidesCheck.state = [d boolForKey:MPPrefShowIndentGuides] ? NSControlStateValueOn : NSControlStateValueOff;
    _showFoldingCheck.state      = [d boolForKey:MPPrefShowFolding]      ? NSControlStateValueOn : NSControlStateValueOff;
    _highlightLineCheck.state    = [d boolForKey:MPPrefHighlightCurrentLine] ? NSControlStateValueOn : NSControlStateValueOff;
    [_themePopup selectItemAtIndex:[d integerForKey:MPPrefColorTheme]];
}

// Snapshot current NSUserDefaults values so Cancel can restore them
- (NSDictionary *)currentPrefsSnapshot {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    return @{
        MPPrefFontName:             [d stringForKey:MPPrefFontName] ?: @"Menlo",
        MPPrefFontSize:             @([d doubleForKey:MPPrefFontSize] ?: 12),
        MPPrefTabWidth:             @([d integerForKey:MPPrefTabWidth] ?: 4),
        MPPrefUseSpacesForTabs:     @([d boolForKey:MPPrefUseSpacesForTabs]),
        MPPrefWordWrap:             @([d boolForKey:MPPrefWordWrap]),
        MPPrefShowLineNumbers:      @([d boolForKey:MPPrefShowLineNumbers]),
        MPPrefShowWhitespace:       @([d boolForKey:MPPrefShowWhitespace]),
        MPPrefShowIndentGuides:     @([d boolForKey:MPPrefShowIndentGuides]),
        MPPrefShowFolding:          @([d boolForKey:MPPrefShowFolding]),
        MPPrefHighlightCurrentLine: @([d boolForKey:MPPrefHighlightCurrentLine]),
        MPPrefColorTheme:           @([d integerForKey:MPPrefColorTheme]),
    };
}

- (void)prefsChanged:(id)sender {
    [self savePrefs];
}

- (void)fontSizeStepperChanged:(NSStepper *)stepper {
    _fontSizeField.doubleValue = stepper.doubleValue;
    [self savePrefs];
}

- (void)savePrefs {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:_fontPopup.titleOfSelectedItem forKey:MPPrefFontName];
    [d setDouble:_fontSizeField.doubleValue forKey:MPPrefFontSize];
    // Keep stepper in sync with typed value
    double clamped = MAX(6, MIN(72, _fontSizeField.doubleValue));
    _fontSizeStepper.doubleValue = clamped;
    [d setInteger:_tabWidthField.integerValue forKey:MPPrefTabWidth];
    [d setBool:(_useSpacesCheck.state   == NSControlStateValueOn) forKey:MPPrefUseSpacesForTabs];
    [d setBool:(_wordWrapCheck.state    == NSControlStateValueOn) forKey:MPPrefWordWrap];
    [d setBool:(_showLineNumCheck.state == NSControlStateValueOn) forKey:MPPrefShowLineNumbers];
    [d setBool:(_showWhitespaceCheck.state   == NSControlStateValueOn) forKey:MPPrefShowWhitespace];
    [d setBool:(_showIndentGuidesCheck.state == NSControlStateValueOn) forKey:MPPrefShowIndentGuides];
    [d setBool:(_showFoldingCheck.state      == NSControlStateValueOn) forKey:MPPrefShowFolding];
    [d setBool:(_highlightLineCheck.state    == NSControlStateValueOn) forKey:MPPrefHighlightCurrentLine];
    [d setInteger:_themePopup.indexOfSelectedItem forKey:MPPrefColorTheme];
    [d synchronize];
}

- (void)closePrefs:(id)sender {
    [self savePrefs];
    _savedPrefsSnapshot = nil;
    [self.window orderOut:nil];
}

- (void)cancel:(id)sender {
    // Restore all settings to the values they had when the panel was opened
    if (_savedPrefsSnapshot) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setObject:_savedPrefsSnapshot[MPPrefFontName] forKey:MPPrefFontName];
        [d setDouble:[_savedPrefsSnapshot[MPPrefFontSize] doubleValue] forKey:MPPrefFontSize];
        [d setInteger:[_savedPrefsSnapshot[MPPrefTabWidth] integerValue] forKey:MPPrefTabWidth];
        [d setBool:[_savedPrefsSnapshot[MPPrefUseSpacesForTabs] boolValue] forKey:MPPrefUseSpacesForTabs];
        [d setBool:[_savedPrefsSnapshot[MPPrefWordWrap] boolValue] forKey:MPPrefWordWrap];
        [d setBool:[_savedPrefsSnapshot[MPPrefShowLineNumbers] boolValue] forKey:MPPrefShowLineNumbers];
        [d setBool:[_savedPrefsSnapshot[MPPrefShowWhitespace] boolValue] forKey:MPPrefShowWhitespace];
        [d setBool:[_savedPrefsSnapshot[MPPrefShowIndentGuides] boolValue] forKey:MPPrefShowIndentGuides];
        [d setBool:[_savedPrefsSnapshot[MPPrefShowFolding] boolValue] forKey:MPPrefShowFolding];
        [d setBool:[_savedPrefsSnapshot[MPPrefHighlightCurrentLine] boolValue] forKey:MPPrefHighlightCurrentLine];
        [d setInteger:[_savedPrefsSnapshot[MPPrefColorTheme] integerValue] forKey:MPPrefColorTheme];
        [d synchronize];
        _savedPrefsSnapshot = nil;
    }
    [self.window orderOut:nil];
}

- (void)showPreferences {
    _savedPrefsSnapshot = [self currentPrefsSnapshot];
    [self loadCurrentPrefs];
    [self showWindow:nil];
    [self.window makeKeyAndOrderFront:nil];
}

@end
