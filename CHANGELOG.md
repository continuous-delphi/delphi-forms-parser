# Changelog for delphi-forms-parser
Home repo: https://github.com/continuous-delphi/delphi-forms-parser

---


### 0.1.7 - Unreleased

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