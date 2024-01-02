unit PingOneAuth;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.OleCtrls, SHDocVw, Mshtmhst,

  JOSE.Core.JWT,
  JOSE.Core.JWS,
  JOSE.Core.JWK,
  JOSE.Types.JSON;

const
  DOCHOSTUIFLAG_ENABLE_REDIRECT_NOTIFICATION = $04000000;

type
  TPingOneClaims = class(TJWTClaims)
  // Adding some given by the OpenID Connect scope: profile
  private
    function GetPreferredUsername: string;
    procedure SetPreferredUsername(const Value: string);
    function GetGivenName: string;
    procedure SetGivenName(const Value: string);
    function GetFamilyName: string;
    procedure SetFamilyName(const Value: string);

  public
    property PreferredUsername: string read GetPreferredUsername write SetPreferredUsername;
    property GivenName: string read GetGivenName write SetGivenName;
    property FamilyName: string read GetFamilyName write SetFamilyName;
  end;

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
    FUserIdClaim: string;
    FOnAuthorized: TNotifyEvent;
    FOnDenied: TNotifyEvent;
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure BeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
    procedure Authorize;
    property OIDCToken: string read FOIDCToken;
    property UserId: string read FUserId write FUserId;
    property GreetName: string read FGreetName write FGreetName;
  published
    { Published declarations }
    property EnvironmentId: string read FEnvironmentId write FEnvironmentId;
    property AuthPath: string read FAuthPath write FAuthPath;
    property ClientId: string read FClientID write FClientId;
    property ClientSecret: string read FClientSecret write FClientSecret;
    property RedirectUri: string read FRedirectUri write FRedirectUri;
    property AuthEndpoint: string read FAuthEndpoint write FAuthEndpoint;
    property TokenEndpoint: string read FTokenEndpoint write FTokenEndpoint;
    property Scope: string read FScope write FScope;
    property ResponseType: string read FResponseType write FResponseType;
    property UserIdClaim: string read FUserIdClaim write FUserIdClaim;
    property OnAuthorized: TNotifyEvent read FOnAuthorized write FOnAuthorized;
    property OnDenied: TNotifyEvent read FOnDenied write FOnDenied;
  end;

procedure Register;

implementation

uses
  System.NetEncoding,
  System.Net.HTTPClient,
  System.Net.HttpClientComponent,
  System.Json;

procedure Register;
begin
  RegisterComponents('FixedByCode', [TPingOneAuth]);
end;

{ TPingOneAuth }

procedure TPingOneAuth.Authorize;
var
  url: string;
begin
  url := FAuthPath+FEnvironmentId+FAuthEndpoint+'?response_type='+FResponseType+'&client_id='+FClientID+'&redirect_uri='+TNetEncoding.URL.Encode(FRedirectUri)+'&scope='+TNetEncoding.URL.Encode(FScope);
  Navigate(url);
end;

procedure TPingOneAuth.BeforeNavigate2(ASender: TObject; const pDisp: IDispatch;
  const URL, Flags, TargetFrameName, PostData, Headers: OleVariant;
  var Cancel: WordBool);
var
  uri: string;
  HTTP: TNetHTTPClient;
  lRequestBody: TStringStream;
  lResponse: IHTTPResponse;
  lJSONResponse: TJSONObject;

  LKey: TJWK;
  LToken: TJWT;
  LClaims: TPingOneClaims;
  LSigner: TJWS;
begin
  uri := URL;
  if uri.StartsWith(FRedirectUri+'?code=', True) then
  begin
    // Stop navigation since we are done - just need to get the id_token.
    Self.Stop;
    FOIDCToken := '';
    FAuthCode := uri.Substring(Length(FRedirectUri+'?code='));
    Cancel := True;
    // Call token with code
    lRequestBody := nil;
	  lJSONResponse := nil;
    HTTP := TNetHTTPClient.Create(nil);
    try
      // pre-URL encode content
      lRequestBody := TStringStream.Create
        ('grant_type=authorization_code&code='+FAuthCode+'&redirect_uri='+FRedirectUri+'&client_id='+FClientID);
      HTTP.ContentType := 'application/x-www-form-urlencoded';
      lResponse := HTTP.Post(FAuthPath+FEnvironmentId+FTokenEndpoint, lRequestBody);
      if lResponse.StatusCode = 200 then
      begin
        lJSONResponse := TJSONObject.ParseJSONValue(lResponse.ContentAsString) as TJSONObject;
        FOIDCToken := LJSONResponse.Values['id_token'].Value;
      end;
    finally
      FreeAndNil(HTTP);
      FreeAndNil(lJSONResponse);
      FreeAndNil(lRequestBody);
    end;

    if FOIDCToken<>'' then
    begin
      LKey := TJWK.Create(FClientSecret);
      try
        LToken := TJWT.Create(TPingOneClaims);
        try
          LSigner := TJWS.Create(LToken);
          try
            LSigner.SkipKeyValidation := True;
            LSigner.SetKey(LKey);
            LSigner.CompactToken := FOIDCToken;

            LClaims := LToken.Claims as TPingOneClaims;
            FUserId := LClaims.PreferredUsername;
            FGreetName := LClaims.GivenName+' '+LClaims.FamilyName;
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
      if (FUserId<>'') and Assigned(OnAuthorized) then
        OnAuthorized(Self);
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
  FUserIdClaim := 'preferred_username';
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

{ TPingOneClaims }

function TPingOneClaims.GetFamilyName: string;
begin
  Result := TJSONUtils.GetJSONValue('family_name', FJSON).AsString;
end;

function TPingOneClaims.GetGivenName: string;
begin
  Result := TJSONUtils.GetJSONValue('given_name', FJSON).AsString;
end;

function TPingOneClaims.GetPreferredUsername: string;
begin
  Result := TJSONUtils.GetJSONValue('preferred_username', FJSON).AsString;
end;

procedure TPingOneClaims.SetFamilyName(const Value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('family_name', Value, FJSON);
end;

procedure TPingOneClaims.SetGivenName(const Value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('given_name', Value, FJSON);
end;

procedure TPingOneClaims.SetPreferredUsername(const Value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('preferred_username', Value, FJSON);
end;

end.
