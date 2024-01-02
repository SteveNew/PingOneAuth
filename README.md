# TPingOneAuth
## Delphi Auth component for the PingOne Platform API

This is a TWebBrowser decendant handling the Authentication process against the PingOne IAM platform - including MFA.

![AuthTest1](https://github.com/SteveNew/PingOneAuth/assets/1895619/b16c2ba6-b6c8-4873-82bf-7ba68a7fc46d)

The purpose is only to get the userId and a full name for greetings - from an OpenID Connect Auth process - so that this info can be used to give a more secure and correct authentication compared to a single application-centric user authentication.

Prerequisite:
Delphi JOSE and JWT Library: https://github.com/paolo-rossi/delphi-jose-jwt

The following properties needs to be set on the component - sample values shown:

- AuthEndpoint: /as/authorize
- AuthPath: https://auth.pingone.eu/
- ClientId:
- ClientSecret:
- EnvironmentId:
- RedirectUri:
- ResponseType: code
- Scope: openid profile
- TokenEndpoint: /as/token
- UserIdClaim: preferred_username (currently ignored)

Event added apart from the normal TWebBrowser ones:

- OnAuthenticated - fires when successfull authenticated
- OnDenied - fires when no valid id_token is obtained

An Authorize method is call to start the process after the properties are set. After sucessfull authentication (which might use MFA), the public properties Userid and GreetName are set.

There is a companion blog post: https://fixedbycode.blogspot.com/2024/01/just-ping-someone.html

This is still a first working version.

/Enjoy
