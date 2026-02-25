#import "FindReplacePanel.h"
#import "EditorView.h"
#import "ScintillaView.h"
#import "Scintilla.h"

static FindReplacePanel *sSharedPanel = nil;

@interface FindReplacePanel ()
// Find row container (moveable between find/replace modes)
@property (nonatomic, strong) NSView      *findRowView;
@property (nonatomic, strong) NSTextField *findField;
@property (nonatomic, strong) NSButton    *findNextBtn;
@property (nonatomic, strong) NSButton    *findPrevBtn;
@property (nonatomic, strong) NSButton    *findAllBtn;
@property (nonatomic, strong) NSButton    *markAllBtn;
// Replace row (shown in replace mode, always at kReplaceRowY)
@property (nonatomic, strong) NSView      *replaceRow;
@property (nonatomic, strong) NSTextField *replaceField;
@property (nonatomic, strong) NSButton    *replaceBtn;
@property (nonatomic, strong) NSButton    *replaceAllBtn;
// Options
@property (nonatomic, strong) NSButton    *matchCaseCheck;
@property (nonatomic, strong) NSButton    *wholeWordCheck;
@property (nonatomic, strong) NSButton    *regexCheck;
@property (nonatomic, strong) NSButton    *wrapAroundCheck;
// Status
@property (nonatomic, strong) NSTextField *statusLabel;
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
    // ── Row layout (y measured from bottom of content view) ──────────────────
    //
    //  Find mode (content h=116):
    //   y=10   [x]Match case  [x]Whole word  [x]Regex  [x]Wrap
    //   y=40   [Find All]  [Mark All]  <status label>
    //   y=70   Find: [___________________field___________] [Find Next] [FindPrev]
    //
    //  Find & Replace mode (content h=148):
    //   y=10   [x]Match case  [x]Whole word  [x]Regex  [x]Wrap
    //   y=40   [Find All]  [Mark All]  <status label>
    //   y=70   Replace: [_________________field__________] [Replace] [Repl.All]
    //   y=102  Find:    [_________________field__________] [FindNext] [FindPrev]
    //
    //  The replaceRow sits at fixed y=70; the findRowView moves from y=70
    //  (find mode) to y=102 (replace mode) via showFindMode / showFindAndReplaceMode.

    self.title = @"Find";
    self.level = NSFloatingWindowLevel;
    [self setMinSize:NSMakeSize(500, 100)];
    [self center];

    NSView *content = self.contentView;

    // Geometry constants (based on default window width 560)
    static const CGFloat kW  = 548;   // usable width
    static const CGFloat kBW = 90;    // button width
    static const CGFloat kLW = 64;    // label column width
    static const CGFloat kFX = 78;    // field x-start
    // Field width = remaining after label, two buttons, and gaps
    static const CGFloat kFW = kW - kFX - kBW * 2 - 8;
    static const CGFloat kB1 = kFX + kFW + 4;   // first button x
    static const CGFloat kB2 = kB1 + kBW + 4;   // second button x

    // ── Options row (always at y=10) ─────────────────────────────────────────
    _matchCaseCheck = [NSButton checkboxWithTitle:@"Match case" target:nil action:nil];
    _matchCaseCheck.frame = NSMakeRect(12, 10, 108, 20);
    [content addSubview:_matchCaseCheck];

    _wholeWordCheck = [NSButton checkboxWithTitle:@"Whole word" target:nil action:nil];
    _wholeWordCheck.frame = NSMakeRect(126, 10, 108, 20);
    [content addSubview:_wholeWordCheck];

    _regexCheck = [NSButton checkboxWithTitle:@"Regex" target:nil action:nil];
    _regexCheck.frame = NSMakeRect(240, 10, 80, 20);
    [content addSubview:_regexCheck];

    _wrapAroundCheck = [NSButton checkboxWithTitle:@"Wrap around" target:nil action:nil];
    _wrapAroundCheck.frame = NSMakeRect(326, 10, 120, 20);
    _wrapAroundCheck.state = NSControlStateValueOn;
    [content addSubview:_wrapAroundCheck];

    // ── Find All / Mark All row (always at y=40) ──────────────────────────────
    _findAllBtn = [NSButton buttonWithTitle:@"Find All" target:self action:@selector(findAll)];
    _findAllBtn.frame = NSMakeRect(12, 40, 88, 22);
    [content addSubview:_findAllBtn];

    _markAllBtn = [NSButton buttonWithTitle:@"Mark All" target:self action:@selector(markAll)];
    _markAllBtn.frame = NSMakeRect(106, 40, 88, 22);
    [content addSubview:_markAllBtn];

    _statusLabel = [NSTextField labelWithString:@""];
    _statusLabel.frame = NSMakeRect(200, 43, kW - 200, 16);
    _statusLabel.textColor = [NSColor tertiaryLabelColor];
    _statusLabel.font = [NSFont systemFontOfSize:11];
    _statusLabel.autoresizingMask = NSViewWidthSizable;
    [content addSubview:_statusLabel];

    // ── Replace row (y=70, hidden by default) ─────────────────────────────────
    _replaceRow = [[NSView alloc] initWithFrame:NSMakeRect(0, 70, kW + 12, 28)];
    _replaceRow.autoresizingMask = NSViewWidthSizable;
    _replaceRow.hidden = YES;

    NSTextField *replaceLbl = [NSTextField labelWithString:@"Replace:"];
    replaceLbl.frame = NSMakeRect(12, 4, kLW, 20);
    [_replaceRow addSubview:replaceLbl];

    _replaceField = [[NSTextField alloc] initWithFrame:NSMakeRect(kFX, 3, kFW, 22)];
    _replaceField.placeholderString = @"Replace with";
    _replaceField.autoresizingMask = NSViewWidthSizable;
    [_replaceRow addSubview:_replaceField];

    _replaceBtn = [NSButton buttonWithTitle:@"Replace" target:self action:@selector(replace)];
    _replaceBtn.frame = NSMakeRect(kB1, 3, kBW, 22);
    _replaceBtn.autoresizingMask = NSViewMinXMargin;
    [_replaceRow addSubview:_replaceBtn];

    _replaceAllBtn = [NSButton buttonWithTitle:@"Replace All" target:self action:@selector(replaceAll)];
    _replaceAllBtn.frame = NSMakeRect(kB2, 3, kBW, 22);
    _replaceAllBtn.autoresizingMask = NSViewMinXMargin;
    [_replaceRow addSubview:_replaceAllBtn];

    [content addSubview:_replaceRow];

    // ── Find row container (starts at y=70; moves to y=102 in replace mode) ──
    _findRowView = [[NSView alloc] initWithFrame:NSMakeRect(0, 70, kW + 12, 28)];
    _findRowView.autoresizingMask = NSViewWidthSizable;

    NSTextField *findLbl = [NSTextField labelWithString:@"Find:"];
    findLbl.frame = NSMakeRect(12, 4, kLW, 20);
    [_findRowView addSubview:findLbl];

    _findField = [[NSTextField alloc] initWithFrame:NSMakeRect(kFX, 3, kFW, 22)];
    _findField.placeholderString = @"Search text";
    _findField.autoresizingMask = NSViewWidthSizable;
    [_findRowView addSubview:_findField];

    _findNextBtn = [NSButton buttonWithTitle:@"Find Next" target:self action:@selector(findNext)];
    _findNextBtn.frame = NSMakeRect(kB1, 3, kBW, 22);
    _findNextBtn.autoresizingMask = NSViewMinXMargin;
    _findNextBtn.keyEquivalent = @"\r";
    [_findRowView addSubview:_findNextBtn];

    _findPrevBtn = [NSButton buttonWithTitle:@"Find Prev" target:self action:@selector(findPrevious)];
    _findPrevBtn.frame = NSMakeRect(kB2, 3, kBW, 22);
    _findPrevBtn.autoresizingMask = NSViewMinXMargin;
    [_findRowView addSubview:_findPrevBtn];

    [content addSubview:_findRowView];
}

