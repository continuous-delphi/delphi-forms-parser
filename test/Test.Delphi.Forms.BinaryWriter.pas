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
    [Test]
    procedure RoundTrip_PreservesInt32Tag;
    [Test]
    procedure RoundTrip_PreservesSingleTag;
    [Test]
    procedure RoundTrip_PreservesCurrencyTag;
    [Test]
    procedure RoundTrip_PreservesDateTag;
    [Test]
    procedure RoundTrip_PreservesShortStringTag;
    [Test]
    procedure RoundTrip_PreservesLStringTag;
    [Test]
    procedure RoundTrip_PreservesWStringTag;
    [Test]
    procedure RoundTrip_PreservesUStringTag;
    [Test]
    procedure RoundTrip_PreservesExtendedTag;
    [Test]
    procedure RoundTrip_PreservesCollectionItemIndex;
    [Test]
    procedure Write_SequentialIndicesWhenNotSet;
    [Test]
    procedure Write_ShortStringOver255_Raises;
    [Test]
    procedure RoundTrip_PreservesVaNil;
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

procedure AppendByte(var Data: TBytes; B: Byte);
var
  Len: Integer;
begin
  Len := Length(Data);
  SetLength(Data, Len + 1);
  Data[Len] := B;
end;

procedure AppendShortString(var Data: TBytes; const S: string);
var
  I: Integer;
begin
  AppendByte(Data, Byte(Length(S)));
  for I := 1 to Length(S) do
    AppendByte(Data, Byte(S[I]));
end;

procedure AppendBytes(var Data: TBytes; const B: TBytes);
var
  Len: Integer;
begin
  Len := Length(Data);
  SetLength(Data, Len + Length(B));
  if Length(B) > 0 then
    Move(B[0], Data[Len], Length(B));
end;

function BuildBinaryWithPropValue(const PropName: string; const ValueBytes: TBytes): TBytes;
begin
  Result := nil;
  AppendBytes(Result, TBytes.Create(Ord('T'), Ord('P'), Ord('F'), Ord('0')));
  AppendShortString(Result, 'TF');
  AppendShortString(Result, 'f');
  AppendShortString(Result, PropName);
  AppendBytes(Result, ValueBytes);
  AppendByte(Result, 0); // end properties
  AppendByte(Result, 0); // end children
end;

procedure AssertBinaryBytesRoundTrip(const OriginalData: TBytes; Reader: TDfmBinaryReader; Writer: TDfmBinaryWriter);
var
  F: TFormFile;
  OutputData: TBytes;
begin
  F := Reader.ReadFromBytes(OriginalData);
  try
    OutputData := Writer.WriteToBytes(F);
    // The writer adds $FF prefix; original may not have it
    // Compare from the TPF0 signature onward
    var OrigStart: Integer := 0;
    var OutStart: Integer := 0;
    if OriginalData[0] = $FF then OrigStart := 1;
    if OutputData[0] = $FF then OutStart := 1;
    var OrigLen: Integer := Length(OriginalData) - OrigStart;
    var OutLen: Integer := Length(OutputData) - OutStart;
    Assert.AreEqual(NativeInt(OrigLen), NativeInt(OutLen), 'Round-trip byte length mismatch');
    Assert.IsTrue(CompareMem(@OriginalData[OrigStart], @OutputData[OutStart], OrigLen), 'Round-trip bytes differ');
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesInt32Tag;
var
  ValBytes: TBytes;
begin
  // Force vaInt32 for a value that fits in vaInt8
  ValBytes := TBytes.Create(vaInt32, 42, 0, 0, 0);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Left', ValBytes), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesSingleTag;
var
  ValBytes: TBytes;
  S: Single;
begin
  S := 3.14;
  ValBytes := nil;
  AppendByte(ValBytes, vaSingle);
  SetLength(ValBytes, Length(ValBytes) + 4);
  Move(S, ValBytes[1], 4);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Scale', ValBytes), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesCurrencyTag;
var
  ValBytes: TBytes;
  C: Currency;
begin
  C := 99.95;
  ValBytes := nil;
  AppendByte(ValBytes, vaCurrency);
  SetLength(ValBytes, Length(ValBytes) + 8);
  Move(C, ValBytes[1], 8);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Price', ValBytes), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesDateTag;
var
  ValBytes: TBytes;
  D: Double;
begin
  D := 44000.5; // a TDateTime value
  ValBytes := nil;
  AppendByte(ValBytes, vaDate);
  SetLength(ValBytes, Length(ValBytes) + 8);
  Move(D, ValBytes[1], 8);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Created', ValBytes), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesShortStringTag;
var
  ValBytes: TBytes;
begin
  // vaString + ShortString "Hi"
  ValBytes := TBytes.Create(vaString, 2, Ord('H'), Ord('i'));
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Hint', ValBytes), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesLStringTag;
var
  ValBytes: TBytes;
begin
  // vaLString + Int32 len (3) + "abc"
  ValBytes := TBytes.Create(vaLString, 3, 0, 0, 0, Ord('a'), Ord('b'), Ord('c'));
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Hint', ValBytes), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesWStringTag;
var
  Data: TBytes;
  WBuf: TBytes;
