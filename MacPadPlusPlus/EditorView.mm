#import "EditorView.h"
#import "SyntaxHighlighter.h"
#import "PreferencesWindowController.h"
#import "Scintilla.h"
#import "SciLexer.h"

@interface EditorView ()
@property (nonatomic, assign) NSInteger zoomLevel;
@end

@implementation EditorView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // Create ScintillaView filling this view
    _scintillaView = [[ScintillaView alloc] initWithFrame:self.bounds];
    [_scintillaView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_scintillaView setDelegate:self];
    [self addSubview:_scintillaView];

    _fontName = @"Menlo";
    _fontSize = 12.0;
    _tabWidth = 4;
    _useSpacesForTabs = NO;
    _showLineNumbers = YES;
    _wordWrapEnabled = NO;
    _showWhitespace = NO;
    _showEOL = NO;
    _showIndentGuides = YES;
    _showFolding = YES;
    _highlightCurrentLine = YES;
    _zoomLevel = 0;

    [self setupEditor];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupEditor {
    ScintillaView *v = _scintillaView;

    // --- Font ---
    [v setFontName:_fontName size:(int)_fontSize bold:NO italic:NO];

    // --- Line numbers margin ---
    [v setGeneralProperty:SCI_SETMARGINTYPEN parameter:0 value:SC_MARGIN_NUMBER];
    [v setGeneralProperty:SCI_SETMARGINWIDTHN parameter:0 value:(_showLineNumbers ? 50 : 0)];

    // --- Fold margin ---
    [v setGeneralProperty:SCI_SETMARGINTYPEN parameter:2 value:SC_MARGIN_SYMBOL];
    [v setGeneralProperty:SCI_SETMARGINMASKN parameter:2 value:SC_MASK_FOLDERS];
    [v setGeneralProperty:SCI_SETMARGINWIDTHN parameter:2 value:(_showFolding ? 16 : 0)];
    [v setGeneralProperty:SCI_SETMARGINSENSITIVEN parameter:2 value:1];

    // --- Fold markers ---
    [v setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDER value:SC_MARK_ARROWDOWN];
    [v setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEROPEN value:SC_MARK_ARROWDOWN];
    [v setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEREND value:SC_MARK_ARROW];
    [v setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEROPENMID value:SC_MARK_ARROWDOWN];
    [v setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERMIDTAIL value:SC_MARK_EMPTY];
    [v setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERSUB value:SC_MARK_EMPTY];
    [v setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERTAIL value:SC_MARK_EMPTY];
    [v setGeneralProperty:SCI_SETAUTOMATICFOLD value:SC_AUTOMATICFOLD_SHOW | SC_AUTOMATICFOLD_CLICK | SC_AUTOMATICFOLD_CHANGE];

    // --- Tabs & Indent ---
    [v setGeneralProperty:SCI_SETTABWIDTH value:_tabWidth];
    [v setGeneralProperty:SCI_SETUSETABS value:(_useSpacesForTabs ? 0 : 1)];
    [v setGeneralProperty:SCI_SETINDENT value:_tabWidth];
    [v setGeneralProperty:SCI_SETINDENTATIONGUIDES value:(_showIndentGuides ? SC_IV_LOOKBOTH : SC_IV_NONE)];
    [v setGeneralProperty:SCI_SETBACKSPACEUNINDENTS value:1];
    [v setGeneralProperty:SCI_SETTABINDENTS value:1];

    // --- Word wrap ---
    [v setGeneralProperty:SCI_SETWRAPMODE value:(_wordWrapEnabled ? SC_WRAP_WORD : SC_WRAP_NONE)];
    [v setGeneralProperty:SCI_SETWRAPVISUALFLAGS value:SC_WRAPVISUALFLAG_END];
    [v setGeneralProperty:SCI_SETWRAPINDENTMODE value:SC_WRAPINDENT_INDENT];

    // --- Caret ---
    [v setGeneralProperty:SCI_SETCARETLINEVISIBLE value:(_highlightCurrentLine ? 1 : 0)];
    [v setGeneralProperty:SCI_SETCARETLINEVISIBLEALWAYS value:1];
    [v setGeneralProperty:SCI_SETCARETWIDTH value:2];

    // --- Whitespace & EOL ---
    [v setGeneralProperty:SCI_SETVIEWWS value:(_showWhitespace ? SCWS_VISIBLEALWAYS : SCWS_INVISIBLE)];
    [v setGeneralProperty:SCI_SETVIEWEOL value:(_showEOL ? 1 : 0)];

    // --- Edge line at column 80 ---
    [v setGeneralProperty:SCI_SETEDGEMODE value:EDGE_LINE];
    [v setGeneralProperty:SCI_SETEDGECOLUMN value:80];

    // --- Scrolling ---
    [v setGeneralProperty:SCI_SETSCROLLWIDTHTRACKING value:1];
    [v setGeneralProperty:SCI_SETSCROLLWIDTH value:1];

    // --- Brace matching ---
    [v setGeneralProperty:SCI_SETMOUSEDOWNCAPTURES value:1];

    // --- Multi-selection ---
    [v setGeneralProperty:SCI_SETMULTIPLESELECTION value:1];
    [v setGeneralProperty:SCI_SETADDITIONALSELECTIONTYPING value:1];
    [v setGeneralProperty:SCI_SETMULTIPASTE value:1];

    // --- EOL mode ---
    [v setGeneralProperty:SCI_SETEOLMODE value:SC_EOL_LF];

    // --- Auto-complete ---
    [v setGeneralProperty:SCI_AUTOCSETIGNORECASE value:1];
    [v setGeneralProperty:SCI_AUTOCSETDROPRESTOFWORD value:1];

    // --- Buffered draw ---
    [v setGeneralProperty:SCI_SETBUFFEREDDRAW value:1];

    // Apply default theme
    [[SyntaxHighlighter sharedHighlighter] applyTheme:MPColorThemeDefault toEditor:v language:@"none"];
}

