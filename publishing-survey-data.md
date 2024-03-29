
# Publishing survey data

Use case:
* collect data with Nettskjema
* create HTML reports, or JSON files using respondent data
* make the reports available to a group of people
  * using electronic identities which they already have


## Overview

0. Prerequisites and limitations
1. Create groups
2. Approve associated members, add to groups
3. Create publication rule for groups
4. Create and activate the Nettskjema form
5. Get an API client
6. Fetch data from the survey API
7. Create persons
8. Add persons to groups
9. Publish files about persons
10. Fetching reports


## 0. Prerequisites and limitations

* Have an active TSD project
* The group of people who will access reports about respondents:
  * must be able to login with idporten/BankID, and must therefore have a Norwegian electronic identity
  * must be made associated members of the TSD project


## 1. Create groups

A typical case will have two groups: one for the readers of the reports, and another for the respondents of the survey. For example, one could have two groups in TSD project `p11`:

* `p11-doctor-group` - "Doctors, Hospital A"
* `p11-patient-group` - "Patients, Hospital A, Division B"

When creating groups, consider the following:

* the name should conform to the following regex: `p[0-9]+-[a-z0-9-]+-group`
* group descriptions will be displayed on the publication portal
* request that the project's admin-group be set as group moderator
* the groups should be web groups

Create a group as such:
```txt
PUT /v1/{pnum}/iam/groups
Authorization: Bearer $auto_publication

{
    "group_name": "p11-doctor-group",
    "group_descrtiption": "a great group",
    "group_class": "secondary",
    "group_type": "web"
}
```

Set the moderator of the group to the admin group:
```txt
PUT /v1/{pnum}/iam/groups/p11-doctor-group/moderators
Authorization: Bearer $auto_publication

{
    "moderator": "p11-admin-group",
}
```

## 2. Approving associated members

Continuing with the example above, in order to make the doctors members of the `p11-doctor-group`, they first have to [apply for project membership in the TSD selfservice portal](https://selfservice.tsd.usit.no/application/). Here they will log in with ID-porten, and will have to provide the project number, such as "p11" during application.

Once this is done, a project admin can [approve their applications](https://selfservice.tsd.usit.no/project/pending-applications), and choose to make them "associated members" of the project. This means that they will not have access to the project's virtual machines, but it will be possible add them to groups.

Once the doctors have been associated with the project they [can be added as members](https://selfservice.tsd.usit.no/project/people-groups) to the `p11-doctor-group`.


## 3. Grant group access

In the example above, grant the doctor group access to data from the patient group. Do this as follows:

```txt
PUT /v1/{pnum}/publication/access/groups/p11-patient-group/p11-doctor-group
Authorization: Bearer $auto_publication

{
    "backends": [{"name": "files"}, {"name": "raw"}]
}
```

## 4. Create and activate the Nettskjema form

Use [nettskjema.no](https://nettskjema.no/), with your TSD account.


## 5. Get an API client

This is issued [on request](https://www.uio.no/english/services/it/research/sensitive-data/contact/). The API client will grant you access to process Nettskjema data and share data via the publication portal. Also, whitelist the IP where you publication app will run, send this information with the request.


## 6. Fetch data from the survey API

```txt
POST /v1/{pnum}/auth/basic/token?type=survey_export_auto
Authorization: Bearer $api_key
```
* the `api_key` is the secret which you receive along with your API client, also called a client secret
* `{pnum}` is your TSD project number

To get form data:
```txt
GET /v1/{pnum}/survey/{formid}/submissions
Authorization: Bearer $survey_export_auto
```

To get form metadata (information about the data types):
```txt
GET /v1/{pnum}/survey/{formid}/metadata
Authorization: Bearer $survey_export_auto
```

Your app can then process this data to produce the reports you want to share.


## 7. Create persons

To ensure data collected from Nettskjema respondents can be shared, the repondents themselves must have person objects in TSD's Identity and Access Management system. To create a person, the following API call must be made:

```txt
POST /v1/{pnum}/iam/persons
Content-Type: application/json
Authorization: Bearer $auto_publication

{
    "full_name": "First Last",
    "birth_date": "2000-01-01",
    "identifiers": {
        "id": "00010112345",
        "type": "id_number",
        "issuer": {"country": "NO"},
    }
}
```
It is a good idea to add their birth date, collected from the first part of their Norwegian personal ID, since that can be used to distinguish between people who have the same name. This data has to be collected in Nettskjema. If a person with the same `identifiers` has already been created, then the above request will return the person ID, without modifying the rest of the attributes. If a new person is created, the same response will be returned:

```json
{"person_id": "some-uuid-value"}
```

The mapping between the ID number and the TSD person ID will not change, so this information can be cached by the application, so that new Nettskjema submissions can perform the person ID lookup without having to make the API call.

## 8. Add persons to groups

To add a person (a respondent in this case) to a group:
```txt
PUT /v1/{pnum}/iam/groups/{pnum}-{name}-group/members
Authorization: Bearer $auto_publication
Content-Type: application/json

{
    "member": "person_id"
}
```

## 9. Publish files about persons

Once your application has processed the Nettskjema data fetched from the survey API, an HTML report can be uploaded to a respondent specific URL as such, e.g.:

```txt
PUT /v1/{pnum}/publication/{num}/import/files/{person_id}/{report-file-name}
Authorization: Bearer $auto_publication
```

JSON data can be uploaded _as files_ to the `raw` data backend:

```txt
PUT /v1/{pnum}/publication/{num}/import/raw/{person_id}/{report-file-name}
Authorization: Bearer $auto_publication
```

Where:

* `{pnum}`, project number, e.g.: `p11`
* `{num}`, project number without the `p`, e.g. `11`
* `{report-file-name}`, e.g. `report-2022-10-17.html`


## 10. Fetching reports

The doctors can now login to the external [publication portal](https://publication.tsd.usit.no/), using ID-Porten/BankID, to browse reports for the different respondents.
