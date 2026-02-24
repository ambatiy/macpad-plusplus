#import <Cocoa/Cocoa.h>
#import "ScintillaView.h"
#import "MPDocument.h"

NS_ASSUME_NONNULL_BEGIN

@class EditorView;

@protocol EditorViewDelegate <NSObject>
- (void)editorViewContentChanged:(EditorView *)editorView;
- (void)editorView:(EditorView *)editorView cursorMovedToLine:(NSInteger)line column:(NSInteger)column;
- (void)editorViewSelectionChanged:(EditorView *)editorView;
@end

@interface EditorView : NSView <ScintillaNotificationProtocol>

@property (nonatomic, weak, nullable) id<EditorViewDelegate> delegate;
@property (nonatomic, strong, readonly) ScintillaView *scintillaView;
@property (nonatomic, strong) MPDocument *document;

// Content
@property (nonatomic, copy) NSString *text;
- (NSString *)selectedText;
- (NSRange)selectedRange;

// Cursor
@property (nonatomic, assign) NSInteger caretLine;    // 1-based
@property (nonatomic, assign) NSInteger caretColumn;  // 1-based

// Settings
@property (nonatomic, assign) BOOL wordWrapEnabled;
@property (nonatomic, assign) BOOL showLineNumbers;
@property (nonatomic, assign) BOOL showWhitespace;
@property (nonatomic, assign) BOOL showEOL;
@property (nonatomic, assign) BOOL showIndentGuides;
@property (nonatomic, assign) BOOL showFolding;
@property (nonatomic, assign) BOOL highlightCurrentLine;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, assign) NSInteger tabWidth;
@property (nonatomic, assign) BOOL useSpacesForTabs;

// Actions
- (void)undo;
- (void)redo;
- (void)selectAll;
- (void)copyText;
- (void)cutText;
- (void)pasteText;
- (void)deleteSelectedText;

- (void)moveLinesUp;
- (void)moveLinesDown;
- (void)duplicateCurrentLine;
- (void)deleteCurrentLine;
- (void)joinLines;
- (void)toggleLineComment;
- (void)toUpperCase;
- (void)toLowerCase;

- (void)foldAll;
- (void)unfoldAll;

- (void)zoomIn;
- (void)zoomOut;
- (void)zoomReset;

- (void)gotoLine:(NSInteger)lineNumber;
- (void)scrollToTop;
- (void)scrollToBottom;

- (NSInteger)lineCount;
- (NSInteger)caretPosition;

// Language
- (void)setLanguage:(NSString *)language;

@end

NS_ASSUME_NONNULL_END
