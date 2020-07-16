unit Test.Autofixture.exceptions;

interface

uses AutoFixture,
  DUnitX.TestFramework,
  Generics.Collections,
  Test.AutoFixture.Types;

type

[TestFixture]
TAutofixtureExceptionTest = class
private
  UUT: TAutoFixture;
public
    [SetUp]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLargeSet;

    [Test]
    procedure TestLargeSetByName;
end;

implementation

uses SysUtils;

procedure TAutofixtureExceptionTest.Setup;
begin
  UUT := TAutoFixture.Create;
end;

procedure TAutofixtureExceptionTest.TearDown;
begin
  FreeAndNil(UUT);
end;

procedure TAutofixtureExceptionTest.TestLargeSet;
var
  vTest: TTestSubClass;
  vExpected: TWeekSet;
begin
  // Arrange
  vExpected := [1, 4];

  //Act + Assert
  Assert.WillRaiseWithMessage(
    procedure
    begin
      UUT.Configure<TTestSubClass>.WithValue<TWeekSet>(
        function (ATestSubClass: TTestSubClass): TWeekSet
        begin
          Result := ATestSubClass.FWeekdays;
        end,
        vExpected);
    end, Exception, 'Autofixture is unable to get RTTI type information for this type', 'Type error');
end;

procedure TAutofixtureExceptionTest.TestLargeSetByName;
var
  vTest: TTestSubClass;
  vExpected: TWeekSet;
begin
  // Arrange
  vExpected := [1, 4];

  //Act + Assert
  Assert.WillRaiseWithMessage(
    procedure
    begin
      UUT.Configure<TTestSubClass>.WithValue('FWeekdays', vExpected);
    end,
    Exception, 'Autofixture is unable to get RTTI type information for this type', 'Type error');
end;

end.
