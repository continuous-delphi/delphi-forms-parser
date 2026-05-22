unit Test.Delphi.Forms.BinaryWriter;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  Delphi.Forms.Types,
  Delphi.Forms.BinaryReader,
  Delphi.Forms.BinaryWriter;

type

  [TestFixture]
  TDfmBinaryWriterTests = class
  private
    FWriter: TDfmBinaryWriter;
    FReader: TDfmBinaryReader;
    procedure AssertBinaryRoundTrip(FormFile: TFormFile);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Write_MinimalObject;
    [Test]
    procedure Write_StartsWithFFTPF0;
    [Test]
    procedure Write_Int8Property;
    [Test]
    procedure Write_Int16Property;
    [Test]
    procedure Write_Int32Property;
    [Test]
    procedure Write_StringProperty;
    [Test]
    procedure Write_BooleanProperties;
    [Test]
    procedure Write_IdentProperty;
    [Test]
    procedure Write_SetProperty;
    [Test]
    procedure Write_BinaryProperty;
    [Test]
    procedure Write_ListProperty;
    [Test]
    procedure Write_NestedChild;
    [Test]
    procedure Write_InheritedKind;
    [Test]
    procedure Write_InlineKind;
    [Test]
    procedure RoundTrip_ConstructedForm;
    [Test]
    procedure RoundTrip_MultipleProperties;
  end;

implementation

procedure TDfmBinaryWriterTests.Setup;
begin
  FWriter := TDfmBinaryWriter.Create;
  FReader := TDfmBinaryReader.Create;
end;

procedure TDfmBinaryWriterTests.TearDown;
begin
  FReader.Free;
  FWriter.Free;
end;

procedure TDfmBinaryWriterTests.AssertBinaryRoundTrip(FormFile: TFormFile);
var
  Bytes1: TBytes;
  F2: TFormFile;
  Bytes2: TBytes;
begin
  Bytes1 := FWriter.WriteToBytes(FormFile);
  F2 := FReader.ReadFromBytes(Bytes1);
  try
    Bytes2 := FWriter.WriteToBytes(F2);
    Assert.AreEqual(NativeInt(Length(Bytes1)), NativeInt(Length(Bytes2)), 'Round-trip byte length mismatch');
    Assert.IsTrue(CompareMem(@Bytes1[0], @Bytes2[0], Length(Bytes1)), 'Round-trip bytes differ');
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_MinimalObject;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'Form1';
    F.Root.ClassName_ := 'TForm';
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  // Verify by reading back
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual('Form1', F2.Root.Name);
    Assert.AreEqual('TForm', F2.Root.ClassName_);
    Assert.AreEqual(okObject, F2.Root.ObjectKind);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_StartsWithFFTPF0;
