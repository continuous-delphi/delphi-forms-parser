# AST Overview

## What It Is

The AST (Abstract Syntax Tree) represents the structured content of Delphi
form files (.dfm/.fmx).  Where the token stream preserves every character
for text round-trip fidelity, the AST drops syntactic noise (delimiters,
whitespace, keywords) and exposes typed fields (names, values, children)
directly on concrete node classes.

The DFM AST is intentionally flat compared to a source-code AST.  DFM files
describe a component tree with properties -- there are no statements,
expressions, or scopes.  The entire AST is four classes deep at most.

```
Text DFM  --> TDfmLexer --> TDfmTokenList --> TDfmParser --> TFormFile (AST)
Binary DFM --> TDfmBinaryReader --------------------------------^
                                                                |
TFormFile --> TDfmTextWriter --> text DFM                        |
TFormFile --> TDfmBinaryWriter --> binary DFM                    |
```


## Units

| Unit | Purpose |
|------|---------|
| `Delphi.Forms.Types` | AST node classes: `TFormFile`, `TFormObject`, `TFormProperty`, `TFormValue` |
| `Delphi.Forms.Token` | `TDfmTokenKind` enum (21 kinds), `TDfmToken` record |
| `Delphi.Forms.Lexer` | `TDfmLexer.Tokenize` -- text DFM source to token list |
| `Delphi.Forms.Parser` | `TDfmParser.Parse` / `ParseWithDiagnostics` -- tokens to AST |
| `Delphi.Forms.TextWriter` | `TDfmTextWriter.Write` -- AST to text DFM |
| `Delphi.Forms.BinaryReader` | `TDfmBinaryReader.ReadFromBytes/Stream/File` -- TPF0 binary to AST |
| `Delphi.Forms.BinaryWriter` | `TDfmBinaryWriter.WriteToBytes/Stream/File` -- AST to TPF0 binary |
| `Delphi.Forms.Diagnostics` | `TFormDiagnostic`, `TParseResult`, diagnostic code constants |
| `Delphi.Forms` | `TDelphiFormsParser` facade with format auto-detection and encoding overloads |
| `Delphi.Forms.Info` | Version constant (auto-incremented by pre-commit hook) |


## Node Hierarchy

The AST uses a minimal four-class hierarchy.  There is no abstract base
node -- each class is concrete and directly instantiable.

```
TFormFile                        (root: one per form file)
  |-- Root: TFormObject          (top-level component)
  |
TFormObject                      (a component instance)
  |-- ObjectKind: TObjectKind    (okObject, okInherited, okInline)
  |-- Name: string               (component name, e.g. 'Button1')
  |-- ClassName_: string         (component class, e.g. 'TButton')
  |-- ItemIndex: Int64           (collection item index; -1 = not set)
  |-- Parent: TFormObject        (non-owning back-reference)
  |-- Properties: TFormPropertyList
  |-- Children: TFormObjectList
  |-- SourceStart / SourceEnd    (character offsets; -1 for binary input)
  |
TFormProperty                    (a named property assignment)
  |-- Name: string               (dotted name, e.g. 'Font.Color')
  |-- Value: TFormValue
  |-- SourceStart / SourceEnd
  |
TFormValue                       (a property value of any kind)
  |-- Kind: TFormValueKind       (discriminant for which field to read)
  |-- IntValue: Int64            (fvInteger)
  |-- FloatValue: Extended       (fvFloat)
  |-- StringValue: string        (fvString)
  |-- BoolValue: Boolean         (fvBoolean)
  |-- IdentValue: string         (fvIdentifier -- enum values, nil)
  |-- SetItems: TArray<string>   (fvSet)
  |-- BinaryData: TBytes         (fvBinary)
  |-- ListItems: TFormValueList  (fvList -- ordered values)
  |-- CollectionItems: TFormObjectList  (fvCollection -- item objects)
  |-- RawText: string            (original text for round-trip fidelity)
  |-- OriginalValueType: Byte    (binary tag preserved for round-trip)
  |-- ExtendedRawBytes: TBytes   (raw 10-byte Extended for binary round-trip)
  |-- SourceStart / SourceEnd
```


## TFormValueKind

The `Kind` field on `TFormValue` determines which data field holds the
value.  Each kind maps to exactly one field:

