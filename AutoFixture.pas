unit AutoFixture;

interface

uses
  SysUtils,
  RTTI,
  Generics.Collections,
  AutoFixtureSetup,
  AutoFixtureGenerator,
  Delphi.Mocks,
  Spring.Mocking,
  EncapsulatedRecord;

type

TTypeList = class
  private
    FTypeList: TObjectList<TRttiType>;

    function GetRandomType: TRttiType;
  public
    constructor Create(AType: TRttiType);
    function OrTo<T>: TTypeList;
end;

TAutoFixture = class;

IAutoFixture = interface(IInterface)
  Function Fixture: TAutoFixture;
end;

ICustomization = interface
  procedure Customize(AAutoFixture: TAutoFixture);
end;

TAutoFixture = class(TInterfacedObject, IAutoFixture, IValueGenerator, IObjectGenerator)
private
  FGenerators: TList<IValueGenerator>;
  FDMocks: TDictionary<System.Pointer, IEncapsulatedRecordType>;
  FSMocks: TDictionary<System.Pointer, IEncapsulatedRecordType>;
  FSetup: TAutofixtureSetup;
  FBindtypeDict: TDictionary<TRttiType, TTypeList>;
  FConfigurationDict: TDictionary<TRttiType, IObjectGenerator>;

  class var FGlobalCustomization: ICustomization;

  procedure setObjectProperties(AType: TRttiType; AObject: TObject; AReferenceDepth: Integer);
  procedure HandleCollection(ACollectionItemType: TRttiType);

public
  constructor Create; overload;
  constructor Create(ACustomization: ICustomization); overload;
  constructor Create(ADefaultGenerator: IValueGenerator); overload;
  constructor Create(ADefaultGenerator, AIdGenerator: IValueGenerator); overload;

  destructor Destroy; override;
  function New<T: Class>(AReferenceDepth: Integer; APropertyName: String = ''): T; overload;
  function New<T>(APropertyName: String = ''): T; overload;

  {TODO -ojehyk -cGeneral : Handle record types}
//  function NewRecord<T: Record>: T; overload;
//  function NewRecord<T: record>(AReferenceDepth: Integer): T; overload;

  function NewObjectList<T: Class>(AOwnsObjects: Boolean = True): TObjectList<T>; overload;
  function NewObjectList<T: Class>(AReferenceDepth: Integer; AOwnsObjects: Boolean = True): TObjectList<T>; overload;
  function NewList<T>(APropertyName: String = ''): TList<T>;

  procedure AddManyTo<T: Class>(var AList: T; ANumberOfElements: Integer=0);
  procedure AddManyToArray<T>(var AArray: TArray<T>; ANumberOfElements: Integer=0);

  procedure Inject<T>(aValue: T); overload;
  procedure Inject<T>(aDelegate: TInjectNameDelegate<T>); overload;
  procedure Inject<T>(aPropertyName: String; aDelegate: TInjectDelegate<T>); overload;
  procedure Inject<T>(aPropertyName: String; aValue: T); overload;
  function DMock<T>(): Delphi.Mocks.TMock<T>;
  function SMock<T>(): Spring.Mocking.Mock<T>;

  function Configure<T: Class>: TObjectConfig<T>;
  function Build<T: Class>: TObjectConfig<T>;

  procedure Customize<T: Class>(AConfigProc: TProc<TObjectConfig<T>>); overload;
  procedure Customize(AValueGenerator: IValueGenerator); overload;
  procedure Customize(ACustomization: ICustomization); overload;

  class property GlobalCustomization: ICustomization read FGlobalCustomization write FGlobalCustomization;
  class procedure AddGlobalCustomization(ACustomization: ICustomization);

  function GetValue(aPropertyName: String; aType: TRttiType): TValue; overload;
  function GetValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: Integer): TValue; overload;
  //function getObject(AType: TRttiType): TObject; overload;
  function GetObject(AType: TRttiType; AReferenceDepth: Integer = -1): TObject;

  function CallMethod(AOnObject: TObject; vMethod: TRttiMethod; AReferenceDepth: Integer = -1): TValue;
  function RegisterType<T, TBind>: TTypeList;
  function ResolveType(ARttiType: TRttiType): TRttiType;
  function Fixture: TAutofixture;

  property Generators: TList<IValueGenerator> read FGenerators;
  property Setup: TAutoFixtureSetup read FSetup;
