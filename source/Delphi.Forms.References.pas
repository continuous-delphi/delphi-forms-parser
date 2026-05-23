unit Delphi.Forms.References;

interface

uses
  Delphi.Forms.Types;

type

  TComponentRef = record
    SourceComponent: TFormObject;
    Property_: TFormProperty;
    TargetComponent: TFormObject;
    TargetName: string;
  end;

function IsComponentReference(Value: TFormValue; Form: TFormFile): Boolean;
function ResolveComponentReference(Value: TFormValue; Form: TFormFile): TFormObject;
function EnumComponentReferences(Form: TFormFile): TArray<TComponentRef>;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms.Navigation;

function ResolveComponentReference(Value: TFormValue; Form: TFormFile): TFormObject;
begin
  Result := nil;
  if (Value = nil) or (Form = nil) or (Form.Root = nil) then
    Exit;
  if Value.Kind <> fvIdentifier then
    Exit;
  // Dotted identifiers (cross-form references) cannot be resolved
  if Pos('.', Value.IdentValue) > 0 then
    Exit;
  Result := FindObjectByName(Form.Root, Value.IdentValue);
end;

function IsComponentReference(Value: TFormValue; Form: TFormFile): Boolean;
begin
  Result := ResolveComponentReference(Value, Form) <> nil;
end;

procedure CollectRefs(Obj: TFormObject; Form: TFormFile; List: TList<TComponentRef>);
var
  I: Integer;
  Ref: TComponentRef;
  Value: TFormValue;
begin
  if Obj = nil then
    Exit;
  for I := 0 to Obj.Properties.Count - 1 do
  begin
    Value := Obj.Properties[I].Value;
    if (Value <> nil) and (Value.Kind = fvIdentifier) then
    begin
      Ref.SourceComponent := Obj;
      Ref.Property_ := Obj.Properties[I];
      Ref.TargetName := Value.IdentValue;
      if Pos('.', Value.IdentValue) > 0 then
      begin
        // Dotted identifier -- cross-form reference, unresolved
        Ref.TargetComponent := nil;
        List.Add(Ref);
      end
      else
      begin
        Ref.TargetComponent := FindObjectByName(Form.Root, Value.IdentValue);
        if Ref.TargetComponent <> nil then
          List.Add(Ref);
      end;
    end;
  end;
  for I := 0 to Obj.Children.Count - 1 do
    CollectRefs(Obj.Children[I], Form, List);
end;

function EnumComponentReferences(Form: TFormFile): TArray<TComponentRef>;
var
  List: TList<TComponentRef>;
begin
  List := TList<TComponentRef>.Create;
  try
    if (Form <> nil) and (Form.Root <> nil) then
      CollectRefs(Form.Root, Form, List);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

end.
