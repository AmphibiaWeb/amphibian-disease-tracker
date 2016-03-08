AmphibianDisease.og
==========================

Quick Links:

- [Project Browser](https://amphibiandisease.org/project.php)
- [Login/Administration](https://amphibiandisease.org/admin)
- [Administration Dashboard](https://amphibiandisease.org/admin-page.html)

## Features

TODO

## API access

All responses are as `application/json`.

Note that input is aggressively URL escaped. Depending on your use you may want to de-escape the text before use (especially raw JSON-as-text).

### API errors

If a given query produces an error, the `status` key will be `false`.

In addition, you will always have an `error` key with technical
details. When appropriate, the server may provide a `human_error` key
with a response that's more friendly to an end user.

### API Authentication

These parameters are optional for unauthenticated API access (in some cases, you may get additional results here), and mandatory for authenticated API access.

#### Acquiring API tokens

If you don't already have a set of identifier tokens, you will need to acquire them.

API target: `https://amphibiandisease.org/api.php`
Method: `POST`

Parameters:

> `action`: `login`
> `username`: The email of the user
> `password`: The password of the user


**Aside: TOTP**
>**Important Note**: If your user is configured to use Two-Factor authentication, you'll recieve a response like:
>
>```json
>{
>  "status": false,
>  "user": "foo@bar.com",
>  "encrypted_hash": "jU+3Yson68O6vluIAStEnBFOX87xT0dmnYLauKs+jM8=",
>  "encrypted_secret": "jU+3Yson68O6vluIAStEnBFOX87xT0dmnYLauKs+jM8=",
>  "encrypted_password": "%2BaHg3NELhMcD%2FKUXrjAnXPu8xA4evKS0Ew8%2F%2Bv9Nxtk%3D",
>  "human_error": "Please enter the code generated by the authenticator application on your device for foo@bar.com.",
>  "error": false,
>  "totp": true
>}
>```
>
>Which you can test for by checking if `result.status === false && result.totp === true`.
>
>When you re-reply, send
>
>> `action`: `login`
>> `username`: The email of the user
>> `password`: The previous response `response.encrypted_password`
>> `totp`: Your TOTP value



Response:

> `status`: boolean
> `user`: JSON string of {'COOKIE_NAME':'USER_EMAIL'}. Note this is NOT an object.
> `auth`: JSON string of {'COOKIE_NAME':'USER_AUTHORIZATION_HASH'}. Note this is NOT an object.
> `secret`: JSON string of {'COOKIE_NAME':'USER_AUTHORIZATION_SECRET'}. Note this is NOT an object.
> `link`: JSON string of {'COOKIE_NAME':'USER_DB_UNQ_ID'}. Note this is NOT an object.
> `pic`: JSON string of {'COOKIE_NAME':'USER_PICTURE_PATH'}. Note this is NOT an object.
> `name`: JSON string of {'COOKIE_NAME':'USER_FIRST_NAME'}. Note this is NOT an object.
> `full_name`: JSON string of {'COOKIE_NAME':'USER_FULL_NAME'}. Note this is NOT an object.
> `js`: A JavaScript function to evaluate using [js-cookie](https://github.com/js-cookie/js-cookie/tree/v1.5.1) to set the cookies in-browser.
> `ip_given`: The IP from which these cookies are valid. Changing IP addresses will invalidate the cookies.
> `raw_auth`: The data from `response.auth`
> `raw_secret`: The data from `response.secret`
> `raw_uid`: The data from `response.link`
> `expires`: The expires parameter on the cookies.

#### Sending API tokens

| Parameter | Value Meaning                                       | Key from Acquired Tokens |
|-----------|-----------------------------------------------------|--------------------------|
| `hash`    | Verification value of user secret and server secret | `response.raw_auth`  |
| `secret`  | One of two parts of a secret session identiifer     | `response.raw_secret`|
| `dblink`  | Unique server ID for user; UserID equivalent        | `response.raw_uid`  |


For any authenticated/psuedoauthenticated request, these parameters can be sent as extra parameters to validate a login session. The cookie key pairs may also be sent in the header of the POST, rather than these raw cookie values.

### Unauthenticated APIs

API target: `https://amphibiandisease.org/api.php`
Method: `GET`/`POST`

**Note**: The `Access-Control-Allow-Origin` header is set to `*`. This may be directly accessed by JavaScript from any origin.

Mandatory parameter: `action`

- `fetch`:
  > Queries raw data from the total dataset. Psuedoauthenticated.
  > Be aware that access may be restricted based on your login status. If you're not logged in, only public resources are queryable.
  >
  > Parameters:
  > `sql_query`: An SQL query against the raw data. When constructing your query, you'll want to use the `table` value from the JSON in the `carto_id` key. To obtain this the first time, you'll want to make an authenticated API hit with `perform=get` ([see below](#authenticated-apis))
  >
  > Response:
  > `status`: boolean
  > `sql_statements`: Array of queried statements
  > `post_response`: Array of raw responses from CartoDB
  > `parsed_responses`: Formatted responses from CartoDB

- `validate`:
  > Validates a taxon against Amphibiaweb and returns canonical information.
  >
  > The taxonomy returned may be different from the one provided if AmphibiaWeb views it as a synonym. Synonyms may also include a species gender change, which you can monitor via the notice `FUZZY_SPECIES_MATCH`.
  >
  > Parameters:
  > (req) `genus`: Genus to validate. Case-insensitive.
  > (req) `species`: Species to validate. If you only want to check for a genus, the value 'sp.' may be used here.
  > `subspecies`: Reserved for future use; currently not tracked by AmphibiaWeb.
  >
  > Response:
  > `status`: boolean
  > `aweb_list_age`: Current age of the taxonomy list being validated against
  > `aweb_list_max_age`: Maximum age of the AmphibiaWeb taxonomy used, in seconds.
  > `notices`: Array. List of non-fatal notices. Includes notices if taxonomy was changed.
  > `original_taxon`: The provided taxon, if changed. If unchanged, this field is absent.
  > `validated_taxon`: Object. The canonical taxon information

- `search_project`:

- `search_users`:





### Authenticated APIs

API target: `https://amphibiandisease.org/admin-api.php`
Method: `POST`

**Note**: The `Access-Control-Allow-Origin` header is set to `*`. This may be directly accessed by JavaScript from any origin.

Mandatory parameter: `perform`

- `list`
- `new`
- `save`
- `delete`
- `get`
  >
  > Sample Response:
  >
  > ```json
  >{
  >  "execution_time": 6.0899257659912,
  >  "project_id_raw": "ffa21641ba4266adabd59ee826a15eaa",
  >  "project_id": "ffa21641ba4266adabd59ee826a15eaa",
  >  "user": {
  >    "is_author": true,
  >    "has_view_permissions": true,
  >    "has_edit_permissions": true,
  >    "user": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb"
  >  },
  >  "project": {
  >    "project_dir_identifier": "45c66a601877cadcb32caa4181c582b4",
  >    "dataset_arks": "ark:\/21547\/AMe2::f70e11df52296545a7d61c184064f992.xlsx",
  >    "project_obj_id": "ark:\/21547\/AMd2",
  >    "extended_funding_reach_goals": "",
  >    "more_analysis_funding_request": "0",
  >    "public": true,
  >    "carto_id": "{\"table\":\"t29c7b8ff37f83116c16efc7d1e70136b&#95;6d6d454828c05e8ceea03c99cc5f547e52fcb5fb\",\"raw&#95;data\":{\"hasDataFile\":true,\"fileName\":\"f70e11df52296545a7d61c184064f992.xlsx\",\"filePath\":\"helpers\/js-dragdrop\/uploaded\/45c66a601877cadcb32caa4181c582b4\/f70e11df52296545a7d61c184064f992.xlsx\"},\"bounding&#95;polygon\":[{\"lat\":37.86,\"lng\":-122.30000000000001},{\"lat\":37.87,\"lng\":-122.2894},{\"lat\":37.88,\"lng\":-122.281},{\"lat\":37.89,\"lng\":-122.27499999999998},{\"lat\":37.8865,\"lng\":-122.28499999999997},{\"lat\":37.88,\"lng\":-122.29500000000002},{\"lat\":37.86,\"lng\":-122.30000000000001}]}",
  >    "publication": "",
  >    "pi_lab": "mkoo",
  >    "access_data": {
  >      "composite": {
  >        "tigerhawkvok@gmail.com": {
  >          "user_id": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb",
  >          "email": "tigerhawkvok@gmail.com"
  >        }
  >      },
  >      "author": "tigerhawkvok@gmail.com",
  >      "viewers_list": null,
  >      "editors_list": {
  >        "0": "tigerhawkvok@gmail.com"
  >      },
  >      "total": {
  >        "0": "tigerhawkvok@gmail.com"
  >      },
  >      "viewers": null,
  >      "editors": {
  >        "0": {
  >          "user_id": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb",
  >          "email": "tigerhawkvok@gmail.com"
  >        },
  >      }
  >    },
  >    "author_data": "{\"name\":\"Philip Kahn\",\"contact_email\":\"tigerhawkvok@gmail.com\",\"affiliation\":\"Github\",\"lab\":\"mkoo\",\"diagnostic_lab\":\"CoffeeScript\",\"entry_date\":1457399089073}",
  >    "author": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb",
  >    "transect_file": "",
  >    "radius": "2238",
  >    "bounding_box_s": "37.86",
  >    "bounding_box_w": "-122.3",
  >    "bounding_box_e": "-122.275",
  >    "bounding_box_n": "37.89",
  >    "lng": "-122.28805466667",
  >    "lat": "37.877788555556",
  >    "sample_raw_data": "https:\/\/amphibiandisease.org\/helpers\/js-dragdrop\/uploaded\/45c66a601877cadcb32caa4181c582b4\/f70e11df52296545a7d61c184064f992.xlsx",
  >    "locality": "Berkeley, CA, USA",
  >    "sample_notes": "Testing different ARKs for project and datasets. Expedition ARK should be `ark:\/21547\/AMd2`",
  >    "sample_field_numbers": "1,2,3,4,5,6,6,6,6",
  >    "sample_catalog_numbers": "PLK1,PLK2,PLK3,PLK4,PLK5,PLK6,PLK7,PLK8,PLK9",
  >    "sample_dispositions_used": "",
  >    "sample_methods_used": "",
  >    "sampling_years": "2015,2016",
  >    "sampling_months": "February,January,November",
  >    "sampled_collection_end": "1.45437e+12",
  >    "sampled_collection_start": "1.4478e+12",
  >    "sampled_species_data": "",
  >    "sampled_clades": "Plethodontidae,Bufonidae",
  >    "sampled_species": "Batrachoseps attenuatus,Anaxyrus fowleri,Batrachoseps major,Atelopus tricolor",
  >    "includes_gymnophiona": false,
  >    "includes_caudata": true,
  >    "includes_anura": true,
  >    "sample_method": "",
  >    "disease_mortality": "5",
  >    "disease_morbidity": "3",
  >    "disease_no_confidence": "1",
  >    "disease_negative": "5",
  >    "disease_positive": "3",
  >    "disease_samples": "9",
  >    "disease_strain": "",
  >    "disease": "Batrachochytridium dendrobatidus",
  >    "reference_id": "",
  >    "project_title": "test diff arks for project and datasets",
  >    "project_id": "ffa21641ba4266adabd59ee826a15eaa",
  >    "id": "39"
  >  },
  >  "human_error": null,
  >  "error": "OK",
  >  "status": true
  >}
  >```
- `mint_data`
- `create_expedition`
- `associate_expedition`
- `validate`
- `check_access`


## Data Storage

You can view  a [CSON](https://github.com/bevry/cson) representation of the data storage of the system at [./meta/data-storage.coffee](https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-storage.coffee)

There is no equivalent to [BD-Maps'](http://www.bd-maps.net/isolates/) following fields:

- Global ID: Redundant to sample ID
- Country / Continent / Region: Redundant and derivable from coordinate bounding boxes
- Elevation: Lookup-able from sample coordinates
- Accuracy: Should be built in to `radius` field.
- Coordinate source: Is the model of GPS actually relevant?
- Developmental stage: Per-sample, should be included in raw data. At a high level, redundant to `sampled_species_detail[N].sampled_life_stages`
- Method of detection: Since this may vary on a per-sample basis, this is relegated to the raw data.
- Abnormalities: Problems in data are encapsulated in `disease_no_confidence`, problems with animals belong with the raw data.
- All individual sample data (eg, spore count, genbank ID, etc): Belongs in raw data


## Configuration Data

This data is encrypted using
[BlackBox](https://github.com/StackExchange/blackbox). If you want
access to the configuration, please ask to have your credentials
added, or add it yourself in a clone and push the changes. Once you
let an administrator know, you can be added to the keyring and gain
decryption privledges.
