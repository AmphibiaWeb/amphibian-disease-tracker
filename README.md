AmphibianDisease.org - ARCHIVE ONLY
===========================
_29 Jan 2020 Update:_ Amphibian Disease portal has migrated! [Read more in our blog announcement here.](http://updates.amphibiandisease.org/news/resources/2019/12/17/Important-Announcement.html) This repo is frozen at the moment during our transition. 

Please refer to our current repo at **[AmphibiaWebDiseasePortal 2.0](https://github.com/BNHM/AmphibiaWebDiseasePortal)**

Visit the new site at [AmphibianDisease.org](https://amphibiandisease.org)



## Quick Links

- [Project Site](https://amphibiandisease.org)
- [Project Dashboard](https://amphibiandisease.org/dashboard)
- [Project Contribution Page](https://amphibiandisease.org/contributing)
- [AmphibianDisease.org Code](https://github.com/BNHM/AmphibiaWebDiseasePortal)
- [AmphibianDisease.org API](https://github.com/BNHM/AmphibiaWebDiseasePortalAPI)


## Documentation

[![Documentation Status](https://readthedocs.org/projects/amphibian-disease-tracker/badge/?version=latest)](http://amphibian-disease-tracker.readthedocs.org/en/latest/?badge=latest)

See the documentation over at https://amphibian-disease-tracker.readthedocs.org/en/latest

## Features

TODO

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


## Building the application


### Dependencies

This writeup assumes you have access to a Linux-like environment. If you run Windows, set up [Bash on Ubuntu on Windows (WSL)](https://msdn.microsoft.com/en-us/commandline/wsl/about) for best results.

Your life will also be a lot easier if you have [Homebrew](https://brew.sh/) or [LinuxBrew](http://linuxbrew.sh/) installed.


#### Build dependencies

- [Yarn](https://yarnpkg.com/lang/en/docs/cli/) You can install Yarn by running `brew install yarn`
- [Grunt](http://gruntjs.com/). You can install Grunt from the command line by running `yarn global add grunt-cli`.
- Recommended: [Coffeescript](http://coffeescript.org) and [Less](http://lesscss.org/). They're included locally but often behave better globally via `yarn global add coffee-script less`
- Run `yarn install` to install local dependencies.

#### Deploy dependencies

- [Blackbox](https://github.com/StackExchange/blackbox) You can install Blackbox by runing `brew install blackbox`


### Deploying

You can update the whole application, with dependencies, by running
`grunt build` at the root directory.

If you don't need to update dependencies, just run `grunt qbuild`.

#### Installation

##### Configuration Files

If you're part of the project, your PGP public key should already be registered in the application. If you need to make changes, do:

```sh
blackbox_edit_start PATH/TO/FILE.ext.gpg
# Edit your file
blackbox_edit_end PATH/TO/FILE.ext
```

The two primary configuration files are `CONFIG.php.gpg` and `admin/CONFIG.php.gpg`
