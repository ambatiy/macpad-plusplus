#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

// ── Model object for a single search result ───────────────────────────────────
@interface FindResultEntry : NSObject
@property (nonatomic, assign) NSInteger lineNumber;   // 1-based
@property (nonatomic, copy)   NSString  *lineText;    // full line content
@property (nonatomic, assign) NSRange    matchRange;  // range within lineText
@end

// ── Delegate ──────────────────────────────────────────────────────────────────
@class FindResultsController;

@protocol FindResultsControllerDelegate <NSObject>
- (void)findResultsController:(FindResultsController *)controller
          didSelectLineNumber:(NSInteger)lineNumber;
- (void)findResultsControllerDidClose:(FindResultsController *)controller;
@end

// ── Controller ────────────────────────────────────────────────────────────────
@interface FindResultsController : NSViewController
    <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak, nullable) id<FindResultsControllerDelegate> delegate;
@property (nonatomic, readonly) NSInteger resultCount;

- (void)showResults:(NSArray<FindResultEntry *> *)results
         searchTerm:(NSString *)term;
- (void)clearResults;

@end

NS_ASSUME_NONNULL_END
