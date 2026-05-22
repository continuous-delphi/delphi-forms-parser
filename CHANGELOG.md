# Changelog for delphi-forms-parser
Home repo: https://github.com/continuous-delphi/delphi-forms-parser

---


### 0.1.3 - Unreleased

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