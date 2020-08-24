unit Test.AutoFixture.Configure;

interface

uses AutoFixture,
  DUnitX.TestFramework,
  Generics.Collections,
  Test.AutoFixture.Types;

type

[TestFixture]
TAutofixtureConfigureTest = class
private
  UUT: TAutoFixture;
public
    [SetUp]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestConfigureString;

    [Test]
    procedure TestConfigureInt;

    [Test]
    procedure TestConfigureChar;

    [Test]
    procedure TestConfigureInt64;

    [Test]
    [Testcase('Normal', '0.123456789')]
    [Testcase('Zero', '0')]
    [Testcase('Negative', '-1.7657')]
    [Testcase('Large', '123456789123456789')]
    procedure TestConfigureDouble(ADouble: Double);

    [Test]
    [Testcase('Normal', '0.123456789')]
    [Testcase('Zero', '0')]
    [Testcase('Negative', '-1.7657')]
    [Testcase('Large', '123456789123456789')]
    procedure TestConfigureExtended(AValue: Extended);

    [Test]
    [Testcase('Past', '1800-01-01')]
    [Testcase('Future', '2100-11-12')]
    procedure TestConfigureDateTime(ADatetime: TDateTime);

    [Test]
    [Testcase('True', 'True')]
    [Testcase('False', 'False')]
    procedure TestConfigureBoolean1(AValue: Boolean);

    [Test]
    [Testcase('True', 'True')]
    [Testcase('False', 'False')]
    procedure TestConfigureBoolean2(AValue: Boolean);

    [Test]
    [Testcase('True', 'True')]
    [Testcase('False', 'False')]
    procedure TestConfigureBoolean3(AValue: Boolean);

    [Test]
    [Testcase('Normal', 'Test string')]
    [Testcase('Blank', '')]
    procedure TestConfigure3Objects(AValue: String);

    [Test]
    procedure TestConfigureSmallSet;

    [Test]
    procedure TestOmit;

    [Test]
    procedure TestOmitByName;

    [Test]
    procedure TestEnum;

    [Test]
    procedure TestRecord;
end;

implementation

uses SysUtils,
  Rtti;

{ TAutofixtureTest }

procedure TAutofixtureConfigureTest.Setup;
begin
  UUT := TAutoFixture.Create;
end;

procedure TAutofixtureConfigureTest.TearDown;
begin
  FreeAndNil(UUT);
end;

procedure TAutofixtureConfigureTest.TestConfigureInt64;
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Int64>(
    function (ATestSubClass: TTestSubClass): Int64
    begin
      Result := ATestSubClass.FInt64;
    end,
    123456789012);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual<Int64>(123456789012, vTest.FInt64, 'Configure Int64');
end;

procedure TAutofixtureConfigureTest.TestConfigureSmallSet;
var
  vTest: TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<TWeekEnumSet>(
    function (ATestSubClass: TTestSubClass): TWeekEnumSet
    begin
      Result := ATestSubClass.FWeekEnumSet;
    end,
    [monday, thursday, sunday]);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual<TWeekEnumSet>([monday, thursday, sunday], vTest.FWeekEnumSet, 'Configure Small set');
end;

procedure TAutofixtureConfigureTest.TestConfigureInt;
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Integer>(
    function (ATestSubClass: TTestSubClass): Integer
    begin
      Result := ATestSubClass.FInt;
    end,
    42);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(42, vTest.FInt, 'Configure Int');
end;

procedure TAutofixtureConfigureTest.TestOmit;
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.Omit<Integer>(
    function (ATestSubClass: TTestSubClass): Integer
    begin
      Result := ATestSubClass.FInt;
    end);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(0, vTest.FInt, 'Omit Int'); // 0 is the default value for int, which is used of the init of the property is omitted
end;


procedure TAutofixtureConfigureTest.TestOmitByName;
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.Omit<Integer>('FInt');

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(0, vTest.FInt, 'Omit Int by name'); // 0 is the default value for int, which is used of the init of the property is omitted
end;

procedure TAutofixtureConfigureTest.TestRecord;
var
  vTest: TTestSubClass;
  vRec: TRecord;
