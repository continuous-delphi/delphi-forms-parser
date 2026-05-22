unit Test.Delphi.Forms.Types;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms.Types;

type

  [TestFixture]
  TFormValueTests = class
  public
    [Test]
    procedure IntegerValue_StoresKindAndValue;
    [Test]
    procedure FloatValue_StoresKindAndValue;
    [Test]
    procedure StringValue_StoresKindAndValue;
    [Test]
    procedure BooleanValue_StoresKindAndValue;
    [Test]
    procedure IdentifierValue_StoresKindAndValue;
    [Test]
    procedure SetValue_StoresItems;
    [Test]
    procedure BinaryValue_StoresDataAndHex;
    [Test]
    procedure ListValue_CreatesOwnedList;
    [Test]
    procedure CollectionValue_CreatesOwnedList;
    [Test]
    procedure RawText_PreservedOnValue;
  end;

  [TestFixture]
  TFormPropertyTests = class
  public
    [Test]
    procedure Property_OwnsValue;
    [Test]
    procedure Property_StoresDottedName;
  end;

  [TestFixture]
  TFormObjectTests = class
  public
    [Test]
    procedure Object_DefaultsToOkObject;
    [Test]
    procedure Object_StoresNameAndClassName;
    [Test]
    procedure Object_OwnsPropertiesAndChildren;
    [Test]
    procedure Object_NestedChildren_NoLeaks;
    [Test]
    procedure Object_InheritedKind;
    [Test]
    procedure Object_InlineKind;
  end;

  [TestFixture]
  TFormFileTests = class
  public
    [Test]
    procedure FormFile_OwnsRoot;
    [Test]
    procedure FormFile_NilRoot_NoLeak;
    [Test]
    procedure FormFile_FullTree_NoLeaks;
  end;

implementation

{ TFormValueTests }

procedure TFormValueTests.IntegerValue_StoresKindAndValue;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvInteger);
  try
    V.IntValue := 42;
    Assert.AreEqual(fvInteger, V.Kind);
    Assert.AreEqual(Int64(42), V.IntValue);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.FloatValue_StoresKindAndValue;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvFloat);
  try
    V.FloatValue := 3.14;
    Assert.AreEqual(fvFloat, V.Kind);
    Assert.AreEqual(Extended(3.14), V.FloatValue, Extended(0.001));
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.StringValue_StoresKindAndValue;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvString);
  try
    V.StringValue := 'Hello World';
    Assert.AreEqual(fvString, V.Kind);
    Assert.AreEqual('Hello World', V.StringValue);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.BooleanValue_StoresKindAndValue;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvBoolean);
  try
    V.BoolValue := True;
    Assert.AreEqual(fvBoolean, V.Kind);
    Assert.IsTrue(V.BoolValue);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.IdentifierValue_StoresKindAndValue;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvIdentifier);
  try
    V.IdentValue := 'clBtnFace';
    Assert.AreEqual(fvIdentifier, V.Kind);
    Assert.AreEqual('clBtnFace', V.IdentValue);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.SetValue_StoresItems;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvSet);
  try
    V.SetItems := TArray<string>.Create('ssDouble', 'ssBold');
    Assert.AreEqual(fvSet, V.Kind);
    Assert.AreEqual(NativeInt(2), NativeInt(Length(V.SetItems)));
    Assert.AreEqual('ssDouble', V.SetItems[0]);
    Assert.AreEqual('ssBold', V.SetItems[1]);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.BinaryValue_StoresDataAndHex;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvBinary);
  try
    V.BinaryData := TBytes.Create($0A, $54, $4A);
    V.BinaryHex := '0A544A';
    Assert.AreEqual(fvBinary, V.Kind);
    Assert.AreEqual(NativeInt(3), NativeInt(Length(V.BinaryData)));
    Assert.AreEqual(Byte($0A), V.BinaryData[0]);
    Assert.AreEqual('0A544A', V.BinaryHex);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.ListValue_CreatesOwnedList;
var
  V: TFormValue;
  Child: TFormValue;
begin
  V := TFormValue.Create(fvList);
  try
    Assert.IsNotNull(V.ListItems, 'ListItems should be auto-created for fvList');
    Child := TFormValue.Create(fvString);
    Child.StringValue := 'item1';
    V.ListItems.Add(Child);
    Assert.AreEqual(NativeInt(1), V.ListItems.Count);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.CollectionValue_CreatesOwnedList;
