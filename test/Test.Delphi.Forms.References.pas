unit Test.Delphi.Forms.References;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Forms,
  Delphi.Forms.Types,
  Delphi.Forms.References;

type

  [TestFixture]
  TComponentRefTests = class
  public
    [Test]
    procedure IsComponentReference_SimpleMatch;

    [Test]
    procedure IsComponentReference_NoMatch;

    [Test]
    procedure IsComponentReference_NonIdentifier;

    [Test]
    procedure IsComponentReference_NilValue;

    [Test]
    procedure IsComponentReference_NilForm;

    [Test]
    procedure ResolveComponentReference_ReturnsTarget;

    [Test]
    procedure ResolveComponentReference_DottedIdentifier_ReturnsNil;

    [Test]
    procedure EnumComponentReferences_SimpleForm;

    [Test]
    procedure EnumComponentReferences_NestedReference;

    [Test]
    procedure EnumComponentReferences_DottedCrossForm;

    [Test]
    procedure EnumComponentReferences_EnumValueNotReported;

    [Test]
    procedure EnumComponentReferences_NoReferences;

    [Test]
    procedure EnumComponentReferences_NilForm;

    [Test]
    procedure EnumComponentReferences_MultipleRefs;
  end;

implementation

const
  RefDfm =
    'object Form1: TForm1'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    Left = 0'#13#10 +
    '    PopupMenu = pmMain'#13#10 +
    '  end'#13#10 +
    '  object pmMain: TPopupMenu'#13#10 +
    '    Left = 100'#13#10 +
    '  end'#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Action = actSave'#13#10 +
    '    Align = alClient'#13#10 +
    '  end'#13#10 +
    '  object actSave: TAction'#13#10 +
    '    Caption = ''Save'''#13#10 +
    '  end'#13#10 +
    'end'#13#10;

{ TComponentRefTests }

procedure TComponentRefTests.IsComponentReference_SimpleMatch;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(RefDfm);
  try
    // Panel1.PopupMenu = pmMain -- pmMain is a component
    Prop := F.Root.Children[0].Properties[1]; // PopupMenu = pmMain
    Assert.IsTrue(IsComponentReference(Prop.Value, F));
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.IsComponentReference_NoMatch;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(RefDfm);
  try
    // Button1.Align = alClient -- alClient is an enum value, not a component
    Prop := F.Root.Children[2].Properties[1]; // Align = alClient
    Assert.IsFalse(IsComponentReference(Prop.Value, F));
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.IsComponentReference_NonIdentifier;
var
  F: TFormFile;
  Prop: TFormProperty;
begin
  F := TDelphiFormsParser.ParseText(RefDfm);
  try
    // Panel1.Left = 0 -- integer, not an identifier
    Prop := F.Root.Children[0].Properties[0]; // Left = 0
    Assert.IsFalse(IsComponentReference(Prop.Value, F));
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.IsComponentReference_NilValue;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(RefDfm);
  try
    Assert.IsFalse(IsComponentReference(nil, F));
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.IsComponentReference_NilForm;
var
  V: TFormValue;
begin
  V := TFormValue.Create(fvIdentifier);
  try
    V.IdentValue := 'pmMain';
    Assert.IsFalse(IsComponentReference(V, nil));
  finally
    V.Free;
  end;
end;

procedure TComponentRefTests.ResolveComponentReference_ReturnsTarget;
var
  F: TFormFile;
  Prop: TFormProperty;
  Target: TFormObject;
begin
  F := TDelphiFormsParser.ParseText(RefDfm);
  try
    Prop := F.Root.Children[0].Properties[1]; // PopupMenu = pmMain
    Target := ResolveComponentReference(Prop.Value, F);
    Assert.IsNotNull(Target);
    Assert.AreEqual('pmMain', Target.Name);
    Assert.AreEqual('TPopupMenu', Target.ClassName_);
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.ResolveComponentReference_DottedIdentifier_ReturnsNil;
var
  F: TFormFile;
  V: TFormValue;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  DataSource = DataModule1.dsCustomers'#13#10 +
    'end'#13#10);
  try
    V := F.Root.Properties[0].Value;
    Assert.IsNull(ResolveComponentReference(V, F), 'Dotted identifier should not resolve');
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.EnumComponentReferences_SimpleForm;
var
  F: TFormFile;
  Refs: TArray<TComponentRef>;
