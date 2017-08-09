> - [Main API docs](https://amphibian-disease-tracker.readthedocs.io/en/latest/APIs/)
> - [API Authentication](https://amphibian-disease-tracker.readthedocs.io/en/latest/Authenticating%20Asynchronous%20Requests/)
> - [Other APIs](https://amphibian-disease-tracker.readthedocs.io/en/latest/Other%20APIs/)

# General API information

All responses are as `application/json`.

Note that input is aggressively URL escaped. Depending on your use you may want to de-escape the text before use (especially raw JSON-as-text).

[This Github Gist](https://gist.github.com/tigerhawkvok/285b8631ed6ebef4446d) has CoffeeScript and JavaScript code to help, or [this PHP block](https://github.com/tigerhawkvok/php-core/blob/070cd80b9c5ae5526be87ae41abc0d047e5e948a/core.php#L349-L369) as a PHP helper.

## API errors

If a given query produces an error, the `status` key will be `false`.

In addition, you will always have an `error` key with technical
details. When appropriate, the server may provide a `human_error` key
with a response that's more friendly to an end user.

# Unauthenticated APIs

API target: `https://amphibiandisease.org/api.php`
Method: `GET`/`POST`

**Note**: The `Access-Control-Allow-Origin` header is set to `*`. This may be directly accessed by JavaScript from any origin.

Mandatory parameter: `action`

## Querying project samples


Queries raw data from the total dataset. **Psuedoauthenticated**.

Be aware that access may be restricted based on your login status. If you're not logged in, only public resources are queryable.  Attempting to access a non-public project will return an `UNAUTHORIZED` error.

Query security checks are case-insensitive.

| Parameter | Value |
|-----------|-------|
| `action` | `fetch` |
| `sql_query` | An SQL query against the raw data. When constructing your query, you'll want to use the `table` value from the JSON in the `carto_id` key. To obtain this the first time, you'll want to make an authenticated API hit with `perform=get` ([see below](#authenticated-apis)) |

Response:


| Key | Detail                                       |
|-----|----------------------------------------------|
| `status` | `true` or `false` (boolean) |
| `sql_statements`  | Array of queried statements  |
| `post_response`  | Array of raw responses from CartoDB |
| `parsed_responses`  | Formatted responses from CartoDB  |


In general, most queries are restricted for all projects that are not flagged with `public = true`. For compatibility reasons, if a CartoDB table isn't associated with a `project_id`, then the queries are unrestricted.

For all projects, the query to view columns

```sql
SELECT * FROM t1234567890 WHERE FALSE;
```

is permitted, again largely for compatibility reasons.

**Please note**: For security reasons, the name format of the table is **restricted**. The table name **must** start with `t`, then be followed by the hexadecimal character set (`[a-fA-f0-9]`) with up to one underscore (`_`). All your queries will fail as unauthenticated if the table name doesn't match this regular expression:

```regex
/(?i)(t[0-9a-f]+[_]?[0-9a-f]*)/
```

## Search projects by data criteria

Find projects matching certain classes of criteria. This is the back-end that drives the search on the main index page.


| Parameter | Value | Description | Required? |
|-----------|-------|-------------|-----------|
| `action`  | `foo` | foo | **true** |


### Response

| Key | Value | Description |
|-----|-------|-------------|
| `status` | boolean | **true** for successful lookup, **false** on error |


## Chart Data

Returns the semiauthorized data formatted for charts from the database.

| Parameter | Value | Description | Required? |
|-----------|-------|-------------|-----------|
| `action`  | `chart` | Mandatory | **true** |
| `bin`  | string | Controlled vocabulary `time`, `species`, `location`, or `infection` (default). Controls the grouping of the returned chart data. **Note**: `time` is currently nonfunctional. | **false** |
| `sort`  | string | For bin `species`, "species" or "genus" (defaults to "genus").  For bin `location`, any valid column (defaults to "samples")  | **false** |
| `disease`  | string | Controlled vocabulary `bd` or `bsal` to only include results for those diseases. Any other string or nullish returns both diseases. | **false** |
| `include_sp`  | boolean | **true** to include undescribed species, **false** to ignore them. Default **false** | **false** |


### Response

To see the formatted data, view the  Data Dashboard page.

| Key | Value | Description |
|-----|-------|-------------|
| `status` | boolean | **true** for successful lookup, **false** on error |
| `data` | `json` |  Data for the chart application |
| `axes` | object | Subkeys `x` and `y` for axis titles |
| `title` | string | Chart title |
| `use_preprocessor` | boolean | If the results need a preprocessor before being run through the chart application |
| `rows` | int | Number of data rows |
| `format` | string | The data format, eg, "chart.js" |
| `provided` | object | formatted provided data |
| `full_description` | string | Description of the chart output |
| `basedata` | `json` | Source data |


## Taxon Data

Gets data for an individual taxon.

| Parameter | Value | Description | Required? |
|-----------|-------|-------------|-----------|
| `action`  | `taxon` | Mandatory | **true** |

### Response

| Key | Value | Description |
|-----|-------|-------------|
| `status` | boolean | **true** for successful lookup, **false** on error |

### IUCN Data

You can specify getting just the IUCN subset of data.

| Parameter | Value | Description | Required? |
|-----------|-------|-------------|-----------|
| `action`  | `iucn` | foo | **true** |

### Response

| Key | Value | Description |
|-----|-------|-------------|
| `status` | boolean | **true** for successful lookup, **false** on error |

### AmphibiaWeb data

You can specify fetting just the AmphibiaWeb subset of data.

| Parameter | Value | Description | Required? |
|-----------|-------|-------------|-----------|
| `action`  | `aweb` | foo | **true** |

### Response

| Key | Value | Description |
|-----|-------|-------------|
| `status` | boolean | **true** for successful lookup, **false** on error |

## Validating / Updating Taxa

Validates a taxon against Amphibiaweb and returns canonical information.

The taxonomy returned may be different from the one provided if AmphibiaWeb views it as a synonym. Synonyms may also include a species gender change, which you can monitor via the `notices` response key for `FUZZY_SPECIES_MATCH`.

Parameters:

| Parameter | Value |
|-----------|-------|
| `action` | `validate` |
| `genus` |  Genus to validate. Case-insensitive. |
| `species` | Species to validate.<sup>\*</sup> |
| `subspecies` | **Optional:** Reserved for future use; currently not tracked by AmphibiaWeb. |

<sup>\*</sup>**Genus only validation**: You can validate only the genus by providing a species name `sp.` For the purposes of application-based validation, it may also be `nov. sp.`, with or without the `.` after `nov` or `sp`, and may be trailed by up to one space and any number of digits thereafter. That is to say, `nov sp 3`, `sp. 2`, `nov. sp.`, etc. are all "species" that will trigger genus-only validation (as are any other strings [that match the regular expression `/^(nov[.]{0,1} ){0,1}(sp[.]{0,1}([ ]{0,1}\d+){0,1})$/m`](http://regexr.com/3d1kb)). The "validated species" in the response will be normalized.

Response:

| Key | Detail                                       |
|-----|----------------------------------------------|
| `status` | `true` or `false` (boolean) |
| `aweb_list_age` | Current age of the taxonomy list being validated against  |
| `aweb_list_max_age` | Maximum age of the AmphibiaWeb taxonomy used, in seconds.  |
| `notices` | Array. List of non-fatal notices. Includes notices if taxonomy was changed.  |
| `original_taxon` | The provided taxon, if changed. If unchanged, this field is absent.  |
| `validated_taxon` | Object. The canonical taxon information. Most relevant keys would be `genus` and `species`. |

Please note that generic names are not necessarily capitalized. It is assumed that this will be taken care of presentationally when parsed, eg,

```coffee
html = """
<span style="text-transform:capitalize;">#{response.validated_taxon.genus}</span> #{response.validated_taxon.species}
"""
```

Sample response:

*query: `https://amphibiandisease.org/api.php?action=validate&genus=bufo&species=boreas`*

```json
{
  "execution_time": 173.39897155762,
  "validated_taxon": {
    "taxon_notes_public": "",
    "uri_or_guid": "http:\/\/amphibiaweb.org\/species\/122",
    "aweb_uid": "122",
    "intro_isocc": "",
    "isocc": {
      "2": "MX",
      "1": "CA",
      "0": "US"
    },
    "iucn": "Near Threatened (NT)",
    "itis_names": {
      "1": "Bufo politus",
      "0": "Bufo boreas"
    },
    "synonymies": "",
    "gaa_name": "Anaxyrus boreas",
    "common_name": {
      "2": "California Toad (<i>B. b. halophilus<\/i>)",
      "1": "Boreal Toad (<i>B. b. boreas<\/i>)",
      "0": "Western Toad"
    },
    "species": "boreas",
    "subgenus": "",
    "genus": "Anaxyrus",
    "subfamily": "",
    "family": "Bufonidae",
    "order": "Anura"
  },
  "original_taxon": "bufo boreas",
  "aweb_list_max_age": 86400,
  "aweb_list_age": 13,
  "notices": {
    "0": "Your entry 'bufo boreas' was a synonym in the AmphibiaWeb database. It was automatically converted to the canonical taxon."
  },
  "args_provided": {
    "species": "boreas",
    "genus": "bufo",
    "action": "validate"
  },
  "status": true
}
```

## Find a specific project

Search for a project based on criteria. This is the back-end that drives the project search on [the Project Browser page](https://amphibiandisease.org/project.php).

Parameters:

| Parameter | Value |
|-----------|-------|
| `action` | `search_projects` |
| `q` | The query value to search against |
| `cols` | **Optional:** The columns to search against, as comma-separated values. Defaults to `project_id,project_title`. |

In the project browser, the radio buttons map as follows:

- Project Names & IDs: `project_id,project_title`
- PIs, Labs, Creators, Affiliation: `author_data`
- Project Taxa: `sampled_species,sampled_clades`

If any column is specified that does not exist, the defaults will be used (even if the rest are valid).

Response:

| Key      | Detail                      |
|----------|-----------------------------|
| `status` | `true` or `false` (boolean) |
| `cols` | Array. List of columns searched. |
| `result` | Array. Each item has `project_id`, `project_title`, and `public` as keys. |
| `count` | Number of results |


## Find a user

Find a user in the database. Searches email, name, and handle. Returns all partial string matches.

Parameters:

| Parameter | Value |
|-----------|-------|
| `action` | `search_users` |
| `q` | Search query |

Response:

| Key | Detail                                       |
|-----|----------------------------------------------|
| `status` | `true` or `false` (boolean) |
| `result` | Array of results, each an object containing `email`, `uid`, `handle`, `first_name`, `last_name`, and `full_name` |
| `count` | Total number of results |




# Authenticated APIs

API target: `https://amphibiandisease.org/admin-api.php`
Method: `POST`

**Note**: The `Access-Control-Allow-Origin` header is set to `*`. This may be directly accessed by JavaScript from any origin.

Mandatory parameter: `perform`

## Listing accessible projects

**Psuedoauthenticated**. If this is hit without authentication, a list of public projects will be returned.

Parameters:

| Parameter | Value  |
|-----------|--------|
| `perform` | `list` |

Response:

| Key | Detail                                       |
|-----|----------------------------------------------|
| `status` | `true` or `false` (boolean) |
| `projects` | Array of projects, as `projectId: "projectName"` key:value pairs. |
| `public_projects` | Array of project IDs for public projects in this list |
| `authored_projects` | Array of project IDs for projects authored by the checking user |
| `editable_projects` | Array of project IDs for projects editable by the checking user |
| `check_authentication` | `true` or `false` if the authentication status of the user was checked |

Private, view-only projects are not returned as their own entry. They are the entries in `response.projects` that are not in `response.public_projects`, `response.authored_projects`, or `response.editable_projects`.

## Create a new project

**Requires an [unrestricted account](Creating%20a%20New%20Project/#restricted-vs-unrestricted-profiles)**

Parameters:

| Parameter | Value |
|-----------|-------|
| `perform` | `new` |

Response:

| Key      | Detail                      |
|----------|-----------------------------|
| `status` | `true` or `false` (boolean) |

## Save changes to a project

Parameters:

| Parameter | Value  |
|-----------|--------|
| `perform` | `save` |

Response:

| Key      | Detail                      |
|----------|-----------------------------|
| `status` | `true` or `false` (boolean) |

## Delete a project

Parameters:

| Parameter | Value    |
|-----------|----------|
| `perform` | `delete` |

Response:

| Key      | Detail                      |
|----------|-----------------------------|
| `status` | `true` or `false` (boolean) |

## Get project details

Get the details of a project

Parameters:

| Parameter | Value |
|-----------|-------|
| `perform` | `get` |
| `project` | The ID string of the project |

Response:

| Key | Detail                                       |
|-----------|-----------------------------------------------------|
| `status` | `true` or `false` (boolean) |
| `project_id` | ID of the project |
| `user`  | Permission details of the user making this request  |
| `project`  | Actual project details. Detailed key information is available [on Github in the  `./meta/data-storage.coffee` file, with comments](https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-storage.coffee). However, note that some columns will contain parsed information, rather than raw database information, such as `access_data`.  |


Please note that if you're not authorized to view the project, you'll recieve an `ACCESS_AUTHORIZATION_FAILED` error.

Sample Response:

```json
{
  "execution_time": 6.0899257659912,
  "project_id_raw": "ffa21641ba4266adabd59ee826a15eaa",
  "project_id": "ffa21641ba4266adabd59ee826a15eaa",
  "user": {
    "is_author": true,
    "has_view_permissions": true,
    "has_edit_permissions": true,
    "user": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb"
  },
  "project": {
    "project_dir_identifier": "45c66a601877cadcb32caa4181c582b4",
    "dataset_arks": "ark:\/21547\/AMe2::f70e11df52296545a7d61c184064f992.xlsx",
    "project_obj_id": "ark:\/21547\/AMd2",
    "extended_funding_reach_goals": "",
    "more_analysis_funding_request": "0",
    "public": true,
    "carto_id": "{\"table\":\"t29c7b8ff37f83116c16efc7d1e70136b&#95;6d6d454828c05e8ceea03c99cc5f547e52fcb5fb\",\"raw&#95;data\":{\"hasDataFile\":true,\"fileName\":\"f70e11df52296545a7d61c184064f992.xlsx\",\"filePath\":\"helpers\/js-dragdrop\/uploaded\/45c66a601877cadcb32caa4181c582b4\/f70e11df52296545a7d61c184064f992.xlsx\"},\"bounding&#95;polygon\":[{\"lat\":37.86,\"lng\":-122.30000000000001},{\"lat\":37.87,\"lng\":-122.2894},{\"lat\":37.88,\"lng\":-122.281},{\"lat\":37.89,\"lng\":-122.27499999999998},{\"lat\":37.8865,\"lng\":-122.28499999999997},{\"lat\":37.88,\"lng\":-122.29500000000002},{\"lat\":37.86,\"lng\":-122.30000000000001}]}",
    "publication": "",
    "pi_lab": "mkoo",
    "access_data": {
      "composite": {
        "tigerhawkvok@gmail.com": {
          "user_id": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb",
          "email": "tigerhawkvok@gmail.com"
        }
      },
      "author": "tigerhawkvok@gmail.com",
      "viewers_list": null,
      "editors_list": {
        "0": "tigerhawkvok@gmail.com"
      },
      "total": {
        "0": "tigerhawkvok@gmail.com"
      },
      "viewers": null,
      "editors": {
        "0": {
          "user_id": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb",
          "email": "tigerhawkvok@gmail.com"
        },
      }
    },
    "author_data": "{\"name\":\"Philip Kahn\",\"contact_email\":\"tigerhawkvok@gmail.com\",\"affiliation\":\"Github\",\"lab\":\"mkoo\",\"diagnostic_lab\":\"CoffeeScript\",\"entry_date\":1457399089073}",
    "author": "6d6d454828c05e8ceea03c99cc5f547e52fcb5fb",
    "transect_file": "",
    "radius": "2238",
    "bounding_box_s": "37.86",
    "bounding_box_w": "-122.3",
    "bounding_box_e": "-122.275",
    "bounding_box_n": "37.89",
    "lng": "-122.28805466667",
    "lat": "37.877788555556",
    "sample_raw_data": "https:\/\/amphibiandisease.org\/helpers\/js-dragdrop\/uploaded\/45c66a601877cadcb32caa4181c582b4\/f70e11df52296545a7d61c184064f992.xlsx",
    "locality": "Berkeley, CA, USA",
    "sample_notes": "Testing different ARKs for project and datasets. Expedition ARK should be `ark:\/21547\/AMd2`",
    "sample_field_numbers": "1,2,3,4,5,6,6,6,6",
    "sample_catalog_numbers": "PLK1,PLK2,PLK3,PLK4,PLK5,PLK6,PLK7,PLK8,PLK9",
    "sample_dispositions_used": "",
    "sample_methods_used": "",
    "sampling_years": "2015,2016",
    "sampling_months": "February,January,November",
    "sampled_collection_end": "1.45437e+12",
    "sampled_collection_start": "1.4478e+12",
    "sampled_species_data": "",
    "sampled_clades": "Plethodontidae,Bufonidae",
    "sampled_species": "Batrachoseps attenuatus,Anaxyrus fowleri,Batrachoseps major,Atelopus tricolor",
    "includes_gymnophiona": false,
    "includes_caudata": true,
    "includes_anura": true,
    "sample_method": "",
    "disease_mortality": "5",
    "disease_morbidity": "3",
    "disease_no_confidence": "1",
    "disease_negative": "5",
    "disease_positive": "3",
    "disease_samples": "9",
    "disease_strain": "",
    "disease": "Batrachochytridium dendrobatidus",
    "reference_id": "",
    "project_title": "test diff arks for project and datasets",
    "project_id": "ffa21641ba4266adabd59ee826a15eaa",
    "id": "39"
  },
  "human_error": null,
  "error": null,
  "status": true
}
```

## Validate Project Data

Validate the project data against [the FIMS system](https://fims.readthedocs.org/en/latest/)

Please note the source file needs to exist locally on the host server.

Parameters:

| Parameter | Value  |
|-----------|--------|
| `perform` | `validate` |
| `datasrc` | Server relative path to the file to be validated |
| `project` | Project ID of project with existing BiSciCol expedition (has an ARK) |

Response:

| Key      | Detail                      |
|----------|-----------------------------|
| `status` | `true` or `false` (boolean) |
| `validate_status` | `true` or `false` (boolean) |
| `responses` | Object of raw response data. Most important fields here are `validate_response` and `validate_has_error` |
| `post_params` | Details on what was sent to FIMS |
| `data` | Details on the datafile sent to FIMS |


## Get Project Access Lists

Parameters:

| Parameter | Value  |
|-----------|--------|
| `perform` | `check_access` |
| `project` | The project ID |

Response:

| Key      | Detail                      |
|----------|-----------------------------|
| `status` | `true` or `false` (boolean) reflects your ability to view the project |
| `project`| The project ID you looked up |
| `detailed_authorization` | The full authorization lists |
| `details` | If you're authorized to view the project, details about the project as per `perform=get` above. Otherwise, this key will not be present. |

## Edit Project Access Lists

Parameters:

| Parameter | Value  |
|-----------|--------|
| `perform` | `edit_access` |

Response:

| Key      | Detail                      |
|----------|-----------------------------|
| `status` | `true` or `false` (boolean) |
