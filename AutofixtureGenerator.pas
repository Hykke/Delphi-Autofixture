unit AutofixtureGenerator;

interface

uses
  RTTI,
  Generics.Collections,
  AutoFixtureSetup;

type
{$SCOPEDENUMS ON}

IValueGenerator = interface
  function getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
end;

IObjectGenerator = interface(IValueGenerator)
  function getObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
end;

TInjectDelegate<T> = reference to function(): T;
TInjectNameDelegate<T> = reference to function(aPropertyName: String): T;
TObjectModifyProcedure<T> = reference to procedure(AObject: T);
TPropertySelector<TObjectType, TPropertyType> = reference to function(AObject: TObjectType): TPropertyType;

TValueGenerator<T> = class(TInterfacedObject, IValueGenerator)
protected
  FTypeInfo: TRttiType;
  FPropertyName: String;
  FDelegate: TInjectDelegate<T>;
  FNameDelegate: TInjectNameDelegate<T>;
public
  constructor Create(); virtual;
  destructor Destroy; override;
  procedure Register(aPropertyName: String; aDelegate: TInjectDelegate<T>); overload;
  procedure Register(aDelegate: TInjectNameDelegate<T>); overload;
  function canGenerate(aPropertyName: String): Boolean;
  function getValue(aPropertyName: String; aType:TRttiType; AReferenceDepth: integer = -1): TValue;
end;

TProcessProperty = (Uninitialized, Omit, ValueSet);

TPropertyConfig = class
private
  FFieldType: TRttiField;
  FType: TRttiType;
  FPropertyName: String;
  FConfiguredPropertyValue: TValue; // If any!
  FPropertyIdentifier: TValue;
  FProcessProperty: TProcessProperty;
end;

TBaseConfig = class(TInterfacedObject, IObjectGenerator)
protected
  FType: TRttiType;
  FPreviousGenerator: IObjectGenerator;
  FProperties: TDictionary<String, TPropertyConfig>;
  FPropertiesByType: TDictionary<TRttiType, TList<TPropertyConfig>>;

  procedure InitProperties;
public
  constructor Create(AType: TRttiType; APreviousConfig: IObjectGenerator);
  destructor Destroy; override;
  function GetValue(aPropertyName: String; aType:TRttiType; AReferenceDepth: integer = -1): TValue;
  function GetObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
end;

TObjectConfig<T: Class> = class(TBaseConfig)
protected
  FSetup: TAutofixtureSetup;
  FRttiContext: TRttiContext;
  FExecList: TList<TObjectModifyProcedure<T>>;
  FObject: T;
  //function GetPropertiesOfType<Typ>: TList<TPropertyConfig>;
  function GetPropertyFromSelector<Typ>(AProperty: TPropertySelector<T, Typ>): TPropertyConfig;
  function GenerateIndexValue(AType: TRttiType; AIndex: Integer): TValue;
  function GetIndexFromValue<Typ>(AValue: Typ): Integer;
//  procedure InitProperties();
public
  constructor Create(AAutofixtueSetup: TAutoFixtureSetup; APreviousConfig: IObjectGenerator);
  destructor Destroy; override;
//  function getValue(aPropertyName: String; aType:TRttiType): TValue;
//  function getObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
  function OmitAutoProperties: TObjectConfig<T>;
  function WithValue<Typ>(AProperty: String; AValue: Typ): TObjectConfig<T>; overload;
  function WithValue<Typ>(AProperty: TPropertySelector<T, Typ>; AValue: Typ): TObjectConfig<T>; overload;
  function Without<Typ>(AProperty: String): TObjectConfig<T>; overload;
  function Without<Typ>(AProperty: TPropertySelector<T, Typ>): TObjectConfig<T>; overload;
  function Omit<Typ>(AProperty: String): TObjectConfig<T>; overload;
  function Omit<Typ>(AProperty: TPropertySelector<T, Typ>): TObjectConfig<T>; overload;
  function Exec(AProcedureModifier: TObjectModifyProcedure<T>): TObjectConfig<T>; overload;
  function New: T;
end;

TRandomGenerator = class(TinterfacedObject, IValueGenerator)
  function getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
end;

TCollectionItemGenerator = class(TBaseConfig)
public
  constructor Create(AType: TRttiType; APreviousConfig: IObjectGenerator); virtual;
  destructor Destroy; override;
//  function getValue(aPropertyName: String; aType:TRttiType): TValue;
//  function getObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
end;

implementation

uses SysUtils,
  System.Classes,
  Dateutils,
  Spring.Mocking.Matching;


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

destructor TValueGenerator<T>.Destroy;
begin
  FDelegate := nil;
  FNameDelegate := nil;

  inherited;
end;

