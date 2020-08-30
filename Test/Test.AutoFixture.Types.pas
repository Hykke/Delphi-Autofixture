unit Test.AutoFixture.Types;

interface

uses
  Generics.Collections;

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
//  FBirthDay: TDateTime;
//  FName: String;
  FSpouse: TPerson;
end;

TListWithSelection<T> = class
public
  FList: TList<T>;
  FSelectedItem: T;
end;

implementation

{ TTestAbstractClass }

constructor TTestAbstractClass.Create;
begin
  Self.FProperty := 'TEST';
end;

end.
