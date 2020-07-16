unit AutoFixtureExample1;

interface
uses
  DUnitX.TestFramework,
  ClassesToTest;

type
  // Two identical tests shown, one using autofixture, and the other using traditional mocking

  [TestFixture]
  TAutoFixtureExample1 = class(TObject)
  protected
    UUT: IUnitUnderTest;
  public
    [Test]
    [TestCase('Concat', 'Two,Words,TwoWords')]
    [TestCase('Simple', 'Use,Mocking,UseMocking')]
    procedure SimpleTestNoAutofixture(AParam1, AParam2, AExpectedResult: String);

    [Test]
    [TestCase('Concat', 'Two', 'ConcatTwo')]
    [TestCase('Simple', 'Mocking', 'SimpleMocking')]
    procedure SimpleTestWithAutofixture(AParam1, AParam2, AExpectedResult: String);
  end;

implementation

uses
  Delphi.Mocks,
  AutoFixture;

// Simple example where a call to an external dependency is mocked
procedure TAutoFixtureExample1.SimpleTestNoAutofixture(AParam1, AParam2, AExpectedResult: String);
var
  vMock: TMock<IExternalDependence>;
  vResult : String;
begin
  // Arrange
  vMock := vMock.Create;
  UUT := TUnitUnderTest.Create(vMock);
  vMock.Setup.WillReturn(AParam1 + AParam2).When.DoExternalWork(AParam1 + AParam2);

  // Act
  vResult := UUT.SimpleConcatTest(AParam1, AParam2);

  // Assert
  Assert.AreEqual(vResult, AExpectedResult);
end;

// This first example is very simple, and doesn't begin to show the strength of Autofixture
// It does show how mocking can be implemented very simply inside autofixture
// it also shows how it's possible to create an object without supplying all constructor parameters
// Try to alter the class TUnitUnderTest, so the constructor gains another parameter, which test will fail to compile?
procedure TAutoFixtureExample1.SimpleTestWithAutofixture(AParam1, AParam2, AExpectedResult: String);
var
  vFixture: IAutoFixture;
  vResult : String;
begin
  vFixture := TAutoFixture.Create();
  with vFixture.Fixture do begin
    // Arrange
    DMock<IExternalDependence>.Setup.WillReturn(AParam1 + AParam2).When.DoExternalWork(AParam1 + AParam2);
    UUT := New<TUnitUnderTest>;

    // Act
    vResult := UUT.SimpleConcatTest(AParam1, AParam2);

    // Assert
    Assert.AreEqual(vResult, AExpectedResult);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAutoFixtureExample1);
end.