- (void)preferencesChanged:(NSNotification *)notification {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSString *newFont = [d stringForKey:MPPrefFontName] ?: @"Menlo";
    CGFloat newSize = [d doubleForKey:MPPrefFontSize];
    if (newSize < 6) newSize = 12;

    if (![newFont isEqualToString:_fontName] || newSize != _fontSize) {
        _fontName = newFont;
        _fontSize = newSize;
        [_scintillaView setFontName:_fontName size:(int)_fontSize bold:NO italic:NO];
    }
}

#pragma mark - Properties

- (void)setText:(NSString *)text {
    [_scintillaView setString:text ?: @""];
}

- (NSString *)text {
    return [_scintillaView string] ?: @"";
}

- (NSString *)selectedText {
    return [_scintillaView selectedString] ?: @"";
}

- (NSRange)selectedRange {
    return [_scintillaView selectedRange];
}

- (NSInteger)caretLine {
    NSInteger pos = [_scintillaView message:SCI_GETCURRENTPOS wParam:0 lParam:0];
    return [_scintillaView message:SCI_LINEFROMPOSITION wParam:pos lParam:0] + 1;
}

- (NSInteger)caretColumn {
    NSInteger pos = [_scintillaView message:SCI_GETCURRENTPOS wParam:0 lParam:0];
    NSInteger lineStart = [_scintillaView message:SCI_POSITIONFROMLINE
                                           wParam:[_scintillaView message:SCI_LINEFROMPOSITION wParam:pos lParam:0]
                                           lParam:0];
    return [_scintillaView message:SCI_GETCOLUMN wParam:pos lParam:0] + 1;
    (void)lineStart;
}

- (NSInteger)lineCount {
    return [_scintillaView message:SCI_GETLINECOUNT wParam:0 lParam:0];
}

- (NSInteger)caretPosition {
    return [_scintillaView message:SCI_GETCURRENTPOS wParam:0 lParam:0];
}

- (void)setDocument:(MPDocument *)document {
    _document = document;
    if (document) {
        [_scintillaView setString:document.content ?: @""];
        [self setLanguage:document.language];
        NSInteger lineEnding = SC_EOL_LF;
        if (document.lineEnding == MPLineEndingCRLF) lineEnding = SC_EOL_CRLF;
        else if (document.lineEnding == MPLineEndingCR) lineEnding = SC_EOL_CR;
        [_scintillaView setGeneralProperty:SCI_SETEOLMODE value:lineEnding];
        // Clear undo history for loaded files
        [_scintillaView message:SCI_EMPTYUNDOBUFFER wParam:0 lParam:0];
    }
}

#pragma mark - Language

- (void)setLanguage:(NSString *)language {
    if (!language) language = @"none";
    [[SyntaxHighlighter sharedHighlighter] applyLanguage:language toEditor:_scintillaView];

    // Set keywords for specific languages
    [self applyKeywordsForLanguage:language];
}

