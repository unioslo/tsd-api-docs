
# TSD API: architecture and protocols

The TSD API design outlines a secure multi-tenant HTTP API with event-driven integration points, suitable for deployment in Trusted Research Environments (TREs).

## Component overview

TREs are typically deployed with their own networks which are protected by firewalls, and TSD is no exception in this regard. The figure below shows the overall API design.

_insert figure_

Users interact with clients (web services) which in turn connect to application servers (which implement business logic) via proxies. There are two proxies: 1) an external proxy, which has a connection to the network outside of the TRE's perimiter, and the internal network, and 2) an internal proxy, which has access to the management network in the TRE and tenant subnets, where researchers' virtual machines are deployed. The proxies expose services to clients (and users) without exposing them to untrusted networks.

## Authentication

All service data are exposed via HTTP API endpoints implemented by app servers. All API endpoints are protected by access control, which means that all API calls must be authorized - i.e. the API has to determine whether the user is allowed to perform a given action with the given data. Authenticating the user, and the client, is therefore a prerequisite for request authorization.

_insert figure_

To authenticate users, TSD uses the OpenID Connect protocol, either with its own OIDC provider, or with third-party OIDC providers. Third-party OIDC providers integrated on a case-by-case basis.


## Authorization

## Resource requests

## Event-driven integrations
