---
layout: post
title:  "Progress report on portal development"
date:   2016-04-18 07:00:00
author: Michelle Koo
categories: News Resources
---

Spring update on the [Amphibian Disease portal](https://amphibiandisease.org/): We are in alpha release with core features working! The beta version is in progress now. Most importantly we have outlined the framework for the portal, which is sketched out in a user's workflow diagram.

![Workflow schema](https://docs.google.com/drawings/d/1dlV446IKjq8GKNJoz0h7aLsCrKDUig0yqrGucEBq-H8/pub?w=960&h=540)

Here are the highlights:

 - Creation of Projects by Principal Investigators, where areas of effort can be identified and mapped
 - Uploading of Datasets, which are linked to Projects
 - Assigning of unique, resolvable identifiers to Projects and Datasets (e.g., minting doi's)
 - Searchable map for Project sites in the Project Browser page
 - User registration and contact information
 - Project editing by PI

_**Projects**_
Projects are the way we organize data and enable users to find past and future field and lab activities. They can be specific to a region and one-time sampling effort, e.g., "Andean frog chytrid testing in 2014", or set-up as an ongoing monitoring project, e.g., "Monitoring for Bsal in the Golden Gate National Recreation Area" (neither of which are actual projects!). Basic information on PI and contact details as well as region and description of purpose are always publicly viewable but they may have all associated datasets declared private and thus masked from public maps or searches.

Projects allows PIs to assign other users to upload datasets if students or others are to collate field and lab results.

Projects also can be associated with publications or other DOI and thus serves as a means to deposit negative and positive results.

All Projects can be viewed, searched or mapped on the [Project Browser](https://amphibiandisease.org/project.php)

_**Private vs. Public data**_
Whether datasets, that is the sampling record of species, location and disease status, are publicly viewable or private and masked from the general searches is determined by the Principal Investigator when creating the Project. This allows datasets to be encumbered and private while dissertations are written or publications are in review. Private datasets will likely have a default time span of 1 or 2 years after which time, if not renewed explicitly, will be made automatically public. Once made public, any data cannot be made private again (this is more a function of the nature of the internet and that Google bots do such a good job of scraping the web than anything we can control).

_**Project footprints**_
The Project bounding box or area of effort can be defined in multiple ways during Project creation. These polygons will appear on the Project Browser page as orange areas for public projects and purple for private. Projects should not be created without a defined area of effort.

Users can define the Project areas by either: 1) searching on a **Locality Name** so that Google Map can automatically calculate its bounding box; 2) enter a **list of coordinate pairs** to define a bounding box; 3) use the Map interface to drop pins to define an area by clicking on the map then use the **Build Map** tool to create the footprint; 4) lastly, by uploading a dataset in an XLS spreadsheet where the minimum convex polygon will be automatically calculated.

_Coming soon:_
More information on **User registration and profiles**, **Data use policy**, and **Uploading data with our XLS template**, and **DOIs and Publications**.

Send us feedback and any suggestions! [Email Michelle Koo](mailto:mkoo@berkeley.edu)

