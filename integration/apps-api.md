
# Apps API

To register a new app, please contact TSD. Throughout this section project `p11` is used as an example.

### Endpoints

Generic:
```txt
/v1/p11/apps/{your-app}/tables/{table}
/v1/p11/apps/{your-app}/tables/{table}/audit
/v1/p11/apps/{your-app}/files
/v1/p11/apps/{your-app}/resumables
```

Personal:
```txt
/v1/p11/apps/{your-app}/tables/persons/{person_identifier}
/v1/p11/apps/{your-app}/tables/persons/{person_identifier}/audit
/v1/p11/apps/{your-app}/files/persons/{person_identifier}
/v1/p11/apps/{your-app}/resumables
```

### Access control and access tokens

The apps API implements a mandatory access control model designed around different roles and use cases. The table below sumamrises the different roles, their respective access tokens, how to obtain them, where they can be used, and which API operations they are authorized to perform:

| Role | Access token | Auth method | Host | Access (generic) | Access (personal) |
| :-: | :-----------: | :---------: | :--: | :--------------: | :--------------: |
| machines | app-basic | basic | outside | W | - |
| data owners | app-user | OIDC | outside | R, W | R, W, U, D |
| researchers | app-member | TSD | inside | R | R |
| administrators | app-admin | OIDC | outside, inside | R, W, U, D | R, W, U, D |

* `R`: read, GET, HEAD
* `W`: write, PUT, PATCH (for file uploads)
* `U`: update, PATCH (for tables)
* `D`: delete, DELETE
* `inside`: available inside TSD projects at `internal.api.tsd.usit.no`
* `outside`: available outside TSD at `api.tsd.usit.no`

With the help of the table one can now elaborate three main use cases.

#### 1. Automated data collection

By using the `app-basic` access token with basic authentication, API clients can collect data from sensors, and send them as either files or JSON to the so-called generic endpoints. Researchers can then access this data from inside their TSD project, and conduct research. Administrators can edit, and delete as necessary.

#### 2.  Authenticated data collection (generic)

In this scenario an app would allow users that login with an OIDC provider to the use token exchange to obtain an `app-user` token. This allows the user to write to, and read from the generic app endpoints. This implies that the app itself has to implement any other access control necessary, and ensure that access token remain server side. The flexibility gives more design control to the app developer, but also places more responsibility on the app developer by leaving some access control undone. On the inside of TSD, researchers will have access to all data uploaded by the app. Administrators can edit, and delete as necessary.

#### 3.  Authenticated data collection (personal)

Users login with an OIDC provider and the app uses token exchange to obtain an `app-user` token. The so-called personal endpoints, where data is explicitly organised per person, is the most strict access control regime offered by the API. It ensures that users can write, read, update and delete _only their own data_. To use this correctly, apps must add the `pid` claim, obtained from the access token, in the URLs where the `{person_identifier}` was given. On the inside of TSD, researchers will have access to all data uploaded by the app. Administrators can edit, and delete as necessary.

### Scope

Data are organised via apps and tables. *Apps* define organisational contexts, affected by access control (see above). *Tables* denote structural units, i. e. collections of data records. In the following examples, we use `my-app` as the app, and `my-table` as the table.

### JSON data

Apps API manages data records, i. e. table rows, as JSON documents, each of which consists of a dictionary of key-value pairs. The only restriction is that each data record must be unique - that is, each JSON entry sent to the API should contain a unique key-value pair such as an ID, or a timestamp.

#### Writing

To insert a data record into the table send the JSON-serialised data record as payload:
```txt
PUT /v1/p11/apps/my-app/tables/my-table
Authorization: Bearer $token

{...}
```

#### Reading

To retrieve data from a table:
```txt
GET /v1/p11/apps/my-app/tables/my-table
Authorization: Bearer $token
```

This returns an array consisting of all data records, in no particular order. One can refine the results which are returned by adding queries, which are explained in the next section.

#### Updating

