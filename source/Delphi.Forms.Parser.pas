unit Delphi.Forms.Parser;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms.Token,
  Delphi.Forms.Lexer,
  Delphi.Forms.Types;

type

  TDfmParser = class
  private
    FTokens: TDfmTokenList;
    FPos: Integer;
    function Current: TDfmToken;
    function CurrentKind: TDfmTokenKind;
    function CurrentText: string;
    function AtEnd: Boolean;
    procedure Advance;
    procedure SkipTrivia;
    procedure Expect(Kind: TDfmTokenKind);
    function MatchIdent(const Text: string): Boolean;
    function IsObjectKeyword: Boolean;
    function ParseObject: TFormObject;
    function ParseProperty: TFormProperty;
    function ParseDottedName: string;
    function ParseValue: TFormValue;
    function ParseStringValue: TFormValue;
    function ParseSetValue: TFormValue;
    function ParseListValue: TFormValue;
    function ParseCollectionValue: TFormValue;
    function ParseBinaryValue: TFormValue;
  public
    function Parse(const Source: string): TFormFile;
  end;

implementation

{ TDfmParser }

function TDfmParser.Current: TDfmToken;
begin
  Result := FTokens[FPos];
end;

function TDfmParser.CurrentKind: TDfmTokenKind;
begin
  Result := FTokens[FPos].Kind;
end;

function TDfmParser.CurrentText: string;
begin
  Result := FTokens[FPos].Text;
end;

function TDfmParser.AtEnd: Boolean;
begin
  Result := FPos >= FTokens.Count;
end;

procedure TDfmParser.Advance;
begin
  if FPos < FTokens.Count then
    Inc(FPos);
end;

procedure TDfmParser.SkipTrivia;
begin
  while not AtEnd and ((CurrentKind = dtkWhitespace) or (CurrentKind = dtkEOL)) do
    Advance;
end;

procedure TDfmParser.Expect(Kind: TDfmTokenKind);
begin
  if CurrentKind <> Kind then
    raise Exception.CreateFmt('Expected token kind %d but got %d at line %d col %d', [Ord(Kind), Ord(CurrentKind), Current.Line, Current.Col]);
  Advance;
end;


function TDfmParser.MatchIdent(const Text: string): Boolean;
begin
  Result := not AtEnd and (CurrentKind = dtkIdentifier) and SameText(CurrentText, Text);
end;

function TDfmParser.IsObjectKeyword: Boolean;
begin
  Result := not AtEnd and (CurrentKind = dtkIdentifier) and (SameText(CurrentText, 'object') or SameText(CurrentText, 'inherited') or SameText(CurrentText, 'inline'));
end;

function TDfmParser.ParseObject: TFormObject;
var
  KwText: string;
begin
  Result := TFormObject.Create;
  try
    SkipTrivia;

    // object/inherited/inline keyword
    KwText := CurrentText;
    if SameText(KwText, 'inherited') then
      Result.ObjectKind := okInherited
    else if SameText(KwText, 'inline') then
      Result.ObjectKind := okInline
    else
      Result.ObjectKind := okObject;
    Advance;
    SkipTrivia;

    // Name : ClassName
    Result.Name := CurrentText;
    Expect(dtkIdentifier);
    SkipTrivia;
    Expect(dtkColon);
    SkipTrivia;
    Result.ClassName_ := CurrentText;
    Expect(dtkIdentifier);
    SkipTrivia;

    // Properties and children until 'end'
    while not AtEnd and not MatchIdent('end') do
    begin
      SkipTrivia;
      if AtEnd then
        Break;
      if MatchIdent('end') then
        Break;

      if IsObjectKeyword then
        Result.Children.Add(ParseObject)
      else if CurrentKind = dtkIdentifier then
        Result.Properties.Add(ParseProperty)
      else
        Advance; // skip unexpected tokens
    end;

    // Consume 'end'
    if not AtEnd and MatchIdent('end') then
      Advance;
    SkipTrivia;
  except
    Result.Free;
    raise;
  end;
end;

function TDfmParser.ParseProperty: TFormProperty;
var
  PropName: string;
  Val: TFormValue;
begin
  PropName := ParseDottedName;
  SkipTrivia;
  Expect(dtkEquals);
  SkipTrivia;
  Val := ParseValue;
  SkipTrivia;
  Result := TFormProperty.Create(PropName, Val);
end;

function TDfmParser.ParseDottedName: string;
begin
  Result := CurrentText;
  Expect(dtkIdentifier);
  while not AtEnd and (CurrentKind = dtkDot) do
  begin
    Result := Result + '.';
    Advance; // skip dot
    Result := Result + CurrentText;
    Expect(dtkIdentifier);
  end;
end;

