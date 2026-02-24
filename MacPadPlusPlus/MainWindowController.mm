#import "MainWindowController.h"
#import "EditorView.h"
#import "StatusBarController.h"
#import "FindReplacePanel.h"
#import "FindResultsController.h"
#import "SyntaxHighlighter.h"
#import "PreferencesWindowController.h"
#import "AppDelegate.h"

@interface AppDelegate (RecentFiles)
- (void)addRecentFile:(NSURL *)url;
@end

// Toolbar item identifiers
static NSString * const kToolbarNew         = @"ToolbarNew";
static NSString * const kToolbarOpen        = @"ToolbarOpen";
static NSString * const kToolbarSave        = @"ToolbarSave";
static NSString * const kToolbarSaveAll     = @"ToolbarSaveAll";
static NSString * const kToolbarCut         = @"ToolbarCut";
static NSString * const kToolbarCopy        = @"ToolbarCopy";
static NSString * const kToolbarPaste       = @"ToolbarPaste";
static NSString * const kToolbarUndo        = @"ToolbarUndo";
static NSString * const kToolbarRedo        = @"ToolbarRedo";
static NSString * const kToolbarFind        = @"ToolbarFind";
static NSString * const kToolbarFindReplace = @"ToolbarFindReplace";
static NSString * const kToolbarZoomIn      = @"ToolbarZoomIn";
static NSString * const kToolbarZoomOut     = @"ToolbarZoomOut";
static NSString * const kToolbarZoomReset   = @"ToolbarZoomReset";

// Tab button height
static const CGFloat kTabBarHeight = 30.0;
static const CGFloat kStatusBarHeight = 24.0;
static const CGFloat kTabMinWidth = 100.0;
static const CGFloat kTabMaxWidth = 220.0;

#pragma mark - TabButton

@interface MPTabButton : NSButton
@property (nonatomic, strong) MPDocument *document;
@property (nonatomic, weak) id closeTarget;
@property (nonatomic) SEL closeAction;
@property (nonatomic, assign) BOOL isSelected;
@end

@implementation MPTabButton

- (void)drawRect:(NSRect)dirtyRect {
    NSColor *bg = self.isSelected
        ? [NSColor controlBackgroundColor]
        : [NSColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];

    [bg setFill];
    NSRectFill(self.bounds);

    // Top border for selected tab
    if (self.isSelected) {
        [[NSColor systemBlueColor] setFill];
        NSRectFill(NSMakeRect(0, self.bounds.size.height - 2, self.bounds.size.width, 2));
    }

    // Bottom border for unselected
    if (!self.isSelected) {
        [[NSColor separatorColor] setFill];
        NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    }

    // Right separator
    [[NSColor separatorColor] setFill];
    NSRectFill(NSMakeRect(self.bounds.size.width - 1, 0, 1, self.bounds.size.height));

    // Title
    NSString *title = self.title;
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12],
        NSForegroundColorAttributeName: self.isSelected ? [NSColor labelColor] : [NSColor secondaryLabelColor],
    };
    NSSize ts = [title sizeWithAttributes:attrs];
    CGFloat tx = (self.bounds.size.width - ts.width - 16) / 2;
    [title drawAtPoint:NSMakePoint(tx, (self.bounds.size.height - ts.height) / 2) withAttributes:attrs];

    // Close button (×) on the right
    NSString *closeStr = @"✕";
    NSDictionary *closeAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:9],
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor],
    };
    NSSize cs = [closeStr sizeWithAttributes:closeAttrs];
    [closeStr drawAtPoint:NSMakePoint(self.bounds.size.width - cs.width - 8,
                                      (self.bounds.size.height - cs.height) / 2)
           withAttributes:closeAttrs];
}

- (void)mouseUp:(NSEvent *)event {
    NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];
    // Check if close button was clicked (right 20px)
    if (pt.x > self.bounds.size.width - 22) {
        [self.closeTarget performSelector:self.closeAction withObject:self];
        return;
    }
    [super mouseUp:event];
}

@end

#pragma mark - TabBarView

@interface MPTabBarView : NSView
@property (nonatomic, strong) NSMutableArray<MPTabButton *> *tabButtons;
@property (nonatomic, weak) id selectTarget;
@property (nonatomic) SEL selectAction;
@property (nonatomic, weak) id closeTarget;
@property (nonatomic) SEL closeAction;
@end

@implementation MPTabBarView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0].CGColor;
        _tabButtons = [NSMutableArray new];
    }
    return self;
}

