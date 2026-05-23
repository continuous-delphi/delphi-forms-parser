unit Test.Delphi.Forms.Navigation;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Forms,
  Delphi.Forms.Types,
  Delphi.Forms.Navigation;

type

  [TestFixture]
  TFormNavigationTests = class
  public
    [Test]
    procedure FindObjectByName_Root;

    [Test]
    procedure FindObjectByName_NestedChild;

    [Test]
    procedure FindObjectByName_DeepChild;

    [Test]
    procedure FindObjectByName_NotFound;

    [Test]
    procedure FindObjectByName_CaseInsensitive;

    [Test]
    procedure FindObjectByName_Nil;

    [Test]
    procedure FindObjectsByClass_MultipleMatches;

    [Test]
    procedure FindObjectsByClass_NoMatches;

    [Test]
    procedure FindObjectsByClass_CaseInsensitive;

    [Test]
    procedure FindObjectsByClass_Nil;

    [Test]
    procedure FindProperty_Found;

    [Test]
    procedure FindProperty_NotFound;

    [Test]
    procedure FindProperty_CaseInsensitive;

    [Test]
    procedure FindProperty_Nil;

    [Test]
    procedure FindPropertyByPath_DirectProperty;

    [Test]
    procedure FindPropertyByPath_DottedPropertyName;

    [Test]
    procedure FindPropertyByPath_ObjectThenProperty;

    [Test]
    procedure FindPropertyByPath_DeepPath;

    [Test]
    procedure FindPropertyByPath_NotFound;

    [Test]
    procedure FindPropertyByPath_Nil;

    [Test]
    procedure EnumAllObjects_PopulatedTree;

    [Test]
    procedure EnumAllObjects_EmptyRoot;

    [Test]
    procedure EnumAllObjects_Nil;

    [Test]
    procedure EnumAllProperties_PopulatedTree;

    [Test]
    procedure EnumAllProperties_EmptyRoot;

    [Test]
    procedure EnumAllProperties_Nil;
  end;

implementation