To update existing data records, use the query functionality (explained in section *Queries* below) to specify the record(s) affected by the operation, and provide the new data as payload:
```txt
PATCH /v1/p11/apps/my-app/tables/my-table?set=data&where=metaData.id=eq.1
Authorization: Bearer $token

{data: [...]}
```

All updates are recorded in the audit log for each table:
```txt
GET /v1/p11/apps/my-app/tables/my-table/audit
Authorization: Bearer $token
```

This returns the full audit log as an array, in no particular order. Like queries (see *Queries* below), the result set of the audit log can be sorted and and its contents limited.

#### Deleting

To delete data records that match a conditional clause:
```txt
DELETE /v1/p11/apps/my-app/tables/my-table?where=data=eq.1
Authorization: Bearer $token
```

### Queries

Suppose you use the following format for data records, each record being inserted via a request of its own (see *Writing* above):

```json
[
    {
        "metaData": {"id": 1},
        "data": [
            {"code": 0, "variable": "ans1", "text": "no", "degree": 5},
            {"code": 1, "variable": "ans2", "text": "bla"},
            {"code": 2, "variable": "ans3", "text": "yes", "degree": 3},
        ]
    },
    {
        "metaData": {"id": 2},
        "data": [
            {"code": 1, "variable": "ans1", "text": "no", "degree": 10},
            {"code": 2, "variable": "ans2", "text": "bla"}
        ]
    },
    {
        "metaData": {"id": 3},
        "data": [
           {"code": 0, "variable": "ans1", "text": "no", "degree": 1}
       ]
    }
]
```

#### Key filtering

To filter by a specific key of the record, one can use the `select` clause as a query parameter.

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

A row with a specific `id`, nested inside the `metaData` key:
```txt
?where=metaData.id=eq.1
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

The order in which records are returned can be forced to be either ascending (`asc`) or descending (`desc`) with respect to the value of a specific key:
```txt
order=metaData.id.desc
```

#### Paginating

To limit the subset of records returned by a query to a specific range, one needs to specify an offset (0-based integer value) and the number of records returned:
```txt
range=1.2
```
returns up to two records of the dataset, starting with the second record.

### Files

#### Basic file operations

To upload a file, hypothetically named `interview.txt`:
```txt
PUT /v1/p11/apps/my-app/files/interview.txt
Authorization: Bearer $token

All the interview data...
```

There is a 5GB limit on size, when using this method, and note this is _not_ `multipart/form-data`, clients should send the file contents byte-per-byte.

Or to a subdirectory specific to a user, e.g.:
```txt
PUT /v1/p11/apps/my-app/files/user1/interview.txt
Authorization: Bearer $token

All the interview data...
```

To list files:
```txt
GET /v1/p11/apps/my-app/files
Authorization: Bearer $token
```

To get a file:
```txt
GET /v1/p11/apps/my-app/files/interview.txt
Authorization: Bearer $token
```

To delete a file:
```txt
DELETE /v1/p11/apps/my-app/files/interview.txt
Authorization: Bearer $token
```

#### Resumable uploads

The client, having chunked the file, starts by initiating a PATCH, uploading the first chunk:
```txt
PATCH /v1/p11/apps/my-app/files/filename?chunk=1
Authorization: Bearer $token

{
    filename: str,
    max_chunk: int,
    id: uuid
}
```

Using the UUID returned by the server in the response, the client can continue sending succesive chunks, in sequence:
```txt
PATCH /v1/p11/apps/my-app/files/filename?chunk=<num>&id=<UUID>
Authorization: Bearer $token

{
    filename: str,
    max_chunk: int,
    id: uuid
}
```

To finish the upload the client must explicitly indicate that the upload is finished by sending an empty request as such:
```txt
PATCH /v1/p11/apps/my-app/files/filename?chunk=end&id=<UUID>
Authorization: Bearer $token
```

To get an overview of uploads which can be resumed:
```txt
GET /v1/p11/apps/{your-app}/files/resumables
Authorization: Bearer $token
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
DELETE /v1/p11/apps/{your-app}/files/filename?id=<UUID>
Authorization: Bearer $token
```