- (void)addTabForDocument:(MPDocument *)document {
    MPTabButton *btn = [[MPTabButton alloc] initWithFrame:NSZeroRect];
    btn.document = document;
    btn.title = document.displayTitle;
    btn.isSelected = NO;
    btn.target = self.selectTarget;
    btn.action = self.selectAction;
    btn.closeTarget = self.closeTarget;
    btn.closeAction = self.closeAction;
    [_tabButtons addObject:btn];
    [self addSubview:btn];
    [self layoutTabs];
}

- (void)removeTabForDocument:(MPDocument *)document {
    MPTabButton *found = nil;
    for (MPTabButton *btn in _tabButtons) {
        if (btn.document == document) { found = btn; break; }
    }
    if (found) {
        [found removeFromSuperview];
        [_tabButtons removeObject:found];
        [self layoutTabs];
    }
}

- (void)selectDocument:(MPDocument *)document {
    for (MPTabButton *btn in _tabButtons) {
        btn.isSelected = (btn.document == document);
        btn.title = btn.document.displayTitle;
        [btn setNeedsDisplay:YES];
    }
}

- (void)refreshTitles {
    for (MPTabButton *btn in _tabButtons) {
        btn.title = btn.document.displayTitle;
        [btn setNeedsDisplay:YES];
    }
}

- (void)layoutTabs {
    CGFloat totalWidth = self.bounds.size.width;
    NSInteger count = _tabButtons.count;
    if (count == 0) return;

    CGFloat tabWidth = MIN(kTabMaxWidth, MAX(kTabMinWidth, totalWidth / count));
    CGFloat x = 0;
    for (MPTabButton *btn in _tabButtons) {
        btn.frame = NSMakeRect(x, 0, tabWidth, kTabBarHeight);
        x += tabWidth;
    }
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    [self layoutTabs];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Bottom border
    [[NSColor separatorColor] setFill];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
}

@end

#pragma mark - MainWindowController

@interface MainWindowController () <EditorViewDelegate, NSWindowDelegate, NSSplitViewDelegate, NSToolbarDelegate>
@property (nonatomic, strong) NSMutableArray<MPDocument *> *mutableDocuments;
@property (nonatomic, strong, nullable) MPDocument *mutableActiveDocument;
@property (nonatomic, strong) NSMutableDictionary<NSString *, EditorView *> *editorViews;
@property (nonatomic, strong) MPTabBarView *tabBarView;
@property (nonatomic, strong) NSSplitView *editorSplitView;
@property (nonatomic, strong) NSView *editorContainer;
@property (nonatomic, strong) FindResultsController *findResultsController;
@property (nonatomic, strong) StatusBarController *statusBarController;
@property (nonatomic, strong) NSToolbar *toolbar;
@end

@implementation MainWindowController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc]
                        initWithContentRect:NSMakeRect(100, 100, 1024, 768)
                        styleMask:(NSWindowStyleMaskTitled |
                                   NSWindowStyleMaskClosable |
                                   NSWindowStyleMaskMiniaturizable |
                                   NSWindowStyleMaskResizable)
                        backing:NSBackingStoreBuffered
                        defer:NO];
    window.title = @"MacPad++";
    window.titlebarAppearsTransparent = NO;
    [window setMinSize:NSMakeSize(400, 300)];

    self = [super initWithWindow:window];
    if (self) {
        _mutableDocuments = [NSMutableArray new];
        _editorViews = [NSMutableDictionary new];
        window.delegate = self;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    NSView *content = self.window.contentView;
    NSRect bounds = content.bounds;

    // --- Toolbar ---
    [self setupToolbar];

    // --- Tab bar ---
    _tabBarView = [[MPTabBarView alloc] initWithFrame:NSMakeRect(0, bounds.size.height - kTabBarHeight, bounds.size.width, kTabBarHeight)];
    _tabBarView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    _tabBarView.selectTarget = self;
    _tabBarView.selectAction = @selector(tabButtonClicked:);
    _tabBarView.closeTarget = self;
    _tabBarView.closeAction = @selector(tabCloseButtonClicked:);
    [content addSubview:_tabBarView];

    // --- Status bar ---
    _statusBarController = [[StatusBarController alloc] init];
    [_statusBarController loadView];
    _statusBarController.view.frame = NSMakeRect(0, 0, bounds.size.width, kStatusBarHeight);
    _statusBarController.view.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    [content addSubview:_statusBarController.view];

    // --- Split view: editor (top) + find results (bottom, initially collapsed) ---
    CGFloat splitTop = bounds.size.height - kTabBarHeight;
    CGFloat splitH   = splitTop - kStatusBarHeight;

    _editorSplitView = [[NSSplitView alloc]
                        initWithFrame:NSMakeRect(0, kStatusBarHeight, bounds.size.width, splitH)];
    _editorSplitView.vertical      = NO;          // horizontal divider (top/bottom)
    _editorSplitView.dividerStyle  = NSSplitViewDividerStyleThin;
    _editorSplitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _editorSplitView.delegate      = self;
    [content addSubview:_editorSplitView];

    // Top portion: editor views live here
    _editorContainer = [[NSView alloc] initWithFrame:_editorSplitView.bounds];
    [_editorSplitView addSubview:_editorContainer];

    // Bottom portion: find results panel
    _findResultsController = [[FindResultsController alloc] init];
    [_findResultsController loadView];
    _findResultsController.delegate = self;
    _findResultsController.view.frame = NSMakeRect(0, 0, bounds.size.width, 0);
    [_editorSplitView addSubview:_findResultsController.view];

    // Collapse the find results panel once layout is complete
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat h = self->_editorSplitView.bounds.size.height;
        if (h > 0) {
            [self->_editorSplitView setPosition:h ofDividerAtIndex:0];
        }
    });
}