begin
  // Arrange
  vRec.FString := UUT.New<string>;
  vRec.FInt := UUT.New<integer>;

  UUT.Configure<TTestSubClass>.WithValue<TRecord>(
    function (ATestSubClass: TTestSubClass): TRecord
    begin
      Result := ATestSubClass.FRecord;
    end,
    vRec);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(vRec, vTest.FRecord, 'Configure String');
end;

procedure TAutofixtureConfigureTest.TestConfigureString;
var
  vTest: TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<String>(
    function (ATestSubClass: TTestSubClass): String
    begin
      Result := ATestSubClass.FSubProperty;
    end,
    'Test string');

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual('Test string', vTest.FSubProperty, 'Configure String');
end;

procedure TAutofixtureConfigureTest.TestEnum;
var
  vTest: TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<TDayEnum>(
    function (ATestSubClass: TTestSubClass): TDayEnum
    begin
      Result := ATestSubClass.FDay;
    end,
    TDayEnum.friday);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(TDayEnum.friday, vTest.FDay, 'Configure Enum');
end;

procedure TAutofixtureConfigureTest.TestConfigure3Objects(AValue: String);
var
  vTest1, vTest2, vTest3 : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<String>(
    function (ATestSubClass: TTestSubClass): String
    begin
      Result := ATestSubClass.FSubProperty;
    end,
    AValue);

  // Act
  vTest1 := UUT.New<TTestSubClass>;
  vTest2 := UUT.New<TTestSubClass>;
  vTest3 := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(AValue, vTest1.FSubProperty, 'Configure 3 objects 1');
  Assert.AreEqual(AValue, vTest2.FSubProperty, 'Configure 3 objects 2');
  Assert.AreEqual(AValue, vTest3.FSubProperty, 'Configure 3 objects 3');
end;

procedure TAutofixtureConfigureTest.TestConfigureBoolean1(AValue: Boolean);
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Boolean>(
    function (ATestSubClass: TTestSubClass): Boolean
    begin
      Result := ATestSubClass.FBool1;
    end,
    AValue);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(AValue, vTest.FBool1, 'Configure Bool 3');
end;

procedure TAutofixtureConfigureTest.TestConfigureBoolean2(AValue: Boolean);
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Boolean>(
    function (ATestSubClass: TTestSubClass): Boolean
    begin
      Result := ATestSubClass.FBool2;
    end,
    AValue);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(AValue, vTest.FBool2, 'Configure Bool 3');
end;

procedure TAutofixtureConfigureTest.TestConfigureBoolean3(AValue: Boolean);
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Boolean>(
    function (ATestSubClass: TTestSubClass): Boolean
    begin
      Result := ATestSubClass.FBool3;
    end,
    AValue);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(AValue, vTest.FBool3, 'Configure Bool 3');
end;

procedure TAutofixtureConfigureTest.TestConfigureChar;
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Char>(
    function (ATestSubClass: TTestSubClass): Char
    begin
      Result := ATestSubClass.FChar;
    end,
    '@');

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual('@', vTest.FChar, 'Configure char');
end;

procedure TAutofixtureConfigureTest.TestConfigureDateTime(ADatetime: TDateTime);
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<TDateTime>(
    function (ATestSubClass: TTestSubClass): TDateTime
    begin
      Result := ATestSubClass.FDate;
    end,
    ADateTime);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(ADateTime, vTest.FDate, 'Configure Datetime');
end;

procedure TAutofixtureConfigureTest.TestConfigureDouble(ADouble: Double);
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Double>(
    function (ATestSubClass: TTestSubClass): Double
    begin
      Result := ATestSubClass.FDouble;
    end,
    ADouble);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(ADouble, vTest.FDouble, 'Configure Double');
end;

procedure TAutofixtureConfigureTest.TestConfigureExtended(AValue: Extended);
var
  vTest : TTestSubClass;
begin
  // Arrange
  UUT.Configure<TTestSubClass>.WithValue<Extended>(
    function (ATestSubClass: TTestSubClass): Extended
    begin
      Result := ATestSubClass.FExtended;
    end,
    AValue);

  // Act
  vTest := UUT.New<TTestSubClass>;

  // Assert
  Assert.AreEqual(AValue, vTest.FExtended, 'Configure Extended');
end;

end.
