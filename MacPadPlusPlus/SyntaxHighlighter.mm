#import "SyntaxHighlighter.h"
#import "ScintillaView.h"
#import "Scintilla.h"
#import "SciLexer.h"

// Lexilla C interface
extern "C" {
    void *CreateLexer(const char *name);
}

static SyntaxHighlighter *sSharedHighlighter = nil;

// Color helper macros
#define RGB_COLOR(r,g,b) [NSColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]

@implementation SyntaxHighlighter

+ (instancetype)sharedHighlighter {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sSharedHighlighter = [[SyntaxHighlighter alloc] init];
    });
    return sSharedHighlighter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentTheme = MPColorThemeDefault;
    }
    return self;
}

- (void)applyLanguage:(NSString *)language toEditor:(ScintillaView *)editor {
    const char *lexName = [language UTF8String];

    // Use Lexilla to create lexer
    void *lexer = CreateLexer(lexName);
    if (lexer) {
        [editor message:SCI_SETILEXER wParam:0 lParam:(sptr_t)lexer];
    }

    [self applyTheme:_currentTheme toEditor:editor language:language];
}

- (void)applyTheme:(MPColorTheme)theme toEditor:(ScintillaView *)editor language:(NSString *)language {
    _currentTheme = theme;

    // Base colors based on theme
    NSColor *bgColor, *fgColor, *keywordColor, *stringColor, *commentColor,
            *numberColor, *operatorColor, *preprocessorColor, *typeColor, *lineNumBgColor;

    switch (theme) {
        case MPColorThemeDark:
            bgColor        = RGB_COLOR(30, 30, 30);
            fgColor        = RGB_COLOR(220, 220, 220);
            keywordColor   = RGB_COLOR(86, 156, 214);
            stringColor    = RGB_COLOR(206, 145, 120);
            commentColor   = RGB_COLOR(106, 153, 85);
            numberColor    = RGB_COLOR(181, 206, 168);
            operatorColor  = RGB_COLOR(200, 200, 200);
            preprocessorColor = RGB_COLOR(155, 155, 100);
            typeColor      = RGB_COLOR(78, 201, 176);
            lineNumBgColor = RGB_COLOR(40, 40, 40);
            break;

        case MPColorThemeMonokai:
            bgColor        = RGB_COLOR(39, 40, 34);
            fgColor        = RGB_COLOR(248, 248, 242);
            keywordColor   = RGB_COLOR(249, 38, 114);
            stringColor    = RGB_COLOR(230, 219, 116);
            commentColor   = RGB_COLOR(117, 113, 94);
            numberColor    = RGB_COLOR(174, 129, 255);
            operatorColor  = RGB_COLOR(248, 248, 242);
            preprocessorColor = RGB_COLOR(102, 217, 239);
            typeColor      = RGB_COLOR(102, 217, 239);
            lineNumBgColor = RGB_COLOR(50, 50, 44);
            break;

        case MPColorThemeSolarizedLight:
            bgColor        = RGB_COLOR(253, 246, 227);
            fgColor        = RGB_COLOR(101, 123, 131);
            keywordColor   = RGB_COLOR(133, 153, 0);
            stringColor    = RGB_COLOR(42, 161, 152);
            commentColor   = RGB_COLOR(147, 161, 161);
            numberColor    = RGB_COLOR(211, 54, 130);
            operatorColor  = RGB_COLOR(101, 123, 131);
            preprocessorColor = RGB_COLOR(203, 75, 22);
            typeColor      = RGB_COLOR(38, 139, 210);
            lineNumBgColor = RGB_COLOR(238, 232, 213);
            break;

        case MPColorThemeSolarizedDark:
            bgColor        = RGB_COLOR(0, 43, 54);
            fgColor        = RGB_COLOR(131, 148, 150);
            keywordColor   = RGB_COLOR(133, 153, 0);
            stringColor    = RGB_COLOR(42, 161, 152);
            commentColor   = RGB_COLOR(88, 110, 117);
            numberColor    = RGB_COLOR(211, 54, 130);
            operatorColor  = RGB_COLOR(131, 148, 150);
            preprocessorColor = RGB_COLOR(203, 75, 22);
            typeColor      = RGB_COLOR(38, 139, 210);
            lineNumBgColor = RGB_COLOR(7, 54, 66);
            break;

        case MPColorThemeOneDarkPro:
            bgColor        = RGB_COLOR(40, 44, 52);
            fgColor        = RGB_COLOR(171, 178, 191);
            keywordColor   = RGB_COLOR(198, 120, 221);
            stringColor    = RGB_COLOR(152, 195, 121);
            commentColor   = RGB_COLOR(92, 99, 112);
            numberColor    = RGB_COLOR(209, 154, 102);
            operatorColor  = RGB_COLOR(171, 178, 191);
            preprocessorColor = RGB_COLOR(224, 108, 117);
            typeColor      = RGB_COLOR(97, 175, 239);
            lineNumBgColor = RGB_COLOR(33, 37, 43);
            break;

        case MPColorThemeDracula:
            bgColor        = RGB_COLOR(40, 42, 54);
            fgColor        = RGB_COLOR(248, 248, 242);
            keywordColor   = RGB_COLOR(255, 121, 198);
            stringColor    = RGB_COLOR(241, 250, 140);
            commentColor   = RGB_COLOR(98, 114, 164);
            numberColor    = RGB_COLOR(189, 147, 249);
            operatorColor  = RGB_COLOR(255, 121, 198);
            preprocessorColor = RGB_COLOR(139, 233, 253);
            typeColor      = RGB_COLOR(139, 233, 253);
            lineNumBgColor = RGB_COLOR(68, 71, 90);
            break;

        case MPColorThemeNord:
            bgColor        = RGB_COLOR(46, 52, 64);
            fgColor        = RGB_COLOR(216, 222, 233);
            keywordColor   = RGB_COLOR(129, 161, 193);
            stringColor    = RGB_COLOR(163, 190, 140);
            commentColor   = RGB_COLOR(76, 86, 106);
            numberColor    = RGB_COLOR(180, 142, 173);
            operatorColor  = RGB_COLOR(129, 161, 193);
            preprocessorColor = RGB_COLOR(136, 192, 208);
            typeColor      = RGB_COLOR(143, 188, 187);
            lineNumBgColor = RGB_COLOR(59, 66, 82);
            break;

        case MPColorThemeGruvboxDark:
            bgColor        = RGB_COLOR(40, 40, 40);
            fgColor        = RGB_COLOR(235, 219, 178);
            keywordColor   = RGB_COLOR(251, 73, 52);
            stringColor    = RGB_COLOR(184, 187, 38);
            commentColor   = RGB_COLOR(146, 131, 116);
            numberColor    = RGB_COLOR(211, 134, 155);
            operatorColor  = RGB_COLOR(235, 219, 178);
            preprocessorColor = RGB_COLOR(250, 189, 47);
            typeColor      = RGB_COLOR(131, 165, 152);
            lineNumBgColor = RGB_COLOR(60, 56, 54);
            break;

        case MPColorThemeGruvboxLight:
            bgColor        = RGB_COLOR(251, 241, 199);
            fgColor        = RGB_COLOR(60, 56, 54);
            keywordColor   = RGB_COLOR(157, 0, 6);
            stringColor    = RGB_COLOR(121, 116, 14);
            commentColor   = RGB_COLOR(146, 131, 116);
            numberColor    = RGB_COLOR(143, 63, 113);
            operatorColor  = RGB_COLOR(60, 56, 54);
            preprocessorColor = RGB_COLOR(181, 118, 20);
            typeColor      = RGB_COLOR(66, 123, 88);
            lineNumBgColor = RGB_COLOR(242, 229, 188);
            break;

        case MPColorThemeTomorrowNight:
            bgColor        = RGB_COLOR(29, 31, 33);
            fgColor        = RGB_COLOR(197, 200, 198);
            keywordColor   = RGB_COLOR(178, 148, 187);
            stringColor    = RGB_COLOR(181, 189, 104);
            commentColor   = RGB_COLOR(150, 152, 150);
            numberColor    = RGB_COLOR(222, 147, 95);
            operatorColor  = RGB_COLOR(197, 200, 198);
            preprocessorColor = RGB_COLOR(204, 102, 102);
            typeColor      = RGB_COLOR(129, 162, 190);
            lineNumBgColor = RGB_COLOR(40, 42, 46);
            break;

        case MPColorThemeCobalt2:
            bgColor        = RGB_COLOR(25, 53, 73);
            fgColor        = RGB_COLOR(255, 255, 255);
            keywordColor   = RGB_COLOR(255, 157, 0);
            stringColor    = RGB_COLOR(58, 217, 0);
            commentColor   = RGB_COLOR(0, 136, 255);
            numberColor    = RGB_COLOR(255, 98, 140);
            operatorColor  = RGB_COLOR(255, 157, 0);
            preprocessorColor = RGB_COLOR(128, 255, 187);
            typeColor      = RGB_COLOR(158, 255, 255);
            lineNumBgColor = RGB_COLOR(13, 58, 88);
            break;

        case MPColorThemeMaterialDark:
            bgColor        = RGB_COLOR(38, 50, 56);
            fgColor        = RGB_COLOR(205, 211, 222);
            keywordColor   = RGB_COLOR(137, 221, 255);
            stringColor    = RGB_COLOR(195, 232, 141);
            commentColor   = RGB_COLOR(84, 110, 122);
            numberColor    = RGB_COLOR(247, 140, 108);
            operatorColor  = RGB_COLOR(137, 221, 255);
            preprocessorColor = RGB_COLOR(199, 146, 234);
            typeColor      = RGB_COLOR(255, 203, 107);
            lineNumBgColor = RGB_COLOR(55, 71, 79);
            break;

        default: // Light theme
            bgColor        = [NSColor whiteColor];
            fgColor        = [NSColor blackColor];
            keywordColor   = RGB_COLOR(0, 0, 255);
            stringColor    = RGB_COLOR(163, 21, 21);
            commentColor   = RGB_COLOR(0, 128, 0);
            numberColor    = RGB_COLOR(9, 134, 88);
            operatorColor  = RGB_COLOR(0, 0, 0);
            preprocessorColor = RGB_COLOR(128, 64, 0);
            typeColor      = RGB_COLOR(43, 145, 175);
            lineNumBgColor = RGB_COLOR(240, 240, 240);
            break;
    }

    // Apply default style to all
    [editor setColorProperty:SCI_STYLESETBACK parameter:STYLE_DEFAULT value:bgColor];
    [editor setColorProperty:SCI_STYLESETFORE parameter:STYLE_DEFAULT value:fgColor];
    [editor message:SCI_STYLECLEARALL wParam:0 lParam:0];

    // Line number margin
    [editor setColorProperty:SCI_STYLESETBACK parameter:STYLE_LINENUMBER value:lineNumBgColor];
    [editor setColorProperty:SCI_STYLESETFORE parameter:STYLE_LINENUMBER value:RGB_COLOR(130, 130, 130)];

    // Brace highlight
    [editor setColorProperty:SCI_STYLESETBACK parameter:STYLE_BRACELIGHT value:RGB_COLOR(180, 220, 255)];
    [editor setColorProperty:SCI_STYLESETFORE parameter:STYLE_BRACELIGHT value:fgColor];
    [editor setColorProperty:SCI_STYLESETBACK parameter:STYLE_BRACEBAD value:RGB_COLOR(255, 180, 180)];

    // Apply language-specific styles
    [self applyLanguageStyles:language editor:editor
                     keyword:keywordColor string:stringColor comment:commentColor
                      number:numberColor operator:operatorColor preprocessor:preprocessorColor
                        type:typeColor fg:fgColor bg:bgColor];

    // Set caret color (no row highlight — EditorView disables SCI_SETCARETLINEVISIBLE)
    [editor setColorProperty:SCI_SETCARETFORE parameter:0 value:fgColor];

    // Selection color
    [editor setColorProperty:SCI_SETSELBACK parameter:1 value:RGB_COLOR(51, 153, 255)];

    // Edge line color
    NSColor *edgeColor = (theme == MPColorThemeDefault) ? RGB_COLOR(220, 220, 220) : RGB_COLOR(80, 80, 80);
    [editor setColorProperty:SCI_SETEDGECOLOUR parameter:0 value:edgeColor];
}