- (void)setupToolbar {
    _toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainToolbar"];
    _toolbar.delegate = self;
    _toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    _toolbar.sizeMode = NSToolbarSizeModeRegular;
    _toolbar.allowsUserCustomization = YES;
    _toolbar.autosavesConfiguration = YES;
    self.window.toolbar = _toolbar;
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        kToolbarNew, kToolbarOpen, kToolbarSave, kToolbarSaveAll,
        NSToolbarSeparatorItemIdentifier,
        kToolbarCut, kToolbarCopy, kToolbarPaste,
        NSToolbarSeparatorItemIdentifier,
        kToolbarUndo, kToolbarRedo,
        NSToolbarSeparatorItemIdentifier,
        kToolbarFind, kToolbarFindReplace,
        NSToolbarSeparatorItemIdentifier,
        kToolbarZoomIn, kToolbarZoomOut, kToolbarZoomReset,
    ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        kToolbarNew, kToolbarOpen, kToolbarSave, kToolbarSaveAll,
        kToolbarCut, kToolbarCopy, kToolbarPaste,
        kToolbarUndo, kToolbarRedo,
        kToolbarFind, kToolbarFindReplace,
        kToolbarZoomIn, kToolbarZoomOut, kToolbarZoomReset,
        NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
    ];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {

    // Helper block to create a standard icon+label toolbar item
    NSToolbarItem *(^makeItem)(NSString *, NSString *, NSString *, SEL) =
    ^NSToolbarItem *(NSString *ident, NSString *label, NSString *symbol, SEL action) {
        NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:ident];
        item.label          = label;
        item.paletteLabel   = label;
        item.toolTip        = label;
        item.image          = [NSImage imageWithSystemSymbolName:symbol
                                        accessibilityDescription:label];
        item.target         = self;
        item.action         = action;
        return item;
    };

    if ([itemIdentifier isEqualToString:kToolbarNew]) {
        return makeItem(kToolbarNew, @"New", @"doc.badge.plus", @selector(newDocument:));
    }
    if ([itemIdentifier isEqualToString:kToolbarOpen]) {
        return makeItem(kToolbarOpen, @"Open", @"folder", @selector(openDocument:));
    }
    if ([itemIdentifier isEqualToString:kToolbarSave]) {
        return makeItem(kToolbarSave, @"Save", @"square.and.arrow.down", @selector(saveDocument:));
    }
    if ([itemIdentifier isEqualToString:kToolbarSaveAll]) {
        return makeItem(kToolbarSaveAll, @"Save All", @"square.and.arrow.down.on.square", @selector(saveAllDocuments:));
    }
    if ([itemIdentifier isEqualToString:kToolbarCut]) {
        NSToolbarItem *item = makeItem(kToolbarCut, @"Cut", @"scissors", @selector(cut:));
        item.target = nil;   // targets first responder
        return item;
    }
    if ([itemIdentifier isEqualToString:kToolbarCopy]) {
        NSToolbarItem *item = makeItem(kToolbarCopy, @"Copy", @"doc.on.doc", @selector(copy:));
        item.target = nil;
        return item;
    }
    if ([itemIdentifier isEqualToString:kToolbarPaste]) {
        NSToolbarItem *item = makeItem(kToolbarPaste, @"Paste", @"doc.on.clipboard", @selector(paste:));
        item.target = nil;
        return item;
    }
    if ([itemIdentifier isEqualToString:kToolbarUndo]) {
        NSToolbarItem *item = makeItem(kToolbarUndo, @"Undo", @"arrow.uturn.backward", @selector(undo:));
        item.target = nil;
        return item;
    }
    if ([itemIdentifier isEqualToString:kToolbarRedo]) {
        NSToolbarItem *item = makeItem(kToolbarRedo, @"Redo", @"arrow.uturn.forward", @selector(redo:));
        item.target = nil;
        return item;
    }
    if ([itemIdentifier isEqualToString:kToolbarFind]) {
        return makeItem(kToolbarFind, @"Find", @"magnifyingglass", @selector(showFindPanel:));
    }
    if ([itemIdentifier isEqualToString:kToolbarFindReplace]) {
        return makeItem(kToolbarFindReplace, @"Find & Replace", @"arrow.triangle.2.circlepath",
                        @selector(showFindAndReplacePanel:));
    }
    if ([itemIdentifier isEqualToString:kToolbarZoomIn]) {
        return makeItem(kToolbarZoomIn, @"Zoom In", @"plus.magnifyingglass", @selector(zoomIn:));
    }
    if ([itemIdentifier isEqualToString:kToolbarZoomOut]) {
        return makeItem(kToolbarZoomOut, @"Zoom Out", @"minus.magnifyingglass", @selector(zoomOut:));
    }
    if ([itemIdentifier isEqualToString:kToolbarZoomReset]) {
        return makeItem(kToolbarZoomReset, @"Reset Zoom", @"1.magnifyingglass", @selector(zoomReset:));
    }
    return nil;
}

