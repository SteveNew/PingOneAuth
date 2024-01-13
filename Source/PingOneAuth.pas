unit PingOneAuth;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Controls, Vcl.OleCtrls,
  SHDocVw, Mshtmhst,

  JOSE.Core.JWT,
  JOSE.Core.JWS,
  JOSE.Core.JWK,
  JOSE.Types.JSON;

const
  DOCHOSTUIFLAG_ENABLE_REDIRECT_NOTIFICATION = $04000000;

type
  TBrowserEmulationAdjuster = class
  private
    class function GetExeName(): String; inline;
  public const
    // Source: https://msdn.microsoft.com/library/ee330730.aspx
    IE11_default = 11000;
    IE11_Quirks = 11001;
    IE10_force = 10001;
    IE10_default = 10000;
    IE9_Quirks = 9999;
    IE9_default = 9000;
    IE7_embedded = 7000;
  public
    class procedure SetBrowserEmulationDWORD(const value: DWORD);
  end;

  TOIDCClaims = class(TJWTClaims)
    // Adding some given by the OpenID Connect scope: profile or email
  private
    function GetPreferredUsername: string;
    procedure SetPreferredUsername(const value: string);
    function GetGivenName: string;
    procedure SetGivenName(const value: string);
    function GetFamilyName: string;
    procedure SetFamilyName(const value: string);
    function GetEmail: string;
    procedure SetEmail(const value: string);
  public
    property PreferredUsername: string read GetPreferredUsername write SetPreferredUsername;
    property GivenName: string read GetGivenName write SetGivenName;
    property FamilyName: string read GetFamilyName write SetFamilyName;
    property Email: string read GetEmail write SetEmail;
  end;

  // Claims where to get a unique id for the user from
  // - sub is unique, but not that useable as it neither is known by user or relateable
  // - email would be fine, even extracting the name part, but multiple PingOne users can refer to the same email, so not unique
  // - preferred_username, is unique and what the user identifies as in the login process. So best and default option.
  {$SCOPEDENUMS ON}
  TUserIdClaim = (preferred_username, email, sub);
  {$SCOPEDENUMS OFF}

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TPingOneAuth = class(TWebBrowser, IDocHostUIHandler)
  strict private
    // IDocHostUIHandler "override"
    function GetHostInfo(var pInfo: TDocHostUIInfo): HRESULT; stdcall;
  private
    { Private declarations }
    FEnvironmentId: string;
    FAuthPath: string;
    FClientID: string;
    FClientSecret: string;
    FRedirectUri: string;
    FAuthEndpoint: string;
    FTokenEndpoint: string;
    FScope: string;
    FResponseType: string;
    FAuthCode: string;
    FOIDCToken: string;
    FUserId: string;
    FGreetName: string;
    FUserIdClaim: TUserIdClaim;
    FOnAuthenticated: TNotifyEvent;
    FOnDenied: TNotifyEvent;
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure BeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant;
      var Cancel: WordBool);
    procedure Authorize;
    property OIDCToken: string read FOIDCToken;
    property UserId: string read FUserId write FUserId;
    property GreetName: string read FGreetName write FGreetName;
  published
    { Published declarations }
    property EnvironmentId: string read FEnvironmentId write FEnvironmentId;
    property AuthPath: string read FAuthPath write FAuthPath;
    property ClientId: string read FClientID write FClientID;
    property ClientSecret: string read FClientSecret write FClientSecret;
    property RedirectUri: string read FRedirectUri write FRedirectUri;
    property AuthEndpoint: string read FAuthEndpoint write FAuthEndpoint;
    property TokenEndpoint: string read FTokenEndpoint write FTokenEndpoint;
    property Scope: string read FScope write FScope;
    property ResponseType: string read FResponseType write FResponseType;
    property UserIdClaim: TUserIdClaim read FUserIdClaim write FUserIdClaim;
    property OnAuthenticated: TNotifyEvent read FOnAuthenticated write FOnAuthenticated;
    property OnDenied: TNotifyEvent read FOnDenied write FOnDenied;
  end;

procedure Register;

implementation

uses
  System.NetEncoding,
  System.Net.HTTPClient,
  System.Net.HttpClientComponent,
  System.JSON,
  System.Win.Registry;

procedure Register;
begin
  RegisterComponents('FixedByCode', [TPingOneAuth]);
end;

{ TPingOneAuth }

procedure TPingOneAuth.Authorize;
var
  URL: string;
begin
  URL := FAuthPath + FEnvironmentId + FAuthEndpoint + '?response_type=' + FResponseType + '&client_id=' + FClientID + '&redirect_uri=' +
    TNetEncoding.URL.Encode(FRedirectUri) + '&scope=' + TNetEncoding.URL.Encode(FScope);
  Navigate(URL);
end;

