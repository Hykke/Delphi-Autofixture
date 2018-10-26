unit AutofixtureGeneratorTest;

interface

uses DUnitX.TestFramework, RTTI, AutoFixture, AutoFixtureGenerator;

type
  TMyEnum = (meOption1, meOption2, meOption3);

[TestFixture]
TRandomGeneratorTest = class
private
  UUT: TRandomGenerator;
  ctx: TRTTIContext;
public
    [SetUp]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreation;
    [Test]
    procedure TestGetInteger;
    [Test]
    procedure TestIntegerIsRandom;
    [Test]
    procedure TestGetChar;
    [Test]
    procedure TestGetSmallCapsChar;
    [Test]
    procedure TestGetCapitalChar;
    [Test]
    procedure TestGetNumberAsChar;
    [Test]
    procedure TestGetString;
    [Test]
    procedure TestGetAnsiString;
    [Test]
    procedure TestGetWideString;
    [Test]
    procedure TestGetUTFString;
    [Test]
    procedure TestEnum;
    [Test]
    procedure TestBoolean;
    [Test]
    procedure TestDouble;
    [Test]
    procedure TestByte;
    [Test]
    procedure TestWord;
    [Test]
    procedure TestSmallInt;
    [Test]
    procedure TestLongWord;
    [Test]
    procedure TestCardinal;
    [Test]
    procedure TestLongInt;
    [Test]
    procedure TestInt64;
    [Test]
    procedure TestSingle;
    [Test]
    procedure TestCurrency;
    [Test]
    procedure TestExtended;
    [Test]
    procedure TestVariant;
end;

implementation

uses SysUtils, System.Variants;

{ TRandomGeneratorTest }

procedure TRandomGeneratorTest.Setup;
var vFixture: TAutoFixture;
begin
  vFixture := TAutoFixture.Create;

  UUT := vFixture.New<TRandomGenerator>;
  ctx := TRTTIContext.Create;
end;

procedure TRandomGeneratorTest.TearDown;
begin
  FreeAndNil(UUT);
  ctx.Free;
end;

procedure TRandomGeneratorTest.TestBoolean;
var vValue: TValue;
  vEnum: Boolean;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Boolean)));
  vEnum := vValue.AsType<Boolean>;

  // Assert
  Assert.IsFalse(vValue.IsEmpty, 'Der skal ikke returneres en default Boolean værdi');
  Assert.isTrue(vEnum in [True, False], 'Der kan genereres en Boolean');
end;

procedure TRandomGeneratorTest.TestByte;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Byte)));

  // Assert
  Assert.IsTrue(vValue.AsType<Byte>() > 0, 'Der kan genereres en Byte');
end;

procedure TRandomGeneratorTest.TestCardinal;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Cardinal)));

  // Assert
  Assert.IsTrue(vValue.AsType<Cardinal>() > 0, 'Der kan genereres en Cardinal');
end;


procedure TRandomGeneratorTest.TestCreation;
begin
  Assert.IsTrue(Assigned(UUT));
end;


procedure TRandomGeneratorTest.TestCurrency;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Currency)));
  // Assert
  Assert.IsTrue(vValue.AsType<Currency>() > 0, 'Der kan genereres en Cardinal');
end;

procedure TRandomGeneratorTest.TestDouble;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Double)));
  // Assert
  Assert.IsTrue(vValue.AsType<Double>() > 0, 'Der kan genereres en Double');
end;

procedure TRandomGeneratorTest.TestEnum;
var vValue: TValue;
  vEnum: TMyEnum;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(TMyEnum)));
  vEnum := vValue.AsType<TMyEnum>;
  // Assert
  Assert.IsFalse(vValue.IsEmpty, 'Der skal ikke returneres en default værdi');
  Assert.isTrue(vEnum in [meOption1, meOption2, meOption3], 'Der kan genereres en Enum');
end;

procedure TRandomGeneratorTest.TestExtended;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Extended)));
  // Assert
  Assert.IsTrue(vValue.AsType<Extended>() > 0, 'Der kan genereres en Extended');
end;

procedure TRandomGeneratorTest.TestGetAnsiString;
var vValue: TValue;
  s: AnsiString;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(AnsiString)));
  s := vValue.AsType<AnsiString>;
  // Assert
  Assert.isTrue(Length(s)>0, 'Der kan genereres en AnsiString');
end;

procedure TRandomGeneratorTest.TestGetCapitalChar;
var vValue: TValue;
  i: Integer;
  c: Char;
begin
  // Act

  for i := 1 to 100 do begin
    vValue := UUT.getValue('TJOE', ctx.GetType(TypeInfo(Char)));
    c := vValue.AsType<Char>;
    if Pos(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ') > 0 then begin
      Break;
    end;
  end;
  // Assert
  Assert.isTrue(Pos(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ') > 0, 'De genererede chars kan være et small caps bogstav' );

end;

procedure TRandomGeneratorTest.TestGetChar;
var vValue: TValue;
  c: Char;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Char)));
  c := vValue.AsType<Char>;
  // Assert
  Assert.AreEqual(1, Length(c), 'Der kan genereres en char');
