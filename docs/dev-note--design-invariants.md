# Dev Note -- Design Invariants

Internal architecture notes for **delphi-forms-parser**

Design invariants are rules that must hold across all components of the system.

They are different from implementation details:
- Implementation details may change as the code evolves.
- Invariants must remain true regardless of refactoring.

If a future design change requires violating an invariant,
the invariant must be revised here _first_ before code changes proceed.

Each invariant states:
- the rule
- why it exists
- what breaks if it is violated

---

## I-1: Text round-trip fidelity

**Rule:** Parsing a canonically-formatted text DFM file into a `TFormFile` AST
and writing it back to text with `TDfmTextWriter` reproduces the original
source byte-for-byte. No character may be added, removed, or altered.

**Canonical formatting** means the layout produced by the Delphi IDE:
- 2-space indentation per nesting level
- CRLF line endings
- Single space around `=` in property assignments
- Single space between `object`/`inherited`/`inline` and the component name
- No trailing whitespace
- No comments (the IDE never emits comments in DFM files)

Hand-edited DFM files that deviate from canonical formatting (different
indentation, extra whitespace, LF-only line endings) will be normalized to
canonical layout on write. The round-trip guarantee applies only to
canonically-formatted input.

**Why it exists:** Migration and refactoring tools need to read a DFM, modify
specific properties or components, and write it back without disturbing
untouched portions of the file. If the writer changes indentation, value
formatting, or line endings on unmodified content, diffs become noisy and
code review is impractical. Since the Delphi IDE always produces canonical
formatting, this covers the overwhelming majority of real-world DFM files.

**What breaks if violated:** A tool that updates a single property and writes
the file back produces a diff touching every line. Round-trip tests in
`TDfmTextWriterTests` and `TGoldenTests` catch this at test time.

**How it is achieved:** The parser stores `RawText` on `TFormValue` for values
where the original text representation matters (hex integers, negative numbers,
string concatenation patterns). The writer uses `RawText` when available,
falling back to canonical formatting only for programmatically constructed ASTs.
Structural whitespace (indentation, line endings, spacing around `=`) is not
preserved in the AST -- the writer always generates canonical layout.

---

## I-2: Binary round-trip fidelity

**Rule:** Reading a binary DFM file (TPF0 format) into a `TFormFile` AST and
writing it back to binary with `TDfmBinaryWriter` reproduces the original
bytes exactly.

**Why it exists:** Binary DFM files from legacy Delphi projects must survive
read-modify-write cycles without silent corruption. If the writer changes
value type tags (e.g., upgrading vaString to vaUTF8String, or collapsing
vaInt32 to vaInt8), the output differs from the input even though the logical
values are identical.

**What breaks if violated:** A migration tool that reads a binary DFM, extracts
metadata, and writes it back produces a different file. Source control shows
spurious changes; in extreme cases, older Delphi versions that depend on
specific value type tags reject the modified file.

**How it is achieved:** The binary reader stores `OriginalValueType` (the raw
value type tag byte) and `ExtendedRawBytes` (the raw 10 bytes for vaExtended)
on `TFormValue`. The binary writer checks `OriginalValueType` first and
re-encodes using the original tag. For programmatically constructed ASTs
where `OriginalValueType = 0`, the writer uses compact defaults (smallest
integer tag, vaDouble for floats, vaUTF8String for strings).

Collection item indices are preserved in `TFormObject.ItemIndex` (default -1).
The writer uses the preserved index when >= 0, falling back to sequential
indices for constructed ASTs.

---

## I-3: Token coverage -- every character in exactly one token

**Rule:** Every character index in the source string belongs to exactly one
token's `Text` field. There are no gaps and no overlaps.

**Why it exists:** A direct consequence of I-4. If a character appears in two
tokens, concatenation doubles it. If it appears in none, concatenation drops
it. The invariant makes the token list a lossless partition of the source.

**What breaks if violated:** The lexer round-trip test (`AssertRoundTrip`)
will fail. Any tool that iterates tokens and tracks position by summing
lengths will desynchronize.

---

## I-4: Token concatenation reproduces source

**Rule:** Concatenating `Token.Text` across every token in the list, in order,
reproduces `Source` exactly. This is the lexer-level analogue of I-1.

**Why it exists:** The lexer is the foundation of the text parsing pipeline.
If the token stream loses information, no amount of downstream logic can
recover it. This guarantee means the lexer is a lossless, reversible
transformation.

**What breaks if violated:** Any consumer that reconstructs source from
tokens (round-trip tests, formatters, diffing tools) will produce corrupted
output. The `TDfmLexerTests.AssertRoundTrip` helper verifies this on every
test run.

---

## I-5: Final token is always dtkEOF with Text = ''

**Rule:** The last element of every token list produced by `TDfmLexer` is
`dtkEOF` with `Text = ''`. There is exactly one `dtkEOF` token and it is
always last.

**Why it exists:** The parser can use a simple sentinel check instead of
bounds-checking on every lookahead. The EOF token has an empty `Text` field,
so it contributes nothing to the round-trip concatenation (I-4).

**What breaks if violated:** The parser's `AtEnd` check or `SkipTrivia` loop
may run past the end of the list. Because the parser accesses
`FTokens[FPos]` in `Current`/`CurrentKind`/`CurrentText`, a missing EOF
sentinel causes an index-out-of-range exception instead of graceful
termination.

---

## I-6: Deterministic tokenization and parsing

**Rule:** The same source string always produces the same token list and the
same AST. There is no context-dependent, random, or order-dependent behavior
in the lexer or parser.

**Why it exists:** Determinism is required for caching, diffing, and parallel
processing. If two runs produce different ASTs for the same input, round-trip
testing is meaningless and build reproducibility is compromised.