end;

TEncapsulatedAutoFixture = class(TInterfacedObject, IAutoFixture, IObjectGenerator)
protected
  FAutoFixture: TAutoFixture;
public
  constructor Create(AAutoFixture: TAutoFixture);
  Function Fixture: TAutoFixture;
  function getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
  function getObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
end;

TCompositeCustomization = class(TInterfacedObject, ICustomization)
protected
  FCustomization: ICustomization;
  FOtherCustomization: ICustomization;
public
  procedure Customize(AFixture: TAutoFixture);
  constructor Create(ACustomization, AOtherCustumization: ICustomization);
end;

implementation

uses
  AutoFixture.IdGenerator,
  Spring,
  AutoFixtureLibrary;

{ TAutoFixture }
class procedure TAutoFixture.AddGlobalCustomization(ACustomization: ICustomization);
begin
  if Assigned(FGlobalCustomization) then begin
    FGlobalCustomization := TCompositeCustomization.Create(FGlobalCustomization, ACustomization);
  end
  else begin
    FGlobalCustomization := ACustomization;
  end;
end;

procedure TAutoFixture.AddManyTo<T>(var AList: T; ANumberOfElements: Integer=0);
var
  i: Integer;
  ctx: TRttiContext;
  vType: TRttiType;
  vMethod: TRttiMethod;
  vParams: TArray<TRttiParameter>;
  vParam: TRttiParameter;
  vValueList: TArray<TValue>;
begin
  if ANumberOfElements <= 0 then begin
    ANumberOfElements := FSetup.CollectionSize;
  end;

  ctx := TRttiContext.Create;
  vType := ctx.GetType(TypeInfo(T));

  // Find the "Add" method.
  for vMethod in vType.GetMethods do begin
    if (AnsiUpperCase(vMethod.Name) = 'ADD') then begin
      vParams := vMethod.GetParameters;

      if Length(vParams) = 1 then begin
        vParam := vParams[0];
        setLength(vValueList, 1);

        for i := 1 to ANumberOfElements do begin
          vValueList[0] := getValue('', vParam.ParamType);
          vMethod.Invoke(AList, vValueList);
        end;

        break;
      end
      else if (Length(vParams) = 0) and (vMethod.ReturnType <> nil) then begin
        setLength(vValueList, 0);

        for i := 1 to ANumberOfElements do begin
          vMethod.Invoke(AList, vValueList);
        end;
      end;
    end;
  end;
end;

procedure TAutoFixture.AddManyToArray<T>(var AArray: TArray<T>; ANumberOfElements: Integer=0);
var
  ctx: TRttiContext;
  vType: TRttiType;
  i: Integer;
  vValue: TValue;
  vActual: T;
begin
  ctx := TRttiContext.Create;
  vType := ctx.GetType(TypeInfo(T));

  if ANumberOfElements <= 0 then begin
    ANumberOfElements := FSetup.CollectionSize;
  end;

  SetLength(AArray, Length(AArray) + ANumberOfElements);

  for i := Length(AArray) - ANumberOfElements to Length(AArray) - 1 do begin
    vValue := getValue('', vType);
    if vValue.TryAsType(vActual) then begin
      AArray[i] := vActual;
    end;
  end;
end;

function TAutoFixture.Build<T>: TObjectConfig<T>;
var
  ctx: TRttiContext;
  vType: TRttiType;
  vGenerator: IObjectGenerator;
  vEncapsulatedFixture: IObjectGenerator;
begin
  ctx := TRttiContext.Create;
  vType := ctx.GetType(TypeInfo(T));

  if FConfigurationDict.TryGetValue(vType, vGenerator) then begin
    Result := TObjectConfig<T>.Create(FSetup, vGenerator);
  end
  else begin
    vEncapsulatedFixture := TEncapsulatedAutoFixture.Create(Self);
    Result := TObjectConfig<T>.Create(FSetup, vEncapsulatedFixture);
  end;
