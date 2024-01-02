unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls, Vcl.OleCtrls, SHDocVw, PingOneAuth;

type
  TForm6 = class(TForm)
    leAuthEndPoint: TLabeledEdit;
    leAuthPath: TLabeledEdit;
    leClientId: TLabeledEdit;
    leClientSecret: TLabeledEdit;
    leEnvironmentId: TLabeledEdit;
    leRedirectUri: TLabeledEdit;
    leResponseType: TLabeledEdit;
    leScope: TLabeledEdit;
    leTokenEndpoint: TLabeledEdit;
    btnAuth: TButton;
    PingOneAuth: TPingOneAuth;
    procedure btnAuthClick(Sender: TObject);
    procedure PingOneAuthAuthenticated(Sender: TObject);
    procedure PingOneAuthDenied(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

procedure TForm6.btnAuthClick(Sender: TObject);
begin
  // Setting properties
  PingOneAuth.AuthEndpoint := leAuthEndPoint.Text;
  PingOneAuth.AuthPath := leAuthPath.Text;
  PingOneAuth.ClientId := leClientId.Text;
  PingOneAuth.ClientSecret := leClientSecret.Text;
  PingOneAuth.EnvironmentId := leEnvironmentId.Text;
  PingOneAuth.RedirectUri := leRedirectUri.Text;
  PingOneAuth.ResponseType := leResponseType.Text;
  PingOneAuth.Scope := leScope.Text;
  PingOneAuth.TokenEndpoint := leTokenEndpoint.Text;
  // Might set Callbacks events at runtime
//  PingOneAuth.OnAuthorized :=
//  PingOneAuth.OnDenied :=
  // Authorize
  PingOneAuth.Authorize;
end;

procedure TForm6.PingOneAuthAuthenticated(Sender: TObject);
begin
  ShowMessage('Welcome '+PingOneAuth.GreetName+'!'+sLineBreak+sLineBreak+'You have be authenticated as userId: '+PingOneAuth.UserId);
end;

procedure TForm6.PingOneAuthDenied(Sender: TObject);
begin
  ShowMessage('You have not been authenticated!');
end;

end.
