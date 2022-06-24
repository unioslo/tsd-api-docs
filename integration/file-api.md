
# File import and export

### Simple file upload

To stream file contents:
```txt
PUT /v1/p11/files/stream/filename?group=p11-data-group
Authorization: Bearer $import_token
```
Notice the `group` parameter in the URI. The value of this specifies which file group should have access to the file once it is uploaded to TSD. Access tokens issued by the auth API contain a claim listing the identity's group memberships. Clients can therefore set the value of the group parameter to any one of these groups.

To upload a file to a directory, called `mydir/anotherdir`, e.g.:
```txt
PUT /v1/p11/files/stream/p11-data-group/mydir/anotherdir/filename?group=p11-data-group
Authorization: Bearer $import_token
```
Notice that the group has to precede the directories, and appear in the URL parameter.

To check if a file exists, and get some metadata:
```txt
HEAD /v1/p11/files/stream/p11-data-group/filename
Authorization: Bearer $import_token
```

To list the import directory:
```txt
GET /v1/p11/files/stream
Authorization: Bearer $import_token
```
This will list group folder which the requestor is allowed to list (based on their group membership).

To continue listing specific group folders in the import directory:
```txt
GET /v1/p11/files/stream/p11-data-group
Authorization: Bearer $import_token
```
Note: if the requestor is not a member of the group in the URI, then the listing will return 401.

### Simple file download

To list the export directory
```txt
GET /v1/p11/files/export
Authorization: Bearer $export_token
```

To check if a file exists, and get some metadata:
```txt
HEAD /v1/p11/files/export/myfolder/myfile
Authorization: Bearer $export_token
```

To download a file:
```txt
GET /v1/p11/files/export/myfile
Authorization: Bearer $export_token
```

To download a file from a directory in the export folder:
```txt
GET /v1/p11/files/export/myfolder/myfile
Authorization: Bearer $export_token
```

### Resumable file upload