- (void)applyKeywordsForLanguage:(NSString *)language {
    if ([language isEqualToString:@"cpp"]) {
        const char *kw1 = "alignas alignof and and_eq asm auto bitand bitor bool break case catch char char8_t "
            "char16_t char32_t class compl concept const consteval constexpr constinit const_cast continue "
            "co_await co_return co_yield decltype default delete do double dynamic_cast else enum explicit "
            "export extern false float for friend goto if inline int long mutable namespace new noexcept not "
            "not_eq nullptr operator or or_eq private protected public register reinterpret_cast requires "
            "return short signed sizeof static static_assert static_cast struct switch template this thread_local "
            "throw true try typedef typeid typename union unsigned using virtual void volatile wchar_t while xor xor_eq";
        [_scintillaView setGeneralProperty:SCI_SETKEYWORDS parameter:0 value:(long)kw1];

        const char *kw2 = "std string vector map unordered_map set unordered_set list deque queue stack pair "
            "tuple optional variant any shared_ptr unique_ptr weak_ptr make_shared make_unique "
            "size_t ptrdiff_t nullptr_t int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t "
            "FILE NULL true false";
        [_scintillaView setGeneralProperty:SCI_SETKEYWORDS parameter:1 value:(long)kw2];

    } else if ([language isEqualToString:@"python"]) {
        const char *kw1 = "False None True and as assert async await break class continue def del elif else "
            "except finally for from global if import in is lambda nonlocal not or pass raise return "
            "try while with yield";
        [_scintillaView setGeneralProperty:SCI_SETKEYWORDS parameter:0 value:(long)kw1];

        const char *kw2 = "abs all any ascii bin bool breakpoint bytearray bytes callable chr classmethod "
            "compile complex copyright credits delattr dict dir divmod enumerate eval exec exit filter "
            "float format frozenset getattr globals hasattr hash help hex id input int isinstance issubclass "
            "iter len license list locals map max memoryview min next object oct open ord pow print property "
            "quit range repr reversed round set setattr slice sorted staticmethod str sum super tuple type "
            "vars zip __name__ __doc__ __package__ __spec__ __loader__ __builtins__";
        [_scintillaView setGeneralProperty:SCI_SETKEYWORDS parameter:1 value:(long)kw2];

    } else if ([language isEqualToString:@"javascript"]) {
        const char *kw1 = "abstract arguments as async await boolean break byte case catch char class const "
            "continue debugger default delete do double else enum export extends false final finally float "
            "for from function get goto if implements import in instanceof int interface let long native new "
            "null of package private protected public return set short static super switch synchronized this "
            "throw throws transient true try typeof undefined var void volatile while with yield";
        [_scintillaView setGeneralProperty:SCI_SETKEYWORDS parameter:0 value:(long)kw1];

    } else if ([language isEqualToString:@"sql"]) {
        const char *kw1 = "ADD ALL ALTER AND ANY AS ASC AUTHORIZATION BACKUP BEGIN BETWEEN BREAK BROWSE BULK BY "
            "CASCADE CASE CHECK CHECKPOINT CLOSE CLUSTERED COALESCE COLLATE COLUMN COMMIT COMPUTE CONSTRAINT "
            "CONTAINS CONTAINSTABLE CONTINUE CONVERT CREATE CROSS CURRENT CURRENT_DATE CURRENT_TIME "
            "CURRENT_TIMESTAMP CURRENT_USER CURSOR DATABASE DBCC DEALLOCATE DECLARE DEFAULT DELETE DENY DESC "
            "DISTINCT DISTRIBUTED DOUBLE DROP DUMP ELSE END ERRLVL ESCAPE EXCEPT EXEC EXECUTE EXISTS EXIT "
            "EXTERNAL FETCH FILE FILLFACTOR FOR FOREIGN FREETEXT FREETEXTTABLE FROM FULL FUNCTION GOTO GRANT "
            "GROUP HAVING HOLDLOCK IDENTITY IDENTITYCOL IDENTITY_INSERT IF IN INDEX INNER INSERT INTERSECT INTO "
            "IS JOIN KEY KILL LEFT LIKE LINENO LOAD MERGE NATIONAL NOCHECK NONCLUSTERED NOT NULL NULLIF OF OFF "
            "OFFSETS ON OPEN OPENDATASOURCE OPENQUERY OPENROWSET OPENXML OPTION OR ORDER OUTER OVER PERCENT PIVOT "
            "PLAN PRECISION PRIMARY PRINT PROC PROCEDURE PUBLIC RAISERROR READ READTEXT RECONFIGURE REFERENCES "
            "REPLICATION RESTORE RESTRICT RETURN REVERT REVOKE RIGHT ROLLBACK ROWCOUNT ROWGUIDCOL RULE SAVE SCHEMA "
            "SECURITYAUDIT SELECT SEMANTICKEYPHRASETABLE SEMANTICSIMILARITYDETAILSTABLE SEMANTICSIMILARITYTABLE "
            "SESSION_USER SET SETUSER SHUTDOWN SOME STATISTICS SYSTEM_USER TABLE TABLESAMPLE TEXTSIZE THEN TO TOP "
            "TRAN TRANSACTION TRIGGER TRUNCATE TRY_CONVERT TSEQUAL UNION UNIQUE UNPIVOT UPDATE UPDATETEXT USE USER "
            "VALUES VARYING VIEW WAITFOR WHEN WHERE WHILE WITH WITHIN WRITETEXT";
        [_scintillaView setGeneralProperty:SCI_SETKEYWORDS parameter:0 value:(long)kw1];

    } else if ([language isEqualToString:@"bash"]) {
        const char *kw = "alias bg bind break builtin caller case cd command compgen complete compopt continue "
            "declare dirs disown echo enable eval exec exit export false fc fg getopts hash help history "
            "if in jobs kill let local logout mapfile popd printf pushd pwd read readarray readonly return "
            "set shift shopt source suspend test time times trap true type typeset ulimit umask unalias "
            "unset until wait while do done fi then elif else esac for function select";
        [_scintillaView setGeneralProperty:SCI_SETKEYWORDS parameter:0 value:(long)kw];
    }
}

