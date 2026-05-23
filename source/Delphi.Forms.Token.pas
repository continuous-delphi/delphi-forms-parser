unit Delphi.Forms.Token;

interface

uses
  System.Generics.Collections;

type

  TDfmTokenKind = (
    dtkIdentifier,
    dtkInteger,
    dtkFloat,
    dtkString,
    dtkCharLiteral,
    dtkEquals,
    dtkColon,
    dtkDot,
    dtkComma,
    dtkPlus,
    dtkMinus,
    dtkLBracket,
    dtkRBracket,
    dtkLParen,
    dtkRParen,
    dtkLAngle,
    dtkRAngle,
    dtkBinaryData,
    dtkWhitespace,
    dtkEOL,
    dtkEOF
  );

  TDfmToken = record
    Kind: TDfmTokenKind;
    Text: string;
    Line: Integer;
    Col: Integer;
    StartOffset: Integer;
  end;

  TDfmTokenList = TList<TDfmToken>;

function TokenKindToString(Kind: TDfmTokenKind): string;

implementation

uses
  System.SysUtils;

function TokenKindToString(Kind: TDfmTokenKind): string;
begin
  case Kind of
    dtkIdentifier:  Result := 'identifier';
    dtkInteger:     Result := 'integer';
    dtkFloat:       Result := 'float';
    dtkString:      Result := 'string';
    dtkCharLiteral: Result := 'char literal';
    dtkEquals:      Result := '''=''';
    dtkColon:       Result := ''':''';
    dtkDot:         Result := '''.''';
    dtkComma:       Result := ''',''';
    dtkPlus:        Result := '''+''';
    dtkMinus:       Result := '''-''';
    dtkLBracket:    Result := '''[''';
    dtkRBracket:    Result := ''']''';
    dtkLParen:      Result := '''(''';
    dtkRParen:      Result := ''')''';
    dtkLAngle:      Result := '''<''';
    dtkRAngle:      Result := '''>''';
    dtkBinaryData:  Result := 'binary data';
    dtkWhitespace:  Result := 'whitespace';
    dtkEOL:         Result := 'end of line';
    dtkEOF:         Result := 'end of file';
  else
    Result := Format('unknown(%d)', [Ord(Kind)]);
  end;
end;

end.
