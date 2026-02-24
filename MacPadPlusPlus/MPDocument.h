#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MPLineEnding) {
    MPLineEndingLF = 0,
    MPLineEndingCRLF,
    MPLineEndingCR,
};

typedef NS_ENUM(NSInteger, MPEncoding) {
    MPEncodingUTF8 = 0,
    MPEncodingUTF8BOM,
    MPEncodingUTF16BE,
    MPEncodingUTF16LE,
    MPEncodingASCII,
    MPEncodingLatin1,
};

@interface MPDocument : NSObject

@property (nonatomic, copy, nullable) NSURL *fileURL;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, assign) BOOL isModified;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, assign) MPLineEnding lineEnding;
@property (nonatomic, assign) MPEncoding encoding;
@property (nonatomic, assign) NSInteger caretPosition;
@property (nonatomic, assign) NSInteger scrollPosition;

- (instancetype)initNew;
- (instancetype)initWithURL:(NSURL *)url;

- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error;
- (BOOL)reloadFromDisk:(NSError **)error;

- (NSString *)displayTitle;
- (NSString *)lineEndingName;
- (NSString *)encodingName;
- (NSStringEncoding)nsStringEncoding;

@end

NS_ASSUME_NONNULL_END
