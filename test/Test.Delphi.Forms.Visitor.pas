unit Test.Delphi.Forms.Visitor;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms,
  Delphi.Forms.Types,
  Delphi.Forms.Visitor;

type

  [TestFixture]
  TFormVisitorTests = class
  public
    [Test]
    procedure ComponentCounter_CountsAllObjects;

    [Test]
    procedure PropertyCounter_CountsAllProperties;

    [Test]
    procedure DepthTracking_MatchesNesting;

    [Test]
    procedure TraversalOrder_DepthFirst;

    [Test]
    procedure CollectionItems_VisitedAsObjects;

    [Test]
    procedure Values_Visited;

    [Test]
    procedure NilForm_NoError;

    [Test]
    procedure EmptyForm_NoVisits;

    [Test]
    procedure WalkObject_Subtree;

    [Test]
    procedure BaseClass_CompilesAndRuns;
  end;

implementation

type
  TComponentCounter = class(TFormVisitor)
  public
    Count: Integer;
    procedure VisitObject(Obj: TFormObject; Depth: Integer); override;
  end;

  TPropertyCounter = class(TFormVisitor)
  public
    Count: Integer;
    procedure VisitProperty(Prop: TFormProperty; Obj: TFormObject; Depth: Integer); override;
  end;

  TDepthRecorder = class(TFormVisitor)
  public
    MaxDepth: Integer;
    Depths: TList<Integer>;
    constructor Create;
    destructor Destroy; override;
    procedure VisitObject(Obj: TFormObject; Depth: Integer); override;
  end;

  TNameRecorder = class(TFormVisitor)
  public
    Names: TList<string>;
    constructor Create;
    destructor Destroy; override;
    procedure VisitObject(Obj: TFormObject; Depth: Integer); override;
  end;

  TValueCounter = class(TFormVisitor)
  public
    Count: Integer;
    procedure VisitValue(Value: TFormValue; Prop: TFormProperty; Depth: Integer); override;
  end;

{ TComponentCounter }

procedure TComponentCounter.VisitObject(Obj: TFormObject; Depth: Integer);
begin
  Inc(Count);
end;

{ TPropertyCounter }

procedure TPropertyCounter.VisitProperty(Prop: TFormProperty; Obj: TFormObject; Depth: Integer);
begin
  Inc(Count);
end;

{ TDepthRecorder }

constructor TDepthRecorder.Create;
begin
  inherited Create;
  Depths := TList<Integer>.Create;
  MaxDepth := -1;
end;

destructor TDepthRecorder.Destroy;
begin
  Depths.Free;
  inherited;
end;

procedure TDepthRecorder.VisitObject(Obj: TFormObject; Depth: Integer);
begin
  Depths.Add(Depth);
  if Depth > MaxDepth then
    MaxDepth := Depth;
end;

{ TNameRecorder }

constructor TNameRecorder.Create;
begin
  inherited Create;
  Names := TList<string>.Create;
end;

destructor TNameRecorder.Destroy;
begin
  Names.Free;
  inherited;
end;

procedure TNameRecorder.VisitObject(Obj: TFormObject; Depth: Integer);
begin
  Names.Add(Obj.Name);
end;

{ TValueCounter }

procedure TValueCounter.VisitValue(Value: TFormValue; Prop: TFormProperty; Depth: Integer);
begin
  Inc(Count);
end;

{ TFormVisitorTests }

