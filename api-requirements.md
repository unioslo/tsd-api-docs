# API

## Structure

### Survey

Contains all available surveys. Each survey has a general type

```json
{
  "id": string, // Unique URL will be used in front-end as identifier
  "survey_name": string, // More query friendly short name
  "name": string // Name of survey
}
```

### Patient

All patients will receive an anonymous clinic_id which is how researchers will see each patient individually represented.

```json
{
  "clinic_id": string, // Anonymous ID used by researchers to identify subject. Can be queried
  "full_name": string,
  "birth_date": DateTime,
  "identifiers": {
    "id": string,
    "type": string,
    "issuer": {"country": string},
  },
  "email": string
}
```

### Patient/surveyID

Patients can have multiple surveys with the same survey_name associated with them.

```json
  {
    "id": string, // References this instance of survey in relation to patient
    "survey_name": string,
    "date": DateTime,
    "data": {…} // Survey data
  }
```

## Endpoints needed:

### Doctors:

- Required:

  - POST create new patient.
    data
    ```json
      {
        "clinic_id": "XXXXXXX", // Anonymous ID used by researchers to identify subject.
        "full_name": "First Last",
        "birth_date": "2000-01-01",
        "identifiers": {
          "id": "00010112345",
          "type": "id_number",
          "issuer": {"country": "NO"},
        }
        "email": "my@mail.no"
      }
    ```
    returns
    ```json
      {
        "person_id": string,
      }
    ```
  - PUT Assign a survey to a patient
    Patients will not have access to surveys before assigned by doctor.
    returns
    ```json
    {
      "survey_id": string
    }
    ```
  - GET all patients WHERE doctor_id = X
    returns
    ```json
    [
      {
        "person_id": string,
        "data": {…}
      }
    ]
    ```
  - GET all patients WHERE doctor_id = X AND survey_name = X
    returns

    ```json
    [
      {
        "person_id": string,
        "data": {…}
      }
    ]

    ```

  - GET survey data WHERE survey_name = X AND patient_id = X
    returns

    ```json
    [
      {
        "survey_id": string,
        "survey_name": string,
        "name": string,
      }
    ]

    ```

  - GET patient results WHERE patient/survey_id = X
    returns
    ```json
    {
      "survey_id": string,
      "data": {…}
    }
    ```

- Nice to have:
  - GET all surveys WHERE doctor_id = X, GROUP BY survey_name
    returns
    ```json
    [
      {
        "surveyId": string,
        "name": string,
        "_count": number // Nice to have. Count all patients in survey result.
      },
    ]
    ```

### Researchers

Researchers should be able to see all survey related data down to individual level. But no personal data.

- Required

  - GET all patients WHERE surveyID = X
    returns
    ```json
    [
      {
        "clinic_id": string, // Anonymous patient ID
        "data": {…}
      }
    ]
    ```
  - GET patient survey results WHERE surveyID = X
    returns
    ```json
    {
      "clinic_id": string, // Anonymous patient ID
      "data": {…}
    }
    ```

- Nice to have
  - GET all surveys, GROUP BY survey_name
    returns
    ```json
    [
      {
        "surveyId": string,
        "name": string,
        "_count": number; // Nice to have. Count all patients in survey result.
      },
    ]
    ```

### Researchers and doctors

- GET aggregated data WHERE survey_id = X
- GET aggregated data WHERE survey_id = X AND patient_id = X
- GET aggregated data WHERE survey_name = X
- GET aggregated data WHERE survey_name = X AND patient_id = X
