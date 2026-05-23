unit Test.Delphi.Forms.Parser;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Forms.Types,
  Delphi.Forms.Parser;

type

  [TestFixture]
  TDfmParserTests = class
  private
    FParser: TDfmParser;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Parse_MinimalForm;
    [Test]
    procedure Parse_IntegerProperty;
    [Test]
    procedure Parse_NegativeInteger;
    [Test]
    procedure Parse_HexInteger;
    [Test]
    procedure Parse_FloatProperty;
    [Test]
    procedure Parse_NegativeFloat;
    [Test]
    procedure Parse_StringProperty;
    [Test]
    procedure Parse_StringWithEscapedQuote;
    [Test]
    procedure Parse_StringConcat;
    [Test]
    procedure Parse_StringWithCharLiteral;
    [Test]
    procedure Parse_BooleanTrue;
    [Test]
    procedure Parse_BooleanFalse;
    [Test]
    procedure Parse_IdentifierValue;
    [Test]
    procedure Parse_DottedPropertyName;
    [Test]
    procedure Parse_DottedIdentifierValue;
    [Test]
    procedure Parse_SetValue;
    [Test]
    procedure Parse_EmptySet;
    [Test]
    procedure Parse_BinaryData;
    [Test]
    procedure Parse_ListValue;
    [Test]
    procedure Parse_NestedObjects;
    [Test]
    procedure Parse_InheritedForm;
    [Test]
    procedure Parse_InlineForm;
    [Test]
    procedure Parse_CollectionValue;
    [Test]
    procedure Parse_TypedCollectionItems;
    [Test]
    procedure Parse_MixedCollectionItems;
    [Test]
    procedure Parse_MultipleProperties;
    [Test]
    procedure Parse_RealWorldForm;
    [Test]
    procedure Parse_TruncatedMissingEnd;
    [Test]
    procedure Parse_TruncatedMissingValue;
    [Test]
    procedure Parse_TruncatedMissingClassName;
    [Test]
    procedure Parse_EmptyInput;
    [Test]
    procedure Parse_IncompleteHexData;
    [Test]
    procedure Parse_CharLiteralLargeValue;
  end;

implementation

procedure TDfmParserTests.Setup;
begin
  FParser := TDfmParser.Create;
end;

procedure TDfmParserTests.TearDown;
begin
  FParser.Free;
end;

procedure TDfmParserTests.Parse_MinimalForm;
var
  F: TFormFile;
