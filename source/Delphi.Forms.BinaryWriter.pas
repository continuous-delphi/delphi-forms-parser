unit Delphi.Forms.BinaryWriter;

interface

uses
  System.SysUtils,
  System.Classes,
  Delphi.Forms.Types,
  Delphi.Forms.BinaryReader;

type

  TDfmBinaryWriter = class
  private
    FStream: TStream;
    procedure WriteByte(B: Byte);
    procedure WriteWord(W: Word);
    procedure WriteInt32(V: Int32);
    procedure WriteInt64(V: Int64);
    procedure WriteShortString(const S: string);
    procedure WriteObject(Obj: TFormObject);
    procedure WriteProperty(Prop: TFormProperty);
    procedure WriteValue(Value: TFormValue);
    procedure WriteIntegerValue(Value: Int64);
    procedure WriteIntegerValueWithTag(Value: Int64; Tag: Byte);
    procedure WriteStringValue(const S: string);
    procedure WriteStringValueWithTag(const S: string; Tag: Byte);
    procedure WriteFloatValueWithTag(Value: TFormValue);
  public
    function WriteToBytes(FormFile: TFormFile): TBytes;
    procedure WriteToStream(FormFile: TFormFile; Stream: TStream);
    procedure WriteToFile(FormFile: TFormFile; const FileName: string);
  end;

implementation

{ TDfmBinaryWriter }

procedure TDfmBinaryWriter.WriteByte(B: Byte);
begin
  FStream.WriteBuffer(B, 1);
end;

procedure TDfmBinaryWriter.WriteWord(W: Word);
begin
  FStream.WriteBuffer(W, 2);
end;

procedure TDfmBinaryWriter.WriteInt32(V: Int32);
begin
  FStream.WriteBuffer(V, 4);
end;

procedure TDfmBinaryWriter.WriteInt64(V: Int64);
begin
  FStream.WriteBuffer(V, 8);
end;

procedure TDfmBinaryWriter.WriteShortString(const S: string);
var
  Buf: TBytes;
begin
  Buf := TEncoding.ANSI.GetBytes(S);
  WriteByte(Byte(Length(Buf)));
  if Length(Buf) > 0 then
    FStream.WriteBuffer(Buf[0], Length(Buf));
end;

procedure TDfmBinaryWriter.WriteObject(Obj: TFormObject);
var
  ClassBuf: TBytes;
  LenByte: Byte;
  I: Integer;
begin
  ClassBuf := TEncoding.ANSI.GetBytes(Obj.ClassName_);
  LenByte := Byte(Length(ClassBuf));
  case Obj.ObjectKind of
    okInherited: LenByte := LenByte or $10;
    okInline: LenByte := LenByte or $20;
  end;
  WriteByte(LenByte);
  if Length(ClassBuf) > 0 then
    FStream.WriteBuffer(ClassBuf[0], Length(ClassBuf));

  WriteShortString(Obj.Name);

  for I := 0 to Obj.Properties.Count - 1 do
    WriteProperty(Obj.Properties[I]);
  WriteByte(0); // end of properties

  for I := 0 to Obj.Children.Count - 1 do
    WriteObject(Obj.Children[I]);
  WriteByte(0); // end of children
end;

procedure TDfmBinaryWriter.WriteProperty(Prop: TFormProperty);
var
  Buf: TBytes;
begin
  Buf := TEncoding.ANSI.GetBytes(Prop.Name);
  WriteByte(Byte(Length(Buf)));
  if Length(Buf) > 0 then
    FStream.WriteBuffer(Buf[0], Length(Buf));
  WriteValue(Prop.Value);
end;

procedure TDfmBinaryWriter.WriteIntegerValue(Value: Int64);
begin
  if (Value >= Low(ShortInt)) and (Value <= High(ShortInt)) then
  begin
    WriteByte(vaInt8);
    WriteByte(Byte(ShortInt(Value)));
  end
  else if (Value >= Low(SmallInt)) and (Value <= High(SmallInt)) then
  begin
    WriteByte(vaInt16);
    WriteWord(Word(SmallInt(Value)));
  end
  else if (Value >= Low(Int32)) and (Value <= High(Int32)) then
  begin
    WriteByte(vaInt32);
    WriteInt32(Int32(Value));
  end
  else
  begin
    WriteByte(vaInt64);
    WriteInt64(Value);
  end;
end;

procedure TDfmBinaryWriter.WriteIntegerValueWithTag(Value: Int64; Tag: Byte);
begin
  WriteByte(Tag);
  case Tag of
    vaInt8: WriteByte(Byte(ShortInt(Value)));
    vaInt16: WriteWord(Word(SmallInt(Value)));
    vaInt32: WriteInt32(Int32(Value));
    vaInt64: WriteInt64(Value);
  end;
end;

procedure TDfmBinaryWriter.WriteStringValue(const S: string);
var
  Buf: TBytes;
begin
  Buf := TEncoding.UTF8.GetBytes(S);
  WriteByte(vaUTF8String);
  WriteInt32(Length(Buf));
  if Length(Buf) > 0 then
    FStream.WriteBuffer(Buf[0], Length(Buf));
end;

procedure TDfmBinaryWriter.WriteStringValueWithTag(const S: string; Tag: Byte);
var
  Buf: TBytes;