end;

function TAutoFixture.Configure<T>: TObjectConfig<T>;
var
  ctx: TRttiContext;
  vType: TRttiType;
  vGenerator: IObjectGenerator;
  vEncapsulatedFixture: IObjectGenerator;
begin
  ctx := TRttiContext.Create;
  vType := ctx.GetType(TypeInfo(T));

  if FConfigurationDict.TryGetValue(vType, vGenerator) then begin
    if not (vGenerator is TObjectConfig<T>) then begin
      vGenerator := TObjectConfig<T>.Create(FSetup, vGenerator);
      FConfigurationDict[vType] := vGenerator;
    end;
  end
  else begin
    vEncapsulatedFixture := TEncapsulatedAutoFixture.Create(Self);
    vGenerator := TObjectConfig<T>.Create(FSetup, vEncapsulatedFixture);
    FConfigurationDict.Add(vType, vGenerator);
  end;
  Result := TObjectConfig<T>(vGenerator);
end;

constructor TAutoFixture.Create(ACustomization: ICustomization);
begin
  Create(nil, nil);
  ACustomization.Customize(Self);
end;

constructor TAutoFixture.Create;
begin
  Create(nil, nil);
end;

constructor TAutoFixture.Create(ADefaultGenerator: IValueGenerator);
begin
  Create(ADefaultGenerator, nil);
end;

constructor TAutoFixture.Create(ADefaultGenerator, AIdGenerator: IValueGenerator);
begin
  FGenerators := TList<IValueGenerator>.Create;

  if Assigned(ADefaultGenerator) then begin
    FGenerators.Add(ADefaultGenerator);
  end
  else begin
    FGenerators.Add(TRandomGenerator.Create);
  end;

  if Assigned(AIdGenerator) then begin
    FGenerators.Add(AIdGenerator);
  end
  else begin
    FGenerators.Add(TIdGenerator.Create);
  end;

  Fsetup := TAutoFixtureSetup.Create;
  FDMocks := TDictionary<System.Pointer, IEncapsulatedRecordType>.Create;
  FSMocks := TDictionary<System.Pointer, IEncapsulatedRecordType>.Create;
  FBindtypeDict := TDictionary<TRttiType, TTypeList>.Create;
  FConfigurationDict := TDictionary<TRttiType, IObjectGenerator>.Create;

  if Assigned(FGlobalCustomization) then begin
    FGlobalCustomization.Customize(Self);
  end;
end;

procedure TAutoFixture.Customize(AValueGenerator: IValueGenerator);
begin
  FGenerators.Add(AValueGenerator);
end;

procedure TAutoFixture.Customize(ACustomization: ICustomization);
begin
  ACustomization.Customize(Self);
end;

procedure TAutoFixture.Customize<T>(AConfigProc: TProc<TObjectConfig<T>>);
begin
  // This function simply encapsulates Configure (Better just call configure directly, only included to be more similar to the .Net version)
  AConfigProc(Configure<T>);
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

destructor TAutoFixture.Destroy;
begin
  FreeAndNil(FSetup);
  FreeAndNil(FGenerators);
  FreeAndNil(FDMocks);
  FreeAndNil(FSMocks);
  FreeAndNil(FBindtypeDict);

  inherited;
end;

function TAutoFixture.Fixture: TAutofixture;
begin
  Result := Self;
end;

{$WARN UNSAFE_CAST OFF}
procedure TAutoFixture.setObjectProperties(AType: TRttiType; AObject: TObject; AReferenceDepth: Integer);
var
  vProperty: TRttiProperty;
  vField: TRttiField;
  vValue: TValue;
  vGenerator: IObjectGenerator;