begin
  F := TDelphiFormsParser.ParseText(RefDfm);
  try
    Refs := EnumComponentReferences(F);
    // PopupMenu = pmMain, Action = actSave -- alClient is not a component
    Assert.AreEqual(NativeInt(2), NativeInt(Length(Refs)));
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.EnumComponentReferences_NestedReference;
var
  F: TFormFile;
  Refs: TArray<TComponentRef>;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      FocusControl = Edit1'#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object Edit1: TEdit'#13#10 +
    '    Left = 0'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    Refs := EnumComponentReferences(F);
    Assert.AreEqual(NativeInt(1), NativeInt(Length(Refs)));
    Assert.AreEqual('Label1', Refs[0].SourceComponent.Name);
    Assert.AreEqual('FocusControl', Refs[0].Property_.Name);
    Assert.AreEqual('Edit1', Refs[0].TargetName);
    Assert.IsNotNull(Refs[0].TargetComponent);
    Assert.AreEqual('Edit1', Refs[0].TargetComponent.Name);
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.EnumComponentReferences_DottedCrossForm;
var
  F: TFormFile;
  Refs: TArray<TComponentRef>;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  DataSource = DataModule1.dsCustomers'#13#10 +
    'end'#13#10);
  try
    Refs := EnumComponentReferences(F);
    Assert.AreEqual(NativeInt(1), NativeInt(Length(Refs)));
    Assert.AreEqual('DataModule1.dsCustomers', Refs[0].TargetName);
    Assert.IsNull(Refs[0].TargetComponent, 'Cross-form reference should be unresolved');
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.EnumComponentReferences_EnumValueNotReported;
var
  F: TFormFile;
  Refs: TArray<TComponentRef>;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Align = alClient'#13#10 +
    '  Position = poScreenCenter'#13#10 +
    'end'#13#10);
  try
    Refs := EnumComponentReferences(F);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(Refs)));
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.EnumComponentReferences_NoReferences;
var
  F: TFormFile;
  Refs: TArray<TComponentRef>;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10 +
    '  Caption = ''Test'''#13#10 +
    'end'#13#10);
  try
    Refs := EnumComponentReferences(F);
    Assert.AreEqual(NativeInt(0), NativeInt(Length(Refs)));
  finally
    F.Free;
  end;
end;

procedure TComponentRefTests.EnumComponentReferences_NilForm;
var
  Refs: TArray<TComponentRef>;
begin
  Refs := EnumComponentReferences(nil);
  Assert.AreEqual(NativeInt(0), NativeInt(Length(Refs)));
end;

procedure TComponentRefTests.EnumComponentReferences_MultipleRefs;
var
  F: TFormFile;
  Refs: TArray<TComponentRef>;
begin
  F := TDelphiFormsParser.ParseText(RefDfm);
  try
    Refs := EnumComponentReferences(F);
    // Verify source/target details
    Assert.AreEqual('Panel1', Refs[0].SourceComponent.Name);
    Assert.AreEqual('PopupMenu', Refs[0].Property_.Name);
    Assert.AreEqual('pmMain', Refs[0].TargetName);
    Assert.IsNotNull(Refs[0].TargetComponent);

    Assert.AreEqual('Button1', Refs[1].SourceComponent.Name);
    Assert.AreEqual('Action', Refs[1].Property_.Name);
    Assert.AreEqual('actSave', Refs[1].TargetName);
    Assert.IsNotNull(Refs[1].TargetComponent);
  finally
    F.Free;
  end;
end;

end.
