unit AutoFixture;

interface

uses RTTI, Generics.Collections,
  AutofixtureGenerator,
  Delphi.Mocks,
  EncapsulatedRecord;

type

TConstructorSearch = (csNone, csSimplest, csMostParams);

TAutofixtureSetup = class
  private
    FConstructorSearch: TConstructorSearch;
    FReferenceDepth: Integer;
    FCollectionSize: Integer;
    FAutoDetectList: Boolean;
    FAutoDetectDictionary: Boolean;
  public
    property ConstructorSearch: TConstructorSearch read FConstructorSearch write FConstructorSearch;
    property ReferenceDepth: Integer read FReferenceDepth write FReferenceDepth;
    property CollectionSize: Integer read FCollectionSize write FCollectionSize;
    property AutoDetectList: Boolean read FAutodetectList write FAutoDetectList;
    property AutoDetectDictionary: Boolean read FAutoDetectDictionary write FAutoDetectDictionary;

    constructor Create;
end;

TTypeList = class
  private
    FTypeList: TObjectList<TRttiType>;

    function GetRandomType: TRttiType;
  public
    constructor Create(AType: TRttiType);
    function Orto<T>: TTypeList;
end;

TAutoFixture = class(TInterfacedObject, IValueGenerator)
private
  FGenerators: TList<IValueGenerator>;
  FMocks: TDictionary<System.Pointer, IEncapsulatedRecordType>;
  FSetup: TAutofixtureSetup;
  FBindtypeDict: TDictionary<TRttiType, TTypeList>;
public
  constructor Create;
  destructor Destroy; override;
  function New<T: Class>: T; overload;
  function New<T: Class>(AReferenceDepth: Integer): T; overload;
  function NewInterface<T: IInterface>: T; overload;
  function NewInterface<T: IInterface>(AReferenceDepth: Integer): T; overload;
  function getValue(aPropertyName: String; aType: TRttiType): TValue;
  procedure Inject<T>(aValue: T); overload;
  procedure Inject<T>(aDelegate: TInjectNameDelegate<T>); overload;
  procedure Inject<T>(aPropertyName: String; aDelegate: TInjectDelegate<T>); overload;
  procedure Inject<T>(aPropertyName: String; aValue: T); overload;
  function Mock<T>(): TMock<T>;

  function getObject(AType: TRttiType): TObject; overload;
  function getObject(AType: TRttiType; AReferenceDepth: Integer): TObject; Overload;
  procedure CallMethod(AOnObject: TObject; vMethod: TRttiMethod);
  function RegisterType<T, TBind>: TTypeList;
  function ResolveType(ARttiType: TRttiType): TRttiType;

  property Setup: TAutoFixtureSetup read FSetup;
end;

implementation

uses SysUtils,
  AutoFixture.IdGenerator;

{ TAutoFixture }
constructor TAutoFixture.Create;
begin
  FGenerators := TList<IValueGenerator>.Create;
  FGenerators.Add(TRandomGenerator.Create);
  FGenerators.Add(TIdGenerator.Create);
  Fsetup := TAutoFixtureSetup.Create;
  FMocks := TDictionary<System.Pointer, IEncapsulatedRecordType>.Create;
  FBindtypeDict := TDictionary<TRttiType, TTypeList>.Create;
end;

procedure TAutoFixture.Inject<T>(aDelegate: TInjectNameDelegate<T>);
var
  vGenerator: TValueGenerator<T>;
begin
  vGenerator := TValueGenerator<T>.Create;
  vGenerator.Register(aDelegate);
  FGenerators.Add(vGenerator);
end;

procedure TAutoFixture.Inject<T>(aValue: T);
var
  vGenerator: TValueGenerator<T>;
begin
  vGenerator := TValueGenerator<T>.Create;
  vGenerator.Register(function(x: String): T
                      begin
                        Result := aValue;
                      end);
  FGenerators.Add(vGenerator);
end;

procedure TAutoFixture.Inject<T>(aPropertyName: String; aDelegate: TInjectDelegate<T>);
var
  vGenerator: TValueGenerator<T>;
begin
  vGenerator := TValueGenerator<T>.Create;
  vGenerator.Register(aPropertyName, aDelegate);
  FGenerators.Add(vGenerator);
end;

function TAutoFixture.New<T>: T;
begin
  Result := Self.New<T>(Setup.ReferenceDepth);
end;

destructor TAutoFixture.Destroy;
begin
  FreeAndNil(FSetup);
  FreeAndNil(FGenerators);
  FreeAndNil(FMocks);
  FreeAndNil(FBindtypeDict);

  inherited;
end;

function TAutoFixture.getObject(AType: TRttiType): TObject;
begin
  Result := Self.getObject(AType, Setup.FReferenceDepth);
end;

