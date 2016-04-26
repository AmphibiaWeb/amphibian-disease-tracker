# Data Storage

You can view  a [CSON](https://github.com/bevry/cson) representation of the data storage of the system at [`./meta/data-storage.coffee` here](https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/meta/data-storage.coffee)

The file `DB_CONFIG.php` should have all the columns as represented in the CSON file above.

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


# Configuration Data

This data is encrypted using
[BlackBox](https://github.com/StackExchange/blackbox). If you want
access to the configuration, please ask to have your credentials
added, or add it yourself in a clone and push the changes. Once you
let an administrator know, you can be added to the keyring and gain
decryption privledges.
