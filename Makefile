# MacPad++ macOS Makefile
# Requires: Apple Clang (Xcode Command Line Tools)
# Usage: make [debug] [clean] [run]

PROJ_ROOT   := $(shell pwd)
APP_NAME    := MacPad++
BINARY_NAME := MacPadPlusPlus
BUILD_DIR   := $(PROJ_ROOT)/build/obj
APP_DIR     := $(PROJ_ROOT)/build/$(APP_NAME).app
APP_MACOS   := $(APP_DIR)/Contents/MacOS
APP_RES     := $(APP_DIR)/Contents/Resources
DIST_DIR    := $(PROJ_ROOT)/build/dist

# ---- Toolchain ----
CXX      := clang++
CC       := clang
LIBTOOL  := libtool
INSTALL_NAME_TOOL := install_name_tool

# SDK
SDK_PATH := $(shell xcrun --show-sdk-path)

# ---- Build type ----
ifdef DEBUG
    OPT_FLAGS  := -O0 -g -DDEBUG
else
    OPT_FLAGS  := -O2 -DNDEBUG
endif

# ---- Base flags ----
MACOS_MIN    := 11.0
ARCH         := $(shell uname -m)

COMMON_FLAGS := \
    -arch $(ARCH) \
    -isysroot $(SDK_PATH) \
    -mmacosx-version-min=$(MACOS_MIN) \
    $(OPT_FLAGS) \
    -DLINK_LEXERS \
    -DSCI_LEXER \
    -Wno-deprecated-declarations \
    -Wno-unused-parameter \
    -Wno-sign-compare \
    -Wno-missing-field-initializers

CXX_STD      := -std=c++17
OBJCXX_STD   := -std=c++17

# ---- Include paths ----
# Third-party includes (Scintilla + Lexilla) - NO MacPadPlusPlus here to avoid header name conflicts
SCI_INCLUDES := \
    -I$(PROJ_ROOT)/scintilla/include \
    -I$(PROJ_ROOT)/scintilla/cocoa \
    -I$(PROJ_ROOT)/scintilla/src \
    -I$(PROJ_ROOT)/lexilla/include \
    -I$(PROJ_ROOT)/lexilla/lexlib \
    -I$(PROJ_ROOT)/lexilla/src \
    -I$(PROJ_ROOT)/lexilla/lexers

# App includes (our own sources + all Scintilla/Lexilla headers)
INCLUDES := \
    $(SCI_INCLUDES) \
    -I$(PROJ_ROOT)/MacPadPlusPlus

# ---- Linker flags ----
LDFLAGS := \
    -arch $(ARCH) \
    -isysroot $(SDK_PATH) \
    -mmacosx-version-min=$(MACOS_MIN) \
    -ObjC \
    -framework Cocoa \
    -framework AppKit \
    -framework Foundation \
    -framework CoreText \
    -framework CoreGraphics \
    -framework CoreFoundation \
    -framework QuartzCore \
    -framework CoreServices

# ---- Scintilla core sources (.cxx) ----
SCI_SRC_DIR := $(PROJ_ROOT)/scintilla/src
SCI_CORE_SRCS := \
    $(SCI_SRC_DIR)/AutoComplete.cxx \
    $(SCI_SRC_DIR)/CallTip.cxx \
    $(SCI_SRC_DIR)/CaseConvert.cxx \
    $(SCI_SRC_DIR)/CaseFolder.cxx \
    $(SCI_SRC_DIR)/CellBuffer.cxx \
    $(SCI_SRC_DIR)/ChangeHistory.cxx \
    $(SCI_SRC_DIR)/CharacterCategoryMap.cxx \
    $(SCI_SRC_DIR)/CharacterType.cxx \
    $(SCI_SRC_DIR)/CharClassify.cxx \
    $(SCI_SRC_DIR)/ContractionState.cxx \
    $(SCI_SRC_DIR)/DBCS.cxx \
    $(SCI_SRC_DIR)/Decoration.cxx \
    $(SCI_SRC_DIR)/Document.cxx \
    $(SCI_SRC_DIR)/EditModel.cxx \
    $(SCI_SRC_DIR)/Editor.cxx \
    $(SCI_SRC_DIR)/EditView.cxx \
    $(SCI_SRC_DIR)/Geometry.cxx \
    $(SCI_SRC_DIR)/Indicator.cxx \
    $(SCI_SRC_DIR)/KeyMap.cxx \
    $(SCI_SRC_DIR)/LineMarker.cxx \
    $(SCI_SRC_DIR)/MarginView.cxx \
    $(SCI_SRC_DIR)/PerLine.cxx \
    $(SCI_SRC_DIR)/PositionCache.cxx \
    $(SCI_SRC_DIR)/RESearch.cxx \
    $(SCI_SRC_DIR)/RunStyles.cxx \
    $(SCI_SRC_DIR)/ScintillaBase.cxx \
    $(SCI_SRC_DIR)/Selection.cxx \
    $(SCI_SRC_DIR)/Style.cxx \
    $(SCI_SRC_DIR)/UndoHistory.cxx \
    $(SCI_SRC_DIR)/UniConversion.cxx \
    $(SCI_SRC_DIR)/UniqueString.cxx \
    $(SCI_SRC_DIR)/ViewStyle.cxx \
    $(SCI_SRC_DIR)/XPM.cxx