begin
  F := FParser.Parse('object frmMain: TfrmMain'#13#10'end'#13#10);
  try
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('frmMain', F.Root.Name);
    Assert.AreEqual('TfrmMain', F.Root.ClassName_);
    Assert.AreEqual(okObject, F.Root.ObjectKind);
    Assert.AreEqual(NativeInt(0), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(0), F.Root.Children.Count);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_IntegerProperty;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Left = 42'#13#10'end'#13#10);
  try
    Assert.AreEqual(NativeInt(1), F.Root.Properties.Count);
    Assert.AreEqual('Left', F.Root.Properties[0].Name);
    Assert.AreEqual(fvInteger, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Int64(42), F.Root.Properties[0].Value.IntValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_NegativeInteger;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Top = -12'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvInteger, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Int64(-12), F.Root.Properties[0].Value.IntValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_HexInteger;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Color = $00FF00'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvInteger, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Int64($00FF00), F.Root.Properties[0].Value.IntValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_FloatProperty;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Scale = 3.14'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvFloat, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Extended(3.14), F.Root.Properties[0].Value.FloatValue, Extended(0.001));
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_NegativeFloat;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Offset = -1.5'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvFloat, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Extended(-1.5), F.Root.Properties[0].Value.FloatValue, Extended(0.001));
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_StringProperty;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Caption = ''Hello'''#13#10'end'#13#10);
  try
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('Hello', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_StringWithEscapedQuote;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Caption = ''can''''t'''#13#10'end'#13#10);
  try
    Assert.AreEqual('can''t', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_StringConcat;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Caption = ''Hello'' + '' World'''#13#10'end'#13#10);
  try
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('Hello World', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_StringWithCharLiteral;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Caption = ''Line1''#13#10''Line2'''#13#10'end'#13#10);
  try
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('Line1'#13#10'Line2', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_BooleanTrue;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Visible = True'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvBoolean, F.Root.Properties[0].Value.Kind);
    Assert.IsTrue(F.Root.Properties[0].Value.BoolValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_BooleanFalse;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Visible = False'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvBoolean, F.Root.Properties[0].Value.Kind);
    Assert.IsFalse(F.Root.Properties[0].Value.BoolValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_IdentifierValue;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Color = clBtnFace'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvIdentifier, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('clBtnFace', F.Root.Properties[0].Value.IdentValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_DottedPropertyName;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Font.Name = ''Segoe UI'''#13#10'end'#13#10);
  try
    Assert.AreEqual('Font.Name', F.Root.Properties[0].Name);
    Assert.AreEqual('Segoe UI', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_DottedIdentifierValue;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Charset = Font.DEFAULT_CHARSET'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvIdentifier, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('Font.DEFAULT_CHARSET', F.Root.Properties[0].Value.IdentValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_SetValue;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Anchors = [akLeft, akTop, akRight]'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvSet, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(3), NativeInt(Length(F.Root.Properties[0].Value.SetItems)));
    Assert.AreEqual('akLeft', F.Root.Properties[0].Value.SetItems[0]);
    Assert.AreEqual('akTop', F.Root.Properties[0].Value.SetItems[1]);
    Assert.AreEqual('akRight', F.Root.Properties[0].Value.SetItems[2]);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_EmptySet;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Font.Style = []'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvSet, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(F.Root.Properties[0].Value.SetItems)));
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_BinaryData;
var
  F: TFormFile;
begin
  F := FParser.Parse('object f: TF'#13#10'  Data = {0A54FF}'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvBinary, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(3), NativeInt(Length(F.Root.Properties[0].Value.BinaryData)));
    Assert.AreEqual(Byte($0A), F.Root.Properties[0].Value.BinaryData[0]);
    Assert.AreEqual(Byte($54), F.Root.Properties[0].Value.BinaryData[1]);
    Assert.AreEqual(Byte($FF), F.Root.Properties[0].Value.BinaryData[2]);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_ListValue;
var
  F: TFormFile;
begin
  F := FParser.Parse(
    'object f: TF'#13#10 +
    '  Items.Strings = ('#13#10 +
    '    ''Item 1'''#13#10 +
    '    ''Item 2'''#13#10 +
    '    ''Item 3'')'#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual(fvList, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(3), F.Root.Properties[0].Value.ListItems.Count);
    Assert.AreEqual('Item 1', F.Root.Properties[0].Value.ListItems[0].StringValue);
    Assert.AreEqual('Item 2', F.Root.Properties[0].Value.ListItems[1].StringValue);
    Assert.AreEqual('Item 3', F.Root.Properties[0].Value.ListItems[2].StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_NestedObjects;
var
  F: TFormFile;
begin
  F := FParser.Parse(
    'object frmMain: TfrmMain'#13#10 +
    '  Caption = ''Main'''#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    Left = 0'#13#10 +
    '    object Button1: TButton'#13#10 +
    '      Caption = ''Click'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual(NativeInt(1), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(1), F.Root.Children.Count);
    Assert.AreEqual('Panel1', F.Root.Children[0].Name);
    Assert.AreEqual('TPanel', F.Root.Children[0].ClassName_);
    Assert.AreEqual(NativeInt(1), F.Root.Children[0].Children.Count);
    Assert.AreEqual('Button1', F.Root.Children[0].Children[0].Name);
    Assert.AreEqual('Click', F.Root.Children[0].Children[0].Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_InheritedForm;
var
  F: TFormFile;
begin
  F := FParser.Parse('inherited frmChild: TfrmChild'#13#10'  Caption = ''Child'''#13#10'end'#13#10);
  try
    Assert.AreEqual(okInherited, F.Root.ObjectKind);
    Assert.AreEqual('frmChild', F.Root.Name);
    Assert.AreEqual('TfrmChild', F.Root.ClassName_);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_InlineForm;
var
  F: TFormFile;
begin
  F := FParser.Parse('inline frmEmbed: TfrmEmbed'#13#10'end'#13#10);
  try
    Assert.AreEqual(okInline, F.Root.ObjectKind);
    Assert.AreEqual('frmEmbed', F.Root.Name);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_CollectionValue;
var
  F: TFormFile;
begin
  F := FParser.Parse(
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
  try
    Assert.AreEqual(fvCollection, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(2), F.Root.Properties[0].Value.CollectionItems.Count);
    Assert.AreEqual('Col 1', F.Root.Properties[0].Value.CollectionItems[0].Properties[0].Value.StringValue);
    Assert.AreEqual(NativeInt(2), F.Root.Properties[0].Value.CollectionItems[0].Properties.Count);
    Assert.AreEqual('Col 2', F.Root.Properties[0].Value.CollectionItems[1].Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_TypedCollectionItems;
var
  F: TFormFile;
begin
  F := FParser.Parse(
    'object f: TF'#13#10 +
    '  Buttons = <'#13#10 +
    '    item TToolButton'#13#10 +
    '      Caption = ''Open'''#13#10 +
    '    end'#13#10 +
    '    item TToolButton'#13#10 +
    '      Caption = ''Save'''#13#10 +
    '    end>'#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual(fvCollection, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(2), F.Root.Properties[0].Value.CollectionItems.Count);
    Assert.AreEqual('TToolButton', F.Root.Properties[0].Value.CollectionItems[0].ClassName_);
    Assert.AreEqual('Open', F.Root.Properties[0].Value.CollectionItems[0].Properties[0].Value.StringValue);
    Assert.AreEqual('TToolButton', F.Root.Properties[0].Value.CollectionItems[1].ClassName_);
    Assert.AreEqual('Save', F.Root.Properties[0].Value.CollectionItems[1].Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_MixedCollectionItems;
var
  F: TFormFile;
begin
  // Mix of bare 'item' and typed 'item ClassName'
  F := FParser.Parse(
    'object f: TF'#13#10 +
    '  Items = <'#13#10 +
    '    item'#13#10 +
    '      Caption = ''Bare'''#13#10 +
    '    end'#13#10 +
    '    item TSpecialItem'#13#10 +
    '      Caption = ''Typed'''#13#10 +
    '    end>'#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual(NativeInt(2), F.Root.Properties[0].Value.CollectionItems.Count);
    Assert.AreEqual('', F.Root.Properties[0].Value.CollectionItems[0].ClassName_);
    Assert.AreEqual('TSpecialItem', F.Root.Properties[0].Value.CollectionItems[1].ClassName_);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_MultipleProperties;
var
  F: TFormFile;
begin
  F := FParser.Parse(
    'object f: TF'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 10'#13#10 +
    '  Caption = ''Test'''#13#10 +
    '  Color = clBtnFace'#13#10 +
    '  Visible = True'#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual(NativeInt(5), F.Root.Properties.Count);
    Assert.AreEqual('Left', F.Root.Properties[0].Name);
    Assert.AreEqual('Top', F.Root.Properties[1].Name);
    Assert.AreEqual('Caption', F.Root.Properties[2].Name);
    Assert.AreEqual('Color', F.Root.Properties[3].Name);
    Assert.AreEqual('Visible', F.Root.Properties[4].Name);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_RealWorldForm;
var
  F: TFormFile;
begin
  F := FParser.Parse(
    'object frmMain: TfrmMain'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Caption = ''Delphi-Lexer Tokenizer Debug Utility'''#13#10 +
    '  ClientHeight = 848'#13#10 +
    '  ClientWidth = 997'#13#10 +
    '  Color = clBtnFace'#13#10 +
    '  Font.Charset = DEFAULT_CHARSET'#13#10 +
    '  Font.Color = clWindowText'#13#10 +
    '  Font.Height = -12'#13#10 +
    '  Font.Name = ''Segoe UI'''#13#10 +
    '  Font.Style = []'#13#10 +
    '  Position = poScreenCenter'#13#10 +
    '  OnCreate = FormCreate'#13#10 +
    '  DesignSize = ('#13#10 +
    '    997'#13#10 +
    '    848)'#13#10 +
    '  TextHeight = 15'#13#10 +
    '  object labSourceCode: TLabel'#13#10 +
    '    Left = 8'#13#10 +
    '    Top = 11'#13#10 +
    '    Width = 104'#13#10 +
    '    Height = 15'#13#10 +
    '    Caption = ''Source To Tokenize:'''#13#10 +
    '  end'#13#10 +
    '  object butTokenize: TButton'#13#10 +
    '    Left = 8'#13#10 +
    '    Top = 272'#13#10 +
    '    Width = 100'#13#10 +
    '    Height = 25'#13#10 +
    '    Caption = ''Tokenize'''#13#10 +
    '    TabOrder = 1'#13#10 +
    '    OnClick = butTokenizeClick'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    Assert.AreEqual('frmMain', F.Root.Name);
    Assert.AreEqual('TfrmMain', F.Root.ClassName_);
    Assert.AreEqual(NativeInt(15), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(2), F.Root.Children.Count);

    Assert.AreEqual('Font.Name', F.Root.Properties[9].Name);
    Assert.AreEqual('Segoe UI', F.Root.Properties[9].Value.StringValue);

    Assert.AreEqual(fvSet, F.Root.Properties[10].Value.Kind);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(F.Root.Properties[10].Value.SetItems)));

    Assert.AreEqual(fvList, F.Root.Properties[13].Value.Kind);
    Assert.AreEqual(NativeInt(2), F.Root.Properties[13].Value.ListItems.Count);

    Assert.AreEqual('labSourceCode', F.Root.Children[0].Name);
    Assert.AreEqual('TLabel', F.Root.Children[0].ClassName_);
    Assert.AreEqual('butTokenize', F.Root.Children[1].Name);
    Assert.AreEqual('TButton', F.Root.Children[1].ClassName_);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_TruncatedMissingEnd;
var
  F: TFormFile;
begin
  // Object without closing 'end' -- should not crash
  F := nil;
  try
    F := FParser.Parse('object f: TF'#13#10'  Left = 0'#13#10);
    // Parser should handle gracefully (consume until EOF)
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('f', F.Root.Name);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_TruncatedMissingValue;
var
  F: TFormFile;
begin
  // Property with = but value is just 'end' keyword (parsed as identifier)
  // Parser is lenient: treats 'end' as the value, object ends up unclosed
  // Key assertion: no access violation, no crash
  F := FParser.Parse('object f: TF'#13#10'  Left ='#13#10'end'#13#10);
  try
    Assert.IsNotNull(F.Root);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_TruncatedMissingClassName;
begin
  // Object without class name -- should raise, not crash with AV
  Assert.WillRaise(
    procedure
    var
      F: TFormFile;
    begin
      F := FParser.Parse('object f'#13#10'end'#13#10);
      F.Free;
    end);
end;

procedure TDfmParserTests.Parse_EmptyInput;
var
  F: TFormFile;
begin
  F := FParser.Parse('');
  try
    Assert.IsNull(F.Root, 'Empty input should produce nil root');
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_IncompleteHexData;
var
  F: TFormFile;
begin
  // Odd number of hex chars: {0A5} has 3 hex chars, last nibble dropped
  // Parser should not crash, binary data should contain 1 byte ($0A)
  F := FParser.Parse('object f: TF'#13#10'  Data = {0A5}'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvBinary, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(1), NativeInt(Length(F.Root.Properties[0].Value.BinaryData)), 'Odd hex chars: partial byte dropped');
    Assert.AreEqual(Byte($0A), F.Root.Properties[0].Value.BinaryData[0]);
  finally
    F.Free;
  end;
end;

procedure TDfmParserTests.Parse_CharLiteralLargeValue;
var
  F: TFormFile;
begin
  // #65 = 'A', should not crash
  F := FParser.Parse('object f: TF'#13#10'  Caption = #65'#13#10'end'#13#10);
  try
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('A', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDfmParserTests);

end.
