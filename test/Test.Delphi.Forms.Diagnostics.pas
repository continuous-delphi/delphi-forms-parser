unit Test.Delphi.Forms.Diagnostics;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Forms,
  Delphi.Forms.Types,
  Delphi.Forms.Diagnostics,
  Delphi.Forms.BinaryReader;

type

  [TestFixture]
  TDiagnosticsTests = class
  public
    [Test]
    procedure ExistingParseText_StillRaisesOnError;

    [Test]
    procedure ExistingParseText_StillWorksForValidInput;

    [Test]
    procedure DFM001_UnexpectedEndOfInput_TruncatedMissingEnd;

    [Test]
    procedure DFM001_UnexpectedEndOfInput_EmptyInput;

    [Test]
    procedure DFM002_ExpectedTokenNotFound_MissingColon;

    [Test]
    procedure DFM002_ExpectedTokenNotFound_MissingClassName;

    [Test]
    procedure DFM003_InvalidValueSyntax_UnexpectedToken;

    [Test]
    procedure DFM004_InvalidBinarySignature;

    [Test]
    procedure DFM005_UnknownBinaryValueType;

    [Test]
    procedure DFM006_IncompleteHexData;

    [Test]
    procedure DFM007_CharLiteralOutOfRange;

    [Test]
    procedure DFM008_ParsedWithRecovery;

    [Test]
    procedure ValidInput_ReturnsSuccess;

    [Test]
    procedure ValidInput_FormNotNil;

    [Test]
    procedure PartialAST_ReturnedOnError;

    [Test]
    procedure ParseBytesWithDiagnostics_TextFormat;

    [Test]
    procedure ParseBinaryWithDiagnostics_ValidInput;

    [Test]
    procedure MultipleErrors_AllCollected;

    [Test]
    procedure ParseFileWithDiagnostics_ValidGoldenFile;
  end;

  [TestFixture]
  TFormAncestryTests = class
  public
    [Test]
    procedure InheritedForm_ReturnsTrue;

    [Test]
    procedure NonInheritedForm_ReturnsFalse;

    [Test]
    procedure InlineForm_ReturnsFalse;

    [Test]
    procedure NilForm_ReturnsFalse;

    [Test]
    procedure FormWithNoRoot_ReturnsFalse;

    [Test]
    procedure InheritedForm_ReturnsClassName;

    [Test]
    procedure NonInheritedForm_ReturnsEmpty;

    [Test]
    procedure NilForm_ReturnsEmpty;
  end;

implementation

uses
  System.IOUtils;