#pragma mark - Document Management

- (NSArray<MPDocument *> *)documents {
    return [_mutableDocuments copy];
}

- (MPDocument *)activeDocument {
    return _mutableActiveDocument;
}

- (EditorView *)activeEditorView {
    if (!_mutableActiveDocument) return nil;
    return _editorViews[_mutableActiveDocument.title];
}

- (EditorView *)editorViewForDocument:(MPDocument *)document {
    NSString *key = [NSString stringWithFormat:@"%p", (void *)document];
    return _editorViews[key];
}

- (void)setEditorView:(EditorView *)view forDocument:(MPDocument *)document {
    NSString *key = [NSString stringWithFormat:@"%p", (void *)document];
    _editorViews[key] = view;
}

- (MPDocument *)newDocument {
    MPDocument *doc = [[MPDocument alloc] initNew];
    [self addDocument:doc];
    return doc;
}

- (MPDocument *)openDocumentFromURL:(NSURL *)url {
    // Check if already open
    for (MPDocument *existing in _mutableDocuments) {
        if ([existing.fileURL isEqual:url]) {
            [self selectDocument:existing];
            return existing;
        }
    }

    MPDocument *doc = [[MPDocument alloc] initWithURL:url];
    [self addDocument:doc];

    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    [appDelegate addRecentFile:url];

    return doc;
}

- (void)addDocument:(MPDocument *)document {
    [_mutableDocuments addObject:document];

    // Create editor view for this document
    EditorView *editor = [[EditorView alloc] initWithFrame:_editorContainer.bounds];
    editor.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    editor.delegate = self;

    // Apply preferences
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    editor.fontName = [d stringForKey:MPPrefFontName] ?: @"Menlo";
    CGFloat sz = [d doubleForKey:MPPrefFontSize]; if (sz < 6) sz = 12;
    editor.fontSize = sz;
    editor.tabWidth = [d integerForKey:MPPrefTabWidth] ?: 4;
    editor.useSpacesForTabs = [d boolForKey:MPPrefUseSpacesForTabs];
    editor.wordWrapEnabled = [d boolForKey:MPPrefWordWrap];
    editor.showLineNumbers = ![d objectForKey:MPPrefShowLineNumbers] || [d boolForKey:MPPrefShowLineNumbers];
    editor.showWhitespace = [d boolForKey:MPPrefShowWhitespace];
    editor.showIndentGuides = ![d objectForKey:MPPrefShowIndentGuides] || [d boolForKey:MPPrefShowIndentGuides];
    editor.showFolding = ![d objectForKey:MPPrefShowFolding] || [d boolForKey:MPPrefShowFolding];
    editor.highlightCurrentLine = ![d objectForKey:MPPrefHighlightCurrentLine] || [d boolForKey:MPPrefHighlightCurrentLine];

    // Apply theme
    MPColorTheme theme = (MPColorTheme)[d integerForKey:MPPrefColorTheme];
    [[SyntaxHighlighter sharedHighlighter] applyTheme:theme toEditor:editor.scintillaView language:document.language];

    // Set document content
    editor.document = document;

    [self setEditorView:editor forDocument:document];
    [_tabBarView addTabForDocument:document];
    [self selectDocument:document];
}

