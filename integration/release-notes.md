
## API release notes

The TSD-API is still in beta and the interface is evolving. It is, therefore, difficult to apply semantic versioning to it. For now we just document new features and breaking changes along with a release date.

## 2017-03-27

### New features

- the API now handles file uploads; files can be upload in the following ways:
    - single request `Content-Type: multipart/form-data`
    - multiple ranged requests `Content-Type: multipart/form-data`
    - streaming content with `Transfer-Encoding: chunked`

### Improvements

- synchronous table creation in the storage API
- tables, once created, can be updated with new columns by POSTing an updated definition

### Breaking changes

- new project-level endpoint for getting tokens `/auth`
    - previously, tokens for JSON storage were requested at `/storage/rpc/token`
    - now they are requested at `/auth/import_token`
- tokens returned in dictionaries: `{"token": <token>}` instead of in length-1 arrays: `[{"token": <token>}]`
