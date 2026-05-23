unit Delphi.Forms.FormStats.Main;

interface

uses
  System.JSON,
  System.Generics.Collections,
  System.Generics.Defaults,
  Delphi.Forms.Types;

type

  TFormStats = record
  private const
    AppName = 'Delphi.Forms.FormStats';
    ExitCode_Success = 0;
    ExitCode_BadParams = 1;
    ExitCode_ParseFailures = 2;
  private type
    TOutputFormat = (ofText, ofJson);
    TStats = record
      FileCount: Integer;
      TextFileCount: Integer;
      BinaryFileCount: Integer;
      ComponentCount: Integer;
      PropertyCount: Integer;
      MaxDepth: Integer;
      DepthSum: Integer;
      ObjectKindCounts: array[TObjectKind] of Integer;
      ValueKindCounts: array[TFormValueKind] of Integer;
      ClassCounts: TDictionary<string, Integer>;
      PropNameCounts: TDictionary<string, Integer>;
      ParseFailures: Integer;
      procedure Init;
      procedure Finalize;
    end;
  private
    class procedure ShowUsage; static;
    class procedure CollectObject(Obj: TFormObject; Depth: Integer; var Stats: TStats); static;
    class procedure ProcessFile(const FileName: string; var Stats: TStats); static;
    class procedure ScanDirectory(const Dir: string; Recursive: Boolean; var Stats: TStats); static;
    class procedure WriteTextOutput(const Path: string; const Stats: TStats; ATopN: Integer); static;
    class procedure WriteJSONOutput(const Path: string; const Stats: TStats; ATopN: Integer); static;
    class function ValueKindName(Kind: TFormValueKind): string; static;
    class function ObjectKindName(Kind: TObjectKind): string; static;
    class function TopN(Dict: TDictionary<string, Integer>; N: Integer): TArray<TPair<string, Integer>>; static;
  public
    class function Run: Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Math,
  Delphi.Forms,
  Delphi.Forms.Info;

{ TFormStats.TStats }

procedure TFormStats.TStats.Init;
var
  OK: TObjectKind;
  VK: TFormValueKind;
begin
  FileCount := 0;
  TextFileCount := 0;
  BinaryFileCount := 0;
  ComponentCount := 0;
  PropertyCount := 0;
  MaxDepth := 0;
  DepthSum := 0;
  ParseFailures := 0;
  for OK := Low(TObjectKind) to High(TObjectKind) do
    ObjectKindCounts[OK] := 0;
  for VK := Low(TFormValueKind) to High(TFormValueKind) do
    ValueKindCounts[VK] := 0;
  ClassCounts := TDictionary<string, Integer>.Create;
  PropNameCounts := TDictionary<string, Integer>.Create;
end;

procedure TFormStats.TStats.Finalize;
begin
  ClassCounts.Free;
  PropNameCounts.Free;
end;

{ TFormStats }

class function TFormStats.ValueKindName(Kind: TFormValueKind): string;
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

class function TFormStats.ObjectKindName(Kind: TObjectKind): string;
begin
  case Kind of
    okObject: Result := 'object';
    okInherited: Result := 'inherited';
    okInline: Result := 'inline';
  else
    Result := 'object';
  end;
end;

class function TFormStats.TopN(Dict: TDictionary<string, Integer>; N: Integer): TArray<TPair<string, Integer>>;
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

class procedure TFormStats.CollectObject(Obj: TFormObject; Depth: Integer; var Stats: TStats);
var
  I: Integer;
  Count: Integer;
begin
  Inc(Stats.ComponentCount);
  if Depth > Stats.MaxDepth then
    Stats.MaxDepth := Depth;
  Stats.DepthSum := Stats.DepthSum + Depth;

  Inc(Stats.ObjectKindCounts[Obj.ObjectKind]);

  if Obj.ClassName_ <> '' then
  begin
    if Stats.ClassCounts.TryGetValue(Obj.ClassName_, Count) then
      Stats.ClassCounts[Obj.ClassName_] := Count + 1
    else
      Stats.ClassCounts.Add(Obj.ClassName_, 1);
  end;

  for I := 0 to Obj.Properties.Count - 1 do
  begin
    Inc(Stats.PropertyCount);
    Inc(Stats.ValueKindCounts[Obj.Properties[I].Value.Kind]);

    if Stats.PropNameCounts.TryGetValue(Obj.Properties[I].Name, Count) then
      Stats.PropNameCounts[Obj.Properties[I].Name] := Count + 1
    else
      Stats.PropNameCounts.Add(Obj.Properties[I].Name, 1);
  end;

  for I := 0 to Obj.Children.Count - 1 do
    CollectObject(Obj.Children[I], Depth + 1, Stats);
end;

class procedure TFormStats.ProcessFile(const FileName: string; var Stats: TStats);
var
  Data: TBytes;
  F: TFormFile;
