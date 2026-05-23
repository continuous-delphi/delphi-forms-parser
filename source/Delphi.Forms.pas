unit Delphi.Forms;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Delphi.Forms.Types,
  Delphi.Forms.Diagnostics,
  Delphi.Forms.Parser,
  Delphi.Forms.TextWriter,
  Delphi.Forms.BinaryReader,
  Delphi.Forms.BinaryWriter;

type

  TDfmFormat = (dfText, dfBinary);

  TDelphiFormsParser = class
  private
    class function DetectTextEncoding(const Data: TBytes): TEncoding;
  public
    class function ParseFile(const FileName: string): TFormFile; overload;
    class function ParseFile(const FileName: string; Encoding: TEncoding): TFormFile; overload;
    class function ParseText(const Source: string): TFormFile;
    class function ParseBinary(const Data: TBytes): TFormFile;
    class function ParseBytes(const Data: TBytes): TFormFile; overload;
    class function ParseBytes(const Data: TBytes; Encoding: TEncoding): TFormFile; overload;

    class function ParseTextWithDiagnostics(const Source: string): TParseResult;
    class function ParseBinaryWithDiagnostics(const Data: TBytes): TParseResult;
    class function ParseFileWithDiagnostics(const FileName: string): TParseResult;
    class function ParseBytesWithDiagnostics(const Data: TBytes): TParseResult;

    class function WriteText(FormFile: TFormFile): string;
    class function WriteBinary(FormFile: TFormFile): TBytes;

    class function BinaryToText(const Data: TBytes): string;
    class function TextToBinary(const Source: string): TBytes;

    class function DetectFormat(const Data: TBytes): TDfmFormat;
    class function IsBinaryDfm(const Data: TBytes): Boolean;
  end;

implementation

{ TDelphiFormsParser }

class function TDelphiFormsParser.DetectFormat(const Data: TBytes): TDfmFormat;
begin
  if IsBinaryDfm(Data) then
    Result := dfBinary
  else
    Result := dfText;
end;

class function TDelphiFormsParser.IsBinaryDfm(const Data: TBytes): Boolean;
begin
  Result := False;
  if Length(Data) < 4 then
    Exit;
  // Check for $FF + TPF0
  if (Data[0] = $FF) and (Length(Data) >= 5) and (Data[1] = Ord('T')) and (Data[2] = Ord('P')) and (Data[3] = Ord('F')) and (Data[4] = Ord('0')) then
    Result := True
  // Check for bare TPF0
  else if (Data[0] = Ord('T')) and (Data[1] = Ord('P')) and (Data[2] = Ord('F')) and (Data[3] = Ord('0')) then
    Result := True;
end;

class function TDelphiFormsParser.DetectTextEncoding(const Data: TBytes): TEncoding;
begin
  // UTF-8 BOM: $EF $BB $BF
  if (Length(Data) >= 3) and (Data[0] = $EF) and (Data[1] = $BB) and (Data[2] = $BF) then
    Result := TEncoding.UTF8
  // UTF-16 LE BOM: $FF $FE (unlikely for DFM but handle it)
  else if (Length(Data) >= 2) and (Data[0] = $FF) and (Data[1] = $FE) then
    Result := TEncoding.Unicode
  // No BOM: default to UTF-8 (modern Delphi)
  else
    Result := TEncoding.UTF8;
end;

class function TDelphiFormsParser.ParseFile(const FileName: string): TFormFile;
var
  Data: TBytes;
begin
  Data := TFile.ReadAllBytes(FileName);
  Result := ParseBytes(Data);
end;

class function TDelphiFormsParser.ParseFile(const FileName: string; Encoding: TEncoding): TFormFile;
var
  Data: TBytes;
begin
  Data := TFile.ReadAllBytes(FileName);
  Result := ParseBytes(Data, Encoding);
end;

class function TDelphiFormsParser.ParseBytes(const Data: TBytes): TFormFile;
var
  Enc: TEncoding;
  Preamble: TBytes;
  Offset: Integer;
  Source: string;
  Win1252: TEncoding;
