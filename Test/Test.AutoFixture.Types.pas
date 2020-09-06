unit Test.AutoFixture.Types;

interface

uses
  RTTI,
  Generics.Collections,
  AutofixtureGenerator;

type

TWeekSet = Set of 1..7;

TDayEnum = (monday, tuesday, wednesday, thursday, friday, saturday, sunday);

TWeekEnumSet = Set of TDayEnum;

ITestInterfaceType = interface
end;

TRecord = record
  FString: String;
  FInt: Integer;
end;

TTestAbstractClass = class(TInterfacedObject, ITestInterfaceType)
public
  FProperty: String;

  constructor Create; virtual;
end;

TTestSubClass = class(TTestAbstractClass, ITestInterfaceType)
public
  FSubProperty: String;
  FInt: Integer;
  FInt64: Int64;
  FDouble: Double;
  FChar: Char;
  FDate: TDateTime;
  FExtended: Extended;
  FWeekdays: TWeekSet;
  FDay: TDayEnum;
  FWeekEnumSet: TWeekEnumSet;

  FBool1, FBool2, FBool3: Boolean;

  FList: TList<Integer>;
  FRecord: TRecord;
end;

TPerson = class
public
  FBirthDay: TDateTime;
  FName: String;
  FSpouse: TPerson;
end;

TListWithSelection<T> = class
public
  FList: TList<T>;
  FSelectedItem: T;
end;

TTestCustomization = class(TInterfacedObject, IValueGenerator)
  function getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
end;

implementation

uses
  SysUtils;
{ TTestAbstractClass }

constructor TTestAbstractClass.Create;
begin
  Self.FProperty := 'TEST';
end;

{ TTestCustomization }

function TTestCustomization.getValue(APropertyName: String; aType: TRttiType; AReferenceDepth: integer): TValue;
begin
  Result := TValue.Empty;
  if Uppercase(APropertyName) = 'ID' then begin
    if AType.TypeKind = TTypeKind.tkInteger then begin
      Result := TValue.From(0);
    end;
  end;
end;

end.
