object frmNested: TfrmNested
  Left = 0
  Top = 0
  Caption = 'Nested Form'
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 400
    Height = 300
    Caption = 'Panel'
    object Button1: TButton
      Left = 16
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Click Me'
      OnClick = Button1Click
    end
    object Label1: TLabel
      Left = 16
      Top = 50
      Width = 50
      Height = 15
      Caption = 'Status:'
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 320
    Width = 420
    Height = 19
  end
end
