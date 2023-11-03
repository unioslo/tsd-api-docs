# Accessing survey API data using R

This tutorial will show how to fetch data from the survey API using R.

You can take a look at the form used in the example [here](https://nettskjema.no/a/375224)

## Requirements

* `R`
* `httr2`
* `jsonlite`

## Fetching a token

To access data from the survey API, you will need a valid token.

This assumes that you have already registered an API Key, and that the
API Key is stored in the environment variable `$APIKEY`.

```r
library(httr2)
library(jsonlite)

api_key <- Sys.getenv("APIKEY")
token_url <- "https://internal.api.tsd.usit.no/v1/p1337/auth/basic/token?type=survey_member"

req <- request(token_url) %>%
    req_method("POST") %>%
    req_headers("Authorization" = paste("Bearer", api_key))

resp <- req_perform(req)
token <- resp_body_json(resp)$token
```

## Fetching metadata

```r
metadata_url <- "https://internal.api.tsd.usit.no/v1/p1337/survey/375224/metadata"
req <- request(metadata_url) %>%
    req_headers("Authorization" = paste("Bearer", token))
resp <- req_perform(req)

metadata <- resp_body_json(resp)[[1]]
```

## Fetching answers

```r
submissions_url <- "https://internal.api.tsd.usit.no/v1/p1337/survey/375224/submissions"
req <- request(submissions_url) %>%
    req_headers("Authorization" = paste("Bearer", token))
resp <- req_perform(req)
submissions <- resp_body_json(resp,simplifyVector=TRUE)

m <- merge(submissions$answers, submissions$metadata)

# Compare how many answers would like to fight the horse sized duck or the 100 
# duck sized horses
table(m$duck_or_horse)
#
#    1_duck 100_horses 
#         8          8 
```
