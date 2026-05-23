unit Delphi.Forms.BinaryReader;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Collections,
  Delphi.Forms.Types,
  Delphi.Forms.Diagnostics;

type

  // Reads TPF0 binary DFM format into a TFormFile AST.
  // Requires a seekable stream (TBytesStream, TFileStream, TMemoryStream).
  // The reader uses Position-based peek-and-rewind for list, collection,
  // and child object termination checks.
  TDfmBinaryReader = class
  private
    FStream: TStream;
    FDiagnostics: TList<TFormDiagnostic>;
    function ReadByte: Byte;
    function ReadWord: Word;
    function ReadInt32: Int32;
    function ReadInt64: Int64;
    function ReadSingle: Single;
    function ReadDouble: Double;
    function ReadCurrency: Currency;
    function ReadShortString: string;
    function ReadLString: string;
    function ReadWString: string;
    function ReadUTF8String: string;
    function ReadUString: string;
    function ReadBytes(Count: Integer): TBytes;
    function ReadExtended80FromBytes(const Buf: TBytes): Extended;
    function ReadObject: TFormObject;
    function ReadValue: TFormValue;
    procedure ReadProperties(Obj: TFormObject);
    procedure ReadChildren(Obj: TFormObject);
    procedure AddDiag(Severity: TFormDiagnosticSeverity; const Code, Msg: string);
  public
    function ReadFromStream(Stream: TStream): TFormFile;
    function ReadFromBytes(const Data: TBytes): TFormFile;
    function ReadFromFile(const FileName: string): TFormFile;
    function ReadFromBytesWithDiagnostics(const Data: TBytes): TParseResult;
  end;

const
  vaList       = 1;
  vaInt8       = 2;
  vaInt16      = 3;
  vaInt32      = 4;
  vaExtended   = 5;
  vaString     = 6;
  vaIdent      = 7;
  vaFalse      = 8;
  vaTrue       = 9;
  vaBinary     = 10;
  vaSet        = 11;
  vaLString    = 12;
  vaNil        = 13;
  vaCollection = 14;
  vaSingle     = 15;
  vaDouble     = 16;
  vaCurrency   = 17;
  vaDate       = 18;
  vaWString    = 19;
  vaInt64      = 20;
  vaUTF8String = 21;
  vaUString    = 22;

implementation

{ TDfmBinaryReader }

procedure TDfmBinaryReader.AddDiag(Severity: TFormDiagnosticSeverity; const Code, Msg: string);
begin
  if FDiagnostics <> nil then
    FDiagnostics.Add(TFormDiagnostic.Create(Severity, 0, 0, Msg, Code));
end;

function TDfmBinaryReader.ReadByte: Byte;
begin
  FStream.ReadBuffer(Result, 1);
end;

function TDfmBinaryReader.ReadWord: Word;
begin
  FStream.ReadBuffer(Result, 2);
end;

function TDfmBinaryReader.ReadInt32: Int32;
begin
  FStream.ReadBuffer(Result, 4);
end;

function TDfmBinaryReader.ReadInt64: Int64;
begin
  FStream.ReadBuffer(Result, 8);
end;

function TDfmBinaryReader.ReadSingle: Single;
begin
  FStream.ReadBuffer(Result, 4);
end;

function TDfmBinaryReader.ReadDouble: Double;
begin
  FStream.ReadBuffer(Result, 8);
end;

function TDfmBinaryReader.ReadCurrency: Currency;
begin
  FStream.ReadBuffer(Result, 8);
end;

function TDfmBinaryReader.ReadExtended80FromBytes(const Buf: TBytes): Extended;
var
  {$IF SizeOf(Extended) = 10}
  E: Extended;
  {$ELSE}
  D: Double;
  Sign: Integer;
  Exp: Integer;
  Mantissa: UInt64;
  {$IFEND}
begin
  {$IF SizeOf(Extended) = 10}
  Move(Buf[0], E, 10);
  Result := E;
  {$ELSE}
  Sign := (Buf[9] shr 7) and 1;
  Exp := ((Buf[9] and $7F) shl 8) or Buf[8];
  Mantissa := PUInt64(@Buf[0])^;

  if (Exp = 0) and (Mantissa = 0) then
    D := 0.0
  else if Exp = $7FFF then
    D := Infinity
  else
  begin
    Exp := Exp - 16383 + 1023;
    if Exp <= 0 then
      D := 0.0
    else if Exp >= $7FF then
      D := Infinity
    else
    begin
      Mantissa := Mantissa shl 1;
      Mantissa := Mantissa shr 12;
      PUInt64(@D)^ := (UInt64(Sign) shl 63) or (UInt64(Exp) shl 52) or Mantissa;
    end;
  end;
  if Sign = 1 then
    D := -Abs(D);
  Result := D;
  {$IFEND}
