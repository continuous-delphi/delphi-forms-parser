unit Test.Delphi.Forms.Lexer;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Delphi.Forms.Token,
  Delphi.Forms.Lexer;

type

  [TestFixture]
  TDfmLexerTests = class
  private
    FLexer: TDfmLexer;
    function Tok(const Source: string): TDfmTokenList;
    procedure AssertRoundTrip(const Source: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Empty_ProducesEOF;
    [Test]
    procedure Identifier_Simple;
    [Test]
    procedure Identifier_WithUnderscore;
    [Test]
    procedure Identifier_Keywords;
    [Test]
    procedure Integer_Decimal;
    [Test]
    procedure Integer_Hex;
    [Test]
    procedure Integer_NegativeIsTwo;
    [Test]
    procedure Float_Simple;
    [Test]
    procedure Float_Exponent;
    [Test]
    procedure String_Simple;
    [Test]
    procedure String_EscapedQuote;
    [Test]
    procedure String_Empty;
    [Test]
    procedure CharLiteral_Decimal;
    [Test]
    procedure CharLiteral_Hex;
    [Test]
    procedure BinaryData_SingleLine;
    [Test]
    procedure BinaryData_MultiLine;
    [Test]
    procedure Symbols_AllSingle;
    [Test]
    procedure Whitespace_SpacesAndTabs;
    [Test]
    procedure EOL_LF;
    [Test]
    procedure EOL_CRLF;
    [Test]
    procedure EOL_CR;
    [Test]
    procedure LineTracking;
    [Test]
    procedure StartOffset_Tracking;
    [Test]
    procedure RoundTrip_SimpleForm;
    [Test]
    procedure RoundTrip_BinaryData;
    [Test]
    procedure RoundTrip_StringConcat;
    [Test]
    procedure RoundTrip_SetValue;
    [Test]
    procedure RoundTrip_DesignSize;
    [Test]
    procedure AlwaysEndsWithEOF;
  end;

implementation

procedure TDfmLexerTests.Setup;
begin
  FLexer := TDfmLexer.Create;
end;

procedure TDfmLexerTests.TearDown;
begin
  FLexer.Free;
end;

function TDfmLexerTests.Tok(const Source: string): TDfmTokenList;
begin
  Result := FLexer.Tokenize(Source);
end;

procedure TDfmLexerTests.AssertRoundTrip(const Source: string);
var
  Tokens: TDfmTokenList;
  Rebuilt: string;
  I: Integer;
begin
  Tokens := Tok(Source);
  try
    Rebuilt := '';
    for I := 0 to Tokens.Count - 1 do
      Rebuilt := Rebuilt + Tokens[I].Text;
    Assert.AreEqual(Source, Rebuilt, 'Round-trip failed');
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Empty_ProducesEOF;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('');
  try
    Assert.AreEqual(NativeInt(1), Tokens.Count);
    Assert.AreEqual(dtkEOF, Tokens[0].Kind);
    Assert.AreEqual('', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Identifier_Simple;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('Button1');
  try
    Assert.AreEqual(NativeInt(2), Tokens.Count);
    Assert.AreEqual(dtkIdentifier, Tokens[0].Kind);
    Assert.AreEqual('Button1', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Identifier_WithUnderscore;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('my_component');
  try
    Assert.AreEqual(dtkIdentifier, Tokens[0].Kind);
    Assert.AreEqual('my_component', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Identifier_Keywords;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('object end inherited inline item True False');
  try
    Assert.AreEqual(dtkIdentifier, Tokens[0].Kind);
    Assert.AreEqual('object', Tokens[0].Text);
    Assert.AreEqual(dtkIdentifier, Tokens[2].Kind);
    Assert.AreEqual('end', Tokens[2].Text);
    Assert.AreEqual(dtkIdentifier, Tokens[4].Kind);
    Assert.AreEqual('inherited', Tokens[4].Text);
    Assert.AreEqual(dtkIdentifier, Tokens[6].Kind);
    Assert.AreEqual('inline', Tokens[6].Text);
    Assert.AreEqual(dtkIdentifier, Tokens[8].Kind);
    Assert.AreEqual('item', Tokens[8].Text);
    Assert.AreEqual(dtkIdentifier, Tokens[10].Kind);
    Assert.AreEqual('True', Tokens[10].Text);
    Assert.AreEqual(dtkIdentifier, Tokens[12].Kind);
    Assert.AreEqual('False', Tokens[12].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Integer_Decimal;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('42');
  try
    Assert.AreEqual(dtkInteger, Tokens[0].Kind);
    Assert.AreEqual('42', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Integer_Hex;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('$FF00FF');
  try
    Assert.AreEqual(dtkInteger, Tokens[0].Kind);
    Assert.AreEqual('$FF00FF', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Integer_NegativeIsTwo;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('-12');
  try
    Assert.AreEqual(NativeInt(3), Tokens.Count); // minus, integer, EOF
    Assert.AreEqual(dtkMinus, Tokens[0].Kind);
    Assert.AreEqual(dtkInteger, Tokens[1].Kind);
    Assert.AreEqual('12', Tokens[1].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Float_Simple;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('3.14');
  try
    Assert.AreEqual(dtkFloat, Tokens[0].Kind);
    Assert.AreEqual('3.14', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Float_Exponent;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('1.5E-10');
  try
    Assert.AreEqual(dtkFloat, Tokens[0].Kind);
    Assert.AreEqual('1.5E-10', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.String_Simple;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('''Hello World''');
  try
    Assert.AreEqual(dtkString, Tokens[0].Kind);
    Assert.AreEqual('''Hello World''', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.String_EscapedQuote;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('''can''''t''');
  try
    Assert.AreEqual(dtkString, Tokens[0].Kind);
    Assert.AreEqual('''can''''t''', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.String_Empty;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('''''');
  try
    Assert.AreEqual(dtkString, Tokens[0].Kind);
    Assert.AreEqual('''''', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.CharLiteral_Decimal;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('#13');
  try
    Assert.AreEqual(dtkCharLiteral, Tokens[0].Kind);
    Assert.AreEqual('#13', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.CharLiteral_Hex;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('#$0D');
  try
    Assert.AreEqual(dtkCharLiteral, Tokens[0].Kind);
    Assert.AreEqual('#$0D', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.BinaryData_SingleLine;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('{0A544A}');
  try
    Assert.AreEqual(dtkBinaryData, Tokens[0].Kind);
    Assert.AreEqual('{0A544A}', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.BinaryData_MultiLine;
var
  Tokens: TDfmTokenList;
  Source: string;
begin
  Source := '{' + #13#10 + '  0A544A' + #13#10 + '  FF0000' + #13#10 + '}';
  Tokens := Tok(Source);
  try
    Assert.AreEqual(dtkBinaryData, Tokens[0].Kind);
    Assert.AreEqual(Source, Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Symbols_AllSingle;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('=:.,+-[]()<>');
  try
    Assert.AreEqual(dtkEquals, Tokens[0].Kind);
    Assert.AreEqual(dtkColon, Tokens[1].Kind);
    Assert.AreEqual(dtkDot, Tokens[2].Kind);
    Assert.AreEqual(dtkComma, Tokens[3].Kind);
    Assert.AreEqual(dtkPlus, Tokens[4].Kind);
    Assert.AreEqual(dtkMinus, Tokens[5].Kind);
    Assert.AreEqual(dtkLBracket, Tokens[6].Kind);
    Assert.AreEqual(dtkRBracket, Tokens[7].Kind);
    Assert.AreEqual(dtkLParen, Tokens[8].Kind);
    Assert.AreEqual(dtkRParen, Tokens[9].Kind);
    Assert.AreEqual(dtkLAngle, Tokens[10].Kind);
    Assert.AreEqual(dtkRAngle, Tokens[11].Kind);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.Whitespace_SpacesAndTabs;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('  '#9' ');
  try
    Assert.AreEqual(NativeInt(2), Tokens.Count);
    Assert.AreEqual(dtkWhitespace, Tokens[0].Kind);
    Assert.AreEqual('  '#9' ', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.EOL_LF;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok(#10);
  try
    Assert.AreEqual(dtkEOL, Tokens[0].Kind);
    Assert.AreEqual(#10, Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.EOL_CRLF;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok(#13#10);
  try
    Assert.AreEqual(dtkEOL, Tokens[0].Kind);
    Assert.AreEqual(#13#10, Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.EOL_CR;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok(#13);
  try
    Assert.AreEqual(dtkEOL, Tokens[0].Kind);
    Assert.AreEqual(#13, Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.LineTracking;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('abc'#13#10'def');
  try
    Assert.AreEqual(1, Tokens[0].Line, 'abc line');
    Assert.AreEqual(1, Tokens[0].Col, 'abc col');
    Assert.AreEqual(1, Tokens[1].Line, 'EOL line');
    Assert.AreEqual(2, Tokens[2].Line, 'def line');
    Assert.AreEqual(1, Tokens[2].Col, 'def col');
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.StartOffset_Tracking;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('ab cd');
  try
    Assert.AreEqual(0, Tokens[0].StartOffset, 'ab offset');
    Assert.AreEqual(2, Tokens[1].StartOffset, 'space offset');
    Assert.AreEqual(3, Tokens[2].StartOffset, 'cd offset');
  finally
    Tokens.Free;
  end;
end;

procedure TDfmLexerTests.RoundTrip_SimpleForm;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 0'#13#10 +
    '  Caption = ''Hello'''#13#10 +
    '  object Button1: TButton'#13#10 +
    '    Left = 8'#13#10 +
    '  end'#13#10 +
    'end'#13#10
  );
end;

procedure TDfmLexerTests.RoundTrip_BinaryData;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  Picture.Data = {'#13#10 +
    '    0A544A504547496D616765'#13#10 +
    '    FF00FF00FF00}'#13#10 +
    'end'#13#10
  );
end;

procedure TDfmLexerTests.RoundTrip_StringConcat;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  Caption = ''Line 1''#13#10 +' + #13#10 +
    '    ''Line 2'''#13#10 +
    'end'#13#10
  );
end;

procedure TDfmLexerTests.RoundTrip_SetValue;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  Anchors = [akLeft, akTop, akRight]'#13#10 +
    '  Font.Style = []'#13#10 +
    'end'#13#10
  );
end;

procedure TDfmLexerTests.RoundTrip_DesignSize;
begin
  AssertRoundTrip(
    'object frmMain: TfrmMain'#13#10 +
    '  DesignSize = ('#13#10 +
    '    997'#13#10 +
    '    848)'#13#10 +
    'end'#13#10
  );
end;

procedure TDfmLexerTests.AlwaysEndsWithEOF;
var
  Tokens: TDfmTokenList;
begin
  Tokens := Tok('abc');
  try
    Assert.AreEqual(dtkEOF, Tokens[Tokens.Count - 1].Kind, 'Last token must be EOF');
    Assert.AreEqual('', Tokens[Tokens.Count - 1].Text, 'EOF text must be empty');
  finally
    Tokens.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDfmLexerTests);

end.