const
  ValidDfm =
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Caption = ''Hello'''#13#10 +
    'end'#13#10;

{ TDiagnosticsTests }

procedure TDiagnosticsTests.ExistingParseText_StillRaisesOnError;
begin
  // Truncated property value triggers 'Unexpected end of DFM input' in Current/CurrentKind
  Assert.WillRaise(
    procedure
    begin
      TDelphiFormsParser.ParseText('object Form1: TForm1'#13#10'  Left ='#13#10).Free;
    end);
end;

procedure TDiagnosticsTests.ExistingParseText_StillWorksForValidInput;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(ValidDfm);
  try
    Assert.IsNotNull(F);
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('Form1', F.Root.Name);
  finally
    F.Free;
  end;
end;

procedure TDiagnosticsTests.DFM001_UnexpectedEndOfInput_TruncatedMissingEnd;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
begin
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10);
  try
    Assert.IsFalse(R.Success);
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagUnexpectedEndOfInput then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsError), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM001 diagnostic');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM001_UnexpectedEndOfInput_EmptyInput;
var
  R: TParseResult;
begin
  R := TDelphiFormsParser.ParseTextWithDiagnostics('');
  try
    Assert.IsTrue(R.Success, 'Empty input should succeed with empty form');
    Assert.IsNotNull(R.Form);
    Assert.IsNull(R.Form.Root);
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM002_ExpectedTokenNotFound_MissingColon;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
begin
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1 TForm1'#13#10 +
    'end'#13#10);
  try
    Assert.IsFalse(R.Success);
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagExpectedTokenNotFound then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsError), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM002 diagnostic');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM002_ExpectedTokenNotFound_MissingClassName;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
begin
  // After the colon, the next non-trivia token is '=' which is not an identifier
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: = 0'#13#10 +
    'end'#13#10);
  try
    Assert.IsFalse(R.Success);
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagExpectedTokenNotFound then
      begin
        Found := True;
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM002 diagnostic for missing class name');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM003_InvalidValueSyntax_UnexpectedToken;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
begin
  // Property value is missing/invalid -- triggers error during property parse
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: TForm1'#13#10 +
    '  Left = :'#13#10 +
    '  Top = 0'#13#10 +
    'end'#13#10);
  try
    Assert.IsFalse(R.Success);
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagInvalidValueSyntax then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsError), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM003 diagnostic');
    // Parser should have recovered and continued -- form should exist
    Assert.IsNotNull(R.Form);
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM004_InvalidBinarySignature;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
  Data: TBytes;
begin
  Data := TBytes.Create($FF, $00, $00, $00, $00);
  R := TDelphiFormsParser.ParseBinaryWithDiagnostics(Data);
  try
    Assert.IsFalse(R.Success);
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagInvalidBinarySignature then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsError), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM004 diagnostic');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM005_UnknownBinaryValueType;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
  Data: TBytes;
begin
  // Build a minimal binary DFM with an unknown value type tag (99)
  // $FF + TPF0 + class "TF" (len 2) + name "F" (len 1) + prop "X" (len 1) + value type 99
  Data := TBytes.Create(
    $FF, Ord('T'), Ord('P'), Ord('F'), Ord('0'),  // signature
    2, Ord('T'), Ord('F'),                          // class name len=2 "TF"
    1, Ord('F'),                                    // object name len=1 "F"
    1, Ord('X'),                                    // property name len=1 "X"
    99                                               // unknown value type
  );
  R := TDelphiFormsParser.ParseBinaryWithDiagnostics(Data);
  try
    Assert.IsFalse(R.Success);
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagUnknownBinaryValueType then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsError), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM005 diagnostic');
    // Partial form should still be returned
    Assert.IsNotNull(R.Form);
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM006_IncompleteHexData;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
begin
  // Odd number of hex digits -- should produce DFM006 warning
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: TForm1'#13#10 +
    '  Data = {0A5}'#13#10 +
    'end'#13#10);
  try
    Assert.IsTrue(R.Success, 'Should succeed with warning');
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagIncompleteHexData then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsWarning), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM006 diagnostic');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM007_CharLiteralOutOfRange;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
begin
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: TForm1'#13#10 +
    '  Caption = #99999'#13#10 +
    'end'#13#10);
  try
    Assert.IsTrue(R.Success, 'Should succeed with warning');
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagCharLiteralOutOfRange then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsWarning), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM007 diagnostic');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.DFM008_ParsedWithRecovery;
var
  R: TParseResult;
  Found: Boolean;
  I: Integer;
begin
  // DFM006 produces a warning; DFM008 info should be added when warnings present but no errors
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: TForm1'#13#10 +
    '  Data = {0A5}'#13#10 +
    'end'#13#10);
  try
    Assert.IsTrue(R.Success);
    Found := False;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Code = DiagParsedWithRecovery then
      begin
        Found := True;
        Assert.AreEqual(Ord(dsInfo), Ord(R.Diagnostics[I].Severity));
        Break;
      end;
    Assert.IsTrue(Found, 'Expected DFM008 diagnostic');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.ValidInput_ReturnsSuccess;
var
  R: TParseResult;
begin
  R := TDelphiFormsParser.ParseTextWithDiagnostics(ValidDfm);
  try
    Assert.IsTrue(R.Success);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(R.Diagnostics)));
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.ValidInput_FormNotNil;
var
  R: TParseResult;
begin
  R := TDelphiFormsParser.ParseTextWithDiagnostics(ValidDfm);
  try
    Assert.IsNotNull(R.Form);
    Assert.IsNotNull(R.Form.Root);
    Assert.AreEqual('Form1', R.Form.Root.Name);
    Assert.AreEqual('TForm1', R.Form.Root.ClassName_);
    Assert.AreEqual(NativeInt(3), R.Form.Root.Properties.Count);
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.PartialAST_ReturnedOnError;
var
  R: TParseResult;
begin
  // Missing 'end' -- parser should return partial AST
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10);
  try
    Assert.IsFalse(R.Success);
    Assert.IsNotNull(R.Form, 'Form should not be nil even on error');
    Assert.IsNotNull(R.Form.Root, 'Root should be populated with partial AST');
    Assert.AreEqual('Form1', R.Form.Root.Name);
    // Properties parsed before the error should be present
    Assert.IsTrue(R.Form.Root.Properties.Count >= 1, 'At least some properties should be parsed');
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.ParseBytesWithDiagnostics_TextFormat;
var
  Data: TBytes;
  R: TParseResult;
begin
  Data := TEncoding.UTF8.GetBytes(ValidDfm);
  R := TDelphiFormsParser.ParseBytesWithDiagnostics(Data);
  try
    Assert.IsTrue(R.Success);
    Assert.IsNotNull(R.Form);
    Assert.AreEqual('Form1', R.Form.Root.Name);
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.ParseBinaryWithDiagnostics_ValidInput;
var
  OrigForm: TFormFile;
  BinData: TBytes;
  R: TParseResult;
begin
  // Build a valid binary DFM via text -> parse -> write binary
  OrigForm := TDelphiFormsParser.ParseText(ValidDfm);
  try
    BinData := TDelphiFormsParser.WriteBinary(OrigForm);
  finally
    OrigForm.Free;
  end;
  R := TDelphiFormsParser.ParseBinaryWithDiagnostics(BinData);
  try
    Assert.IsTrue(R.Success);
    Assert.IsNotNull(R.Form);
    Assert.AreEqual('Form1', R.Form.Root.Name);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(R.Diagnostics)));
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.MultipleErrors_AllCollected;
var
  R: TParseResult;
begin
  // Two bad properties -- parser should recover from each and collect both
  R := TDelphiFormsParser.ParseTextWithDiagnostics(
    'object Form1: TForm1'#13#10 +
    '  Left = :'#13#10 +
    '  Top = :'#13#10 +
    '  Width = 100'#13#10 +
    'end'#13#10);
  try
    Assert.IsFalse(R.Success);
    // Should have at least 2 error diagnostics
    var ErrorCount := 0;
    var I: Integer;
    for I := 0 to Length(R.Diagnostics) - 1 do
      if R.Diagnostics[I].Severity = dsError then
        Inc(ErrorCount);
    Assert.IsTrue(ErrorCount >= 2, 'Expected at least 2 error diagnostics, got ' + IntToStr(ErrorCount));
  finally
    R.Form.Free;
  end;
end;

procedure TDiagnosticsTests.ParseFileWithDiagnostics_ValidGoldenFile;
var
  R: TParseResult;
  GoldenDir: string;
begin
  GoldenDir := ExtractFilePath(ParamStr(0)) + '..\..\..\test\golden\';
  if not DirectoryExists(GoldenDir) then
    GoldenDir := ExtractFilePath(ParamStr(0)) + '..\..\test\golden\';
  if not DirectoryExists(GoldenDir) then
    Exit; // skip if golden dir not found

  R := TDelphiFormsParser.ParseFileWithDiagnostics(GoldenDir + 'minimal.dfm');
  try
    Assert.IsTrue(R.Success);
    Assert.IsNotNull(R.Form);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(R.Diagnostics)));
  finally
    R.Form.Free;
  end;
end;

{ TFormAncestryTests }

procedure TFormAncestryTests.InheritedForm_ReturnsTrue;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(
    'inherited frmChild: TfrmBase'#13#10 +
    '  Caption = ''Child'''#13#10 +
    'end'#13#10);
  try
    Assert.IsTrue(IsInheritedForm(F));
  finally
    F.Free;
  end;