end;


function TDfmBinaryReader.ReadShortString: string;
var
  Len: Byte;
  Buf: TBytes;
begin
  Len := ReadByte;
  if Len = 0 then
    Exit('');
  SetLength(Buf, Len);
  FStream.ReadBuffer(Buf[0], Len);
  Result := TEncoding.ANSI.GetString(Buf);
end;

function TDfmBinaryReader.ReadLString: string;
var
  Len: Int32;
  Buf: TBytes;
begin
  Len := ReadInt32;
  if Len = 0 then
    Exit('');
  SetLength(Buf, Len);
  FStream.ReadBuffer(Buf[0], Len);
  Result := TEncoding.ANSI.GetString(Buf);
end;

function TDfmBinaryReader.ReadWString: string;
var
  Len: Int32;
  Buf: TBytes;
begin
  Len := ReadInt32;
  if Len = 0 then
    Exit('');
  SetLength(Buf, Len * 2);
  FStream.ReadBuffer(Buf[0], Len * 2);
  Result := TEncoding.Unicode.GetString(Buf);
end;

function TDfmBinaryReader.ReadUTF8String: string;
var
  Len: Int32;
  Buf: TBytes;
begin
  Len := ReadInt32;
  if Len = 0 then
    Exit('');
  SetLength(Buf, Len);
  FStream.ReadBuffer(Buf[0], Len);
  Result := TEncoding.UTF8.GetString(Buf);
end;

function TDfmBinaryReader.ReadUString: string;
var
  Len: Int32;
  Buf: TBytes;
begin
  Len := ReadInt32;
  if Len = 0 then
    Exit('');
  SetLength(Buf, Len * 2);
  FStream.ReadBuffer(Buf[0], Len * 2);
  Result := TEncoding.Unicode.GetString(Buf);
end;

function TDfmBinaryReader.ReadBytes(Count: Integer): TBytes;
begin
  SetLength(Result, Count);
  if Count > 0 then
    FStream.ReadBuffer(Result[0], Count);
end;

function TDfmBinaryReader.ReadObject: TFormObject;
var
  ClassNameLen: Byte;
  Buf: TBytes;
