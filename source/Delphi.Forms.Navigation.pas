unit Delphi.Forms.Navigation;

interface

uses
  Delphi.Forms.Types;

function FindObjectByName(Root: TFormObject; const Name: string): TFormObject;
function FindObjectsByClass(Root: TFormObject; const ClassName: string): TArray<TFormObject>;
function FindProperty(Obj: TFormObject; const Name: string): TFormProperty;
function FindPropertyByPath(Root: TFormObject; const Path: string): TFormProperty;
function EnumAllObjects(Root: TFormObject): TArray<TFormObject>;
function EnumAllProperties(Root: TFormObject): TArray<TFormProperty>;

implementation

uses
  System.SysUtils,
  System.Generics.Collections;

function FindObjectByName(Root: TFormObject; const Name: string): TFormObject;
var
  I: Integer;
  Found: TFormObject;
begin
  Result := nil;
  if Root = nil then
    Exit;
  if SameText(Root.Name, Name) then
    Exit(Root);
  for I := 0 to Root.Children.Count - 1 do
  begin
    Found := FindObjectByName(Root.Children[I], Name);
    if Found <> nil then
      Exit(Found);
  end;
end;

function FindObjectsByClass(Root: TFormObject; const ClassName: string): TArray<TFormObject>;

  procedure Collect(Obj: TFormObject; List: TList<TFormObject>);
  var
    I: Integer;
  begin
    if Obj = nil then
      Exit;
    if SameText(Obj.ClassName_, ClassName) then
      List.Add(Obj);
    for I := 0 to Obj.Children.Count - 1 do
      Collect(Obj.Children[I], List);
  end;

var
  List: TList<TFormObject>;
begin
  List := TList<TFormObject>.Create;
  try
    Collect(Root, List);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function FindProperty(Obj: TFormObject; const Name: string): TFormProperty;
var
  I: Integer;
begin
  Result := nil;
  if Obj = nil then
    Exit;
  for I := 0 to Obj.Properties.Count - 1 do
  begin
    if SameText(Obj.Properties[I].Name, Name) then
      Exit(Obj.Properties[I]);
  end;
end;

function FindChildByName(Obj: TFormObject; const Name: string): TFormObject;
var
  I: Integer;
begin
  Result := nil;
  if Obj = nil then
    Exit;
  for I := 0 to Obj.Children.Count - 1 do
  begin
    if SameText(Obj.Children[I].Name, Name) then
      Exit(Obj.Children[I]);
  end;
end;

function FindPropertyByPath(Root: TFormObject; const Path: string): TFormProperty;
var
  DotPos: Integer;
  Segment, Rest: string;
  Child: TFormObject;
  Prop: TFormProperty;
begin
  Result := nil;
  if (Root = nil) or (Path = '') then
    Exit;

  // Try the path as a direct property name first (handles dotted property names like 'Font.Color')
  Prop := FindProperty(Root, Path);
  if Prop <> nil then
    Exit(Prop);

  // Split on first dot and try object-then-rest navigation
  DotPos := Pos('.', Path);
  if DotPos = 0 then
    Exit; // No dot and not a direct property -- not found

  Segment := Copy(Path, 1, DotPos - 1);
  Rest := Copy(Path, DotPos + 1, MaxInt);

  // Try navigating to a child object named Segment
  Child := FindChildByName(Root, Segment);
  if Child <> nil then
    Exit(FindPropertyByPath(Child, Rest));
end;

function EnumAllObjects(Root: TFormObject): TArray<TFormObject>;

  procedure Collect(Obj: TFormObject; List: TList<TFormObject>);
  var
    I: Integer;
  begin
    if Obj = nil then
      Exit;
    List.Add(Obj);
    for I := 0 to Obj.Children.Count - 1 do
      Collect(Obj.Children[I], List);
  end;

var
  List: TList<TFormObject>;
begin
  List := TList<TFormObject>.Create;
  try
    Collect(Root, List);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function EnumAllProperties(Root: TFormObject): TArray<TFormProperty>;

  procedure Collect(Obj: TFormObject; List: TList<TFormProperty>);
  var
    I: Integer;
  begin
    if Obj = nil then
      Exit;
    for I := 0 to Obj.Properties.Count - 1 do
      List.Add(Obj.Properties[I]);
    for I := 0 to Obj.Children.Count - 1 do
      Collect(Obj.Children[I], List);
  end;

var
  List: TList<TFormProperty>;
begin
  List := TList<TFormProperty>.Create;
  try
    Collect(Root, List);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

end.