function TValueGenerator<T>.getValue(aPropertyName: String; aType:TRttiType; AReferenceDepth: integer = -1): TValue;
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

procedure TValueGenerator<T>.Register(ADelegate: TInjectNameDelegate<T>);
begin
  FPropertyName := '';
  FNameDelegate := aDelegate;
end;

{ TRandomGenerator }

function TRandomGenerator.getValue(APropertyName: String; AType: TRttiType; AReferenceDepth: integer = -1): TValue;
var i: Integer;
  vGuid: TGuid;
  vClassRef: TClass;
  ctx: TRttiContext;
  vType: TRttiClassRefType;
begin
  Result := TValue.Empty;

  if Assigned(AType) then begin
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
    tkInterface: begin
      Result := TValue.From(nil); {TODO -oJEHYK -cAutoMock : Make mock object dynamically}
    end;
    tkClassRef: begin
      vType := AType as TRttiClassRefType;
      vClassRef := vType.MetaclassType;
      Result := TValue.From(vClassRef); // Gets the topmost classref that it's possible to assign - not always correct, but the best we can do
    end;
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

{ TBaseConfig<T> }

{$WARN UNSAFE_CAST OFF}
constructor TObjectConfig<T>.Create(AAutofixtueSetup: TAutoFixtureSetup; APreviousConfig: IObjectGenerator);
var
  vObject: T;
  vPByte: ^Byte;
  i: Integer;
  vList: TList<TPropertyConfig>;
  vValue: TValue;
  vConfig: TPropertyConfig;
begin
  FSetup := AAutofixtueSetup;
  FExecList := TList<TObjectModifyProcedure<T>>.Create;

  // Find all properties
  FRttiContext := TRttiContext.Create;
  inherited Create(FRttiContext.GetType(TypeInfo(T)), APreviousConfig);

  // TODO: Make lazy!
  // Initialize "Object property finder"
  FObject := T(FType.AsInstance.MetaclassType.Create);

  for vList in FPropertiesByType.Values do begin
    for i := 0 to vList.Count - 1 do begin
      vConfig := vList[i];
      vValue := GenerateIndexValue(vConfig.FType, i);

      if not vValue.IsEmpty then begin
        // Write value to object
        vConfig.FFieldType.SetValue(pointer(FObject), vValue);
      end;
      // Now get value we check against
      vConfig.FPropertyIdentifier := vConfig.FFieldType.GetValue(pointer(FObject));
    end;
  end;
  vList := nil;
end;

destructor TObjectConfig<T>.Destroy;
begin
  FreeAndNil(FExecList);

  inherited;
end;

function TObjectConfig<T>.Exec(AProcedureModifier: TObjectModifyProcedure<T>): TObjectConfig<T>;
begin
  Result := Self;
  FExecList.Add(AProcedureModifier);
end;

function TObjectConfig<T>.GetIndexFromValue<Typ>(AValue: Typ): Integer;
var
  vValue: TValue;
