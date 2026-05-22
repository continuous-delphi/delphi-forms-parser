# Changelog for delphi-forms-parser
Home repo: https://github.com/continuous-delphi/delphi-forms-parser

---


### 0.1.5 - Unreleased

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