end;

procedure TRandomGeneratorTest.TestGetInteger;
var vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Integer)));
  // Assert
  Assert.IsTrue(vValue.AsInteger > 0, 'Der kan genereres en integer');
end;

procedure TRandomGeneratorTest.TestGetNumberAsChar;
var vValue: TValue;
  i: Integer;
  c: Char;
begin
  // Act

  for i := 1 to 100 do begin
    vValue := UUT.getValue('TJOE', ctx.GetType(TypeInfo(Char)));
    c := vValue.AsType<Char>;
    if Pos(c,'01234567890') > 0 then begin
      Break;
    end;
  end;
  // Assert
  Assert.isTrue(Pos(c,'01234567890') > 0, 'De genererede chars kan være et tal' );
end;

procedure TRandomGeneratorTest.TestGetSmallCapsChar;
var vValue: TValue;
  i: Integer;
  c: Char;
begin
  // Act
  for i := 1 to 100 do begin
    vValue := UUT.getValue('TJOE', ctx.GetType(TypeInfo(Char)));
    c := vValue.AsType<Char>;
    if Pos(c,'abcdefghijklmnopqrstuvwxyz') > 0 then begin
      Break;
    end;
  end;

  // Assert
  Assert.isTrue(Pos(c,'abcdefghijklmnopqrstuvwxyz') > 0, 'De genererede chars kan være et small caps bogstav' );
end;

procedure TRandomGeneratorTest.TestGetString;
var vValue: TValue;
  s: String;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(String)));
  s := vValue.AsType<String>;
  // Assert
  Assert.isTrue(Length(s)>0, 'Der kan genereres en String');
end;

procedure TRandomGeneratorTest.TestGetUTFString;
var vValue: TValue;
  s: Utf8String;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Utf8String)));
  s := vValue.AsType<Utf8String>;
  // Assert
  Assert.isTrue(Length(s)>0, 'Der kan genereres en UTF8String');
end;

procedure TRandomGeneratorTest.TestGetWideString;
var vValue: TValue;
  s: WideString;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(WideString)));
  s := vValue.AsType<WideString>;
  // Assert
  Assert.isTrue(Length(s)>0, 'Der kan genereres en WideString');
end;

procedure TRandomGeneratorTest.TestInt64;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Int64)));
  // Assert
  Assert.IsTrue(vValue.AsType<Int64>() > 0, 'Der kan genereres en Int64');
end;

procedure TRandomGeneratorTest.TestIntegerIsRandom;
var vValue: TValue;
  i,j: Integer;
begin
  // Act
  vValue := UUT.getValue('TJOE', ctx.GetType(TypeInfo(Integer)));
  i := vValue.AsInteger;

  for j := 1 to 100 do begin
    vValue := UUT.getValue('også', ctx.GetType(TypeInfo(Integer)));
    if vValue.AsInteger <> i then begin
      Break;
    end;
  end;
  // Assert
  Assert.AreNotEqual(i, vValue.AsInteger, 'De genererede integers er tilfældige tal' );
end;



procedure TRandomGeneratorTest.TestLongInt;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(LongInt)));

  // Assert
  Assert.IsTrue(vValue.AsType<LongInt>() > 0, 'Der kan genereres en LongInt');
end;

procedure TRandomGeneratorTest.TestLongWord;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(LongWord)));

  // Assert
  Assert.IsTrue(vValue.AsType<LongWord>() > 0, 'Der kan genereres en LongWord');
end;

procedure TRandomGeneratorTest.TestSingle;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Single)));

  // Assert
  Assert.IsTrue(vValue.AsType<Single>() > 0, 'Der kan genereres en Single');
end;

procedure TRandomGeneratorTest.TestSmallInt;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(SmallInt)));

  // Assert
  Assert.IsTrue(vValue.AsType<SmallInt>() > 0, 'Der kan genereres en SmallInt');
end;

procedure TRandomGeneratorTest.TestVariant;
var vValue: TValue;
  vVariant: Variant;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Variant)));
  vVariant := vValue.AsType<Variant>;

  // Assert
  Assert.IsFalse(vValue.IsEmpty, 'Der skal ikke returneres en default værdi');
  Assert.IsFalse(varIsNull(vVariant), 'Der kan genereres en Variant');
end;

procedure TRandomGeneratorTest.TestWord;
var
  vValue: TValue;
begin
  // Act
  vValue := UUT.getValue('TEST', ctx.GetType(TypeInfo(Word)));

  // Assert
  Assert.IsTrue(vValue.AsType<Word>() > 0, 'Der kan genereres en Word');
end;

end.
