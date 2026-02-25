#import "MPDocument.h"

static NSInteger sNewDocumentCounter = 0;

@implementation MPDocument

- (instancetype)initNew {
    self = [super init];
    if (self) {
        sNewDocumentCounter++;
        _isNew = YES;
        _isModified = NO;
        _title = [NSString stringWithFormat:@"new %ld", (long)sNewDocumentCounter];
        _content = @"";
        _language = @"none";
        _lineEnding = MPLineEndingLF;
        _encoding = MPEncodingUTF8;
        _caretPosition = 0;
        _scrollPosition = 0;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _fileURL = url;
        _isNew = NO;
        _isModified = NO;
        _title = url.lastPathComponent;
        _language = [self detectLanguageFromURL:url];
        _lineEnding = MPLineEndingLF;
        _encoding = MPEncodingUTF8;
        _caretPosition = 0;
        _scrollPosition = 0;

        NSError *error = nil;
        [self loadFromURL:url error:&error];
    }
    return self;
}

- (BOOL)loadFromURL:(NSURL *)url error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) return NO;

    // Detect encoding
    NSString *content = nil;
    NSStringEncoding detected = NSUTF8StringEncoding;

    // Check for BOM
    if (data.length >= 3 &&
        ((const uint8_t *)data.bytes)[0] == 0xEF &&
        ((const uint8_t *)data.bytes)[1] == 0xBB &&
        ((const uint8_t *)data.bytes)[2] == 0xBF) {
        _encoding = MPEncodingUTF8BOM;
        detected = NSUTF8StringEncoding;
        data = [data subdataWithRange:NSMakeRange(3, data.length - 3)];
    } else if (data.length >= 2 &&
               ((const uint8_t *)data.bytes)[0] == 0xFE &&
               ((const uint8_t *)data.bytes)[1] == 0xFF) {
        _encoding = MPEncodingUTF16BE;
        detected = NSUTF16BigEndianStringEncoding;
    } else if (data.length >= 2 &&
               ((const uint8_t *)data.bytes)[0] == 0xFF &&
               ((const uint8_t *)data.bytes)[1] == 0xFE) {
        _encoding = MPEncodingUTF16LE;
        detected = NSUTF16LittleEndianStringEncoding;
    } else {
        _encoding = MPEncodingUTF8;
        detected = NSUTF8StringEncoding;
    }

    content = [[NSString alloc] initWithData:data encoding:detected];
    if (!content) {
        // Fallback to Latin-1
        content = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
        _encoding = MPEncodingLatin1;
    }
    if (!content) content = @"";

    // Detect line ending
    if ([content containsString:@"\r\n"]) {
        _lineEnding = MPLineEndingCRLF;
    } else if ([content containsString:@"\r"]) {
        _lineEnding = MPLineEndingCR;
    } else {
        _lineEnding = MPLineEndingLF;
    }

    // Normalize to LF for internal storage
    _content = [content stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    _content = [_content stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    return YES;
}

- (BOOL)reloadFromDisk:(NSError **)error {
    if (!_fileURL) return NO;
    return [self loadFromURL:_fileURL error:error];
}

- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error {
    NSString *saveContent = _content;

    // Convert line endings
    if (_lineEnding == MPLineEndingCRLF) {
        saveContent = [saveContent stringByReplacingOccurrencesOfString:@"\n" withString:@"\r\n"];
    } else if (_lineEnding == MPLineEndingCR) {
        saveContent = [saveContent stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
    }

    NSData *data = [saveContent dataUsingEncoding:[self nsStringEncoding]];
    if (!data) {
        data = [saveContent dataUsingEncoding:NSUTF8StringEncoding];
        _encoding = MPEncodingUTF8;
    }

    // Add BOM for UTF-8 BOM
    if (_encoding == MPEncodingUTF8BOM) {
        NSMutableData *bomData = [NSMutableData dataWithBytes:"\xEF\xBB\xBF" length:3];
        [bomData appendData:data];
        data = bomData;
    }

    if ([data writeToURL:url options:NSDataWritingAtomic error:error]) {
        BOOL urlChanged = ![url isEqual:_fileURL];
        _fileURL = url;
        _title = url.lastPathComponent;
        // Re-detect language when the file gets a new path (Save As)
        if (urlChanged) {
            _language = [self detectLanguageFromURL:url];
        }
        _isModified = NO;
        _isNew = NO;
        return YES;
    }
    return NO;
}

- (NSString *)displayTitle {
    NSString *title = _title ?: @"Untitled";
    return _isModified ? [title stringByAppendingString:@" •"] : title;
}

- (NSString *)lineEndingName {
    switch (_lineEnding) {
        case MPLineEndingCRLF: return @"Windows (CRLF)";
        case MPLineEndingCR:   return @"Old Mac (CR)";
        default:               return @"Unix (LF)";
    }
}

- (NSString *)encodingName {
    switch (_encoding) {
        case MPEncodingUTF8BOM:  return @"UTF-8 BOM";
        case MPEncodingUTF16BE:  return @"UTF-16 BE";
        case MPEncodingUTF16LE:  return @"UTF-16 LE";
        case MPEncodingASCII:    return @"ASCII";
        case MPEncodingLatin1:   return @"Latin-1";
        default:                 return @"UTF-8";
    }
}

- (NSStringEncoding)nsStringEncoding {
    switch (_encoding) {
        case MPEncodingUTF8BOM:  return NSUTF8StringEncoding;
        case MPEncodingUTF16BE:  return NSUTF16BigEndianStringEncoding;
        case MPEncodingUTF16LE:  return NSUTF16LittleEndianStringEncoding;
        case MPEncodingASCII:    return NSASCIIStringEncoding;
        case MPEncodingLatin1:   return NSISOLatin1StringEncoding;
        default:                 return NSUTF8StringEncoding;
    }
}

- (NSString *)detectLanguageFromURL:(NSURL *)url {
    NSString *ext = url.pathExtension.lowercaseString;
    NSString *name = url.lastPathComponent.lowercaseString;

    NSDictionary *extMap = @{
        @"c": @"cpp", @"cpp": @"cpp", @"cc": @"cpp", @"cxx": @"cpp",
        @"h": @"cpp", @"hpp": @"cpp", @"hxx": @"cpp",
        @"mm": @"cpp", @"m": @"cpp",
        @"py": @"python", @"pyw": @"python",
        @"js": @"javascript", @"mjs": @"javascript", @"cjs": @"javascript",
        @"ts": @"javascript", @"jsx": @"javascript", @"tsx": @"javascript",
        @"html": @"hypertext", @"htm": @"hypertext",
        @"xml": @"xml", @"xsl": @"xml", @"xslt": @"xml", @"svg": @"xml",
        @"css": @"css",
        @"json": @"json",
        @"md": @"markdown", @"markdown": @"markdown",
        @"sh": @"bash", @"bash": @"bash", @"zsh": @"bash", @"fish": @"bash",
        @"rb": @"ruby",
        @"java": @"java",
        @"cs": @"cpp",
        @"swift": @"cpp",
        @"go": @"cpp",
        @"rs": @"cpp",
        @"php": @"phpscript",
        @"sql": @"sql",
        @"lua": @"lua",
        @"pl": @"perl", @"pm": @"perl",
        @"r": @"r",
        @"yaml": @"yaml", @"yml": @"yaml",
        @"toml": @"toml",
        @"cmake": @"cmake",
        @"bat": @"batch", @"cmd": @"batch",
        @"ps1": @"powershell",
        @"asm": @"asm", @"s": @"asm",
        @"diff": @"diff", @"patch": @"diff",
        @"ini": @"properties", @"cfg": @"properties",
        @"conf": @"properties",
        @"properties": @"properties",
        @"tex": @"latex",
        @"makefile": @"makefile", @"mk": @"makefile",
    };

    NSString *lang = extMap[ext];
    if (!lang) {
        // Check filename
        if ([name isEqualToString:@"makefile"] || [name isEqualToString:@"gnumakefile"]) {
            lang = @"makefile";
        } else if ([name isEqualToString:@"dockerfile"]) {
            lang = @"makefile";
        } else {
            lang = @"none";
        }
    }
    return lang;
}

@end
