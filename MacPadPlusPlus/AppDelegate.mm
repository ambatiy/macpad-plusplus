#import "AppDelegate.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "FindReplacePanel.h"
#import "SyntaxHighlighter.h"
#import "MPDocument.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSMutableArray<NSURL *> *recentFiles;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Register user defaults
    [[PreferencesWindowController sharedController] class]; // triggers registerDefaults

    // Load recent files
    NSArray *stored = [[NSUserDefaults standardUserDefaults] arrayForKey:MPPrefRecentFiles] ?: @[];
    _recentFiles = [NSMutableArray arrayWithCapacity:stored.count];
    for (NSString *path in stored) {
        [_recentFiles addObject:[NSURL fileURLWithPath:path]];
    }

    // Build menu
    [self setupMenuBar];

    // Create main window
    _mainWindowController = [[MainWindowController alloc] init];
    [_mainWindowController showWindow:nil];

    // Collect any command-line file arguments
    NSArray<NSString *> *args = [[NSProcessInfo processInfo] arguments];
    NSMutableArray *cmdFiles = [NSMutableArray new];
    for (NSUInteger i = 1; i < args.count; i++) {
        NSString *arg = args[i];
        if ([arg hasPrefix:@"-"]) continue;
        if ([[NSFileManager defaultManager] fileExistsAtPath:arg]) {
            [cmdFiles addObject:arg];
        }
    }

    if (cmdFiles.count > 0) {
        // Command-line files take priority; don't restore session
        for (NSString *path in cmdFiles) {
            [_mainWindowController openDocumentFromURL:[NSURL fileURLWithPath:path]];
        }
    } else {
        // Try to restore the previous session
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        NSArray *sessionPaths = [d arrayForKey:@"sessionFiles"];
        [d removeObjectForKey:@"sessionFiles"]; // clear immediately so a crash doesn't loop

        BOOL restored = NO;
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *path in sessionPaths) {
            if ([fm fileExistsAtPath:path]) {
                [_mainWindowController openDocumentFromURL:[NSURL fileURLWithPath:path]];
                restored = YES;
            }
        }

        if (!restored) {
            [_mainWindowController newDocument];
        }
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSURL *url = [NSURL fileURLWithPath:filename];
    MPDocument *doc = [_mainWindowController openDocumentFromURL:url];
    return doc != nil;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames {
    for (NSString *f in filenames) {
        [_mainWindowController openDocumentFromURL:[NSURL fileURLWithPath:f]];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Let the window controller handle unsaved changes
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // Save paths of all open file-backed documents so the next launch can restore them
    NSMutableArray *paths = [NSMutableArray new];
    for (MPDocument *doc in _mainWindowController.documents) {
        if (doc.fileURL && !doc.isNew) {
            [paths addObject:doc.fileURL.path];
        }
    }
    if (paths.count > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:paths forKey:@"sessionFiles"];
    }
}

- (IBAction)newDocument:(id)sender {
    [_mainWindowController newDocument];
}

- (IBAction)openDocument:(id)sender {
    [_mainWindowController openDocument:sender];
}

- (IBAction)showPreferences:(id)sender {
    [[PreferencesWindowController sharedController] showPreferences];
}

- (void)addRecentFile:(NSURL *)url {
    [_recentFiles removeObject:url];
    [_recentFiles insertObject:url atIndex:0];
    if (_recentFiles.count > 15) {
        [_recentFiles removeLastObject];
    }
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:_recentFiles.count];
    for (NSURL *u in _recentFiles) [paths addObject:u.path];
    [[NSUserDefaults standardUserDefaults] setObject:paths forKey:MPPrefRecentFiles];
    [self updateRecentFilesMenu];
}

