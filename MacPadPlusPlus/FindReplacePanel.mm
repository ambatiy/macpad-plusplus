#import "FindReplacePanel.h"
#import "EditorView.h"
#import "ScintillaView.h"
#import "Scintilla.h"

static FindReplacePanel *sSharedPanel = nil;

@interface FindReplacePanel ()
// Find row
@property (nonatomic, strong) NSTextField *findField;
@property (nonatomic, strong) NSButton *findNextBtn;
@property (nonatomic, strong) NSButton *findPrevBtn;
@property (nonatomic, strong) NSButton *markAllBtn;
// Replace row (shown in replace mode)
@property (nonatomic, strong) NSTextField *replaceField;
@property (nonatomic, strong) NSButton *replaceBtn;
@property (nonatomic, strong) NSButton *replaceAllBtn;
// Options
@property (nonatomic, strong) NSButton *matchCaseCheck;
@property (nonatomic, strong) NSButton *wholeWordCheck;
@property (nonatomic, strong) NSButton *regexCheck;
@property (nonatomic, strong) NSButton *wrapAroundCheck;
// Status
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSView *replaceRow;
@property (nonatomic, assign) BOOL isReplaceMode;
@end

@implementation FindReplacePanel

+ (instancetype)sharedPanel {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sSharedPanel = [[FindReplacePanel alloc]
                        initWithContentRect:NSMakeRect(0, 0, 560, 130)
                        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                        backing:NSBackingStoreBuffered
                        defer:NO];
        sSharedPanel->_isReplaceMode = NO;
        [sSharedPanel setupUI];
    });
    return sSharedPanel;
}

- (void)setupUI {
    self.title = @"Find";
    self.level = NSFloatingWindowLevel;
    [self setMinSize:NSMakeSize(460, 100)];
    [self center];

    NSView *content = self.contentView;

    // --- Find row ---
    NSTextField *findLbl = [NSTextField labelWithString:@"Find:"];
    findLbl.frame = NSMakeRect(12, 88, 55, 20);
    [content addSubview:findLbl];

    _findField = [[NSTextField alloc] initWithFrame:NSMakeRect(72, 86, 340, 22)];
    _findField.placeholderString = @"Search text";
    _findField.autoresizingMask = NSViewWidthSizable;
    [content addSubview:_findField];

    _findNextBtn = [NSButton buttonWithTitle:@"Find Next" target:self action:@selector(findNext)];
    _findNextBtn.frame = NSMakeRect(420, 86, 120, 22);
    _findNextBtn.autoresizingMask = NSViewMinXMargin;
    _findNextBtn.keyEquivalent = @"\r";
    [content addSubview:_findNextBtn];

    _findPrevBtn = [NSButton buttonWithTitle:@"Find Prev" target:self action:@selector(findPrevious)];
    _findPrevBtn.frame = NSMakeRect(420, 62, 120, 22);
    _findPrevBtn.autoresizingMask = NSViewMinXMargin;
    [content addSubview:_findPrevBtn];

    _markAllBtn = [NSButton buttonWithTitle:@"Mark All" target:self action:@selector(markAll)];
    _markAllBtn.frame = NSMakeRect(296, 62, 110, 22);
    _markAllBtn.autoresizingMask = NSViewMinXMargin;
    [content addSubview:_markAllBtn];

    // --- Replace row (hidden by default) ---
    _replaceRow = [[NSView alloc] initWithFrame:NSMakeRect(0, 60, 540, 24)];
    _replaceRow.autoresizingMask = NSViewWidthSizable;
    _replaceRow.hidden = YES;

    NSTextField *replaceLbl = [NSTextField labelWithString:@"Replace:"];
    replaceLbl.frame = NSMakeRect(12, 0, 55, 20);
    [_replaceRow addSubview:replaceLbl];

    _replaceField = [[NSTextField alloc] initWithFrame:NSMakeRect(72, 0, 220, 22)];
    _replaceField.placeholderString = @"Replace with";
    _replaceField.autoresizingMask = NSViewWidthSizable;
    [_replaceRow addSubview:_replaceField];

    _replaceBtn = [NSButton buttonWithTitle:@"Replace" target:self action:@selector(replace)];
    _replaceBtn.frame = NSMakeRect(300, 0, 90, 22);
    [_replaceRow addSubview:_replaceBtn];

    _replaceAllBtn = [NSButton buttonWithTitle:@"Replace All" target:self action:@selector(replaceAll)];
    _replaceAllBtn.frame = NSMakeRect(396, 0, 110, 22);
    [_replaceRow addSubview:_replaceAllBtn];

    [content addSubview:_replaceRow];

    // --- Options row ---
    _matchCaseCheck = [NSButton checkboxWithTitle:@"Match case" target:nil action:nil];
    _matchCaseCheck.frame = NSMakeRect(12, 10, 110, 20);
    [content addSubview:_matchCaseCheck];

    _wholeWordCheck = [NSButton checkboxWithTitle:@"Whole word" target:nil action:nil];
    _wholeWordCheck.frame = NSMakeRect(128, 10, 110, 20);
    [content addSubview:_wholeWordCheck];

    _regexCheck = [NSButton checkboxWithTitle:@"Regular expression" target:nil action:nil];
    _regexCheck.frame = NSMakeRect(244, 10, 155, 20);
    [content addSubview:_regexCheck];

    _wrapAroundCheck = [NSButton checkboxWithTitle:@"Wrap around" target:nil action:nil];
    _wrapAroundCheck.frame = NSMakeRect(404, 10, 120, 20);
    _wrapAroundCheck.state = NSControlStateValueOn;
    [content addSubview:_wrapAroundCheck];

    // Status label
    _statusLabel = [NSTextField labelWithString:@""];
    _statusLabel.frame = NSMakeRect(72, 64, 200, 18);
    _statusLabel.textColor = [NSColor tertiaryLabelColor];
    _statusLabel.font = [NSFont systemFontOfSize:11];
    _statusLabel.autoresizingMask = NSViewWidthSizable;
    [content addSubview:_statusLabel];
}

