unit AutoFixtureSetup;

interface

type
{$SCOPEDENUMS ON}

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

implementation

{ TAutofixtureSetup }
constructor TAutofixtureSetup.Create;
begin
  Self.FReferenceDepth := 3;
  Self.FCollectionSize := 3;
  Self.FAutoDetectList := True;
  Self.FAutoDetectDictionary := True;
  Self.FConstructorSearch := TConstructorSearch.csSimplest;
end;

end.