function TAutoFixture.getObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
var
  vMethod, vConstructor, vAddMethod: TRttiMethod;
  vParameterList: TArray<TRttiParameter>;
  vProperty: TRttiProperty;
  vField: TRttiField;
  vValue: TValue;
  i: Integer;
  vCollectionDetected: Boolean;
begin
  AType := ResolveType(AType);
  Result := AType.AsInstance.MetaclassType.Create;
  vAddMethod := nil;

  // Find constructor method
  vConstructor := nil;

  if FSetup.ConstructorSearch = TConstructorSearch.csSimplest then begin
    // Find simplest constructor deklareret i klassen
    for vMethod in AType.GetDeclaredMethods do begin
      if vMethod.IsConstructor then begin
        if Assigned(vConstructor) then begin
          // Find simplest constructor
          if Length(vMethod.GetParameters()) < Length(vConstructor.GetParameters()) then begin
            vConstructor := vMethod;
          end;
        end
        else begin
          vConstructor := vMethod;
        end;
      end
      else if vMethod.Name = 'Add' then begin
        vAddMethod := vMethod;
      end;
    end;
  end
  else if FSetup.ConstructorSearch = TConstructorSearch.csMostParams then begin
    // Find constructor with many params
    for vMethod in AType.GetDeclaredMethods do begin
      if vMethod.IsConstructor then begin
        if Assigned(vConstructor) then begin
          if Length(vMethod.GetParameters()) > Length(vConstructor.GetParameters()) then begin
            vConstructor := vMethod;
          end;
        end
        else begin
          vConstructor := vMethod;
        end;
      end;
    end;
  end;

  if vConstructor <> nil then begin
    CallMethod(Result, vConstructor);
  end;

  vCollectionDetected := False;
  if Assigned(vAddMethod) then begin
    vParameterList := vAddMethod.GetParameters;

    if Setup.AutoDetectList then begin
      if Length(vParameterList) = 1 then begin
        vCollectionDetected := True;

        for i := 1 to Setup.FCollectionSize do begin
          CallMethod(Result, vAddMethod);
        end;
      end;
    end
    else begin
      if Setup.AutoDetectDictionary then begin
        if Length(vParameterList) = 2 then begin
          vCollectionDetected := True;

          for i := 1 to Setup.FCollectionSize do begin
            CallMethod(Result, vAddMethod);
          end;
        end;
      end;
    end;
  end;

  if not vCollectionDetected then begin
    // Loop through and set fields
    for vField in AType.GetFields do begin
      if vField.Name <> 'FRefCount' then begin
        // Try to set value
        vValue := getValue(vField.Name, vField.FieldType);

        if not vValue.IsEmpty then begin
          vField.SetValue(Pointer(Result), vValue);
        end
        else begin
          if vField.FieldType.TypeKind = tkClass then begin
            if AReferenceDepth > 1 then begin
              vValue := TValue.From(getObject(vField.FieldType, AReferenceDepth - 1));
              vField.SetValue(Pointer(Result), vValue);
            end;
          end;
        end;
      end;
    end;

    // Loop through and set properties
    for vProperty in AType.GetProperties do begin
      if vProperty.IsWritable then begin
        // Try to set property value
        vValue := getValue(vProperty.Name, vProperty.PropertyType);

        if not vValue.IsEmpty then begin
          vProperty.SetValue(Pointer(Result), vValue);
        end
        else begin
          if vProperty.PropertyType.TypeKind = tkClass then begin
            if AReferenceDepth > 1 then begin
              vValue := TValue.From(getObject(vProperty.PropertyType, AReferenceDepth - 1));
              vProperty.SetValue(Pointer(Result), vValue);
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TAutoFixture.CallMethod(AOnObject: TObject; vMethod: TRttiMethod);
var
  vValueList: System.Generics.Collections.TList<TValue>;
  vParam: TRttiParameter;
  vValue: TValue;
begin
  // Call constructor
  vValueList := TList<TValue>.Create;
  try
    for vParam in vMethod.GetParameters do
    begin
      vValue := getValue(vParam.Name, vParam.ParamType);
      vValueList.Add(vValue);
    end;
    vMethod.Invoke(AOnObject, vValueList.ToArray);
  finally
    FreeAndNil(vValueList);
  end;
end;


function TAutoFixture.getValue(aPropertyName: String; aType: TRttiType): TValue;
var vGenerator: IValueGenerator;
  vValue: TValue;
  vMaxTypeResDepth: Integer;
begin
  Result := TValue.Empty;
  // Resolve type binding
  AType := ResolveType(AType);

  for vGenerator in FGenerators do begin
    vValue := vGenerator.getValue(aPropertyName, aType);

    if not vValue.IsEmpty then begin
      Result := vValue;
    end;
  end;
end;

