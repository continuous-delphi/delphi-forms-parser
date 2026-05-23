unit Delphi.Forms.FormStats.Main;

interface

type

  TFormStats = record
  private const
    AppName = 'Delphi.Forms.FormStats';
    ExitCode_Success = 0;
    ExitCode_BadParams = 1;
    ExitCode_ParseFailures = 2;
  private type
    TOutputFormat = (ofText, ofJson);
    TFileStats = record
      FileCount: Integer;
      TextFileCount: Integer;
      BinaryFileCount: Integer;
      ParseFailures: Integer;
    end;
  private
    class procedure ShowUsage; static;
  public
    class function Run: Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  Delphi.Forms,
  Delphi.Forms.Types,
  Delphi.Forms.JSON,
  Delphi.Forms.Statistics,
  Delphi.Forms.Info;

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
  FileStats: TFileStats;
  Forms: TList<TFormFile>;
  Files: TArray<string>;
  FileName: string;
  Data: TBytes;
  F: TFormFile;
  Stats: TFormStatistics;
  VK: TFormValueKind;
  OK: TObjectKind;
  Pct: Double;
  CU: TClassUsage;
  PU: TPropertyUsage;
  JsonRoot: TJSONObject;
  StatsJson: TJSONObject;
  SearchOpt: TSearchOption;
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

  // Collect files and parse
  FileStats := Default(TFileStats);
  Forms := TList<TFormFile>.Create;
  try
    if TDirectory.Exists(Path) then
    begin
      if Recursive then
        SearchOpt := TSearchOption.soAllDirectories
      else
        SearchOpt := TSearchOption.soTopDirectoryOnly;
      Files := TDirectory.GetFiles(Path, '*.dfm', SearchOpt);
      for FileName in TDirectory.GetFiles(Path, '*.fmx', SearchOpt) do
      begin
        SetLength(Files, Length(Files) + 1);
        Files[High(Files)] := FileName;
      end;
      for FileName in Files do
      begin
        Inc(FileStats.FileCount);
        try
          Data := TFile.ReadAllBytes(FileName);
          if TDelphiFormsParser.IsBinaryDfm(Data) then
            Inc(FileStats.BinaryFileCount)
          else
            Inc(FileStats.TextFileCount);
          F := TDelphiFormsParser.ParseBytes(Data);
          Forms.Add(F);
        except
          on E: Exception do
          begin
            Inc(FileStats.ParseFailures);
            WriteLn(ErrOutput, 'warning: failed to parse ', FileName, ': ', E.Message);
          end;
        end;
      end;
    end
    else if TFile.Exists(Path) then
    begin
      Inc(FileStats.FileCount);
      try
        Data := TFile.ReadAllBytes(Path);
        if TDelphiFormsParser.IsBinaryDfm(Data) then
          Inc(FileStats.BinaryFileCount)
        else
          Inc(FileStats.TextFileCount);
        F := TDelphiFormsParser.ParseBytes(Data);
        Forms.Add(F);
      except
        on E: Exception do
        begin
          Inc(FileStats.ParseFailures);
          WriteLn(ErrOutput, 'warning: failed to parse ', Path, ': ', E.Message);
        end;
      end;
    end
    else
    begin
      WriteLn('error: path not found: ', Path);
      Exit(ExitCode_BadParams);
    end;

    // Compute statistics via library
    Stats := TFormStatisticsHelper.ComputeStatistics(Forms.ToArray, ATopN);

    case OutputFmt of
      ofText:
      begin
        WriteLn;
        WriteLn(AppName);
        WriteLn('Path: ', Path);
        WriteLn('Files: ', FileStats.FileCount, ' (', FileStats.TextFileCount, ' text, ', FileStats.BinaryFileCount, ' binary)');
        WriteLn;
        WriteLn('Components:     ', Stats.ComponentCount);
        WriteLn('Unique classes: ', Stats.UniqueClassCount);
        WriteLn('Properties:     ', Stats.PropertyCount);
        WriteLn('Max depth:      ', Stats.MaxDepth);
        WriteLn('Avg depth:      ', FormatFloat('0.0', Stats.AvgDepth));
        WriteLn;
        WriteLn('Value types:');
        for VK := Low(TFormValueKind) to High(TFormValueKind) do
        begin
          if Stats.PropertyCount > 0 then
            Pct := Stats.ValueTypeCounts[VK] / Stats.PropertyCount * 100
          else
            Pct := 0;
          WriteLn(Format('  %-14s %6d (%5.1f%%)', [FormValueKindName(VK) + ':', Stats.ValueTypeCounts[VK], Pct]));
        end;
        WriteLn;
        WriteLn('Object kinds:');
        for OK := Low(TObjectKind) to High(TObjectKind) do
          WriteLn(Format('  %-14s %6d', [FormObjectKindName(OK) + ':', Stats.ObjectKindCounts[OK]]));
        WriteLn;
        WriteLn('Top ', Length(Stats.TopClasses), ' classes:');
        for CU in Stats.TopClasses do
          WriteLn(Format('  %-20s %d', [CU.Name, CU.Count]));
        WriteLn;
        WriteLn('Top ', Length(Stats.TopProperties), ' properties:');
        for PU in Stats.TopProperties do
          WriteLn(Format('  %-20s %d', [PU.Name, PU.Count]));
        WriteLn;
        WriteLn('Parse failures: ', FileStats.ParseFailures);
      end;
      ofJson:
      begin
        JsonRoot := TJSONObject.Create;
        try
          JsonRoot.AddPair('path', Path);
          JsonRoot.AddPair('fileCount', TJSONNumber.Create(FileStats.FileCount));
          JsonRoot.AddPair('textFileCount', TJSONNumber.Create(FileStats.TextFileCount));
          JsonRoot.AddPair('binaryFileCount', TJSONNumber.Create(FileStats.BinaryFileCount));
          StatsJson := Stats.ToJSON;
          // Merge stats fields into root
          for I := 0 to StatsJson.Count - 1 do
            JsonRoot.AddPair(StatsJson.Pairs[I].JsonString.Value, StatsJson.Pairs[I].JsonValue.Clone as TJSONValue);
          StatsJson.Free;
          JsonRoot.AddPair('parseFailures', TJSONNumber.Create(FileStats.ParseFailures));
          WriteLn(JsonRoot.Format(2));
        finally
          JsonRoot.Free;
        end;
      end;
    end;

    if FileStats.ParseFailures > 0 then
      Result := ExitCode_ParseFailures
    else
      Result := ExitCode_Success;
  finally
    for I := 0 to Forms.Count - 1 do
      Forms[I].Free;
    Forms.Free;
  end;
end;

end.
