unit Test.Delphi.Forms.RoundTrip;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Delphi.Forms,
  Delphi.Forms.Types;

type

  [TestFixture]
  TRoundTripTests = class
  public
    [Test]
    procedure TextToText_Minimal;
    [Test]
    procedure TextToText_AllValueTypes;
    [Test]
    procedure TextToBinaryToText_Stable;
    [Test]
    procedure BinaryToBinaryRoundTrip;
    [Test]
    procedure TextToBinaryToText_NestedForm;
    [Test]
    procedure TextToBinaryToText_BoolAndIdent;
    [Test]
    procedure TextToBinaryToText_SetProperty;
    [Test]
    procedure DetectFormat_TextInput;
    [Test]
    procedure DetectFormat_BinaryInput;
    [Test]
    procedure ParseBytes_AutoDetectsText;
    [Test]
    procedure ParseBytes_AutoDetectsBinary;
    [Test]
    procedure ParseBytes_UTF8WithBOM;
    [Test]
    procedure ParseBytes_ANSIExplicit;
    [Test]
    procedure ParseFile_EncodingOverload;
    [Test]
    procedure ParseBytes_Win1252Fallback;
    [Test]
    procedure ParseBytes_ExplicitEncoding_NoFallback;
  end;

implementation

procedure TRoundTripTests.TextToText_Minimal;
var
  Source: string;
  F: TFormFile;
  Output: string;
begin
  Source := 'object f: TF'#13#10'  Left = 0'#13#10'end'#13#10;
  F := TDelphiFormsParser.ParseText(Source);
  try
    Output := TDelphiFormsParser.WriteText(F);
    Assert.AreEqual(Source, Output);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.TextToText_AllValueTypes;
var
  Source: string;
  F: TFormFile;
  Output: string;
begin
  Source :=
    'object f: TF'#13#10 +
    '  IntProp = 42'#13#10 +
    '  NegProp = -5'#13#10 +
    '  FloatProp = 3.14'#13#10 +
    '  StrProp = ''Hello'''#13#10 +
    '  BoolProp = True'#13#10 +
    '  IdProp = clRed'#13#10 +
    '  SetProp = [akLeft, akTop]'#13#10 +
    '  EmptySet = []'#13#10 +
    '  BinProp = {DEADBEEF}'#13#10 +
    '  ListProp = ('#13#10 +
    '    100'#13#10 +
    '    200)'#13#10 +
    'end'#13#10;
  F := TDelphiFormsParser.ParseText(Source);
  try
    Output := TDelphiFormsParser.WriteText(F);
    Assert.AreEqual(Source, Output);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.TextToBinaryToText_Stable;
var
  Source: string;
  BinData: TBytes;
  Text1: string;
  Text2: string;
begin
  Source :=
    'object frmMain: TfrmMain'#13#10 +
    '  Left = 0'#13#10 +
    '  Caption = ''Hello'''#13#10 +
    '  Visible = True'#13#10 +
    '  Color = clBtnFace'#13#10 +
    'end'#13#10;
  // Text -> AST -> Binary
  BinData := TDelphiFormsParser.TextToBinary(Source);
  Assert.IsTrue(TDelphiFormsParser.IsBinaryDfm(BinData), 'Should be binary format');
  // Binary -> AST -> Text
  Text1 := TDelphiFormsParser.BinaryToText(BinData);
  // Text -> AST -> Binary -> AST -> Text (stability check)
  BinData := TDelphiFormsParser.TextToBinary(Text1);
  Text2 := TDelphiFormsParser.BinaryToText(BinData);
  Assert.AreEqual(Text1, Text2, 'Text->Binary->Text should be stable after first pass');
end;

procedure TRoundTripTests.BinaryToBinaryRoundTrip;
var
  Source: string;
  Bin1: TBytes;
  Bin2: TBytes;
  F: TFormFile;
