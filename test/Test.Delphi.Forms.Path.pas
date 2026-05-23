unit Test.Delphi.Forms.Path;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Forms,
  Delphi.Forms.Types,
  Delphi.Forms.Path;

type

  [TestFixture]
  TFormPathTests = class
  public
    [Test]
    procedure GetObjectPath_Root;

    [Test]
    procedure GetObjectPath_NestedChild;

    [Test]
    procedure GetObjectPath_DeepNesting;

    [Test]
    procedure GetObjectPath_Nil;

    [Test]
    procedure GetObjectDepth_Root;

    [Test]
    procedure GetObjectDepth_DirectChild;

    [Test]
    procedure GetObjectDepth_DeepNesting;

    [Test]
    procedure GetObjectDepth_Nil;

    [Test]
    procedure IsAncestorOf_DirectParent;

    [Test]
    procedure IsAncestorOf_Grandparent;

    [Test]
    procedure IsAncestorOf_NonAncestor;

    [Test]
    procedure IsAncestorOf_Self;

    [Test]
    procedure IsAncestorOf_Nil;

    [Test]
    procedure GetAncestorByClass_Match;

    [Test]
    procedure GetAncestorByClass_NoMatch;

    [Test]
    procedure GetAncestorByClass_CaseInsensitive;

    [Test]
    procedure GetAncestorByClass_Nil;

    [Test]
    procedure GetAncestorByClass_NearestMatch;
  end;

implementation

const
  NestedDfm =
    'object Form1: TForm1'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      Caption = ''Hi'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Caption = ''OK'''#13#10 +
    '  end'#13#10 +
    'end'#13#10;

{ TFormPathTests }

procedure TFormPathTests.GetObjectPath_Root;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.AreEqual('Form1', GetObjectPath(F.Root));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetObjectPath_NestedChild;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.AreEqual('Form1.Panel1', GetObjectPath(F.Root.Children[0]));
    Assert.AreEqual('Form1.Button1', GetObjectPath(F.Root.Children[1]));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetObjectPath_DeepNesting;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.AreEqual('Form1.Panel1.Label1', GetObjectPath(F.Root.Children[0].Children[0]));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetObjectPath_Nil;
begin
  Assert.AreEqual('', GetObjectPath(nil));
end;

procedure TFormPathTests.GetObjectDepth_Root;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.AreEqual(0, GetObjectDepth(F.Root));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetObjectDepth_DirectChild;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.AreEqual(1, GetObjectDepth(F.Root.Children[0]));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetObjectDepth_DeepNesting;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.AreEqual(2, GetObjectDepth(F.Root.Children[0].Children[0]));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetObjectDepth_Nil;
begin
  Assert.AreEqual(0, GetObjectDepth(nil));
end;

procedure TFormPathTests.IsAncestorOf_DirectParent;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.IsTrue(IsAncestorOf(F.Root, F.Root.Children[0]));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.IsAncestorOf_Grandparent;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.IsTrue(IsAncestorOf(F.Root, F.Root.Children[0].Children[0]));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.IsAncestorOf_NonAncestor;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    // Button1 is not an ancestor of Label1
    Assert.IsFalse(IsAncestorOf(F.Root.Children[1], F.Root.Children[0].Children[0]));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.IsAncestorOf_Self;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    // An object is not its own ancestor
    Assert.IsFalse(IsAncestorOf(F.Root, F.Root));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.IsAncestorOf_Nil;
begin
  Assert.IsFalse(IsAncestorOf(nil, nil));
end;

procedure TFormPathTests.GetAncestorByClass_Match;
var
  F: TFormFile;
  Ancestor: TFormObject;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Ancestor := GetAncestorByClass(F.Root.Children[0].Children[0], 'TPanel');
    Assert.IsNotNull(Ancestor);
    Assert.AreEqual('Panel1', Ancestor.Name);
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetAncestorByClass_NoMatch;
var
  F: TFormFile;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Assert.IsNull(GetAncestorByClass(F.Root.Children[0].Children[0], 'TGroupBox'));
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetAncestorByClass_CaseInsensitive;
var
  F: TFormFile;
  Ancestor: TFormObject;
begin
  F := TDelphiFormsParser.ParseText(NestedDfm);
  try
    Ancestor := GetAncestorByClass(F.Root.Children[0].Children[0], 'tpanel');
    Assert.IsNotNull(Ancestor);
    Assert.AreEqual('Panel1', Ancestor.Name);
  finally
    F.Free;
  end;
end;

procedure TFormPathTests.GetAncestorByClass_Nil;
begin
  Assert.IsNull(GetAncestorByClass(nil, 'TForm1'));
end;

procedure TFormPathTests.GetAncestorByClass_NearestMatch;
var
  F: TFormFile;
  Ancestor: TFormObject;
begin
  // Two nested TPanel objects -- should return the nearest one
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  object OuterPanel: TPanel'#13#10 +
    '    object InnerPanel: TPanel'#13#10 +
    '      object Label1: TLabel'#13#10 +
    '        Caption = ''Hi'''#13#10 +
    '      end'#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    Ancestor := GetAncestorByClass(F.Root.Children[0].Children[0].Children[0], 'TPanel');
    Assert.IsNotNull(Ancestor);
    Assert.AreEqual('InnerPanel', Ancestor.Name, 'Should return nearest TPanel ancestor');
  finally
    F.Free;
  end;
end;

end.
