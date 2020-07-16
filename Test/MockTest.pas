unit MockTest;

interface
uses
  DUnitX.TestFramework, Delphi.Mocks, AutoFixture;

type
  TDaoClass = class
    public function saveObjectToDb(aObject: String): Boolean; virtual;
  end;


  TControllerClass = class
  private
    Fdao: TDaoClass;
    FId: Integer;

  public
    property Id:Integer read Fid write Fid;
    function process(aObject: String): Boolean;

    constructor Create(aDao: TDaoClass); reintroduce;
  end;

  [TestFixture]
  TMockTest = class(TObject)
  private
    UUT: TControllerClass;
    //FMockDao: TMock<TDaoClass>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure Test1;
    // Test with TestCase Attribute to supply parameters.
    [Test]
    [TestCase('TestA','1,2')]
    [TestCase('TestB','3,4')]
    procedure Test2(const AValue1 : Integer;const AValue2 : Integer);
  end;

implementation

procedure TMockTest.Setup;
//var vUUTMock: TMock<TControllerClass>;
var vFixture: TAutoFixture;
begin
  vFixture := TAutoFixture.Create;

  // FMockDao := TMock<TDaoClass>.Create;
//  FMockDao.Setup.WillReturn(True).When.saveObjectToDb('TEST');
//  vFixture.Inject(FMockDao.Instance);

  vFixture.DMock<TDaoClass>.Setup.WillReturn(True).When.saveObjectToDb('TEST');

  UUT := vFixture.New<TControllerClass>;
  //vUUTMock := TMock<TControllerClass>.Create;
  //UUT := vUUTMock;
end;

procedure TMockTest.TearDown;
begin
end;

procedure TMockTest.Test1;
begin
  Assert.IsTrue(Assigned(UUT), 'Fdao was not created');
end;

procedure TMockTest.Test2(const AValue1 : Integer;const AValue2 : Integer);
var vResult: Boolean;
begin
  // Act
  vResult := UUT.process('TEST');
  // Assert
  Assert.IsTrue(vResult, 'Process not returning success (true)');
end;

{ TControllerClass }

constructor TControllerClass.Create(aDao: TDaoClass);
begin
  inherited Create;
  FDao := aDao;
end;

function TControllerClass.process(aObject: String): Boolean;
begin
  Result := FDao.saveObjectToDb(aObject);
end;

{ TDaoClass }

function TDaoClass.saveObjectToDb(aObject: String): Boolean;
begin
  Result := (aObject = '');
end;

initialization
  TDUnitX.RegisterTestFixture(TMockTest);
end.
