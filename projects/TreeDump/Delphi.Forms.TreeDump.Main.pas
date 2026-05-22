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
  Delphi.Forms.Types;

type

  TTreeDump = record
  private const
    AppName = 'Delphi.Forms.TreeDump';
    FormatVersion = '1.0.0';
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
  F: TFormFile;
  Data: TBytes;
  Format: TDfmFormat;
  Source: string;
  Output: string;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  FileName := '';
  ShowValues := True;
  DoRoundTrip := False;

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
  Format := TDelphiFormsParser.DetectFormat(Data);

  WriteLn;
  WriteLn(AppName);
  WriteLn('inputFile: ', FileName);
  if Format = dfBinary then
    WriteLn('format: binary')
  else
    WriteLn('format: text');
  WriteLn('formatVersion: ', FormatVersion);
  WriteLn;

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

    WriteObject(F.Root, 0, ShowValues);

    // Summary
    WriteLn;
    WriteLn('Properties: ', F.Root.Properties.Count, '; Children: ', F.Root.Children.Count);

    // Round-trip check (text format only)
    if DoRoundTrip and (Format = dfText) then
    begin
      Source := TEncoding.UTF8.GetString(Data);
      // Normalize to CRLF
      Source := StringReplace(Source, #13#10, #10, [rfReplaceAll]);
      Source := StringReplace(Source, #10, #13#10, [rfReplaceAll]);
      Output := TDelphiFormsParser.WriteText(F);
      if Source = Output then
        WriteLn('Round-trip: Pass')
      else
      begin
        WriteLn('Round-trip: FAIL ***');
        WriteLn('  Expected length: ', Length(Source));
        WriteLn('  Actual length:   ', Length(Output));
        Exit(ExitCode_RoundTripFailed);
      end;
    end;

    Result := ExitCode_Success;
    WriteLn('Exit Code: ', Result);
  finally
    F.Free;
  end;
end;

end.