#pragma mark - View Settings

- (void)setWordWrapEnabled:(BOOL)wordWrapEnabled {
    _wordWrapEnabled = wordWrapEnabled;
    [_scintillaView setGeneralProperty:SCI_SETWRAPMODE value:(wordWrapEnabled ? SC_WRAP_WORD : SC_WRAP_NONE)];
}

- (void)setShowLineNumbers:(BOOL)showLineNumbers {
    _showLineNumbers = showLineNumbers;
    [_scintillaView setGeneralProperty:SCI_SETMARGINWIDTHN parameter:0 value:(showLineNumbers ? 50 : 0)];
}

- (void)setShowWhitespace:(BOOL)showWhitespace {
    _showWhitespace = showWhitespace;
    [_scintillaView setGeneralProperty:SCI_SETVIEWWS value:(showWhitespace ? SCWS_VISIBLEALWAYS : SCWS_INVISIBLE)];
}

- (void)setShowEOL:(BOOL)showEOL {
    _showEOL = showEOL;
    [_scintillaView setGeneralProperty:SCI_SETVIEWEOL value:(showEOL ? 1 : 0)];
}

- (void)setShowIndentGuides:(BOOL)showIndentGuides {
    _showIndentGuides = showIndentGuides;
    [_scintillaView setGeneralProperty:SCI_SETINDENTATIONGUIDES value:(showIndentGuides ? SC_IV_LOOKBOTH : SC_IV_NONE)];
}

- (void)setShowFolding:(BOOL)showFolding {
    _showFolding = showFolding;
    [_scintillaView setGeneralProperty:SCI_SETMARGINWIDTHN parameter:2 value:(showFolding ? 16 : 0)];
}

- (void)setHighlightCurrentLine:(BOOL)highlightCurrentLine {
    _highlightCurrentLine = highlightCurrentLine;
    [_scintillaView setGeneralProperty:SCI_SETCARETLINEVISIBLE value:(highlightCurrentLine ? 1 : 0)];
}

- (void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
    [_scintillaView setFontName:_fontName size:(int)_fontSize bold:NO italic:NO];
}

- (void)setFontName:(NSString *)fontName {
    _fontName = fontName;
    [_scintillaView setFontName:_fontName size:(int)_fontSize bold:NO italic:NO];
}

- (void)setTabWidth:(NSInteger)tabWidth {
    _tabWidth = tabWidth;
    [_scintillaView setGeneralProperty:SCI_SETTABWIDTH value:tabWidth];
    [_scintillaView setGeneralProperty:SCI_SETINDENT value:tabWidth];
}

