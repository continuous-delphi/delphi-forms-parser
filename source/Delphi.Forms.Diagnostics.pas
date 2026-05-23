unit Delphi.Forms.Diagnostics;

interface

uses
  Delphi.Forms.Types;

type

  TFormDiagnosticSeverity = (dsError, dsWarning, dsInfo);

  TFormDiagnostic = record
    Severity: TFormDiagnosticSeverity;
    Line: Integer;
    Col: Integer;
    Message: string;
    Code: string;
    constructor Create(ASeverity: TFormDiagnosticSeverity; ALine, ACol: Integer; const AMessage, ACode: string);
  end;

  TParseResult = record
    Form: TFormFile;
    Diagnostics: TArray<TFormDiagnostic>;
    Success: Boolean;
  end;

const
  DiagUnexpectedEndOfInput   = 'DFM001';
  DiagExpectedTokenNotFound  = 'DFM002';
  DiagInvalidValueSyntax     = 'DFM003';
  DiagInvalidBinarySignature = 'DFM004';
  DiagUnknownBinaryValueType = 'DFM005';
  DiagIncompleteHexData      = 'DFM006';
  DiagCharLiteralOutOfRange  = 'DFM007';
  DiagParsedWithRecovery     = 'DFM008';

implementation

{ TFormDiagnostic }

constructor TFormDiagnostic.Create(ASeverity: TFormDiagnosticSeverity; ALine, ACol: Integer; const AMessage, ACode: string);
begin
  Severity := ASeverity;
  Line := ALine;
  Col := ACol;
  Message := AMessage;
  Code := ACode;
end;

end.
