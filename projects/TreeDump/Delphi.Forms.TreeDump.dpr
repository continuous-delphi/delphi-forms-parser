program Delphi.Forms.TreeDump;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Delphi.Forms.Info in '..\..\source\Delphi.Forms.Info.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
