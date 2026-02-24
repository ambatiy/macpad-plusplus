#import <Cocoa/Cocoa.h>
#import "MPDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface StatusBarController : NSViewController

@property (nonatomic, assign) NSInteger currentLine;    // 1-based
@property (nonatomic, assign) NSInteger currentColumn;  // 1-based
@property (nonatomic, assign) NSInteger selectionLength;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, assign) MPEncoding encoding;
@property (nonatomic, assign) MPLineEnding lineEnding;
@property (nonatomic, assign) NSInteger totalLines;
@property (nonatomic, assign) NSInteger documentLength;

- (void)updateFromDocument:(MPDocument *)document line:(NSInteger)line column:(NSInteger)column selLen:(NSInteger)selLen;

@end

NS_ASSUME_NONNULL_END
