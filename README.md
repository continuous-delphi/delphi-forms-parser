# delphi-forms-parser

[![Delphi](https://img.shields.io/badge/delphi-red)](https://www.embarcadero.com/products/delphi)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Continuous Delphi](https://img.shields.io/badge/org-continuous--delphi-red)](https://github.com/continuous-delphi)

A standalone parser for Delphi VCL and FMX form files (.dfm/.fmx) in both text
and binary formats. Produces a typed AST with full round-trip fidelity.

---

## Features

- **Text DFM/FMX parsing** -- lexer + recursive-descent parser for the text
  form file format
- **Binary DFM parsing** -- reads the TPF0 binary format used by older Delphi
  versions
- **Text writer** -- serialize AST back to text DFM with byte-for-byte
  round-trip fidelity
- **Binary writer** -- serialize AST back to binary DFM format
- **Format detection** -- auto-detect text vs binary format
- **Cross-format conversion** -- binary-to-text conversion for migration
  workflows

## Quick start

```pascal
uses
  Delphi.Forms,
  Delphi.Forms.Types;

var
  FormFile: TFormFile;
begin
  // Parse a text DFM file
  FormFile := TDelphiFormsParser.ParseFile('MyForm.dfm');
  try
    // Access the component tree
    WriteLn('Root: ', FormFile.Root.Name, ': ', FormFile.Root.ClassName_);
    WriteLn('Children: ', FormFile.Root.Children.Count);
    WriteLn('Properties: ', FormFile.Root.Properties.Count);

    // Round-trip: write back to text
    WriteLn(TDelphiFormsParser.WriteText(FormFile));
  finally
    FormFile.Free;
  end;
end;
```

## Supported value types

| Type | Text example | Binary tag |
|------|-------------|------------|
| Integer | `123`, `-5`, `$FF` | vaInt8, vaInt16, vaInt32, vaInt64 |
| Float | `3.14`, `-1.5E2` | vaSingle, vaDouble, vaExtended, vaCurrency, vaDate |
| String | `'Hello'`, `'line1'#13#10'line2'` | vaString, vaLString, vaWString, vaUTF8String, vaUString |
| Boolean | `True`, `False` | vaTrue, vaFalse |
| Identifier | `clRed`, `poScreenCenter` | vaIdent |
| Set | `[ssDouble, ssBold]`, `[]` | vaSet |
| Binary | `{ 0A544A5045... }` | vaBinary |
| List | `(item1 item2)` | vaList |
| Collection | `< item ... end>` | vaCollection |

## Design invariants

1. **Text round-trip** -- parse text DFM, write back: output matches original
   byte-for-byte
2. **Binary round-trip** -- read binary DFM, write back: output matches original
   byte-for-byte
3. **Token coverage** -- every character in text DFM appears in exactly one token
4. **Deterministic** -- same input always produces same output

## Architecture

```
Text DFM ---> TDfmLexer ---> TDfmTokenList ---> TDfmParser ---> TFormFile (AST)
Binary DFM ---> TDfmBinaryReader -----------------------------------^
                                                                    |
TFormFile ---> TDfmTextWriter ---> text DFM output                  |
TFormFile ---> TDfmBinaryWriter ---> binary DFM output              |
```

## Related projects

- [delphi-lexer](https://github.com/continuous-delphi/delphi-lexer) -- lexer
  for Delphi Object Pascal source code

## License

MIT -- see [LICENSE](LICENSE).