**What breaks if violated:** Golden tests become flaky. Caching layers that
key on file content produce stale results.

---

## I-7: No information loss in the AST

**Rule:** The `TFormFile` AST preserves all data needed to reproduce the
original DFM file via the corresponding writer (text or binary).

For text-parsed ASTs:
- `RawText` on `TFormValue` preserves the original text representation of
  values (hex integers like `$FF`, negative numbers like `-12`, string
  concatenation patterns)

For binary-parsed ASTs:
- `OriginalValueType` preserves the binary value type tag
- `ExtendedRawBytes` preserves the raw 80-bit extended float bytes
- `ItemIndex` preserves the collection item index

**Why it exists:** Round-trip fidelity (I-1, I-2) requires the AST to carry
enough information to reproduce the original format. Without these fields,
the writer must guess at formatting, which inevitably differs from the
original.

**What breaks if violated:** Round-trip tests fail. More critically, a tool
that reads a DFM, makes no changes, and writes it back produces a different
file -- defeating the purpose of a lossless parser.

---

## I-8: Binary data `{ hex }` is not a comment

**Rule:** The DFM text lexer treats `{` as the start of a binary data block
(`dtkBinaryData`), never as a comment. This is the fundamental reason the
DFM lexer is a separate unit from `delphi-lexer`.

**Why it exists:** In Delphi source code, `{ }` is a block comment. In DFM
text format, `{ hex }` is a binary data literal. These are incompatible
semantics that cannot be resolved without context-dependent lexing, which
violates I-6.

**What breaks if violated:** Binary data properties (images, blobs, custom
data) are silently consumed as comments and lost. The DFM round-trips with
missing data, and the resulting form is visually or functionally broken.

---

## I-9: Typed collection items preserve class names

**Rule:** The parser detects optional class names on collection items
(`item TToolButton ... end`) using lookahead: if the identifier after `item`
is not followed by `=`, it is treated as a class name and stored in
`TFormObject.ClassName_`. The writer emits `item ClassName` when
`ClassName_` is set, and bare `item` otherwise.

**Why it exists:** Some DFM constructs use typed collection items where the
class name is meaningful (toolbar buttons, action items). Dropping the class
name would alter the form's behavior when loaded by the Delphi streaming
system.

**What breaks if violated:** Typed collection items lose their class name on
round-trip. The Delphi IDE may interpret the items differently when loading
the modified form.

**Grammar note:** This detection uses the same heuristic as Delphi's own
`ObjectTextToResource`: if the first identifier after `item` is followed by
`=`, it is a property name; otherwise it is a class name. This is ambiguous
for malformed input but correct for all well-formed DFM files.

---

## I-10: Parser tolerates truncated input without access violations

**Rule:** The parser's `Current`, `CurrentKind`, `CurrentText`, and `Expect`
methods raise a descriptive `Exception` with the message "Unexpected end of
DFM input" when `FPos >= FTokens.Count`. They never produce an
index-out-of-range access violation.

**Why it exists:** Migration tools processing thousands of legacy DFM files
will encounter malformed or truncated files. A crash with an access violation
is unhelpful; a descriptive exception allows the tool to log the error and
continue to the next file.

**What breaks if violated:** A truncated DFM file (missing `end`, incomplete
property, etc.) crashes the process instead of raising a catchable exception.
Batch migration workflows abort on the first malformed file.

---

## Type summaries

### TDfmToken

`TDfmToken` is defined in `Delphi.Forms.Token.pas`:

| Field | Type | Description |
|---|---|---|
| `Kind` | `TDfmTokenKind` | Token classification (21 kinds) |
| `Text` | `string` | Characters as they appear in source; concatenation is lossless (I-4) |
| `Line` | `Integer` | 1-based line number of the first character |
| `Col` | `Integer` | 1-based column number of the first character |
| `StartOffset` | `Integer` | 0-based absolute character index into source |

### TFormValue

`TFormValue` is defined in `Delphi.Forms.Types.pas`:

| Field | Type | Description |
|---|---|---|
| `Kind` | `TFormValueKind` | Value classification (9 kinds) |
| `IntValue` | `Int64` | Integer value (fvInteger) |
| `FloatValue` | `Extended` | Float value (fvFloat) |
| `StringValue` | `string` | Decoded string content (fvString) |
| `BoolValue` | `Boolean` | Boolean value (fvBoolean) |
| `IdentValue` | `string` | Identifier text, possibly dotted (fvIdentifier) |
| `SetItems` | `TArray<string>` | Set member names (fvSet) |
| `BinaryData` | `TBytes` | Decoded binary bytes (fvBinary) |
| `ListItems` | `TFormValueList` | Owned child values (fvList) |
| `CollectionItems` | `TFormObjectList` | Owned collection item objects (fvCollection) |
| `RawText` | `string` | Original text representation for round-trip (I-7) |
| `OriginalValueType` | `Byte` | Binary value type tag, 0 if not from binary (I-2) |
| `ExtendedRawBytes` | `TBytes` | Raw 10 bytes for vaExtended round-trip (I-2) |

### TFormObject

`TFormObject` is defined in `Delphi.Forms.Types.pas`:

| Field | Type | Description |
|---|---|---|
| `ObjectKind` | `TObjectKind` | okObject, okInherited, or okInline |
| `Name` | `string` | Component name |
| `ClassName_` | `string` | Component class name (trailing underscore avoids Delphi reserved word) |
| `ItemIndex` | `Int64` | Binary collection item index, -1 if not set (I-2) |
| `Properties` | `TFormPropertyList` | Owned property list |
| `Children` | `TFormObjectList` | Owned child object list |