# ---- Scintilla Cocoa sources (.mm) ----
SCI_COCOA_DIR := $(PROJ_ROOT)/scintilla/cocoa
SCI_COCOA_SRCS := \
    $(SCI_COCOA_DIR)/InfoBar.mm \
    $(SCI_COCOA_DIR)/PlatCocoa.mm \
    $(SCI_COCOA_DIR)/ScintillaCocoa.mm \
    $(SCI_COCOA_DIR)/ScintillaView.mm

# ---- Lexilla sources (.cxx) ----
LEX_DIR    := $(PROJ_ROOT)/lexilla
LEX_LIB_SRCS := \
    $(LEX_DIR)/lexlib/Accessor.cxx \
    $(LEX_DIR)/lexlib/CharacterCategory.cxx \
    $(LEX_DIR)/lexlib/CharacterSet.cxx \
    $(LEX_DIR)/lexlib/DefaultLexer.cxx \
    $(LEX_DIR)/lexlib/InList.cxx \
    $(LEX_DIR)/lexlib/LexAccessor.cxx \
    $(LEX_DIR)/lexlib/LexerBase.cxx \
    $(LEX_DIR)/lexlib/LexerModule.cxx \
    $(LEX_DIR)/lexlib/LexerSimple.cxx \
    $(LEX_DIR)/lexlib/PropSetSimple.cxx \
    $(LEX_DIR)/lexlib/StyleContext.cxx \
    $(LEX_DIR)/lexlib/WordList.cxx

