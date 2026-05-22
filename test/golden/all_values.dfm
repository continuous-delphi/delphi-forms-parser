object frmAllValues: TfrmAllValues
  Left = 0
  Top = 0
  Caption = 'All Value Types'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  Visible = True
  Anchors = [akLeft, akTop, akRight, akBottom]
  DesignSize = (
    800
    600)
  HexColor = $00FF8040
  NegativeTop = -15
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 784
    Height = 584
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      'Line 1'
      'Line 2'
      'Line 3')
    ScrollBars = ssBoth
    TabOrder = 0
  end
end
