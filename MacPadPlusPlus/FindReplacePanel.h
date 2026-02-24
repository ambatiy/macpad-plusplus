#import <Cocoa/Cocoa.h>
#import "FindResultsController.h"   // for FindResultEntry

@class EditorView;
@class FindReplacePanel;

NS_ASSUME_NONNULL_BEGIN

// Delegate notified when "Find All" is triggered
@protocol FindReplacePanelFindAllDelegate <NSObject>
- (void)findPanel:(FindReplacePanel *)panel
       didFindAll:(NSArray<FindResultEntry *> *)results
          forTerm:(NSString *)term;
@end

@interface FindReplacePanel : NSPanel

@property (nonatomic, weak, nullable) EditorView *targetEditor;
@property (nonatomic, weak, nullable) id<FindReplacePanelFindAllDelegate> findAllDelegate;

+ (instancetype)sharedPanel;

- (void)showFindMode;
- (void)showFindAndReplaceMode;
- (void)findNext;
- (void)findPrevious;

@end

NS_ASSUME_NONNULL_END
