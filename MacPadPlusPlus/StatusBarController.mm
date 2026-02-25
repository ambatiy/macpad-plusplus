#import "StatusBarController.h"
#import "SyntaxHighlighter.h"

@interface StatusBarController ()
@property (nonatomic, strong) NSTextField *positionLabel;
@property (nonatomic, strong) NSTextField *selectionLabel;
@property (nonatomic, strong) NSTextField *languageLabel;
@property (nonatomic, strong) NSTextField *encodingLabel;
@property (nonatomic, strong) NSTextField *lineEndingLabel;
@property (nonatomic, strong) NSTextField *linesLabel;
@end

@implementation StatusBarController

- (void)loadView {
    NSView *v = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 24)];
    v.wantsLayer = YES;
    v.layer.backgroundColor = [NSColor controlBackgroundColor].CGColor;

    // Top border
    NSView *border = [[NSView alloc] initWithFrame:NSMakeRect(0, 23, 1024, 1)];
    border.wantsLayer = YES;
    border.layer.backgroundColor = [NSColor separatorColor].CGColor;
    border.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [v addSubview:border];

    // Create labels
    _positionLabel   = [self makeLabel:@"Ln 1, Col 1"];
    _selectionLabel  = [self makeLabel:@""];
    _languageLabel   = [self makeLabel:@"Plain Text"];
    _encodingLabel   = [self makeLabel:@"UTF-8"];
    _lineEndingLabel = [self makeLabel:@"Unix (LF)"];
    _linesLabel      = [self makeLabel:@"Lines: 1"];

    // Left sub-stack: position | sel  (pinned to leading edge)
    NSStackView *leftStack = [NSStackView stackViewWithViews:@[
        _positionLabel, [self makeSepView], _selectionLabel
    ]];
    leftStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    leftStack.spacing     = 6;
    leftStack.alignment   = NSLayoutAttributeCenterY;

    // Right sub-stack: language | encoding | line ending | lines  (pinned to trailing edge)
    NSStackView *rightStack = [NSStackView stackViewWithViews:@[
        _languageLabel,   [self makeSepView],
        _encodingLabel,   [self makeSepView],
        _lineEndingLabel, [self makeSepView],
        _linesLabel
    ]];
    rightStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    rightStack.spacing     = 6;
    rightStack.alignment   = NSLayoutAttributeCenterY;

    // Main container — gravity areas push left/right stacks to their respective edges
    NSStackView *main = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 24)];
    main.orientation   = NSUserInterfaceLayoutOrientationHorizontal;
    main.distribution  = NSStackViewDistributionGravityAreas;
    main.alignment     = NSLayoutAttributeCenterY;
    main.edgeInsets    = NSEdgeInsetsMake(0, 8, 0, 8);
    main.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [main addView:leftStack  inGravity:NSStackViewGravityLeading];
    [main addView:rightStack inGravity:NSStackViewGravityTrailing];
    [v addSubview:main];

    self.view = v;
}

// Label without a fixed frame — NSStackView sizes it to intrinsic content
- (NSTextField *)makeLabel:(NSString *)text {
    NSTextField *lbl = [NSTextField labelWithString:text];
    lbl.font          = [NSFont systemFontOfSize:11];
    lbl.textColor     = [NSColor secondaryLabelColor];
    lbl.lineBreakMode = NSLineBreakByTruncatingTail;
    return lbl;
}

// 1×16 px vertical separator with explicit size constraints for NSStackView
- (NSView *)makeSepView {
    NSView *sep = [[NSView alloc] initWithFrame:NSZeroRect];
    sep.wantsLayer = YES;
    sep.layer.backgroundColor = [NSColor separatorColor].CGColor;
    [sep addConstraint:[NSLayoutConstraint constraintWithItem:sep
                                                    attribute:NSLayoutAttributeWidth
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:nil
                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                   multiplier:1 constant:1]];
    [sep addConstraint:[NSLayoutConstraint constraintWithItem:sep
                                                    attribute:NSLayoutAttributeHeight
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:nil
                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                   multiplier:1 constant:16]];
    return sep;
}

- (void)updateFromDocument:(MPDocument *)document line:(NSInteger)line column:(NSInteger)column selLen:(NSInteger)selLen {
    _currentLine   = line;
    _currentColumn = column;
    _selectionLength = selLen;

    _positionLabel.stringValue = [NSString stringWithFormat:@"Ln %ld, Col %ld", (long)line, (long)column];

    if (selLen > 0) {
        _selectionLabel.stringValue = [NSString stringWithFormat:@"Sel: %ld char%@",
                                       (long)selLen, (selLen == 1 ? @"" : @"s")];
    } else {
        _selectionLabel.stringValue = @"";
    }

    if (document) {
        _languageLabel.stringValue   = [[SyntaxHighlighter sharedHighlighter] displayNameForLanguage:document.language];
        _encodingLabel.stringValue   = [document encodingName];
        _lineEndingLabel.stringValue = [document lineEndingName];
    }
}

- (void)setLanguage:(NSString *)language {
    _language = language;
    _languageLabel.stringValue = [[SyntaxHighlighter sharedHighlighter] displayNameForLanguage:language];
}

- (void)setEncoding:(MPEncoding)encoding {
    _encoding = encoding;
    NSString *names[] = {@"UTF-8", @"UTF-8 BOM", @"UTF-16 BE", @"UTF-16 LE", @"ASCII", @"Latin-1"};
    if (encoding >= 0 && encoding < 6) {
        _encodingLabel.stringValue = names[encoding];
    }
}

- (void)setLineEnding:(MPLineEnding)lineEnding {
    _lineEnding = lineEnding;
    NSString *names[] = {@"Unix (LF)", @"Windows (CRLF)", @"Old Mac (CR)"};
    if (lineEnding >= 0 && lineEnding < 3) {
        _lineEndingLabel.stringValue = names[lineEnding];
    }
}

- (void)setCurrentLine:(NSInteger)currentLine {
    _currentLine = currentLine;
    _positionLabel.stringValue = [NSString stringWithFormat:@"Ln %ld, Col %ld",
                                  (long)_currentLine, (long)_currentColumn];
}

- (void)setCurrentColumn:(NSInteger)currentColumn {
    _currentColumn = currentColumn;
    _positionLabel.stringValue = [NSString stringWithFormat:@"Ln %ld, Col %ld",
                                  (long)_currentLine, (long)_currentColumn];
}

- (void)setTotalLines:(NSInteger)totalLines {
    _totalLines = totalLines;
    _linesLabel.stringValue = [NSString stringWithFormat:@"Lines: %ld", (long)totalLines];
}

- (void)setSelectionLength:(NSInteger)selectionLength {
    _selectionLength = selectionLength;
    if (selectionLength > 0) {
        _selectionLabel.stringValue = [NSString stringWithFormat:@"Sel: %ld char%@",
                                       (long)selectionLength, (selectionLength == 1 ? @"" : @"s")];
    } else {
        _selectionLabel.stringValue = @"";
    }
}

@end
