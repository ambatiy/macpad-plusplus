// LexUserStub.cxx - macOS stub for LexUser (which requires Windows APIs)
// This provides a no-op lmUserDefine so Lexilla links on macOS.

#include <cstdint>
#include "ILexer.h"
#include "LexerModule.h"

using namespace Lexilla;

static Scintilla::ILexer5 *UserLexerFactory() { return nullptr; }

// SCLEX_USER = 98  — extern gives external linkage (C++ const defaults to internal)
extern const LexerModule lmUserDefine(98, UserLexerFactory, "user");

