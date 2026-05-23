unit Delphi.Forms.Path;

interface

uses
  Delphi.Forms.Types;

function GetObjectPath(Obj: TFormObject): string;
function GetObjectDepth(Obj: TFormObject): Integer;
function IsAncestorOf(Ancestor, Descendant: TFormObject): Boolean;
function GetAncestorByClass(Obj: TFormObject; const ClassName: string): TFormObject;

implementation

uses
  System.SysUtils;

function GetObjectPath(Obj: TFormObject): string;
var
  Current: TFormObject;
begin
  if Obj = nil then
    Exit('');
  Result := Obj.Name;
  Current := Obj.Parent;
  while Current <> nil do
  begin
    Result := Current.Name + '.' + Result;
    Current := Current.Parent;
  end;
end;

function GetObjectDepth(Obj: TFormObject): Integer;
var
  Current: TFormObject;
begin
  Result := 0;
  if Obj = nil then
    Exit;
  Current := Obj.Parent;
  while Current <> nil do
  begin
    Inc(Result);
    Current := Current.Parent;
  end;
end;

function IsAncestorOf(Ancestor, Descendant: TFormObject): Boolean;
var
  Current: TFormObject;
begin
  Result := False;
  if (Ancestor = nil) or (Descendant = nil) then
    Exit;
  Current := Descendant.Parent;
  while Current <> nil do
  begin
    if Current = Ancestor then
      Exit(True);
    Current := Current.Parent;
  end;
end;

function GetAncestorByClass(Obj: TFormObject; const ClassName: string): TFormObject;
var
  Current: TFormObject;
begin
  Result := nil;
  if Obj = nil then
    Exit;
  Current := Obj.Parent;
  while Current <> nil do
  begin
    if SameText(Current.ClassName_, ClassName) then
      Exit(Current);
    Current := Current.Parent;
  end;
end;

end.