- (void)setUseSpacesForTabs:(BOOL)useSpacesForTabs {
    _useSpacesForTabs = useSpacesForTabs;
    [_scintillaView setGeneralProperty:SCI_SETUSETABS value:(useSpacesForTabs ? 0 : 1)];
}

#pragma mark - Edit Actions

- (void)undo {
    [_scintillaView message:SCI_UNDO wParam:0 lParam:0];
}

- (void)redo {
    [_scintillaView message:SCI_REDO wParam:0 lParam:0];
}

- (void)selectAll {
    [_scintillaView message:SCI_SELECTALL wParam:0 lParam:0];
}

- (void)copyText {
    [_scintillaView message:SCI_COPY wParam:0 lParam:0];
}

- (void)cutText {
    [_scintillaView message:SCI_CUT wParam:0 lParam:0];
}

- (void)pasteText {
    [_scintillaView message:SCI_PASTE wParam:0 lParam:0];
}

- (void)deleteSelectedText {
    [_scintillaView message:SCI_CLEAR wParam:0 lParam:0];
}

- (void)moveLinesUp {
    [_scintillaView message:SCI_MOVESELECTEDLINESUP wParam:0 lParam:0];
}

- (void)moveLinesDown {
    [_scintillaView message:SCI_MOVESELECTEDLINESDOWN wParam:0 lParam:0];
}

- (void)duplicateCurrentLine {
    [_scintillaView message:SCI_SELECTIONDUPLICATE wParam:0 lParam:0];
}

- (void)deleteCurrentLine {
    [_scintillaView message:SCI_LINEDELETE wParam:0 lParam:0];
}

- (void)joinLines {
    [_scintillaView message:SCI_TARGETFROMSELECTION wParam:0 lParam:0];
    [_scintillaView message:SCI_LINESJOIN wParam:0 lParam:0];
}

