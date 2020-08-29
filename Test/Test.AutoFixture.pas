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

    [Test]
    procedure TestObjectConstructor;

    [Test]
    procedure AddToArray;

    [Test]
    procedure AddToTList;

    [Test]
    procedure AddToObjectList;

    [Test]
    procedure AddToCollection;
end;



implementation

uses SysUtils,
  System.Classes,
  AutofixtureSetup;

{ TAutofixtureTest }

procedure TAutofixtureTest.AddToArray;
var vArray: TArray<Integer>;
begin
  // Arrange
  // Act
  UUT.AddManyToArray<Integer>(vArray);

  // Assert
  Assert.AreEqual(UUT.Setup.CollectionSize, Length(vArray), 'TArray<Integer> length');
end;

procedure TAutofixtureTest.AddToCollection;
var vCol: TCollection;
begin
  // Arrange
  //UUT.Setup.ConstructorSearch := TConstructorSearch.csNone;
  //vCol := TCollection.Create;

  vCol := UUT.New<TCollection>;
  // Act
  UUT.AddManyTo(vCol);
  // Assert
  Assert.AreEqual(UUT.Setup.CollectionSize * 2, vCol.Count, 'TCollection Size');
end;

procedure TAutofixtureTest.AddToObjectList;
var vList: TObjectList<TTestAbstractClass>;
begin
  // Arrange
  vList := UUT.NewObjectList<TTestAbstractClass>;
  // Act
  UUT.AddManyTo(vList);
  // Assert
  Assert.AreEqual(UUT.Setup.CollectionSize * 2, vList.Count, 'TObjectList Size');
end;

procedure TAutofixtureTest.AddToTList;
var vList: TList<Integer>;
begin
  // Arrange
  vList := UUT.NewList<Integer>;
  // Act
  UUT.AddManyTo(vList);
  // Assert
  Assert.AreEqual(UUT.Setup.CollectionSize * 2, vList.Count, 'TList Size');
end;

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
  s := UUT.New<String>;

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
  str1 := UUT.New<String>('AnythingElse');
  str2 := UUT.New<String>('MyName');

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
  vIObj := UUT.New<ITestInterfaceType>;

  // Assert
  Assert.IsTrue(vIObj is TTestSubClass);
  Assert.AreNotEqual('', TTestSubClass(vIObj).FSubProperty, 'Properties initialized');
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
  vIObj := UUT.New<ITestInterfaceType>;

  // Assert
  Assert.AreEqual(1,1)
end;

procedure TAutofixtureTest.TestObjectConstructor;
var
  vRes: TTestAbstractClass;
begin
  // Act
  vRes := UUT.Build<TTestAbstractClass>.OmitAutoProperties.New;

  // Assert
  Assert.AreEqual('TEST', vRes.FProperty, 'Constructor call');
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
  s := UUT.New<String>('Name');

  // Assert
  Assert.AreNotEqual('', s, 'String generation');
end;

initialization
  TDUnitX.RegisterTestFixture(TAutofixtureTest);

end.
