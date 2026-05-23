unit Delphi.Forms.Parser;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms.Token,
  Delphi.Forms.Lexer,
  Delphi.Forms.Types,
  Delphi.Forms.Diagnostics;

type

  TDfmParser = class
  private
    FTokens: TDfmTokenList;
    FPos: Integer;
    FDiagnostics: TList<TFormDiagnostic>;
    FDiagnosticMode: Boolean;
    function Current: TDfmToken;
    function CurrentKind: TDfmTokenKind;
    function CurrentText: string;
    function AtEnd: Boolean;
    procedure Advance;
    procedure SkipTrivia;
    function TryExpect(Kind: TDfmTokenKind): Boolean;
    procedure Expect(Kind: TDfmTokenKind);
    function MatchIdent(const Text: string): Boolean;
    function IsObjectKeyword: Boolean;
    function CurrentOffset: Integer;
    procedure AddDiag(Severity: TFormDiagnosticSeverity; const Code, Msg: string; Line, Col: Integer);
    procedure SkipToRecoveryPoint;
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
    function ParseWithDiagnostics(const Source: string): TParseResult;
  end;

implementation

{ TDfmParser }

function TDfmParser.Current: TDfmToken;
begin
  if FPos >= FTokens.Count then
    raise Exception.Create('Unexpected end of DFM input');
  Result := FTokens[FPos];
end;

function TDfmParser.CurrentKind: TDfmTokenKind;
begin
  if FPos >= FTokens.Count then
    raise Exception.Create('Unexpected end of DFM input');
  Result := FTokens[FPos].Kind;
end;

function TDfmParser.CurrentText: string;
begin
  if FPos >= FTokens.Count then
    raise Exception.Create('Unexpected end of DFM input');
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

procedure TDfmParser.AddDiag(Severity: TFormDiagnosticSeverity; const Code, Msg: string; Line, Col: Integer);
begin
  if FDiagnostics <> nil then
    FDiagnostics.Add(TFormDiagnostic.Create(Severity, Line, Col, Msg, Code));
end;

procedure TDfmParser.SkipToRecoveryPoint;
begin
  // Skip tokens until we find an identifier (next property), 'end', or EOF
  while not AtEnd do
  begin
    if (CurrentKind = dtkIdentifier) then
      Break;
    if (CurrentKind = dtkEOF) then
      Break;
    Advance;
  end;
end;

function TDfmParser.TryExpect(Kind: TDfmTokenKind): Boolean;
begin
  if AtEnd then
  begin
    if FDiagnosticMode then
    begin
      AddDiag(dsError, DiagUnexpectedEndOfInput, Format('Unexpected end of DFM input: expected token kind %d', [Ord(Kind)]), 0, 0);
      Result := False;
      Exit;
    end
    else
      raise Exception.CreateFmt('Unexpected end of DFM input: expected token kind %d', [Ord(Kind)]);
  end;
  if CurrentKind <> Kind then
  begin
    if FDiagnosticMode then
    begin
      AddDiag(dsError, DiagExpectedTokenNotFound, Format('Expected token kind %d but got %d at line %d col %d', [Ord(Kind), Ord(CurrentKind), Current.Line, Current.Col]), Current.Line, Current.Col);
      Result := False;
      Exit;
    end
    else
      raise Exception.CreateFmt('Expected token kind %d but got %d at line %d col %d', [Ord(Kind), Ord(CurrentKind), Current.Line, Current.Col]);
  end;
  Advance;
  Result := True;
end;

procedure TDfmParser.Expect(Kind: TDfmTokenKind);
begin
  if AtEnd then
    raise Exception.CreateFmt('Unexpected end of DFM input: expected token kind %d', [Ord(Kind)]);
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

function TDfmParser.CurrentOffset: Integer;
begin
  if AtEnd then
    Result := -1
  else
    Result := Current.StartOffset;
end;

function TDfmParser.ParseObject: TFormObject;
var
  KwText: string;
