
# Publication API

The publication API allows persons to discover resources that have been shared with them by TSD projects (the actual sharing is performed by TSD researchers inside their projects, using an API which is currently not available for general use).

## Datasets Metadata

The datasets metadata is metadata published by projects for datasets they want to make available publicly or on demand. The information about the datasets is stored in table.

### API for publishing dataset metadata

Create a metadata for a dataset:

```txt
PUT /v1/<project>/publication/metadata
Authorization: $publication_token
data: 
{
   "id": "<uuid>"
   ....
}
```

where id is an unique dataset id.

Fetch all metadata published for a project

```txt
GET /v1/<project>/publication/metadata
Authorization: $publication_token
Response:
[
  {},{},{}
]
```

Fetch metadata for a specific dataset

```txt
GET /v1/<project>/publication/metadata/<dataset_id>
Authorization: $publication_token
Response:
{
  "id" : "<dataset_id>"
  ...
}
```

Delete metadata for a specific dataset

```txt
DELETE /v1/<project>/publication/metadata/<dataset_id>
Authorization: $publication_token
Response:
{"status": "ok"}
```

Update metadata for a specific dataset

```txt
PATCH /v1/<project>/publication/metadata/<dataset_id>
Authorization: $publication_token
Data:
{
  "id" : "<dataset_id>"
}
Response:
{"status": "ok"}
```

### Public Link to a dataset metadata

Once published the dataset metadata is available as following

```txt
GET /v1/all/publication/metadata/<pnum>/<dataset_id>
Response:
{
  "id" : "<dataset_id>"
  ...
}
```

## Discovery

Discovery is the process person finding resources shared with them .

### Discovery Authentication

To use the publication API for discovering and downloading data, applications should perform token exchange with an OIDC provider (currently only ID-Porten is supported), and get an access token of type `person`.

### Resource discovery

Get information about a person's direct resources, and group-based resources:

```txt
GET /v1/all/publication/discovery/persons/{person_id}
Authorization: $person_token
```

where `{person_id}` is the value of the `pid` claim in the access token. A request to this endpoint will return data about a person's direct resources and their resource groups. Direct resources are files that are shared with this person specifically. Resource groups are groups to which the person belongs, which have been granted access to data belonging to other groups. An example response is given below:

```json
{
  "direct_resources": [
    {
      "project": "p111",
      "resources": [
        {
          "href": "/v1/all/publication/111/e80d6401-d8b1-4139-958b-b9cefcda6be3/file1.txt",
          "metadata": {
            "description": "the best data ever",
            "project": "p111",
            "publisher": "Oscar Wilde",
            "publisher_pid": "e80d6401-d8b1-4139-958b-b9cefcda6be3",
            "timestamp": "2022-02-03 14:37:18.036920"
          },
          "publisher": "Oscar Wilde",
          "timestamp": "2022-02-03 14:37:18.036920"
        },
  ],
  "resource_groups": [
    {
      "groups": [
        {
          "description": "p111 patient group",
          "group": "p111-patient-group",
          "href": "/v1/all/publication/discovery/groups/p111-patient-group"
        }
      ],
      "project": "p111"
    }
  ]
}
```

To then get information about which persons provide data to the person via a resource group, another request needs to be made:

```txt
GET /v1/all/publication/discovery/groups/{group}
Authorization: $person_token
```

The response will contain a list of persons about whom data can be fetched, along with the URIs where the data can be found. Data is shared via two different backends: 1) `files` which is intended for visual display, and/or 2) `raw` which is intended for machine processing, such as by mobile apps.

```json
{
  "group_resources": [
    {
      "full_name": "Camille Paglia",
      "metadata": {
        "birth_date": "1984-01-01"
      },
      "resources": [
        {
          "backend": "files",
          "uris": [
            {
              "description": null,
              "uri": "/v1/all/publication/111/files/041f9640-27da-423c-b8be-b3343e290a49"
            }
          ]
        },
        {
          "backend": "raw",
          "uris": [
            {
              "description": null,
              "uri": "/v1/all/publication/111/raw/041f9640-27da-423c-b8be-b3343e290a49"
            }
          ]
        }
      ]
    },]
}
```
