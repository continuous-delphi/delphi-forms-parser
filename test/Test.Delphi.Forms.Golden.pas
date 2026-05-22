unit Test.Delphi.Forms.Golden;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  Delphi.Forms,
  Delphi.Forms.Types;

type

  [TestFixture]
  TGoldenTests = class
  private
    FGoldenDir: string;
    function GoldenPath(const FileName: string): string;
    procedure AssertTextRoundTrip(const FileName: string);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure Golden_Minimal;
    [Test]
    procedure Golden_Nested;
    [Test]
    procedure Golden_AllValues;
    [Test]
    procedure Golden_InheritedForm;
    [Test]
    procedure Golden_Collections;
    [Test]
    procedure Golden_BinaryData;
    [Test]
    procedure Golden_Minimal_Structure;
    [Test]
    procedure Golden_Nested_Structure;
    [Test]
    procedure Golden_AllValues_Structure;
    [Test]
    procedure Golden_FmxForm;
    [Test]
    procedure Golden_FmxForm_Structure;
    [Test]
    procedure Golden_Empty;
    [Test]
    procedure Golden_Empty_Structure;
    [Test]
    procedure Golden_DeepNesting;
    [Test]
    procedure Golden_DeepNesting_Structure;
    [Test]
    procedure Golden_LargeBinary;
    [Test]
    procedure Golden_LargeBinary_Structure;
  end;

implementation

procedure TGoldenTests.Setup;
begin
  FGoldenDir := TPath.Combine(ExtractFileDir(ParamStr(0)), '..\..\golden');
  FGoldenDir := TPath.GetFullPath(FGoldenDir);
  if not TDirectory.Exists(FGoldenDir) then
    FGoldenDir := TPath.Combine(ExtractFileDir(ParamStr(0)), '..\..\..\test\golden');
  FGoldenDir := TPath.GetFullPath(FGoldenDir);
end;

function TGoldenTests.GoldenPath(const FileName: string): string;
begin
  Result := TPath.Combine(FGoldenDir, FileName);
end;

procedure TGoldenTests.AssertTextRoundTrip(const FileName: string);
var
  Path: string;
  Source: string;
  F: TFormFile;
  Output: string;