- (BOOL)closeDocumentObj:(MPDocument *)document {
    if (document.isModified) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"Do you want to save changes to \"%@\"?", document.title];
        alert.informativeText = @"Your changes will be lost if you don't save them.";
        [alert addButtonWithTitle:@"Save"];
        [alert addButtonWithTitle:@"Don't Save"];
        [alert addButtonWithTitle:@"Cancel"];
        alert.alertStyle = NSAlertStyleWarning;

        NSModalResponse response = [alert runModal];
        if (response == NSAlertFirstButtonReturn) {
            if (![self saveDocumentObj:document]) return NO;
        } else if (response == NSAlertThirdButtonReturn) {
            return NO; // Cancel
        }
    }

    NSInteger idx = [_mutableDocuments indexOfObject:document];
    [_mutableDocuments removeObject:document];

    // Remove editor
    EditorView *editor = [self editorViewForDocument:document];
    [editor removeFromSuperview];
    NSString *key = [NSString stringWithFormat:@"%p", (void *)document];
    [_editorViews removeObjectForKey:key];

    // Remove tab
    [_tabBarView removeTabForDocument:document];

    // Select adjacent tab
    if (_mutableDocuments.count > 0) {
        NSInteger newIdx = MIN(idx, (NSInteger)_mutableDocuments.count - 1);
        [self selectDocument:_mutableDocuments[newIdx]];
    } else {
        _mutableActiveDocument = nil;
        [self newDocument];
    }
    return YES;
}

- (void)closeAllDocuments {
    NSArray *docs = [_mutableDocuments copy];
    for (MPDocument *doc in docs) {
        [self closeDocumentObj:doc];
    }
}

- (BOOL)saveDocumentObj:(MPDocument *)document {
    if (!document) return NO;
    if (!document.fileURL || document.isNew) {
        return [self saveDocumentObjAs:document];
    }
    // Sync content from editor
    EditorView *editor = [self editorViewForDocument:document];
    if (editor) document.content = editor.text;

    NSError *error = nil;
    if (![document saveToURL:document.fileURL error:&error]) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return NO;
    }
    [_tabBarView refreshTitles];
    [self updateWindowTitle];
    return YES;
}

- (BOOL)saveDocumentObjAs:(MPDocument *)document {
    if (!document) return NO;

    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.title = @"Save As";
    if (document.fileURL) {
        panel.directoryURL = [document.fileURL URLByDeletingLastPathComponent];
        panel.nameFieldStringValue = document.fileURL.lastPathComponent;
    } else {
        panel.nameFieldStringValue = document.title;
    }

    if ([panel runModal] == NSModalResponseOK) {
        EditorView *editor = [self editorViewForDocument:document];
        if (editor) document.content = editor.text;

        NSError *error = nil;
        if (![document saveToURL:panel.URL error:&error]) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return NO;
        }
        [_tabBarView refreshTitles];
        [self updateWindowTitle];
        return YES;
    }
    return NO;
}

- (void)saveAllDocuments {
    for (MPDocument *doc in _mutableDocuments) {
        if (doc.isModified) [self saveDocumentObj:doc];
    }
}

- (void)reloadDocument:(MPDocument *)document {
    if (!document.fileURL) return;
    if (document.isModified) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"Reload \"%@\" from disk?", document.title];
        alert.informativeText = @"Unsaved changes will be lost.";
        [alert addButtonWithTitle:@"Reload"];
        [alert addButtonWithTitle:@"Cancel"];
        if ([alert runModal] != NSAlertFirstButtonReturn) return;
    }
    NSError *error = nil;
    [document reloadFromDisk:&error];
    EditorView *editor = [self editorViewForDocument:document];
    if (editor) {
        editor.document = document;
    }
}

- (void)selectDocument:(MPDocument *)document {
    if (_mutableActiveDocument == document) return;

    // Hide current editor
    EditorView *current = [self editorViewForDocument:_mutableActiveDocument];
    [current removeFromSuperview];

    _mutableActiveDocument = document;

    // Show new editor
    EditorView *editor = [self editorViewForDocument:document];
    if (editor) {
        editor.frame = _editorContainer.bounds;
        [_editorContainer addSubview:editor];
        // Focus the editor
        [self.window makeFirstResponder:[editor.scintillaView content]];
    }

    [_tabBarView selectDocument:document];
    [self updateStatusBar];
    [self updateWindowTitle];

    // Update Find panel target
    [FindReplacePanel sharedPanel].targetEditor = editor;
}

