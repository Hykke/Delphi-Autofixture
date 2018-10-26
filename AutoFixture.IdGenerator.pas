unit AutoFixture.IdGenerator;

interface

uses
  RTTI,
  AutofixtureGenerator;

type

TIdGenerator = class(TInterfacedObject, IValueGenerator)
private
  FId : Integer;
public
  procedure SetStartValue(AStartId: Integer);
  function getValue(aPropertyName: String; aType: TRttiType): TValue;
end;

implementation

uses SysUtils;

{ TIdGenerator }

function TIdGenerator.getValue(aPropertyName: String; aType: TRttiType): TValue;
var
  vName: String;
begin
  Result := TValue.Empty;
  vName := UpperCase(aPropertyName);

  if (aType.TypeKind = tkInteger) and ((vName = 'ID') or (vName = 'KEY')) then begin
    Result := TValue.From<Integer>(Fid);
    inc(FId);
  end;
end;

procedure TIdGenerator.SetStartValue(AStartId: Integer);
begin
  FId := AStartId;
end;

end.
