project_id:
  type: "varchar(255)"
  logical: "string"
  unique: true
project_title:
  type: "varchar(512)"
  logical: "string"
reference_id:
  # For offsite references. No internal use.
  # Could be initial, GUID, etc.
  type: "varchar(255)"
  logical: "string"
disease:
  # Project-wide
  type: "varchar(255)"
  logical: "string"
disease_strain:
  # Project-wide
  type: "varchar(255)"
  logical: "string"
disease_samples:
  # Computed. Roughly number of rows in dataset.
  type: "int"
  logical: "Number of total samples"
disease_positive:
  # Computed sum
  type: "int"
disease_negative:
  # Computed sum
  type: "int"
disease_no_confidence:
  # Computed sum
  type: "int"
disease_morbidity:
  # Computed sum
  type: "int"
  logical: "Number of sick individuals"
disase_mortality:
  # Computed sum
  type: "int"
  logical: "Number of individuals who died"
sample_method:
  # List of unique sample methods
  type: "varchar(255)"
  logical: "string"
includes_anura:
  # Computed, from AW clade lookup
  type: "boolean"
includes_caudata:
  # Computed, from AW clade lookup
  type: "boolean"
includes_gymnophiona:
  # Computed, from AW clade lookup
  type: "boolean"
sampled_species:
  # Computed list from unique
  type: "text"
  logical: "csv"
  sample: "Batrachoseps attenuatus, Lithobates catesbeianus"
sampled_clades:
  # Clades sampled. Appx. Linnean "family". Computed list of unique
  type: "text"
  logical: "csv"
  sample: "plethodontidae, ranoidea"
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
      sample_method: "swab_live"
      sample_disposition: "released"
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
      sample_method: "swab_preserved"
      sample_disposition: "destroyed"
sample_collection_start:
  # Computed from sample dates
  type: "int"
  logical: "Linux epoch date"
sample_collection_end:
  # If blank on user input, default to the same as collection_start
  type: "int"
  logical: "Linux epoch date"
sampling_months:
  # Calculated
  type: "varchar(24)"
  logical: "MM CSV"
sampling_years:
  # Calculated
  type: "varchar(255)"
  logical: "YYYY CSV"
sample_methods_used:
  # Calculated from detailed data
  type: "text"
  logical: "csv"
sample_dispositions_used:
  # Calculated from detailed data
  type: "text"
  logical: "csv"
sample_catalog_numbers:
  # Calculated from detailed data
  type: "text"
  logical: "csv"
sample_field_numbers:
  # Calculated from detailed data
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
  # Input from UI
  type: "text"
  logical: "Markdown text of high-level notes"
locality:
  # Human-friendly location marker. Reverse geocode lookup
  type: "text"
  logical: "location"
lat:
  # Representative location of the transect. Mean of points from data.
  type: "double"
  logical: "number"
lng:
  # Representative location of the transect. Mean of points from data.
  type: "double"
  logical: "number"
radius:
  # The radius of a circle encompassing collection area/transect, in
  # meters
  type: "long"
  logical: "natural number"
bounding_box_n:
  # North coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
bounding_box_e:
  # East coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
bounding_box_s:
  # South coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
bounding_box_w:
  # West coordinate of bounding box (for area searches)
  type: "double"
  logical: "number"
transect_file:
  # relative path to KML file of transect coordinates
  type: "varchar(255)"
  logical: "File path"
author:
  # May be edited to another access_data member
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
pi_lab:
  type:"varchar(255)"
  logical: "Lab PI"
access_data:
  # Who can access this data?
  # The author is always permitted
  # All other entries are user links in CSV
  # This field is ignored if "public" is truthy
  # If the value of this field is "link", then it's unlisted but
  # available without login
  type: "text"
  logical: "csv"
  sample: "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33,62cdb7020ff920e5aa642c3d4066950dd1f01f4d"
publication:
  type: "varchar(255)"
  logical: "doi"
public:
  # Overrides access_data for reads; access data always controls writes.
  type: "boolean"
  logical: "boolean"
carto_id:
  # CartoDB identifier for this dataset.
  type: "varchar(255)"
  logical: "json"
  sample: "{'viz':'2b13c956-e7c1-11e2-806b-5404a6a683d5','table':'t62b61b0091e633029be9332b5f20bf74_6d6d454828c05e8ceea03c99cc5f5'}"
more_analysis_funding_request:
  # Does the group doing this research have other goals that want more funding?
  # After
  # https://github.com/tigerhawkvok/amphibian-disease-tracker/issues/3
  type: "boolean"
  logical: "boolean"
extended_funding_reach_goals:
  # After
  # https://github.com/tigerhawkvok/amphibian-disease-tracker/issues/3
  type: "text"
  logical: "csv"