begin
  // Check if there is a configuration for this object type
  if FConfigurationDict.TryGetValue(AType, vGenerator) then begin
    // Loop through and set fields using the generator found
    for vField in AType.GetFields do begin
      if vField.Name <> 'FRefCount' then begin
        // Try to set value
        vValue := vGenerator.getValue(vField.Name, vField.FieldType);

        if not vValue.IsEmpty then begin
          vField.SetValue(Pointer(AObject), vValue);
        end
        else begin
          if Assigned(vField.FieldType) and (vField.FieldType.TypeKind = tkClass) then begin
            if AReferenceDepth > 1 then begin
              vValue := TValue.From(getObject(vField.FieldType, AReferenceDepth - 1));
              if not vValue.IsEmpty then begin
                vField.SetValue(Pointer(AObject), vValue);
              end;
            end;
          end;
        end;
      end;
    end;
  end
  else begin
    // Loop through and set fields
    for vField in AType.GetFields do begin
      if vField.Name <> 'FRefCount' then begin
        // Try to set value
        vValue := getValue(vField.Name, vField.FieldType, AReferenceDepth - 1);

        if not vValue.IsEmpty then begin
          vField.SetValue(Pointer(AObject), vValue);
        end
        else begin
          if Assigned(vField.FieldType) and (vField.FieldType.TypeKind = tkClass) then begin
            if AReferenceDepth > 1 then begin
              vValue := TValue.From(getObject(vField.FieldType, AReferenceDepth - 1));
              vField.SetValue(Pointer(AObject), vValue);
            end;
          end;
        end;
      end;
    end;


    // Loop through and set properties
//    for vProperty in AType.GetProperties do
//    begin
//      if vProperty.IsWritable then
//      begin
//        // Try to set property value
//        vValue := getValue(vProperty.Name, vProperty.PropertyType, AReferenceDepth);
//        if not vValue.IsEmpty then
//        begin
//          vProperty.SetValue(Pointer(AObject), vValue);
//        end;
//      end;
//    end;
  end;
end;

function TAutoFixture.GetObject(AType: TRttiType; AReferenceDepth: Integer = -1): TObject;
var
  vConstructor, vAddMethod: TRttiMethod;
  vParameterList: TArray<TRttiParameter>;
  vValue: TValue;
  i: Integer;
  vCollectionDetected: Boolean;
  vConfig: IObjectGenerator;
begin
  if AReferenceDepth = -1 then begin
    AReferenceDepth := Setup.ReferenceDepth
  end
  else if AReferenceDepth = 0 then begin
    Result := nil;
    Exit;
  end;

  // Lookup type bindings
  AType := ResolveType(AType);

  // Check if class configured
  if Self.FConfigurationDict.TryGetValue(AType, vConfig) then begin
    Result := vConfig.getObject(AType, AReferenceDepth);
  end
  else begin
    Result := AType.AsInstance.MetaclassType.Create;

    // Find constructor and optionally Add methods
    TAutofixtureLibrary.GetMethods(FSetup, AType, vConstructor, vAddMethod);

    if vConstructor <> nil then begin
      CallMethod(Result, vConstructor, AReferenceDepth);
    end;

    vCollectionDetected := False;
    if Assigned(vAddMethod) then begin
      vParameterList := vAddMethod.GetParameters;

      if Setup.AutoDetectList then begin
        if Length(vParameterList) <= 1 then begin
          vCollectionDetected := True;

          if Length(vParameterList) = 1 then begin
            // Some type of list with an add method taking one parameter
            for i := 1 to Setup.CollectionSize do begin
              CallMethod(Result, vAddMethod, AReferenceDepth);
            end;
          end
          else begin
            // Probably some kind of collection with an add method returning a TCollectionItem
            if Assigned(vAddMethod.ReturnType) and (vAddMethod.ReturnType.TypeKind = tkClass) then begin
              for i := 1 to Setup.CollectionSize do begin
                vValue := CallMethod(Result, vAddMethod, AReferenceDepth);
                HandleCollection(vValue.ValueType);
                if not vValue.IsEmpty then begin
                  SetObjectProperties(vValue.ValueType, vValue.AsObject, AReferenceDepth);
                end;
              end;
            end
            else begin
              // Nope, not a TCollection anyway
              vCollectionDetected := False;
            end;
          end;
        end;
      end
      else begin
        if Setup.AutoDetectDictionary then begin
          if Length(vParameterList) = 2 then begin
            vCollectionDetected := True;

            for i := 1 to Setup.CollectionSize do begin
              CallMethod(Result, vAddMethod, AReferenceDepth);
            end;
          end;
        end;
      end;
    end;

    if not vCollectionDetected then begin
      setObjectProperties(AType, Result, AReferenceDepth);
    end;
  end;
