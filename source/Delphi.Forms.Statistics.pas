unit Delphi.Forms.Statistics;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  System.Generics.Defaults,
  Delphi.Forms.Types;

type

  TClassUsage = record
    Name: string;
    Count: Integer;
  end;

  TPropertyUsage = record
    Name: string;
    Count: Integer;
  end;

  TFormStatistics = record
    ComponentCount: Integer;
    UniqueClassCount: Integer;
    PropertyCount: Integer;
    MaxDepth: Integer;
    AvgDepth: Double;
    ValueTypeCounts: array[TFormValueKind] of Integer;
    ObjectKindCounts: array[TObjectKind] of Integer;
    TopClasses: TArray<TClassUsage>;
    TopProperties: TArray<TPropertyUsage>;
    function ToJSON: TJSONObject;
  end;

  TFormStatisticsHelper = record
  private
    class procedure CollectObject(Obj: TFormObject; Depth: Integer; var ComponentCount, PropertyCount, MaxDepth, DepthSum: Integer; var ObjectKindCounts: array of Integer; var ValueKindCounts: array of Integer; ClassCounts, PropNameCounts: TDictionary<string, Integer>); static;
    class function GetTopN(Dict: TDictionary<string, Integer>; N: Integer): TArray<TPair<string, Integer>>; static;
  public
    class function ComputeStatistics(Form: TFormFile; ATopN: Integer = 10): TFormStatistics; overload; static;
    class function ComputeStatistics(const Forms: TArray<TFormFile>; ATopN: Integer = 10): TFormStatistics; overload; static;
  end;

implementation

uses
  Delphi.Forms.JSON;

{ TFormStatistics }

function TFormStatistics.ToJSON: TJSONObject;
var
  VK: TFormValueKind;
  OK: TObjectKind;
  ValueTypes: TJSONObject;
  ObjKinds: TJSONObject;
  TopClassesArr: TJSONArray;
  TopPropsArr: TJSONArray;
  Item: TJSONObject;
  CU: TClassUsage;
  PU: TPropertyUsage;
begin
  Result := TJSONObject.Create;
  Result.AddPair('componentCount', TJSONNumber.Create(ComponentCount));
  Result.AddPair('uniqueClasses', TJSONNumber.Create(UniqueClassCount));
  Result.AddPair('propertyCount', TJSONNumber.Create(PropertyCount));
  Result.AddPair('maxDepth', TJSONNumber.Create(MaxDepth));
  Result.AddPair('avgDepth', TJSONNumber.Create(AvgDepth));

  ValueTypes := TJSONObject.Create;
  for VK := Low(TFormValueKind) to High(TFormValueKind) do
    ValueTypes.AddPair(FormValueKindName(VK), TJSONNumber.Create(ValueTypeCounts[VK]));
  Result.AddPair('valueTypes', ValueTypes);

  ObjKinds := TJSONObject.Create;
  for OK := Low(TObjectKind) to High(TObjectKind) do
    ObjKinds.AddPair(FormObjectKindName(OK), TJSONNumber.Create(ObjectKindCounts[OK]));
  Result.AddPair('objectKinds', ObjKinds);

  TopClassesArr := TJSONArray.Create;
  for CU in TopClasses do
  begin
    Item := TJSONObject.Create;
    Item.AddPair('name', CU.Name);
    Item.AddPair('count', TJSONNumber.Create(CU.Count));
    TopClassesArr.AddElement(Item);
  end;
  Result.AddPair('topClasses', TopClassesArr);

  TopPropsArr := TJSONArray.Create;
  for PU in TopProperties do
  begin
    Item := TJSONObject.Create;
    Item.AddPair('name', PU.Name);
    Item.AddPair('count', TJSONNumber.Create(PU.Count));
    TopPropsArr.AddElement(Item);
  end;
  Result.AddPair('topProperties', TopPropsArr);
end;

{ TFormStatisticsHelper }

class procedure TFormStatisticsHelper.CollectObject(Obj: TFormObject; Depth: Integer; var ComponentCount, PropertyCount, MaxDepth, DepthSum: Integer; var ObjectKindCounts: array of Integer; var ValueKindCounts: array of Integer; ClassCounts, PropNameCounts: TDictionary<string, Integer>);
var
  I: Integer;
  Count: Integer;
