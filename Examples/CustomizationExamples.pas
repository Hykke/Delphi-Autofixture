unit CustomizationExamples;

// There are many ways to configure how Autofixture generates values
// using the functions Build, Configure or Customize
// This example includes a custom value generator TZeroIdGenerator, that generates the value zero for all fields with name "FID".
// You can see different ways of applying this generator in the following examples:

interface

uses
  RTTI,
  DUnitX.TestFramework,
  ClassesToTest,
  Autofixture,
  AutofixtureGenerator
  ;

type

  [TestFixture]
  TAutoFixtureCustomizations = class(TObject)
  protected
    UUT: TCar;
  public
    [Test]
    procedure UsingBuild;

    [Test]
    procedure UsingConfigure;

    [Test]
    procedure UsingConstructor;

    [Test]
    procedure UsingGenerators;

    [Test]
    procedure UsingCustomize;

    [Test]
    procedure UsingGlobalCustomize;

    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  end;

 // Sample value generator
 // This value generator will generate zero for all integer FId fields
 TZeroIdGenerator = class(TInterfacedObject, IValueGenerator)
   function getValue(APropertyName: String; AType: TRttiType; AReferenceDepth: integer = -1): TValue;
 end;

 // Sample customization
 // This customization will apply the above TZeroIdGenerator, setting Id=0
 // except for TControlPanel, where the Id value will be equal to 1.
 TZeroIdCustomize = class(TInterfacedObject, ICustomization)
   procedure Customize(AAutoFixture: TAutoFixture);
 end;

implementation

uses
  SysUtils,
  Generics.Collections;

{ TAutoFixtureExample2 }


procedure TAutoFixtureCustomizations.Setup;
begin

end;

procedure TAutoFixtureCustomizations.TearDown;
begin

end;



procedure TAutoFixtureCustomizations.UsingBuild;
var
  vFixture: TAutoFixture;
begin
  // Arrange
  vFixture := TAutoFixture.Create;

  // Act
  // Using build it's possible to configure the id property to be zero
  // But this will only affect properties directly on the class being built
  UUT := vFixture.Build<TCar>.WithValue('FId', 0).New;

  // Assert
  Assert.AreEqual(0, UUT.Id, 'Build Id zero');
  Assert.AreNotEqual(0, UUT.Controls.Id, 'Controlpanel id not zero');
end;

procedure TAutoFixtureCustomizations.UsingConfigure;
var
  vFixture: TAutoFixture;
begin
  // Arrange
  vFixture := TAutoFixture.Create;
  // Using configure you can set the value zero for any number of classes you like
  vFixture.Configure<TCar>.WithValue('FId', 0);
  vFixture.Configure<TControlPanel>.WithValue('FId', 0);

  // Act
  UUT := vFixture.new<TCar>;

  // Assert
  Assert.AreEqual(0, UUT.Id, 'Configure Id zero');
  Assert.AreEqual(0, UUT.Controls.Id, 'Configure Controlpanel id zero');
end;

procedure TAutoFixtureCustomizations.UsingGenerators;
var
  vFixture: TAutoFixture;
begin
  // Arrange
  vFixture := TAutoFixture.Create;
  // Instead of configuring the id on each class to be equal to zero it might be easier
  // to create an implementation of IValueGenerator, and have that generate all FId fields
  vFixture.Generators.Add(TZeroIdGenerator.Create);

  // Act
  UUT := vFixture.new<TCar>;

  // Assert
  Assert.AreEqual(0, UUT.Id, 'Generate Id zero');
  Assert.AreEqual(0, UUT.Controls.Id, 'Generate Controlpanel id zero');
  Assert.AreEqual(0, UUT.NumberPlate.Id, 'Generate numberplate');
end;

procedure TAutoFixtureCustomizations.UsingConstructor;
var
  vFixture: TAutoFixture;
