# Accessing survey API data using python

This tutorial will show how to fetch data from the survey API using curl.

You can take a look at the form used in the example [here](https://nettskjema.no/a/375224)

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
