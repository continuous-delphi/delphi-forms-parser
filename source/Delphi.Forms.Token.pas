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

implementation

end.
