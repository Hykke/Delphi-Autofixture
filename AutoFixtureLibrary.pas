unit AutoFixtureLibrary;

interface

uses
  RTTI,
  AutoFixtureSetup;

type
  TAutofixtureLibrary = class
    class procedure GetMethods(ASetup: TAutofixtureSetup; AType: TRttiType; var vConstructor: TRttiMethod; var vAddMethod: TRttiMethod);
  end;

implementation

{ TAutofixtureLibrary }

class procedure TAutofixtureLibrary.GetMethods(ASetup: TAutofixtureSetup; AType: TRttiType; var vConstructor, vAddMethod: TRttiMethod);
var
  vMethod: TRttiMethod;
begin
  vConstructor := nil;
  vAddMethod := nil;
  if ASetup.ConstructorSearch = TConstructorSearch.csSimplest then begin
    // Find simplest constructor deklareret i klassen
    for vMethod in AType.GetMethods do begin
      if vMethod.IsConstructor then begin
        if Assigned(vConstructor) then begin
          // don't shift to parent class constructor once class constructor found
          if vMethod.Parent = AType then begin
            if vConstructor.Parent = AType then begin
              if Length(vMethod.GetParameters) < Length(vConstructor.GetParameters) then begin
                vConstructor := vMethod;
              end;
            end
            else begin
              vConstructor := vMethod;
            end;
          end
          else begin
            if vConstructor.Parent <> AType then begin
              if Length(vMethod.GetParameters) < Length(vConstructor.GetParameters) then begin
                vConstructor := vMethod;
              end;
            end;
          end;
        end
        else begin
          vConstructor := vMethod;
        end;
      end
      else if vMethod.Name = 'Add' then begin
        if Assigned(vAddMethod) then begin
          if (vMethod.Parent = AType) and (vAddMethod.Parent <> AType) then begin
            vAddMethod := vMethod;
          end;
        end
        else begin
          vAddMethod := vMethod;
        end;
      end;
    end;
  end
  else if ASetup.ConstructorSearch = TConstructorSearch.csMostParams then begin
    // Find constructor with many params
    for vMethod in AType.GetDeclaredMethods do begin
      if vMethod.IsConstructor then begin
        if Assigned(vConstructor) then begin
          if Length(vMethod.GetParameters) > Length(vConstructor.GetParameters) then begin
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
  else begin
    // Find only add method
    for vMethod in AType.GetDeclaredMethods do begin
      if vMethod.Name = 'Add' then begin
        vAddMethod := vMethod;
      end;
    end;
  end;
end;


end.
