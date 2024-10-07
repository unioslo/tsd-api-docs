# Accessing survey API data using python

This tutorial will show how to fetch data from the survey API using curl.

You can take a look at the form used in the example [here](https://nettskjema.no/a/375224)

All of these examples assume that you are working from within TSD. If accessing
the survey API externally, you will need to use a `survey_export` or `survey_export_auto` token
and use `api.tsd.usit.no` instead of the internal endpoint.

## Requirements

* `python >= 3.6`
* `requests`

## Fetching a token

To access data from the survey API, you will need a valid token.

This assumes that you have already registered an API Key, and that the
API Key is stored in the environment variable `$APIKEY`.

```python
import os
import requests

api_key = os.getenv("APIKEY")
headers = {"Authorization": f"Bearer {api_key}"}

token_url = "https://internal.api.tsd.usit.no/v1/p1337/auth/basic/token?type=survey_member"
resp = requests.post(token_url, headers=headers)

token = resp.json()["token"]
```

## Fetching metadata

```python
headers = {"Authorization": f"Bearer {token}"}
metadata_url = "https://internal.api.tsd.usit.no/v1/p1337/survey/375224/metadata"

resp = requests.get(metadata_url, headers=headers)

# The metadata response will be an array, we just pick the first one, but usually
# you should select the metadata with the newest "generatedDate"
# Metadata is updated if the form is reactivated or changed.
metadata = resp.json()[0]

# Get the codebook for the first question
q_codebook = metadata["elements"][0]["externalElementId"]
```

## Fetching answers

```python
submissions_url = "https://internal.api.tsd.usit.no/v1/p1337/survey/375224/submissions"
resp = requests.get(submissions_url, headers=headers)
submissions = resp.json()

# Print all answers to our first question
for s in submissions:
    print(s["answers"][q_codebook])

# 100_horses
# 1_duck
# 1_duck
# 100_horses
```

## Fetching attachments (and pdf signatures)

Listing attachments:

```python
attachments_url = "https://internal.api.tsd.usit.no/v1/p1337/survey/395025/attachments"
resp = requests.get(requests_url, headers=headers)
attachments = resp.json()
```

The output from the attachment listing will look something like this:

```json
{
  "files": [
    {
      "filename": "formId-395025_submissionId-31089868_signed.pdf",
      "size": 305389,
      "modified_date": "2024-03-19T13:30:00.183715",
      "href": "/v1/p1337/survey/395025/attachments/formId-395025_submissionId-31089868_signed.pdf",
      "exportable": true,
      "reason": null,
      "mime-type": "application/pdf",
      "owner": "p01-fileapi-user",
      "etag": "f6da2b075e7b382cd18663c191eddab8",
      "mtime": 1710851400.183715
    },
    {
      "filename": "formId-395025_submissionId-30244006_signed.pdf",
      "size": 304158,
      "modified_date": "2024-01-19T09:40:01.097433",
      "href": "/v1/p1337/survey/395025/attachments/formId-395025_submissionId-30244006_signed.pdf",
      "exportable": true,
      "reason": null,
      "mime-type": "application/pdf",
      "owner": "p01-fileapi-user",
      "etag": "55f925033d75eac9a1eeb4ebfef35b40",
      "mtime": 1705653601.0974329
    }
  ],
  "page": null
}
```

If there are a large amount of files, you might need request multiple pages. 
You find more info about pagination [here](https://github.com/unioslo/tsd-api-docs/blob/master/integration/survey-api.md#files)

So to download all files, and write them to disk, we could do something like this:

```python
for attachment in resp.json()["files"]:
    url = f"https://internal.api.tsd.usit.no{attachment['href']}"
    resp = requests.get(url, headers=headers)

    # Lets write the file to for example /tmp
    output_file_path = f"/tmp/{attachment['filename']}"
    with open(output_file_path, "wb") as f:
        f.write(resp.content)
```
