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
samples_raw_data:
  # File path to 7z archive of data
  # Why 7z? Because it's a free, open-source standard
  # https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Markov_chain_algorithm
  # http://www.7-zip.org/sdk.html
  type: "varchar(255)"
  logical: "file path"
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
      entry_date: "1442007442" # Linux Epoch time
access_data:
  # The author is always permitted
  # This field is ignored if "public" is truthy
  type: "text"
  logical: "csv"
  sample: "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33,62cdb7020ff920e5aa642c3d4066950dd1f01f4d"
public:
  type: "boolean"
  logical: "boolean"