- (void)showFindMode {
    self.title = @"Find";
    _isReplaceMode = NO;
    _replaceRow.hidden = YES;
    [self setContentSize:NSMakeSize(self.frame.size.width, 118)];
    [self makeKeyAndOrderFront:nil];
    [self makeFirstResponder:_findField];
}

- (void)showFindAndReplaceMode {
    self.title = @"Find & Replace";
    _isReplaceMode = YES;
    _replaceRow.hidden = NO;
    [self setContentSize:NSMakeSize(self.frame.size.width, 142)];
    [self makeKeyAndOrderFront:nil];
    [self makeFirstResponder:_findField];
}

- (BOOL)performFind:(BOOL)forward {
    NSString *searchText = _findField.stringValue;
    if (searchText.length == 0) return NO;

    BOOL matchCase = (_matchCaseCheck.state == NSControlStateValueOn);
    BOOL wholeWord = (_wholeWordCheck.state == NSControlStateValueOn);
    BOOL wrap = (_wrapAroundCheck.state == NSControlStateValueOn);

    if (!_targetEditor) return NO;

    ScintillaView *sci = _targetEditor.scintillaView;
    BOOL found = [sci findAndHighlightText:searchText
                                 matchCase:matchCase
                                 wholeWord:wholeWord
                                  scrollTo:YES
                                      wrap:wrap
                                 backwards:!forward];
    if (!found) {
        _statusLabel.stringValue = @"Not found";
        _statusLabel.textColor = [NSColor systemRedColor];
        NSBeep();
    } else {
        _statusLabel.stringValue = @"";
    }
    return found;
}

- (void)findNext {
    [self performFind:YES];
}

- (void)findPrevious {
    [self performFind:NO];
}

- (void)markAll {
    NSString *searchText = _findField.stringValue;
    if (searchText.length == 0 || !_targetEditor) return;

    ScintillaView *sci = _targetEditor.scintillaView;
    BOOL matchCase = (_matchCaseCheck.state == NSControlStateValueOn);
    BOOL wholeWord = (_wholeWordCheck.state == NSControlStateValueOn);

    // Count occurrences
    int count = [sci findAndReplaceText:searchText
                                 byText:searchText
                              matchCase:matchCase
                              wholeWord:wholeWord
                                  doAll:YES];
    _statusLabel.stringValue = [NSString stringWithFormat:@"%d occurrence%@ found", count, (count == 1 ? @"" : @"s")];
    _statusLabel.textColor = [NSColor secondaryLabelColor];
}

- (void)replace {
    NSString *searchText = _findField.stringValue;
    NSString *replaceText = _replaceField.stringValue;
    if (searchText.length == 0 || !_targetEditor) return;

    ScintillaView *sci = _targetEditor.scintillaView;
    BOOL matchCase = (_matchCaseCheck.state == NSControlStateValueOn);
    BOOL wholeWord = (_wholeWordCheck.state == NSControlStateValueOn);
    BOOL wrap = (_wrapAroundCheck.state == NSControlStateValueOn);

    // Replace current selection if it matches, then find next
    NSString *sel = [sci selectedString];
    if ([sel isEqualToString:searchText]) {
        [sci findAndReplaceText:searchText byText:replaceText matchCase:matchCase wholeWord:wholeWord doAll:NO];
    }
    [sci findAndHighlightText:searchText matchCase:matchCase wholeWord:wholeWord scrollTo:YES wrap:wrap];
}

- (void)replaceAll {
    NSString *searchText = _findField.stringValue;
    NSString *replaceText = _replaceField.stringValue;
    if (searchText.length == 0 || !_targetEditor) return;

    ScintillaView *sci = _targetEditor.scintillaView;
    BOOL matchCase = (_matchCaseCheck.state == NSControlStateValueOn);
    BOOL wholeWord = (_wholeWordCheck.state == NSControlStateValueOn);

    int count = [sci findAndReplaceText:searchText
                                 byText:replaceText
                              matchCase:matchCase
                              wholeWord:wholeWord
                                  doAll:YES];
    _statusLabel.stringValue = [NSString stringWithFormat:@"%d replacement%@ made", count, (count == 1 ? @"" : @"s")];
    _statusLabel.textColor = [NSColor secondaryLabelColor];
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    if (event.type == NSEventTypeKeyDown) {
        if ([event.charactersIgnoringModifiers isEqualToString:@"f"] &&
            (event.modifierFlags & NSEventModifierFlagCommand)) {
            [self makeFirstResponder:_findField];
            return YES;
        }
        if (event.keyCode == 53) { // Escape
            [self orderOut:nil];
            return YES;
        }
    }
    return [super performKeyEquivalent:event];
}

@end
