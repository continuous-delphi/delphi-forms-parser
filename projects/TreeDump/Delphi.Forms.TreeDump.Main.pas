(*

  delphi-forms-parser
  https://github.com/continuous-delphi/delphi-forms-parser

  A standalone parser for VCL and FMX form files (.dfm/.fmx) in both
  text and binary formats. Produces a typed AST with full round-trip
  fidelity.

  License: MIT
  Copyright (c) 2026 Darian Miller

*)

unit Delphi.Forms.TreeDump.Main;

// DFM/FMX tree dump utility for delphi-forms-parser.
//
// Reads a form file (.dfm/.fmx), auto-detects text or binary format,
// parses it into a TFormFile AST, then writes an indented text
// representation of the component tree.
//
// Text output (default): each node on one line --
//   <indent><ObjectKind> <Name>: <ClassName>
//   <indent>  <PropertyName> = <value> [<valueKind>]
//
// Exit codes:
//   0 -- success
//   1 -- invalid parameters or file not found
//   2 -- parse error
//   3 -- round-trip invariant violated (text format only)

interface

uses
  System.JSON,
  Delphi.Forms.Types;

type

  TOutputFormat = (ofText, ofJson);

  TTreeDump = record
  private const
    AppName = 'Delphi.Forms.TreeDump';
    FormatVersion = '1.1.0';
    ExitCode_Success = 0;
    ExitCode_BadParams = 1;
    ExitCode_ParseError = 2;
    ExitCode_RoundTripFailed = 3;
  private
    class procedure ShowUsage; static;
    class procedure WriteObject(Obj: TFormObject; Depth: Integer; ShowValues: Boolean); static;
    class function ValueKindName(Kind: TFormValueKind): string; static;
    class function ObjectKindName(Kind: TObjectKind): string; static;
    class function ValuePreview(Value: TFormValue): string; static;
    class function ObjectToJSON(Obj: TFormObject): TJSONObject; static;
    class function PropertyToJSON(Prop: TFormProperty): TJSONObject; static;
    class function ValueToJSONValue(Value: TFormValue): string; static;
  public
    class function Run: Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Delphi.Forms,
  Delphi.Forms.Info;

class function TTreeDump.ObjectKindName(Kind: TObjectKind): string;
begin
  case Kind of
    okObject: Result := 'object';
    okInherited: Result := 'inherited';
    okInline: Result := 'inline';
  else
    Result := 'object';
  end;
end;

class function TTreeDump.ValueKindName(Kind: TFormValueKind): string;
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

class function TTreeDump.ValuePreview(Value: TFormValue): string;
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

class procedure TTreeDump.WriteObject(Obj: TFormObject; Depth: Integer; ShowValues: Boolean);
var
  Indent: string;
  PropIndent: string;
  I: Integer;
begin
  Indent := StringOfChar(' ', Depth * 2);
  PropIndent := StringOfChar(' ', (Depth + 1) * 2);

  WriteLn(Indent + ObjectKindName(Obj.ObjectKind) + ' ' + Obj.Name + ': ' + Obj.ClassName_);

  for I := 0 to Obj.Properties.Count - 1 do
  begin
    if ShowValues then
      WriteLn(PropIndent + Obj.Properties[I].Name + ' = ' + ValuePreview(Obj.Properties[I].Value) + ' [' + ValueKindName(Obj.Properties[I].Value.Kind) + ']')
    else
      WriteLn(PropIndent + Obj.Properties[I].Name + ' [' + ValueKindName(Obj.Properties[I].Value.Kind) + ']');
  end;

  for I := 0 to Obj.Children.Count - 1 do
    WriteObject(Obj.Children[I], Depth + 1, ShowValues);

  WriteLn(Indent + 'end');
end;

class function TTreeDump.ObjectToJSON(Obj: TFormObject): TJSONObject;
var
  Props: TJSONArray;
  Children: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('objectKind', ObjectKindName(Obj.ObjectKind));
  Result.AddPair('name', Obj.Name);
  Result.AddPair('className', Obj.ClassName_);
  Props := TJSONArray.Create;
  for I := 0 to Obj.Properties.Count - 1 do
    Props.AddElement(PropertyToJSON(Obj.Properties[I]));
  Result.AddPair('properties', Props);
  Children := TJSONArray.Create;
  for I := 0 to Obj.Children.Count - 1 do
    Children.AddElement(ObjectToJSON(Obj.Children[I]));
  Result.AddPair('children', Children);
end;

class function TTreeDump.PropertyToJSON(Prop: TFormProperty): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', Prop.Name);
  Result.AddPair('kind', ValueKindName(Prop.Value.Kind));
  Result.AddPair('value', ValueToJSONValue(Prop.Value));
end;

class function TTreeDump.ValueToJSONValue(Value: TFormValue): string;
begin
  Result := ValuePreview(Value);
end;