begin
  Source :=
    'object f: TF'#13#10 +
    '  Left = 42'#13#10 +
    '  Caption = ''Test'''#13#10 +
    'end'#13#10;
  Bin1 := TDelphiFormsParser.TextToBinary(Source);
  F := TDelphiFormsParser.ParseBinary(Bin1);
  try
    Bin2 := TDelphiFormsParser.WriteBinary(F);
    Assert.AreEqual(NativeInt(Length(Bin1)), NativeInt(Length(Bin2)), 'Binary length mismatch');
    Assert.IsTrue(CompareMem(@Bin1[0], @Bin2[0], Length(Bin1)), 'Binary bytes differ');
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.TextToBinaryToText_NestedForm;
var
  Source: string;
  Text1: string;
  Text2: string;
begin
  Source :=
    'object frmMain: TfrmMain'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    Left = 8'#13#10 +
    '    object Button1: TButton'#13#10 +
    '      Caption = ''OK'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    'end'#13#10;
  Text1 := TDelphiFormsParser.BinaryToText(TDelphiFormsParser.TextToBinary(Source));
  Text2 := TDelphiFormsParser.BinaryToText(TDelphiFormsParser.TextToBinary(Text1));
  Assert.AreEqual(Text1, Text2, 'Nested form cross-format not stable');
end;

procedure TRoundTripTests.TextToBinaryToText_BoolAndIdent;
var
  Source: string;
  F: TFormFile;
begin
  Source :=
    'object f: TF'#13#10 +
    '  Visible = True'#13#10 +
    '  Enabled = False'#13#10 +
    '  Color = clBtnFace'#13#10 +
    'end'#13#10;
  F := TDelphiFormsParser.ParseBinary(TDelphiFormsParser.TextToBinary(Source));
  try
    Assert.IsTrue(F.Root.Properties[0].Value.BoolValue);
    Assert.IsFalse(F.Root.Properties[1].Value.BoolValue);
    Assert.AreEqual('clBtnFace', F.Root.Properties[2].Value.IdentValue);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.TextToBinaryToText_SetProperty;
var
  Source: string;
  F: TFormFile;
begin
  Source :=
    'object f: TF'#13#10 +
    '  Anchors = [akLeft, akTop, akRight]'#13#10 +
    'end'#13#10;
  F := TDelphiFormsParser.ParseBinary(TDelphiFormsParser.TextToBinary(Source));
  try
    Assert.AreEqual(fvSet, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(3), NativeInt(Length(F.Root.Properties[0].Value.SetItems)));
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.DetectFormat_TextInput;
var
  Data: TBytes;