begin
  Result := -1; // Obviously invalid index
  vValue := TValue.From(AValue);

  case FRttiContext.getType(TypeInfo(Typ)).TypeKind of
  tkInteger: begin
    Result := vValue.AsInteger;
  end;
  tkInt64: begin
    Result := vValue.AsInt64;
  end;
  tkChar, TkWChar: begin
    Result := Ord(vValue.AsString[1]);
  end;
  tkWString, tkUString, tkLString: begin
    Result := StrToInt(vValue.AsString);
  end;
  tkEnumeration: begin
    Result := vValue.AsOrdinal;
  end;
  tkFloat: Begin
    Result := Trunc(vValue.AsExtended);
  End;
  tkVariant: Begin
    Result := Integer(vValue.AsVariant);
  End;
  tkSet: begin
    // Not really possible to generate a random set, just leave blank
  end;
  tkInterface, tkClass: begin
    Result := Integer(vValue.AsObject);
  end;
{


tkSet

Set types

tkClass

Class types

tkMethod

Procedure and function method types

tkWString

The Delphi 3 constant which replaces tkLWString

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

function TObjectConfig<T>.GenerateIndexValue(AType: TRttiType; AIndex: Integer): TValue;
var i: Integer;
  vObject: TObject;
  vPointer: ^TObject;
begin
  Result := TValue.Empty;

  case AType.TypeKind of
  tkInteger: begin
    Result := TValue.From<Integer>(AIndex);
  end;
  tkInt64: begin
    Result := TValue.From<Int64>(AIndex);
  end;
  tkChar, TkWChar: begin
    Result := TValue.From(Chr(Aindex));
  end;
  tkWString, tkUString, tkLString: begin
    Result := TValue.From(IntToStr(AIndex))
  end;
  tkEnumeration: begin
    Result := TValue.FromOrdinal(aType.Handle, AIndex);
  end;
  tkFloat: Begin
    Result := TValue.From(0.1 + AIndex);
  End;
  tkVariant: Begin
    Result := TValue.FromVariant(AIndex);
  End;
  tkSet: begin
    // Not really possible to generate a random set, just leave blank
  end;
  tkInterface, tkClass: begin
    vObject := nil;
    vPointer := @vObject;
    inc(vPointer, AIndex);
    vObject := vPointer^;
    Result := TValue.From(vObject);
  end;
{


tkSet

Set types

tkClass

Class types

tkMethod

Procedure and function method types

tkWString

The Delphi 3 constant which replaces tkLWString

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

function TObjectConfig<T>.New: T;
var
  vConfig: TPropertyConfig;
  vValue: TValue;
begin
  Result := FType.AsInstance.MetaclassType.Create as T;

  // Now loop through properties
  for vConfig in Self.FProperties.Values do begin
    vValue := getValue(vConfig.FPropertyName, vConfig.FType);
    if not vValue.IsEmpty then begin
      vConfig.FFieldType.SetValue(Pointer(Result), vValue);
    end;
  end;
end;

procedure TBaseConfig.InitProperties();
var
  vField: TRttiField;
  vPropertyConfig: TPropertyConfig;
  vList: TList<TPropertyConfig>;
begin
  for vField in FType.GetFields do
  begin
    if (vField.Name <> 'FRefCount')  then
    begin
      vPropertyConfig := TPropertyConfig.Create;
      vPropertyConfig.FFieldType := vField;
      vPropertyConfig.FType := vField.FieldType;
      vPropertyConfig.FPropertyName := vField.Name;

      if not FProperties.ContainsKey(vPropertyConfig.FPropertyName.ToUpper) then begin
        FProperties.Add(vPropertyConfig.FPropertyName.ToUpper, vPropertyConfig);
      end;

      if Assigned(vPropertyConfig.FType) and FPropertiesByType.TryGetValue(vPropertyConfig.FType, vList) then
      begin
        vList.Add(vPropertyConfig);
      end
      else begin
        vList := TList<TPropertyConfig>.Create;
        vList.Add(vPropertyConfig);

        if Assigned(vPropertyConfig.FType) then begin
          FPropertiesByType.Add(vPropertyConfig.FType, vList);
        end;
        //FProperties.Add(vPropertyConfig.FPropertyName, vPropertyConfig);
      end;
    end;
  end;
end;


function TObjectConfig<T>.Omit<Typ>(AProperty: TPropertySelector<T, Typ>): TObjectConfig<T>;
var
  vConfig: TPropertyConfig;
begin
  Result := Self;

  vConfig := GetPropertyFromSelector<Typ>(AProperty);

  if Assigned(vConfig) then begin
    vConfig.FProcessProperty := TProcessProperty.Omit;
  end;
end;

function TObjectConfig<T>.Omit<Typ>(AProperty: String): TObjectConfig<T>;
var
  vConfig: TPropertyConfig;
begin
  Result := Self;

  if FProperties.TryGetValue(AProperty.ToUpper, vConfig) then begin
    vConfig.FProcessProperty := TProcessProperty.Omit;
  end;
end;

function TObjectConfig<T>.OmitAutoProperties: TObjectConfig<T>;
var
  vConfig: TPropertyConfig;
begin
  Result := Self;

  if FPreviousGenerator is TObjectConfig<T> then begin
    TObjectConfig<T>(FPreviousGenerator).OmitAutoProperties;
  end
  else begin
    for vConfig in FProperties.Values do begin
      if vConfig.FProcessProperty = TProcessProperty.Uninitialized then begin
        vConfig.FProcessProperty := TProcessProperty.Omit;
      end;
    end;
  end;
end;

function TObjectConfig<T>.Without<Typ>(AProperty: TPropertySelector<T, Typ>): TObjectConfig<T>;
var
  vConfig: TPropertyConfig;
begin
  Result := Self;
  vConfig := GetPropertyFromSelector<Typ>(AProperty);

  if Assigned(vConfig) then begin
    vConfig.FProcessProperty := TProcessProperty.Omit;
  end;
end;

function TObjectConfig<T>.Without<Typ>(AProperty: String): TObjectConfig<T>;
var
  vConfig: TPropertyConfig;
begin
  Result := Self;

  if FProperties.TryGetValue(AProperty.ToUpper, vConfig) then begin
    vConfig.FProcessProperty := TProcessProperty.Omit;
  end;
end;

function TObjectConfig<T>.GetPropertyFromSelector<Typ>(AProperty: TPropertySelector<T, Typ>): TPropertyConfig;
var
  vActualValue: Typ;
  vValue: TValue;
  vIndex: Integer;
  vType: TRttiType;
  vList: TList<TPropertyConfig>;
  vProperty: TPropertyConfig;
begin
  Result := nil;
  vType := FRttiContext.GetType(TypeInfo(Typ));

  if not Assigned(vType) then begin
    raise Exception.Create('Autofixture is unable to get RTTI type information for this type');
  end;

  if not FPropertiesByType.ContainsKey(vType) then begin
    raise Exception.Create('The class ' + Self.FType.Name + ' doesn''t contain any properties with type ' + vType.Name);
  end;

  vActualValue := AProperty(FObject);
  vValue := TValue.From(vActualValue);

  vIndex := GetIndexFromValue(vActualValue);
  vList := FPropertiesByType[vType];

  if vIndex >= 0 then begin
    if vIndex < vList.Count then begin
      vProperty := vList[vIndex];

      if vProperty.FPropertyIdentifier.ToString = vValue.ToString then begin
        Result := vProperty;
        Exit;
      end;
    end;
  end;

  for vIndex := 0 to vList.Count - 1 do begin
    vProperty := vList[vIndex];

    if vProperty.FPropertyIdentifier.ToString = vValue.ToString then begin
        Result := vProperty;
        Exit;
      end;
  end;
end;

function TObjectConfig<T>.WithValue<Typ>(AProperty: TPropertySelector<T, Typ>; AValue: Typ): TObjectConfig<T>;
var
  vConfig: TPropertyConfig;
begin
  Result := Self;

  vConfig := GetPropertyFromSelector<Typ>(AProperty);
  if Assigned(vConfig) then begin
    vConfig.FProcessProperty := TProcessProperty.ValueSet;
    vConfig.FConfiguredPropertyValue := TValue.From(AValue);
  end;
end;

function TObjectConfig<T>.WithValue<Typ>(AProperty: String; AValue: Typ): TObjectConfig<T>;
var
  vConfig: TPropertyConfig;
begin
  Result := Self;

  if FProperties.TryGetValue(AProperty.ToUpper, vConfig) then begin
    vConfig.FProcessProperty := TProcessProperty.ValueSet;
    vConfig.FConfiguredPropertyValue := TValue.From(AValue);

    if vConfig.FConfiguredPropertyValue.isEmpty then begin
      if not Assigned(vConfig.FType) then begin
        raise Exception.Create('Autofixture is unable to get RTTI type information for this type');
      end;
    end;
  end;
end;

{ TCollectionItemGenerator }

constructor TCollectionItemGenerator.Create(AType: TRttiType; APreviousConfig: IObjectGenerator);
var
  ctx: TRttiContext;
begin
  inherited Create(AType, APreviousConfig);

  // Ignore Index and Collection properties
  if FProperties.ContainsKey('INDEX') then begin
    FProperties['INDEX'].FProcessProperty := TProcessProperty.Omit;
  end;

  if FProperties.ContainsKey('COLLECTION') then begin
    FProperties['COLLECTION'].FProcessProperty := TProcessProperty.Omit;
  end;
end;

destructor TCollectionItemGenerator.Destroy;
begin

  inherited;
end;

{ TBaseConfig }

constructor TBaseConfig.Create(AType: TRttiType; APreviousConfig: IObjectGenerator);
begin
  FType := AType;
  FPreviousGenerator := APreviousConfig;
  FProperties := TDictionary<String, TPropertyConfig>.Create;
  FPropertiesByType := TDictionary<TRttiType, TList<TPropertyConfig>>.Create;

  InitProperties;
end;

destructor TBaseConfig.Destroy;
begin
  FreeAndNil(FProperties);
  FreeAndNil(FPropertiesByType);

  inherited;
end;

function TBaseConfig.getObject(AType: TRttiType; AReferenceDepth: Integer): TObject;
var
  vConfig: TPropertyConfig;
  vValue: TValue;
begin
  Result := FType.AsInstance.MetaclassType.Create;

  // Now loop through properties
  for vConfig in Self.FProperties.Values do begin
    vValue := getValue(vConfig.FPropertyName, vConfig.FType);

    if not vValue.IsEmpty then begin
      vConfig.FFieldType.SetValue(Pointer(Result), vValue);
    end
  end;
end;

function TBaseConfig.getValue(aPropertyName: String; aType: TRttiType; AReferenceDepth: integer = -1): TValue;
var
  vConfig: TPropertyConfig;
begin
  Result := TValue.Empty;
  if FProperties.TryGetValue(aPropertyName.ToUpper, vConfig) then begin
    case vConfig.FProcessProperty of
      TProcessProperty.ValueSet: Result := vConfig.FConfiguredPropertyValue;
      TProcessProperty.Uninitialized: Result := FPreviousGenerator.getValue(aPropertyName, aType, AReferenceDepth);
    end;
  end;
end;

end.
