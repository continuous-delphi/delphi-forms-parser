unit Test.Delphi.Forms.BinaryReader;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  Delphi.Forms.Types,
  Delphi.Forms.BinaryReader;

type

  [TestFixture]
  TDfmBinaryReaderTests = class
  private
    FReader: TDfmBinaryReader;
    function BuildMinimalBinary(const ClassName, ObjName: string): TBytes;
    function BuildBinaryWithProperty(const ClassName, ObjName, PropName: string; const ValueBytes: TBytes): TBytes;
    procedure AppendByte(var Data: TBytes; B: Byte);
    procedure AppendShortString(var Data: TBytes; const S: string);
    procedure AppendBytes(var Data: TBytes; const B: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Read_MinimalObject;
    [Test]
    procedure Read_WithFFPrefix;
    [Test]
    procedure Read_Int8Property;
    [Test]
    procedure Read_Int16Property;
    [Test]
    procedure Read_Int32Property;
    [Test]
    procedure Read_StringProperty;
    [Test]
    procedure Read_LStringProperty;
    [Test]
    procedure Read_IdentProperty;
    [Test]
    procedure Read_BooleanFalse;
    [Test]
    procedure Read_BooleanTrue;
    [Test]
    procedure Read_SetProperty;
    [Test]
    procedure Read_BinaryProperty;
    [Test]
    procedure Read_ListProperty;
    [Test]
    procedure Read_NestedChild;
    [Test]
    procedure Read_MultipleProperties;
    [Test]
    procedure Read_UTF8StringProperty;
    [Test]
    procedure Read_InvalidSignature_Raises;
    [Test]
    procedure Read_TruncatedStream_Raises;
    [Test]
    procedure Read_UnknownValueType_Raises;
  end;

implementation

procedure TDfmBinaryReaderTests.Setup;
begin
  FReader := TDfmBinaryReader.Create;
end;

procedure TDfmBinaryReaderTests.TearDown;
begin
  FReader.Free;
end;

procedure TDfmBinaryReaderTests.AppendByte(var Data: TBytes; B: Byte);
var
  Len: Integer;
begin
  Len := Length(Data);
  SetLength(Data, Len + 1);
  Data[Len] := B;
end;

procedure TDfmBinaryReaderTests.AppendShortString(var Data: TBytes; const S: string);
var
  I: Integer;
begin
  AppendByte(Data, Byte(Length(S)));
  for I := 1 to Length(S) do
    AppendByte(Data, Byte(S[I]));
end;

procedure TDfmBinaryReaderTests.AppendBytes(var Data: TBytes; const B: TBytes);
var
  Len: Integer;
begin
  Len := Length(Data);
  SetLength(Data, Len + Length(B));
  if Length(B) > 0 then
    Move(B[0], Data[Len], Length(B));
end;

function TDfmBinaryReaderTests.BuildMinimalBinary(const ClassName, ObjName: string): TBytes;
begin
  // TPF0 + ClassName(short) + ObjName(short) + 0(end props) + 0(end children)
  Result := nil;
  AppendBytes(Result, TBytes.Create(Ord('T'), Ord('P'), Ord('F'), Ord('0')));
  AppendShortString(Result, ClassName);
  AppendShortString(Result, ObjName);
  AppendByte(Result, 0); // end of properties
  AppendByte(Result, 0); // end of children
end;

function TDfmBinaryReaderTests.BuildBinaryWithProperty(const ClassName, ObjName, PropName: string; const ValueBytes: TBytes): TBytes;
begin
  Result := nil;
  AppendBytes(Result, TBytes.Create(Ord('T'), Ord('P'), Ord('F'), Ord('0')));
  AppendShortString(Result, ClassName);
  AppendShortString(Result, ObjName);
  // Property: name + value
  AppendShortString(Result, PropName);
  AppendBytes(Result, ValueBytes);
  AppendByte(Result, 0); // end of properties
  AppendByte(Result, 0); // end of children
end;

procedure TDfmBinaryReaderTests.Read_MinimalObject;
var
  Data: TBytes;
  F: TFormFile;
begin
  Data := BuildMinimalBinary('TForm', 'Form1');
  F := FReader.ReadFromBytes(Data);
  try
    Assert.IsNotNull(F.Root);
    Assert.AreEqual('Form1', F.Root.Name);
    Assert.AreEqual('TForm', F.Root.ClassName_);
    Assert.AreEqual(okObject, F.Root.ObjectKind);
    Assert.AreEqual(NativeInt(0), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(0), F.Root.Children.Count);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_WithFFPrefix;
var
  Data: TBytes;
  MinData: TBytes;
  F: TFormFile;
begin
  MinData := BuildMinimalBinary('TForm', 'Form1');
  Data := nil;
  AppendByte(Data, $FF);
  AppendBytes(Data, MinData);
  F := FReader.ReadFromBytes(Data);
  try
    Assert.AreEqual('Form1', F.Root.Name);
    Assert.AreEqual('TForm', F.Root.ClassName_);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_Int8Property;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  ValBytes := TBytes.Create(vaInt8, 42);
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Left', ValBytes));
  try
    Assert.AreEqual(NativeInt(1), F.Root.Properties.Count);
    Assert.AreEqual('Left', F.Root.Properties[0].Name);
    Assert.AreEqual(fvInteger, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Int64(42), F.Root.Properties[0].Value.IntValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_Int16Property;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaInt16 + 1000 (little-endian: $E8, $03)
  ValBytes := TBytes.Create(vaInt16, $E8, $03);
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Width', ValBytes));
  try
    Assert.AreEqual(fvInteger, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Int64(1000), F.Root.Properties[0].Value.IntValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_Int32Property;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaInt32 + 100000 (little-endian: $A0, $86, $01, $00)
  ValBytes := TBytes.Create(vaInt32, $A0, $86, $01, $00);
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Tag', ValBytes));
  try
    Assert.AreEqual(fvInteger, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(Int64(100000), F.Root.Properties[0].Value.IntValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_StringProperty;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaString + ShortString "Hello"
  ValBytes := TBytes.Create(vaString, 5, Ord('H'), Ord('e'), Ord('l'), Ord('l'), Ord('o'));
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Caption', ValBytes));
  try
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('Hello', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_LStringProperty;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaLString + Int32 length (3) + "abc"
  ValBytes := TBytes.Create(vaLString, 3, 0, 0, 0, Ord('a'), Ord('b'), Ord('c'));
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Hint', ValBytes));
  try
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('abc', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_IdentProperty;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaIdent + ShortString "clBtnFace"
  ValBytes := nil;
  AppendByte(ValBytes, vaIdent);
  AppendShortString(ValBytes, 'clBtnFace');
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Color', ValBytes));
  try
    Assert.AreEqual(fvIdentifier, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('clBtnFace', F.Root.Properties[0].Value.IdentValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_BooleanFalse;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  ValBytes := TBytes.Create(vaFalse);
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Visible', ValBytes));
  try
    Assert.AreEqual(fvBoolean, F.Root.Properties[0].Value.Kind);
    Assert.IsFalse(F.Root.Properties[0].Value.BoolValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_BooleanTrue;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  ValBytes := TBytes.Create(vaTrue);
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Visible', ValBytes));
  try
    Assert.AreEqual(fvBoolean, F.Root.Properties[0].Value.Kind);
    Assert.IsTrue(F.Root.Properties[0].Value.BoolValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_SetProperty;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaSet + "akLeft"(short) + "akTop"(short) + 0(end)
  ValBytes := nil;
  AppendByte(ValBytes, vaSet);
  AppendShortString(ValBytes, 'akLeft');
  AppendShortString(ValBytes, 'akTop');
  AppendByte(ValBytes, 0); // empty string terminates set
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Anchors', ValBytes));
  try
    Assert.AreEqual(fvSet, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(2), NativeInt(Length(F.Root.Properties[0].Value.SetItems)));
    Assert.AreEqual('akLeft', F.Root.Properties[0].Value.SetItems[0]);
    Assert.AreEqual('akTop', F.Root.Properties[0].Value.SetItems[1]);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_BinaryProperty;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaBinary + Int32 length (3) + 3 bytes
  ValBytes := TBytes.Create(vaBinary, 3, 0, 0, 0, $0A, $54, $FF);
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Data', ValBytes));
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

procedure TDfmBinaryReaderTests.Read_ListProperty;
var
  F: TFormFile;
  ValBytes: TBytes;
begin
  // vaList + vaString "Item1" + vaString "Item2" + 0(end)
  ValBytes := nil;
  AppendByte(ValBytes, vaList);
  AppendByte(ValBytes, vaString);
  AppendShortString(ValBytes, 'Item1');
  AppendByte(ValBytes, vaString);
  AppendShortString(ValBytes, 'Item2');
  AppendByte(ValBytes, 0); // end of list
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Items', ValBytes));
  try
    Assert.AreEqual(fvList, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual(NativeInt(2), F.Root.Properties[0].Value.ListItems.Count);
    Assert.AreEqual('Item1', F.Root.Properties[0].Value.ListItems[0].StringValue);
    Assert.AreEqual('Item2', F.Root.Properties[0].Value.ListItems[1].StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_NestedChild;
var
  Data: TBytes;
  F: TFormFile;
begin
  Data := nil;
  AppendBytes(Data, TBytes.Create(Ord('T'), Ord('P'), Ord('F'), Ord('0')));
  AppendShortString(Data, 'TForm');
  AppendShortString(Data, 'Form1');
  // Property: Left = 0
  AppendShortString(Data, 'Left');
  AppendByte(Data, vaInt8);
  AppendByte(Data, 0);
  AppendByte(Data, 0); // end of properties
  // Child object: Button1: TButton
  AppendShortString(Data, 'TButton');
  AppendShortString(Data, 'Button1');
  // Child property: Caption = 'Click'
  AppendShortString(Data, 'Caption');
  AppendByte(Data, vaString);
  AppendShortString(Data, 'Click');
  AppendByte(Data, 0); // end child properties
  AppendByte(Data, 0); // end child children
  AppendByte(Data, 0); // end parent children

  F := FReader.ReadFromBytes(Data);
  try
    Assert.AreEqual('Form1', F.Root.Name);
    Assert.AreEqual(NativeInt(1), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(1), F.Root.Children.Count);
    Assert.AreEqual('Button1', F.Root.Children[0].Name);
    Assert.AreEqual('TButton', F.Root.Children[0].ClassName_);
    Assert.AreEqual('Click', F.Root.Children[0].Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_MultipleProperties;
var
  Data: TBytes;
  F: TFormFile;
begin
  Data := nil;
  AppendBytes(Data, TBytes.Create(Ord('T'), Ord('P'), Ord('F'), Ord('0')));
  AppendShortString(Data, 'TForm');
  AppendShortString(Data, 'f');
  // Left = 10
  AppendShortString(Data, 'Left');
  AppendByte(Data, vaInt8);
  AppendByte(Data, 10);
  // Top = 20
  AppendShortString(Data, 'Top');
  AppendByte(Data, vaInt8);
  AppendByte(Data, 20);
  // Visible = True
  AppendShortString(Data, 'Visible');
  AppendByte(Data, vaTrue);
  AppendByte(Data, 0); // end properties
  AppendByte(Data, 0); // end children

  F := FReader.ReadFromBytes(Data);
  try
    Assert.AreEqual(NativeInt(3), F.Root.Properties.Count);
    Assert.AreEqual('Left', F.Root.Properties[0].Name);
    Assert.AreEqual(Int64(10), F.Root.Properties[0].Value.IntValue);
    Assert.AreEqual('Top', F.Root.Properties[1].Name);
    Assert.AreEqual(Int64(20), F.Root.Properties[1].Value.IntValue);
    Assert.AreEqual('Visible', F.Root.Properties[2].Name);
    Assert.IsTrue(F.Root.Properties[2].Value.BoolValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_UTF8StringProperty;
var
  F: TFormFile;
  ValBytes: TBytes;
  Utf8Bytes: TBytes;
begin
  // vaUTF8String + Int32 length + UTF-8 bytes for "Hello"
  Utf8Bytes := TEncoding.UTF8.GetBytes('Hello');
  ValBytes := nil;
  AppendByte(ValBytes, vaUTF8String);
  AppendByte(ValBytes, Byte(Length(Utf8Bytes)));
  AppendByte(ValBytes, 0);
  AppendByte(ValBytes, 0);
  AppendByte(ValBytes, 0);
  AppendBytes(ValBytes, Utf8Bytes);
  F := FReader.ReadFromBytes(BuildBinaryWithProperty('TForm', 'f', 'Caption', ValBytes));
  try
    Assert.AreEqual(fvString, F.Root.Properties[0].Value.Kind);
    Assert.AreEqual('Hello', F.Root.Properties[0].Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TDfmBinaryReaderTests.Read_InvalidSignature_Raises;
begin
  Assert.WillRaise(
    procedure
    var
      F: TFormFile;
    begin
      F := FReader.ReadFromBytes(TBytes.Create($00, $00, $00, $00, $00));
      F.Free;
    end,
    Exception);
end;

procedure TDfmBinaryReaderTests.Read_TruncatedStream_Raises;
var
  Data: TBytes;
begin
  // Valid signature but stream ends mid-object (no class name bytes)
  Data := TBytes.Create(Ord('T'), Ord('P'), Ord('F'), Ord('0'), 5);
  // Class name length says 5 but no bytes follow
  Assert.WillRaise(
    procedure
    var
      F: TFormFile;
    begin
      F := FReader.ReadFromBytes(Data);
      F.Free;
    end);
end;

procedure TDfmBinaryReaderTests.Read_UnknownValueType_Raises;
var
  Data: TBytes;
begin
  Data := nil;
  AppendBytes(Data, TBytes.Create(Ord('T'), Ord('P'), Ord('F'), Ord('0')));
  AppendShortString(Data, 'TF');
  AppendShortString(Data, 'f');
  AppendShortString(Data, 'Prop');
  AppendByte(Data, 250); // unknown value type tag
  AppendByte(Data, 0); // end props
  AppendByte(Data, 0); // end children
  Assert.WillRaise(
    procedure
    var
      F: TFormFile;
    begin
      F := FReader.ReadFromBytes(Data);
      F.Free;
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TDfmBinaryReaderTests);

end.