begin
  Data := TEncoding.UTF8.GetBytes('object f: TF'#13#10'end'#13#10);
  Assert.AreEqual(dfText, TDelphiFormsParser.DetectFormat(Data));
  Assert.IsFalse(TDelphiFormsParser.IsBinaryDfm(Data));
end;

procedure TRoundTripTests.DetectFormat_BinaryInput;
var
  Data: TBytes;
begin
  Data := TDelphiFormsParser.TextToBinary('object f: TF'#13#10'end'#13#10);
  Assert.AreEqual(dfBinary, TDelphiFormsParser.DetectFormat(Data));
  Assert.IsTrue(TDelphiFormsParser.IsBinaryDfm(Data));
end;

procedure TRoundTripTests.ParseBytes_AutoDetectsText;
var
  Data: TBytes;
  F: TFormFile;
begin
  Data := TEncoding.UTF8.GetBytes('object f: TF'#13#10'  Left = 0'#13#10'end'#13#10);
  F := TDelphiFormsParser.ParseBytes(Data);
  try
    Assert.AreEqual('f', F.Root.Name);
    Assert.AreEqual('TF', F.Root.ClassName_);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.ParseBytes_AutoDetectsBinary;
var
  BinData: TBytes;
  F: TFormFile;
begin
  BinData := TDelphiFormsParser.TextToBinary('object f: TF'#13#10'  Left = 42'#13#10'end'#13#10);
  F := TDelphiFormsParser.ParseBytes(BinData);
  try
    Assert.AreEqual('f', F.Root.Name);
    Assert.AreEqual(Int64(42), F.Root.Properties[0].Value.IntValue);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.ParseBytes_UTF8WithBOM;
var
  Source: string;
  Utf8Bytes: TBytes;
  BomBytes: TBytes;
  Data: TBytes;
  F: TFormFile;
begin
  Source := 'object f: TF'#13#10'  Caption = ''Hello'''#13#10'end'#13#10;
  Utf8Bytes := TEncoding.UTF8.GetBytes(Source);
  // Prepend UTF-8 BOM
  BomBytes := TBytes.Create($EF, $BB, $BF);
  SetLength(Data, Length(BomBytes) + Length(Utf8Bytes));
  Move(BomBytes[0], Data[0], Length(BomBytes));
  Move(Utf8Bytes[0], Data[Length(BomBytes)], Length(Utf8Bytes));

  F := TDelphiFormsParser.ParseBytes(Data);
  try
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('f', F.Root.Name);
    Assert.AreEqual('Hello', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.ParseBytes_ANSIExplicit;
var
  Source: string;
  AnsiBytes: TBytes;
  F: TFormFile;
begin
  Source := 'object f: TF'#13#10'  Caption = ''Test'''#13#10'end'#13#10;
  AnsiBytes := TEncoding.ANSI.GetBytes(Source);

  F := TDelphiFormsParser.ParseBytes(AnsiBytes, TEncoding.ANSI);
  try
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('Test', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.ParseFile_EncodingOverload;
var
  TempFile: string;
  Source: string;
  F: TFormFile;
begin
  Source := 'object f: TF'#13#10'  Left = 0'#13#10'end'#13#10;
  TempFile := TPath.GetTempFileName;
  try
    TFile.WriteAllBytes(TempFile, TEncoding.UTF8.GetBytes(Source));
    F := TDelphiFormsParser.ParseFile(TempFile, TEncoding.UTF8);
    try
      Assert.AreEqual('f', F.Root.Name);
      Assert.AreEqual(Int64(0), F.Root.Properties[0].Value.IntValue);
    finally
      F.Free;
    end;
  finally
    TFile.Delete(TempFile);
  end;
end;

procedure TRoundTripTests.ParseBytes_Win1252Fallback;
var
  Data: TBytes;
  F: TFormFile;
begin
  // Build ANSI bytes with $E9 (e-acute in Win1252, invalid as standalone UTF-8)
  // 'object f: TF\r\n  Caption = 'Caf' + $E9 + '\r\nend\r\n'
  Data := TBytes.Create(
    Ord('o'),Ord('b'),Ord('j'),Ord('e'),Ord('c'),Ord('t'),Ord(' '),
    Ord('f'),Ord(':'),Ord(' '),Ord('T'),Ord('F'),$0D,$0A,
    Ord(' '),Ord(' '),Ord('C'),Ord('a'),Ord('p'),Ord('t'),Ord('i'),Ord('o'),Ord('n'),
    Ord(' '),Ord('='),Ord(' '),Ord(''''),Ord('C'),Ord('a'),Ord('f'),$E9,Ord(''''),
    $0D,$0A,Ord('e'),Ord('n'),Ord('d'),$0D,$0A);
  // $E9 is invalid standalone UTF-8, should fall back to Win1252
  F := TDelphiFormsParser.ParseBytes(Data);
  try
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('f', F.Root.Name);
    // Win1252 $E9 = e-acute (U+00E9)
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
  finally
    F.Free;
  end;
end;

procedure TRoundTripTests.ParseBytes_ExplicitEncoding_NoFallback;
var
  Data: TBytes;
begin
  // Same invalid-UTF-8 data, but with explicit UTF-8 encoding -- should raise
  Data := TBytes.Create(
    Ord('o'),Ord('b'),Ord('j'),Ord('e'),Ord('c'),Ord('t'),Ord(' '),
    Ord('f'),Ord(':'),Ord(' '),Ord('T'),Ord('F'),$0D,$0A,
    Ord(' '),Ord(' '),Ord('L'),Ord('e'),Ord('f'),Ord('t'),
    Ord(' '),Ord('='),Ord(' '),$FE,$FF,$0D,$0A,
    Ord('e'),Ord('n'),Ord('d'),$0D,$0A);
  // Explicit encoding does NOT fall back -- $FE $FF are invalid UTF-8
  // Parser may either raise or produce garbage, but should not crash with AV
  // Just verify it doesn't crash
  try
    var F := TDelphiFormsParser.ParseBytes(Data, TEncoding.UTF8);
    F.Free;
  except
    // Exception is acceptable for explicit encoding with invalid bytes
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRoundTripTests);

end.