begin
  // vaWString + Int32 charcount (2) + UTF-16LE "Hi"
  WBuf := TEncoding.Unicode.GetBytes('Hi');
  Data := nil;
  AppendByte(Data, vaWString);
  AppendByte(Data, 2); AppendByte(Data, 0); AppendByte(Data, 0); AppendByte(Data, 0); // Int32 = 2
  AppendBytes(Data, WBuf);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Caption', Data), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesUStringTag;
var
  Data: TBytes;
  WBuf: TBytes;
begin
  // vaUString + Int32 charcount (2) + UTF-16LE "Ok"
  WBuf := TEncoding.Unicode.GetBytes('Ok');
  Data := nil;
  AppendByte(Data, vaUString);
  AppendByte(Data, 2); AppendByte(Data, 0); AppendByte(Data, 0); AppendByte(Data, 0);
  AppendBytes(Data, WBuf);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Text', Data), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesCollectionItemIndex;
var
  Data: TBytes;
  ValBytes: TBytes;
begin
  // Build a collection with non-sequential indices (5, 10)
  ValBytes := nil;
  AppendByte(ValBytes, vaCollection);
  // Item with index 5
  AppendByte(ValBytes, vaInt8); AppendByte(ValBytes, 5); // index = 5
  AppendShortString(ValBytes, 'Caption');
  AppendByte(ValBytes, vaString); AppendShortString(ValBytes, 'A');
  AppendByte(ValBytes, 0); // end item props
  // Item with index 10
  AppendByte(ValBytes, vaInt8); AppendByte(ValBytes, 10); // index = 10
  AppendShortString(ValBytes, 'Caption');
  AppendByte(ValBytes, vaString); AppendShortString(ValBytes, 'B');
  AppendByte(ValBytes, 0); // end item props
  AppendByte(ValBytes, 0); // end collection

  Data := BuildBinaryWithPropValue('Items', ValBytes);
  // Read -> verify indices preserved -> write -> verify bytes match
  var F := FReader.ReadFromBytes(Data);
  try
    Assert.AreEqual(Int64(5), F.Root.Properties[0].Value.CollectionItems[0].ItemIndex, 'First item index');
    Assert.AreEqual(Int64(10), F.Root.Properties[0].Value.CollectionItems[1].ItemIndex, 'Second item index');
    AssertBinaryBytesRoundTrip(Data, FReader, FWriter);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_SequentialIndicesWhenNotSet;
var
  F: TFormFile;
  V: TFormValue;
  Item: TFormObject;
  Bytes: TBytes;
  F2: TFormFile;
begin
  // Programmatically constructed collection -- ItemIndex defaults to -1
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'f';
    F.Root.ClassName_ := 'TF';
    V := TFormValue.Create(fvCollection);
    Item := TFormObject.Create;
    Item.Properties.Add(TFormProperty.Create('A', TFormValue.Create(fvString)));
    Item.Properties[0].Value.StringValue := 'X';
    V.CollectionItems.Add(Item);
    Item := TFormObject.Create;
    Item.Properties.Add(TFormProperty.Create('A', TFormValue.Create(fvString)));
    Item.Properties[0].Value.StringValue := 'Y';
    V.CollectionItems.Add(Item);
    F.Root.Properties.Add(TFormProperty.Create('Items', V));
    Bytes := FWriter.WriteToBytes(F);
  finally
    F.Free;
  end;
  // Read back and verify sequential indices 0, 1
  F2 := FReader.ReadFromBytes(Bytes);
  try
    Assert.AreEqual(Int64(0), F2.Root.Properties[0].Value.CollectionItems[0].ItemIndex);
    Assert.AreEqual(Int64(1), F2.Root.Properties[0].Value.CollectionItems[1].ItemIndex);
  finally
    F2.Free;
  end;
end;

procedure TDfmBinaryWriterTests.Write_ShortStringOver255_Raises;
begin
  Assert.WillRaise(
    procedure
    var
      F: TFormFile;
    begin
      F := TFormFile.Create;
      try
        F.Root := TFormObject.Create;
        F.Root.Name := StringOfChar('X', 256);
        F.Root.ClassName_ := 'TF';
        FWriter.WriteToBytes(F);
      finally
        F.Free;
      end;
    end,
    Exception);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesVaNil;
var
  ValBytes: TBytes;
begin
  // vaNil is a single byte (tag 13), no payload
  ValBytes := TBytes.Create(vaNil);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('PopupMenu', ValBytes), FReader, FWriter);
end;

procedure TDfmBinaryWriterTests.RoundTrip_PreservesExtendedTag;
var
  Data: TBytes;
  ExtBytes: TBytes;
begin
  // vaExtended + 10 raw bytes (a known 80-bit extended value)
  ExtBytes := TBytes.Create($00, $00, $00, $00, $00, $00, $00, $C0, $00, $40); // 2.0 in 80-bit extended
  Data := nil;
  AppendByte(Data, vaExtended);
  AppendBytes(Data, ExtBytes);
  AssertBinaryBytesRoundTrip(BuildBinaryWithPropValue('Value', Data), FReader, FWriter);
end;

initialization
  TDUnitX.RegisterTestFixture(TDfmBinaryWriterTests);

end.