- (void)applyLanguageStyles:(NSString *)language editor:(ScintillaView *)editor
                    keyword:(NSColor *)kw string:(NSColor *)str comment:(NSColor *)cmt
                     number:(NSColor *)num operator:(NSColor *)op preprocessor:(NSColor *)pp
                       type:(NSColor *)tp fg:(NSColor *)fg bg:(NSColor *)bg {

    if ([language isEqualToString:@"cpp"] ||
        [language isEqualToString:@"javascript"]) {
        // SCE_C_* styles
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_COMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_COMMENTLINE value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_COMMENTDOC value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_WORD value:kw];
        [editor setGeneralProperty:SCI_STYLESETBOLD parameter:SCE_C_WORD value:1];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_STRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_CHARACTER value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_PREPROCESSOR value:pp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_OPERATOR value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_WORD2 value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_GLOBALCLASS value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_VERBATIM value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_C_REGEX value:RGB_COLOR(100, 150, 200)];

    } else if ([language isEqualToString:@"python"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_COMMENTLINE value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_COMMENTBLOCK value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_WORD value:kw];
        [editor setGeneralProperty:SCI_STYLESETBOLD parameter:SCE_P_WORD value:1];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_STRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_CHARACTER value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_TRIPLE value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_TRIPLEDOUBLE value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_OPERATOR value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_DECORATOR value:pp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_CLASSNAME value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_DEFNAME value:RGB_COLOR(220, 160, 50)];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_P_WORD2 value:tp];

    } else if ([language isEqualToString:@"hypertext"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_TAG value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_TAGUNKNOWN value:RGB_COLOR(200, 0, 0)];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_ATTRIBUTE value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_ATTRIBUTEUNKNOWN value:RGB_COLOR(200, 0, 0)];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_DOUBLESTRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_SINGLESTRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_COMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_ENTITY value:op];

    } else if ([language isEqualToString:@"xml"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_TAG value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_ATTRIBUTE value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_DOUBLESTRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_SINGLESTRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_H_COMMENT value:cmt];

    } else if ([language isEqualToString:@"css"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_COMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_TAG value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_CLASS value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_ID value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_ATTRIBUTE value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_PSEUDOCLASS value:pp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_UNKNOWN_PSEUDOCLASS value:RGB_COLOR(200,0,0)];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_OPERATOR value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_IDENTIFIER value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_DOUBLESTRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_SINGLESTRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_CSS_VALUE value:num];

    } else if ([language isEqualToString:@"json"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_STRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_STRINGEOL value:RGB_COLOR(200,0,0)];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_PROPERTYNAME value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_KEYWORD value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_LINECOMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_BLOCKCOMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_JSON_OPERATOR value:op];

    } else if ([language isEqualToString:@"bash"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_COMMENTLINE value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_WORD value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_STRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_CHARACTER value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_OPERATOR value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_IDENTIFIER value:fg];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_BACKTICKS value:pp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SH_PARAM value:tp];

    } else if ([language isEqualToString:@"sql"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_COMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_COMMENTLINE value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_COMMENTDOC value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_WORD value:kw];
        [editor setGeneralProperty:SCI_STYLESETBOLD parameter:SCE_SQL_WORD value:1];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_STRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_CHARACTER value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_OPERATOR value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_SQL_WORD2 value:tp];

    } else if ([language isEqualToString:@"ruby"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_COMMENTLINE value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_WORD value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_STRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_CHARACTER value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_OPERATOR value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_CLASSNAME value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_DEFNAME value:RGB_COLOR(220, 160, 50)];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_RB_SYMBOL value:pp];

    } else if ([language isEqualToString:@"lua"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_COMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_COMMENTLINE value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_COMMENTDOC value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_WORD value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_STRING value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_CHARACTER value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_LUA_OPERATOR value:op];

    } else if ([language isEqualToString:@"yaml"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_COMMENT value:cmt];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_IDENTIFIER value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_KEYWORD value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_NUMBER value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_REFERENCE value:pp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_DOCUMENT value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_TEXT value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_YAML_ERROR value:RGB_COLOR(200, 0, 0)];

    } else if ([language isEqualToString:@"markdown"]) {
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_STRONG1 value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_STRONG2 value:kw];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_EM1 value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_EM2 value:tp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_HEADER1 value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_HEADER2 value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_HEADER3 value:num];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_CODE value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_CODE2 value:str];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_LINK value:pp];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_ULIST_ITEM value:op];
        [editor setColorProperty:SCI_STYLESETFORE parameter:SCE_MARKDOWN_OLIST_ITEM value:op];
    }
}