begin
  // Arrange

  // Instead of adding the zero generator to the list of generators, you can
  // replace the default Id generator - this is not recommended because the default
  // generator is much more general than the TZeroIdGenerator, however as we can see here
  // it's possible to do if you want:
  vFixture := TAutoFixture.Create(nil, TZeroIdGenerator.Create);

  // Act
  UUT := vFixture.new<TCar>;

  // Assert
  Assert.AreEqual(0, UUT.Id, 'Generate Id zero');
  Assert.AreEqual(0, UUT.Controls.Id, 'Generate Controlpanel id zero');
  Assert.AreEqual(0, UUT.NumberPlate.Id, 'Generate numberplate');
end;

procedure TAutoFixtureCustomizations.UsingCustomize;
var
  vFixture: TAutoFixture;
begin
  // Arrange

  // sometimes a single generator is not enough, in which case an ICustomization object
  // can be created. This object can create any number of customizations for Autofixture
  // and is a great way to bundle many customizations and make them easy to apply
  vFixture := TAutoFixture.Create;
  vFixture.Customize(ICustomization(TZeroIdCustomize.Create));

  // Act
  UUT := vFixture.new<TCar>;

  // Assert
  Assert.AreEqual(0, UUT.Id, 'Customize Id zero');
  Assert.AreEqual(1, UUT.Controls.Id, 'Customize Controlpanel id 1');
  Assert.AreEqual(0, UUT.NumberPlate.Id, 'Customize numberplate');
end;



procedure TAutoFixtureCustomizations.UsingGlobalCustomize;
var
  vFixture1: TAutoFixture;
  vFixture2: TAutoFixture;
begin
  // Arrange

  // A customization can not only bundle together several different customizations
  // it can also be used to alter the default behaviour of Autofixture.
  // For this use the GlobalCustomizations, that will be applied to all instances of
  // TAutofixture created. Beware, only do this if you truly want this behaiviour in
  // every single unit test in the entire project, and then preferably do it inside an
  // initialize function to ensure it is executed prior to the first unit test.
  TAutoFixture.GlobalCustomization := TZeroIdCustomize.Create;
  vFixture1 := TAutoFixture.Create;
  vFixture2 := TAutoFixture.Create;

  // Act 1
  UUT := vFixture1.New<TCar>;

  // Assert
  Assert.AreEqual(0, UUT.Id, '1. Customize Id zero');
  Assert.AreEqual(1, UUT.Controls.Id, '1. Customize Controlpanel id 1');
  Assert.AreEqual(0, UUT.NumberPlate.Id, '1. Customize numberplate');

  // Act 2
  UUT := vFixture2.New<TCar>;

  // Assert
  Assert.AreEqual(0, UUT.Id, '2. Customize Id zero');
  Assert.AreEqual(1, UUT.Controls.Id, '2. Customize Controlpanel id 1');
  Assert.AreEqual(0, UUT.NumberPlate.Id, '2. Customize numberplate');

  // For the purposes of this unit test project it's not a great idea if this global
  // Customization is applied from now on for all instances of Autofixture, so it is
  // removed again
  TAutofixture.GlobalCustomization := nil;
end;

{ TZeroIdGenerator }

function TZeroIdGenerator.getValue(APropertyName: String; AType: TRttiType; AReferenceDepth: integer): TValue;
begin
  Result := TValue.Empty;
  if (UpperCase(APropertyName) = 'FID') and (AType.TypeKind = tkInteger) then begin
    Result := TValue.From<Integer>(0);
  end;
end;

{ TZeroIdCustomize }

procedure TZeroIdCustomize.Customize(AAutoFixture: TAutoFixture);
begin
  AAutoFixture.Generators.Add(TZeroIdGenerator.Create);
  AAutoFixture.Configure<TControlPanel>.WithValue('FId', 1);
end;

initialization
  TDUnitX.RegisterTestFixture(TAutoFixtureCustomizations);
end.