procedure TPingOneAuth.BeforeNavigate2(ASender: TObject; const pDisp: IDispatch;
  const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
var
  uri: string;
  HTTP: TNetHTTPClient;
  lRequestBody: TStringStream;
  lResponse: IHTTPResponse;
  lJSONResponse: TJSONObject;

  LKey: TJWK;
  LToken: TJWT;
  LClaims: TOIDCClaims;
  LSigner: TJWS;
begin
  uri := URL;
  if uri.StartsWith(FRedirectUri + '?code=', True) then
  begin
    // Stop navigation since we are done - just need to get the id_token.
    Self.Stop;
    FOIDCToken := '';
    FAuthCode := uri.Substring(Length(FRedirectUri + '?code='));
    Cancel := True;
    // Call token with code
    lRequestBody := nil;
    lJSONResponse := nil;
    HTTP := TNetHTTPClient.Create(nil);
    try
      // pre-URL encode content
      lRequestBody := TStringStream.Create('grant_type=authorization_code&code=' + FAuthCode + '&redirect_uri=' + FRedirectUri +
        '&client_id=' + FClientID);
      HTTP.ContentType := 'application/x-www-form-urlencoded';
      lResponse := HTTP.Post(FAuthPath + FEnvironmentId + FTokenEndpoint, lRequestBody);
      if lResponse.StatusCode = 200 then
      begin
        lJSONResponse := TJSONObject.ParseJSONValue(lResponse.ContentAsString) as TJSONObject;
        FOIDCToken := lJSONResponse.Values['id_token'].value;
      end;
    finally
      FreeAndNil(HTTP);
      FreeAndNil(lJSONResponse);
      FreeAndNil(lRequestBody);
    end;

    if FOIDCToken <> '' then
    begin
      LKey := TJWK.Create(FClientSecret);
      try
        LToken := TJWT.Create(TOIDCClaims);
        try
          LSigner := TJWS.Create(LToken);
          try
            LSigner.SkipKeyValidation := True;
            LSigner.SetKey(LKey);
            LSigner.CompactToken := FOIDCToken;

            LClaims := LToken.Claims as TOIDCClaims;

            case FUserIdClaim of
              TUserIdClaim.preferred_username: FUserId := LClaims.PreferredUsername;
              TUserIdClaim.email: FUserId := LClaims.Email;
              TUserIdClaim.sub: FUserId := LClaims.Subject;
            end;

            FGreetName := Trim(LClaims.GivenName + ' ' + LClaims.FamilyName);
          finally
            LSigner.Free;
          end;
        finally
          LToken.Free;
        end;
      finally
        LKey.Free;
      end;
      // If we do not get the OpenId Connect profile scope back - we will not know who got autenticated, so...
      if (FUserId <> '') and Assigned(OnAuthenticated) then
        OnAuthenticated(Self);
    end
    else
    begin
      if Assigned(OnDenied) then
        OnDenied(Self);
    end;
    Self.Navigate('about:blank');
  end;
end;

constructor TPingOneAuth.Create(AOwner: TComponent);
begin
  inherited;
  FResponseType := 'code';
  FScope := 'openid profile';
  FUserIdClaim := TUserIdClaim.preferred_username;
  // Due to IE not being supported anymore and lack "correct" handling of strict JS code -
  // use (Edge)WebView2 runtime and deploy WebView2Loader.dll in the bitness required with your application - if possible
  SelectedEngine := TSelectedEngine.EdgeIfAvailable;
  OnBeforeNavigate2 := BeforeNavigate2;
end;

function TPingOneAuth.GetHostInfo(var pInfo: TDocHostUIInfo): HRESULT;
begin
  pInfo.cbSize := SizeOf(pInfo);
  pInfo.dwFlags := 0;
  pInfo.dwFlags := pInfo.dwFlags or DOCHOSTUIFLAG_NO3DBORDER;
  pInfo.dwFlags := pInfo.dwFlags or DOCHOSTUIFLAG_THEME;
  pInfo.dwFlags := pInfo.dwFlags or DOCHOSTUIFLAG_ENABLE_REDIRECT_NOTIFICATION;
  Result := S_OK;
end;

{ TOIDCClaims }

function TOIDCClaims.GetEmail: string;
begin
  Result := TJSONUtils.GetJSONValue('email', FJSON).AsString;
end;

function TOIDCClaims.GetFamilyName: string;
begin
  Result := TJSONUtils.GetJSONValue('family_name', FJSON).AsString;
end;

function TOIDCClaims.GetGivenName: string;
begin
  Result := TJSONUtils.GetJSONValue('given_name', FJSON).AsString;
end;

function TOIDCClaims.GetPreferredUsername: string;
begin
  Result := TJSONUtils.GetJSONValue('preferred_username', FJSON).AsString;
end;

procedure TOIDCClaims.SetEmail(const value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('email', value, FJSON);
end;

procedure TOIDCClaims.SetFamilyName(const value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('family_name', value, FJSON);
end;

procedure TOIDCClaims.SetGivenName(const value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('given_name', value, FJSON);
end;

procedure TOIDCClaims.SetPreferredUsername(const value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('preferred_username', value, FJSON);
end;

{ TBrowserEmulationAdjuster }

class function TBrowserEmulationAdjuster.GetExeName: String;
begin
  Result := TPath.GetFileName(ParamStr(0));
end;

class procedure TBrowserEmulationAdjuster.SetBrowserEmulationDWORD(const value: DWORD);
const
  registryPath = 'Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION';
var
  registry: TRegistry;
  exeName: String;
begin
  exeName := GetExeName();
  registry := TRegistry.Create(KEY_SET_VALUE);
  try
    registry.RootKey := HKEY_CURRENT_USER;
{$WARN SYMBOL_PLATFORM OFF}
    Win32Check(registry.OpenKey(registryPath, True));
{$WARN SYMBOL_PLATFORM ON}
    registry.WriteInteger(exeName, value)
  finally
    registry.Destroy();
  end;
end;

end.