function TDfmParser.ParseValue: TFormValue;
begin
  case CurrentKind of
    dtkInteger:
    begin
      Result := TFormValue.Create(fvInteger);
      try
        Result.RawText := CurrentText;
        if (Length(CurrentText) > 0) and (CurrentText[1] = '$') then
          Result.IntValue := StrToInt64(CurrentText)
        else
          Result.IntValue := StrToInt64(CurrentText);
        Advance;
      except
        Result.Free;
        raise;
      end;
    end;
    dtkFloat:
    begin
      Result := TFormValue.Create(fvFloat);
      try
        Result.RawText := CurrentText;
        Result.FloatValue := StrToFloat(CurrentText, TFormatSettings.Invariant);
        Advance;
      except
        Result.Free;
        raise;
      end;
    end;
    dtkMinus:
    begin
      Advance; // skip minus
      SkipTrivia;
      if CurrentKind = dtkFloat then
      begin
        Result := TFormValue.Create(fvFloat);
        try
          Result.RawText := '-' + CurrentText;
          Result.FloatValue := -StrToFloat(CurrentText, TFormatSettings.Invariant);
          Advance;
        except
          Result.Free;
          raise;
        end;
      end
      else
      begin
        Result := TFormValue.Create(fvInteger);
        try
          Result.RawText := '-' + CurrentText;
          Result.IntValue := -StrToInt64(CurrentText);
          Advance;
        except
          Result.Free;
          raise;
        end;
      end;
    end;
    dtkString, dtkCharLiteral:
      Result := ParseStringValue;
    dtkIdentifier:
    begin
      if MatchIdent('True') then
      begin
        Result := TFormValue.Create(fvBoolean);
        Result.BoolValue := True;
        Result.RawText := 'True';
        Advance;
      end
      else if MatchIdent('False') then
      begin
        Result := TFormValue.Create(fvBoolean);
        Result.BoolValue := False;
        Result.RawText := 'False';
        Advance;
      end
      else
      begin
        Result := TFormValue.Create(fvIdentifier);
        try
          Result.IdentValue := ParseDottedName;
          Result.RawText := Result.IdentValue;
        except
          Result.Free;
          raise;
        end;
      end;
    end;
    dtkLBracket:
      Result := ParseSetValue;
    dtkLParen:
      Result := ParseListValue;
    dtkLAngle:
      Result := ParseCollectionValue;
    dtkBinaryData:
      Result := ParseBinaryValue;
  else
    raise Exception.CreateFmt('Unexpected token kind %d at line %d col %d', [Ord(CurrentKind), Current.Line, Current.Col]);
  end;
end;

function TDfmParser.ParseStringValue: TFormValue;
var
  S: string;
  Raw: string;
