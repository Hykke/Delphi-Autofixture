unit Test.AutoFixture.Build;

interface

uses AutoFixture,
  DUnitX.TestFramework,
  Generics.Collections,
  Test.AutoFixture.Types;

type

[TestFixture]
TAutofixtureBuildTest = class
private
  UUT: TAutoFixture;
public
    [SetUp]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestBuildString;

    [Test]
    procedure TestBuildInt;

    [Test]
    procedure TestBuildChar;

    [Test]
    procedure TestBuildInt64;

    [Test]
    [Testcase('Normal', '0.123456789')]
    [Testcase('Zero', '0')]
    [Testcase('Negative', '-1.7657')]
    [Testcase('Large', '123456789123456789')]
    procedure TestBuildDouble(ADouble: Double);

    [Test]
    [Testcase('Normal', '0.123456789')]
    [Testcase('Zero', '0')]
    [Testcase('Negative', '-1.7657')]
    [Testcase('Large', '123456789123456789')]
    procedure TestBuildExtended(AValue: Extended);

    [Test]
    [Testcase('Past', '1800-01-01')]
    [Testcase('Future', '2100-11-12')]
    procedure TestBuildDateTime(ADatetime: TDateTime);

    [Test]
    [Testcase('True', 'True')]
    [Testcase('False', 'False')]
    procedure TestBuildBoolean1(AValue: Boolean);

    [Test]
    [Testcase('True', 'True')]
    [Testcase('False', 'False')]
    procedure TestBuildBoolean2(AValue: Boolean);

    [Test]
    [Testcase('True', 'True')]
    [Testcase('False', 'False')]
    procedure TestBuildBoolean3(AValue: Boolean);

    [Test]
    [Testcase('Normal', 'Test string')]
    [Testcase('Blank', '')]
    procedure TestBuild3Objects(AValue: String);

    [Test]
    procedure TestRecord;
end;



implementation

uses SysUtils;

{ TAutofixtureTest }

procedure TAutofixtureBuildTest.Setup;
begin
  UUT := TAutoFixture.Create;
end;

procedure TAutofixtureBuildTest.TearDown;
begin
  FreeAndNil(UUT);
end;

procedure TAutofixtureBuildTest.TestBuildInt64;
var
  vTest : TTestSubClass;
begin
  // Act
  vTest := UUT.Build<TTestSubClass>.WithValue<Int64>(
    function (ATestSubClass: TTestSubClass): Int64
    begin
      Result := ATestSubClass.FInt64;
    end,
    123456789012).New;

  // Assert
  Assert.AreEqual<Int64>(123456789012, vTest.FInt64, 'Build Int64');
end;

procedure TAutofixtureBuildTest.TestBuildInt;
var
  vTest : TTestSubClass;
begin
  // Act
  vTest := UUT.Build<TTestSubClass>.WithValue<Integer>(
    function (ATestSubClass: TTestSubClass): Integer
    begin
      Result := ATestSubClass.FInt;
    end,
    42).New;

  // Assert
  Assert.AreEqual(42, vTest.FInt, 'Build Int');
end;

procedure TAutofixtureBuildTest.TestBuildString;
var
  vTest : TTestSubClass;
begin
  // Act
  vTest := UUT.Build<TTestSubClass>.WithValue<String>(
    function (ATestSubClass: TTestSubClass): String
    begin
      Result := ATestSubClass.FSubProperty;
    end,
    'Test string').New;

  // Assert
  Assert.AreEqual('Test string', vTest.FSubProperty, 'Build String');
end;

procedure TAutofixtureBuildTest.TestRecord;
var
  vTest : TTestSubClass;
begin
  // Act
  vTest := UUT.Build<TTestSubClass>.New;

  // Assert
  Assert.AreEqual('', vTest.FRecord.FString, 'Build Record String');
  Assert.AreEqual(0, vTest.FRecord.Fint, 'Build Record Int');
end;

procedure TAutofixtureBuildTest.TestBuild3Objects(AValue: String);
var
  vTest1, vTest2, vTest3 : TTestSubClass;