begin
  if IsBinaryDfm(Data) then
    Result := ParseBinary(Data)
  else
  begin
    Enc := DetectTextEncoding(Data);
    Preamble := Enc.GetPreamble;
    Offset := Length(Preamble);
    // Verify BOM actually matches before skipping
    if (Offset > 0) and (Length(Data) >= Offset) then
    begin
      var Match := True;
      for var I := 0 to Offset - 1 do
        if Data[I] <> Preamble[I] then begin Match := False; Break; end;
      if not Match then
        Offset := 0;
    end
    else
      Offset := 0;
    try
      Source := Enc.GetString(Data, Offset, Length(Data) - Offset);
    except
      on E: EEncodingError do
      begin
        // UTF-8 decode failed -- fall back to Windows-1252 (legacy ANSI DFM)
        Win1252 := TMBCSEncoding.Create(1252, False);
        try
          Source := Win1252.GetString(Data);
        finally
          Win1252.Free;
        end;
      end;
    end;
    Result := ParseText(Source);
  end;
end;

class function TDelphiFormsParser.ParseBytes(const Data: TBytes; Encoding: TEncoding): TFormFile;
begin
  if IsBinaryDfm(Data) then
    Result := ParseBinary(Data)
  else
    Result := ParseText(Encoding.GetString(Data));
end;

class function TDelphiFormsParser.ParseText(const Source: string): TFormFile;
var
  Parser: TDfmParser;
begin
  Parser := TDfmParser.Create;
  try
    Result := Parser.Parse(Source);
  finally
    Parser.Free;
  end;
end;

class function TDelphiFormsParser.ParseBinary(const Data: TBytes): TFormFile;
var
  Reader: TDfmBinaryReader;
begin
  Reader := TDfmBinaryReader.Create;
  try
    Result := Reader.ReadFromBytes(Data);
  finally
    Reader.Free;
  end;
end;

class function TDelphiFormsParser.ParseTextWithDiagnostics(const Source: string): TParseResult;
var
  Parser: TDfmParser;
begin
  Parser := TDfmParser.Create;
  try
    Result := Parser.ParseWithDiagnostics(Source);
  finally
    Parser.Free;
  end;
end;

class function TDelphiFormsParser.ParseBinaryWithDiagnostics(const Data: TBytes): TParseResult;
var
  Reader: TDfmBinaryReader;
begin
  Reader := TDfmBinaryReader.Create;
  try
    Result := Reader.ReadFromBytesWithDiagnostics(Data);
  finally
    Reader.Free;
  end;
end;

class function TDelphiFormsParser.ParseFileWithDiagnostics(const FileName: string): TParseResult;
var
  Data: TBytes;
begin
  Data := TFile.ReadAllBytes(FileName);
  Result := ParseBytesWithDiagnostics(Data);
end;

class function TDelphiFormsParser.ParseBytesWithDiagnostics(const Data: TBytes): TParseResult;
var
  Enc: TEncoding;
  Preamble: TBytes;
  Offset: Integer;
  Source: string;
  Win1252: TEncoding;
begin
  if IsBinaryDfm(Data) then
    Result := ParseBinaryWithDiagnostics(Data)
  else
  begin
    Enc := DetectTextEncoding(Data);
    Preamble := Enc.GetPreamble;
    Offset := Length(Preamble);
    if (Offset > 0) and (Length(Data) >= Offset) then
    begin
      var Match := True;
      for var I := 0 to Offset - 1 do
        if Data[I] <> Preamble[I] then begin Match := False; Break; end;
      if not Match then
        Offset := 0;
    end
    else
      Offset := 0;
    try
      Source := Enc.GetString(Data, Offset, Length(Data) - Offset);
    except
      on E: EEncodingError do
      begin
        Win1252 := TMBCSEncoding.Create(1252, False);
        try
          Source := Win1252.GetString(Data);
        finally
          Win1252.Free;
        end;
      end;
    end;
    Result := ParseTextWithDiagnostics(Source);
  end;
end;

class function TDelphiFormsParser.WriteText(FormFile: TFormFile): string;
var
  Writer: TDfmTextWriter;
begin
  Writer := TDfmTextWriter.Create;
  try
    Result := Writer.Write(FormFile);
  finally
    Writer.Free;
  end;
end;

class function TDelphiFormsParser.WriteBinary(FormFile: TFormFile): TBytes;
var
  Writer: TDfmBinaryWriter;
begin
  Writer := TDfmBinaryWriter.Create;
  try
    Result := Writer.WriteToBytes(FormFile);
  finally
    Writer.Free;
  end;
end;

class function TDelphiFormsParser.BinaryToText(const Data: TBytes): string;
var
  F: TFormFile;
begin
  F := ParseBinary(Data);
  try
    Result := WriteText(F);
  finally
    F.Free;
  end;
end;

class function TDelphiFormsParser.TextToBinary(const Source: string): TBytes;
var
  F: TFormFile;
begin
  F := ParseText(Source);
  try
    Result := WriteBinary(F);
  finally
    F.Free;
  end;
end;

end.
