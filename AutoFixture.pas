unit AutoFixture;

interface

uses
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
    function Orto<T>: TTypeList;
end;

TAutoFixture = class;

IAutoFixture = interface(IInterface)
  Function Fixture: TAutoFixture;
end;

TAutoFixture = class(TInterfacedObject, IAutoFixture, IValueGenerator, IObjectGenerator)
private
  FGenerators: TList<IValueGenerator>;
  FDMocks: TDictionary<System.Pointer, IEncapsulatedRecordType>;
  FSMocks: TDictionary<System.Pointer, IEncapsulatedRecordType>;
  FSetup: TAutofixtureSetup;
  FBindtypeDict: TDictionary<TRttiType, TTypeList>;
  FConfigurationDict: TDictionary<TRttiType, IObjectGenerator>;

public
  constructor Create;
  destructor Destroy; override;
  function New<T: Class>: T; overload;
  function New<T: Class>(AReferenceDepth: Integer): T; overload;
  function NewInterface<T: IInterface>: T; overload;
  function NewInterface<T: IInterface>(AReferenceDepth: Integer): T; overload;
{TODO -ojehyk -cGeneral : Handle record types}
//  function NewRecord<T: Record>: T; overload;
//  function NewRecord<T: record>(AReferenceDepth: Integer): T; overload;

  function NewList<T: Class>(AOwnsObjects: Boolean = True): TObjectList<T>; overload;
  function NewList<T: Class>(AReferenceDepth: Integer; AOwnsObjects: Boolean = True): TObjectList<T>; overload;
  function NewInterfaceList<T: IInterface>: TList<T>; overload;
  function NewInterfaceList<T: IInterface>(AReferenceDepth: Integer): TList<T>; overload;

  function getValue(aPropertyName: String; aType: TRttiType): TValue; overload;
  function getValue<T>: T; overload;
  procedure Inject<T>(aValue: T); overload;
  procedure Inject<T>(aDelegate: TInjectNameDelegate<T>); overload;
  procedure Inject<T>(aPropertyName: String; aDelegate: TInjectDelegate<T>); overload;
  procedure Inject<T>(aPropertyName: String; aValue: T); overload;
  function DMock<T>(): Delphi.Mocks.TMock<T>;
  function SMock<T>(): Spring.Mocking.Mock<T>;

  function Configure<T: Class>: TBaseConfig<T>;
  function Build<T: Class>: TBaseConfig<T>;

  function getObject(AType: TRttiType): TObject; overload;
  function getObject(AType: TRttiType; AReferenceDepth: Integer): TObject; Overload;
  procedure CallMethod(AOnObject: TObject; vMethod: TRttiMethod);
  function RegisterType<T, TBind>: TTypeList;
  function ResolveType(ARttiType: TRttiType): TRttiType;
  function Fixture: TAutofixture;

  property Setup: TAutoFixtureSetup read FSetup;
end;

TEncapsulatedAutoFixture = class(TInterfacedObject, IAutoFixture, IObjectGenerator)
protected
  FAutoFixture: TAutoFixture;
public
  constructor Create(AAutoFixture: TAutoFixture);
  Function Fixture: TAutoFixture;
  function getValue(aPropertyName: String; aType: TRttiType): TValue;
  function getObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
end;


implementation

uses SysUtils,
  AutoFixture.IdGenerator;

{ TAutoFixture }
function TAutoFixture.Build<T>: TBaseConfig<T>;
var
  ctx: TRttiContext;
  vType: TRttiType;
  vGenerator: IObjectGenerator;
  vEncapsulatedFixture: IObjectGenerator;
begin
  ctx := TRttiContext.Create;
  vType := ctx.GetType(TypeInfo(T));

  if FConfigurationDict.TryGetValue(vType, vGenerator) then begin
    Result := TBaseConfig<T>.Create(FSetup, vGenerator);
  end
  else begin
    vEncapsulatedFixture := TEncapsulatedAutoFixture.Create(Self);
    Result := TBaseConfig<T>.Create(FSetup, vEncapsulatedFixture);
  end;
end;

function TAutoFixture.Configure<T>: TBaseConfig<T>;
var
  ctx: TRttiContext;
  vType: TRttiType;
  vGenerator: IObjectGenerator;
  vEncapsulatedFixture: IObjectGenerator;
begin
  ctx := TRttiContext.Create;
  vType := ctx.GetType(TypeInfo(T));

  if FConfigurationDict.TryGetValue(vType, vGenerator) then begin
    Result := vGenerator as TBaseConfig<T>;
  end
  else begin
    vEncapsulatedFixture := TEncapsulatedAutoFixture.Create(Self);
    vGenerator := TBaseConfig<T>.Create(FSetup, vEncapsulatedFixture);
    Result := TBaseConfig<T>(vGenerator);
    FConfigurationDict.Add(vType, vGenerator);
  end;
end;

constructor TAutoFixture.Create;
begin
  FGenerators := TList<IValueGenerator>.Create;
  FGenerators.Add(TRandomGenerator.Create);
  FGenerators.Add(TIdGenerator.Create);
  Fsetup := TAutoFixtureSetup.Create;
  FDMocks := TDictionary<System.Pointer, IEncapsulatedRecordType>.Create;
  FSMocks := TDictionary<System.Pointer, IEncapsulatedRecordType>.Create;
  FBindtypeDict := TDictionary<TRttiType, TTypeList>.Create;
  FConfigurationDict := TDictionary<TRttiType, IObjectGenerator>.Create;
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