begin
  Result := TFormObject.Create;
  try
    SkipTrivia;
    Result.SourceStart := CurrentOffset;

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
    if FDiagnosticMode then
    begin
      if not AtEnd and (CurrentKind = dtkIdentifier) then
      begin
        Result.Name := CurrentText;
        Advance;
      end
      else
      begin
        AddDiag(dsError, DiagExpectedTokenNotFound, 'Expected object name identifier', 0, 0);
        Result.SourceEnd := CurrentOffset;
        Exit;
      end;
      SkipTrivia;
      if not TryExpect(dtkColon) then
      begin
        Result.SourceEnd := CurrentOffset;
        Exit;
      end;
      SkipTrivia;
      if not AtEnd and (CurrentKind = dtkIdentifier) then
      begin
        Result.ClassName_ := CurrentText;
        Advance;
      end
      else
      begin
        AddDiag(dsError, DiagExpectedTokenNotFound, 'Expected class name identifier', 0, 0);
        Result.SourceEnd := CurrentOffset;
        Exit;
      end;
      SkipTrivia;
    end
    else
    begin
      Result.Name := CurrentText;
      Expect(dtkIdentifier);
      SkipTrivia;
      Expect(dtkColon);
      SkipTrivia;
      Result.ClassName_ := CurrentText;
      Expect(dtkIdentifier);
      SkipTrivia;
    end;

    // Properties and children until 'end'
    while not AtEnd and not MatchIdent('end') do
    begin
      SkipTrivia;
      if AtEnd then
        Break;
      if MatchIdent('end') then
        Break;

      if IsObjectKeyword then
      begin
        if FDiagnosticMode then
        begin
          try
            Result.Children.Add(ParseObject);
          except
            on E: Exception do
            begin
              AddDiag(dsError, DiagInvalidValueSyntax, E.Message, 0, 0);
              SkipToRecoveryPoint;
            end;
          end;
        end
        else
          Result.Children.Add(ParseObject);
      end
      else if CurrentKind = dtkIdentifier then
      begin
        if FDiagnosticMode then
        begin
          try
            Result.Properties.Add(ParseProperty);
          except
            on E: Exception do
            begin
              var Line := 0;
              var Col := 0;
              if not AtEnd then begin Line := Current.Line; Col := Current.Col; end;
              AddDiag(dsError, DiagInvalidValueSyntax, E.Message, Line, Col);
              SkipToRecoveryPoint;
            end;
          end;
        end
        else
          Result.Properties.Add(ParseProperty);
      end
      else
        Advance; // skip unexpected tokens
    end;

    // Consume 'end'
    if not AtEnd and MatchIdent('end') then
    begin
      Result.SourceEnd := Current.StartOffset + Length(Current.Text);
      Advance;
    end
    else
    begin
      if FDiagnosticMode then
        AddDiag(dsError, DiagUnexpectedEndOfInput, 'Unexpected end of DFM input: missing ''end''', 0, 0);
      Result.SourceEnd := CurrentOffset;
    end;
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
  StartOfs: Integer;
begin
  StartOfs := CurrentOffset;
  PropName := ParseDottedName;
  SkipTrivia;
  Expect(dtkEquals);
  SkipTrivia;
  Val := ParseValue;
  Result := TFormProperty.Create(PropName, Val);
  Result.SourceStart := StartOfs;
  Result.SourceEnd := Val.SourceEnd;
  SkipTrivia;
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
var
  StartOfs: Integer;
begin
  StartOfs := CurrentOffset;
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
  Result.SourceStart := StartOfs;
  if Result.SourceEnd < 0 then
    Result.SourceEnd := CurrentOffset;
end;