end;

function TAutoFixture.getValue(aPropertyName: String; aType: TRttiType): TValue;
begin
  Result := getValue(APropertyName, AType, Setup.ReferenceDepth);
end;

function TAutoFixture.CallMethod(AOnObject: TObject; vMethod: TRttiMethod; AReferenceDepth: Integer = -1): TValue;
var
  vValueList: TList<TValue>;
  vParam: TRttiParameter;
  vValue: TValue;
begin
  if AReferenceDepth = -1 then begin
    AReferenceDepth := FSetup.ReferenceDepth;
  end;

  vValueList := TList<TValue>.Create;
  try
    for vParam in vMethod.GetParameters do
    begin
      vValue := getValue(vParam.Name, vParam.ParamType, AReferenceDepth);
      vValueList.Add(vValue);
    end;
    Result := vMethod.Invoke(AOnObject, vValueList.ToArray);
  finally
    FreeAndNil(vValueList);
  end;
end;


function TAutoFixture.getValue(APropertyName: String; AType: TRttiType; AReferenceDepth: Integer): TValue;
var vGenerator: IValueGenerator;
  vValue: TValue;
begin
  Result := TValue.Empty;
  // Resolve type binding
  if Assigned(AType) then begin
    AType := ResolveType(AType);

    for vGenerator in FGenerators do begin
      vValue := vGenerator.getValue(aPropertyName, aType, AReferenceDepth);

      if not vValue.IsEmpty then begin
        Result := vValue;
      end;
    end;

    if Result.IsEmpty then begin
      if AType.TypeKind = tkClass then begin
        if AReferenceDepth > 0 then begin
          Result := TValue.From(getObject(AType, AReferenceDepth));
        end;
      end;
    end;
  end;
end;

procedure TAutoFixture.HandleCollection(ACollectionItemType: TRttiType);
var
  vGenerator: IObjectGenerator;
  vCollectionItemGenerator: TCollectionItemGenerator;
begin
  if FConfigurationDict.TryGetValue(ACollectionItemType, vGenerator) then begin
    // there is already a configured item for this element - best thing to do is to add a collectionItem handler on top
    if not (vGenerator is TCollectionItemGenerator) then begin
      FConfigurationDict[ACollectionItemType] := TCollectionItemGenerator.Create(ACollectionItemType, vGenerator);
    end;
  end
  else begin
    vCollectionItemGenerator := TCollectionItemGenerator.Create(ACollectionItemType, TEncapsulatedAutoFixture.Create(Self));
    FConfigurationDict.Add(ACollectionItemType, vCollectionItemGenerator);
  end;
end;

function TAutoFixture.New<T>(APropertyName: String): T;
var ctx: TRttiContext;
  vValue: TValue;
  vType: TRttiType;
begin
  ctx := TRttiContext.Create;
  vType := ctx.getType(TypeInfo(T));
  vValue := getValue(APropertyName, vType);

  if vValue.isEmpty then begin
    Result := Default(T);
  end
  else begin
    if not vValue.TryAsType(Result) then begin
      result := vValue.AsType<T>;
    end;
  end;
end;

function TAutoFixture.NewList<T>(APropertyName: String): TList<T>;
var
  i: Integer;
begin
  Result := TList<T>.Create;
  for i := 1 to Fsetup.CollectionSize do begin
    Result.Add(New<T>(APropertyName));
  end;
end;

function TAutoFixture.NewObjectList<T>(AOwnsObjects: Boolean): TObjectList<T>;
var
  i: Integer;
begin
  Result := TObjectList<T>.Create(AOwnsObjects);
  for i := 1 to Fsetup.CollectionSize do begin
    Result.Add(New<T>())
  end;
end;

