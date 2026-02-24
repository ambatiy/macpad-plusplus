cmake_minimum_required(VERSION 3.16)

# ---- Scintilla core sources ----
set(SCINTILLA_SRC_DIR "${CMAKE_SOURCE_DIR}/scintilla/src")
set(SCINTILLA_COCOA_DIR "${CMAKE_SOURCE_DIR}/scintilla/cocoa")

set(SCINTILLA_CORE_SOURCES
    ${SCINTILLA_SRC_DIR}/AutoComplete.cxx
    ${SCINTILLA_SRC_DIR}/CallTip.cxx
    ${SCINTILLA_SRC_DIR}/CaseConvert.cxx
    ${SCINTILLA_SRC_DIR}/CaseFolder.cxx
    ${SCINTILLA_SRC_DIR}/CellBuffer.cxx
    ${SCINTILLA_SRC_DIR}/ChangeHistory.cxx
    ${SCINTILLA_SRC_DIR}/CharacterCategoryMap.cxx
    ${SCINTILLA_SRC_DIR}/CharacterType.cxx
    ${SCINTILLA_SRC_DIR}/CharClassify.cxx
    ${SCINTILLA_SRC_DIR}/ContractionState.cxx
    ${SCINTILLA_SRC_DIR}/DBCS.cxx
    ${SCINTILLA_SRC_DIR}/Decoration.cxx
    ${SCINTILLA_SRC_DIR}/Document.cxx
    ${SCINTILLA_SRC_DIR}/EditModel.cxx
    ${SCINTILLA_SRC_DIR}/Editor.cxx
    ${SCINTILLA_SRC_DIR}/EditView.cxx
    ${SCINTILLA_SRC_DIR}/Geometry.cxx
    ${SCINTILLA_SRC_DIR}/Indicator.cxx
    ${SCINTILLA_SRC_DIR}/KeyMap.cxx
    ${SCINTILLA_SRC_DIR}/LineMarker.cxx
    ${SCINTILLA_SRC_DIR}/MarginView.cxx
    ${SCINTILLA_SRC_DIR}/PerLine.cxx
    ${SCINTILLA_SRC_DIR}/PositionCache.cxx
    ${SCINTILLA_SRC_DIR}/RESearch.cxx
    ${SCINTILLA_SRC_DIR}/RunStyles.cxx
    ${SCINTILLA_SRC_DIR}/ScintillaBase.cxx
    ${SCINTILLA_SRC_DIR}/Selection.cxx
    ${SCINTILLA_SRC_DIR}/Style.cxx
    ${SCINTILLA_SRC_DIR}/UndoHistory.cxx
    ${SCINTILLA_SRC_DIR}/UniConversion.cxx
    ${SCINTILLA_SRC_DIR}/UniqueString.cxx
    ${SCINTILLA_SRC_DIR}/ViewStyle.cxx
    ${SCINTILLA_SRC_DIR}/XPM.cxx
)

set(SCINTILLA_COCOA_SOURCES
    ${SCINTILLA_COCOA_DIR}/InfoBar.mm
    ${SCINTILLA_COCOA_DIR}/PlatCocoa.mm
    ${SCINTILLA_COCOA_DIR}/ScintillaCocoa.mm
    ${SCINTILLA_COCOA_DIR}/ScintillaView.mm
)

# ---- Lexilla sources ----
set(LEXILLA_DIR "${CMAKE_SOURCE_DIR}/lexilla")

set(LEXILLA_LIB_SOURCES
    ${LEXILLA_DIR}/lexlib/Accessor.cxx
    ${LEXILLA_DIR}/lexlib/CharacterCategory.cxx
    ${LEXILLA_DIR}/lexlib/CharacterSet.cxx
    ${LEXILLA_DIR}/lexlib/DefaultLexer.cxx
    ${LEXILLA_DIR}/lexlib/InList.cxx
    ${LEXILLA_DIR}/lexlib/LexAccessor.cxx
    ${LEXILLA_DIR}/lexlib/LexerBase.cxx
    ${LEXILLA_DIR}/lexlib/LexerModule.cxx
    ${LEXILLA_DIR}/lexlib/LexerSimple.cxx
    ${LEXILLA_DIR}/lexlib/PropSetSimple.cxx
    ${LEXILLA_DIR}/lexlib/StyleContext.cxx
    ${LEXILLA_DIR}/lexlib/WordList.cxx
)

