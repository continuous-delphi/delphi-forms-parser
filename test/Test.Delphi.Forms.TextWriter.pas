unit Test.Delphi.Forms.TextWriter;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Forms.Types,
  Delphi.Forms.Parser,
  Delphi.Forms.TextWriter;

type

  [TestFixture]
  TDfmTextWriterTests = class
  private
    FParser: TDfmParser;
    FWriter: TDfmTextWriter;
    procedure AssertRoundTrip(const Source: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Write_MinimalForm;
    [Test]
    procedure Write_IntegerProperty;
    [Test]
    procedure Write_HexIntegerPreservesRawText;
    [Test]
    procedure Write_NegativeInteger;
    [Test]
    procedure Write_FloatProperty;
    [Test]
    procedure Write_StringProperty;
    [Test]
    procedure Write_BooleanProperties;
    [Test]
    procedure Write_IdentifierProperty;
    [Test]
    procedure Write_DottedPropertyName;
    [Test]
    procedure Write_SetProperty;
    [Test]
    procedure Write_EmptySet;
    [Test]
    procedure Write_NestedObjects;
    [Test]
    procedure Write_InheritedForm;
    [Test]
    procedure Write_InlineForm;
    [Test]
    procedure Write_MultipleProperties;
    [Test]
    procedure RoundTrip_SimpleForm;
    [Test]
    procedure RoundTrip_NestedObjects;
    [Test]
    procedure RoundTrip_AllValueTypes;
    [Test]
    procedure RoundTrip_ListValue;
    [Test]
    procedure RoundTrip_BinaryData;
    [Test]
    procedure RoundTrip_CollectionValue;
    [Test]
    procedure RoundTrip_RealWorldForm;
    [Test]
    procedure Write_Canonical_FromConstructedAST;
  end;

implementation

procedure TDfmTextWriterTests.Setup;
begin
  FParser := TDfmParser.Create;
  FWriter := TDfmTextWriter.Create;
end;

procedure TDfmTextWriterTests.TearDown;
begin
  FWriter.Free;
  FParser.Free;
end;

procedure TDfmTextWriterTests.AssertRoundTrip(const Source: string);
var
  F: TFormFile;
  Output: string;
begin
  F := FParser.Parse(Source);
  try
    Output := FWriter.Write(F);
    Assert.AreEqual(Source, Output, 'Round-trip failed');
  finally
    F.Free;
  end;
end;

procedure TDfmTextWriterTests.Write_MinimalForm;
var
  F: TFormFile;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'frmMain';
    F.Root.ClassName_ := 'TfrmMain';
    Assert.AreEqual('object frmMain: TfrmMain'#13#10'end'#13#10, FWriter.Write(F));
  finally
    F.Free;
  end;
end;

procedure TDfmTextWriterTests.Write_IntegerProperty;
var
  F: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvInteger);
    V.IntValue := 42;
    F.Root.Properties.Add(TFormProperty.Create('Left', V));
    Assert.AreEqual('object f: TF'#13#10'  Left = 42'#13#10'end'#13#10, FWriter.Write(F));
  finally
    F.Free;
  end;
end;

procedure TDfmTextWriterTests.Write_HexIntegerPreservesRawText;
begin
  AssertRoundTrip('object f: TF'#13#10'  Color = $00FF00'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_NegativeInteger;
begin
  AssertRoundTrip('object f: TF'#13#10'  Top = -12'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_FloatProperty;
begin
  AssertRoundTrip('object f: TF'#13#10'  Scale = 3.14'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_StringProperty;
begin
  AssertRoundTrip('object f: TF'#13#10'  Caption = ''Hello'''#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_BooleanProperties;
begin
  AssertRoundTrip('object f: TF'#13#10'  Visible = True'#13#10'end'#13#10);
  AssertRoundTrip('object f: TF'#13#10'  Visible = False'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_IdentifierProperty;
begin
  AssertRoundTrip('object f: TF'#13#10'  Color = clBtnFace'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_DottedPropertyName;
begin
  AssertRoundTrip('object f: TF'#13#10'  Font.Name = ''Segoe UI'''#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_SetProperty;
begin
  AssertRoundTrip('object f: TF'#13#10'  Anchors = [akLeft, akTop, akRight]'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_EmptySet;
begin
  AssertRoundTrip('object f: TF'#13#10'  Font.Style = []'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_NestedObjects;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  Caption = ''Main'''#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    Left = 0'#13#10 +
    '    object Button1: TButton'#13#10 +
    '      Caption = ''Click'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_InheritedForm;
begin
  AssertRoundTrip('inherited frmChild: TfrmChild'#13#10'  Caption = ''Child'''#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_InlineForm;
begin
  AssertRoundTrip('inline frmEmbed: TfrmEmbed'#13#10'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_MultipleProperties;
begin
  AssertRoundTrip(
    'object f: TF'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 10'#13#10 +
    '  Caption = ''Test'''#13#10 +
    '  Color = clBtnFace'#13#10 +
    '  Visible = True'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.RoundTrip_SimpleForm;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Caption = ''Hello'''#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.RoundTrip_NestedObjects;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    object Button1: TButton'#13#10 +
    '      Caption = ''Deep'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object Label1: TLabel'#13#10 +
    '    Caption = ''Label'''#13#10 +
    '  end'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.RoundTrip_AllValueTypes;
begin
  AssertRoundTrip(
    'object f: TF'#13#10 +
    '  IntProp = 42'#13#10 +
    '  HexProp = $FF'#13#10 +
    '  NegProp = -5'#13#10 +
    '  FloatProp = 3.14'#13#10 +
    '  StrProp = ''Hello'''#13#10 +
    '  BoolProp = True'#13#10 +
    '  IdProp = clRed'#13#10 +
    '  SetProp = [akLeft, akTop]'#13#10 +
    '  EmptySet = []'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.RoundTrip_ListValue;
begin
  AssertRoundTrip(
    'object f: TF'#13#10 +
    '  Items.Strings = ('#13#10 +
    '    ''Item 1'''#13#10 +
    '    ''Item 2'''#13#10 +
    '    ''Item 3'')'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.RoundTrip_BinaryData;
begin
  AssertRoundTrip(
    'object f: TF'#13#10 +
    '  Data = {0A54FF}'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.RoundTrip_CollectionValue;
begin
  AssertRoundTrip(
    'object f: TF'#13#10 +
    '  Columns = <'#13#10 +
    '    item'#13#10 +
    '      Caption = ''Col 1'''#13#10 +
    '      Width = 100'#13#10 +
    '    end'#13#10 +
    '    item'#13#10 +
    '      Caption = ''Col 2'''#13#10 +
    '    end>'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.RoundTrip_RealWorldForm;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Caption = ''Debug Utility'''#13#10 +
    '  ClientHeight = 848'#13#10 +
    '  ClientWidth = 997'#13#10 +
    '  Color = clBtnFace'#13#10 +
    '  Font.Charset = DEFAULT_CHARSET'#13#10 +
    '  Font.Color = clWindowText'#13#10 +
    '  Font.Height = -12'#13#10 +
    '  Font.Name = ''Segoe UI'''#13#10 +
    '  Font.Style = []'#13#10 +
    '  Position = poScreenCenter'#13#10 +
    '  object labSourceCode: TLabel'#13#10 +
    '    Left = 8'#13#10 +
    '    Top = 11'#13#10 +
    '    Caption = ''Source:'''#13#10 +
    '  end'#13#10 +
    '  object butTokenize: TButton'#13#10 +
    '    Left = 8'#13#10 +
    '    Caption = ''Tokenize'''#13#10 +
    '    OnClick = butTokenizeClick'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
end;

procedure TDfmTextWriterTests.Write_Canonical_FromConstructedAST;
var
  F: TFormFile;
  V: TFormValue;
  SetV: TFormValue;
  Child: TFormObject;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'frmMain';
    F.Root.ClassName_ := 'TfrmMain';

    V := TFormValue.Create(fvInteger);
    V.IntValue := 0;
    F.Root.Properties.Add(TFormProperty.Create('Left', V));

    V := TFormValue.Create(fvString);
    V.StringValue := 'Hello';
    F.Root.Properties.Add(TFormProperty.Create('Caption', V));

    V := TFormValue.Create(fvBoolean);
    V.BoolValue := True;
    F.Root.Properties.Add(TFormProperty.Create('Visible', V));

    SetV := TFormValue.Create(fvSet);
    SetV.SetItems := TArray<string>.Create('akLeft', 'akTop');
    F.Root.Properties.Add(TFormProperty.Create('Anchors', SetV));

    Child := TFormObject.Create;
    Child.Name := 'Button1';
    Child.ClassName_ := 'TButton';
    V := TFormValue.Create(fvString);
    V.StringValue := 'Click';
    Child.Properties.Add(TFormProperty.Create('Caption', V));
    F.Root.Children.Add(Child);

    Assert.AreEqual(
      'object frmMain: TfrmMain'#13#10 +
      '  Left = 0'#13#10 +
      '  Caption = ''Hello'''#13#10 +
      '  Visible = True'#13#10 +
      '  Anchors = [akLeft, akTop]'#13#10 +
      '  object Button1: TButton'#13#10 +
      '    Caption = ''Click'''#13#10 +
      '  end'#13#10 +
      'end'#13#10,
      FWriter.Write(F));
  finally
    F.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDfmTextWriterTests);

end.
