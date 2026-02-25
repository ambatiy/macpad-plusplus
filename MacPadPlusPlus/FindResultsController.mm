#import "FindResultsController.h"

// ── Model ─────────────────────────────────────────────────────────────────────
@implementation FindResultEntry
@end

// ── Private interface ─────────────────────────────────────────────────────────
@interface FindResultsController ()
@property (nonatomic, strong) NSTableView   *tableView;
@property (nonatomic, strong) NSScrollView  *scrollView;
@property (nonatomic, strong) NSTextField   *headerLabel;
@property (nonatomic, strong) NSMutableArray<FindResultEntry *> *results;
@property (nonatomic, copy,   nullable) NSString *searchTerm;
@end

// ── Implementation ────────────────────────────────────────────────────────────
@implementation FindResultsController

static NSString * const kColLine = @"line";
static NSString * const kColText = @"text";

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 200)];
    root.wantsLayer = YES;
    _results = [NSMutableArray new];

    // ── Header bar constants ───────────────────────────────────────────────────
    static const CGFloat kHeaderH = 28.0;

    // ── Table inside a scroll view ────────────────────────────────────────────
    _tableView = [[NSTableView alloc] init];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.allowsMultipleSelection = NO;
    _tableView.rowHeight = 18.0;
    _tableView.intercellSpacing = NSMakeSize(0, 1);
    _tableView.headerView = nil;          // no column header bar
    _tableView.usesAlternatingRowBackgroundColors = YES;
    _tableView.columnAutoresizingStyle = NSTableViewLastColumnOnlyAutoresizingStyle;
    _tableView.target = self;
    _tableView.action = @selector(tableRowClicked:);

    // Line number column (fixed 58 px)
    NSTableColumn *lineCol = [[NSTableColumn alloc] initWithIdentifier:kColLine];
    lineCol.width    = 58;
    lineCol.minWidth = 42;
    lineCol.maxWidth = 80;
    lineCol.resizingMask = NSTableColumnNoResizing;
    [_tableView addTableColumn:lineCol];

    // Content column (fills remaining width)
    NSTableColumn *textCol = [[NSTableColumn alloc] initWithIdentifier:kColText];
    textCol.width    = 720;
    textCol.minWidth = 100;
    textCol.resizingMask = NSTableColumnAutoresizingMask;
    [_tableView addTableColumn:textCol];

    _scrollView = [[NSScrollView alloc]
                   initWithFrame:NSMakeRect(0, 0, 800, root.bounds.size.height - kHeaderH)];
    _scrollView.documentView = _tableView;
    _scrollView.hasVerticalScroller   = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers    = YES;
    _scrollView.autoresizingMask      = NSViewWidthSizable | NSViewHeightSizable;
    // Add scroll view FIRST so the header (added next) is on top in z-order
    [root addSubview:_scrollView];

    // ── Header bar (added LAST so it is always on top) ────────────────────────
    NSView *header = [[NSView alloc] initWithFrame:NSMakeRect(0, root.bounds.size.height - kHeaderH,
                                                              root.bounds.size.width, kHeaderH)];
    header.wantsLayer = YES;
    header.layer.backgroundColor = [NSColor controlBackgroundColor].CGColor;
    header.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;

    // Top separator line (between table and header)
    NSView *divider = [[NSView alloc] initWithFrame:NSMakeRect(0, kHeaderH - 1,
                                                              root.bounds.size.width, 1)];
    divider.wantsLayer = YES;
    divider.layer.backgroundColor = [NSColor separatorColor].CGColor;
    divider.autoresizingMask = NSViewWidthSizable;
    [header addSubview:divider];

    // Label
    _headerLabel = [NSTextField labelWithString:@"Find Results"];
    _headerLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
    _headerLabel.textColor = [NSColor secondaryLabelColor];
    _headerLabel.frame = NSMakeRect(8, (kHeaderH - 16) / 2, root.bounds.size.width - 80, 16);
    _headerLabel.autoresizingMask = NSViewWidthSizable;
    [header addSubview:_headerLabel];

    // Close button — uses [NSButton buttonWithTitle:] factory which properly
    // configures the button cell; NSBezelStyleInline renders cleanly in panels
    NSButton *closeBtn = [NSButton buttonWithTitle:@"✕ Close"
                                            target:self
                                            action:@selector(closeResults)];
    closeBtn.controlSize  = NSControlSizeSmall;
    closeBtn.bezelStyle   = NSBezelStyleRoundRect;
    closeBtn.font         = [NSFont systemFontOfSize:11];
    CGFloat bW = 64, bH = 18;
    closeBtn.frame        = NSMakeRect(root.bounds.size.width - bW - 6,
                                       (kHeaderH - bH) / 2, bW, bH);
    closeBtn.autoresizingMask = NSViewMinXMargin;
    [header addSubview:closeBtn];

    [root addSubview:header];  // on top of scrollView

    self.view = root;
}