# Main Lexilla entry point (registers all lexers)
set(LEXILLA_MAIN_SOURCE ${LEXILLA_DIR}/src/Lexilla.cxx)

# Collect all lexer files
file(GLOB LEXILLA_LEXER_SOURCES "${LEXILLA_DIR}/lexers/*.cxx")

# ---- App sources ----
set(APP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/main.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/AppDelegate.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/MainWindowController.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/MPDocument.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/EditorView.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/SyntaxHighlighter.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/FindReplacePanel.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/StatusBarController.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/PreferencesWindowController.mm
)

# ---- Create macOS app bundle ----
add_executable(MacPadPlusPlus MACOSX_BUNDLE
    ${APP_SOURCES}
    ${SCINTILLA_CORE_SOURCES}
    ${SCINTILLA_COCOA_SOURCES}
    ${LEXILLA_LIB_SOURCES}
    ${LEXILLA_MAIN_SOURCE}
    ${LEXILLA_LEXER_SOURCES}
)

# ---- Include paths ----
target_include_directories(MacPadPlusPlus PRIVATE
    # Our app
    ${CMAKE_CURRENT_SOURCE_DIR}
    # Scintilla
    ${CMAKE_SOURCE_DIR}/scintilla/include
    ${CMAKE_SOURCE_DIR}/scintilla/cocoa
    ${CMAKE_SOURCE_DIR}/scintilla/src
    # Lexilla
    ${CMAKE_SOURCE_DIR}/lexilla/include
    ${CMAKE_SOURCE_DIR}/lexilla/lexlib
    ${CMAKE_SOURCE_DIR}/lexilla/src
    ${CMAKE_SOURCE_DIR}/lexilla/lexers
)

# ---- Compile definitions ----
target_compile_definitions(MacPadPlusPlus PRIVATE
    # Lexilla: link all lexers statically
    LINK_LEXERS
    SCI_LEXER
    # Suppress deprecation warnings for Scintilla legacy API
    NOMINMAX
)

# ---- Compile options ----
target_compile_options(MacPadPlusPlus PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++17 -Wno-deprecated-declarations>
    $<$<COMPILE_LANGUAGE:OBJCXX>:-std=c++17 -Wno-deprecated-declarations>
    # Scintilla Cocoa files use manual memory management in some places
    $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc-exceptions>
)

# Enable ARC for our app sources only
set_source_files_properties(
    ${APP_SOURCES}
    PROPERTIES COMPILE_FLAGS "-fobjc-arc"
)

# Scintilla Cocoa sources — may need -fno-objc-arc depending on version
# Try without ARC first; if build errors occur, add -fno-objc-arc
set_source_files_properties(
    ${SCINTILLA_COCOA_SOURCES}
    PROPERTIES COMPILE_FLAGS "-Wno-deprecated-declarations"
)

# ---- Linker flags ----
target_link_options(MacPadPlusPlus PRIVATE
    "-ObjC"
)

# ---- Frameworks ----
target_link_libraries(MacPadPlusPlus
    "-framework Cocoa"
    "-framework AppKit"
    "-framework Foundation"
    "-framework CoreText"
    "-framework CoreGraphics"
    "-framework CoreFoundation"
    "-framework QuartzCore"
    "-framework CoreServices"
    "-framework Security"
    "-framework UniformTypeIdentifiers"
)

# ---- App bundle properties ----
set_target_properties(MacPadPlusPlus PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Resources/Info.plist"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.macpad.MacPadPlusPlus"
    MACOSX_BUNDLE_BUNDLE_NAME "MacPad++"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
    MACOSX_BUNDLE_MINIMUM_SYSTEM_VERSION "11.0"
    MACOSX_BUNDLE_COPYRIGHT "Copyright © 2024 MacPad++ Contributors. GPL v3."
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.macpad.MacPadPlusPlus"
)

# ---- Install ----
install(TARGETS MacPadPlusPlus
    BUNDLE DESTINATION /Applications
)

message(STATUS "MacPad++ macOS target configured")
message(STATUS "  Scintilla core: ${CMAKE_SOURCE_DIR}/scintilla/src")
message(STATUS "  Scintilla Cocoa: ${CMAKE_SOURCE_DIR}/scintilla/cocoa")
message(STATUS "  Lexilla: ${CMAKE_SOURCE_DIR}/lexilla")
message(STATUS "  Lexer count: ${CMAKE_SOURCE_DIR}/lexilla/lexers/*.cxx")
