# MacPad++

A native macOS code editor inspired by Notepad++, built with AppKit/Cocoa,
Scintilla, and Lexilla.

---

## Features

| Feature | Details |
|---|---|
| **Multi-tab editing** | Notepad++-style custom tab bar; unlimited tabs |
| **Syntax highlighting** | 33+ languages via Lexilla (`CreateLexer`) with per-token colours |
| **Color themes** | Default (light), Dark, Monokai, Solarized Light, Solarized Dark |
| **Find Results panel** | Docked bottom panel shows every matching line; click to navigate |
| **Find & Replace** | Floating panel with Match Case, Whole Word, Wrap Around; Find All |
| **Code folding** | Click fold-margin arrows or use View → Fold All / Unfold All |
| **Brace matching** | Auto-highlights matched `()`, `[]`, `{}` pairs |
| **Auto-indent** | Preserves indentation on new lines |
| **Line numbers** | Toggle via View menu |
| **Status bar** | Line/column, selection length, language, encoding, line ending, total lines |
| **Word wrap** | Toggle per-document via View → Word Wrap |
| **Whitespace / EOL display** | View → Show Whitespace / Show Indent Guides |
| **Zoom** | Cmd `+` / `-` / `0` |
| **Text operations** | Move lines up/down, duplicate line, delete line, UPPERCASE/lowercase, toggle comment |
| **File operations** | Open, Save, Save As, Save All, Reload from Disk, recent files |
| **Encoding & line endings** | Detect and convert UTF-8 / UTF-8 BOM / UTF-16; LF / CRLF / CR |
| **Preferences** | Font family, size, tab width, theme, editor toggles |
| **App icon** | Custom MacPad++ icon (dark-blue background, paper document, green `++`) |
| **macOS integration** | Retina-ready, dark mode, Services, drag-and-drop file open |

---

## Supported Languages (syntax highlighting)

Bash, Batch, CMake, CoffeeScript, C/C++, CSS, Diff, HTML, Java, JavaScript,
JSON, LaTeX, Lua, Makefile, Markdown, Pascal, Perl, PHP, PowerShell,
Properties/INI, Python, R, Ruby, Rust, SQL, Swift, TOML, TypeScript, XML,
YAML — plus 100+ additional languages via Lexilla lexers (highlighting
styles use default colours for those).

---

## Build

### Requirements

- macOS 11.0 or later (arm64 or x86_64)
- Xcode Command Line Tools (`xcode-select --install`)
  - Provides: `clang++`, `swift`, `sips`, `iconutil`

### Steps

```bash
# Clone the repository
git clone https://github.com/ambatiy/macpad-plus-plus.git
cd macpad-plus-plus

# Build (release)
make

# Build (debug symbols)
make DEBUG=1

# Run
make run

# Or open directly
open build/MacPad++.app
```

The first build also generates the `AppIcon.icns` automatically via `make_icon.swift`.

### Clean

```bash
make clean
```

---

## Project Structure

```
macpad-plus-plus/
├── MacPadPlusPlus/           # Native macOS app (Objective-C++)
│   ├── main.mm               # Entry point
│   ├── AppDelegate.h/.mm     # App lifecycle, menu bar, recent files
│   ├── MainWindowController.h/.mm  # Window, tabs, split view, delegates
│   ├── EditorView.h/.mm      # Wraps ScintillaView; all editor operations
│   ├── MPDocument.h/.mm      # Document model (file I/O, encoding, lang)
│   ├── SyntaxHighlighter.h/.mm     # Lexilla integration + colour themes
│   ├── FindReplacePanel.h/.mm      # Floating Find / Replace panel
│   ├── FindResultsController.h/.mm # Docked Find Results panel (bottom)
│   ├── StatusBarController.h/.mm   # Bottom status bar
│   ├── PreferencesWindowController.h/.mm  # Preferences window
│   └── Resources/
│       └── Info.plist
├── scintilla/                # Scintilla text-editing component (Cocoa backend)
├── lexilla/                  # Lexilla syntax-highlighting library (127 lexers)
│   └── lexers/LexUserStub.cxx  # macOS stub replacing Windows-only LexUser.cxx
├── Makefile                  # Primary build system
├── make_icon.swift           # Swift script that generates AppIcon.icns
└── build_mac.sh              # Build helper script
```

---

## Using Find Results

1. Open **Search → Find…** (`Cmd+F`) to open the Find panel.
2. Type your search term and click **Find All** (or use **Search → Find All in Document**, `Cmd+Shift+F`).
3. A **Find Results** panel slides open at the bottom of the window showing every matching line with the search term highlighted in orange.
4. Click any row to jump directly to that line in the editor.
5. Use arrow keys to move through results — each line is selected in the editor as you navigate.
6. Click **✕** in the panel header to close the results panel.

The panel is resizable by dragging the divider between the editor and the results panel.

---

## Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| New tab | `Cmd+N` |
| Open file | `Cmd+O` |
| Save | `Cmd+S` |
| Save As | `Cmd+Shift+S` |
| Close tab | `Cmd+W` |
| Find | `Cmd+F` |
| Find & Replace | `Cmd+H` |
| Find All in Document | `Cmd+Shift+F` |
| Find Next | `Cmd+G` |
| Find Previous | `Cmd+Shift+G` |
| Go to Line | `Cmd+Shift+L` |
| Next tab | `Cmd+]` |
| Previous tab | `Cmd+[` |
| Duplicate line | `Cmd+Shift+D` |
| Delete line | `Cmd+Shift+K` |
| Toggle comment | `Cmd+/` |
| UPPERCASE | `Cmd+Shift+U` |
| lowercase | `Cmd+Shift+L` |
| Zoom in | `Cmd++` |
| Zoom out | `Cmd+-` |
| Reset zoom | `Cmd+0` |
| Preferences | `Cmd+,` |

---

## Architecture Notes

- **Scintilla Cocoa backend** — `scintilla/cocoa/` provides `ScintillaView`,
  `ScintillaCocoa`, `PlatCocoa`, and `InfoBar`. Compiled with ARC (`-fobjc-arc`)
  because `ScintillaCocoa.h` uses `__weak` references.
- **Lexilla static linking** — built with `-DLINK_LEXERS` so all 127 lexers
  are compiled in. `LexUser.cxx` (Windows-only) is excluded and replaced by
  `lexilla/lexers/LexUserStub.cxx` which provides the required `lmUserDefine`
  symbol with `extern const` linkage.
- **Separate include paths** — Scintilla/Lexilla sources use `SCI_INCLUDES`
  (no `MacPadPlusPlus/` path) to prevent `Document.h` header name conflicts.
  App sources use the full `INCLUDES` set.
- **No cmake or Xcode required** — the Makefile invokes `clang++` directly.
  The icon pipeline uses `swift`, `sips`, and `iconutil` (all part of CLT).

---

## License

MacPad++ application code: **GPL v3**
Scintilla: **HPND** (Historical Permission Notice and Disclaimer)
Lexilla: **HPND**

This project is a macOS port/reimplementation built on top of the Scintilla
and Lexilla libraries from the Notepad++ ecosystem.
