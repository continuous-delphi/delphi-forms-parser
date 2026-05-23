unit Delphi.Forms.Types;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type

  TObjectKind = (okObject, okInherited, okInline);

  TFormValueKind = (
    fvInteger,
    fvFloat,
    fvString,
    fvBoolean,
    fvIdentifier,
    fvSet,
    fvBinary,
    fvList,
    fvCollection
  );

  TFormValue = class;
  TFormProperty = class;
  TFormObject = class;

  TFormValueList = TObjectList<TFormValue>;
  TFormPropertyList = TObjectList<TFormProperty>;
  TFormObjectList = TObjectList<TFormObject>;

  TFormValue = class
  public
    Kind: TFormValueKind;
    SourceStart: Integer;
    SourceEnd: Integer;
    IntValue: Int64;
    FloatValue: Extended;
    StringValue: string;
    BoolValue: Boolean;
    IdentValue: string;
    SetItems: TArray<string>;
    BinaryData: TBytes;
    ListItems: TFormValueList;
    CollectionItems: TFormObjectList;
    RawText: string;
    OriginalValueType: Byte;
    ExtendedRawBytes: TBytes;
    constructor Create(AKind: TFormValueKind);
    destructor Destroy; override;
  end;

  TFormProperty = class
  public
    Name: string;
    Value: TFormValue;
    SourceStart: Integer;
    SourceEnd: Integer;
    constructor Create(const AName: string; AValue: TFormValue);
    destructor Destroy; override;
  end;

  TFormObject = class
  public
    ObjectKind: TObjectKind;
    Name: string;
    ClassName_: string;
    ItemIndex: Int64;
    SourceStart: Integer;
    SourceEnd: Integer;
    Parent: TFormObject;
    Properties: TFormPropertyList;
    Children: TFormObjectList;
    constructor Create;
    destructor Destroy; override;
  end;

  TFormFile = class
  public
    Root: TFormObject;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TFormValue }

constructor TFormValue.Create(AKind: TFormValueKind);
begin
  inherited Create;
  Kind := AKind;
  SourceStart := -1;
  SourceEnd := -1;
  case AKind of
    fvList:
      ListItems := TFormValueList.Create;
    fvCollection:
      CollectionItems := TFormObjectList.Create;
  end;
end;

destructor TFormValue.Destroy;
begin
  ListItems.Free;
  CollectionItems.Free;
  inherited;
end;

{ TFormProperty }

constructor TFormProperty.Create(const AName: string; AValue: TFormValue);
begin
  inherited Create;
  Name := AName;
  Value := AValue;
  SourceStart := -1;
  SourceEnd := -1;
end;

destructor TFormProperty.Destroy;
begin
  Value.Free;
  inherited;
end;

{ TFormObject }

constructor TFormObject.Create;
begin
  inherited Create;
  ItemIndex := -1;
  SourceStart := -1;
  SourceEnd := -1;
  Properties := TFormPropertyList.Create;
  Children := TFormObjectList.Create;
end;

destructor TFormObject.Destroy;
begin
  Children.Free;
  Properties.Free;
  inherited;
end;

{ TFormFile }

constructor TFormFile.Create;
begin
  inherited Create;
end;

destructor TFormFile.Destroy;
begin
  Root.Free;
  inherited;
end;

end.
