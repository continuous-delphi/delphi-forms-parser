unit Delphi.Forms.Lexer;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms.Token;

type

  TDfmLexer = class
  private
    FSource: string;
    FPos: Integer;
    FLine: Integer;
    FCol: Integer;
    FLen: Integer;
    function Peek: Char; inline;
    function PeekAt(Offset: Integer): Char; inline;
    function AtEnd: Boolean; inline;
    procedure Advance; inline;
    function MakeToken(AKind: TDfmTokenKind; const AText: string; AStartOffset, AStartLine, AStartCol: Integer): TDfmToken;
    function ReadIdentifier: TDfmToken;
    function ReadNumber: TDfmToken;
    function ReadString: TDfmToken;
    function ReadCharLiteral: TDfmToken;
    function ReadBinaryData: TDfmToken;
    function ReadWhitespace: TDfmToken;
    function ReadEOL: TDfmToken;
  public
    function Tokenize(const Source: string): TDfmTokenList;
  end;

implementation

{ TDfmLexer }

function TDfmLexer.Peek: Char;
begin
  if FPos <= FLen then
    Result := FSource[FPos]
  else
    Result := #0;
end;

function TDfmLexer.PeekAt(Offset: Integer): Char;
var
  P: Integer;
begin
  P := FPos + Offset;
  if (P >= 1) and (P <= FLen) then
    Result := FSource[P]
  else
    Result := #0;
end;

function TDfmLexer.AtEnd: Boolean;
begin
  Result := FPos > FLen;
end;

procedure TDfmLexer.Advance;
begin
  Inc(FPos);
  Inc(FCol);
end;

function TDfmLexer.MakeToken(AKind: TDfmTokenKind; const AText: string; AStartOffset, AStartLine, AStartCol: Integer): TDfmToken;
begin
  Result.Kind := AKind;
  Result.Text := AText;
  Result.StartOffset := AStartOffset;
  Result.Line := AStartLine;
  Result.Col := AStartCol;
end;

function TDfmLexer.ReadIdentifier: TDfmToken;
var
  Start: Integer;
  StartLine: Integer;
  StartCol: Integer;