- (void)updateRecentFilesMenu {
    NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:100] submenu];
    NSMenuItem *recentItem = [fileMenu itemWithTag:110];
    if (!recentItem) return;

    NSMenu *recentMenu = recentItem.submenu;
    [recentMenu removeAllItems];

    for (NSURL *url in _recentFiles) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:url.lastPathComponent
                                                      action:@selector(openRecentFile:)
                                               keyEquivalent:@""];
        item.representedObject = url;
        item.target = self;
        [recentMenu addItem:item];
    }
    if (_recentFiles.count == 0) {
        [recentMenu addItem:[NSMenuItem new]];
        [[recentMenu itemArray].lastObject setTitle:@"(No recent files)"];
        [[recentMenu itemArray].lastObject setEnabled:NO];
    }
    [recentMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *clearItem = [[NSMenuItem alloc] initWithTitle:@"Clear Recent Files"
                                                       action:@selector(clearRecentFiles:)
                                                keyEquivalent:@""];
    clearItem.target = self;
    [recentMenu addItem:clearItem];
    (void)recentMenu.itemArray; // Silence unused property warning
}

- (IBAction)openRecentFile:(id)sender {
    NSURL *url = [(NSMenuItem *)sender representedObject];
    if (url) [_mainWindowController openDocumentFromURL:url];
}

- (IBAction)clearRecentFiles:(id)sender {
    [_recentFiles removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MPPrefRecentFiles];
    [self updateRecentFilesMenu];
}

#pragma mark - Menu Setup

