
# Using the apps API - an example

## Use case

In this example there are three different roles, each with different levels of data access:

1. doctors - read and write on individual and aggregate data
2. patients - read and write on their own individual data
3. researchers - read on aggregate data

## Access tokens

The following token types are defined to cover these roles:

* `app-processor`, requested by doctors
* `app-subject`, requested by patients
* `app-researcher`, requested by researchers
* `app-basic`, write-only token used by the app

## Identity management requirements

The following groups should be created:
* `p[0-9]+-{app}-processor-group`
* `p[0-9]+-{app}-subject-group`
* `p[0-9]+-{app}-researcher-group`

In the use case above, the following would apply:

* doctors are members of the `p[0-9]+-{app}-processor-group`
  * a TSD project member requests group creation (a person group)
  * doctors apply for TSD project membership
  * TSD project admins approve them as associated members
* patients are members of the `p[0-9]+-{app}-subject-group`
  * a TSD project member requests group creation (a person group)
  * patient person objects are created
  * patients are _added to groups by processors in the app_
* researchers are members of the `p[0-9]+-{app}-researcher-group`
  * a TSD project member requests group creation (a person group)
  * researchers apply for TSD project membership
  * TSD project admins approve them as associated members

## Using the API

### App setup

Create a study definition:
```txt
PUT /v1/{pnum}/apps/{app}/tables/generic/study_definitions
Authorization: Bearer $app-basic
Content-Type: application/json

{
    "study_name": "study1".
    "study_id": "12345",
    "questions": [],
}
```

### Patient creation

Create a person object for a new patient, optionally assigning a diagnosis and a survey:
```txt
PUT /v1/{pnum}/apps/{app}/iam/persons
Authorization: Bearer $app-processor-token
Content-Type: application/json

{
    "full_name": "First Last",
    "birth_date": "2000-01-01",
    "identifiers": [
        {
            "id": "00010112345",
            "type": "id_number",
            "issuer": {"country": "NO"},
        },
    ],
    "email": "my@mail.no",
    "person_metadata": {
        "apps": {
            "app-name": {
                "study_id": "12345",
                "doctors": ["some-id"],
                "diagnoses": ["some-diagnosis"],
                "surveys": ["survey1"],
            }
        }
    }
}
```

It is mandatory to include the name of your app in the `apps` key inside `person_metadata`, and to nest your app-specific metadata under that name.

If a person with the same `identifiers` has already been created, then the above request will return the person ID, and update any existing attributes with the new values. If a new person is created, the same response will be returned:
```json
{
    "person_id": "some-uuid-value"
}
```

_Manadatory_: a processor must add them to the subject group:
```
PUT /v1/{pnum}/apps/{app}/iam/groups/{pnum}-{app}-{subject}-group/members
Authorization: Bearer $app-processor-token
Content-Type: application/json

{
    "member": "person_id"
}
```

### Editing patient person data

For array values, `PATCH` requests will over-write existing sub-keys of the `person_metadata`, so if the intent is to append an item to an array, the client must first fetch the current value, update the array in memory to the desired value, and then perform the `PATCH` API call.

Assign a diagnosis:
```txt
PATCH /v1/{pnum}/apps/{app}/iam/persons/{person_id}/person_metadata.apps.{app-name}.diagnoses
Authorization: Bearer $app-processor-token
Content-Type: application/json

{
    "diagnoses": ["some-diagnosis"],
}
```

Assign a survey:
```txt
PATCH /v1/{pnum}/apps/{app}/iam/persons/{person_id}/person_metadata.apps.{app-name}.surveys
Authorization: Bearer $app-processor-token
Content-Type: application/json

{
    "surveys": ["survey1", "survey2"],
}
```

### Getting data

List all patients treated by a doctor:
```
GET /v1/{pnum}/apps/{app}/iam/persons?person_metadata.apps.{app-name}.doctors=<@['doctor-person-id']
Authorization: Bearer $app-processor-token
```

A subject adds data about themselves to a hypothetical survey named `study1`, or a processor does so on their behalf:
```
PUT /v1/{pnum}/apps/{app}/tables/persons/studies?where.id=eq.{person_id}
Authorization: Bearer $app-processor-token|$app-subject-token
Content-Type: application/json

{
    "id": "subject-person-id",
    "data": {...}
    "studyId": "some-id"
}
```

A subject gets their own data _for all studies_, or a processor gets data about a specific subject:
```
GET /v1/{pnum}/apps/{app}/tables/persons/studies?where.id=eq.{person_id}
Authorization: Bearer $app-processor-token|$app-subject-token
```

A processor gets data about all subjects:
```
GET /v1/{pnum}/apps/{app}/tables/persons/studies
Authorization: Bearer $app-processor-token
```

## Other API calls

List the members of groups:
```
GET /v1/{pnum}/apps/{app}/iam/groups/{pnum}-{app}-{subject|processor}-group/members
Authorization: Bearer $app-processor-token
```
