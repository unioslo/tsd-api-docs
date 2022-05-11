
# 3rd Party OIDC


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