class procedure TTreeDump.ShowUsage;
begin
  WriteLn(AppName + ' v' + Delphi.Forms.Info.Version);
  WriteLn('Renders a DFM/FMX form file as a component tree');
  WriteLn('A command-line utility for delphi-forms-parser');
  WriteLn;
  WriteLn('Usage:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' <file> [options]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  --format:<name>       Output format: text (default) or json');
  WriteLn('  --no-values           Omit property values, show only names and types');
  WriteLn('  --round-trip          Verify text round-trip (parse -> write == original)');
  WriteLn('  -?, --help            Show this help and exit');
  WriteLn('  -v, --version         Show version and exit');
end;

class function TTreeDump.Run: Integer;
var
  I: Integer;
  Arg: string;
  FileName: string;
  ShowValues: Boolean;
  DoRoundTrip: Boolean;
  OutputFmt: TOutputFormat;
  F: TFormFile;
  Data: TBytes;
  DfmFmt: TDfmFormat;
  FmtStr: string;
  Source: string;
  Output: string;
  RoundTripResult: string;
  JsonRoot: TJSONObject;
  JsonSummary: TJSONObject;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  FileName := '';
  ShowValues := True;
  DoRoundTrip := False;
  OutputFmt := ofText;
  FmtStr := '';

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
    if SameText(Arg, '--no-values') then
      ShowValues := False
    else if SameText(Arg, '--round-trip') then
      DoRoundTrip := True
    else if SameText(Copy(Arg, 1, 9), '--format:') then
      FmtStr := Copy(Arg, 10, MaxInt)
    else if (Arg <> '') and (Arg[1] = '-') then
    begin
      WriteLn('error: unknown option: ', Arg);
      Exit(ExitCode_BadParams);
    end
    else if FileName = '' then
      FileName := Arg
    else
    begin
      WriteLn('error: too many input files');
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
      WriteLn('Supported formats: text, json');
      Exit(ExitCode_BadParams);
    end;
  end;

  if FileName = '' then
  begin
    ShowUsage;
    Exit(ExitCode_BadParams);
  end;

  if not TFile.Exists(FileName) then
  begin
    WriteLn('error: file not found: ', FileName);
    Exit(ExitCode_BadParams);
  end;

  Data := TFile.ReadAllBytes(FileName);
  DfmFmt := TDelphiFormsParser.DetectFormat(Data);

  F := nil;
  try
    try
      F := TDelphiFormsParser.ParseBytes(Data);
    except
      on E: Exception do
      begin
        WriteLn('error: parse failed: ', E.Message);
        Exit(ExitCode_ParseError);
      end;
    end;

    // Round-trip check (text format only)
    RoundTripResult := '';
    if DoRoundTrip and (DfmFmt = dfText) then
    begin
      Source := TEncoding.UTF8.GetString(Data);
      Source := StringReplace(Source, #13#10, #10, [rfReplaceAll]);
      Source := StringReplace(Source, #10, #13#10, [rfReplaceAll]);
      Output := TDelphiFormsParser.WriteText(F);
      if Source = Output then
        RoundTripResult := 'Pass'
      else
        RoundTripResult := 'FAIL';
    end;

    Result := ExitCode_Success;
    case OutputFmt of
      ofText:
      begin
        WriteLn;
        WriteLn(AppName);
        WriteLn('inputFile: ', FileName);
        if DfmFmt = dfBinary then
          WriteLn('format: binary')
        else
          WriteLn('format: text');
        WriteLn('formatVersion: ', FormatVersion);
        WriteLn;

        WriteObject(F.Root, 0, ShowValues);

        WriteLn;
        WriteLn('Properties: ', F.Root.Properties.Count, '; Children: ', F.Root.Children.Count);

        if RoundTripResult <> '' then
        begin
          if RoundTripResult = 'Pass' then
            WriteLn('Round-trip: Pass')
          else
          begin
            WriteLn('Round-trip: FAIL ***');
            Exit(ExitCode_RoundTripFailed);
          end;
        end;

        Result := ExitCode_Success;
        WriteLn('Exit Code: ', Result);
      end;
      ofJson:
      begin
        JsonRoot := TJSONObject.Create;
        try
          JsonRoot.AddPair('formatVersion', FormatVersion);
          JsonRoot.AddPair('inputFile', FileName);
          if DfmFmt = dfBinary then
            JsonRoot.AddPair('format', 'binary')
          else
            JsonRoot.AddPair('format', 'text');
          JsonRoot.AddPair('root', ObjectToJSON(F.Root));
          JsonSummary := TJSONObject.Create;
          JsonSummary.AddPair('properties', TJSONNumber.Create(F.Root.Properties.Count));
          JsonSummary.AddPair('children', TJSONNumber.Create(F.Root.Children.Count));
          if RoundTripResult <> '' then
            JsonSummary.AddPair('roundTrip', RoundTripResult);
          JsonRoot.AddPair('summary', JsonSummary);
          WriteLn(JsonRoot.Format(2));
        finally
          JsonRoot.Free;
        end;

        if RoundTripResult = 'FAIL' then
          Exit(ExitCode_RoundTripFailed);

        Result := ExitCode_Success;
      end;
    end;
  finally
    F.Free;
  end;
end;

end.
