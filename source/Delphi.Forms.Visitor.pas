unit Delphi.Forms.Visitor;

interface

uses
  Delphi.Forms.Types;

type

  IFormVisitor = interface
    ['{F1A2B3C4-D5E6-7890-ABCD-EF1234567890}']
    procedure VisitObject(Obj: TFormObject; Depth: Integer);
    procedure VisitProperty(Prop: TFormProperty; Obj: TFormObject; Depth: Integer);
    procedure VisitValue(Value: TFormValue; Prop: TFormProperty; Depth: Integer);
  end;

  TFormVisitor = class(TInterfacedObject, IFormVisitor)
  public
    procedure VisitObject(Obj: TFormObject; Depth: Integer); virtual;
    procedure VisitProperty(Prop: TFormProperty; Obj: TFormObject; Depth: Integer); virtual;
    procedure VisitValue(Value: TFormValue; Prop: TFormProperty; Depth: Integer); virtual;
  end;

procedure WalkForm(Form: TFormFile; const Visitor: IFormVisitor);
procedure WalkObject(Obj: TFormObject; const Visitor: IFormVisitor; Depth: Integer = 0);

implementation

procedure WalkValue(Value: TFormValue; Prop: TFormProperty; const Visitor: IFormVisitor; Depth: Integer);
var
  I: Integer;
begin
  if Value = nil then
    Exit;
  Visitor.VisitValue(Value, Prop, Depth);
  // Walk collection items as nested objects
  if (Value.Kind = fvCollection) and (Value.CollectionItems <> nil) then
  begin
    for I := 0 to Value.CollectionItems.Count - 1 do
      WalkObject(Value.CollectionItems[I], Visitor, Depth + 1);
  end;
  // Walk list items
  if (Value.Kind = fvList) and (Value.ListItems <> nil) then
  begin
    for I := 0 to Value.ListItems.Count - 1 do
      WalkValue(Value.ListItems[I], Prop, Visitor, Depth);
  end;
end;

procedure WalkObject(Obj: TFormObject; const Visitor: IFormVisitor; Depth: Integer);
var
  I: Integer;
begin
  if Obj = nil then
    Exit;
  Visitor.VisitObject(Obj, Depth);
  for I := 0 to Obj.Properties.Count - 1 do
  begin
    Visitor.VisitProperty(Obj.Properties[I], Obj, Depth);
    WalkValue(Obj.Properties[I].Value, Obj.Properties[I], Visitor, Depth);
  end;
  for I := 0 to Obj.Children.Count - 1 do
    WalkObject(Obj.Children[I], Visitor, Depth + 1);
end;

procedure WalkForm(Form: TFormFile; const Visitor: IFormVisitor);
begin
  if Form = nil then
    Exit;
  WalkObject(Form.Root, Visitor, 0);
end;

{ TFormVisitor }

procedure TFormVisitor.VisitObject(Obj: TFormObject; Depth: Integer);
begin
  // Base implementation: no-op
end;

procedure TFormVisitor.VisitProperty(Prop: TFormProperty; Obj: TFormObject; Depth: Integer);
begin
  // Base implementation: no-op
end;

procedure TFormVisitor.VisitValue(Value: TFormValue; Prop: TFormProperty; Depth: Integer);
begin
  // Base implementation: no-op
end;

end.