| Kind | Data field | DFM example |
|------|------------|-------------|
| `fvInteger` | `IntValue: Int64` | `Left = 42`, `Tag = $FF` |
| `fvFloat` | `FloatValue: Extended` | `Width = 3.14`, `Scale = 1.5E2` |
| `fvString` | `StringValue: string` | `Caption = 'Hello'`, `Text = 'It''s'` |
| `fvBoolean` | `BoolValue: Boolean` | `Visible = True` |
| `fvIdentifier` | `IdentValue: string` | `Align = alClient`, `Cursor = crDefault` |
| `fvSet` | `SetItems: TArray<string>` | `Anchors = [akLeft, akTop]` |
| `fvBinary` | `BinaryData: TBytes` | `{4F6E...}` (hex-encoded binary) |
| `fvList` | `ListItems: TFormValueList` | `(item1 item2 ...)` |
| `fvCollection` | `CollectionItems: TFormObjectList` | `<item ... end>` |


## Text Parsing Pipeline

### Lexer

`TDfmLexer.Tokenize(Source)` scans the DFM text into a flat `TDfmTokenList`.

The DFM lexer is intentionally separate from the Delphi source lexer
(`delphi-lexer`) because `{ hex }` in DFM is binary data, not a comment.
This is a fundamental incompatibility that cannot be resolved without
context-dependent lexing.

21 token kinds cover the full DFM text grammar:

| Category | Token kinds |
|----------|-------------|
| Values | `dtkIdentifier`, `dtkInteger`, `dtkFloat`, `dtkString`, `dtkCharLiteral`, `dtkBinaryData` |
| Punctuation | `dtkEquals`, `dtkColon`, `dtkDot`, `dtkComma`, `dtkPlus`, `dtkMinus` |
| Brackets | `dtkLBracket`, `dtkRBracket`, `dtkLParen`, `dtkRParen`, `dtkLAngle`, `dtkRAngle` |
| Trivia | `dtkWhitespace`, `dtkEOL`, `dtkEOF` |

Each `TDfmToken` records `Kind`, `Text`, `Line`, `Col`, and `StartOffset`.
Token concatenation reproduces the original source exactly.

### Parser

`TDfmParser.Parse(Source)` tokenizes, skips trivia, and builds the AST
via recursive descent.  The grammar is:

```
FormFile    = Object
Object      = ('object' | 'inherited' | 'inline') Name ':' ClassName
              Property* Object* 'end'
Property    = DottedName '=' Value
DottedName  = Identifier ('.' Identifier)*
Value       = Integer | Float | '-' (Integer | Float)
            | String ('+' String)*
            | 'True' | 'False'
            | Identifier ('.' Identifier)*
            | '[' Identifier (',' Identifier)* ']'
            | '(' Value* ')'
            | '<' ('item' [ClassName] Property* 'end')* '>'
            | '{' HexData '}'
```

String values support concatenation (`'Hello' + #13#10 + 'World'`) and
character literals (`#13`, `#$0D`).  The parser merges these into a single
`fvString` value with the decoded string in `StringValue` and the original
segments in `RawText`.

Collection items (`<item...end>`) have a grammar ambiguity: the identifier
after `item` could be a class name or a property name.  The parser uses
the same heuristic as Delphi's `ObjectTextToResource`: if the identifier
is followed by `=`, it is a property; otherwise it is a class name.


## Binary Format (TPF0)

### Signature

Binary DFM files start with either `$FF` + `TPF0` (5 bytes, standard) or
bare `TPF0` (4 bytes, legacy).  `TDelphiFormsParser.IsBinaryDfm` checks
both variants.

### Object encoding

```
Object = ClassNameLenByte ClassName(N bytes) NameShortStr
         Property* $00  ChildObject* $00

ClassNameLenByte:
  Low nibble  = class name length (0..15)
  High nibble = flags: $10 = inherited, $20 = inline, $00 = object
```

### Value type tags

Each property value is prefixed by a one-byte type tag:

| Tag | Const | Type | Payload |
|-----|-------|------|---------|
| 1 | `vaList` | List | Values until `$00` sentinel |
| 2 | `vaInt8` | Int8 | 1 byte signed |
| 3 | `vaInt16` | Int16 | 2 bytes LE signed |
| 4 | `vaInt32` | Int32 | 4 bytes LE signed |
| 5 | `vaExtended` | Extended | 10 bytes (80-bit float) |
| 6 | `vaString` | ShortString | Length byte + ANSI bytes |
| 7 | `vaIdent` | Identifier | Length byte + ANSI bytes |
| 8 | `vaFalse` | False | No payload |
| 9 | `vaTrue` | True | No payload |
| 10 | `vaBinary` | Binary | 4-byte length + raw bytes |
| 11 | `vaSet` | Set | ShortStrings until empty string |
| 12 | `vaLString` | LString | 4-byte length + ANSI bytes |
| 13 | `vaNil` | Nil | No payload |
| 14 | `vaCollection` | Collection | Items until `$00` sentinel |
| 15 | `vaSingle` | Single | 4 bytes IEEE 754 |
| 16 | `vaDouble` | Double | 8 bytes IEEE 754 |
| 17 | `vaCurrency` | Currency | 8 bytes (Int64 * 0.0001) |
| 18 | `vaDate` | Date | 8 bytes (TDateTime as Double) |
| 19 | `vaWString` | WString | 4-byte char count + UTF-16LE bytes |
| 20 | `vaInt64` | Int64 | 8 bytes LE signed |
| 21 | `vaUTF8String` | UTF8String | 4-byte length + UTF-8 bytes |
| 22 | `vaUString` | UString | 4-byte char count + UTF-16LE bytes |

### Termination

- Properties end with a zero-length property name (`$00` byte).
- Children end with a zero-length class name (`$00` byte).
- Lists and collections end with a `$00` sentinel byte.
- Sets end with an empty short string (`$00` byte).

The binary reader requires a seekable stream (uses `Position`-based
peek-and-rewind for list, collection, and child termination checks).


## Binary Round-Trip Preservation

Two fields on `TFormValue` exist solely to preserve binary fidelity:

**`OriginalValueType: Byte`** -- The binary reader stores the exact value
type tag read from the stream.  Without this, the writer would choose the
compact default (e.g. `vaDouble` for all floats, `vaUTF8String` for all
strings), producing semantically equivalent but byte-different output.  When
`OriginalValueType` is set, the writer re-encodes with the original tag.

**`ExtendedRawBytes: TBytes`** -- On Win64, `Extended = Double` (8 bytes),
so reading a 10-byte `vaExtended` value and converting to `Extended` loses
2 bytes of precision.  The reader preserves the raw 10 bytes so the writer
can reproduce the original encoding exactly.

### Writer tag selection

| Value kind | OriginalValueType set | OriginalValueType not set |
|------------|----------------------|--------------------------|
| Integer | Write with original tag (`vaInt8`/`vaInt16`/`vaInt32`/`vaInt64`) | Choose smallest tag that fits |
| Float | Write with original tag (`vaSingle`/`vaDouble`/`vaExtended`/`vaCurrency`/`vaDate`) | Default to `vaDouble` |
| String | Write with original tag (`vaString`/`vaLString`/`vaWString`/`vaUTF8String`/`vaUString`) | Default to `vaUTF8String` |
| Boolean | Always `vaTrue`/`vaFalse` (single byte, no variation) | Same |
| Identifier | `vaNil` writes `$0D`; others write `vaIdent` + short string | Same |


## Text Round-Trip Preservation

The `RawText` field on `TFormValue` stores the original text representation
for values where canonical formatting would differ from the source:

- **Integers**: hex (`$FF`) vs decimal (`255`)
- **Floats**: scientific notation (`1.5E2`) vs fixed (`150.0`)
- **Strings**: concatenation segments (`'A' + #13 + 'B'`)
- **Identifiers**: dotted names (`alClient`)
- **Binary data**: original hex layout with line wrapping

The text writer checks `RawText` first and falls back to computed formatting
only when it is empty (e.g. for values created programmatically).


## Diagnostics

`Delphi.Forms.Diagnostics` provides structured error reporting via
`ParseWithDiagnostics` / `ReadFromBytesWithDiagnostics`.

### TFormDiagnostic

```
TFormDiagnostic = record
  Severity: TFormDiagnosticSeverity  (dsError, dsWarning, dsInfo)
  Line: Integer                      (1-based; 0 for binary input)
  Col: Integer                       (1-based; 0 for binary input)
  Message: string
  Code: string                       (DFM001..DFM008)
end;
```

### Diagnostic codes

| Code | Constant | Meaning |
|------|----------|---------|
| DFM001 | `DiagUnexpectedEndOfInput` | Premature end of file |
| DFM002 | `DiagExpectedTokenNotFound` | Token mismatch (expected X got Y) |
| DFM003 | `DiagInvalidValueSyntax` | Malformed property value |
| DFM004 | `DiagInvalidBinarySignature` | Binary DFM missing TPF0 signature |
| DFM005 | `DiagUnknownBinaryValueType` | Unrecognized binary value tag |
| DFM006 | `DiagIncompleteHexData` | Odd nibble count in hex binary data |
| DFM007 | `DiagCharLiteralOutOfRange` | Char literal value outside 0..$FFFF |
| DFM008 | `DiagParsedWithRecovery` | Parse succeeded but with warnings |