- (void)toggleLineComment {
    // Generic toggle - insert/remove // comment for current line
    NSInteger pos = [_scintillaView message:SCI_GETCURRENTPOS wParam:0 lParam:0];
    NSInteger line = [_scintillaView message:SCI_LINEFROMPOSITION wParam:pos lParam:0];
    NSInteger lineStart = [_scintillaView message:SCI_POSITIONFROMLINE wParam:line lParam:0];
    NSInteger lineEnd = [_scintillaView message:SCI_GETLINEENDPOSITION wParam:line lParam:0];

    // Get line content
    NSInteger lineLen = lineEnd - lineStart;
    if (lineLen <= 0) return;

    char *buf = (char *)malloc(lineLen + 2);
    buf[lineLen] = 0;
    [_scintillaView message:SCI_GETLINE wParam:line lParam:(sptr_t)buf];
    NSString *lineStr = [NSString stringWithUTF8String:buf];
    free(buf);

    NSString *trimmed = [lineStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([trimmed hasPrefix:@"//"]) {
        // Remove comment
        NSRange range = [lineStr rangeOfString:@"//"];
        if (range.location != NSNotFound) {
            [_scintillaView message:SCI_SETSEL wParam:lineStart + range.location lParam:lineStart + range.location + 2];
            [_scintillaView message:SCI_REPLACESEL wParam:0 lParam:(sptr_t)""];
        }
    } else {
        // Add comment
        [_scintillaView message:SCI_INSERTTEXT wParam:lineStart lParam:(sptr_t)"//"];
    }
}

- (void)toUpperCase {
    [_scintillaView message:SCI_UPPERCASE wParam:0 lParam:0];
}

- (void)toLowerCase {
    [_scintillaView message:SCI_LOWERCASE wParam:0 lParam:0];
}

- (void)foldAll {
    // SC_FOLDACTION_CONTRACT = 0
    [_scintillaView message:SCI_FOLDALL wParam:0 lParam:0];
}

- (void)unfoldAll {
    // SC_FOLDACTION_EXPAND = 1
    [_scintillaView message:SCI_FOLDALL wParam:1 lParam:0];
}

- (void)zoomIn {
    [_scintillaView message:SCI_ZOOMIN wParam:0 lParam:0];
}

- (void)zoomOut {
    [_scintillaView message:SCI_ZOOMOUT wParam:0 lParam:0];
}

- (void)zoomReset {
    [_scintillaView message:SCI_SETZOOM wParam:0 lParam:0];
}

- (void)gotoLine:(NSInteger)lineNumber {
    NSInteger line = lineNumber - 1;
    if (line < 0) line = 0;
    [_scintillaView message:SCI_ENSUREVISIBLE wParam:line lParam:0];
    [_scintillaView message:SCI_GOTOLINE wParam:line lParam:0];
    [[_scintillaView window] makeFirstResponder:[_scintillaView content]];
}

- (void)scrollToTop {
    [_scintillaView message:SCI_GOTOLINE wParam:0 lParam:0];
}

- (void)scrollToBottom {
    NSInteger lastLine = [_scintillaView message:SCI_GETLINECOUNT wParam:0 lParam:0] - 1;
    [_scintillaView message:SCI_GOTOLINE wParam:lastLine lParam:0];
}

#pragma mark - ScintillaNotificationProtocol

- (void)notification:(SCNotification *)scn {
    if (!scn) return;

    switch (scn->nmhdr.code) {
        case SCN_MODIFIED:
            if (scn->modificationType & (SC_MOD_INSERTTEXT | SC_MOD_DELETETEXT)) {
                if (_document) {
                    _document.content = [_scintillaView string] ?: @"";
                    _document.isModified = YES;
                }
                [_delegate editorViewContentChanged:self];
            }
            break;

        case SCN_UPDATEUI:
            if (scn->updated & (SC_UPDATE_SELECTION | SC_UPDATE_CONTENT)) {
                NSInteger line = self.caretLine;
                NSInteger col = self.caretColumn;
                [_delegate editorView:self cursorMovedToLine:line column:col];
                [_delegate editorViewSelectionChanged:self];

                // Brace matching
                [self updateBraceHighlight];
            }
            break;

        case SCN_CHARADDED:
            // Auto-indent on new line
            if (scn->ch == '\n') {
                [self autoIndent];
            }
            break;

        case SCN_MARGINCLICK:
            // Handle fold margin click
            if (scn->margin == 2) {
                NSInteger line = [_scintillaView message:SCI_LINEFROMPOSITION wParam:scn->position lParam:0];
                [_scintillaView message:SCI_TOGGLEFOLD wParam:line lParam:0];
            }
            break;

        default:
            break;
    }
}

- (void)updateBraceHighlight {
    NSInteger pos = [_scintillaView message:SCI_GETCURRENTPOS wParam:0 lParam:0];
    NSInteger bracePos = INVALID_POSITION;
    char ch = (char)[_scintillaView message:SCI_GETCHARAT wParam:pos lParam:0];

    if (ch == '(' || ch == ')' || ch == '[' || ch == ']' ||
        ch == '{' || ch == '}' || ch == '<' || ch == '>') {
        bracePos = pos;
    } else if (pos > 0) {
        ch = (char)[_scintillaView message:SCI_GETCHARAT wParam:pos - 1 lParam:0];
        if (ch == '(' || ch == ')' || ch == '[' || ch == ']' ||
            ch == '{' || ch == '}' || ch == '<' || ch == '>') {
            bracePos = pos - 1;
        }
    }

    if (bracePos != INVALID_POSITION) {
        NSInteger match = [_scintillaView message:SCI_BRACEMATCH wParam:bracePos lParam:0];
        if (match != INVALID_POSITION) {
            [_scintillaView message:SCI_BRACEHIGHLIGHT wParam:bracePos lParam:match];
        } else {
            [_scintillaView message:SCI_BRACEHIGHLIGHT wParam:INVALID_POSITION lParam:INVALID_POSITION];
        }
    } else {
        [_scintillaView message:SCI_BRACEHIGHLIGHT wParam:INVALID_POSITION lParam:INVALID_POSITION];
    }
}

- (void)autoIndent {
    NSInteger pos = [_scintillaView message:SCI_GETCURRENTPOS wParam:0 lParam:0];
    NSInteger curLine = [_scintillaView message:SCI_LINEFROMPOSITION wParam:pos lParam:0];
    if (curLine <= 0) return;

    NSInteger prevLine = curLine - 1;
    NSInteger prevIndent = [_scintillaView message:SCI_GETLINEINDENTATION wParam:prevLine lParam:0];

    if (prevIndent > 0) {
        [_scintillaView message:SCI_SETLINEINDENTATION wParam:curLine lParam:prevIndent];
        NSInteger newPos = [_scintillaView message:SCI_GETLINEINDENTPOSITION wParam:curLine lParam:0];
        [_scintillaView message:SCI_GOTOPOS wParam:newPos lParam:0];
    }
}

@end
