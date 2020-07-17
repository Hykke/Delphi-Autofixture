unit Test.Autofixture;

interface

uses AutoFixture,
  DUnitX.TestFramework,
  Generics.Collections,
  Test.AutoFixture.Types;

type

[TestFixture]
TAutofixtureTest = class
private
  UUT: TAutoFixture;
public
    [SetUp]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreation;

    [Test]
    procedure TestInterfaceBinding;

    [Test]
    procedure TestInheritanceBinding;

    [Test]
    procedure TestObjectInitialization;

    [Test]
    procedure TestList;

    [Test]
    procedure TestValueString;

    [Test]
    procedure TestInjectString;

    [Test]
    procedure TestInjectDelegate;
end;



implementation

uses SysUtils;

{ TAutofixtureTest }

procedure TAutofixtureTest.Setup;
begin
  UUT := TAutoFixture.Create;
end;

procedure TAutofixtureTest.TearDown;
begin
  FreeAndNil(UUT);
end;

procedure TAutofixtureTest.TestCreation;
begin
  Assert.IsTrue(Assigned(UUT));
end;

procedure TAutofixtureTest.TestInheritanceBinding;
var
  vResult: TTestSubClass;
begin
  // Arrange
  UUT.RegisterType<ITestInterfaceType, TTestAbstractClass>;
  UUT.RegisterType<TTestAbstractClass, TTestSubClass>;
  // Act
  vResult := TTestSubClass(UUT.New<TTestAbstractClass>);
  // Assert
  Assert.IsTrue(vResult is TTestSubClass);
  Assert.AreNotEqual('', vResult.FSubProperty, 'Properties must have been initialized');
end;

procedure TAutofixtureTest.TestInjectString;
var
  s: String;
begin
  // Arrange
  UUT.Inject<String>('Ploeh');

  // Act
  s := UUT.NewValue<String>;

  // Assert
  Assert.AreEqual('Ploeh', s, 'String inject');
end;

procedure TAutofixtureTest.TestInjectDelegate;
var
  str1, str2: String;
begin
  // Arrange
  UUT.Inject<String>(
    function (APropertyName: String): String
    begin
      if APropertyName.ToUpper.Contains('NAME') then begin
        Result := 'Mark Seemann';
      end
      else begin
        Result := 'Unknown';
      end;
    end
  );

  // Act
  str1 := UUT.NewValue<String>('AnythingElse');
  str2 := UUT.NewValue<String>('MyName');

  // Assert
  Assert.AreNotEqual('Mark Seemann', str1, 'String delegate');
  Assert.AreEqual('Mark Seemann', str2, 'String delegate');
end;

procedure TAutofixtureTest.TestInterfaceBinding;
var
  vIObj: ITestInterfaceType;
begin
  // Arrange
  UUT.RegisterType<ITestInterfaceType, TTestAbstractClass>;
  UUT.RegisterType<TTestAbstractClass, TTestSubClass>;

  // Act
  vIObj := UUT.NewInterface<ITestInterfaceType>;

  // Assert
  Assert.IsTrue(vIObj is TTestSubClass);
  Assert.AreNotEqual('', TTestSubClass(vIObj).FSubProperty, 'Properties must have been initialized');
  Assert.AreEqual(TTestSubClass(vIObj).FList.Count, UUT.Setup.CollectionSize, 'List initialized with correct size');
end;

procedure TAutofixtureTest.TestList;
var
  vIObj: ITestInterfaceType;
begin
  // Arrange
  UUT.RegisterType<ITestInterfaceType, TTestAbstractClass>;
  UUT.RegisterType<TTestAbstractClass, TTestSubClass>;
  // Act
  vIObj := UUT.NewInterface<ITestInterfaceType>;

  // Assert
  Assert.AreEqual(1,1)
end;

procedure TAutofixtureTest.TestObjectInitialization;
var
  vResult: TTestSubClass;
begin
  // Arrange
  UUT.RegisterType<ITestInterfaceType, TTestAbstractClass>;
  UUT.RegisterType<TTestAbstractClass, TTestSubClass>;
  // Act
  vResult := UUT.New<TTestSubClass>;
  // Assert
  Assert.IsTrue(vResult is TTestSubClass);
  Assert.AreNotEqual('', vResult.FSubProperty, 'Properties must have been initialized');
end;

procedure TAutofixtureTest.TestValueString;
var s: String;
begin
  // Act
  s := UUT.NewValue<String>('Name');

  // Assert
  Assert.AreNotEqual('', s, 'String generation');
end;

end.
