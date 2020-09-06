program AutoFixtureProject;
{$M+}
{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  MockTest in 'Test\MockTest.pas',
  AutoFixture in 'AutoFixture.pas',
  AutofixtureGenerator in 'AutofixtureGenerator.pas',
  Test.RandomGeneratorTest in 'Test\Test.RandomGeneratorTest.pas',
  EncapsulatedRecord in 'EncapsulatedRecord.pas',
  AutoFixture.IdGenerator in 'AutoFixture.IdGenerator.pas',
  Test.AutoFixture in 'Test\Test.AutoFixture.pas',
  AutoFixtureExample1 in 'Examples\AutoFixtureExample1.pas',
  ClassesToTest in 'Examples\ClassesToTest.pas',
  AutofixtureExample2 in 'Examples\AutofixtureExample2.pas',
  AutoFixtureSetup in 'AutoFixtureSetup.pas',
  Test.AutoFixture.Types in 'Test\Test.AutoFixture.Types.pas',
  Test.AutoFixture.Configure in 'Test\Test.AutoFixture.Configure.pas',
  Test.AutoFixture.Build in 'Test\Test.AutoFixture.Build.pas',
  Test.Autofixture.exceptions in 'Test\Test.Autofixture.exceptions.pas',
  Test.Autofixture.Setup in 'Test\Test.Autofixture.Setup.pas',
  AutoFixtureLibrary in 'AutoFixtureLibrary.pas',
  CustomizationExamples in 'Examples\CustomizationExamples.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

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
end.
