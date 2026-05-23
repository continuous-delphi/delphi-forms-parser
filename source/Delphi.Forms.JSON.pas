unit Delphi.Forms.JSON;

interface

uses
  System.JSON,
  Delphi.Forms.Types;

type

  TFormJsonOption = (joIncludeValues, joIncludePositions, joPrettyPrint, joIncludeRawText);
  TFormJsonOptions = set of TFormJsonOption;

const
  DefaultJsonOptions: TFormJsonOptions = [joIncludeValues, joPrettyPrint];

function FormFileToJSON(FormFile: TFormFile; Options: TFormJsonOptions = [joIncludeValues, joPrettyPrint]): TJSONObject;
function FormFileToJSONString(FormFile: TFormFile; Options: TFormJsonOptions = [joIncludeValues, joPrettyPrint]): string;
function FormObjectToJSON(Obj: TFormObject; Options: TFormJsonOptions = [joIncludeValues, joPrettyPrint]): TJSONObject;
function FormPropertyToJSON(Prop: TFormProperty; Options: TFormJsonOptions = [joIncludeValues, joPrettyPrint]): TJSONObject;
function FormValuePreview(Value: TFormValue): string;
function FormValueKindName(Kind: TFormValueKind): string;
function FormObjectKindName(Kind: TObjectKind): string;

implementation

uses
  System.SysUtils;

function FormObjectKindName(Kind: TObjectKind): string;
begin
  case Kind of
    okObject: Result := 'object';
    okInherited: Result := 'inherited';
    okInline: Result := 'inline';
  else
    Result := 'object';
  end;
end;

function FormValueKindName(Kind: TFormValueKind): string;
begin
  case Kind of
    fvInteger: Result := 'fvInteger';
    fvFloat: Result := 'fvFloat';
    fvString: Result := 'fvString';
    fvBoolean: Result := 'fvBoolean';
    fvIdentifier: Result := 'fvIdentifier';
    fvSet: Result := 'fvSet';
    fvBinary: Result := 'fvBinary';
    fvList: Result := 'fvList';
    fvCollection: Result := 'fvCollection';
  else
    Result := '?';
  end;
end;

function FormValuePreview(Value: TFormValue): string;
const
  MaxLen = 60;
var
  I: Integer;
begin
  case Value.Kind of
    fvInteger:
      if Value.RawText <> '' then
        Result := Value.RawText
      else
        Result := IntToStr(Value.IntValue);
    fvFloat:
      if Value.RawText <> '' then
        Result := Value.RawText
      else
        Result := FloatToStr(Value.FloatValue, TFormatSettings.Invariant);
    fvString:
    begin
      Result := '''' + Copy(Value.StringValue, 1, MaxLen) + '''';
      if Length(Value.StringValue) > MaxLen then
        Result := Result + '...';
    end;
    fvBoolean:
      if Value.BoolValue then Result := 'True' else Result := 'False';
    fvIdentifier:
      Result := Value.IdentValue;
    fvSet:
    begin
      Result := '[';
      for I := 0 to Length(Value.SetItems) - 1 do
      begin
        if I > 0 then Result := Result + ', ';
        Result := Result + Value.SetItems[I];
      end;
      Result := Result + ']';
    end;
    fvBinary:
      Result := Format('{%d bytes}', [Length(Value.BinaryData)]);
    fvList:
      Result := Format('(%d items)', [Value.ListItems.Count]);
    fvCollection:
      Result := Format('<%d items>', [Value.CollectionItems.Count]);
  else
    Result := '?';
  end;
end;

function FormPropertyToJSON(Prop: TFormProperty; Options: TFormJsonOptions): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', Prop.Name);
  Result.AddPair('kind', FormValueKindName(Prop.Value.Kind));
  if joIncludeValues in Options then
    Result.AddPair('value', FormValuePreview(Prop.Value));
  if joIncludeRawText in Options then
    if Prop.Value.RawText <> '' then
      Result.AddPair('rawText', Prop.Value.RawText);
  if joIncludePositions in Options then
  begin
    Result.AddPair('sourceStart', TJSONNumber.Create(Prop.SourceStart));
    Result.AddPair('sourceEnd', TJSONNumber.Create(Prop.SourceEnd));
  end;
end;

function FormObjectToJSON(Obj: TFormObject; Options: TFormJsonOptions): TJSONObject;
var
  Props: TJSONArray;
  Children: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('objectKind', FormObjectKindName(Obj.ObjectKind));
  Result.AddPair('name', Obj.Name);
  Result.AddPair('className', Obj.ClassName_);
  if joIncludePositions in Options then
  begin
    Result.AddPair('sourceStart', TJSONNumber.Create(Obj.SourceStart));
    Result.AddPair('sourceEnd', TJSONNumber.Create(Obj.SourceEnd));
  end;
  Props := TJSONArray.Create;
  for I := 0 to Obj.Properties.Count - 1 do
    Props.AddElement(FormPropertyToJSON(Obj.Properties[I], Options));
  Result.AddPair('properties', Props);
  Children := TJSONArray.Create;
  for I := 0 to Obj.Children.Count - 1 do
    Children.AddElement(FormObjectToJSON(Obj.Children[I], Options));
  Result.AddPair('children', Children);
end;

function FormFileToJSON(FormFile: TFormFile; Options: TFormJsonOptions): TJSONObject;
begin
  Result := TJSONObject.Create;
  if FormFile.Root <> nil then
    Result.AddPair('root', FormObjectToJSON(FormFile.Root, Options));
end;

function FormFileToJSONString(FormFile: TFormFile; Options: TFormJsonOptions): string;
var
  Json: TJSONObject;
begin
  Json := FormFileToJSON(FormFile, Options);
  try
    if joPrettyPrint in Options then
      Result := Json.Format(2)
    else
      Result := Json.ToJSON;
  finally
    Json.Free;
  end;
end;

end.