procedure TFormVisitorTests.ComponentCounter_CountsAllObjects;
var
  F: TFormFile;
  V: TComponentCounter;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      Caption = ''Hi'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Caption = ''OK'''#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    V := TComponentCounter.Create;
    // prevent ref-count free by using interface variable
    WalkForm(F, V);
    Assert.AreEqual(4, V.Count, 'Should count Form1 + Panel1 + Label1 + Button1');
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.PropertyCounter_CountsAllProperties;
var
  F: TFormFile;
  V: TPropertyCounter;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Caption = ''OK'''#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    V := TPropertyCounter.Create;
    WalkForm(F, V);
    Assert.AreEqual(3, V.Count, 'Should count Left + Top + Caption');
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.DepthTracking_MatchesNesting;
var
  F: TFormFile;
  V: TDepthRecorder;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      Caption = ''Hi'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    V := TDepthRecorder.Create;
    WalkForm(F, V);
    Assert.AreEqual(NativeInt(3), V.Depths.Count, '3 objects visited');
    Assert.AreEqual(0, V.Depths[0], 'Form1 at depth 0');
    Assert.AreEqual(1, V.Depths[1], 'Panel1 at depth 1');
    Assert.AreEqual(2, V.Depths[2], 'Label1 at depth 2');
    Assert.AreEqual(2, V.MaxDepth, 'Max depth is 2');
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.TraversalOrder_DepthFirst;
var
  F: TFormFile;
  V: TNameRecorder;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      Caption = ''Hi'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Caption = ''OK'''#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    V := TNameRecorder.Create;
    WalkForm(F, V);
    Assert.AreEqual(NativeInt(4), V.Names.Count);
    Assert.AreEqual('Form1', V.Names[0]);
    Assert.AreEqual('Panel1', V.Names[1]);
    Assert.AreEqual('Label1', V.Names[2]);
    Assert.AreEqual('Button1', V.Names[3]);
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.CollectionItems_VisitedAsObjects;
var
  F: TFormFile;
  V: TComponentCounter;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Items = <'#13#10 +
    '    item'#13#10 +
    '      Caption = ''A'''#13#10 +
    '    end'#13#10 +
    '    item'#13#10 +
    '      Caption = ''B'''#13#10 +
    '    end>'#13#10 +
    'end'#13#10);
  try
    V := TComponentCounter.Create;
    WalkForm(F, V);
    // Form1 + 2 collection items
    Assert.AreEqual(3, V.Count, 'Should count Form1 + 2 collection items');
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.Values_Visited;
var
  F: TFormFile;
  V: TValueCounter;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Left = 0'#13#10 +
    '  Caption = ''Test'''#13#10 +
    'end'#13#10);
  try
    V := TValueCounter.Create;
    WalkForm(F, V);
    Assert.AreEqual(2, V.Count, 'Should visit 2 values');
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.NilForm_NoError;
var
  V: TComponentCounter;
begin
  V := TComponentCounter.Create;
  WalkForm(nil, V);
  Assert.AreEqual(0, V.Count);
end;

procedure TFormVisitorTests.EmptyForm_NoVisits;
var
  F: TFormFile;
  V: TComponentCounter;
begin
  F := TFormFile.Create;
  try
    V := TComponentCounter.Create;
    WalkForm(F, V);
    Assert.AreEqual(0, V.Count);
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.WalkObject_Subtree;
var
  F: TFormFile;
  V: TNameRecorder;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  object Panel1: TPanel'#13#10 +
    '    object Label1: TLabel'#13#10 +
    '      Caption = ''Hi'''#13#10 +
    '    end'#13#10 +
    '  end'#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Caption = ''OK'''#13#10 +
    '  end'#13#10 +
    'end'#13#10);
  try
    V := TNameRecorder.Create;
    // Walk only Panel1 subtree
    WalkObject(F.Root.Children[0], V, 0);
    Assert.AreEqual(NativeInt(2), V.Names.Count, 'Should visit Panel1 + Label1 only');
    Assert.AreEqual('Panel1', V.Names[0]);
    Assert.AreEqual('Label1', V.Names[1]);
  finally
    F.Free;
  end;
end;

procedure TFormVisitorTests.BaseClass_CompilesAndRuns;
var
  F: TFormFile;
  V: TFormVisitor;
begin
  F := TDelphiFormsParser.ParseText(
    'object Form1: TForm1'#13#10 +
    '  Caption = ''Test'''#13#10 +
    'end'#13#10);
  try
    V := TFormVisitor.Create;
    // Base class should not raise -- all methods are no-ops
    WalkForm(F, V);
  finally
    F.Free;
  end;
end;

end.
