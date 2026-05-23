unit Test.Delphi.Forms.Normalize;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Delphi.Forms,
  Delphi.Forms.Types,
  Delphi.Forms.Normalize;

type

  [TestFixture]
  TFormNormalizeTests = class
  private
    function BuildForm(const Dfm: string): TFormFile;
    function HasProperty(Obj: TFormObject; const PropName: string): Boolean;
    function PropertyCount(Obj: TFormObject): Integer;
  public
    [Test]
    procedure RemoveExplicitBounds_RootLevel;

    [Test]
    procedure RemoveExplicitBounds_NestedChildren;

    [Test]
    procedure RemoveTextHeight_RootLevel;

    [Test]
    procedure RemoveTextHeight_NestedChildren;

    [Test]
    procedure RemoveDesignSize_RootLevel;

    [Test]
    procedure RemoveDesignSize_NestedChildren;

    [Test]
    procedure DefaultRules_RemoveAll;

    [Test]
    procedure EmptyRules_RemoveNothing;

    [Test]
    procedure SingleRule_ExplicitBoundsOnly;

    [Test]
    procedure SingleRule_TextHeightOnly;

    [Test]
    procedure SingleRule_DesignSizeOnly;

    [Test]
    procedure NonMatchingProperties_Untouched;

    [Test]
    procedure NilFormFile_NoError;

    [Test]
    procedure EmptyForm_NoError;

    [Test]
    procedure CaseInsensitive_PropertyNames;

    [Test]
    procedure CollectionItems_Normalized;
  end;

implementation

const
  FormWithNoiseProps =
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Caption = ''Main'''#13#10 +
    '  ExplicitLeft = 10'#13#10 +
    '  ExplicitTop = 20'#13#10 +
    '  ExplicitWidth = 800'#13#10 +
    '  ExplicitHeight = 600'#13#10 +
    '  TextHeight = 13'#13#10 +
    '  DesignSize = ('#13#10 +
    '    640'#13#10 +
    '    480)'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    Left = 0'#13#10 +
    '    Top = 0'#13#10 +
    '    ExplicitLeft = 5'#13#10 +
    '    ExplicitTop = 5'#13#10 +
    '    ExplicitWidth = 200'#13#10 +
    '    ExplicitHeight = 100'#13#10 +
    '    TextHeight = 15'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      Left = 8'#13#10 +
    '      Caption = ''Hello'''#13#10 +
    '      ExplicitLeft = 8'#13#10 +
    '      TextHeight = 13'#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    'end'#13#10;

{ TFormNormalizeTests }

function TFormNormalizeTests.BuildForm(const Dfm: string): TFormFile;
begin
  Result := TDelphiFormsParser.ParseText(Dfm);
end;