var
  F: TFormFile;
  Bytes: TBytes;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    Bytes := FWriter.WriteToBytes(F);
    Assert.AreEqual(Byte($FF), Bytes[0], 'First byte should be $FF');
    Assert.AreEqual(Byte(Ord('T')), Bytes[1]);
    Assert.AreEqual(Byte(Ord('P')), Bytes[2]);
    Assert.AreEqual(Byte(Ord('F')), Bytes[3]);
    Assert.AreEqual(Byte(Ord('0')), Bytes[4]);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_Int8Property;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
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
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(Int64(42), F2.Root.Properties[0].Value.IntValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_Int16Property;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvInteger);
    V.IntValue := 1000;
    F.Root.Properties.Add(TFormProperty.Create('Width', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(Int64(1000), F2.Root.Properties[0].Value.IntValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_Int32Property;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvInteger);
    V.IntValue := 100000;
    F.Root.Properties.Add(TFormProperty.Create('Tag', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(Int64(100000), F2.Root.Properties[0].Value.IntValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_StringProperty;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvString);
    V.StringValue := 'Hello World';
    F.Root.Properties.Add(TFormProperty.Create('Caption', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual('Hello World', F2.Root.Properties[0].Value.StringValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_BooleanProperties;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvBoolean);
    V.BoolValue := True;
    F.Root.Properties.Add(TFormProperty.Create('Visible', V));
    V := TFormValue.Create(fvBoolean);
    V.BoolValue := False;
    F.Root.Properties.Add(TFormProperty.Create('Enabled', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.IsTrue(F2.Root.Properties[0].Value.BoolValue);
    Assert.IsFalse(F2.Root.Properties[1].Value.BoolValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_IdentProperty;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvIdentifier);
    V.IdentValue := 'clBtnFace';
    F.Root.Properties.Add(TFormProperty.Create('Color', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual('clBtnFace', F2.Root.Properties[0].Value.IdentValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_SetProperty;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvSet);
    V.SetItems := TArray<string>.Create('akLeft', 'akTop');
    F.Root.Properties.Add(TFormProperty.Create('Anchors', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(NativeInt(2), NativeInt(Length(F2.Root.Properties[0].Value.SetItems)));
    Assert.AreEqual('akLeft', F2.Root.Properties[0].Value.SetItems[0]);
    Assert.AreEqual('akTop', F2.Root.Properties[0].Value.SetItems[1]);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_BinaryProperty;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvBinary);
    V.BinaryData := TBytes.Create($0A, $54, $FF);
    F.Root.Properties.Add(TFormProperty.Create('Data', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(NativeInt(3), NativeInt(Length(F2.Root.Properties[0].Value.BinaryData)));
    Assert.AreEqual(Byte($0A), F2.Root.Properties[0].Value.BinaryData[0]);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_ListProperty;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  V: TFormValue;
  Item: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvList);
    Item := TFormValue.Create(fvString);
    Item.StringValue := 'Item1';
    V.ListItems.Add(Item);
    Item := TFormValue.Create(fvString);
    Item.StringValue := 'Item2';
    V.ListItems.Add(Item);
    F.Root.Properties.Add(TFormProperty.Create('Items', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(fvList, F2.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(2), F2.Root.Properties[0].Value.ListItems.Count);
    Assert.AreEqual('Item1', F2.Root.Properties[0].Value.ListItems[0].StringValue);
    Assert.AreEqual('Item2', F2.Root.Properties[0].Value.ListItems[1].StringValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_NestedChild;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
  Child: TFormObject;
  V: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'Form1';
    F.Root.ClassName_ := 'TForm';
    Child := TFormObject.Create;
    Child.Name := 'Button1';
    Child.ClassName_ := 'TButton';
    V := TFormValue.Create(fvString);
    V.StringValue := 'Click';
    Child.Properties.Add(TFormProperty.Create('Caption', V));
    F.Root.Children.Add(Child);
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(NativeInt(1), F2.Root.Children.Count);
    Assert.AreEqual('Button1', F2.Root.Children[0].Name);
    Assert.AreEqual('TButton', F2.Root.Children[0].ClassName_);
    Assert.AreEqual('Click', F2.Root.Children[0].Properties[0].Value.StringValue);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_InheritedKind;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'frmChild';
    F.Root.ClassName_ := 'TfrmChild';
    F.Root.ObjectKind := okInherited;
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(okInherited, F2.Root.ObjectKind);
    Assert.AreEqual('frmChild', F2.Root.Name);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_InlineKind;
var
  F: TFormFile;
  Bytes: TBytes;
  F2: TFormFile;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'frmEmbed';
    F.Root.ClassName_ := 'TfrmEmbed';
    F.Root.ObjectKind := okInline;
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(okInline, F2.Root.ObjectKind);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.RoundTrip_ConstructedForm;
var
  F: TFormFile;
  V: TFormValue;
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
    V.StringValue := 'Main Form';
    F.Root.Properties.Add(TFormProperty.Create('Caption', V));

    V := TFormValue.Create(fvBoolean);
    V.BoolValue := True;
    F.Root.Properties.Add(TFormProperty.Create('Visible', V));

    V := TFormValue.Create(fvIdentifier);
    V.IdentValue := 'clBtnFace';
    F.Root.Properties.Add(TFormProperty.Create('Color', V));

    Child := TFormObject.Create;
    Child.Name := 'Button1';
    Child.ClassName_ := 'TButton';
    V := TFormValue.Create(fvString);
    V.StringValue := 'OK';
    Child.Properties.Add(TFormProperty.Create('Caption', V));
    F.Root.Children.Add(Child);

    AssertBinaryRoundTrip(F);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryWriterTests.RoundTrip_MultipleProperties;
var
  F: TFormFile;
  V: TFormValue;
  SetV: TFormValue;
  BinV: TFormValue;
  ListV: TFormValue;
  Item: TFormValue;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';

    V := TFormValue.Create(fvInteger);
    V.IntValue := -5;
    F.Root.Properties.Add(TFormProperty.Create('Neg', V));

    V := TFormValue.Create(fvInteger);
    V.IntValue := 50000;
    F.Root.Properties.Add(TFormProperty.Create('Big', V));

    SetV := TFormValue.Create(fvSet);
    SetV.SetItems := TArray<string>.Create('ssBold', 'ssItalic');
    F.Root.Properties.Add(TFormProperty.Create('Style', SetV));

    BinV := TFormValue.Create(fvBinary);
    BinV.BinaryData := TBytes.Create($DE, $AD, $BE, $EF);
    F.Root.Properties.Add(TFormProperty.Create('Data', BinV));

    ListV := TFormValue.Create(fvList);
    Item := TFormValue.Create(fvInteger);
    Item.IntValue := 100;
    ListV.ListItems.Add(Item);
    Item := TFormValue.Create(fvInteger);
    Item.IntValue := 200;
    ListV.ListItems.Add(Item);
    F.Root.Properties.Add(TFormProperty.Create('Values', ListV));

    AssertBinaryRoundTrip(F);
  finally
    F.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDfmBinaryWriterTests);

end.