begin
  case Tag of
    vaString:
    begin
      Buf := TEncoding.ANSI.GetBytes(S);
      WriteByte(vaString);
      WriteByte(Byte(Length(Buf)));
      if Length(Buf) > 0 then
        FStream.WriteBuffer(Buf[0], Length(Buf));
    end;
    vaLString:
    begin
      Buf := TEncoding.ANSI.GetBytes(S);
      WriteByte(vaLString);
      WriteInt32(Length(Buf));
      if Length(Buf) > 0 then
        FStream.WriteBuffer(Buf[0], Length(Buf));
    end;
    vaWString:
    begin
      Buf := TEncoding.Unicode.GetBytes(S);
      WriteByte(vaWString);
      WriteInt32(Length(Buf) div 2);
      if Length(Buf) > 0 then
        FStream.WriteBuffer(Buf[0], Length(Buf));
    end;
    vaUTF8String:
      WriteStringValue(S);
    vaUString:
    begin
      Buf := TEncoding.Unicode.GetBytes(S);
      WriteByte(vaUString);
      WriteInt32(Length(Buf) div 2);
      if Length(Buf) > 0 then
        FStream.WriteBuffer(Buf[0], Length(Buf));
    end;
  else
    WriteStringValue(S);
  end;
end;

procedure TDfmBinaryWriter.WriteFloatValueWithTag(Value: TFormValue);
var
  S: Single;
  D: Double;
  C: Currency;
begin
  case Value.OriginalValueType of
    vaSingle:
    begin
      S := Value.FloatValue;
      WriteByte(vaSingle);
      FStream.WriteBuffer(S, 4);
    end;
    vaExtended:
    begin
      WriteByte(vaExtended);
      if Length(Value.ExtendedRawBytes) = 10 then
        FStream.WriteBuffer(Value.ExtendedRawBytes[0], 10)
      else
      begin
        // Fallback: write as double in 10-byte extended slot
        D := Value.FloatValue;
        FStream.WriteBuffer(D, 8);
        WriteByte(0);
        WriteByte(0);
      end;
    end;
    vaCurrency:
    begin
      C := Value.FloatValue;
      WriteByte(vaCurrency);
      FStream.WriteBuffer(C, 8);
    end;
    vaDate:
    begin
      D := Value.FloatValue;
      WriteByte(vaDate);
      FStream.WriteBuffer(D, 8);
    end;
  else
    // Default: vaDouble
    D := Value.FloatValue;
    WriteByte(vaDouble);
    FStream.WriteBuffer(D, 8);
  end;
end;

procedure TDfmBinaryWriter.WriteValue(Value: TFormValue);
var
  I: Integer;
  CollItem: TFormObject;
begin
  case Value.Kind of
    fvInteger:
    begin
      if Value.OriginalValueType in [vaInt8, vaInt16, vaInt32, vaInt64] then
        WriteIntegerValueWithTag(Value.IntValue, Value.OriginalValueType)
      else
        WriteIntegerValue(Value.IntValue);
    end;
    fvFloat:
      WriteFloatValueWithTag(Value);
    fvString:
    begin
      if Value.OriginalValueType in [vaString, vaLString, vaWString, vaUTF8String, vaUString] then
        WriteStringValueWithTag(Value.StringValue, Value.OriginalValueType)
      else
        WriteStringValue(Value.StringValue);
    end;
    fvBoolean:
    begin
      if Value.BoolValue then
        WriteByte(vaTrue)
      else
        WriteByte(vaFalse);
    end;
    fvIdentifier:
    begin
      WriteByte(vaIdent);
      WriteShortString(Value.IdentValue);
    end;
    fvSet:
    begin
      WriteByte(vaSet);
      for I := 0 to Length(Value.SetItems) - 1 do
        WriteShortString(Value.SetItems[I]);
      WriteByte(0); // empty string terminates set
    end;
    fvBinary:
    begin
      WriteByte(vaBinary);
      WriteInt32(Length(Value.BinaryData));
      if Length(Value.BinaryData) > 0 then
        FStream.WriteBuffer(Value.BinaryData[0], Length(Value.BinaryData));
    end;
    fvList:
    begin
      WriteByte(vaList);
      for I := 0 to Value.ListItems.Count - 1 do
        WriteValue(Value.ListItems[I]);
      WriteByte(0); // end of list
    end;
    fvCollection:
    begin
      WriteByte(vaCollection);
      for I := 0 to Value.CollectionItems.Count - 1 do
      begin
        CollItem := Value.CollectionItems[I];
        // Write item index: use preserved value if set, otherwise sequential
        if CollItem.ItemIndex >= 0 then
          WriteIntegerValue(CollItem.ItemIndex)
        else
          WriteIntegerValue(I);
        // Write item properties
        for var J := 0 to CollItem.Properties.Count - 1 do
          WriteProperty(CollItem.Properties[J]);
        WriteByte(0); // end of item properties
      end;
      WriteByte(0); // end of collection
    end;
  end;
end;

procedure TDfmBinaryWriter.WriteToStream(FormFile: TFormFile; Stream: TStream);
var
  Sig: array[0..3] of AnsiChar;
begin
  FStream := Stream;
  WriteByte($FF);
  Sig[0] := 'T'; Sig[1] := 'P'; Sig[2] := 'F'; Sig[3] := '0';
  FStream.WriteBuffer(Sig, 4);
  if FormFile.Root <> nil then
    WriteObject(FormFile.Root);
end;

function TDfmBinaryWriter.WriteToBytes(FormFile: TFormFile): TBytes;
var
  Stream: TBytesStream;
begin
  Stream := TBytesStream.Create;
  try
    WriteToStream(FormFile, Stream);
    Result := Copy(Stream.Bytes, 0, Stream.Size);
  finally
    Stream.Free;
  end;
end;

procedure TDfmBinaryWriter.WriteToFile(FormFile: TFormFile; const FileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    WriteToStream(FormFile, Stream);
  finally
    Stream.Free;
  end;
end;

end.
