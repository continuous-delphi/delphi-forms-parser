unit Test.Delphi.Forms.RoundTrip;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
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

initialization
  TDUnitX.RegisterTestFixture(TRoundTripTests);

end.
