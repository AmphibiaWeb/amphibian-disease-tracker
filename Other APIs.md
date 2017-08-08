There are a few other API endpoints for data that doesn't fit nicely into [the main API files](https://amphibian-disease-tracker.readthedocs.io/en/latest/APIs/).

## Dashboard API

| Target | Required Parameters | Method | Response Type |
|--------|---------------------|--------|----------|
| https://amphibiandisease.org/dashboard.php | `async=true` | `GET` or `POST` | `JSON` |

Note that these results will, by default, only include **public data**. If you have access to, and wish to use, private data, be sure you're logged in and forward your credential cookies with your request.

### Taxon Existence

Provides an endpoint to check for the existence of data for a taxon in the database.

| Parameter | Value | Description | Required? |
|-----------|-------|-------------|-----------|
| `action`  | `taxon_exists` | Mandatory parameter | **true** |
| `taxon` | String | Case-insensitive taxon string | **true** |

The taxon is provided as a simple string. At least a genus is required, and either `+` or a URL-encoded space (`%20`) should be used to join the taxon components. This is case-insensitive.

Valid query taxa include:

- "batrachoseps attenuatus"
- "Rana"
- "salamandra"

See [this Gist](https://gist.github.com/tigerhawkvok/7d89af3e9bf1bbaf09653b12b8a8e159#file-insertlink-coffee-L114-L177) for a sample script that inserts a link if the taxon exists.

#### Response

| Key | Value | Description |
|-----|-------|-------------|
| `status` | boolean | **true** for successful lookup, **false** on error |
| `exists` | boolean | **true** if the taxon exists in the database, **false** if not |
| `taxon` | object | Details on the lookup taxon |
| `taxon -> provided` | string | Your read input; subkey `interpreted` gives the parsed input taxon broken into keys `genus`, `species`. The key `dwc` contains the DarwinCore values for these terms. Subspecies is ignored. |
| `taxon -> interpreted` | object | Gives the parsed input taxon broken into subkeys. Subspecies is ignored. |
| `taxon -> interpreted -> genus` | string | Gives the parsed genus. |
| `taxon -> interpreted -> species` | string | Gives the parsed species. |
| `taxon -> interpreted -> dwc` | object | Gives the parsed taxon as per the sibling keys, but with DawrinCore labels. |

#### Possible Errors

| Error | Description |
|-------|-------------|
| `DATABASE_ERROR_2` | Application error performing your query |

Note that if you want to check for the validity of the taxon, [you should instead use this endpoint](https://amphibian-disease-tracker.readthedocs.io/en/latest/APIs/#validating-updating-taxa).


### Taxa Per Country

Provides an endpoint to get a list of taxa present in a country.

| Parameter | Value | Description | Required? |
|-----------|-------|-------------|-----------|
| `action`  | `country_taxon` | Mandatory parameter | **true** |
| `country` | string | Case-insensitive country name, like "united states". | **true** |

#### Response

| Key | Value | Description |
|-----|-------|-------------|
| `status` | boolean | **true** for successful lookup, **false** on error |
| `country` | string | Interpreted lookup country |
| `taxa` | int | Number of unique taxa found |
| `data` | object | One subkey per taxon, eg, subkey `Aneides lugubris`. |
| `data -> [taxon]` | object | Data on disease prevalence for this taxon |
| `data -> [taxon] -> true` | int | Number of positive samples |
| `data -> [taxon] -> false` | int | Number of negative samples |
| `data -> [taxon] -> no_confidence` | int | Number of samples where the data are inconclusive |


#### Possible Errors

| Error | Description |
|-------|-------------|
| `COUNTRY_NOT_FOUND` | Couldn't interpret the country you requested |
| `DATABASE_ERROR_1` | Application error performing your query |

### Locale Taxa

Not yet live