- (void)showFindMode {
    self.title = @"Find";
    _isReplaceMode = NO;
    _replaceRow.hidden = YES;
    // Find row sits at y=70 in find-only mode
    NSRect fr = _findRowView.frame;
    fr.origin.y = 70;
    _findRowView.frame = fr;
    [self setContentSize:NSMakeSize(self.frame.size.width, 116)];
    [self makeKeyAndOrderFront:nil];
    [self makeFirstResponder:_findField];
}

- (void)showFindAndReplaceMode {
    self.title = @"Find & Replace";
    _isReplaceMode = YES;
    // Resize first so the find row lands in the right place
    [self setContentSize:NSMakeSize(self.frame.size.width, 148)];
    _replaceRow.hidden = NO;
    // Find row moves up to y=102 to make room for replace row at y=70
    NSRect fr = _findRowView.frame;
    fr.origin.y = 102;
    _findRowView.frame = fr;
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

- (void)findAll {
    NSString *term = _findField.stringValue;
    if (term.length == 0 || !_targetEditor) return;

    BOOL matchCase = (_matchCaseCheck.state == NSControlStateValueOn);
    BOOL wholeWord = (_wholeWordCheck.state == NSControlStateValueOn);

    NSString *content = [_targetEditor.scintillaView string] ?: @"";
    NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
    NSMutableArray<FindResultEntry *> *results = [NSMutableArray array];
    NSStringCompareOptions opts = matchCase ? 0 : NSCaseInsensitiveSearch;
    NSCharacterSet *wordChars = [NSCharacterSet alphanumericCharacterSet];

    for (NSInteger i = 0; i < (NSInteger)lines.count; i++) {
        NSString *line = lines[i];
        NSRange search = NSMakeRange(0, line.length);
        while (search.location < line.length) {
            NSRange found = [line rangeOfString:term options:opts range:search];
            if (found.location == NSNotFound) break;

            // Whole-word boundary check
            if (wholeWord) {
                BOOL leftBound  = (found.location == 0 ||
                    ![wordChars characterIsMember:[line characterAtIndex:found.location - 1]]);
                NSUInteger end  = NSMaxRange(found);
                BOOL rightBound = (end >= line.length ||
                    ![wordChars characterIsMember:[line characterAtIndex:end]]);
                if (!leftBound || !rightBound) {
                    search = NSMakeRange(NSMaxRange(found), line.length - NSMaxRange(found));
                    continue;
                }
            }

            FindResultEntry *entry = [[FindResultEntry alloc] init];
            entry.lineNumber  = i + 1;
            entry.lineText    = line;
            entry.matchRange  = found;
            [results addObject:entry];
            break; // one entry per line (first match on the line)
        }
    }

    NSUInteger n = results.count;
    if (n == 0) {
        _statusLabel.stringValue = @"Not found";
        _statusLabel.textColor   = [NSColor systemRedColor];
        NSBeep();
    } else {
        _statusLabel.stringValue = [NSString stringWithFormat:@"%lu line%@ found",
                                    (unsigned long)n, (n == 1 ? @"" : @"s")];
        _statusLabel.textColor   = [NSColor secondaryLabelColor];
    }

    [_findAllDelegate findPanel:self didFindAll:results forTerm:term];
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
