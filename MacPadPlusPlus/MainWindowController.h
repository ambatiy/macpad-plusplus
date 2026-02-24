#import <Cocoa/Cocoa.h>
#import "MPDocument.h"
#import "FindResultsController.h"
#import "FindReplacePanel.h"

NS_ASSUME_NONNULL_BEGIN

@class EditorView;
@class StatusBarController;

@interface MainWindowController : NSWindowController
    <FindResultsControllerDelegate, FindReplacePanelFindAllDelegate>

@property (nonatomic, strong, readonly) NSArray<MPDocument *> *documents;
@property (nonatomic, strong, nullable, readonly) MPDocument *activeDocument;
@property (nonatomic, strong, nullable, readonly) EditorView *activeEditorView;

// Document management
- (MPDocument *)newDocument;
- (nullable MPDocument *)openDocumentFromURL:(NSURL *)url;
- (BOOL)closeDocumentObj:(MPDocument *)document;
- (void)closeAllDocuments;
- (BOOL)saveDocumentObj:(MPDocument *)document;
- (BOOL)saveDocumentObjAs:(MPDocument *)document;
- (void)saveAllDocuments;
- (void)reloadDocument:(MPDocument *)document;

// Tab management
- (void)selectDocument:(MPDocument *)document;
- (void)selectNextTab;
- (void)selectPreviousTab;
- (void)moveTabToNewWindow:(MPDocument *)document;

// Find/Replace
- (void)showFindPanel;
- (void)showFindAndReplacePanel;

// Menu actions
- (IBAction)newDocument:(nullable id)sender;
- (IBAction)openDocument:(nullable id)sender;
- (IBAction)saveDocument:(nullable id)sender;
- (IBAction)saveDocumentAs:(nullable id)sender;
- (IBAction)saveAllDocuments:(nullable id)sender;
- (IBAction)closeDocument:(nullable id)sender;
- (IBAction)reloadFromDisk:(nullable id)sender;
- (IBAction)showFindPanel:(nullable id)sender;
- (IBAction)showFindAndReplacePanel:(nullable id)sender;
- (IBAction)gotoLine:(nullable id)sender;
- (IBAction)selectNextTab:(nullable id)sender;
- (IBAction)selectPreviousTab:(nullable id)sender;
- (IBAction)toggleWordWrap:(nullable id)sender;
- (IBAction)toggleLineNumbers:(nullable id)sender;
- (IBAction)toggleWhitespace:(nullable id)sender;
- (IBAction)toggleIndentGuides:(nullable id)sender;
- (IBAction)zoomIn:(nullable id)sender;
- (IBAction)zoomOut:(nullable id)sender;
- (IBAction)zoomReset:(nullable id)sender;
- (IBAction)foldAll:(nullable id)sender;
- (IBAction)unfoldAll:(nullable id)sender;
- (IBAction)moveLinesUp:(nullable id)sender;
- (IBAction)moveLinesDown:(nullable id)sender;
- (IBAction)duplicateLine:(nullable id)sender;
- (IBAction)deleteLine:(nullable id)sender;
- (IBAction)toUpperCase:(nullable id)sender;
- (IBAction)toLowerCase:(nullable id)sender;
- (IBAction)toggleLineComment:(nullable id)sender;
- (IBAction)setLanguage:(nullable id)sender;
- (IBAction)setLineEndingLF:(nullable id)sender;
- (IBAction)setLineEndingCRLF:(nullable id)sender;
- (IBAction)setLineEndingCR:(nullable id)sender;
- (IBAction)convertToUTF8:(nullable id)sender;
- (IBAction)convertToUTF8BOM:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