procedure TAutoFixture.Inject<T>(aPropertyName: String; aValue: T);
var vGenerator: TValueGenerator<T>;
begin
  vGenerator := TValueGenerator<T>.Create;
  vGenerator.Register(aPropertyName, function(): T
                                     begin
                                       Result := aValue;
                                     end);

  FGenerators.Add(vGenerator);
end;

function TAutoFixture.Mock<T>: TMock<T>;
begin
  if not FMocks.ContainsKey(Typeinfo(T)) then begin
    Result := TMock<T>.Create;
    FMocks.Add(TypeInfo(T), TRecordEncapsulation<TMock<T>>.Create(Result));
    Self.Inject<T>(Result.Instance);
  end
  else begin
    Result := TRecordEncapsulation<TMock<T>>(FMocks[TypeInfo(T)]).Contents;
  end;
end;

function TAutoFixture.New<T>(AReferenceDepth: Integer): T;
var ctx: TRttiContext;
  vType: TRttiType;
  vValue: TValue;
  vObj: TObject;
begin
  ctx := TRttiContext.Create;
  vValue := getValue('', ctx.getType(TypeInfo(T)));

  if vValue.IsEmpty then begin
    vType := ctx.GetType(TypeInfo(T));

    if vType.TypeKind = tkClass then begin
      Result := T(getObject(vType));
    end
    else begin
      Result := Default(T);
    end;
  end
  else begin
    Result := vValue.AsType<T>;
  end;

  ctx.Free;
end;

function TAutoFixture.NewInterface<T>: T;
begin
  Result := NewInterface<T>(Setup.ReferenceDepth);
end;

function TAutoFixture.NewInterface<T>(AReferenceDepth: Integer): T;
var ctx: TRttiContext;
  vType: TRttiType;
  vValue: TValue;
  vObj: TObject;
  vObjCast: TInterfacedObject;
  vIObj: IInterface;
  vClassName: String;
begin
  Result := nil;
  ctx := TRttiContext.Create;
  vValue := getValue('', ctx.getType(TypeInfo(T)));

  if vValue.IsEmpty then begin
    vType := ctx.GetType(TypeInfo(T));

    if vType.TypeKind = tkInterface then begin
      vObj := getObject(vType);
      vClassName := vObj.ClassName;

      vObjCast := vObj as TInterfacedObject;
      vIObj := IInterface(vObjCast);
      Result := T(vIObj);


      if (vObj is TInterfacedObject) and (vClassName<>'') then begin
        vObjCast := TInterfacedObject(vObj);
        vIObj := IInterface(vObjCast);
        Result := T(vIObj);
      end;
    end
    else begin
      Result := Default(T);
    end;
  end
  else begin
    Result := vValue.AsType<T>;
  end;

  ctx.Free;
end;

function TAutoFixture.RegisterType<T, TBind>: TTypeList;
var ctx: TRttiContext;
  vType, vBindType: TRttiType;
  vValue: TValue;
begin
  ctx := TRttiContext.Create;
  vType := ctx.getType(TypeInfo(T));
  vBindType := ctx.getType(TypeInfo(TBind));

  if FBindtypeDict.ContainsKey(vType) then begin
    FBindtypeDict[vType].Free;
    FBindTypeDict[vType] := TTypeList.Create(vBindType);
  end
  else begin
    FBindtypeDict.Add(vType, TTypeList.Create(vBindType));
  end;
end;

function TAutoFixture.ResolveType(ARttiType: TRttiType): TRttiType;
var
  vMaxTypeResDepth: Integer;
begin
  Result := ARttiType;
  // Resolve type binding
  vMaxTypeResDepth := 10;
  while FBindtypeDict.ContainsKey(Result) do begin
    Result := FBindtypeDict[Result].GetRandomType;
    dec(vMaxTypeResDepth);
    if vMaxTypeResDepth < 1 then begin
      Break;
    end;
  end;
end;

{ TAutofixtureSetup }
constructor TAutofixtureSetup.Create;
begin
  Self.FReferenceDepth := 3;
  Self.FCollectionSize := 3;
  Self.FAutoDetectList := True;
  Self.FAutoDetectDictionary := True;
  Self.FConstructorSearch := csSimplest;
end;

{ TTypeList }

constructor TTypeList.Create(AType: TRttiType);
begin
  FTypeList := TObjectList<TRttiType>.Create(True);

  if Assigned(FtypeList) then begin
    FTypeList.Add(AType);
  end;
end;

function TTypeList.GetRandomType: TRttiType;
begin
  Result := nil;
  if FTypeList.Count > 0 then begin
    Result := FTypeList[Random(FTypeList.Count)];
  end;
end;

function TTypeList.Orto<T>: TTypeList;
var ctx: TRttiContext;
begin
  ctx := TRttiContext.Create;
  FTypeList.Add(ctx.GetType(TypeInfo(T)));
end;

end.
