#import <Cocoa/Cocoa.h>

@class EditorView;

NS_ASSUME_NONNULL_BEGIN

@interface FindReplacePanel : NSPanel

@property (nonatomic, weak, nullable) EditorView *targetEditor;

+ (instancetype)sharedPanel;

- (void)showFindMode;
- (void)showFindAndReplaceMode;
- (void)findNext;
- (void)findPrevious;

@end

NS_ASSUME_NONNULL_END