end;

procedure TFormAncestryTests.NonInheritedForm_ReturnsFalse;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Caption = ''Main'''#13#10 +
    'end'#13#10);
  try
    Assert.IsFalse(IsInheritedForm(F));
  finally
    F.Free;
  end;
end;

procedure TFormAncestryTests.InlineForm_ReturnsFalse;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(
    'inline frmInline: TfrmInline'#13#10 +
    '  Caption = ''Inline'''#13#10 +
    'end'#13#10);
  try
    Assert.IsFalse(IsInheritedForm(F));
  finally
    F.Free;
  end;
end;

procedure TFormAncestryTests.NilForm_ReturnsFalse;
begin
  Assert.IsFalse(IsInheritedForm(nil));
end;

procedure TFormAncestryTests.FormWithNoRoot_ReturnsFalse;
var
  F: TFormFile;
begin
  F := TFormFile.Create;
  try
    Assert.IsFalse(IsInheritedForm(F));
  finally
    F.Free;
  end;
end;

procedure TFormAncestryTests.InheritedForm_ReturnsClassName;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(
    'inherited frmChild: TfrmBase'#13#10 +
    '  Caption = ''Child'''#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual('TfrmBase', GetAncestorClassName(F));
  finally
    F.Free;
  end;
end;

procedure TFormAncestryTests.NonInheritedForm_ReturnsEmpty;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Caption = ''Main'''#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual('', GetAncestorClassName(F));
  finally
    F.Free;
  end;
end;

procedure TFormAncestryTests.NilForm_ReturnsEmpty;
begin
  Assert.AreEqual('', GetAncestorClassName(nil));
end;

end.