- (NSArray<NSString *> *)allLanguageNames {
    return @[
        @"none", @"bash", @"batch", @"cmake", @"coffeescript", @"cpp",
        @"css", @"diff", @"html", @"hypertext", @"java", @"javascript",
        @"json", @"latex", @"lua", @"makefile", @"markdown", @"pascal",
        @"perl", @"php", @"phpscript", @"powershell", @"properties",
        @"python", @"r", @"ruby", @"rust", @"sql", @"swift", @"toml",
        @"typescript", @"xml", @"yaml",
    ];
}

- (NSString *)displayNameForLanguage:(NSString *)language {
    NSDictionary *names = @{
        @"none": @"Plain Text",
        @"bash": @"Bash",
        @"batch": @"Batch",
        @"cmake": @"CMake",
        @"coffeescript": @"CoffeeScript",
        @"cpp": @"C / C++",
        @"css": @"CSS",
        @"diff": @"Diff",
        @"html": @"HTML",
        @"hypertext": @"HTML",
        @"java": @"Java",
        @"javascript": @"JavaScript",
        @"json": @"JSON",
        @"latex": @"LaTeX",
        @"lua": @"Lua",
        @"makefile": @"Makefile",
        @"markdown": @"Markdown",
        @"pascal": @"Pascal",
        @"perl": @"Perl",
        @"php": @"PHP",
        @"phpscript": @"PHP",
        @"powershell": @"PowerShell",
        @"properties": @"INI / Properties",
        @"python": @"Python",
        @"r": @"R",
        @"ruby": @"Ruby",
        @"rust": @"Rust",
        @"sql": @"SQL",
        @"swift": @"Swift",
        @"toml": @"TOML",
        @"typescript": @"TypeScript",
        @"xml": @"XML",
        @"yaml": @"YAML",
    };
    return names[language] ?: language;
}

@end