var
  V: TFormValue;
  Item: TFormObject;
begin
  V := TFormValue.Create(fvCollection);
  try
    Assert.IsNotNull(V.CollectionItems, 'CollectionItems should be auto-created for fvCollection');
    Item := TFormObject.Create;
    Item.Name := 'Item0';
    V.CollectionItems.Add(Item);
    Assert.AreEqual(NativeInt(1), V.CollectionItems.Count);
  finally
    V.Free;
  end;
end;

procedure TFormValueTests.RawText_PreservedOnValue;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvInteger);
  try
    V.IntValue := 255;
    V.RawText := '$FF';
    Assert.AreEqual('$FF', V.RawText);
  finally
    V.Free;
  end;
end;

{ TFormPropertyTests }

procedure TFormPropertyTests.Property_OwnsValue;
var
  P: TFormProperty;
begin
  P := TFormProperty.Create('Caption', TFormValue.Create(fvString));
  try
    P.Value.StringValue := 'Hello';
    Assert.AreEqual('Caption', P.Name);
    Assert.AreEqual('Hello', P.Value.StringValue);
  finally
    P.Free;
  end;
end;

procedure TFormPropertyTests.Property_StoresDottedName;
var
  P: TFormProperty;
begin
  P := TFormProperty.Create('Font.Name', TFormValue.Create(fvString));
  try
    P.Value.StringValue := 'Segoe UI';
    Assert.AreEqual('Font.Name', P.Name);
  finally
    P.Free;
  end;
end;

{ TFormObjectTests }

procedure TFormObjectTests.Object_DefaultsToOkObject;
var
  Obj: TFormObject;
begin
  Obj := TFormObject.Create;
  try
    Assert.AreEqual(okObject, Obj.ObjectKind);
  finally
    Obj.Free;
  end;
end;

procedure TFormObjectTests.Object_StoresNameAndClassName;
var
  Obj: TFormObject;
begin
  Obj := TFormObject.Create;
  try
    Obj.Name := 'frmMain';
    Obj.ClassName_ := 'TfrmMain';
    Assert.AreEqual('frmMain', Obj.Name);
    Assert.AreEqual('TfrmMain', Obj.ClassName_);
  finally
    Obj.Free;
  end;
end;

procedure TFormObjectTests.Object_OwnsPropertiesAndChildren;
var
  Obj: TFormObject;
begin
  Obj := TFormObject.Create;
  try
    Assert.IsNotNull(Obj.Properties);
    Assert.IsNotNull(Obj.Children);
    Obj.Properties.Add(TFormProperty.Create('Left', TFormValue.Create(fvInteger)));
    Obj.Properties[0].Value.IntValue := 0;
    Obj.Children.Add(TFormObject.Create);
    Obj.Children[0].Name := 'Button1';
    Assert.AreEqual(NativeInt(1), Obj.Properties.Count);
    Assert.AreEqual(NativeInt(1), Obj.Children.Count);
  finally
    Obj.Free;
  end;
end;

procedure TFormObjectTests.Object_NestedChildren_NoLeaks;
var
  Root: TFormObject;
  Child: TFormObject;
  GrandChild: TFormObject;
begin
  Root := TFormObject.Create;
  try
    Root.Name := 'frmMain';
    Root.ClassName_ := 'TfrmMain';

    Child := TFormObject.Create;
    Child.Name := 'Panel1';
    Child.ClassName_ := 'TPanel';
    Child.Properties.Add(TFormProperty.Create('Caption', TFormValue.Create(fvString)));
    Child.Properties[0].Value.StringValue := 'Panel';
    Root.Children.Add(Child);

    GrandChild := TFormObject.Create;
    GrandChild.Name := 'Button1';
    GrandChild.ClassName_ := 'TButton';
    GrandChild.Properties.Add(TFormProperty.Create('Left', TFormValue.Create(fvInteger)));
    GrandChild.Properties[0].Value.IntValue := 8;
    Child.Children.Add(GrandChild);

    Assert.AreEqual(NativeInt(1), Root.Children.Count);
    Assert.AreEqual(NativeInt(1), Root.Children[0].Children.Count);
    Assert.AreEqual('Button1', Root.Children[0].Children[0].Name);
  finally
    Root.Free;
  end;