- (void)setupMenuBar {
    NSMenu *mainMenu = [[NSMenu alloc] init];

    // -- App Menu --
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenu addItemWithTitle:@"About MacPad++"
                       action:@selector(orderFrontStandardAboutPanel:)
                keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *prefsItem = [appMenu addItemWithTitle:@"Preferences…"
                                               action:@selector(showPreferences:)
                                        keyEquivalent:@","];
    prefsItem.target = self;
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Services" action:nil keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide MacPad++" action:@selector(hide:) keyEquivalent:@"h"];
    NSMenuItem *hideOthers = [appMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    hideOthers.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
    [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit MacPad++" action:@selector(terminate:) keyEquivalent:@"q"];
    appMenuItem.submenu = appMenu;
    [mainMenu addItem:appMenuItem];

    // -- File Menu --
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    fileMenuItem.tag = 100;
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    NSMenuItem *newItem = [fileMenu addItemWithTitle:@"New" action:@selector(newDocument:) keyEquivalent:@"n"];
    newItem.target = _mainWindowController;
    NSMenuItem *openItem = [fileMenu addItemWithTitle:@"Open…" action:@selector(openDocument:) keyEquivalent:@"o"];
    openItem.target = _mainWindowController;

    // Recent files submenu
    NSMenuItem *recentItem = [[NSMenuItem alloc] initWithTitle:@"Open Recent" action:nil keyEquivalent:@""];
    recentItem.tag = 110;
    recentItem.submenu = [[NSMenu alloc] initWithTitle:@"Open Recent"];
    [fileMenu addItem:recentItem];

    [fileMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *saveItem = [fileMenu addItemWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@"s"];
    saveItem.target = _mainWindowController;
    NSMenuItem *saveAsItem = [fileMenu addItemWithTitle:@"Save As…" action:@selector(saveDocumentAs:) keyEquivalent:@"S"];
    saveAsItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    saveAsItem.target = _mainWindowController;
    NSMenuItem *saveAllItem = [fileMenu addItemWithTitle:@"Save All" action:@selector(saveAllDocuments:) keyEquivalent:@""];
    saveAllItem.target = _mainWindowController;
    [fileMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *reloadItem = [fileMenu addItemWithTitle:@"Reload from Disk" action:@selector(reloadFromDisk:) keyEquivalent:@""];
    reloadItem.target = _mainWindowController;
    [fileMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *closeItem = [fileMenu addItemWithTitle:@"Close" action:@selector(closeDocument:) keyEquivalent:@"w"];
    closeItem.target = _mainWindowController;
    [fileMenu addItem:[NSMenuItem separatorItem]];

    [fileMenu addItemWithTitle:@"Print…" action:@selector(print:) keyEquivalent:@"p"];

    fileMenuItem.submenu = fileMenu;
    [mainMenu addItem:fileMenuItem];

    // -- Edit Menu --
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [editMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *goToLineItem = [editMenu addItemWithTitle:@"Go to Line…" action:@selector(gotoLine:) keyEquivalent:@"l"];
    goToLineItem.target = _mainWindowController;
    goToLineItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;

    editMenuItem.submenu = editMenu;
    [mainMenu addItem:editMenuItem];

    // -- Search Menu --
    NSMenuItem *searchMenuItem = [[NSMenuItem alloc] init];
    NSMenu *searchMenu = [[NSMenu alloc] initWithTitle:@"Search"];

    NSMenuItem *findItem = [searchMenu addItemWithTitle:@"Find…" action:@selector(showFindPanel:) keyEquivalent:@"f"];
    findItem.target = _mainWindowController;
    NSMenuItem *replaceItem = [searchMenu addItemWithTitle:@"Find & Replace…" action:@selector(showFindAndReplacePanel:) keyEquivalent:@"h"];
    replaceItem.target = _mainWindowController;
    [searchMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *findAllItem = [searchMenu addItemWithTitle:@"Find All in Document"
                                                   action:@selector(findAll)
                                            keyEquivalent:@"f"];
    findAllItem.target = [FindReplacePanel sharedPanel];
    findAllItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    [searchMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *findNextItem = [searchMenu addItemWithTitle:@"Find Next" action:@selector(findNext) keyEquivalent:@"g"];
    findNextItem.target = [FindReplacePanel sharedPanel];
    NSMenuItem *findPrevItem = [searchMenu addItemWithTitle:@"Find Previous" action:@selector(findPrevious) keyEquivalent:@"G"];
    findPrevItem.target = [FindReplacePanel sharedPanel];
    findPrevItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;

    searchMenuItem.submenu = searchMenu;
    [mainMenu addItem:searchMenuItem];

    // -- View Menu --
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];

    NSMenuItem *wrapItem = [viewMenu addItemWithTitle:@"Word Wrap" action:@selector(toggleWordWrap:) keyEquivalent:@""];
    wrapItem.target = _mainWindowController;
    NSMenuItem *lineNumItem = [viewMenu addItemWithTitle:@"Show Line Numbers" action:@selector(toggleLineNumbers:) keyEquivalent:@""];
    lineNumItem.target = _mainWindowController;
    NSMenuItem *wsItem = [viewMenu addItemWithTitle:@"Show Whitespace" action:@selector(toggleWhitespace:) keyEquivalent:@""];
    wsItem.target = _mainWindowController;
    NSMenuItem *igItem = [viewMenu addItemWithTitle:@"Show Indent Guides" action:@selector(toggleIndentGuides:) keyEquivalent:@""];
    igItem.target = _mainWindowController;
    [viewMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *ziItem = [viewMenu addItemWithTitle:@"Zoom In" action:@selector(zoomIn:) keyEquivalent:@"+"];
    ziItem.target = _mainWindowController;
    NSMenuItem *zoItem = [viewMenu addItemWithTitle:@"Zoom Out" action:@selector(zoomOut:) keyEquivalent:@"-"];
    zoItem.target = _mainWindowController;
    NSMenuItem *zrItem = [viewMenu addItemWithTitle:@"Reset Zoom" action:@selector(zoomReset:) keyEquivalent:@"0"];
    zrItem.target = _mainWindowController;
    [viewMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *foldAllItem = [viewMenu addItemWithTitle:@"Fold All" action:@selector(foldAll:) keyEquivalent:@""];
    foldAllItem.target = _mainWindowController;
    NSMenuItem *unfoldAllItem = [viewMenu addItemWithTitle:@"Unfold All" action:@selector(unfoldAll:) keyEquivalent:@""];
    unfoldAllItem.target = _mainWindowController;

    viewMenuItem.submenu = viewMenu;
    [mainMenu addItem:viewMenuItem];

    // -- Format Menu --
    NSMenuItem *formatMenuItem = [[NSMenuItem alloc] init];
    NSMenu *formatMenu = [[NSMenu alloc] initWithTitle:@"Format"];

    NSMenuItem *moveUpItem = [formatMenu addItemWithTitle:@"Move Lines Up" action:@selector(moveLinesUp:) keyEquivalent:@""];
    moveUpItem.target = _mainWindowController;
    NSMenuItem *moveDownItem = [formatMenu addItemWithTitle:@"Move Lines Down" action:@selector(moveLinesDown:) keyEquivalent:@""];
    moveDownItem.target = _mainWindowController;
    NSMenuItem *dupLineItem = [formatMenu addItemWithTitle:@"Duplicate Line" action:@selector(duplicateLine:) keyEquivalent:@"d"];
    dupLineItem.target = _mainWindowController;
    dupLineItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    NSMenuItem *delLineItem = [formatMenu addItemWithTitle:@"Delete Line" action:@selector(deleteLine:) keyEquivalent:@"k"];
    delLineItem.target = _mainWindowController;
    delLineItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    [formatMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *upperItem = [formatMenu addItemWithTitle:@"UPPERCASE" action:@selector(toUpperCase:) keyEquivalent:@"u"];
    upperItem.target = _mainWindowController;
    upperItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    NSMenuItem *lowerItem = [formatMenu addItemWithTitle:@"lowercase" action:@selector(toLowerCase:) keyEquivalent:@"l"];
    lowerItem.target = _mainWindowController;
    lowerItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    [formatMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *commentItem = [formatMenu addItemWithTitle:@"Toggle Line Comment" action:@selector(toggleLineComment:) keyEquivalent:@"/"];
    commentItem.target = _mainWindowController;

    formatMenuItem.submenu = formatMenu;
    [mainMenu addItem:formatMenuItem];

    // -- Language Menu --
    NSMenuItem *langMenuItem = [[NSMenuItem alloc] init];
    NSMenu *langMenu = [[NSMenu alloc] initWithTitle:@"Language"];
    SyntaxHighlighter *hl = [SyntaxHighlighter sharedHighlighter];
    for (NSString *lang in [hl allLanguageNames]) {
        NSMenuItem *li = [[NSMenuItem alloc] initWithTitle:[hl displayNameForLanguage:lang]
                                                    action:@selector(setLanguage:)
                                             keyEquivalent:@""];
        li.representedObject = lang;
        li.target = _mainWindowController;
        [langMenu addItem:li];
    }
    langMenuItem.submenu = langMenu;
    [mainMenu addItem:langMenuItem];

    // -- Encoding Menu --
    NSMenuItem *encMenuItem = [[NSMenuItem alloc] init];
    NSMenu *encMenu = [[NSMenu alloc] initWithTitle:@"Encoding"];
    NSMenuItem *utf8Item = [encMenu addItemWithTitle:@"Convert to UTF-8" action:@selector(convertToUTF8:) keyEquivalent:@""];
    utf8Item.target = _mainWindowController;
    NSMenuItem *utf8bomItem = [encMenu addItemWithTitle:@"Convert to UTF-8 BOM" action:@selector(convertToUTF8BOM:) keyEquivalent:@""];
    utf8bomItem.target = _mainWindowController;
    [encMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *lfItem = [encMenu addItemWithTitle:@"Set Line Endings: Unix (LF)" action:@selector(setLineEndingLF:) keyEquivalent:@""];
    lfItem.target = _mainWindowController;
    NSMenuItem *crlfItem = [encMenu addItemWithTitle:@"Set Line Endings: Windows (CRLF)" action:@selector(setLineEndingCRLF:) keyEquivalent:@""];
    crlfItem.target = _mainWindowController;
    encMenuItem.submenu = encMenu;
    [mainMenu addItem:encMenuItem];

    // -- Window Menu --
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *nextTabItem = [windowMenu addItemWithTitle:@"Next Tab" action:@selector(selectNextTab:) keyEquivalent:@"]"];
    nextTabItem.target = _mainWindowController;
    NSMenuItem *prevTabItem = [windowMenu addItemWithTitle:@"Previous Tab" action:@selector(selectPreviousTab:) keyEquivalent:@"["];
    prevTabItem.target = _mainWindowController;
    windowMenuItem.submenu = windowMenu;
    [NSApp setWindowsMenu:windowMenu];
    [mainMenu addItem:windowMenuItem];

    // -- Help Menu --
    NSMenuItem *helpMenuItem = [[NSMenuItem alloc] init];
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenu addItemWithTitle:@"MacPad++ Help" action:nil keyEquivalent:@"?"];
    helpMenuItem.submenu = helpMenu;
    [NSApp setHelpMenu:helpMenu];
    [mainMenu addItem:helpMenuItem];

    [NSApp setMainMenu:mainMenu];
    [self updateRecentFilesMenu];
}

@end