begin
  Inc(Stats.FileCount);
  try
    Data := TFile.ReadAllBytes(FileName);
    if TDelphiFormsParser.IsBinaryDfm(Data) then
      Inc(Stats.BinaryFileCount)
    else
      Inc(Stats.TextFileCount);

    F := TDelphiFormsParser.ParseBytes(Data);
    try
      if F.Root <> nil then
        CollectObject(F.Root, 0, Stats);
    finally
      F.Free;
    end;
  except
    on E: Exception do
    begin
      Inc(Stats.ParseFailures);
      WriteLn(ErrOutput, 'warning: failed to parse ', FileName, ': ', E.Message);
    end;
  end;
end;

class procedure TFormStats.ScanDirectory(const Dir: string; Recursive: Boolean; var Stats: TStats);
var
  Files: TArray<string>;
  FileName: string;
  SearchOpt: TSearchOption;
begin
  if Recursive then
    SearchOpt := TSearchOption.soAllDirectories
  else
    SearchOpt := TSearchOption.soTopDirectoryOnly;

  Files := TDirectory.GetFiles(Dir, '*.dfm', SearchOpt);
  for FileName in Files do
    ProcessFile(FileName, Stats);

  Files := TDirectory.GetFiles(Dir, '*.fmx', SearchOpt);
  for FileName in Files do
    ProcessFile(FileName, Stats);
end;

class procedure TFormStats.WriteTextOutput(const Path: string; const Stats: TStats; ATopN: Integer);
var
  VK: TFormValueKind;
  OK: TObjectKind;
  Pairs: TArray<TPair<string, Integer>>;
  Pair: TPair<string, Integer>;
  Pct: Double;
  AvgDepth: Double;
begin
  WriteLn;
  WriteLn(AppName);
  WriteLn('Path: ', Path);
  WriteLn('Files: ', Stats.FileCount, ' (', Stats.TextFileCount, ' text, ', Stats.BinaryFileCount, ' binary)');
  WriteLn;
  WriteLn('Components:     ', Stats.ComponentCount);
  WriteLn('Unique classes: ', Stats.ClassCounts.Count);
  WriteLn('Properties:     ', Stats.PropertyCount);
  WriteLn('Max depth:      ', Stats.MaxDepth);
  if Stats.ComponentCount > 0 then
    AvgDepth := Stats.DepthSum / Stats.ComponentCount
  else
    AvgDepth := 0;
  WriteLn('Avg depth:      ', FormatFloat('0.0', AvgDepth));
  WriteLn;

  WriteLn('Value types:');
  for VK := Low(TFormValueKind) to High(TFormValueKind) do
  begin
    if Stats.PropertyCount > 0 then
      Pct := Stats.ValueKindCounts[VK] / Stats.PropertyCount * 100
    else
      Pct := 0;
    WriteLn(Format('  %-14s %6d (%5.1f%%)', [ValueKindName(VK) + ':', Stats.ValueKindCounts[VK], Pct]));
  end;
  WriteLn;

  WriteLn('Object kinds:');
  for OK := Low(TObjectKind) to High(TObjectKind) do
    WriteLn(Format('  %-14s %6d', [ObjectKindName(OK) + ':', Stats.ObjectKindCounts[OK]]));
  WriteLn;

  Pairs := TopN(Stats.ClassCounts, ATopN);
  WriteLn('Top ', Length(Pairs), ' classes:');
  for Pair in Pairs do
    WriteLn(Format('  %-20s %d', [Pair.Key, Pair.Value]));
  WriteLn;

  Pairs := TopN(Stats.PropNameCounts, ATopN);
  WriteLn('Top ', Length(Pairs), ' properties:');
  for Pair in Pairs do
    WriteLn(Format('  %-20s %d', [Pair.Key, Pair.Value]));
  WriteLn;

  WriteLn('Parse failures: ', Stats.ParseFailures);
end;

class procedure TFormStats.WriteJSONOutput(const Path: string; const Stats: TStats; ATopN: Integer);
var
  Root: TJSONObject;
  ValueTypes: TJSONObject;
  ObjKinds: TJSONObject;
  TopClasses: TJSONArray;
  TopProps: TJSONArray;
  Item: TJSONObject;
  VK: TFormValueKind;
  OK: TObjectKind;
  Pairs: TArray<TPair<string, Integer>>;
  Pair: TPair<string, Integer>;
  AvgDepth: Double;