function TAutoFixture.NewObjectList<T>(AReferenceDepth: Integer; AOwnsObjects: Boolean): TObjectList<T>;
var
  i: Integer;
begin
  Result := TObjectList<T>.Create(AOwnsObjects);
  for i := 1 to Fsetup.CollectionSize do begin
    Result.Add(New<T>(AReferenceDepth))
  end;
end;

function TAutoFixture.RegisterType<T, TBind>: TTypeList;
var ctx: TRttiContext;
  vType, vBindType: TRttiType;
  vValue: TValue;
  vProperty: TRttiProperty;
  vPropertyFound: Boolean;
begin
  ctx := TRttiContext.Create;
  vType := ctx.getType(TypeInfo(T));
  vBindType := ctx.getType(TypeInfo(TBind));

  Result := TTypeList.Create(vBindType);

  if FBindtypeDict.ContainsKey(vType) then begin
    FBindtypeDict[vType].Free;
    FBindTypeDict[vType] := Result;
  end
  else begin
    FBindtypeDict.Add(vType, Result);
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

function TTypeList.OrTo<T>: TTypeList;
var ctx: TRttiContext;
begin
  ctx := TRttiContext.Create;
  FTypeList.Add(ctx.GetType(TypeInfo(T)));
end;

{ TEncapsulatedAutoFixture }

constructor TEncapsulatedAutoFixture.Create(AAutoFixture: TAutoFixture);
begin
  FAutoFixture := AAutoFixture;
end;

function TEncapsulatedAutoFixture.Fixture: TAutoFixture;
begin
  Result := FAutoFixture;
end;

function TEncapsulatedAutoFixture.GetObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
begin
  Result := FAutoFixture.GetObject(AType, AReferenceDepth);
end;

function TEncapsulatedAutoFixture.getValue(APropertyName: String; AType: TRttiType; AReferenceDepth: integer = -1): TValue;
begin
  Result := FAutoFixture.getValue(APropertyName, AType, AReferenceDepth);
end;

//function TAutoFixture.NewObject<T>: T;
//begin
//  Result := Self.New<T>(Setup.ReferenceDepth);
//end;

function TAutoFixture.New<T>(AReferenceDepth: Integer; APropertyName: String = ''): T;
var ctx: TRttiContext;
  vType: TRttiType;
  vValue: TValue;
  vObj: TObject;
begin
  ctx := TRttiContext.Create;
  vValue := getValue(APropertyName, ctx.getType(TypeInfo(T)));

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

function TAutoFixture.DMock<T>: Delphi.Mocks.TMock<T>;
begin
  if not FDMocks.ContainsKey(Typeinfo(T)) then begin
    Result := Delphi.Mocks.TMock<T>.Create;
    FDMocks.Add(TypeInfo(T), TRecordEncapsulation<Delphi.Mocks.TMock<T>>.Create(Result));
    Self.Inject<T>(Result.Instance);
  end
  else begin
    Result := TRecordEncapsulation<Delphi.Mocks.TMock<T>>(FDMocks[TypeInfo(T)]).Contents;
  end;
end;

function TAutoFixture.SMock<T>: Spring.Mocking.Mock<T>;
begin
  if not FSMocks.ContainsKey(Typeinfo(T)) then begin
    Result := Spring.Mocking.Mock<T>.Create(TMockBehavior.Strict);
    FSMocks.Add(TypeInfo(T), TRecordEncapsulation<Spring.Mocking.Mock<T>>.Create(Result));
    Self.Inject<T>(Result.Instance);
  end
  else begin
    Result := TRecordEncapsulation<Spring.Mocking.Mock<T>>(FSMocks[TypeInfo(T)]).Contents;
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

{ TCompositeCustomization }

constructor TCompositeCustomization.Create(ACustomization, AOtherCustumization: ICustomization);
begin
  FCustomization := ACustomization;
  FOtherCustomization := AOtherCustumization;
end;

procedure TCompositeCustomization.Customize(AFixture: TAutoFixture);
begin
  FCustomization.Customize(AFixture);
  FOtherCustomization.Customize(AFixture);
end;

end.
