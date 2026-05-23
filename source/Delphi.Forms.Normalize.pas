unit Delphi.Forms.Normalize;

interface

uses
  Delphi.Forms.Types;

type

  TFormNormalizeRule = (
    nrRemoveExplicitBounds,
    nrRemoveTextHeight,
    nrRemoveDesignSize
  );
  TFormNormalizeRules = set of TFormNormalizeRule;

const
  DefaultNormalizeRules = [nrRemoveExplicitBounds, nrRemoveTextHeight, nrRemoveDesignSize];

procedure NormalizeForm(FormFile: TFormFile; Rules: TFormNormalizeRules = DefaultNormalizeRules);

implementation

uses
  System.SysUtils;

function IsRemovable(const PropName: string; Rules: TFormNormalizeRules): Boolean;
begin
  Result := False;
  if nrRemoveExplicitBounds in Rules then
  begin
    if SameText(PropName, 'ExplicitLeft') or SameText(PropName, 'ExplicitTop') or SameText(PropName, 'ExplicitWidth') or SameText(PropName, 'ExplicitHeight') then
      Exit(True);
  end;
  if nrRemoveTextHeight in Rules then
  begin
    if SameText(PropName, 'TextHeight') then
      Exit(True);
  end;
  if nrRemoveDesignSize in Rules then
  begin
    if SameText(PropName, 'DesignSize') then
      Exit(True);
  end;
end;

procedure NormalizeObject(Obj: TFormObject; Rules: TFormNormalizeRules);
var
  I: Integer;
begin
  if Obj = nil then
    Exit;

  // Remove matching properties in reverse order to avoid index shifting
  for I := Obj.Properties.Count - 1 downto 0 do
  begin
    if IsRemovable(Obj.Properties[I].Name, Rules) then
      Obj.Properties.Delete(I);
  end;

  // Recurse into children
  for I := 0 to Obj.Children.Count - 1 do
    NormalizeObject(Obj.Children[I], Rules);

  // Recurse into collection items within properties
  for I := 0 to Obj.Properties.Count - 1 do
  begin
    if (Obj.Properties[I].Value <> nil) and (Obj.Properties[I].Value.Kind = fvCollection) then
    begin
      var J: Integer;
      for J := 0 to Obj.Properties[I].Value.CollectionItems.Count - 1 do
        NormalizeObject(Obj.Properties[I].Value.CollectionItems[J], Rules);
    end;
  end;
end;

procedure NormalizeForm(FormFile: TFormFile; Rules: TFormNormalizeRules);
begin
  if (FormFile = nil) or (Rules = []) then
    Exit;
  NormalizeObject(FormFile.Root, Rules);
end;

end.