- (void)updateWindowTitle {
    if (_mutableActiveDocument) {
        self.window.title = [NSString stringWithFormat:@"MacPad++ — %@", _mutableActiveDocument.displayTitle];
        if (_mutableActiveDocument.fileURL) {
            self.window.representedURL = _mutableActiveDocument.fileURL;
        }
    } else {
        self.window.title = @"MacPad++";
    }
}

- (void)updateStatusBar {
    EditorView *editor = [self editorViewForDocument:_mutableActiveDocument];
    if (!editor || !_mutableActiveDocument) return;

    NSInteger line = editor.caretLine;
    NSInteger col = editor.caretColumn;
    NSInteger selLen = (NSInteger)[editor.selectedText length];
    [_statusBarController updateFromDocument:_mutableActiveDocument
                                        line:line
                                      column:col
                                      selLen:selLen];
    _statusBarController.totalLines = [editor lineCount];
    _statusBarController.language = _mutableActiveDocument.language;
    _statusBarController.encoding = _mutableActiveDocument.encoding;
    _statusBarController.lineEnding = _mutableActiveDocument.lineEnding;
}

#pragma mark - Tab Management

- (void)tabButtonClicked:(MPTabButton *)sender {
    [self selectDocument:sender.document];
}

- (void)tabCloseButtonClicked:(MPTabButton *)sender {
    [self closeDocumentObj:sender.document];
}

- (void)selectNextTab {
    if (_mutableDocuments.count <= 1) return;
    NSInteger idx = [_mutableDocuments indexOfObject:_mutableActiveDocument];
    NSInteger next = (idx + 1) % _mutableDocuments.count;
    [self selectDocument:_mutableDocuments[next]];
}

- (void)selectPreviousTab {
    if (_mutableDocuments.count <= 1) return;
    NSInteger idx = [_mutableDocuments indexOfObject:_mutableActiveDocument];
    NSInteger prev = (idx - 1 + _mutableDocuments.count) % _mutableDocuments.count;
    [self selectDocument:_mutableDocuments[prev]];
}

- (void)moveTabToNewWindow:(MPDocument *)document {
    // TODO: Implement move to new window
}

#pragma mark - Find/Replace

- (void)showFindPanel {
    FindReplacePanel *panel = [FindReplacePanel sharedPanel];
    panel.targetEditor    = [self editorViewForDocument:_mutableActiveDocument];
    panel.findAllDelegate = self;
    [panel showFindMode];
}

- (void)showFindAndReplacePanel {
    FindReplacePanel *panel = [FindReplacePanel sharedPanel];
    panel.targetEditor    = [self editorViewForDocument:_mutableActiveDocument];
    panel.findAllDelegate = self;
    [panel showFindAndReplaceMode];
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return subview == _findResultsController.view;
}

- (CGFloat)splitView:(NSSplitView *)splitView
    constrainMinCoordinate:(CGFloat)proposedMin
          ofSubviewAt:(NSInteger)dividerIndex {
    return MAX(80.0, proposedMin);   // editor must stay at least 80 px tall
}

// Hide the 1-px divider line when find results are collapsed (fixes "black line" bug)
- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return [splitView isSubviewCollapsed:_findResultsController.view];
}

// Enlarge the invisible hit-test area around the thin divider so users can grab it easily
- (NSRect)splitView:(NSSplitView *)splitView
      effectiveRect:(NSRect)proposedEffectiveRect
        forDrawnRect:(NSRect)drawnRect
   ofDividerAtIndex:(NSInteger)dividerIndex {
    return NSInsetRect(proposedEffectiveRect, 0, -5);
}

// No max constraint — allow user to drag divider all the way down (collapse)

#pragma mark - FindResultsControllerDelegate

- (void)findResultsController:(FindResultsController *)controller
          didSelectLineNumber:(NSInteger)lineNumber {
    [[self editorViewForDocument:_mutableActiveDocument] gotoLine:lineNumber];
}

- (void)findResultsControllerDidClose:(FindResultsController *)controller {
    [self hideFindResults];
}

#pragma mark - FindReplacePanelFindAllDelegate

- (void)findPanel:(FindReplacePanel *)panel
       didFindAll:(NSArray<FindResultEntry *> *)results
          forTerm:(NSString *)term {
    if (results.count == 0) return;   // status already shown in the panel
    [self showFindResultsWithResults:results term:term];
}

