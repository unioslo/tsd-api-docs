
# Survey API

_Writing_ to the survey API is reserved for Nettskjema usage. Other clients may _read_ from it. If you would like to create an app utilising the functionality of the survey API, the apps API is the right place to look, since it provides the exact same capabilities.

### Endpoints

The following endpoints are available:

```txt
/v1/p11/survey
/v1/p11/survey/{formid}
/v1/p11/survey/{formid}/activated
/v1/p11/survey/{formid}/status
/v1/p11/survey/{formid}/submissions
/v1/p11/survey/{formid}/metadata
/v1/p11/survey/{formid}/audit
/v1/p11/survey/{formid}/attachments
/v1/p11/survey/crypto/key
/v1/p11/survey/resumables
```

The following sections will explain how to use them. We will use a hypothetical formid `1234`.

### Access tokens

There are three different access tokens:

1. `survey_import` - basic and TSD auth
2. `survey_export` - TSD auth
3. `survey_admin` - TSD auth
4. `survey_member` - TSD auth (available inside TSD)

Their use will be demonstrated in the examples below.

### Form activation/deactivation

Before being able to send data to a form, the form must be activated for a given project. To do this, clients obtain a survey token, with end user authentication, using TSD credentials, and:

```txt
PUT /v1/p11/survey/1234/activated
Authorization: Bearer $survey_import
```

To revoke the ability to deliver data to a form:

```txt
DELETE /v1/p11/survey/1234/activated
Authorization: Bearer $survey_admin
```

To check if a form is activated or not:

```txt
GET /v1/p11/survey/1234/status
Authorization: Bearer $survey_import
```

If the form is active:
```json
{"formid": "121113", "status": "active"}
```

If the form is inactive:
```json
{"formid": "121113", "status": "inactive"}
```

### Queries

Before showing examples working with JSON data, it is necessary to understand the URI query language offered by the API. Suppose you sent the following data to a form (each entry of the array being sent in a different request):

```json
[
    {
        "metaData": {"submission_id": 1, "timestamp": "2020-10-13T10:15:26.388573"},
        "data": [
            {"code": 0, "variable": "ans1", "text": "no", "degree": 5},
            {"code": 1, "variable": "ans2", "text": "bla"},
            {"code": 2, "variable": "ans3", "text": "yes", "degree": 3},
        ]
    },
    {
        "metaData": {"submission_id": 2, "timestamp": "2020-10-13T11:33:10.360211"},
        "data": [
            {"code": 1, "variable": "ans1", "text": "no", "degree": 10},
            {"code": 2, "variable": "ans2", "text": "bla"}
        ]
    },
    {
        "metaData": {"submission_id": 3, "timestamp": "2020-10-13T20:40:26.208001"},
        "data": [
           {"code": 0, "variable": "ans1", "text": "no", "degree": 1}
       ]
    }
]
```

#### Key filtering

To filter key, one can use the `select` clause.

Only `metaData`:
```txt
?select=metaData
```
Only `data`:
```txt
?select=data
```
One specific key, inside all array elements in `data`:
```txt
?select=data[*|variable]
```
Two keys, inside one array element in `data`:
```txt
?select=data[1|variable,degree]
```

#### Row filtering

To filter rows, one can use the `where` clause.

A row with a specific `submission_id`, nested inside the `metaData` key:
```txt
?where=metaData.submission_id=eq.1
```
With a pattern match, broadcasting over all elements in the `data` key's array:
```txt
?where=data[0|variable]=like.ans*
```
Combining with `and` and `or`:
```txt
?where=(data[0|variable]=like.ans*,or:data[0|degree]=gt.4),and:data[1|code]=not.is.null
```

The full operator list for `where` filtering is:

* `and` - `and`
* `or` - `or`
* `eq` - `=`
* `gt` - `>`
* `gte` - `>=`
* `lt` - `<`
* `lte` - `<=`
* `neq` - `!=`
* `like` - `like`
* `ilike` - `ilike`
* `not` - `not`
* `is` - `is`
* `in` - `in`

#### Ordering

To control the order of results:
```txt
order=metaData.submission_id.desc
```

#### Paginating

To control which rows are being returned from the relevant set:
```txt
range=1.2
```

#### Aggregation

Client can perform the following aggregation function on data:
* `count` - the number of entries in a selection
* `avg` - geomertic average
* `min` - minimum numeric value
* `max` - maximum numeric value
* `sum` - sum of numeric values
* `min_ts` - minimum timestamp or date
* `max_ts` - maximum timestamp or date

For example, to get the number of table entries, along with the timestamp of the most recent entry:

```txt
?select=count(*),max_ts(metaData.timestamp)
```

### JSON data

To send JSON data, clients can simply do:

```txt
PUT /v1/p11/survey/1234/submissions
Authorization: Bearer $survey_import

{...}
```
Schemas are agreed upon between TSD and Nettskjema.

To update data, use the query functionality to isolate the entry, and send the new row in its entirety:

```txt
PATCH /v1/p11/survey/1234/submissions?set=data&where=metaData.submission_id=eq.1
Authorization: Bearer $survey_import

{data: [...]}
```
Such operations are recorded in the audit log.

To get data:

```txt
GET /v1/p11/survey/1234/submissions?select=data[*|variable]&where=data[0|degree]=gt.4
Authorization: Bearer $survey_export
```

To delete data:

```txt
DELETE /v1/p11/survey/1234/submissions?where=metaData.submission_id=eq.1
Authorization: Bearer $survey_admin
```

### JSON metadata

Schemas are agreed upon between TSD and Nettskjema. The `/metadata` endpoint functions in the exact same way as the `/submissions` endpoint. Using it, clients can associate arbitrary metadata with a form.

### JSON audit

The API keeps track of all changes made to JSON form data. Client can retrieve such information:

```txt
GET /v1/p11/survey/1234/audit
Authorization: Bearer $survey_export
```

### Files

To upload a file, hypothetically named `interview.txt`:

```txt
PUT /v1/p11/survey/1234/attachments/interview.txt
Authorization: Bearer $survey_import

All the interview data...
```

There is a 5GB limit on size, when using this method, and note this is _not_ `multipart/form-data`, clients should send the file contents byte-per-byte.

To list files:

```txt
GET /v1/p11/survey/1234/attachments
Authorization: Bearer $survey_export
```

To get a file:

```txt
GET /v1/p11/survey/1234/attachments/interview.txt
Authorization: Bearer $survey_export
```

To delete a file:

```txt
DELETE /v1/p11/survey/1234/attachments/interview.txt
Authorization: Bearer $survey_admin
```

### Resumable uploads

The client, having chunked the file, starts by initiating a PATCH, uploading the first chunk:

```txt
PATCH /v1/p11/survey/1234/attachments/filename?chunk=1
Authorization: Bearer $survey_import

{
    filename: str,
    max_chunk: int,
    id: uuid
}
```

Using the UUID returned by the server in the response, the client can continue sending succesive chunks, in sequence:

```txt
PATCH /v1/p11/survey/1234/attachments/filename?chunk=<num>&id=<UUID>
Authorization: Bearer $survey_import

{
    filename: str,
    max_chunk: int,
    id: uuid
}
```

To finish the upload the client must explicitly indicate that the upload is finished by sending an empty request as such:

```txt
PATCH /v1/p11/survey/1234/attachments/filename?chunk=end&id=<UUID>
Authorization: Bearer $survey_import
```

To get an overview of uploads which can be resumed:

```txt
GET /v1/p11/survey/resumables
Authorization: Bearer $survey_import
```

In all cases, the following information about a resumable is provided:

```txt
{
    'filename': filename,
    'id': uuid,
    'chunk_size': int,
    'max_chunk': int,
    'md5sum': str,
    'previous_offset': int,
    'next_offset': int,
    'warning': str,
    'group': str,
    'key': str
}
```

The value of the `key` will show the directory to which the file belongs, which will be `{formid}/attachments`.

To cancel a partial upload:

```txt
DELETE /v1/p11/survey/resumables/filename?id=<UUID>
Authorization: Bearer survey_import
```


### Encryption

Clients can optionally encrypt JSON and file data before sending it to the API using [libsodium](https://libsodium.gitbook.io). If so, clients _must_ request automatic decryption, otherwise it will be impossible to access the data. To get the APIs public key, along with an overview of the encryption parameters:

```txt
GET /v1/p11/survey/crypto/key
Authorization: Bearer $survey_import
```

To use this functionality, clients must generate their own session key and nonce, encrypt them with the server's public key, and send the base64 encoded encypted values as headers in the request. Client side data encryption can be done in chunks, if the body is larger than _50MB_, which will be the case for most files. For the server to be able to decrypt such encrypted chunks, clients must therefore also send the chunk size, in bytes, as a header along with the request. It is also compulsory to include a custom content type header: `application/octet-stream+nacl` for files, and `application/json+nacl` for JSON data. Here is an example request for sending an encrypted file:

```txt
PUT /v1/p11/survey/1234/attachments/encrypted-interview.txt
Authorization: Bearer $survey_import
Content-Type: application/octet-stream+nacl
Nacl-Nonce: base64encode(encrypt(nonce, server-public-key))
Nacl-Key: base64encode(encrypt(client-session-key, server-public-key))
Nacl-Chunksize: 100

encrypted data...
```

For the encryption of client session keys, and nonces, the API uses [libsodium sealed boxes](https://libsodium.gitbook.io/doc/public-key_cryptography/sealed_boxes) for asymmetric encryption/decryption. Sealed boxes are designed to anonymously send messages to a recipient given its public key. For data encryption, the API uses [libsodium secret box](https://libsodium.gitbook.io/doc/secret-key_cryptography/secretbox). For a full example of this part of the APIs usage [look here](https://github.com/unioslo/tsd-file-api/blob/master/tsdfileapi/test_file_api.py#L1899).

### Message queue integration

To allow incremental, real-time data processing in respone to API requests clients should include the following headers in their HTTP requests for `PUT`:

```txt
Resource-Identifier-Key: metaData.submissionId
Resource-Identifier: 123456
```

The `Resource-Identifier-Key` header shows how to index into the payload to find the value that uniquely identifies the data, while the `Resource-Identifier` contains the value itself. As such, sending the `Resource-Identifier` itself is optional, but recommended.