begin
  Path := GoldenPath(FileName);
  Assert.IsTrue(TFile.Exists(Path), 'Golden file not found: ' + Path);
  Source := TFile.ReadAllText(Path, TEncoding.UTF8);
  // Normalize to CRLF (golden files may have LF on disk before git normalization)
  Source := StringReplace(Source, #13#10, #10, [rfReplaceAll]);
  Source := StringReplace(Source, #10, #13#10, [rfReplaceAll]);
  F := TDelphiFormsParser.ParseText(Source);
  try
    Output := TDelphiFormsParser.WriteText(F);
    Assert.AreEqual(Source, Output, 'Round-trip failed for ' + FileName);
  finally
    F.Free;
  end;
end;

procedure TGoldenTests.Golden_Minimal;
begin
  AssertTextRoundTrip('minimal.dfm');
end;

procedure TGoldenTests.Golden_Nested;
begin
  AssertTextRoundTrip('nested.dfm');
end;

procedure TGoldenTests.Golden_AllValues;
begin
  AssertTextRoundTrip('all_values.dfm');
end;

procedure TGoldenTests.Golden_InheritedForm;
begin
  AssertTextRoundTrip('inherited_form.dfm');
end;

procedure TGoldenTests.Golden_Collections;
begin
  AssertTextRoundTrip('collections.dfm');
end;

procedure TGoldenTests.Golden_BinaryData;
begin
  AssertTextRoundTrip('binary_data.dfm');
end;

procedure TGoldenTests.Golden_Minimal_Structure;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseFile(GoldenPath('minimal.dfm'));
  try
    Assert.AreEqual('frmMinimal', F.Root.Name);
    Assert.AreEqual('TfrmMinimal', F.Root.ClassName_);
    Assert.AreEqual(okObject, F.Root.ObjectKind);
    Assert.AreEqual(NativeInt(2), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(0), F.Root.Children.Count);
  finally
    F.Free;
  end;
end;

procedure TGoldenTests.Golden_Nested_Structure;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseFile(GoldenPath('nested.dfm'));
  try
    Assert.AreEqual('frmNested', F.Root.Name);
    Assert.AreEqual(NativeInt(3), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(2), F.Root.Children.Count);
    Assert.AreEqual('Panel1', F.Root.Children[0].Name);
    Assert.AreEqual('TPanel', F.Root.Children[0].ClassName_);
    Assert.AreEqual(NativeInt(2), F.Root.Children[0].Children.Count);
    Assert.AreEqual('Button1', F.Root.Children[0].Children[0].Name);
    Assert.AreEqual('Label1', F.Root.Children[0].Children[1].Name);
    Assert.AreEqual('StatusBar1', F.Root.Children[1].Name);
  finally
    F.Free;
  end;
end;

procedure TGoldenTests.Golden_AllValues_Structure;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseFile(GoldenPath('all_values.dfm'));
  try
    Assert.AreEqual('frmAllValues', F.Root.Name);
    // Check various value types exist
    Assert.AreEqual(fvString, F.Root.Properties[2].Value.Kind, 'Caption should be string');
    Assert.AreEqual(fvIdentifier, F.Root.Properties[5].Value.Kind, 'Color should be ident');
    Assert.AreEqual(fvSet, F.Root.Properties[10].Value.Kind, 'Font.Style should be set');
    Assert.AreEqual(fvBoolean, F.Root.Properties[12].Value.Kind, 'Visible should be boolean');
    Assert.AreEqual(fvSet, F.Root.Properties[13].Value.Kind, 'Anchors should be set');
    Assert.AreEqual(fvList, F.Root.Properties[14].Value.Kind, 'DesignSize should be list');
    Assert.AreEqual(fvInteger, F.Root.Properties[15].Value.Kind, 'HexColor should be integer');
    Assert.AreEqual(fvInteger, F.Root.Properties[16].Value.Kind, 'NegativeTop should be integer');
    Assert.AreEqual(NativeInt(1), F.Root.Children.Count);
    Assert.AreEqual('Memo1', F.Root.Children[0].Name);
  finally
    F.Free;
  end;
end;

procedure TGoldenTests.Golden_FmxForm;
begin
  AssertTextRoundTrip('fmx_form.fmx');
end;

procedure TGoldenTests.Golden_FmxForm_Structure;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseFile(GoldenPath('fmx_form.fmx'));
  try
    Assert.AreEqual('frmFmxDemo', F.Root.Name);
    Assert.AreEqual('TfrmFmxDemo', F.Root.ClassName_);
    Assert.AreEqual(NativeInt(1), F.Root.Children.Count);
    Assert.AreEqual('Layout1', F.Root.Children[0].Name);
    Assert.AreEqual('TLayout', F.Root.Children[0].ClassName_);
    Assert.AreEqual(NativeInt(3), F.Root.Children[0].Children.Count);
    Assert.AreEqual('Button1', F.Root.Children[0].Children[0].Name);
    Assert.AreEqual('Label1', F.Root.Children[0].Children[1].Name);
    Assert.AreEqual('Rectangle1', F.Root.Children[0].Children[2].Name);
    // Verify FMX float properties parsed correctly
    Assert.AreEqual(fvFloat, F.Root.Properties[3].Value.Kind, 'ClientHeight should be float');
    Assert.AreEqual(fvFloat, F.Root.Properties[4].Value.Kind, 'ClientWidth should be float');
    // Verify FMX-specific dotted float properties
    Assert.AreEqual('Position.X', F.Root.Children[0].Children[0].Properties[0].Name);
    Assert.AreEqual(fvFloat, F.Root.Children[0].Children[0].Properties[0].Value.Kind, 'Position.X should be float');
    // Verify Opacity float
    Assert.AreEqual('Opacity', F.Root.Children[0].Children[2].Properties[7].Name);
    Assert.AreEqual(fvFloat, F.Root.Children[0].Children[2].Properties[7].Value.Kind, 'Opacity should be float');
  finally
    F.Free;
  end;
end;

procedure TGoldenTests.Golden_Empty;
begin
  AssertTextRoundTrip('empty.dfm');
end;

procedure TGoldenTests.Golden_Empty_Structure;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseFile(GoldenPath('empty.dfm'));
  try
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('frmEmpty', F.Root.Name);
    Assert.AreEqual('TfrmEmpty', F.Root.ClassName_);
    Assert.AreEqual(NativeInt(0), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(0), F.Root.Children.Count);
  finally
    F.Free;
  end;
end;

procedure TGoldenTests.Golden_DeepNesting;
begin
  AssertTextRoundTrip('deep_nesting.dfm');
end;

procedure TGoldenTests.Golden_DeepNesting_Structure;
var
  F: TFormFile;
  Node: TFormObject;
  Depth: Integer;
begin
  F := TDelphiFormsParser.ParseFile(GoldenPath('deep_nesting.dfm'));
  try
    Assert.AreEqual('frmDeep', F.Root.Name);
    // Walk down 12 levels: root -> Level1..Level11 -> Leaf
    Node := F.Root;
    Depth := 0;
    while Node.Children.Count > 0 do
    begin
      Node := Node.Children[0];
      Inc(Depth);
    end;
    Assert.AreEqual(12, Depth, 'Should reach 12 levels deep (11 panels + 1 button)');
    Assert.AreEqual('Leaf', Node.Name);
    Assert.AreEqual('TButton', Node.ClassName_);
    Assert.AreEqual('Deepest', Node.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TGoldenTests.Golden_LargeBinary;
begin
  AssertTextRoundTrip('large_binary.dfm');
end;

procedure TGoldenTests.Golden_LargeBinary_Structure;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseFile(GoldenPath('large_binary.dfm'));
  try
    Assert.AreEqual('frmLargeBinary', F.Root.Name);
    Assert.AreEqual(NativeInt(1), F.Root.Children.Count);
    Assert.AreEqual('Image1', F.Root.Children[0].Name);
    // Picture.Data should be binary with 1024 bytes
    Assert.AreEqual(fvBinary, F.Root.Children[0].Properties[2].Value.Kind);
    Assert.AreEqual(NativeInt(1024), NativeInt(Length(F.Root.Children[0].Properties[2].Value.BinaryData)), 'Binary data should be 1024 bytes');
    // Verify first and last bytes from the known seed
    Assert.AreEqual(Byte($A2), F.Root.Children[0].Properties[2].Value.BinaryData[0], 'First byte');
    Assert.AreEqual(Byte($11), F.Root.Children[0].Properties[2].Value.BinaryData[1023], 'Last byte');
  finally
    F.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGoldenTests);

end.
