unit Test.Delphi.Forms.Smoke;

interface

uses
  DUnitX.TestFramework;

type

  [TestFixture]
  TDUnitXTooling = class
  public

  ///<summary>
  ///  Simple test to ensure the basic tooling is operational
  ///</summary>
  [Test]
  procedure ExampleSuccessfulTest;

  {$IFDEF TEST_FAILURE}
  [Test]
  procedure ExampleFailedTest;
  {$ENDIF}
  end;

implementation


procedure TDUnitXTooling.ExampleSuccessfulTest;
begin
  Assert.IsTrue(True, 'Replicate a successful test');
end;

{$IFDEF TEST_FAILURE}
procedure TDUnitXTooling.ExampleFailedTest;
begin
  Assert.IsTrue(False, 'Replicate a failed test');
end;
{$ENDIF}

initialization
  TDUnitX.RegisterTestFixture(TDUnitXTooling);

end.
