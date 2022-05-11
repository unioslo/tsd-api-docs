
# Consent API

### Registration

To use a consent form the TSD user must register in the system. This is done usually via internal portal but will soon be available outside.

Example registration request:

```
POST /v1/p11/consent/internal
Authorization: Bearer $token

{
    form_id: str,
    title: str,
    description: str,
    consenter_id_attribute: str,
    minor_id_attribute: str,
    reference_attributes:[
      'attribute1' .....
    ],
    questions:[
      {
        'attribute_name': str,
        'granted_value': str,
        'description': str
      }
    ],
}
```

where ```$token``` is a ```consent``` token. To obtain a consent token the user must be member of the consent group (```pxx-consent-group```) of the project.

The form is registered via a form id. A title and description is provided to indicate what is the consent form about. The relative attributes from the form are provided as well: 1) consenter_id_attribute - the attribute that contain the consenter personal id (usually fodselsnummer); 2) minor_id_attribute - the attribute that contains the id number of a minor in case the consent form is filled by a guardian; 3)  A list of reference attribute are associated to each form that indicate the consent reference (ex. dataset, person etc); 4) A list of consent question for form with correspond to yes value in the csv file (e.g. yes, ja, 1 etc.).

### Delete Registered Form

```
DELETE /v1/p11/consent/internal/12345
Authorization: Bearer $token
```

where ```$token``` is a ```consent``` token. Deletion of registered form is straight forward. Just specify the form number in the url.


### Ingestion

The ingestion of data is done by automatic script for registered consent forms. A consent is loaded into the consent system with the following request:

```
POST /v1/p11/consent/internal/12345
Authorization: Bearer $token

{
  consents: [
    {
      id : str,
      delivered_on: str/date,
      data: {attribute:value, ....},
      source: str (form_id/manual)
    }
  ]
}
```
where ```$token``` is a ```consent``` token and  ```data``` is map containing all the attribute and values from the consent submission as in the csv files delivered in TSD.

### Query

The query mechanism provides a simple search functionality.

```
POST /v1/p11/consent/internal/12345/query
Authorization: Bearer $token

{
  query: {
    consenter_id: str,
    minor_id: str,
    reference_attributes:{
      'attribute1': 'value' , ...
    },
    questions:{
      'question1': True/False,
    },
  }
}
```
where ```$token``` is a ```consent``` token. The service can query on any of the consenter ids, reference attributes, and consent questions.

### Consult

The consult is a consenter facing service. It provides the consenters with the consents given for all
projects in TSD. The response contains everything needed to visualize the consent to the consenter.

```
GET /v1/p11/consent/external
Authorization: Bearer $token

Example Result
[{
  'form_id': '1234',
  'title': 'The title of the form',
  'description': 'The form description',
  'questions': [{'attribute_name': '', 'granted_value': '',  'description': ''} ...]
  'current': {'attribute': True/False, ...},
  'past' : [{'attribute': True/False, ...}, {'attribute': True/False, ...}]
}
]
```

where ```$token``` is a ```person``` token. The person token is obtain via IDPRTEN login. The  ```current``` is the most recent delivered consent. The past are previous consent deliveries.