LEX_MAIN_SRC := $(LEX_DIR)/src/Lexilla.cxx
LEX_LEXER_SRCS_ALL := $(wildcard $(LEX_DIR)/lexers/*.cxx)
# Exclude Windows-only LexUser.cxx, replace with macOS stub
LEX_LEXER_SRCS := $(filter-out $(LEX_DIR)/lexers/LexUser.cxx, $(LEX_LEXER_SRCS_ALL))

# ---- App sources (.mm) ----
APP_SRC_DIR := $(PROJ_ROOT)/MacPadPlusPlus
APP_SRCS := \
    $(APP_SRC_DIR)/main.mm \
    $(APP_SRC_DIR)/AppDelegate.mm \
    $(APP_SRC_DIR)/MainWindowController.mm \
    $(APP_SRC_DIR)/MPDocument.mm \
    $(APP_SRC_DIR)/EditorView.mm \
    $(APP_SRC_DIR)/SyntaxHighlighter.mm \
    $(APP_SRC_DIR)/FindReplacePanel.mm \
    $(APP_SRC_DIR)/StatusBarController.mm \
    $(APP_SRC_DIR)/PreferencesWindowController.mm

# ---- Object files ----
SCI_CORE_OBJS  := $(patsubst $(PROJ_ROOT)/%.cxx,$(BUILD_DIR)/%.o,$(SCI_CORE_SRCS))
SCI_COCOA_OBJS := $(patsubst $(PROJ_ROOT)/%.mm,$(BUILD_DIR)/%.o,$(SCI_COCOA_SRCS))
LEX_LIB_OBJS   := $(patsubst $(PROJ_ROOT)/%.cxx,$(BUILD_DIR)/%.o,$(LEX_LIB_SRCS))
LEX_MAIN_OBJ   := $(patsubst $(PROJ_ROOT)/%.cxx,$(BUILD_DIR)/%.o,$(LEX_MAIN_SRC))
LEX_LEXER_OBJS := $(patsubst $(PROJ_ROOT)/%.cxx,$(BUILD_DIR)/%.o,$(LEX_LEXER_SRCS))
APP_OBJS       := $(patsubst $(PROJ_ROOT)/%.mm,$(BUILD_DIR)/%.o,$(APP_SRCS))

ALL_OBJS := $(SCI_CORE_OBJS) $(SCI_COCOA_OBJS) $(LEX_LIB_OBJS) $(LEX_MAIN_OBJ) $(LEX_LEXER_OBJS) $(APP_OBJS)

# ---- Default target ----
.PHONY: all clean run install info

all: $(APP_DIR)/Contents/MacOS/$(BINARY_NAME)
	@echo ""
	@echo "✓ Build successful!"
	@echo "  App: $(APP_DIR)"
	@echo ""
	@echo "  Run with:  make run"
	@echo "  Or:        open '$(APP_DIR)'"

# ---- Link ----
$(APP_DIR)/Contents/MacOS/$(BINARY_NAME): $(ALL_OBJS) | bundle-structure
	@echo "Linking $(BINARY_NAME)..."
	$(CXX) $(ALL_OBJS) $(LDFLAGS) -o $@
	@echo "Linked: $@"

# ---- App bundle structure ----
.PHONY: bundle-structure
bundle-structure:
	@mkdir -p $(APP_MACOS) $(APP_RES)
	@cp $(APP_SRC_DIR)/Resources/Info.plist $(APP_DIR)/Contents/Info.plist

# ---- Compile rules ----

# Scintilla core .cxx -> .o (no ARC, use SCI_INCLUDES only to avoid our Document.h conflict)
$(BUILD_DIR)/scintilla/src/%.o: $(PROJ_ROOT)/scintilla/src/%.cxx
	@mkdir -p $(dir $@)
	$(CXX) $(CXX_STD) $(COMMON_FLAGS) $(SCI_INCLUDES) -c $< -o $@

# Scintilla Cocoa .mm -> .o (needs ARC for __weak support)
$(BUILD_DIR)/scintilla/cocoa/%.o: $(PROJ_ROOT)/scintilla/cocoa/%.mm
	@mkdir -p $(dir $@)
	$(CXX) $(OBJCXX_STD) $(COMMON_FLAGS) $(SCI_INCLUDES) -fobjc-arc -c $< -o $@

# Lexilla lib .cxx -> .o
$(BUILD_DIR)/lexilla/lexlib/%.o: $(PROJ_ROOT)/lexilla/lexlib/%.cxx
	@mkdir -p $(dir $@)
	$(CXX) $(CXX_STD) $(COMMON_FLAGS) $(SCI_INCLUDES) -c $< -o $@

# Lexilla main .cxx -> .o
$(BUILD_DIR)/lexilla/src/%.o: $(PROJ_ROOT)/lexilla/src/%.cxx
	@mkdir -p $(dir $@)
	$(CXX) $(CXX_STD) $(COMMON_FLAGS) $(SCI_INCLUDES) -c $< -o $@

# Lexilla lexers .cxx -> .o
$(BUILD_DIR)/lexilla/lexers/%.o: $(PROJ_ROOT)/lexilla/lexers/%.cxx
	@mkdir -p $(dir $@)
	$(CXX) $(CXX_STD) $(COMMON_FLAGS) $(SCI_INCLUDES) -Wno-unused-variable -c $< -o $@

# App sources .mm -> .o (with ARC + all includes)
$(BUILD_DIR)/MacPadPlusPlus/%.o: $(PROJ_ROOT)/MacPadPlusPlus/%.mm
	@mkdir -p $(dir $@)
	$(CXX) $(OBJCXX_STD) $(COMMON_FLAGS) $(INCLUDES) -fobjc-arc -c $< -o $@

# ---- Clean ----
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(PROJ_ROOT)/build
	@echo "Clean complete."

# ---- Run ----
run: all
	@echo "Launching MacPad++..."
	open "$(APP_DIR)"

# ---- Install ----
install: all
	@echo "Installing to /Applications..."
	cp -r "$(APP_DIR)" /Applications/
	@echo "Installed: /Applications/$(APP_NAME).app"

# ---- Info ----
info:
	@echo "MacPad++ Build Information"
	@echo "=========================="
	@echo "Project root:  $(PROJ_ROOT)"
	@echo "Build dir:     $(BUILD_DIR)"
	@echo "App bundle:    $(APP_DIR)"
	@echo "Architecture:  $(ARCH)"
	@echo "SDK:           $(SDK_PATH)"
	@echo "macOS min:     $(MACOS_MIN)"
	@echo ""
	@echo "Source counts:"
	@echo "  Scintilla core:   $(words $(SCI_CORE_SRCS)) files"
	@echo "  Scintilla Cocoa:  $(words $(SCI_COCOA_SRCS)) files"
	@echo "  Lexilla lib:      $(words $(LEX_LIB_SRCS)) files"
	@echo "  Lexilla lexers:   $(words $(LEX_LEXER_SRCS)) files"
	@echo "  App sources:      $(words $(APP_SRCS)) files"
	@echo "  Total:            $(words $(ALL_OBJS)) object files"

# ---- Dependencies ----
# Ensure object dirs exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