end;

procedure TFormObjectTests.Object_InheritedKind;
var
  Obj: TFormObject;
begin
  Obj := TFormObject.Create;
  try
    Obj.ObjectKind := okInherited;
    Assert.AreEqual(okInherited, Obj.ObjectKind);
  finally
    Obj.Free;
  end;
end;

procedure TFormObjectTests.Object_InlineKind;
var
  Obj: TFormObject;
begin
  Obj := TFormObject.Create;
  try
    Obj.ObjectKind := okInline;
    Assert.AreEqual(okInline, Obj.ObjectKind);
  finally
    Obj.Free;
  end;
end;

{ TFormFileTests }

procedure TFormFileTests.FormFile_OwnsRoot;
var
  F: TFormFile;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'frmMain';
    F.Root.ClassName_ := 'TfrmMain';
    Assert.AreEqual('frmMain', F.Root.Name);
  finally
    F.Free;
  end;
end;

procedure TFormFileTests.FormFile_NilRoot_NoLeak;
var
  F: TFormFile;
begin
  F := TFormFile.Create;
  try
    Assert.IsNull(F.Root);
  finally
    F.Free;
  end;
end;

procedure TFormFileTests.FormFile_FullTree_NoLeaks;
var
  F: TFormFile;
  ListVal: TFormValue;
  SetVal: TFormValue;
  BinVal: TFormValue;
  CollVal: TFormValue;
  CollItem: TFormObject;
  Child: TFormObject;
begin
  F := TFormFile.Create;
  try
    F.Root := TFormObject.Create;
    F.Root.Name := 'frmMain';
    F.Root.ClassName_ := 'TfrmMain';
    F.Root.ObjectKind := okObject;

    F.Root.Properties.Add(TFormProperty.Create('Left', TFormValue.Create(fvInteger)));
    F.Root.Properties[0].Value.IntValue := 0;

    F.Root.Properties.Add(TFormProperty.Create('Caption', TFormValue.Create(fvString)));
    F.Root.Properties[1].Value.StringValue := 'Main Form';

    SetVal := TFormValue.Create(fvSet);
    SetVal.SetItems := TArray<string>.Create('akLeft', 'akTop');
    F.Root.Properties.Add(TFormProperty.Create('Anchors', SetVal));

    BinVal := TFormValue.Create(fvBinary);
    BinVal.BinaryData := TBytes.Create($FF, $D8, $FF);
    BinVal.BinaryHex := 'FFD8FF';
    F.Root.Properties.Add(TFormProperty.Create('Picture.Data', BinVal));

    ListVal := TFormValue.Create(fvList);
    ListVal.ListItems.Add(TFormValue.Create(fvString));
    ListVal.ListItems[0].StringValue := 'Item 1';
    ListVal.ListItems.Add(TFormValue.Create(fvString));
    ListVal.ListItems[1].StringValue := 'Item 2';
    F.Root.Properties.Add(TFormProperty.Create('Items.Strings', ListVal));

    CollVal := TFormValue.Create(fvCollection);
    CollItem := TFormObject.Create;
    CollItem.Properties.Add(TFormProperty.Create('Text', TFormValue.Create(fvString)));
    CollItem.Properties[0].Value.StringValue := 'Column 1';
    CollVal.CollectionItems.Add(CollItem);
    F.Root.Properties.Add(TFormProperty.Create('Columns', CollVal));

    Child := TFormObject.Create;
    Child.Name := 'Button1';
    Child.ClassName_ := 'TButton';
    Child.Properties.Add(TFormProperty.Create('Caption', TFormValue.Create(fvString)));
    Child.Properties[0].Value.StringValue := 'Click Me';
    F.Root.Children.Add(Child);

    Assert.AreEqual(NativeInt(6), F.Root.Properties.Count);
    Assert.AreEqual(NativeInt(1), F.Root.Children.Count);
    Assert.AreEqual('Button1', F.Root.Children[0].Name);
  finally
    F.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFormValueTests);
  TDUnitX.RegisterTestFixture(TFormPropertyTests);
  TDUnitX.RegisterTestFixture(TFormObjectTests);
  TDUnitX.RegisterTestFixture(TFormFileTests);

end.