const
  TestDfm =
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10 +
    '  Caption = ''Main'''#13#10 +
    '  Font.Color = clRed'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    Left = 10'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      Caption = ''Hi'''#13#10 +
    '    end'#13#10 +
    '    object Label2: TLabel'#13#10 +
    '      Caption = ''There'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Caption = ''OK'''#13#10 +
    '  end'#13#10 +
    'end'#13#10;

{ TFormNavigationTests }

procedure TFormNavigationTests.FindObjectByName_Root;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Assert.AreSame(F.Root, FindObjectByName(F.Root, 'Form1'));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectByName_NestedChild;
var
  F: TFormFile;
  Obj: TFormObject;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Obj := FindObjectByName(F.Root, 'Panel1');
    Assert.IsNotNull(Obj);
    Assert.AreEqual('Panel1', Obj.Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectByName_DeepChild;
var
  F: TFormFile;
  Obj: TFormObject;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Obj := FindObjectByName(F.Root, 'Label2');
    Assert.IsNotNull(Obj);
    Assert.AreEqual('Label2', Obj.Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectByName_NotFound;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Assert.IsNull(FindObjectByName(F.Root, 'NonExistent'));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectByName_CaseInsensitive;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Assert.IsNotNull(FindObjectByName(F.Root, 'panel1'));
    Assert.IsNotNull(FindObjectByName(F.Root, 'BUTTON1'));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectByName_Nil;
begin
  Assert.IsNull(FindObjectByName(nil, 'Form1'));
end;

procedure TFormNavigationTests.FindObjectsByClass_MultipleMatches;
var
  F: TFormFile;
  Results: TArray<TFormObject>;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Results := FindObjectsByClass(F.Root, 'TLabel');
    Assert.AreEqual(NativeInt(2), NativeInt(Length(Results)));
    Assert.AreEqual('Label1', Results[0].Name);
    Assert.AreEqual('Label2', Results[1].Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectsByClass_NoMatches;
var
  F: TFormFile;
  Results: TArray<TFormObject>;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Results := FindObjectsByClass(F.Root, 'TGroupBox');
    Assert.AreEqual(NativeInt(0), NativeInt(Length(Results)));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectsByClass_CaseInsensitive;
var
  F: TFormFile;
  Results: TArray<TFormObject>;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Results := FindObjectsByClass(F.Root, 'tlabel');
    Assert.AreEqual(NativeInt(2), NativeInt(Length(Results)));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindObjectsByClass_Nil;
var
  Results: TArray<TFormObject>;
begin
  Results := FindObjectsByClass(nil, 'TLabel');
  Assert.AreEqual(NativeInt(0), NativeInt(Length(Results)));
end;

procedure TFormNavigationTests.FindProperty_Found;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Prop := FindProperty(F.Root, 'Caption');
    Assert.IsNotNull(Prop);
    Assert.AreEqual('Caption', Prop.Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindProperty_NotFound;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Assert.IsNull(FindProperty(F.Root, 'NonExistent'));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindProperty_CaseInsensitive;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Assert.IsNotNull(FindProperty(F.Root, 'caption'));
    Assert.IsNotNull(FindProperty(F.Root, 'LEFT'));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindProperty_Nil;
begin
  Assert.IsNull(FindProperty(nil, 'Caption'));
end;

procedure TFormNavigationTests.FindPropertyByPath_DirectProperty;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Prop := FindPropertyByPath(F.Root, 'Caption');
    Assert.IsNotNull(Prop);
    Assert.AreEqual('Caption', Prop.Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindPropertyByPath_DottedPropertyName;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    // 'Font.Color' is a single dotted property name on the root object
    Prop := FindPropertyByPath(F.Root, 'Font.Color');
    Assert.IsNotNull(Prop);
    Assert.AreEqual('Font.Color', Prop.Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindPropertyByPath_ObjectThenProperty;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    // 'Panel1.Left' -- navigate to Panel1 child, find Left property
    Prop := FindPropertyByPath(F.Root, 'Panel1.Left');
    Assert.IsNotNull(Prop);
    Assert.AreEqual('Left', Prop.Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindPropertyByPath_DeepPath;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    // 'Panel1.Label1.Caption' -- Panel1 > Label1 > Caption
    Prop := FindPropertyByPath(F.Root, 'Panel1.Label1.Caption');
    Assert.IsNotNull(Prop);
    Assert.AreEqual('Caption', Prop.Name);
    Assert.AreEqual('Hi', Prop.Value.StringValue);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindPropertyByPath_NotFound;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Assert.IsNull(FindPropertyByPath(F.Root, 'Panel1.NonExistent'));
    Assert.IsNull(FindPropertyByPath(F.Root, 'NonExistent.Caption'));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.FindPropertyByPath_Nil;
begin
  Assert.IsNull(FindPropertyByPath(nil, 'Caption'));
end;

procedure TFormNavigationTests.EnumAllObjects_PopulatedTree;
var
  F: TFormFile;
  Objs: TArray<TFormObject>;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Objs := EnumAllObjects(F.Root);
    // Form1 + Panel1 + Label1 + Label2 + Button1 = 5
    Assert.AreEqual(NativeInt(5), NativeInt(Length(Objs)));
    // Depth-first order
    Assert.AreEqual('Form1', Objs[0].Name);
    Assert.AreEqual('Panel1', Objs[1].Name);
    Assert.AreEqual('Label1', Objs[2].Name);
    Assert.AreEqual('Label2', Objs[3].Name);
    Assert.AreEqual('Button1', Objs[4].Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.EnumAllObjects_EmptyRoot;
var
  F: TFormFile;
  Objs: TArray<TFormObject>;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    'end'#13#10);
  try
    Objs := EnumAllObjects(F.Root);
    Assert.AreEqual(NativeInt(1), NativeInt(Length(Objs)));
    Assert.AreEqual('Form1', Objs[0].Name);
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.EnumAllObjects_Nil;
var
  Objs: TArray<TFormObject>;
begin
  Objs := EnumAllObjects(nil);
  Assert.AreEqual(NativeInt(0), NativeInt(Length(Objs)));
end;

procedure TFormNavigationTests.EnumAllProperties_PopulatedTree;
var
  F: TFormFile;
  Props: TArray<TFormProperty>;
begin
  F := TDelphiFormsParser.ParseText(TestDfm);
  try
    Props := EnumAllProperties(F.Root);
    // Form1: Left, Caption, Font.Color (3) + Panel1: Left (1) +
    // Label1: Caption (1) + Label2: Caption (1) + Button1: Caption (1) = 7
    Assert.AreEqual(NativeInt(7), NativeInt(Length(Props)));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.EnumAllProperties_EmptyRoot;
var
  F: TFormFile;
  Props: TArray<TFormProperty>;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    'end'#13#10);
  try
    Props := EnumAllProperties(F.Root);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(Props)));
  finally
    F.Free;
  end;
end;

procedure TFormNavigationTests.EnumAllProperties_Nil;
var
  Props: TArray<TFormProperty>;
begin
  Props := EnumAllProperties(nil);
  Assert.AreEqual(NativeInt(0), NativeInt(Length(Props)));
end;

end.
