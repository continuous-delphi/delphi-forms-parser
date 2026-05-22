unit Delphi.Forms.TextWriter;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms.Types;

type

  TDfmTextWriter = class
  private
    FIndent: Integer;
    FLineEnding: string;
    function IndentStr: string;
    function ObjectKindToStr(Kind: TObjectKind): string;
    procedure WriteObject(Obj: TFormObject; var S: string);
    procedure WriteProperty(Prop: TFormProperty; var S: string);
    function WriteValue(Value: TFormValue): string;
    function WriteStringValue(Value: TFormValue): string;
    function WriteSetValue(Value: TFormValue): string;
    function WriteBinaryValue(Value: TFormValue): string;
    function WriteListValue(Value: TFormValue): string;
    function WriteCollectionValue(Value: TFormValue): string;
  public
    constructor Create;
    function Write(FormFile: TFormFile): string;
  end;

implementation

{ TDfmTextWriter }

constructor TDfmTextWriter.Create;
begin
  inherited Create;
  FLineEnding := #13#10;
end;

function TDfmTextWriter.IndentStr: string;
begin
  Result := StringOfChar(' ', FIndent * 2);
end;

function TDfmTextWriter.ObjectKindToStr(Kind: TObjectKind): string;
begin
  case Kind of
    okObject: Result := 'object';
    okInherited: Result := 'inherited';
    okInline: Result := 'inline';
  else
    Result := 'object';
  end;
end;

procedure TDfmTextWriter.WriteObject(Obj: TFormObject; var S: string);
var
  I: Integer;
begin
  S := S + IndentStr + ObjectKindToStr(Obj.ObjectKind) + ' ' + Obj.Name + ': ' + Obj.ClassName_ + FLineEnding;
  Inc(FIndent);
  for I := 0 to Obj.Properties.Count - 1 do
    WriteProperty(Obj.Properties[I], S);
  for I := 0 to Obj.Children.Count - 1 do
    WriteObject(Obj.Children[I], S);
  Dec(FIndent);
  S := S + IndentStr + 'end' + FLineEnding;
end;

procedure TDfmTextWriter.WriteProperty(Prop: TFormProperty; var S: string);
begin
  S := S + IndentStr + Prop.Name + ' = ' + WriteValue(Prop.Value) + FLineEnding;
end;

function TDfmTextWriter.WriteValue(Value: TFormValue): string;
begin
  case Value.Kind of
    fvInteger:
    begin
      if Value.RawText <> '' then
        Result := Value.RawText
      else
        Result := IntToStr(Value.IntValue);
    end;
    fvFloat:
    begin
      if Value.RawText <> '' then
        Result := Value.RawText
      else
        Result := FloatToStr(Value.FloatValue, TFormatSettings.Invariant);
    end;
    fvString:
      Result := WriteStringValue(Value);
    fvBoolean:
    begin
      if Value.BoolValue then
        Result := 'True'
      else
        Result := 'False';
    end;
    fvIdentifier:
    begin
      if Value.RawText <> '' then
        Result := Value.RawText
      else
        Result := Value.IdentValue;
    end;
    fvSet:
      Result := WriteSetValue(Value);
    fvBinary:
      Result := WriteBinaryValue(Value);
    fvList:
      Result := WriteListValue(Value);
    fvCollection:
      Result := WriteCollectionValue(Value);
  end;
end;

function TDfmTextWriter.WriteStringValue(Value: TFormValue): string;
begin
  if Value.RawText <> '' then
    Result := Value.RawText
  else
    Result := '''' + StringReplace(Value.StringValue, '''', '''''', [rfReplaceAll]) + '''';
end;

function TDfmTextWriter.WriteSetValue(Value: TFormValue): string;
var
  I: Integer;
begin
  Result := '[';
  for I := 0 to Length(Value.SetItems) - 1 do
  begin
    if I > 0 then
      Result := Result + ', ';
    Result := Result + Value.SetItems[I];
  end;
  Result := Result + ']';
end;

function TDfmTextWriter.WriteBinaryValue(Value: TFormValue): string;
var
  Hex: string;
  I: Integer;
  InnerIndent: string;
begin
  if Value.RawText <> '' then
  begin
    Result := Value.RawText;
    Exit;
  end;
  // Canonical: { on same line, hex wrapped at 64 chars, } on own line
  Hex := '';
  for I := 0 to Length(Value.BinaryData) - 1 do
    Hex := Hex + IntToHex(Value.BinaryData[I], 2);
  if Length(Hex) <= 64 then
  begin
    Result := '{' + Hex + '}';
  end
  else
  begin
    InnerIndent := StringOfChar(' ', (FIndent + 1) * 2);
    Result := '{' + FLineEnding;
    I := 1;
    while I <= Length(Hex) do
    begin
      Result := Result + InnerIndent + Copy(Hex, I, 64) + FLineEnding;
      Inc(I, 64);
    end;
    Result := Result + InnerIndent + '}';
  end;
end;

function TDfmTextWriter.WriteListValue(Value: TFormValue): string;
var
  I: Integer;
  InnerIndent: string;
begin
  InnerIndent := StringOfChar(' ', (FIndent + 1) * 2);
  Result := '(' + FLineEnding;
  for I := 0 to Value.ListItems.Count - 1 do
  begin
    if I < Value.ListItems.Count - 1 then
      Result := Result + InnerIndent + WriteValue(Value.ListItems[I]) + FLineEnding
    else
      Result := Result + InnerIndent + WriteValue(Value.ListItems[I]) + ')';
  end;
end;

function TDfmTextWriter.WriteCollectionValue(Value: TFormValue): string;
var
  I, J: Integer;
  InnerIndent: string;
  ItemIndent: string;
  Item: TFormObject;
begin
  InnerIndent := StringOfChar(' ', (FIndent + 1) * 2);
  ItemIndent := StringOfChar(' ', (FIndent + 2) * 2);
  Result := '<' + FLineEnding;
  for I := 0 to Value.CollectionItems.Count - 1 do
  begin
    Item := Value.CollectionItems[I];
    Result := Result + InnerIndent + 'item' + FLineEnding;
    for J := 0 to Item.Properties.Count - 1 do
      Result := Result + ItemIndent + Item.Properties[J].Name + ' = ' + WriteValue(Item.Properties[J].Value) + FLineEnding;
    Result := Result + InnerIndent + 'end';
    if I < Value.CollectionItems.Count - 1 then
      Result := Result + FLineEnding
    else
      Result := Result + '>';
  end;
end;

function TDfmTextWriter.Write(FormFile: TFormFile): string;
begin
  FIndent := 0;
  Result := '';
  if FormFile.Root <> nil then
    WriteObject(FormFile.Root, Result);
end;

end.
