unit AutofixtureGenerator;

interface

uses RTTI;

type
IValueGenerator = interface
  function getValue(aPropertyName: String; aType: TRttiType): TValue;
end;

TInjectDelegate<T> = reference to function(): T;
TInjectNameDelegate<T> = reference to function(aPropertyName: String): T;

TValueGenerator<T> = class(TInterfacedObject, IValueGenerator)
  FTypeInfo: TRttiType;
  FPropertyName: String;
  FDelegate: TInjectDelegate<T>;
  FNameDelegate: TInjectNameDelegate<T>;
public
  constructor Create(); virtual;
  procedure Register(aPropertyName: String; aDelegate: TInjectDelegate<T>); overload;
  procedure Register(aDelegate: TInjectNameDelegate<T>); overload;
  function canGenerate(aPropertyName: String): Boolean;
  function getValue(aPropertyName: String; aType:TRttiType): TValue;
end;

TRandomGenerator = class(TinterfacedObject, IValueGenerator)
  function getValue(aPropertyName: String; aType: TRttiType): TValue;
end;

implementation

uses SysUtils, Dateutils;

{ TValueGenerator }

function TValueGenerator<T>.canGenerate(aPropertyName: String): Boolean;
begin
  if typeInfo(T) = FTypeInfo then begin
    Result := True;
  end
  else begin
    Result := False;
  end;
end;

constructor TValueGenerator<T>.Create;
var ctx: TRttiContext;
begin
  ctx := TRttiContext.Create;
  FTypeInfo := ctx.GetType(TypeInfo(T));
end;

function TValueGenerator<T>.getValue(aPropertyName: String; aType:TRttiType): TValue;
var vGetByName: TInjectNameDelegate<T>;
  vSimpleGet: TInjectDelegate<T>;
  vType: TRttiType;
begin
  //vType := typeInfo(T);
  if FTypeInfo = aType  then begin
    if FPropertyName = 'A' + aPropertyName then begin
      //vSimpleGet := TInjectDelegate<T>(FDelegate);
      Result := TValue.From<T>(FDelegate());
    end
    else if FPropertyName = '' then begin
      //vGetByName := TInjectDelegate<T>(FDelegate);
      Result := TValue.From<T>(FNameDelegate(aPropertyName));
    end
    else begin
      Result := TValue.Empty;
    end;
  end
  else begin
    Result := nil;
  end;
end;

procedure TValueGenerator<T>.Register(aPropertyName: String; aDelegate: TInjectDelegate<T>);
begin
  FPropertyName := 'A' + aPropertyName;
  FDelegate := aDelegate;
end;

procedure TValueGenerator<T>.Register(aDelegate: TInjectNameDelegate<T>);
begin
  FPropertyName := '';
  FNameDelegate := aDelegate;
end;

{ TRandomGenerator }

function TRandomGenerator.getValue(aPropertyName: String; aType: TRttiType): TValue;
var i: Integer;
  vGuid: TGuid;
begin
  Result := TValue.Empty;

  case aType.TypeKind of
  tkInteger: begin
    Result := TValue.From<Integer>(1+Random(255));
  end;
  tkInt64: begin
    Result := TValue.From<Int64>(1+Random(255));
  end;
  tkChar, TkWChar: begin
    i := Random(100);
    if i<40 then begin
      Result := TValue.From(Chr(ord('a') + Random(26)));
    end
    else if i<80 then begin
      Result := TValue.From(Chr(ord('A') + Random(26)));
    end
    else begin
      Result := TValue.From(Chr(ord('0') + Random(10)));
    end;
  end;
  tkWString, tkUString, tkLString: begin
    CreateGuid(vGuid);
    Result := TValue.From(aPropertyName + ' ' + GuidToString(vGuid))
  end;
  tkEnumeration: begin
    Result := TValue.FromOrdinal(aType.Handle, aType.AsOrdinal.MinValue + Random(aType.AsOrdinal.MaxValue + 1 - aType.AsOrdinal.MinValue));
  end;
  tkFloat: Begin
    Result := TValue.From(0.1 + Random(300));
  End;
  tkVariant: Begin
    i := Random(100); // Assign variants as integer, string or date
    if i<34 then begin
      Result := TValue.FromVariant(1+Random(300))
    end
    else if i<67 then begin
      CreateGuid(vGuid);
      Result := TValue.FromVariant(aPropertyName + ' ' + GuidToString(vGuid));
    end
    else begin
      Result := TValue.FromVariant(IncDay(Now, -Random(300)));
    end;
  End;
  tkSet: begin
    // Not really possible to generate a random set, just leave blank
  end;
{


tkSet

Set types

tkClass

Class types

tkMethod

Procedure and function method types

tkLString

Delphi 2+ long strings (made of AnsiChars)

tkLWString

Delphi 2 constant added in preparation of long wide strings for Unicode, which were planned for Delphi 3

tkWString

The Delphi 3 constant which replaces tkLWString

tkVariant

Variant type, new in Delphi 2

tkArray

Array types, new in Delphi 3

tkRecord

Record types, new in Delphi 3

tkInterface

Interface types, new in Delphi 3

tkDynArray
 }



  end;

end;

end.