function TFormNormalizeTests.HasProperty(Obj: TFormObject; const PropName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Obj.Properties.Count - 1 do
    if SameText(Obj.Properties[I].Name, PropName) then
      Exit(True);
end;

function TFormNormalizeTests.PropertyCount(Obj: TFormObject): Integer;
begin
  Result := Obj.Properties.Count;
end;

procedure TFormNormalizeTests.RemoveExplicitBounds_RootLevel;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveExplicitBounds]);
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitLeft'));
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitTop'));
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitWidth'));
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitHeight'));
    // TextHeight and DesignSize should remain
    Assert.IsTrue(HasProperty(F.Root, 'TextHeight'));
    Assert.IsTrue(HasProperty(F.Root, 'DesignSize'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.RemoveExplicitBounds_NestedChildren;
var
  F: TFormFile;
  Panel: TFormObject;
  Lbl: TFormObject;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveExplicitBounds]);
    Panel := F.Root.Children[0];
    Assert.IsFalse(HasProperty(Panel, 'ExplicitLeft'));
    Assert.IsFalse(HasProperty(Panel, 'ExplicitTop'));
    Assert.IsFalse(HasProperty(Panel, 'ExplicitWidth'));
    Assert.IsFalse(HasProperty(Panel, 'ExplicitHeight'));
    Lbl := Panel.Children[0];
    Assert.IsFalse(HasProperty(Lbl, 'ExplicitLeft'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.RemoveTextHeight_RootLevel;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveTextHeight]);
    Assert.IsFalse(HasProperty(F.Root, 'TextHeight'));
    // ExplicitBounds should remain
    Assert.IsTrue(HasProperty(F.Root, 'ExplicitLeft'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.RemoveTextHeight_NestedChildren;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveTextHeight]);
    Assert.IsFalse(HasProperty(F.Root.Children[0], 'TextHeight'));
    Assert.IsFalse(HasProperty(F.Root.Children[0].Children[0], 'TextHeight'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.RemoveDesignSize_RootLevel;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveDesignSize]);
    Assert.IsFalse(HasProperty(F.Root, 'DesignSize'));
    Assert.IsTrue(HasProperty(F.Root, 'TextHeight'));
    Assert.IsTrue(HasProperty(F.Root, 'ExplicitLeft'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.RemoveDesignSize_NestedChildren;
var
  F: TFormFile;
begin
  F := BuildForm(
    'object Form1: TForm1'#13#10 +
    '  DesignSize = ('#13#10 +
    '    640'#13#10 +
    '    480)'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    DesignSize = ('#13#10 +
    '      320'#13#10 +
    '      240)'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    NormalizeForm(F, [nrRemoveDesignSize]);
    Assert.IsFalse(HasProperty(F.Root, 'DesignSize'));
    Assert.IsFalse(HasProperty(F.Root.Children[0], 'DesignSize'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.DefaultRules_RemoveAll;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F);
    // Root
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitLeft'));
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitTop'));
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitWidth'));
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitHeight'));
    Assert.IsFalse(HasProperty(F.Root, 'TextHeight'));
    Assert.IsFalse(HasProperty(F.Root, 'DesignSize'));
    // Remaining: Left, Top, Caption
    Assert.AreEqual(NativeInt(3), NativeInt(PropertyCount(F.Root)));
    // Panel1
    Assert.AreEqual(NativeInt(2), NativeInt(PropertyCount(F.Root.Children[0])));
    // Label1
    Assert.AreEqual(NativeInt(2), NativeInt(PropertyCount(F.Root.Children[0].Children[0])));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.EmptyRules_RemoveNothing;
var
  F: TFormFile;
  OrigCount: Integer;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    OrigCount := PropertyCount(F.Root);
    NormalizeForm(F, []);
    Assert.AreEqual(NativeInt(OrigCount), NativeInt(PropertyCount(F.Root)));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.SingleRule_ExplicitBoundsOnly;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveExplicitBounds]);
    Assert.IsFalse(HasProperty(F.Root, 'ExplicitLeft'));
    Assert.IsTrue(HasProperty(F.Root, 'TextHeight'));
    Assert.IsTrue(HasProperty(F.Root, 'DesignSize'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.SingleRule_TextHeightOnly;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveTextHeight]);
    Assert.IsFalse(HasProperty(F.Root, 'TextHeight'));
    Assert.IsTrue(HasProperty(F.Root, 'ExplicitLeft'));
    Assert.IsTrue(HasProperty(F.Root, 'DesignSize'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.SingleRule_DesignSizeOnly;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F, [nrRemoveDesignSize]);
    Assert.IsFalse(HasProperty(F.Root, 'DesignSize'));
    Assert.IsTrue(HasProperty(F.Root, 'ExplicitLeft'));
    Assert.IsTrue(HasProperty(F.Root, 'TextHeight'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.NonMatchingProperties_Untouched;
var
  F: TFormFile;
begin
  F := BuildForm(FormWithNoiseProps);
  try
    NormalizeForm(F);
    Assert.IsTrue(HasProperty(F.Root, 'Left'));
    Assert.IsTrue(HasProperty(F.Root, 'Top'));
    Assert.IsTrue(HasProperty(F.Root, 'Caption'));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.NilFormFile_NoError;
begin
  // Should not raise
  NormalizeForm(nil);
  NormalizeForm(nil, [nrRemoveTextHeight]);
end;

procedure TFormNormalizeTests.EmptyForm_NoError;
var
  F: TFormFile;
begin
  F := BuildForm(
    'object Form1: TForm1'#13#10 +
    'end'#13#10);
  try
    NormalizeForm(F);
    Assert.AreEqual(NativeInt(0), NativeInt(PropertyCount(F.Root)));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.CaseInsensitive_PropertyNames;
var
  F: TFormFile;
begin
  // Delphi IDE always uses exact casing, but normalization should be case-insensitive
  F := BuildForm(
    'object Form1: TForm1'#13#10 +
    '  explicitlEFT = 10'#13#10 +
    '  TEXTHEIGHT = 13'#13#10 +
    '  designsize = ('#13#10 +
    '    640'#13#10 +
    '    480)'#13#10 +
    'end'#13#10);
  try
    NormalizeForm(F);
    Assert.AreEqual(NativeInt(0), NativeInt(PropertyCount(F.Root)));
  finally
    F.Free;
  end;
end;

procedure TFormNormalizeTests.CollectionItems_Normalized;
var
  F: TFormFile;
begin
  F := BuildForm(
    'object Form1: TForm1'#13#10 +
    '  TextHeight = 13'#13#10 +
    '  Items = <'#13#10 +
    '    item'#13#10 +
    '      ExplicitLeft = 10'#13#10 +
    '      Caption = ''Test'''#13#10 +
    '      TextHeight = 15'#13#10 +
    '    end>'#13#10 +
    'end'#13#10);
  try
    NormalizeForm(F);
    Assert.IsFalse(HasProperty(F.Root, 'TextHeight'));
    // Collection item should have ExplicitLeft and TextHeight removed
    var CollItem := F.Root.Properties[0].Value.CollectionItems[0];
    Assert.IsFalse(HasProperty(CollItem, 'ExplicitLeft'));
    Assert.IsFalse(HasProperty(CollItem, 'TextHeight'));
    Assert.IsTrue(HasProperty(CollItem, 'Caption'));
    Assert.AreEqual(NativeInt(1), NativeInt(PropertyCount(CollItem)));
  finally
    F.Free;
  end;
end;

end.
