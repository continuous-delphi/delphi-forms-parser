# Changelog for delphi-forms-parser
Home repo: https://github.com/continuous-delphi/delphi-forms-parser

---


### 0.2.13

- Support typed collection items (`item ClassName ... end`). Parser detects
  optional class name via lookahead, writer emits it when present. Golden file
  and round-trip tests for typed collections.
[#11](https://github.com/continuous-delphi/delphi-forms-parser/issues/11)

### 0.2.12

- Preserve original binary value type tags for true binary round-trip. Reader
  stores OriginalValueType and ExtendedRawBytes on TFormValue; writer uses them
  to reproduce byte-identical output for vaSingle, vaExtended, vaCurrency, vaDate,
  vaString, vaLString, vaWString, vaUString, and vaInt32. 9 new round-trip tests.
[#12](https://github.com/continuous-delphi/delphi-forms-parser/issues/12)

## 0.1 - Unreleased

- Initial delphi-forms-parser project in place

### 0.1.10

- Add edge-case golden files: empty form (0 properties, 0 children), deep nesting
  (12 levels), and large binary data (1024 bytes / 32 hex lines). 6 new tests.
[#13](https://github.com/continuous-delphi/delphi-forms-parser/issues/13)

### 0.1.9

- Add FMX golden test file (fmx_form.fmx) with FMX-specific float coordinates,
  nested layouts, and opacity. Round-trip and structural tests verify .fmx support.
[#14](https://github.com/continuous-delphi/delphi-forms-parser/issues/14)

### 0.1.8

- Add TDelphiFormsParser facade with ParseFile/ParseText/ParseBinary/WriteText/
  WriteBinary/BinaryToText/TextToBinary/DetectFormat. Golden test suite with 6
  .dfm files and 9 golden tests. Cross-format round-trip tests (11 tests).
  Total: 151 tests, 0 leaks.
[#9](https://github.com/continuous-delphi/delphi-forms-parser/issues/9)

### 0.1.7

- Add binary DFM writer (TPF0 format); chooses smallest integer type tag,
  writes strings as vaUTF8String, encodes object kind flags in class name
  byte. Binary round-trip verified. 16 binary writer tests.
[#8](https://github.com/continuous-delphi/delphi-forms-parser/issues/8)

### 0.1.6

- Add binary DFM reader (TPF0 format); handles all value type tags including
  vaInt8-vaInt64, vaExtended (80-bit), vaString/vaLString/vaWString/vaUTF8String/
  vaUString, vaIdent, vaTrue/vaFalse, vaSet, vaBinary, vaList, vaCollection.
  16 binary reader tests.
[#7](https://github.com/continuous-delphi/delphi-forms-parser/issues/7)

### 0.1.5

- Add text DFM writer with round-trip fidelity; preserves RawText for parsed
  values, produces canonical 2-space-indent output for constructed ASTs.
  23 writer tests including 8 round-trip verifications.
[#6](https://github.com/continuous-delphi/delphi-forms-parser/issues/6)

### 0.1.4

- Add recursive-descent text DFM parser; all value types, nested objects,
  inherited/inline forms, collections, string concatenation. 25 parser tests.
[#5](https://github.com/continuous-delphi/delphi-forms-parser/issues/5)

### 0.1.3

- Add text DFM lexer with 21 token kinds and round-trip fidelity; `{ hex }`
  tokenized as binary data, not comments. 29 lexer tests.
[#4](https://github.com/continuous-delphi/delphi-forms-parser/issues/4)

### 0.1.2

- Add core AST types: TFormFile, TFormObject, TFormProperty, TFormValue with
  full ownership semantics and 21 tests (zero memory leaks)
[#3](https://github.com/continuous-delphi/delphi-forms-parser/issues/3)

### 0.1.0

- Initial project scaffolding, modeled after delphi-lexer and delphi-parser projects
CI Pipeline: clean > IncVer > build > run > Coverage > CallGraph 
[#1](https://github.com/continuous-delphi/delphi-forms-parser/issues/1)