function TDfmParser.ParseStringValue: TFormValue;
var
  S: string;
  Raw: string;
  CharVal: Integer;
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
          CharVal := StrToInt('$' + Copy(CurrentText, 3, MaxInt))
        else
          CharVal := StrToInt(Copy(CurrentText, 2, MaxInt));
        if (CharVal < 0) or (CharVal > $FFFF) then
        begin
          if FDiagnosticMode then
            AddDiag(dsWarning, DiagCharLiteralOutOfRange, Format('Char literal %s value %d out of range (0..$FFFF)', [CurrentText, CharVal]), Current.Line, Current.Col);
          CharVal := Ord('?');
        end;
        S := S + Chr(CharVal);
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
            CharVal := StrToInt('$' + Copy(CurrentText, 3, MaxInt))
          else
            CharVal := StrToInt(Copy(CurrentText, 2, MaxInt));
          if (CharVal < 0) or (CharVal > $FFFF) then
          begin
            if FDiagnosticMode then
              AddDiag(dsWarning, DiagCharLiteralOutOfRange, Format('Char literal %s value %d out of range (0..$FFFF)', [CurrentText, CharVal]), Current.Line, Current.Col);
            CharVal := Ord('?');
          end;
          S := S + Chr(CharVal);
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
          // Grammar ambiguity: after 'item', the next identifier could be
          // either a class name (e.g. 'item TToolButton') or a property
          // name (e.g. 'item' followed by 'Caption = ...'). Delphi's own
          // ObjectTextToResource uses the same heuristic: if the identifier
          // is followed by '=' it's a property; otherwise it's a class name.
          // This works correctly for all well-formed DFM files produced by
          // the Delphi IDE. For malformed input where a bare identifier
          // appears without '=' (e.g. 'item Orphan\nend'), it will be
          // misclassified as a class name -- matching Delphi's behavior.
          if not AtEnd and (CurrentKind = dtkIdentifier) and not MatchIdent('end') then
          begin
            var SavePos := FPos;
            Advance;
            SkipTrivia;
            if not AtEnd and (CurrentKind = dtkEquals) then
            begin
              // Followed by '=' -- it's a property name, rewind
              FPos := SavePos;
            end
            else
            begin
              // Not followed by '=' -- treat as class name
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

    // Check for odd nibble count (DFM006)
    if (Length(HexOnly) mod 2 <> 0) and FDiagnosticMode then
      AddDiag(dsWarning, DiagIncompleteHexData, Format('Incomplete hex data: odd nibble count (%d) at line %d col %d', [Length(HexOnly), Current.Line, Current.Col]), Current.Line, Current.Col);

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
      FDiagnosticMode := False;
      FDiagnostics := nil;
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

function TDfmParser.ParseWithDiagnostics(const Source: string): TParseResult;
var
  Lexer: TDfmLexer;
  HasErrors: Boolean;
  I: Integer;
begin
  Result.Form := nil;
  Result.Diagnostics := nil;
  Result.Success := False;

  FDiagnostics := TList<TFormDiagnostic>.Create;
  try
    Lexer := TDfmLexer.Create;
    try
      FTokens := Lexer.Tokenize(Source);
      try
        FPos := 0;
        FDiagnosticMode := True;
        Result.Form := TFormFile.Create;
        try
          SkipTrivia;
          if not AtEnd and IsObjectKeyword then
            Result.Form.Root := ParseObject
          else if not AtEnd and (CurrentKind <> dtkEOF) then
            AddDiag(dsError, DiagInvalidValueSyntax, Format('Expected object/inherited/inline keyword, got ''%s'' at line %d col %d', [CurrentText, Current.Line, Current.Col]), Current.Line, Current.Col);
        except
          on E: Exception do
          begin
            var Line := 0;
            var Col := 0;
            AddDiag(dsError, DiagInvalidValueSyntax, E.Message, Line, Col);
          end;
        end;
      finally
        FTokens.Free;
      end;
    finally
      Lexer.Free;
    end;

    // Check for any recovery that happened (warnings present but parsed OK)
    HasErrors := False;
    for I := 0 to FDiagnostics.Count - 1 do
    begin
      if FDiagnostics[I].Severity = dsError then
      begin
        HasErrors := True;
        Break;
      end;
    end;

    if (not HasErrors) and (FDiagnostics.Count > 0) then
      AddDiag(dsInfo, DiagParsedWithRecovery, 'Form parsed with recovery (warnings present)', 0, 0);

    Result.Success := not HasErrors;
    Result.Diagnostics := FDiagnostics.ToArray;
  finally
    FDiagnostics.Free;
    FDiagnostics := nil;
    FDiagnosticMode := False;
  end;
end;

end.