begin
  Result := TFormValue.Create(fvString);
  try
    S := '';
    Raw := '';
    // Consume the first segment (string or char literal)
    while not AtEnd and ((CurrentKind = dtkString) or (CurrentKind = dtkCharLiteral)) do
    begin
      if CurrentKind = dtkString then
      begin
        Raw := Raw + CurrentText;
        S := S + StringReplace(Copy(CurrentText, 2, Length(CurrentText) - 2), '''''', '''', [rfReplaceAll]);
        Advance;
      end
      else if CurrentKind = dtkCharLiteral then
      begin
        Raw := Raw + CurrentText;
        if (Length(CurrentText) > 1) and (CurrentText[2] = '$') then
          S := S + Chr(StrToInt('$' + Copy(CurrentText, 3, MaxInt)))
        else
          S := S + Chr(StrToInt(Copy(CurrentText, 2, MaxInt)));
        Advance;
      end;
    end;
    // Continue only if + concatenation follows
    SkipTrivia;
    while not AtEnd and (CurrentKind = dtkPlus) do
    begin
      Raw := Raw + '+';
      Advance; // skip +
      SkipTrivia;
      while not AtEnd and ((CurrentKind = dtkString) or (CurrentKind = dtkCharLiteral)) do
      begin
        if CurrentKind = dtkString then
        begin
          Raw := Raw + CurrentText;
          S := S + StringReplace(Copy(CurrentText, 2, Length(CurrentText) - 2), '''''', '''', [rfReplaceAll]);
          Advance;
        end
        else if CurrentKind = dtkCharLiteral then
        begin
          Raw := Raw + CurrentText;
          if (Length(CurrentText) > 1) and (CurrentText[2] = '$') then
            S := S + Chr(StrToInt('$' + Copy(CurrentText, 3, MaxInt)))
          else
            S := S + Chr(StrToInt(Copy(CurrentText, 2, MaxInt)));
          Advance;
        end;
      end;
      SkipTrivia;
    end;
    Result.StringValue := S;
    Result.RawText := Raw;
  except
    Result.Free;
    raise;
  end;
end;

function TDfmParser.ParseSetValue: TFormValue;
var
  Items: TList<string>;
begin
  Result := TFormValue.Create(fvSet);
  try
    Advance; // skip [
    SkipTrivia;
    Items := TList<string>.Create;
    try
      while not AtEnd and (CurrentKind <> dtkRBracket) do
      begin
        if CurrentKind = dtkIdentifier then
        begin
          Items.Add(CurrentText);
          Advance;
          SkipTrivia;
          if not AtEnd and (CurrentKind = dtkComma) then
          begin
            Advance;
            SkipTrivia;
          end;
        end
        else
          Advance;
      end;
      Result.SetItems := Items.ToArray;
    finally
      Items.Free;
    end;
    if not AtEnd and (CurrentKind = dtkRBracket) then
      Advance;
    SkipTrivia;
  except
    Result.Free;
    raise;
  end;
end;

function TDfmParser.ParseListValue: TFormValue;
begin
  Result := TFormValue.Create(fvList);
  try
    Advance; // skip (
    SkipTrivia;
    while not AtEnd and (CurrentKind <> dtkRParen) do
    begin
      Result.ListItems.Add(ParseValue);
      SkipTrivia;
    end;
    if not AtEnd and (CurrentKind = dtkRParen) then
      Advance;
    SkipTrivia;
  except
    Result.Free;
    raise;
  end;
end;

function TDfmParser.ParseCollectionValue: TFormValue;
var
  Item: TFormObject;
begin
  Result := TFormValue.Create(fvCollection);
  try
    Advance; // skip <
    SkipTrivia;
    while not AtEnd and (CurrentKind <> dtkRAngle) do
    begin
      // Each collection item starts with 'item'
      if MatchIdent('item') then
      begin
        Item := TFormObject.Create;
        try
          Advance; // skip 'item'
          SkipTrivia;
          // Check for optional class name: if next ident is NOT followed by '='
          // then it's a class name, not a property name
          if not AtEnd and (CurrentKind = dtkIdentifier) and not MatchIdent('end') then
          begin
            // Peek ahead: save position, skip ident, skip trivia, check for '='
            var SavePos := FPos;
            Advance; // skip the potential class name
            SkipTrivia;
            if not AtEnd and (CurrentKind = dtkEquals) then
            begin
              // It was a property name, not a class name -- rewind
              FPos := SavePos;
            end
            else
            begin
              // It was a class name -- store it, position is already past it
              Item.ClassName_ := FTokens[SavePos].Text;
            end;
          end;
          // Parse properties until 'end'
          while not AtEnd and not MatchIdent('end') do
          begin
            SkipTrivia;
            if AtEnd or MatchIdent('end') then
              Break;
            if CurrentKind = dtkIdentifier then
              Item.Properties.Add(ParseProperty)
            else
              Advance;
          end;
          // Consume 'end'
          if not AtEnd and MatchIdent('end') then
            Advance;
          SkipTrivia;
        except
          Item.Free;
          raise;
        end;
        Result.CollectionItems.Add(Item);
      end
      else
        Advance;
    end;
    if not AtEnd and (CurrentKind = dtkRAngle) then
      Advance;
    SkipTrivia;
  except
    Result.Free;
    raise;
  end;
end;

function TDfmParser.ParseBinaryValue: TFormValue;
var
  FullText: string;
  HexOnly: string;
  I: Integer;
  B: TList<Byte>;
  HexPair: string;
begin
  Result := TFormValue.Create(fvBinary);
  try
    FullText := CurrentText;
    Result.RawText := FullText;
    // Strip { and }, extract hex content
    HexOnly := '';
    for I := 1 to Length(FullText) do
    begin
      if CharInSet(FullText[I], ['0'..'9', 'A'..'F', 'a'..'f']) then
        HexOnly := HexOnly + FullText[I];
    end;
    Result.BinaryHex := Copy(FullText, 2, Length(FullText) - 2); // between { and }

    B := TList<Byte>.Create;
    try
      I := 1;
      while I + 1 <= Length(HexOnly) do
      begin
        HexPair := Copy(HexOnly, I, 2);
        B.Add(Byte(StrToInt('$' + HexPair)));
        Inc(I, 2);
      end;
      Result.BinaryData := TBytes(B.ToArray);
    finally
      B.Free;
    end;
    Advance;
    SkipTrivia;
  except
    Result.Free;
    raise;
  end;
end;

function TDfmParser.Parse(const Source: string): TFormFile;
var
  Lexer: TDfmLexer;
begin
  Lexer := TDfmLexer.Create;
  try
    FTokens := Lexer.Tokenize(Source);
    try
      FPos := 0;
      Result := TFormFile.Create;
      try
        SkipTrivia;
        if not AtEnd and IsObjectKeyword then
          Result.Root := ParseObject;
      except
        Result.Free;
        raise;
      end;
    finally
      FTokens.Free;
    end;
  finally
    Lexer.Free;
  end;
end;

end.
