unit AutofixtureExample2;

// This example is more realistic, the function IsPreassureOK on TCar needs to be tested.
// This function provides a challenge for AutoFixture, since it requires that there be exactly 4 wheels,
// and the preassure of each wheel must be within range or else the entire test fails.
// However this test also demonstrates how the use of autofixture means you can forget about
// classes and data that are irrellevant for your test, such as the number plates or the seats.

interface

uses
  DUnitX.TestFramework,
  ClassesToTest;

type

  [TestFixture]
  TAutoFixtureExample2 = class(TObject)
  protected
    UUT: TCar;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('AllGood', '1,100,True')]
    [TestCase('NoPreassure', '3,0,False')]
    procedure NoAutofixture(ATyreNumber: Integer; AOneWheelPreassure: Integer; AExpectedResult: Boolean);

    [Test]
    [TestCase('AllGood', '1,100,True')]
    [TestCase('NoPreassure', '3,0,False')]
    ///<summary>Same testcase as above, this time autofixture is used to generate classes</summary>
    procedure WithAutofixture(ATyreNumber: Integer; AOneWheelPreassure: Integer; AExpectedResult: Boolean);


    [Test]
    [TestCase('AllGood', '1,100,True')]
    [TestCase('NoPreassure', '3,0,False')]
    ///<summary>With Configure, changes in properties for a single class can be achieved</summary>
    procedure WithConfigure(ATyreNumber: Integer; AOneWheelPreassure: Integer; AExpectedResult: Boolean);

    [Test]
    [TestCase('AllGood', '1,100,True')]
    [TestCase('NoPreassure', '3,0,False')]
    ///<summary>Using anonymous functions to select properties, ensures type checking and availability checking of the property at compile time</summary>
    procedure WithConfigureAndCompileTimeTypeCheck(ATyreNumber, AOneWheelPreassure: Integer; AExpectedResult: Boolean);
  end;
implementation

uses
  SysUtils,
  AutoFixture,
  Generics.Collections;

{ TAutoFixtureExample2 }

procedure TAutoFixtureExample2.NoAutofixture(ATyreNumber:Integer; AOneWheelPreassure: Integer; AExpectedResult: Boolean);
var
  vSteeringWheel: TSteeringWheel;
  vControlPanel: TControlPanel;
  vNumberPlate: TNumberPlate;
  vWheel: TWheel;
  i: Integer;
  vResult: Boolean;
begin
  // Arrange
  vSteeringWheel := TSteeringWheel.Create;
  vControlPanel := TControlPanel.Create(vSteeringWheel);
  vControlPanel.IsIgnitionOn := True; // This is the only value in TControlPanel / TSteeringWheel that is actually needed

  // The numberplate is not really needed for this test, but the TCar class refuses to go anywhere without it...
  vNumberPlate := TNumberPlate.Create('Some numberplate value ... test will work no matter what you put here, except empty string!');

  UUT := TCar.Create(vControlPanel, vNumberPlate);

  for i := 1 to 4 do begin // Create 4 wheels for the car
    vWheel := TWheel.Create;
    if i = ATyreNumber then begin
      vWheel.TyrePreassure := AOneWheelPreassure;
    end
    else begin
      vWheel.TyrePreassure := 100; // normal tyre preassure
    end;
    UUT.AddWheelInfo(vWheel);
  end;

  // Act
  vResult := UUT.IsTyrePreassureOK;

  // Assert
  Assert.AreEqual(vResult, AExpectedResult);
  // 6 variable declarations used
  // 17 lines of code between begin-end, not counting comments
  // 23 lines of code in total, not counting comments
end;

procedure TAutoFixtureExample2.WithAutofixture(ATyreNumber, AOneWheelPreassure: Integer; AExpectedResult: Boolean);
var
  vFixture: TAutoFixture;
  vWheels: TObjectList<TWheel>;
  vResult: Boolean;
