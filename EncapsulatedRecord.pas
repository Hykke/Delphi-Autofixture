unit EncapsulatedRecord;

interface

type
  IEncapsulatedRecordType = interface
  end;

  TRecordEncapsulation<T: record> = class(TInterfacedObject, IEncapsulatedRecordType)
  private
    FContents: T;
  public
    property Contents: T read FContents write FContents;

    constructor Create(AContents: T);
  end;

implementation

{ TEncapsulation<T> }

constructor TRecordEncapsulation<T>.Create(AContents: T);
begin
  FContents := aContents;
end;

end.