begin
  // Arrange
  vTest1 := UUT.Build<TTestSubClass>.WithValue<String>(
    function (ATestSubClass: TTestSubClass): String
    begin
      Result := ATestSubClass.FSubProperty;
    end,
    AValue + '1').New;

  UUT.Configure<TTestSubClass>.WithValue<String>(
    function (ATestSubClass: TTestSubClass): String
    begin
      Result := ATestSubClass.FSubProperty;
    end,
    AValue + '2');

  vTest3 := UUT.Build<TTestSubClass>.WithValue<String>(
    function (ATestSubClass: TTestSubClass): String
    begin
      Result := ATestSubClass.FSubProperty;
    end,
    AValue + '3').New;

  // Act
  vTest2 := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(AValue + '1', vTest1.FSubProperty, 'Build 3 objects 1');
  Assert.AreEqual(AValue + '2', vTest2.FSubProperty, 'Build 3 objects 2');
  Assert.AreEqual(AValue + '3', vTest3.FSubProperty, 'Build 3 objects 3');
end;

procedure TAutofixtureBuildTest.TestBuildBoolean1(AValue: Boolean);
var
  vTest : TTestSubClass;
begin
  // Arrange
  vTest := UUT.Build<TTestSubClass>.WithValue<Boolean>(
    function (ATestSubClass: TTestSubClass): Boolean
    begin
      Result := ATestSubClass.FBool1;
    end,
    AValue).New;

  // Assert
  Assert.AreEqual(AValue, vTest.FBool1, 'Build Bool 3');
end;

procedure TAutofixtureBuildTest.TestBuildBoolean2(AValue: Boolean);
var
  vTest : TTestSubClass;
begin
  // Act
  vTest := UUT.Build<TTestSubClass>.WithValue<Boolean>(
    function (ATestSubClass: TTestSubClass): Boolean
    begin
      Result := ATestSubClass.FBool2;
    end,
    AValue).New;

  // Assert
  Assert.AreEqual(AValue, vTest.FBool2, 'Build Bool 3');
end;

procedure TAutofixtureBuildTest.TestBuildBoolean3(AValue: Boolean);
var
  vTest : TTestSubClass;
begin
  // Act
  vTest := UUT.Build<TTestSubClass>.WithValue<Boolean>(
    function (ATestSubClass: TTestSubClass): Boolean
    begin
      Result := ATestSubClass.FBool3;
    end,
    AValue).New;

  // Assert
  Assert.AreEqual(AValue, vTest.FBool3, 'Build Bool 3');
end;

procedure TAutofixtureBuildTest.TestBuildChar;
var
  vTest : TTestSubClass;
begin
  // Act
  vTest := UUT.Build<TTestSubClass>.WithValue<Char>(
    function (ATestSubClass: TTestSubClass): Char
    begin
      Result := ATestSubClass.FChar;
    end,
    '@').New;

  // Assert
  Assert.AreEqual('@', vTest.FChar, 'Build char');
end;

procedure TAutofixtureBuildTest.TestBuildDateTime(ADatetime: TDateTime);
var
  vTest : TTestSubClass;
begin
  // Arrange
  vTest := UUT.Build<TTestSubClass>.WithValue<TDateTime>(
    function (ATestSubClass: TTestSubClass): TDateTime
    begin
      Result := ATestSubClass.FDate;
    end,
    ADateTime).New;

  // Assert
  Assert.AreEqual(ADateTime, vTest.FDate, 'Build Datetime');
end;

procedure TAutofixtureBuildTest.TestBuildDouble(ADouble: Double);
var
  vTest : TTestSubClass;
begin
  // Arrange
  vTest := UUT.Build<TTestSubClass>.WithValue<Double>(
    function (ATestSubClass: TTestSubClass): Double
    begin
      Result := ATestSubClass.FDouble;
    end,
    ADouble).New;

  // Assert
  Assert.AreEqual(ADouble, vTest.FDouble, 'Build Double');
end;

procedure TAutofixtureBuildTest.TestBuildExtended(AValue: Extended);
var
  vTest : TTestSubClass;
begin
  // Arrange
  vTest :=UUT.Build<TTestSubClass>.WithValue<Extended>(
    function (ATestSubClass: TTestSubClass): Extended
    begin
      Result := ATestSubClass.FExtended;
    end,
    AValue).New;

  // Assert
  Assert.AreEqual(AValue, vTest.FExtended, 'Build Extended');
end;

end.
