#import "StatusBarController.h"
#import "SyntaxHighlighter.h"

@interface StatusBarController ()
@property (nonatomic, strong) NSTextField *positionLabel;
@property (nonatomic, strong) NSTextField *selectionLabel;
@property (nonatomic, strong) NSTextField *languageLabel;
@property (nonatomic, strong) NSTextField *encodingLabel;
@property (nonatomic, strong) NSTextField *lineEndingLabel;
@property (nonatomic, strong) NSTextField *linesLabel;
@property (nonatomic, strong) NSView *separatorView;
@end

@implementation StatusBarController

- (void)loadView {
    NSView *v = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 24)];
    v.wantsLayer = YES;
    v.layer.backgroundColor = [NSColor colorNamed:@"controlBackgroundColor"] ?
        [NSColor controlBackgroundColor].CGColor :
        [NSColor colorWithRed:0.94 green:0.94 blue:0.94 alpha:1.0].CGColor;

    // Top border
    NSView *border = [[NSView alloc] initWithFrame:NSMakeRect(0, 23, 800, 1)];
    border.wantsLayer = YES;
    border.layer.backgroundColor = [NSColor separatorColor].CGColor;
    border.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [v addSubview:border];

    // Create labels
    _positionLabel = [self makeLabel:@"Ln 1, Col 1" x:8];
    _selectionLabel = [self makeLabel:@"" x:140];
    _languageLabel = [self makeLabel:@"Plain Text" x:320];
    _encodingLabel = [self makeLabel:@"UTF-8" x:480];
    _lineEndingLabel = [self makeLabel:@"Unix (LF)" x:570];
    _linesLabel = [self makeLabel:@"Lines: 1" x:660];

    for (NSTextField *lbl in @[_positionLabel, _selectionLabel, _languageLabel, _encodingLabel, _lineEndingLabel, _linesLabel]) {
        [v addSubview:lbl];
    }

    // Separators between sections
    CGFloat sepXPositions[] = {135.0, 315.0, 475.0, 565.0, 655.0};
    for (int si = 0; si < 5; si++) {
        NSView *sep = [[NSView alloc] initWithFrame:NSMakeRect(sepXPositions[si], 4, 1, 16)];
        sep.wantsLayer = YES;
        sep.layer.backgroundColor = [NSColor separatorColor].CGColor;
        [v addSubview:sep];
    }

    self.view = v;
}

- (NSTextField *)makeLabel:(NSString *)text x:(CGFloat)x {
    NSTextField *lbl = [NSTextField labelWithString:text];
    lbl.font = [NSFont systemFontOfSize:11];
    lbl.textColor = [NSColor secondaryLabelColor];
    lbl.frame = NSMakeRect(x, 4, 170, 16);
    lbl.autoresizingMask = NSViewMinYMargin;
    lbl.lineBreakMode = NSLineBreakByTruncatingTail;
    return lbl;
}

- (void)updateFromDocument:(MPDocument *)document line:(NSInteger)line column:(NSInteger)column selLen:(NSInteger)selLen {
    _currentLine = line;
    _currentColumn = column;
    _selectionLength = selLen;

    _positionLabel.stringValue = [NSString stringWithFormat:@"Ln %ld, Col %ld", (long)line, (long)column];

    if (selLen > 0) {
        _selectionLabel.stringValue = [NSString stringWithFormat:@"Sel: %ld char%@", (long)selLen, (selLen == 1 ? @"" : @"s")];
    } else {
        _selectionLabel.stringValue = @"";
    }

    if (document) {
        _languageLabel.stringValue = [[SyntaxHighlighter sharedHighlighter] displayNameForLanguage:document.language];
        _encodingLabel.stringValue = [document encodingName];
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
    _positionLabel.stringValue = [NSString stringWithFormat:@"Ln %ld, Col %ld", (long)_currentLine, (long)_currentColumn];
}

- (void)setCurrentColumn:(NSInteger)currentColumn {
    _currentColumn = currentColumn;
    _positionLabel.stringValue = [NSString stringWithFormat:@"Ln %ld, Col %ld", (long)_currentLine, (long)_currentColumn];
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
