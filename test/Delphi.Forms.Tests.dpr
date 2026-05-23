program Delphi.Forms.Tests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  DUnitX.MemoryLeakMonitor.FastMM4,
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.XML.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,
  Delphi.Forms.Info in '..\source\Delphi.Forms.Info.pas',
  Delphi.Forms.Types in '..\source\Delphi.Forms.Types.pas',
  Delphi.Forms.Token in '..\source\Delphi.Forms.Token.pas',
  Delphi.Forms.Lexer in '..\source\Delphi.Forms.Lexer.pas',
  Delphi.Forms.Parser in '..\source\Delphi.Forms.Parser.pas',
  Delphi.Forms.TextWriter in '..\source\Delphi.Forms.TextWriter.pas',
  Delphi.Forms.BinaryReader in '..\source\Delphi.Forms.BinaryReader.pas',
  Delphi.Forms.BinaryWriter in '..\source\Delphi.Forms.BinaryWriter.pas',
  Delphi.Forms.JSON in '..\source\Delphi.Forms.JSON.pas',
  Delphi.Forms.Statistics in '..\source\Delphi.Forms.Statistics.pas',
  Delphi.Forms.Diagnostics in '..\source\Delphi.Forms.Diagnostics.pas',
  Delphi.Forms.Normalize in '..\source\Delphi.Forms.Normalize.pas',
  Delphi.Forms.Visitor in '..\source\Delphi.Forms.Visitor.pas',
  Delphi.Forms.Path in '..\source\Delphi.Forms.Path.pas',
  Delphi.Forms.Navigation in '..\source\Delphi.Forms.Navigation.pas',
  Delphi.Forms in '..\source\Delphi.Forms.pas',
  Test.Delphi.Forms.Smoke in 'Test.Delphi.Forms.Smoke.pas',
  Test.Delphi.Forms.Types in 'Test.Delphi.Forms.Types.pas',
  Test.Delphi.Forms.Lexer in 'Test.Delphi.Forms.Lexer.pas',
  Test.Delphi.Forms.Parser in 'Test.Delphi.Forms.Parser.pas',
  Test.Delphi.Forms.TextWriter in 'Test.Delphi.Forms.TextWriter.pas',
  Test.Delphi.Forms.BinaryReader in 'Test.Delphi.Forms.BinaryReader.pas',
  Test.Delphi.Forms.BinaryWriter in 'Test.Delphi.Forms.BinaryWriter.pas',
  Test.Delphi.Forms.Golden in 'Test.Delphi.Forms.Golden.pas',
  Test.Delphi.Forms.RoundTrip in 'Test.Delphi.Forms.RoundTrip.pas',
  Test.Delphi.Forms.Diagnostics in 'Test.Delphi.Forms.Diagnostics.pas',
  Test.Delphi.Forms.Normalize in 'Test.Delphi.Forms.Normalize.pas',
  Test.Delphi.Forms.Visitor in 'Test.Delphi.Forms.Visitor.pas',
  Test.Delphi.Forms.Path in 'Test.Delphi.Forms.Path.pas',
  Test.Delphi.Forms.Navigation in 'Test.Delphi.Forms.Navigation.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