#pragma mark - Find Results Panel show / hide

- (void)showFindResultsWithResults:(NSArray<FindResultEntry *> *)results
                              term:(NSString *)term {
    [_findResultsController showResults:results searchTerm:term];

    // Expand the results panel if it is currently collapsed
    if ([_editorSplitView isSubviewCollapsed:_findResultsController.view]) {
        CGFloat totalH   = _editorSplitView.bounds.size.height;
        CGFloat resultsH = MIN(200.0, totalH * 0.28);
        [_editorSplitView setPosition:totalH - resultsH ofDividerAtIndex:0];
    }
}

- (void)hideFindResults {
    [_findResultsController clearResults];
    CGFloat totalH = _editorSplitView.bounds.size.height;
    [_editorSplitView setPosition:totalH ofDividerAtIndex:0];
}

#pragma mark - EditorViewDelegate

- (void)editorViewContentChanged:(EditorView *)editorView {
    [_tabBarView refreshTitles];
    [self updateWindowTitle];
}

- (void)editorView:(EditorView *)editorView cursorMovedToLine:(NSInteger)line column:(NSInteger)column {
    _statusBarController.currentLine = line;
    _statusBarController.currentColumn = column;
    _statusBarController.totalLines = [editorView lineCount];
}

- (void)editorViewSelectionChanged:(EditorView *)editorView {
    _statusBarController.selectionLength = (NSInteger)[editorView.selectedText length];
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(NSWindow *)sender {
    NSArray *modified = [_mutableDocuments filteredArrayUsingPredicate:
                         [NSPredicate predicateWithFormat:@"isModified == YES"]];
    if (modified.count == 0) return YES;

    NSAlert *alert = [[NSAlert alloc] init];
    if (modified.count == 1) {
        alert.messageText = [NSString stringWithFormat:@"Save changes to \"%@\" before quitting?",
                             [(MPDocument *)modified[0] title]];
    } else {
        alert.messageText = [NSString stringWithFormat:@"You have %lu unsaved documents. Save all before quitting?",
                             (unsigned long)modified.count];
    }
    [alert addButtonWithTitle:@"Save All"];
    [alert addButtonWithTitle:@"Discard All"];
    [alert addButtonWithTitle:@"Cancel"];

    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [self saveAllDocuments];
        return YES;
    } else if (response == NSAlertSecondButtonReturn) {
        return YES;
    }
    return NO;
}

#pragma mark - Menu Actions

- (IBAction)newDocument:(id)sender {
    [self newDocument];
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = YES;
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;

    if ([panel runModal] == NSModalResponseOK) {
        for (NSURL *url in panel.URLs) {
            [self openDocumentFromURL:url];
        }
    }
}

- (IBAction)saveDocument:(id)sender {
    [self saveDocumentObj:_mutableActiveDocument];
}

- (IBAction)saveDocumentAs:(id)sender {
    [self saveDocumentObjAs:_mutableActiveDocument];
}

- (IBAction)saveAllDocuments:(id)sender {
    [self saveAllDocuments];
}

- (IBAction)closeDocument:(id)sender {
    [self closeDocumentObj:_mutableActiveDocument];
}

- (IBAction)reloadFromDisk:(id)sender {
    [self reloadDocument:_mutableActiveDocument];
}

- (IBAction)showFindPanel:(id)sender {
    [self showFindPanel];
}

- (IBAction)showFindAndReplacePanel:(id)sender {
    [self showFindAndReplacePanel];
}

- (IBAction)gotoLine:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Go to Line";
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
    field.placeholderString = @"Line number";
    alert.accessoryView = field;
    [alert addButtonWithTitle:@"Go"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert.window makeFirstResponder:field];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSInteger lineNum = field.integerValue;
        [[self editorViewForDocument:_mutableActiveDocument] gotoLine:lineNum];
    }
}

- (IBAction)selectNextTab:(id)sender { [self selectNextTab]; }
- (IBAction)selectPreviousTab:(id)sender { [self selectPreviousTab]; }

- (IBAction)toggleWordWrap:(id)sender {
    EditorView *e = [self editorViewForDocument:_mutableActiveDocument];
    e.wordWrapEnabled = !e.wordWrapEnabled;
}

- (IBAction)toggleLineNumbers:(id)sender {
    EditorView *e = [self editorViewForDocument:_mutableActiveDocument];
    e.showLineNumbers = !e.showLineNumbers;
}

