unit AutoFixture.IdGenerator;

interface

uses
  RTTI,
  Generics.Collections,
  AutofixtureGenerator;

type

TIdGenerator = class(TInterfacedObject, IValueGenerator)
private
  FId : Integer;
public
  procedure SetStartValue(AStartId: Integer);
  function getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
  constructor Create;
end;

TidGeneratorAnyType = class(TInterfacedObject, IValueGenerator)
private
  FIdDict: TDictionary<TRttiType, Integer>;
public
  function getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
  constructor Create;
end;

implementation

uses SysUtils;

{ TIdGenerator }

constructor TIdGenerator.Create;
begin
  FId := 1;
end;

function TIdGenerator.getValue(APropertyName: String; AType: TRttiType; AReferenceDepth: integer = -1): TValue;
var
  vName: String;
begin
  Result := TValue.Empty;
  vName := UpperCase(aPropertyName);

  if Assigned(AType) and (AType.TypeKind = tkInteger) and (vName.EndsWith('ID') or (vName = 'KEY')) then begin
    Result := TValue.From<Integer>(Fid);
    inc(FId);
  end;
end;

procedure TIdGenerator.SetStartValue(AStartId: Integer);
begin
  FId := AStartId;
end;

{ TidGeneratorAnyType }

constructor TidGeneratorAnyType.Create;
begin
  FIdDict := TDictionary<TRttiType, Integer>.Create;
end;

function TidGeneratorAnyType.getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
var
  vId: Integer;
begin
  Result := TValue.Empty;
  if not FIdDict.TryGetValue(aType, vId) then begin
    vId := 0;
    FIdDict.Add(aType, vID);
  end;

  case aType.TypeKind of
    tkInteger: begin
      Result := TValue.From<Integer>(vId);
    end;
    tkInt64: begin
      Result := TValue.From<Int64>(vId);
    end;
    tkChar: begin
      Result := TValue.From<Char>(Chr(vId));
    end;
    tkWChar: begin
      Result := TValue.From<WideChar>(Chr(vID));
    end;
    tkWString, tkUString, tkLString: begin
      Result := TValue.From(IntToStr(vId));
    end;
    tkEnumeration: begin
      Result := TValue.FromOrdinal(aType.Handle, aType.AsOrdinal.MinValue + vId);
    end;
    tkFloat: Begin
      Result := TValue.From(0.1 + vId);
    End;
    tkVariant: Begin
      Result := TValue.From(vId);
    End;
    tkSet: begin
      // RTTI can't work with sets - ignore
    end;
    tkClass: begin
      Result := TValue.From(aType.TypeKind);
    end;
    tkInterface: begin

    end;
    tkArray: begin

    end;
    tkRecord: begin

    end;
    tkDynArray: begin

    end;
    tkPointer: begin

    end;
  end;

  FIdDict[AType] := vId + 1;
end;

end.