begin
  if Stats.ComponentCount > 0 then
    AvgDepth := Stats.DepthSum / Stats.ComponentCount
  else
    AvgDepth := 0;

  Root := TJSONObject.Create;
  try
    Root.AddPair('path', Path);
    Root.AddPair('fileCount', TJSONNumber.Create(Stats.FileCount));
    Root.AddPair('textFileCount', TJSONNumber.Create(Stats.TextFileCount));
    Root.AddPair('binaryFileCount', TJSONNumber.Create(Stats.BinaryFileCount));
    Root.AddPair('componentCount', TJSONNumber.Create(Stats.ComponentCount));
    Root.AddPair('uniqueClasses', TJSONNumber.Create(Stats.ClassCounts.Count));
    Root.AddPair('propertyCount', TJSONNumber.Create(Stats.PropertyCount));
    Root.AddPair('maxDepth', TJSONNumber.Create(Stats.MaxDepth));
    Root.AddPair('avgDepth', TJSONNumber.Create(AvgDepth));

    ValueTypes := TJSONObject.Create;
    for VK := Low(TFormValueKind) to High(TFormValueKind) do
      ValueTypes.AddPair(ValueKindName(VK), TJSONNumber.Create(Stats.ValueKindCounts[VK]));
    Root.AddPair('valueTypes', ValueTypes);

    ObjKinds := TJSONObject.Create;
    for OK := Low(TObjectKind) to High(TObjectKind) do
      ObjKinds.AddPair(ObjectKindName(OK), TJSONNumber.Create(Stats.ObjectKindCounts[OK]));
    Root.AddPair('objectKinds', ObjKinds);

    Pairs := TopN(Stats.ClassCounts, ATopN);
    TopClasses := TJSONArray.Create;
    for Pair in Pairs do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('name', Pair.Key);
      Item.AddPair('count', TJSONNumber.Create(Pair.Value));
      TopClasses.AddElement(Item);
    end;
    Root.AddPair('topClasses', TopClasses);

    Pairs := TopN(Stats.PropNameCounts, ATopN);
    TopProps := TJSONArray.Create;
    for Pair in Pairs do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('name', Pair.Key);
      Item.AddPair('count', TJSONNumber.Create(Pair.Value));
      TopProps.AddElement(Item);
    end;
    Root.AddPair('topProperties', TopProps);

    Root.AddPair('parseFailures', TJSONNumber.Create(Stats.ParseFailures));

    WriteLn(Root.Format(2));
  finally
    Root.Free;
  end;
end;

class procedure TFormStats.ShowUsage;
begin
  WriteLn(AppName + ' v' + Delphi.Forms.Info.Version);
  WriteLn('Component and property statistics for DFM/FMX form files');
  WriteLn('A command-line utility for delphi-forms-parser');
  WriteLn;
  WriteLn('Usage:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' <file-or-dir> [options]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  --recursive           Scan subdirectories');
  WriteLn('  --format:<name>       Output format: text (default) or json');
  WriteLn('  --top:<N>             Number of top classes/properties to show (default 10)');
  WriteLn('  -?, --help            Show this help and exit');
  WriteLn('  -v, --version         Show version and exit');
end;

class function TFormStats.Run: Integer;
var
  I: Integer;
  Arg: string;
  Path: string;
  Recursive: Boolean;
  OutputFmt: TOutputFormat;
  FmtStr: string;
  ATopN: Integer;
  TopStr: string;
  Stats: TStats;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  Path := '';
  Recursive := False;
  OutputFmt := ofText;
  FmtStr := '';
  ATopN := 10;
  TopStr := '';

  for I := 1 to ParamCount do
  begin
    Arg := ParamStr(I);
    if SameText(Arg, '-?') or SameText(Arg, '--help') then
    begin
      ShowUsage;
      Exit(ExitCode_Success);
    end;
    if SameText(Arg, '-v') or SameText(Arg, '--version') then
    begin
      WriteLn(Delphi.Forms.Info.Version);
      Exit(ExitCode_Success);
    end;
    if SameText(Arg, '--recursive') then
      Recursive := True
    else if SameText(Copy(Arg, 1, 9), '--format:') then
      FmtStr := Copy(Arg, 10, MaxInt)
    else if SameText(Copy(Arg, 1, 6), '--top:') then
      TopStr := Copy(Arg, 7, MaxInt)
    else if (Arg <> '') and (Arg[1] = '-') then
    begin
      WriteLn('error: unknown option: ', Arg);
      Exit(ExitCode_BadParams);
    end
    else if Path = '' then
      Path := Arg
    else
    begin
      WriteLn('error: too many arguments');
      Exit(ExitCode_BadParams);
    end;
  end;

  if FmtStr <> '' then
  begin
    if SameText(FmtStr, 'json') then
      OutputFmt := ofJson
    else if SameText(FmtStr, 'text') then
      OutputFmt := ofText
    else
    begin
      WriteLn('error: unknown format: ', FmtStr);
      Exit(ExitCode_BadParams);
    end;
  end;

  if TopStr <> '' then
  begin
    if not TryStrToInt(TopStr, ATopN) or (ATopN < 1) then
    begin
      WriteLn('error: invalid --top value: ', TopStr);
      Exit(ExitCode_BadParams);
    end;
  end;

  if Path = '' then
  begin
    ShowUsage;
    Exit(ExitCode_BadParams);
  end;

  Stats.Init;
  try
    if TDirectory.Exists(Path) then
      ScanDirectory(Path, Recursive, Stats)
    else if TFile.Exists(Path) then
      ProcessFile(Path, Stats)
    else
    begin
      WriteLn('error: path not found: ', Path);
      Exit(ExitCode_BadParams);
    end;

    case OutputFmt of
      ofText: WriteTextOutput(Path, Stats, ATopN);
      ofJson: WriteJSONOutput(Path, Stats, ATopN);
    end;

    if Stats.ParseFailures > 0 then
      Result := ExitCode_ParseFailures
    else
      Result := ExitCode_Success;
  finally
    Stats.Finalize;
  end;
end;

end.
