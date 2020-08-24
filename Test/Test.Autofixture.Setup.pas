unit Test.Autofixture.Setup;

interface
uses AutoFixture,
  DUnitX.TestFramework,
  Generics.Collections,
  Test.AutoFixture.Types,
  System.Classes;

type

[TestFixture]
TAutofixtureSetupTest = class
private
  UUT: TAutoFixture;
public
    [SetUp]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('Hierarchy depth 0', '0')]
    [TestCase('Hierarchy depth 1', '1')]
    [TestCase('Hierarchy depth 2', '2')]
    [TestCase('Hierarchy depth 3', '3')]
    [TestCase('Hierarchy depth 4', '4')]
    procedure TestReferenceDepth(ADepth: Integer);

    [Test]
    [TestCase('Hierarchy depth 0', '0')]
    [TestCase('Hierarchy depth 1', '1')]
    [TestCase('Hierarchy depth 2', '2')]
    [TestCase('Hierarchy depth 3', '3')]
    [TestCase('Hierarchy depth 4', '4')]
    procedure TestReferenceDepthForCollection(ADepth: Integer);
end;

TTestReferenceDepth = class;

TTestReferenceDepth = class(TCollectionItem)
public
  FParent: TTestReferenceDepth;
  FList: TList<TTestReferenceDepth>;
  FCollection: TCollection;
end;

// Setup class reference for binding
TCollectionItemClass = class of TCollectionItem;
TTestReferenceDepthClass = class of TTestReferenceDepth;

implementation

uses SysUtils,
  AutofixtureSetup;

procedure TAutofixtureSetupTest.Setup;
begin
  UUT := TAutoFixture.Create;
end;

procedure TAutofixtureSetupTest.TearDown;
begin
  FreeAndNil(UUT);
end;

procedure TAutofixtureSetupTest.TestReferenceDepth(ADepth: Integer);
var
  vTestDepth, vIterator: TTestReferenceDepth;
  vDepth: Integer;
begin
  // Arrange
  UUT.Setup.ReferenceDepth := ADepth;
  // Because TTestReferenceDepth inherits from collectionItem, there are properties that should not be set
  UUT.Configure<TTestReferenceDepth>.Omit<Integer>('Index'); // Don't try to set a value for index
  UUT.Configure<TTestReferenceDepth>.Omit<TCollection>('Collection'); // Don't try to set a value for Collection
  // Act
  vTestDepth := UUT.New<TTestReferenceDepth>;
  // Assert
    // Find parent depth
    vIterator := vTestDepth;
    vDepth := 0;
    while Assigned(vIterator) do begin
      inc(vDepth, 1);
      vIterator := vIterator.FParent;
    end;
    Assert.AreEqual(ADepth, vDepth, 'Parent depth');

    // Find list depth
    vIterator := vTestDepth;
    vDepth := 0;
    while Assigned(vIterator) do begin
      inc(vDepth, 1);
      if Assigned(vIterator.FList) and (vIterator.FList.Count > 0) then begin
        vIterator := vIterator.FList[0];
      end
      else begin
        vIterator := nil;
      end;
    end;
    Assert.AreEqual(ADepth, vDepth, 'List depth');
end;

procedure TAutofixtureSetupTest.TestReferenceDepthForCollection(ADepth: Integer);
var
  vTestDepth, vIterator: TTestReferenceDepth;
  vDepth: Integer;
begin
  // Arrange
  UUT.Setup.ReferenceDepth := ADepth;
  UUT.RegisterType<TCollectionItemClass, TTestReferenceDepthClass>; // This initializes the TCollection to contain TTestReferenceDepth instances
  // Because TTestReferenceDepth inherits from collectionItem, there are properties that should not be set
  UUT.Configure<TTestReferenceDepth>.Omit<Integer>('Index'); // Don't try to set a value for index
  UUT.Configure<TTestReferenceDepth>.Omit<TCollection>('Collection'); // Don't try to set a value for Collection
  // Act
  vTestDepth := UUT.New<TTestReferenceDepth>;
  // Assert

  // Find Collection depth
  vIterator := vTestDepth;
  vDepth := 0;
  while Assigned(vIterator) do begin
    inc(vDepth, 1);
    if Assigned(vIterator.FCollection) and (vIterator.FCollection.Count > 0) then begin
      vIterator := vIterator.FCollection.Items[0] as TTestReferenceDepth;
    end
    else begin
      vIterator := nil;
    end;
  end;
  Assert.AreEqual(ADepth, vDepth, 'List depth');
end;

end.