begin
  Result := TFormObject.Create;
  try
    // Read flags/object kind from class name prefix byte
    ClassNameLen := ReadByte;
    if ClassNameLen and $F0 <> 0 then
    begin
      case ClassNameLen and $F0 of
        $10: Result.ObjectKind := okInherited;
        $20: Result.ObjectKind := okInline;
      else
        Result.ObjectKind := okObject;
      end;
      ClassNameLen := ClassNameLen and $0F;
    end;

    if ClassNameLen > 0 then
    begin
      SetLength(Buf, ClassNameLen);
      FStream.ReadBuffer(Buf[0], ClassNameLen);
      Result.ClassName_ := TEncoding.ANSI.GetString(Buf);
    end;

    Result.Name := ReadShortString;

    ReadProperties(Result);
    ReadChildren(Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TDfmBinaryReader.ReadProperties(Obj: TFormObject);
var
  NameLen: Byte;
  PropName: string;
  Buf: TBytes;
  Val: TFormValue;
begin
  while True do
  begin
    NameLen := ReadByte;
    if NameLen = 0 then
      Break;
    SetLength(Buf, NameLen);
    FStream.ReadBuffer(Buf[0], NameLen);
    PropName := TEncoding.ANSI.GetString(Buf);
    Val := ReadValue;
    Obj.Properties.Add(TFormProperty.Create(PropName, Val));
  end;
end;

procedure TDfmBinaryReader.ReadChildren(Obj: TFormObject);
var
  PeekByte: Byte;
begin
  while True do
  begin
    PeekByte := ReadByte;
    if PeekByte = 0 then
      Break;
    // Put back the byte -- it's the start of a child object's class name length
    FStream.Position := FStream.Position - 1;
    Obj.Children.Add(ReadObject);
  end;
end;

function TDfmBinaryReader.ReadValue: TFormValue;
var
  ValueType: Byte;
  Len: Int32;
  SetItem: string;
  Items: TList<string>;
  CollItem: TFormObject;
  NameLen: Byte;
  Buf: TBytes;
  PropName: string;
begin
  ValueType := ReadByte;
  case ValueType of
    vaInt8:
    begin
      Result := TFormValue.Create(fvInteger);
      Result.OriginalValueType := vaInt8;
      Result.IntValue := ShortInt(ReadByte);
    end;
    vaInt16:
    begin
      Result := TFormValue.Create(fvInteger);
      Result.OriginalValueType := vaInt16;
      Result.IntValue := SmallInt(ReadWord);
    end;
    vaInt32:
    begin
      Result := TFormValue.Create(fvInteger);
      Result.OriginalValueType := vaInt32;
      Result.IntValue := ReadInt32;
    end;
    vaInt64:
    begin
      Result := TFormValue.Create(fvInteger);
      Result.OriginalValueType := vaInt64;
      Result.IntValue := ReadInt64;
    end;
    vaSingle:
    begin
      Result := TFormValue.Create(fvFloat);
      Result.OriginalValueType := vaSingle;
      Result.FloatValue := ReadSingle;
    end;
    vaDouble:
    begin
      Result := TFormValue.Create(fvFloat);
      Result.OriginalValueType := vaDouble;
      Result.FloatValue := ReadDouble;
    end;
    vaDate:
    begin
      Result := TFormValue.Create(fvFloat);
      Result.OriginalValueType := vaDate;
      Result.FloatValue := ReadDouble;
    end;
    vaExtended:
    begin
      Result := TFormValue.Create(fvFloat);
      Result.OriginalValueType := vaExtended;
      Result.ExtendedRawBytes := ReadBytes(10);
      Result.FloatValue := ReadExtended80FromBytes(Result.ExtendedRawBytes);
    end;
    vaCurrency:
    begin
      Result := TFormValue.Create(fvFloat);
      Result.OriginalValueType := vaCurrency;
      Result.FloatValue := ReadCurrency;
    end;
    vaString:
    begin
      Result := TFormValue.Create(fvString);
      Result.OriginalValueType := vaString;
      Result.StringValue := ReadShortString;
    end;
    vaLString:
    begin
      Result := TFormValue.Create(fvString);
      Result.OriginalValueType := vaLString;
      Result.StringValue := ReadLString;
    end;
    vaWString:
    begin
      Result := TFormValue.Create(fvString);
      Result.OriginalValueType := vaWString;
      Result.StringValue := ReadWString;
    end;
    vaUTF8String:
    begin
      Result := TFormValue.Create(fvString);
      Result.OriginalValueType := vaUTF8String;
      Result.StringValue := ReadUTF8String;
    end;
    vaUString:
    begin
      Result := TFormValue.Create(fvString);
      Result.OriginalValueType := vaUString;
      Result.StringValue := ReadUString;
    end;
    vaIdent:
    begin
      Result := TFormValue.Create(fvIdentifier);
      Result.OriginalValueType := vaIdent;
      Result.IdentValue := ReadShortString;
    end;
    vaFalse:
    begin
      Result := TFormValue.Create(fvBoolean);
      Result.OriginalValueType := vaFalse;
      Result.BoolValue := False;
    end;
    vaTrue:
    begin
      Result := TFormValue.Create(fvBoolean);
      Result.OriginalValueType := vaTrue;
      Result.BoolValue := True;
    end;
    vaNil:
    begin
      Result := TFormValue.Create(fvIdentifier);
      Result.OriginalValueType := vaNil;
      Result.IdentValue := 'nil';
    end;
    vaSet:
    begin
      Result := TFormValue.Create(fvSet);
      try
        Items := TList<string>.Create;
        try
          while True do
          begin
            SetItem := ReadShortString;
            if SetItem = '' then
              Break;
            Items.Add(SetItem);
          end;
          Result.SetItems := Items.ToArray;
        finally
          Items.Free;
        end;
      except
        Result.Free;
        raise;
      end;
    end;
    vaBinary:
    begin
      Result := TFormValue.Create(fvBinary);
      try
        Len := ReadInt32;
        Result.BinaryData := ReadBytes(Len);
      except
        Result.Free;
        raise;
      end;
    end;
    vaList:
    begin
      Result := TFormValue.Create(fvList);
      try
        while True do
        begin
          if ReadByte = 0 then
            Break;
          FStream.Position := FStream.Position - 1;
          Result.ListItems.Add(ReadValue);
        end;
      except
        Result.Free;
        raise;
      end;
    end;
    vaCollection:
    begin
      Result := TFormValue.Create(fvCollection);
      try
        while True do
        begin
          if ReadByte = 0 then
            Break;
          FStream.Position := FStream.Position - 1;
          CollItem := TFormObject.Create;
          try
            // Collection items: read item index (vaInt* value), then properties
            var IdxVal := ReadValue;
            try
              if IdxVal.Kind = fvInteger then
                CollItem.ItemIndex := IdxVal.IntValue;
            finally
              IdxVal.Free;
            end;
            // Read properties until zero-length name
            while True do
            begin
              NameLen := ReadByte;
              if NameLen = 0 then
                Break;
              SetLength(Buf, NameLen);
              FStream.ReadBuffer(Buf[0], NameLen);
              PropName := TEncoding.ANSI.GetString(Buf);
              CollItem.Properties.Add(TFormProperty.Create(PropName, ReadValue));
            end;
          except
            CollItem.Free;
            raise;
          end;
          Result.CollectionItems.Add(CollItem);
        end;
      except
        Result.Free;
        raise;
      end;
    end;
  else
    raise Exception.CreateFmt('Unknown binary value type: %d at position %d', [ValueType, FStream.Position - 1]);
  end;
end;

function TDfmBinaryReader.ReadFromStream(Stream: TStream): TFormFile;
var
  Sig: array[0..3] of AnsiChar;
  FirstByte: Byte;
begin
  FStream := Stream;
  FDiagnostics := nil;

  // Check for $FF prefix
  FirstByte := ReadByte;
  if FirstByte = $FF then
  begin
    // Read TPF0 signature
    FStream.ReadBuffer(Sig, 4);
    if string(Sig) <> 'TPF0' then
      raise Exception.Create('Invalid binary DFM: expected TPF0 signature');
  end
  else
  begin
    // No $FF prefix; check if it starts with TPF0 directly
    FStream.Position := FStream.Position - 1;
    FStream.ReadBuffer(Sig, 4);
    if string(Sig) <> 'TPF0' then
      raise Exception.Create('Invalid binary DFM: expected TPF0 signature');
  end;

  Result := TFormFile.Create;
  try
    Result.Root := ReadObject;
  except
    Result.Free;
    raise;
  end;
end;

function TDfmBinaryReader.ReadFromBytes(const Data: TBytes): TFormFile;
var
  Stream: TBytesStream;
begin
  Stream := TBytesStream.Create(Data);
  try
    Result := ReadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

function TDfmBinaryReader.ReadFromFile(const FileName: string): TFormFile;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result := ReadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

function TDfmBinaryReader.ReadFromBytesWithDiagnostics(const Data: TBytes): TParseResult;
var
  Stream: TBytesStream;
  Sig: array[0..3] of AnsiChar;
  FirstByte: Byte;
  HasErrors: Boolean;
  I: Integer;
begin
  Result.Form := nil;
  Result.Diagnostics := nil;
  Result.Success := False;

  FDiagnostics := TList<TFormDiagnostic>.Create;
  try
    Stream := TBytesStream.Create(Data);
    try
      FStream := Stream;

      // Validate signature
      try
        FirstByte := ReadByte;
        if FirstByte = $FF then
        begin
          FStream.ReadBuffer(Sig, 4);
          if string(Sig) <> 'TPF0' then
          begin
            AddDiag(dsError, DiagInvalidBinarySignature, 'Invalid binary DFM: expected TPF0 signature');
            Result.Diagnostics := FDiagnostics.ToArray;
            Exit;
          end;
        end
        else
        begin
          FStream.Position := FStream.Position - 1;
          FStream.ReadBuffer(Sig, 4);
          if string(Sig) <> 'TPF0' then
          begin
            AddDiag(dsError, DiagInvalidBinarySignature, 'Invalid binary DFM: expected TPF0 signature');
            Result.Diagnostics := FDiagnostics.ToArray;
            Exit;
          end;
        end;
      except
        on E: Exception do
        begin
          AddDiag(dsError, DiagInvalidBinarySignature, 'Invalid binary DFM: ' + E.Message);
          Result.Diagnostics := FDiagnostics.ToArray;
          Exit;
        end;
      end;

      // Read the object tree
      Result.Form := TFormFile.Create;
      try
        Result.Form.Root := ReadObject;
      except
        on E: Exception do
        begin
          if Pos('Unknown binary value type', E.Message) > 0 then
            AddDiag(dsError, DiagUnknownBinaryValueType, E.Message)
          else
            AddDiag(dsError, DiagUnexpectedEndOfInput, E.Message);
          // Keep partial Form (Root may be partially populated)
        end;
      end;
    finally
      Stream.Free;
    end;

    HasErrors := False;
    for I := 0 to FDiagnostics.Count - 1 do
    begin
      if FDiagnostics[I].Severity = dsError then
      begin
        HasErrors := True;
        Break;
      end;
    end;

    Result.Success := not HasErrors;
    Result.Diagnostics := FDiagnostics.ToArray;
  finally
    FDiagnostics.Free;
    FDiagnostics := nil;
  end;
end;

end.