begin
  Inc(ComponentCount);
  if Depth > MaxDepth then
    MaxDepth := Depth;
  DepthSum := DepthSum + Depth;
  Inc(ObjectKindCounts[Ord(Obj.ObjectKind)]);

  if Obj.ClassName_ <> '' then
  begin
    if ClassCounts.TryGetValue(Obj.ClassName_, Count) then
      ClassCounts[Obj.ClassName_] := Count + 1
    else
      ClassCounts.Add(Obj.ClassName_, 1);
  end;

  for I := 0 to Obj.Properties.Count - 1 do
  begin
    Inc(PropertyCount);
    Inc(ValueKindCounts[Ord(Obj.Properties[I].Value.Kind)]);
    if PropNameCounts.TryGetValue(Obj.Properties[I].Name, Count) then
      PropNameCounts[Obj.Properties[I].Name] := Count + 1
    else
      PropNameCounts.Add(Obj.Properties[I].Name, 1);
  end;

  for I := 0 to Obj.Children.Count - 1 do
    CollectObject(Obj.Children[I], Depth + 1, ComponentCount, PropertyCount, MaxDepth, DepthSum, ObjectKindCounts, ValueKindCounts, ClassCounts, PropNameCounts);
end;

class function TFormStatisticsHelper.GetTopN(Dict: TDictionary<string, Integer>; N: Integer): TArray<TPair<string, Integer>>;
var
  Pairs: TArray<TPair<string, Integer>>;
begin
  Pairs := Dict.ToArray;
  TArray.Sort<TPair<string, Integer>>(Pairs,
    TComparer<TPair<string, Integer>>.Construct(
      function(const A, B: TPair<string, Integer>): Integer
      begin
        Result := B.Value - A.Value;
      end));
  if Length(Pairs) > N then
    SetLength(Pairs, N);
  Result := Pairs;
end;

class function TFormStatisticsHelper.ComputeStatistics(Form: TFormFile; ATopN: Integer): TFormStatistics;
begin
  Result := ComputeStatistics(TArray<TFormFile>.Create(Form), ATopN);
end;

class function TFormStatisticsHelper.ComputeStatistics(const Forms: TArray<TFormFile>; ATopN: Integer): TFormStatistics;
var
  VK: TFormValueKind;
  OK: TObjectKind;
  ComponentCount, PropertyCount, MaxDepth, DepthSum: Integer;
  ObjectKindCounts: array[TObjectKind] of Integer;
  ValueKindCounts: array[TFormValueKind] of Integer;
  ClassCounts: TDictionary<string, Integer>;
  PropNameCounts: TDictionary<string, Integer>;
  Pairs: TArray<TPair<string, Integer>>;
  I: Integer;
  F: TFormFile;
begin
  ComponentCount := 0;
  PropertyCount := 0;
  MaxDepth := 0;
  DepthSum := 0;
  for OK := Low(TObjectKind) to High(TObjectKind) do
    ObjectKindCounts[OK] := 0;
  for VK := Low(TFormValueKind) to High(TFormValueKind) do
    ValueKindCounts[VK] := 0;

  ClassCounts := TDictionary<string, Integer>.Create;
  PropNameCounts := TDictionary<string, Integer>.Create;
  try
    for F in Forms do
      if F.Root <> nil then
        CollectObject(F.Root, 0, ComponentCount, PropertyCount, MaxDepth, DepthSum, ObjectKindCounts, ValueKindCounts, ClassCounts, PropNameCounts);

    Result.ComponentCount := ComponentCount;
    Result.PropertyCount := PropertyCount;
    Result.MaxDepth := MaxDepth;
    if ComponentCount > 0 then
      Result.AvgDepth := DepthSum / ComponentCount
    else
      Result.AvgDepth := 0;
    Result.UniqueClassCount := ClassCounts.Count;

    for VK := Low(TFormValueKind) to High(TFormValueKind) do
      Result.ValueTypeCounts[VK] := ValueKindCounts[VK];
    for OK := Low(TObjectKind) to High(TObjectKind) do
      Result.ObjectKindCounts[OK] := ObjectKindCounts[OK];

    Pairs := GetTopN(ClassCounts, ATopN);
    SetLength(Result.TopClasses, Length(Pairs));
    for I := 0 to Length(Pairs) - 1 do
    begin
      Result.TopClasses[I].Name := Pairs[I].Key;
      Result.TopClasses[I].Count := Pairs[I].Value;
    end;

    Pairs := GetTopN(PropNameCounts, ATopN);
    SetLength(Result.TopProperties, Length(Pairs));
    for I := 0 to Length(Pairs) - 1 do
    begin
      Result.TopProperties[I].Name := Pairs[I].Key;
      Result.TopProperties[I].Count := Pairs[I].Value;
    end;
  finally
    PropNameCounts.Free;
    ClassCounts.Free;
  end;
end;

end.
