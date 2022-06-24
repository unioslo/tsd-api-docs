
# Client registration

To register an API client, or to manage client credentials please [contact TSD](https://www.uio.no/english/services/it/research/sensitive-data/contact/). This will soon be available via our self-service portal.

### Renewing your client secret

Once you have a client, you will have a client ID and a client secret. The secrect, the API key, is valid for a year. It is JWT, which can be decoded to check the expiry in your application. To renew it, do:

```txt
POST /v1/p11/auth/clients/secret

{
    "client_id": <your-client-id>,
    "client_secret": <your-current-secret>
}
```

# Authentication and authorization

The TSD API offers multiple protocols for clients to authenticate themselves and users and to obtain authorization for API access by way of access tokens. These protocols leverages the OAuth2.0, OpenID Connect, and JWT standards.

### Token requests

To use TSD's APIs your client must obtain access tokens. Each access token grants the client access to a subset of the TSD API. The methods available for obtaining access tokens can be divided into two classes: 1) direct access token requests, and 2) token exhange.

Direct access token requests make a single API call, providing either client credentials, or a combination of client and user credentials to obtain a specific access token. Authentication and authorization are preformed in a single step. These methods are:

* basic auth
* instance auth
* two-factor auth

```txt
client ---> credentials ---> auth-api
       <--- access_token, refresh_token
```

Token exchange involves a separate integration with one of the supported OIDC providers:

* TSD
* Idporten
* Dataporten
* Elixir

```txt
client ---> OIDC flow ---> oidc-provider
       <--- id_token
client ---> id_token ---> auth-api
       <--- access_token, refresh_token
```

Upon successful user authentication with one of these providers, the client can exchange the resulting ID token for an API access token. Token enrichment also falls into this class of access token requests.

### Token response

```json
{
    "token": "...",
    "refresh_token": "..."
}
```

### Access tokens

TSD has pre-defined access tokens which give clients specific access to parts of the API. To investigate which access tokens are available, for a given authentication method, do:

```txt
GET /v1/p11/auth/tokens/info
```

Note: you do not need a registered client to view this information. The token is a JWT with the following claims:


* `exp`, _int_, unix timestamp, token expiry
* `iat`, _int_, unix timestamp, token issued at
* `nonce`, _str_, unique random string
* `aud`, _str_, audience, the client ID
* `iss`, _str_, issuer, `tsd.usit.no`
* `proj`, _str_, project, the project for which the signature is valid
* `u`, _str_, md5 hash of user agent
* `r`, _str_, md5 hash of remote IP
* `pid`, _str_, TSD person ID
* `user`, _str_, TSD user name used during authentication
* `name`, _str_, name of the token type
* `host`, _str_, API host for which the token is valid
* `pnr`, _str_, norwegian personal number
* `groups`, _array_, group memberships
* `accounts`, _array_, all users belonging to the person
* `ext_sub`, _map_, `sub` claim originating from ID token (used in token exchange)
* `instance_id`, _str_, unique random string (used in capability URLs)
* `apps`, _array_, list of apps owned by the client
* `path`, _str_, path on remote file system (used in capability URLs)
* `role`, _str_, token specific role

Such JWTs are symmetrically signed with project specific secrets using HMAC-SHA256.

### Refresh tokens

Refresh tokens are returned in the response of token requests, if 1) the client has been authorized to obtain refresh tokens, and 2) if the token type is refreshable. The token is a JWT with the following claims:

* `exp`, _int_, unix timestamp, token expiry
* `iat`, _int_, unix timestamp, token issued at
* `iss`, _str_, issuer, `tsd.usit.no`
* `rid`, _str_, refresh ID, unique random string
* `counter`, _int_, decrementing amount of times the token can be refreshed

Such JWTs are symmetrically signed with project specific secrets using HMAC-SHA256. To use a refresh token to get a new access token:

```txt
POST /v1/p11/auth/refresh/token

{
    "refresh_token": "..."
}
```

# Direct access token requests

### Basic authentication

Using just the API key, you can get a short-lived access token that will allow your application to import data to TSD, for the project which you have authorization.

```txt
POST /v1/p11/auth/basic/token?type=<token_type>
Authorization: Bearer $apikey
```

Because basic authentication has a low level of assurance, we require that your app runs on a host with a fixed IP address/range.


### Instance based authentication

Instances are a mechanism that enables projects to create unique identifiers used to allow you to obtain a specific token type in TSD. Optionally the instance can be protected by a secret challenge provided to the person that will use the link. The instances are created on the [self-service website](https://selfservice.tsd.usit.no). To get an access token for a specific project:

```txt
POST /v1/all/auth/instances/token?type=<token_type>
Authorization: Bearer $apikey

{
    "id": "...",
    ("secret_challenge": "...")?
}
```

The secret_challenge is optional, it's usage being mandated by the particulars of the instance (or import link).

### TSD Two-Factor authentication

To get a token:

```txt
POST /v1/p11/auth/tsd/token?type=<type>
Authorization: Bearer $apikey

{
    "user_name":"p11-test",
    "otp":"453627",
    "password": "dhfbjhb"
}
```

# Indirect access token requests

### TSD OIDC

Having obtained an ID token with TSD OIDC, clients must exchange this for access tokens to interact with TSD's other APIs, as such.

```txt
POST /v1/p11/auth/tsdoidc/token?type=<type>
Authorization: Bearer $apikey

{
    "idtoken": "...",
}
```

### ID-porten authentication

Using an external identity provider like [ID-porten](http://eid.difi.no/en/id-porten), with OIDC, allows your application to do identity bridging with TSD.

Once you have registered your application with ID-porten, you will be able to obtain ID tokens. You can send these ID tokens to TSD, to get a TSD access token for a specific project:

```txt
POST /v1/p11/auth/difi/token?type=<type>
Authorization: Bearer $apikey

{
    "idtoken": "...",
}
```

### Dataporten authentication

Using an external identity provider like [Dataporten/Feide](https://docs.feide.no/index.html), with OIDC, allows your application to do identity bridging with TSD.

Once you have registered your application with Dataporten, you will be able to obtain ID tokens. You can send these ID tokens to TSD, to get a TSD access token for a specific project:

```txt
POST /v1/p11/auth/dataporten/token?type=<type>
Authorization: Bearer $apikey

{
    "idtoken": "...",
}
```

### Token Enrichment

The token enrichment is a mechanism to enrich your token with additional claims. This is useful when e.g.: 1) additional information becomes availablle for the identity in question or 2) when you want add to the token claims from another token. To enrich a token:

```txt
POST /v1/p11/auth/enrich/token?type=<token_type>
Authorization: Bearer $apikey

{
    "token": "..."
}
```

or to merge:

```txt
POST /v1/p11/auth/enrich/token?type=<token_type>
Authorization: Bearer $apikey

{
    "token": "...",
    "merge_with": "..."
}
```