function TAutoFixture.getObject(AType: TRttiType): TObject;
begin
  Result := Self.getObject(AType, Setup.ReferenceDepth);
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
  vConfig: IObjectGenerator;
begin
  // Lookup type bindings
  AType := ResolveType(AType);

  // Check if class configured
  if Self.FConfigurationDict.TryGetValue(AType, vConfig) then begin
    Result := vConfig.getObject(AType, AReferenceDepth);
  end
  else begin
    Result := AType.AsInstance.MetaclassType.Create;
    vAddMethod := nil;

    // Find constructor method
    vConstructor := nil;

    if FSetup.ConstructorSearch = TConstructorSearch.csSimplest then begin
      // Find simplest constructor deklareret i klassen
      for vMethod in AType.GetMethods do begin
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

          for i := 1 to Setup.CollectionSize do begin
            CallMethod(Result, vAddMethod);
          end;
        end;
      end
      else begin
        if Setup.AutoDetectDictionary then begin
          if Length(vParameterList) = 2 then begin
            vCollectionDetected := True;

            for i := 1 to Setup.CollectionSize do begin
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
            if Assigned(vField.FieldType) and (vField.FieldType.TypeKind = tkClass) then begin
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
end;

procedure TAutoFixture.CallMethod(AOnObject: TObject; vMethod: TRttiMethod);
var
  vValueList: TList<TValue>;
  vParam: TRttiParameter;
  vValue: TValue;
begin
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


function TAutoFixture.getValue(APropertyName: String; AType: TRttiType): TValue;
var vGenerator: IValueGenerator;
  vValue: TValue;
begin
  Result := TValue.Empty;
  // Resolve type binding
  if Assigned(AType) then begin
    AType := ResolveType(AType);

    for vGenerator in FGenerators do begin
      vValue := vGenerator.getValue(aPropertyName, aType);

      if not vValue.IsEmpty then begin
        Result := vValue;
      end;
    end;

    if vValue.IsEmpty then begin
      if AType.TypeKind = tkClass then begin
        Result := TValue.From(getObject(AType));
      end;
    end;
  end;
end;

function TAutoFixture.getValue<T>(): T;
var ctx: TRttiContext;
  vValue: TValue;
begin
  ctx := TRttiContext.Create;
  vValue := getValue('', ctx.getType(TypeInfo(T)));

  if vValue.isEmpty then begin
    Result := Default(T);
  end
  else begin
    Result := vValue.AsType<T>;
  end;
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
    vObj := getObject(vType, AReferenceDepth);
  end
  else begin
    vObj := vValue.AsObject;
  end;

  vClassName := vObj.ClassName;

  vObjCast := vObj as TInterfacedObject;
  vIObj := IInterface(vObjCast);
  Result := T(vIObj);

  if (vObj is TInterfacedObject) and (vClassName<>'') then begin
    vObjCast := TInterfacedObject(vObj);
    vIObj := IInterface(vObjCast);
    Result := T(vIObj);
  end;

  ctx.Free;
end;

function TAutoFixture.NewInterfaceList<T>: TList<T>;
var
  i: Integer;
begin
  Result := TList<T>.Create;
  for i := 1 to Fsetup.CollectionSize do begin
    Result.Add(NewInterFace<T>())
  end;
end;

function TAutoFixture.NewInterfaceList<T>(AReferenceDepth: Integer): TList<T>;
var
  i: Integer;
begin
  Result := TList<T>.Create;
  for i := 1 to Fsetup.CollectionSize do begin
    Result.Add(NewInterFace<T>(AReferenceDepth))
  end;
end;

function TAutoFixture.NewList<T>(AOwnsObjects: Boolean): TObjectList<T>;
var
  i: Integer;
begin
  Result := TObjectList<T>.Create(AOwnsObjects);
  for i := 1 to Fsetup.CollectionSize do begin
    Result.Add(New<T>())
  end;
end;

function TAutoFixture.NewList<T>(AReferenceDepth: Integer; AOwnsObjects: Boolean): TObjectList<T>;
var
  i: Integer;
begin
  Result := TObjectList<T>.Create(AOwnsObjects);
  for i := 1 to Fsetup.CollectionSize do begin
    Result.Add(New<T>(AReferenceDepth))
  end;
end;

//function TAutoFixture.NewRecord<T>: T;
//begin
//  Result := NewRecord<T>(FSetup.ReferenceDepth);
//end;
//
//function TAutoFixture.NewRecord<T>(AReferenceDepth: Integer): T;
//var ctx: TRttiContext;
//  vType: TRttiType;
//  vValue: TValue;
//  vRec: T;
//begin
//  Result := nil;
//  ctx := TRttiContext.Create;
//  vValue := getValue('', ctx.getType(TypeInfo(T)));
//
//  if vValue.IsEmpty then begin
//    vType := ctx.GetType(TypeInfo(T));
//    vRec := getObject(vType, AReferenceDepth);
//  end
//  else begin
//    vRec := vValue.AsType<T>;
//  end;
//
//  Result := vRec;
//
//  ctx.Free;
//end;

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

function TEncapsulatedAutoFixture.getValue(APropertyName: String; AType: TRttiType): TValue;
begin
  Result := FAutoFixture.getValue(APropertyName, AType);
end;

function TAutoFixture.New<T>: T;
begin
  Result := Self.New<T>(Setup.ReferenceDepth);
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

end.