- (IBAction)toggleWhitespace:(id)sender {
    EditorView *e = [self editorViewForDocument:_mutableActiveDocument];
    e.showWhitespace = !e.showWhitespace;
}

- (IBAction)toggleIndentGuides:(id)sender {
    EditorView *e = [self editorViewForDocument:_mutableActiveDocument];
    e.showIndentGuides = !e.showIndentGuides;
}

- (IBAction)zoomIn:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] zoomIn];
}

- (IBAction)zoomOut:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] zoomOut];
}

- (IBAction)zoomReset:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] zoomReset];
}

- (IBAction)foldAll:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] foldAll];
}

- (IBAction)unfoldAll:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] unfoldAll];
}

- (IBAction)moveLinesUp:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] moveLinesUp];
}

- (IBAction)moveLinesDown:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] moveLinesDown];
}

- (IBAction)duplicateLine:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] duplicateCurrentLine];
}

- (IBAction)deleteLine:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] deleteCurrentLine];
}

- (IBAction)toUpperCase:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] toUpperCase];
}

- (IBAction)toLowerCase:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] toLowerCase];
}

- (IBAction)toggleLineComment:(id)sender {
    [[self editorViewForDocument:_mutableActiveDocument] toggleLineComment];
}

- (IBAction)setLanguage:(id)sender {
    NSString *lang = [(NSMenuItem *)sender representedObject];
    if (!lang || !_mutableActiveDocument) return;
    _mutableActiveDocument.language = lang;
    EditorView *e = [self editorViewForDocument:_mutableActiveDocument];
    [e setLanguage:lang];
    [self updateStatusBar];
}

- (IBAction)setLineEndingLF:(id)sender {
    if (_mutableActiveDocument) {
        _mutableActiveDocument.lineEnding = MPLineEndingLF;
        _mutableActiveDocument.isModified = YES;
        [self updateStatusBar];
    }
}

- (IBAction)setLineEndingCRLF:(id)sender {
    if (_mutableActiveDocument) {
        _mutableActiveDocument.lineEnding = MPLineEndingCRLF;
        _mutableActiveDocument.isModified = YES;
        [self updateStatusBar];
    }
}

- (IBAction)setLineEndingCR:(id)sender {
    if (_mutableActiveDocument) {
        _mutableActiveDocument.lineEnding = MPLineEndingCR;
        _mutableActiveDocument.isModified = YES;
        [self updateStatusBar];
    }
}

- (IBAction)convertToUTF8:(id)sender {
    if (_mutableActiveDocument) {
        _mutableActiveDocument.encoding = MPEncodingUTF8;
        _mutableActiveDocument.isModified = YES;
        [self updateStatusBar];
    }
}

- (IBAction)convertToUTF8BOM:(id)sender {
    if (_mutableActiveDocument) {
        _mutableActiveDocument.encoding = MPEncodingUTF8BOM;
        _mutableActiveDocument.isModified = YES;
        [self updateStatusBar];
    }
}

#pragma mark - Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = menuItem.action;

    if (action == @selector(saveDocument:)) {
        return _mutableActiveDocument != nil && _mutableActiveDocument.isModified;
    }
    if (action == @selector(saveDocumentAs:) ||
        action == @selector(closeDocument:) ||
        action == @selector(gotoLine:) ||
        action == @selector(showFindPanel:) ||
        action == @selector(showFindAndReplacePanel:)) {
        return _mutableActiveDocument != nil;
    }
    if (action == @selector(reloadFromDisk:)) {
        return _mutableActiveDocument != nil && _mutableActiveDocument.fileURL != nil;
    }
    if (action == @selector(toggleWordWrap:)) {
        menuItem.state = [self editorViewForDocument:_mutableActiveDocument].wordWrapEnabled ?
            NSControlStateValueOn : NSControlStateValueOff;
    }
    if (action == @selector(toggleLineNumbers:)) {
        menuItem.state = [self editorViewForDocument:_mutableActiveDocument].showLineNumbers ?
            NSControlStateValueOn : NSControlStateValueOff;
    }
    if (action == @selector(toggleWhitespace:)) {
        menuItem.state = [self editorViewForDocument:_mutableActiveDocument].showWhitespace ?
            NSControlStateValueOn : NSControlStateValueOff;
    }
    if (action == @selector(toggleIndentGuides:)) {
        menuItem.state = [self editorViewForDocument:_mutableActiveDocument].showIndentGuides ?
            NSControlStateValueOn : NSControlStateValueOff;
    }
    return YES;
}

@end