begin
  vFixture := TAutoFixture.Create;
  try
    vFixture.Setup.CollectionSize := 4; // Ensure we get 4 wheels
    vFixture.Inject<Integer>(100); // All integers will contain 100 (Default tyre preassure)
    vFixture.Inject<Boolean>(True); // All booleans will be equal to True! (Ignition must be on)
    vWheels := vFixture.New<TObjectList<TWheel>>; // Initialize the entire array in one statement!
    vWheels[ATyreNumber-1].TyrePreassure := AOneWheelPreassure;
    vFixture.Inject(vWheels); // The array is injected, and will be used when initializing TCar.

    UUT := vFixture.New<TCar>;

    // Act
    vResult := UUT.IsTyrePreassureOK;

    // Assert
    Assert.AreEqual(vResult, AExpectedResult);
  finally
    FreeAndNil(vFixture)
  end;
  // 3 variables used
  // 14 lines of code, however 5 of these lines are overhead from creating and Freeing Autofixture
  // Lines are saved because autofixture creates the TControlPanel and TSteeringWheel classes
  // Also no for-loop and loop variable necessary
  // 17 lines of code in total, not counting comments, 6 lines less than without Autofixture
end;

procedure TAutoFixtureExample2.WithConfigure(ATyreNumber, AOneWheelPreassure: Integer; AExpectedResult: Boolean);
var
  vFixture: TAutoFixture;
  vWheels: TObjectList<TWheel>;
  vResult: Boolean;
begin
  vFixture := TAutoFixture.Create;
  try
    vFixture.Setup.CollectionSize := 4; // Ensure we get 4 wheels
    vFixture.Configure<TWheel>.WithValue('FTyrePreassure', 100); // Only this property in the TWheel class gets 100 as value
    vFixture.Configure<TControlPanel>.WithValue('FIgnition', True); // Ignition must be on
    vWheels := vFixture.New<TObjectList<TWheel>>; // Initialize the entire array in one statement!
    vWheels[ATyreNumber - 1].TyrePreassure := AOneWheelPreassure;
    vFixture.Inject(vWheels); // The array is injected, and will be used when initializing TCar.

    UUT := vFixture.New<TCar>;

    // Act
    vResult := UUT.IsTyrePreassureOK;

    // Assert
    Assert.AreEqual(vResult, AExpectedResult);
  finally
    FreeAndNil(vFixture)
  end;
  // 3 variables used
  // 14 lines of code, same as previous example, except this time only relevant properties are assigned values,
  // not all integers and booleans affected
  // 17 lines of code in total, not counting comments
end;

procedure TAutoFixtureExample2.WithConfigureAndCompileTimeTypeCheck(ATyreNumber, AOneWheelPreassure: Integer; AExpectedResult: Boolean);
var
  vFixture: TAutoFixture;
  vWheels: TObjectList<TWheel>;
  vResult: Boolean;
begin
  vFixture := TAutoFixture.Create;
  try
    vFixture.Setup.CollectionSize := 4; // Ensure we get 4 wheels
    vFixture.Configure<TWheel>.WithValue<Integer>(function(AWheel: TWheel):Integer begin
      Result := AWheel.TyrePreassure;
    end, 100); // This time the TyrePreassure is identified by anonymous function rather than by string
    vFixture.Configure<TControlPanel>.WithValue<Boolean>(function(AControlPanel: TControlPanel): Boolean begin
      Result := AControlPanel.IsIgnitionOn;
    end, True); // Using anonymous functions ensures compile time failures if property changed
    vWheels := vFixture.New<TObjectList<TWheel>>; // Initialize the entire array in one statement!
    vWheels[ATyreNumber - 1].TyrePreassure := AOneWheelPreassure;
    vFixture.Inject(vWheels); // The array is injected, and will be used when initializing TCar.

    UUT := vFixture.New<TCar>;

    // Act
    vResult := UUT.IsTyrePreassureOK;

    // Assert
    Assert.AreEqual(vResult, AExpectedResult);
  finally
    FreeAndNil(vFixture)
  end;
  // This time a few more lines of code are sacrificed in order to get compile time checking of properties and types.
  // 3 variables used
  // 18 lines of code
  // 21 lines of code in total, not counting comments
  // It's up to you to decide if the extra lines of code and cumbersome anonymous functions syntax
  // are worth it
end;

procedure TAutoFixtureExample2.Setup;
begin

end;

procedure TAutoFixtureExample2.TearDown;
begin

end;



initialization
  TDUnitX.RegisterTestFixture(TAutoFixtureExample2);
end.

