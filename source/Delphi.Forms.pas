unit Delphi.Forms;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Delphi.Forms.Types,
  Delphi.Forms.Parser,
  Delphi.Forms.TextWriter,
  Delphi.Forms.BinaryReader,
  Delphi.Forms.BinaryWriter;

type

  TDfmFormat = (dfText, dfBinary);

  TDelphiFormsParser = class
  public
    class function ParseFile(const FileName: string): TFormFile;
    class function ParseText(const Source: string): TFormFile;
    class function ParseBinary(const Data: TBytes): TFormFile;
    class function ParseBytes(const Data: TBytes): TFormFile;

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

class function TDelphiFormsParser.ParseFile(const FileName: string): TFormFile;
var
  Data: TBytes;
begin
  Data := TFile.ReadAllBytes(FileName);
  Result := ParseBytes(Data);
end;

class function TDelphiFormsParser.ParseBytes(const Data: TBytes): TFormFile;
begin
  if IsBinaryDfm(Data) then
    Result := ParseBinary(Data)
  else
    Result := ParseText(TEncoding.UTF8.GetString(Data));
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