### TParseResult

```
TParseResult = record
  Form: TFormFile;             // AST (may be partial on error)
  Diagnostics: TArray<TFormDiagnostic>;
  Success: Boolean;            // False if any dsError diagnostic
end;
```

The diagnostic-mode parser uses error recovery (`SkipToRecoveryPoint`) to
continue parsing after errors, producing a partial AST with accumulated
diagnostics rather than raising on the first error.


## Facade

`TDelphiFormsParser` in `Delphi.Forms.pas` provides high-level class methods:

| Method | Input | Output |
|--------|-------|--------|
| `ParseFile(FileName)` | File path | `TFormFile` |
| `ParseFile(FileName, Encoding)` | File path + explicit encoding | `TFormFile` |
| `ParseText(Source)` | Text DFM string | `TFormFile` |
| `ParseBinary(Data)` | TPF0 byte array | `TFormFile` |
| `ParseBytes(Data)` | Any format (auto-detect) | `TFormFile` |
| `ParseBytes(Data, Encoding)` | Any format + explicit encoding | `TFormFile` |
| `WriteText(FormFile)` | AST | Text DFM string |
| `WriteBinary(FormFile)` | AST | TPF0 byte array |
| `BinaryToText(Data)` | TPF0 bytes | Text DFM string |
| `TextToBinary(Source)` | Text DFM string | TPF0 bytes |
| `DetectFormat(Data)` | Raw bytes | `TDfmFormat` (`dfText` or `dfBinary`) |
| `IsBinaryDfm(Data)` | Raw bytes | Boolean |

All diagnostic variants (`ParseTextWithDiagnostics`,
`ParseBinaryWithDiagnostics`, `ParseFileWithDiagnostics`,
`ParseBytesWithDiagnostics`) return `TParseResult` instead of `TFormFile`.

### Encoding detection

`ParseBytes` (no encoding parameter) auto-detects:
1. UTF-8 BOM (`$EF $BB $BF`) -- decode as UTF-8
2. UTF-16 LE BOM (`$FF $FE`) -- decode as Unicode
3. No BOM -- default to UTF-8; on decode failure, fall back to Windows-1252

The explicit-encoding overloads bypass auto-detection for legacy ANSI DFM
files from pre-Unicode Delphi projects.


## Memory Ownership

- `TFormFile` owns `Root: TFormObject` (freed in destructor).
- `TFormObject` owns `Properties: TFormPropertyList` and
  `Children: TFormObjectList` (both `TObjectList` with `OwnsObjects = True`).
- `TFormProperty` owns `Value: TFormValue` (freed in destructor).
- `TFormValue` owns `ListItems: TFormValueList` and
  `CollectionItems: TFormObjectList` when created for those kinds.
- `TFormObject.Parent` is a non-owning back-reference (set by the parser
  and binary reader when adding children).

Freeing `TFormFile` cascades through the entire tree.

```pascal
// Typical usage:
Form := TDelphiFormsParser.ParseFile('Main.dfm');
try
  // Navigate: Form.Root.Children[0].Properties[0].Value.StringValue
  // Write:   TDelphiFormsParser.WriteText(Form)
finally
  Form.Free;  // frees entire tree
end;
```


## Enums

| Enum | Values |
|------|--------|
| `TObjectKind` | `okObject`, `okInherited`, `okInline` |
| `TFormValueKind` | `fvInteger`, `fvFloat`, `fvString`, `fvBoolean`, `fvIdentifier`, `fvSet`, `fvBinary`, `fvList`, `fvCollection` |
| `TDfmTokenKind` | 21 values: identifiers, numbers, strings, punctuation, brackets, trivia, EOF |
| `TDfmFormat` | `dfText`, `dfBinary` |
| `TFormDiagnosticSeverity` | `dsError`, `dsWarning`, `dsInfo` |


## Design Invariants

1. **Text round-trip**: parse text DFM -> AST -> write text == original
2. **Binary round-trip**: read binary -> AST -> write binary == original
   (requires `OriginalValueType` and `ExtendedRawBytes` preservation)
3. **Lexer token coverage**: every character appears in exactly one token
4. **Lexer token concat**: joining all `Token.Text` reproduces the source
5. **Deterministic**: same input always produces same output
6. **No information loss**: AST preserves all data needed for round-trip
7. **Ownership cascade**: freeing `TFormFile` frees the entire tree
