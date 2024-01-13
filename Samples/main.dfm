object Form6: TForm6
  Left = 0
  Top = 0
  Caption = 'PingAuthTest'
  ClientHeight = 431
  ClientWidth = 803
  Color = clSkyBlue
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  DesignSize = (
    803
    431)
  TextHeight = 15
  object leAuthEndPoint: TLabeledEdit
    Left = 8
    Top = 24
    Width = 129
    Height = 23
    EditLabel.Width = 77
    EditLabel.Height = 15
    EditLabel.Caption = 'AuthEndPoint:'
    TabOrder = 0
    Text = '/as/authorize'
  end
  object leAuthPath: TLabeledEdit
    Left = 8
    Top = 67
    Width = 161
    Height = 23
    EditLabel.Width = 53
    EditLabel.Height = 15
    EditLabel.Caption = 'AuthPath:'
    TabOrder = 1
    Text = 'https://auth.pingone.eu/'
  end
  object leClientId: TLabeledEdit
    Left = 8
    Top = 112
    Width = 225
    Height = 23
    EditLabel.Width = 44
    EditLabel.Height = 15
    EditLabel.Caption = 'ClientId:'
    TabOrder = 2
    Text = ''
  end
  object leClientSecret: TLabeledEdit
    Left = 8
    Top = 160
    Width = 465
    Height = 23
    EditLabel.Width = 66
    EditLabel.Height = 15
    EditLabel.Caption = 'ClientSecret:'
    PasswordChar = '*'
    TabOrder = 3
    Text = ''
  end
  object leEnvironmentId: TLabeledEdit
    Left = 8
    Top = 203
    Width = 225
    Height = 23
    EditLabel.Width = 81
    EditLabel.Height = 15
    EditLabel.Caption = 'EnvironmentId:'
    TabOrder = 4
    Text = ''
  end
  object leRedirectUri: TLabeledEdit
    Left = 8
    Top = 251
    Width = 129
    Height = 23
    EditLabel.Width = 61
    EditLabel.Height = 15
    EditLabel.Caption = 'RedirectUri:'
    TabOrder = 5
    Text = 'http://localhost:5555/'
  end
  object leResponseType: TLabeledEdit
    Left = 8
    Top = 299
    Width = 129
    Height = 23
    EditLabel.Width = 77
    EditLabel.Height = 15
    EditLabel.Caption = 'ResponseType:'
    TabOrder = 6
    Text = 'code'
  end
  object leScope: TLabeledEdit
    Left = 8
    Top = 344
    Width = 129
    Height = 23
    EditLabel.Width = 35
    EditLabel.Height = 15
    EditLabel.Caption = 'Scope:'
    TabOrder = 7
    Text = 'openid profile'
  end
  object leTokenEndpoint: TLabeledEdit
    Left = 8
    Top = 392
    Width = 129
    Height = 23
    EditLabel.Width = 82
    EditLabel.Height = 15
    EditLabel.Caption = 'TokenEndpoint:'
    TabOrder = 8
    Text = '/as/token'
  end
  object btnAuth: TButton
    Left = 304
    Top = 16
    Width = 169
    Height = 49
    Caption = 'Authenticate using PingIdentity'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 9
    WordWrap = True
    OnClick = btnAuthClick
  end
  object PingOneAuth: TPingOneAuth
    Left = 495
    Top = 8
    Width = 300
    Height = 415
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 10
    SelectedEngine = EdgeIfAvailable
    Scope = 'openid profile'
    ResponseType = 'code'
    UserIdClaim = preferred_username
    OnAuthenticated = PingOneAuthAuthenticated
    OnDenied = PingOneAuthDenied
    ControlData = {
      4C000000021F0000E42A00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
end
