
## s3 API

The TSD s3 API offers two features that are especially useful for 1) large datasets, and 2) dynamic datasets:

1) resumable uploads
2) directory synchronisation

All s3 operations are protected by 2FA. This is implemented by checking a custom header on each s3 request. We also use custom headers to determine which project you are interacting with, based on your authentication.

Current s3 clients (such as s3cmd) do not support adding custom headers for each request, but only a very limited subset. TSD has therefore applied a patch to the s3cmd utility and created a command line tool, `tsd-s3cmd` which eases the authentication flow and automatically adds the custom header to the s3 API requests. We recommend using this command line tool for interacting with the s3 API. Contact `tsd-drift@usit.uio.no` about getting the source code.

### 1. Resumable upload

Make a bucket:

```bash
tsd-s3cmd mb s3://mydata
```

Upload a large file, chunked, with resume:

```bash
tsd-s3cmd --multipart-chunk-size-mb=200 put file s3://mydata
```

If the transfer breaks, continue:

```bash
tsd-s3cmd --multipart-chunk-size-mb=200 --upload-id <id> put file s3://mydata
```

### 2. Sync

Synchronise a directory to TSD:

```bash
tsd-s3cmd --multipart-chunk-size-mb=200 sync dir s3://mydata
```

If the transfer breaks, continue:

```bash
tsd-s3cmd --multipart-chunk-size-mb=200 --upload-id <id> sync dir s3://mydata
```

### 3. Listing files

Since listing files is equivalent to exporting data from TSD you need export rights in your TSD project to be able to do this.

```bash
tsd-s3cmd ls s3://mydata
```

For more info:
```bash
tsd-s3cmd --help
```

### 4. Large data transfers

By default, API access tokens last 1 hour. In the case where a large data transfer is done with a single HTTP request the transfer can last longer than the token lifetime, because it is only used to evaluate whether the request can be processed at all.

When using the s3 API for resumable uploads and sync, the client performs many requests, often chunking data along the way. On each request the TSD API will evaluate the access token. This means that if your data transfer will take longer than an hour, then you will need to re-authenticate. This might not suit your needs, if you have several TBs of data which you want to transfer by using scripting.

In that case you can contact TSD at `tsd-drift@usit.uio.no` and ask for longer access tokens. We will then evaluate your case and configure the Auth API accordingly.

### 5. Exporting data

Inside TSD, if you have export right, move your file to the export bucket located at `/tsd/pXX/data/durable/s3-api/export-bucket`. Ensure the s3 API can read the file by doing `chmod go+r` on the file.

```bash
tsd-s3cmd get s3://export-bucket/myfile
```
