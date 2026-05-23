program Delphi.Forms.FormStats;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Delphi.Forms.FormStats.Main in 'Delphi.Forms.FormStats.Main.pas',
  Delphi.Forms.Info in '..\..\source\Delphi.Forms.Info.pas',
  Delphi.Forms.Types in '..\..\source\Delphi.Forms.Types.pas',
  Delphi.Forms.Token in '..\..\source\Delphi.Forms.Token.pas',
  Delphi.Forms.Lexer in '..\..\source\Delphi.Forms.Lexer.pas',
  Delphi.Forms.Parser in '..\..\source\Delphi.Forms.Parser.pas',
  Delphi.Forms.TextWriter in '..\..\source\Delphi.Forms.TextWriter.pas',
  Delphi.Forms.BinaryReader in '..\..\source\Delphi.Forms.BinaryReader.pas',
  Delphi.Forms.BinaryWriter in '..\..\source\Delphi.Forms.BinaryWriter.pas',
  Delphi.Forms in '..\..\source\Delphi.Forms.pas';

begin
  ExitCode := TFormStats.Run;
end.
