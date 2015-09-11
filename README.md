AW Disease Tracker Portal
==========================

## Data Storage

This is a [CSON](https://github.com/bevry/cson) representation of the data storage of the system.


```coffee
sample_id:
  type: "varchar(255)"
  logical: "string"
  unique: true
disease:
  type: "varchar(255)"
  logical: "string"
disease_samples:
  type: "int"
  logical: "Number of total samples"
disease_positive:
  type: "int"
disease_negative:
  type: "int"
disease_no_confidence:
  type: "int"
disease_morbidity:
  type: "int"
  logical: "Number of sick individuals"
disase_mortality:
  type: "int"
  logical: "Number of individuals who died"
sample_method:
  type: "varchar(255)"
  logical: "string"
includes_anura:
  type: "boolean"
includes_caudata:
  type: "boolean"
includes_gymnophiona:
  type: "boolean"
sampled_species:
  type: "text"
  logical: "csv"
  sample: "Batrachoseps attenuatus, Lithobates catesbeianus"
sampled_species_detail:
  # Detailed data for the sampled species.
  # For use on record pages and for search fallbacks
  type: "text"
  logical: "json"
  sample:
    0:
      genus: "batrachoseps"
      species: "attenuatus"
      subspecies: null
      amphibiaweb_reference: "http://amphibiaweb.org/cgi/amphib_query?where-genus=Batrachoseps&where-species=attenuatus&account=amphibiaweb"
      synonyms: # Valid at some point
        genus: ["foo"]
        species: ["bar","baz"]
        subspecies: []
      demoted: # Typos
        genus: ["batracosepts"]
        species: []
        subspecies: []
      wild: true
      invasive: false
      positive: 25
      negative: 4
      no_confidence: 1
      mortality: 20
      morbidity: 24
      sampled_life_stages: "adult, juvenile"
    1:
      genus: "lithobates"
      species: "catesbeianus"
      subspecies: null
      amphibiaweb_reference: "http://www.amphibiaweb.org/cgi/amphib_query?rel-common_name=like&where-scientific_name=rana+catesbeiana&account=amphibiaweb"
      synonyms:
        genus: ["rana", "aquarana"] # Include subgenera. The long road to truly dichotomous phylogenies ...
        species: ["catesbeiana"]
        subspecies: []
      demoted:
        genus: []
        species: []
        subspecies: []
      wild: true
      invasive: false
      positive: 15
      negative: 30
      no_confidence: 0
      mortality: 6
      morbidity: 10
      sampled_life_stages: "adult, tadpole"
sample_collection_start:
  type: "int"
  logical: "Linux epoch date"
sample_collection_end:
  type: "int"
  logical: "Linux epoch date"
sample_methods_used:
  type: "text"
  logical: "csv"
samples_raw_data:
  # File path to 7z archive of data
  # Why 7z? Because it's a free, open-source standard
  # https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Markov_chain_algorithm
  # http://www.7-zip.org/sdk.html
  type: "varchar(255)"
  logical: "file path"
sample_notes:
  type: "text"
  logical: "Markdown text of high-level notes"
lat:
  type: "double"
  logical: "number"
lng:
  type: "double"
  logical: "number"
radius:
  # The radius of a circle encompassing collection area/transect, in
  # meters
  type: "long"
  logical: "natural number"
bounding_box_nw:
  # Northwest coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
bounding_box_ne:
  # Northeast coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
bounding_box_se:
  # Southeast coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
bounding_box_sw:
  # Southwest coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
transect_file:
  # relative path to KML file of transect coordinates
  type: "varchar(255)"
  logical: "File path"
author:
  type: "varchar(255)"
  logical: "User hardlink reference" # See the userhandler code in admin/
  sample: "bbe960a25ea311d21d40669e93df2003ba9b90a2"
author_data:
  type: "text"
  logical: "json"
  sample:
    0:
      name: "Bob smith"
      affiliation: "UC Berkeley"
      lab: "Wake lab"
      entry_date: "1442007442" # Linux Epoch time
access_data:
  # The author is always permitted
  # This field is ignored if "public" is truthy
  type: "text"
  logical: "csv"
  sample: "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33,62cdb7020ff920e5aa642c3d4066950dd1f01f4d"
publication:
  type: "varchar(255)"
  logical: "doi"
public:
  type: "boolean"
  logical: "boolean"

```

There is no equivalent to [BD-Maps'](http://www.bd-maps.net/isolates/) following fields:

- Global ID: Redundant to sample ID
- Country / Continent / Region: Redundant and derivable from coordinate bounding boxes
- Elevation: Lookup-able from sample coordinates
- Accuracy: Should be built in to `radius` field.
- Coordinate source: Is the model of GPS actually relevant?
- Developmental stage: Per-sample, should be included in raw data. At a high level, redundant to `sampled_species_detail[N].sampled_life_stages`
- Method of detection: Since this may vary on a per-sample basis, this is relegated to the raw data.
- Abnormalities: Problems in data are encapsulated in `disease_no_confidence`, problems with animals belong with the raw data.


## Secret Server Data

This data is encrypted using
[BlackBox](https://github.com/StackExchange/blackbox). If you want
access to the configuration, please ask to have your credentials
added, or add it yourself in a clone and push the changes. Once you
let an administrator know, you can be added to the keyring and gain
decryption privledges.