begin
  Start := FPos;
  StartLine := FLine;
  StartCol := FCol;
  while not AtEnd and CharInSet(Peek, ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    Advance;
  Result := MakeToken(dtkIdentifier, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
end;

function TDfmLexer.ReadNumber: TDfmToken;
var
  Start: Integer;
  StartLine: Integer;
  StartCol: Integer;
  IsFloat: Boolean;
begin
  Start := FPos;
  StartLine := FLine;
  StartCol := FCol;
  IsFloat := False;

  if Peek = '$' then
  begin
    Advance;
    while not AtEnd and CharInSet(Peek, ['0'..'9', 'A'..'F', 'a'..'f']) do
      Advance;
    Result := MakeToken(dtkInteger, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
    Exit;
  end;

  while not AtEnd and CharInSet(Peek, ['0'..'9']) do
    Advance;

  if not AtEnd and (Peek = '.') and CharInSet(PeekAt(1), ['0'..'9']) then
  begin
    IsFloat := True;
    Advance;
    while not AtEnd and CharInSet(Peek, ['0'..'9']) do
      Advance;
  end;

  if not AtEnd and CharInSet(Peek, ['E', 'e']) then
  begin
    IsFloat := True;
    Advance;
    if not AtEnd and CharInSet(Peek, ['+', '-']) then
      Advance;
    while not AtEnd and CharInSet(Peek, ['0'..'9']) do
      Advance;
  end;

  if IsFloat then
    Result := MakeToken(dtkFloat, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol)
  else
    Result := MakeToken(dtkInteger, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
end;

function TDfmLexer.ReadString: TDfmToken;
var
  Start: Integer;
  StartLine: Integer;
  StartCol: Integer;
begin
  Start := FPos;
  StartLine := FLine;
  StartCol := FCol;
  Advance; // skip opening quote
  while not AtEnd do
  begin
    if Peek = '''' then
    begin
      Advance;
      if not AtEnd and (Peek = '''') then
        Advance // escaped quote
      else
        Break; // end of string
    end
    else if (Peek = #13) or (Peek = #10) then
      Break // unterminated string at EOL
    else
      Advance;
  end;
  Result := MakeToken(dtkString, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
end;

function TDfmLexer.ReadCharLiteral: TDfmToken;
var
  Start: Integer;
  StartLine: Integer;
  StartCol: Integer;
begin
  Start := FPos;
  StartLine := FLine;
  StartCol := FCol;
  Advance; // skip #
  if not AtEnd and (Peek = '$') then
  begin
    Advance;
    while not AtEnd and CharInSet(Peek, ['0'..'9', 'A'..'F', 'a'..'f']) do
      Advance;
  end
  else
  begin
    while not AtEnd and CharInSet(Peek, ['0'..'9']) do
      Advance;
  end;
  Result := MakeToken(dtkCharLiteral, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
end;

function TDfmLexer.ReadBinaryData: TDfmToken;
var
  Start: Integer;
  StartLine: Integer;
  StartCol: Integer;
begin
  Start := FPos;
  StartLine := FLine;
  StartCol := FCol;
  Advance; // skip {
  while not AtEnd and (Peek <> '}') do
  begin
    if Peek = #13 then
    begin
      Inc(FLine);
      FCol := 0;
      Advance;
      if not AtEnd and (Peek = #10) then
      begin
        FCol := 0;
        Advance;
      end;
    end
    else if Peek = #10 then
    begin
      Inc(FLine);
      FCol := 0;
      Advance;
    end
    else
      Advance;
  end;
  if not AtEnd and (Peek = '}') then
    Advance;
  Result := MakeToken(dtkBinaryData, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
end;

function TDfmLexer.ReadWhitespace: TDfmToken;
var
  Start: Integer;
  StartLine: Integer;
  StartCol: Integer;
begin
  Start := FPos;
  StartLine := FLine;
  StartCol := FCol;
  while not AtEnd and CharInSet(Peek, [' ', #9]) do
    Advance;
  Result := MakeToken(dtkWhitespace, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
end;

function TDfmLexer.ReadEOL: TDfmToken;
var
  Start: Integer;
  StartLine: Integer;
  StartCol: Integer;
begin
  Start := FPos;
  StartLine := FLine;
  StartCol := FCol;
  if Peek = #13 then
  begin
    Advance;
    if not AtEnd and (Peek = #10) then
      Advance;
  end
  else
    Advance; // #10
  Inc(FLine);
  FCol := 1;
  Result := MakeToken(dtkEOL, Copy(FSource, Start, FPos - Start), Start - 1, StartLine, StartCol);
end;

function TDfmLexer.Tokenize(const Source: string): TDfmTokenList;
var
  C: Char;
  StartOffset: Integer;
  StartLine: Integer;
  StartCol: Integer;
begin
  FSource := Source;
  FPos := 1;
  FLine := 1;
  FCol := 1;
  FLen := Length(Source);
  Result := TDfmTokenList.Create;
  try
    while not AtEnd do
    begin
      C := Peek;
      case C of
        ' ', #9:
          Result.Add(ReadWhitespace);
        #13, #10:
          Result.Add(ReadEOL);
        '''':
          Result.Add(ReadString);
        '#':
          Result.Add(ReadCharLiteral);
        '{':
          Result.Add(ReadBinaryData);
        '$':
          Result.Add(ReadNumber);
        '0'..'9':
          Result.Add(ReadNumber);
        'A'..'Z', 'a'..'z', '_':
          Result.Add(ReadIdentifier);
        '=':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkEquals, '=', StartOffset, StartLine, StartCol));
        end;
        ':':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkColon, ':', StartOffset, StartLine, StartCol));
        end;
        '.':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkDot, '.', StartOffset, StartLine, StartCol));
        end;
        ',':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkComma, ',', StartOffset, StartLine, StartCol));
        end;
        '+':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkPlus, '+', StartOffset, StartLine, StartCol));
        end;
        '-':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkMinus, '-', StartOffset, StartLine, StartCol));
        end;
        '[':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkLBracket, '[', StartOffset, StartLine, StartCol));
        end;
        ']':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkRBracket, ']', StartOffset, StartLine, StartCol));
        end;
        '(':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkLParen, '(', StartOffset, StartLine, StartCol));
        end;
        ')':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkRParen, ')', StartOffset, StartLine, StartCol));
        end;
        '<':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkLAngle, '<', StartOffset, StartLine, StartCol));
        end;
        '>':
        begin
          StartOffset := FPos - 1;
          StartLine := FLine;
          StartCol := FCol;
          Advance;
          Result.Add(MakeToken(dtkRAngle, '>', StartOffset, StartLine, StartCol));
        end;
      else
        // Unknown character: emit as single-char identifier to preserve round-trip
        StartOffset := FPos - 1;
        StartLine := FLine;
        StartCol := FCol;
        Advance;
        Result.Add(MakeToken(dtkIdentifier, Copy(FSource, StartOffset + 1, 1), StartOffset, StartLine, StartCol));
      end;
    end;
    Result.Add(MakeToken(dtkEOF, '', FLen, FLine, FCol));
  except
    Result.Free;
    raise;
  end;
end;

end.