A reference client implementation using the resumable import and export API can be found [online](https://github.com/unioslo/tsd-api-client/blob/master/tsdapiclient/fileapi.py).

### Starting a new resumable upload

The client, having chunked the file, starts by initiating a PATCH, uploading the first chunk:

```txt
PATCH /v1/p11/files/stream/filename?chunk=<num>&group=<group-name>
Authorization: Bearer $import_token

{
    filename: str,
    max_chunk: int,
    id: uuid
}
```

Using the UUID returned by the server in the response, the client can continue sending succesive chunks, in sequence:

```txt
PATCH /v1/p11/files/stream/filename?chunk=<num>&id=<UUID>&group=<group-name>
Authorization: Bearer $import_token

{
    filename: str,
    max_chunk: int,
    id: uuid
}
```


### Resuming prior uploads

There are a few different ways to ask the server for resumable information. Firstly, to list all resumables for the authenticated user:
```txt
GET /v1/p11/files/resumables
Authorization: Bearer $import_token

{ resumables: [{...}, {...}] }
```

The client can optionally specify a given filename, and the server will return the resumable with the most data on the server (if there is more than one):
```txt
GET /v1/p11/files/resumables/myfile
Authorization: Bearer $import_token

{...}
```

The information for a specific upload can be requested by including the upload id in addition to the filename:
```txt
GET /v1/p11/files/resumables/myfile?id=<UUID>
Authorization: Bearer $import_token

{...}
```

If the client has been uploading a resumable file to a directory, then it can restrict the informational request by includinig the `key` URI parameter:
```txt
GET /v1/p11/files/resumables/myfile?key=dir-name
Authorization: Bearer $import_token

{...}
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

The combination of the filename and UUID allow the client to resume an upload of a specific file for a specific prior request. The chunk size and number allow the client to seek locally in the file before sending more chunks to the server, avoiding sending the same data more than once. The md5 digest of the latest chunk, combined with the offset information allow clients to verify chunk integrity.

The server will attempt to repair any data inconsistencies which may have arised due to server crashes or filesystem issues. If it cannot get the resumable data back into a consistent state, the `next_offset` field will be set to `end`. Client are recommended to either end the upload, or delete it.

Assuming data is consistent, the client then proceed as follows:
```txt
PATCH /v1/p11/files/stream/filename?chunk=<num>&id=<UUID>&group=<group-name>
Authorization: Bearer $import_token

{
    filename: str,
    max_chunk: int,
    id: uuid
}
```

### Completing a resumable upload

To finish the upload the client must explicitly indicate that the upload is finished by sending an empty request as such:
```txt
PATCH /v1/p11/files/stream/filename?chunk=end&id=<UUID>&group=<group-name>
Authorization: Bearer $import_token
```
This will tell the server to assemble the final file. Setting the group is optional as normal.

### Cancelling a resumable upload

To avoid wasting disk space, partially completed uploads which were not resumed to completion, and abandoned, can be removed as such:

```txt
DELETE /v1/p11/files/resumables/filename?id=<UUID>
Authorization: Bearer $import_token
```

### Implementation

### Server

When a new resumable request is made, the server generates a new UUID, and creates a directory with the name of that UUID which will contain the successive chunks, and writes each chunk to its own file in that directory, e.g.:

```txt
/cb65e4f4-f2f9-4f38-aab6-78c74a8963eb
    /filename.txt.chunk.1
    /filename.txt.chunk.2
    /filename.txt.chunk.3
```

Once the client has sent the final chunk in the sequence, the server will merge the chunks, move the merged file to its final destination, remove the chunks, their accumulating directory, and respond to the client that the upload is complete.

### Clients

Client are expected to split files into chunks, and upload each one as a separate request, _in order_. Since the server will return information about chunks, the client does not have to keep state if and when a resumable file upload fails, but it can if it wants to, since each request return enough information to resume the upload in the event of failure.

If a resumable upload fails and the client has lost track of the upload id, the client can, before initiating a new resumable request for a file, ask the server whether there is a resumable for the given file. If so, it will recieve the chunk size and sequence numner, and the UUID which identifies the upload. Using this, the given file upload can be resumed. The client chunks the file, seeks to the relevant part, and continues the upload.

When uploading the last chunk, the client must explicitly indicate that it is the last part of the sequence.


### Resumable downloads

Or, how to perform conditional range requests, per file.

### Starting a resumable download

Clients can get resource information before starting a download as follows:

```txt
HEAD /v1/p11/files/export/filename
Authorization: Bearer $export_token
```

The server will return an `Etag` header, containing an ID which uniquely identifies the resource content. Addtionally, the server will return the `Content-Length` in bytes. Clients can store the `Etag` to make sure that if they resume a download, they can check with the server that the resource has not changed in the meantime.

Downloads are started as usual:

```txt
GET /v1/p11/files/export/filename
Authorization: Bearer $export_token
```

### Resuming a partially complete download

If a download is paused or fails before completing, the client can count the number of bytes in the local partial download, and request the rest from the server, using the `Range` header. _Importantly, range requests specify ranges with a 0-based index. So if the client already has 103 bytes of a file (bytes 0-102, with an 0-based index), and it wants the rest, then it should ask for_:

```txt
GET /v1/p11/files/export/filename
Range: bytes=103-
Authorization: Bearer $export_token
```

A specific index range can also be requested, if relevant:

```txt
GET /v1/p11/files/export/filename
Range: bytes=104-200
Authorization: Bearer $export_token
```

And to ensure resource integrity it is recommended that the value of the `Etag` ias included, thereby performing a conditional range request:

```txt
GET /v1/p11/files/export/filename
If-Range: 0g04d6de2ecd9d1d1895e2086c8785f1
Range: bytes=104-
Authorization: Bearer $export_token
```

The server will then only send the requested range if the resource has not been modified. Multipart range requests are not supported.


### Request logs

To get request logs, about which files have been exported by whom, when:

```txt
GET /v1/p11/logs/files_export
Authorization: Bearer $iam_token

[
  {
    "uri": "/v1/p11/files/export/file1",
    "method": "GET",
    "requestor": "p11-testing",
    "timestamp": "2021-02-05T10:29:45.322457"
  },
  {
    "uri": "/v1/p11/files/export/file1",
    "method": "GET",
    "requestor": "p11-testing",
    "timestamp": "2021-02-05T10:29:48.050991"
  }
]
```
