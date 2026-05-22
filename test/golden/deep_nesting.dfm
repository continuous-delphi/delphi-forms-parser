object frmDeep: TfrmDeep
  Caption = 'Deep Nesting Test'
  object Level1: TPanel
    Caption = 'L1'
    object Level2: TPanel
      Caption = 'L2'
      object Level3: TPanel
        Caption = 'L3'
        object Level4: TPanel
          Caption = 'L4'
          object Level5: TPanel
            Caption = 'L5'
            object Level6: TPanel
              Caption = 'L6'
              object Level7: TPanel
                Caption = 'L7'
                object Level8: TPanel
                  Caption = 'L8'
                  object Level9: TPanel
                    Caption = 'L9'
                    object Level10: TPanel
                      Caption = 'L10'
                      object Level11: TPanel
                        Caption = 'L11'
                        object Leaf: TButton
                          Caption = 'Deepest'
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
