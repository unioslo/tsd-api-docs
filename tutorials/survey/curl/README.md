# Accessing survey API data using curl

This tutorial will show how to fetch data from the survey API using curl.

You can take a look at the form used in the example [here](https://nettskjema.no/a/375224)

## Requirements

* `curl`

## Fetching a token

To access data from the survey API, you will need a valid token.

This assumes that you have already registered an API Key, and that the
API Key is stored in the environment variable `$APIKEY`.

```console
$ curl -X POST -H "Authorization: Bearer $APIKEY" https://internal.api.tsd.usit.no/v1/p1337/auth/basic/
token?type=survey_member

{"token": "eyJhbGci....HZTtw", "refresh_token": null}
```

Save the token in the environment variable `$TOKEN`, which we will use in the rest of the tutorial.

## Fetching metadata

```console
$ curl -H "Authorization: Bearer $TOKEN" https://internal.api.tsd.usit.no/v1/p1337/survey/375224/metadata

[{"theme": "DEFAULT", "title": "tutorial-form", "formId": 375224, "openTo": null ...
```

To see the full response, see [metadata.json](../example-data/metadata.json). More information about the format can be
found [here](https://github.com/unioslo/survey-api-schemas/blob/master/schema/2023-03/Form.json).

For most uses, the most important part of the metadata will be the data under `elements`. This contains
information about all the questions in the survey, as well as their order.

For example, here is the first element in our example form:

```json
{
    "text": "Would you rather fight 100 duck-sized horses, or 1 horse-sized duck?",
    "altText": null,
    "sequence": 1,
    "elementId": 5845750,
    "dateFormat": null,
    "description": null,
    "elementType": "RADIO",
    "subElements": [],
    "answerOptions": [
        {
            "text": "100 duck-sized horses",
            "sequence": 1,
            "answerOptionId": 14178270,
            "externalAnswerOptionId": "100_horses"
        },
        {
            "text": "1 horse-sized duck",
            "sequence": 2,
            "answerOptionId": 14178271,
            "externalAnswerOptionId": "1_duck"
        }
    ],
    "isAnswerHashed": false,
    "externalElementId": "duck_or_horse",
    "nationalIdNumberType": null
}
```

As we can see from the metadata, this is a question of the `RADIO` type, and it has two options. Values stored in the codebook, can be found in the properties `externalElementId` and `externalAnswerOptionId`.

## Fetching submissions

Fetching all submissions for our form, can be done in the following way:

```console
curl -H "Authorization: Bearer $TOKEN" https://internal.api.tsd.usit.no/v1/p1337/survey/375224/submissions

[{"answers": {"fight_animal": {"cat": "win", "rat": "win", "seal": "draw", "hippo": "loss", "horse": "loss", "moose": "loss", "tiger": "loss", "beaver": "win", "elephant": "loss", "kangaroo": "loss", "crocodile": "loss", "chimpanzee": "loss"}, "duck_or_horse": "100_horses"}, "version": "2022-07", "metadata": {"created": "2023-10-30T00:00:00+01:00", "answer_time": 26515, "submission_id": 29246211}}]
```

We can also do some filtering. Lets say we only want the submissions where the `100_horses` option has been selected in the first question:

```console
curl -H "Authorization: Bearer $TOKEN" https://internal.api.tsd.usit.no/v1/p1337/survey/375224/submissions?where=answers.duck_or_horse=eq.100_horses

...
```

For more info about the filtering, see [here](https://github.com/unioslo/tsd-api-docs/blob/master/integration/survey-api.md#key-filtering).