// ── Public API ────────────────────────────────────────────────────────────────

- (void)showResults:(NSArray<FindResultEntry *> *)results
         searchTerm:(NSString *)term {
    _searchTerm = term;
    [_results setArray:results];

    NSUInteger n = results.count;
    NSString *plural = (n == 1) ? @"" : @"s";
    _headerLabel.stringValue = [NSString stringWithFormat:
        @"Find Results: \"%@\" — %lu match%@", term, (unsigned long)n, plural];

    [_tableView reloadData];

    if (n > 0) {
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
                byExtendingSelection:NO];
        [_tableView scrollRowToVisible:0];
    }
}

- (void)clearResults {
    _searchTerm = nil;
    [_results removeAllObjects];
    _headerLabel.stringValue = @"Find Results";
    [_tableView reloadData];
}

- (NSInteger)resultCount {
    return (NSInteger)_results.count;
}

- (void)closeResults {
    [_delegate findResultsControllerDidClose:self];
}

// ── Table click (navigate on single click) ────────────────────────────────────
- (void)tableRowClicked:(id)sender {
    NSInteger row = _tableView.clickedRow;
    if (row < 0 || row >= (NSInteger)_results.count) return;
    [_delegate findResultsController:self
                 didSelectLineNumber:_results[row].lineNumber];
}

// ── NSTableViewDataSource ──────────────────────────────────────────────────────
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return (NSInteger)_results.count;
}

// ── NSTableViewDelegate ────────────────────────────────────────────────────────
- (nullable NSView *)tableView:(NSTableView *)tableView
            viewForTableColumn:(nullable NSTableColumn *)tableColumn
                           row:(NSInteger)row {
    FindResultEntry *entry = _results[row];

    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier
                                                        owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
        NSTextField *lbl = [NSTextField labelWithString:@""];
        lbl.font = [NSFont monospacedSystemFontOfSize:11
                                               weight:NSFontWeightRegular];
        lbl.lineBreakMode = NSLineBreakByTruncatingTail;
        lbl.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        lbl.frame = cell.bounds;
        [cell addSubview:lbl];
        cell.textField = lbl;
        cell.identifier = tableColumn.identifier;
    }

    if ([tableColumn.identifier isEqualToString:kColLine]) {
        // Right-aligned line number in secondary colour
        cell.textField.stringValue  = [NSString stringWithFormat:@"%ld", (long)entry.lineNumber];
        cell.textField.textColor    = [NSColor tertiaryLabelColor];
        cell.textField.alignment    = NSTextAlignmentRight;
        cell.textField.font         = [NSFont monospacedSystemFontOfSize:11
                                                                  weight:NSFontWeightRegular];
        cell.textField.attributedStringValue = [[NSAttributedString alloc]
            initWithString:cell.textField.stringValue
                attributes:@{
                    NSFontAttributeName: cell.textField.font,
                    NSForegroundColorAttributeName: [NSColor tertiaryLabelColor],
                    NSParagraphStyleAttributeName: ({
                        NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
                        ps.alignment = NSTextAlignmentRight;
                        ps;
                    })
                }];
    } else {
        // Line content with match highlighted in orange
        NSString *trimmed = [entry.lineText
                             stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceCharacterSet]];
        if (trimmed.length == 0) trimmed = @" ";

        NSMutableAttributedString *attrStr =
            [[NSMutableAttributedString alloc] initWithString:trimmed];

        NSDictionary *baseAttrs = @{
            NSFontAttributeName:            [NSFont monospacedSystemFontOfSize:11
                                                                        weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [NSColor labelColor]
        };
        [attrStr addAttributes:baseAttrs range:NSMakeRange(0, trimmed.length)];

        // Highlight every occurrence of the search term
        if (_searchTerm.length > 0) {
            NSRange search = NSMakeRange(0, trimmed.length);
            while (search.location < trimmed.length) {
                NSRange found = [trimmed rangeOfString:_searchTerm
                                               options:NSCaseInsensitiveSearch
                                                 range:search];
                if (found.location == NSNotFound) break;
                [attrStr addAttributes:@{
                    NSForegroundColorAttributeName: [NSColor systemOrangeColor],
                    NSFontAttributeName:            [NSFont monospacedSystemFontOfSize:11
                                                                               weight:NSFontWeightBold]
                } range:found];
                search = NSMakeRange(NSMaxRange(found),
                                     trimmed.length - NSMaxRange(found));
            }
        }

        cell.textField.attributedStringValue = attrStr;
    }

    return cell;
}

// Navigate on selection change (keyboard arrow keys)
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = _tableView.selectedRow;
    if (row < 0 || row >= (NSInteger)_results.count) return;
    [_delegate findResultsController:self
                 didSelectLineNumber:_results[row].lineNumber];
}

@end
