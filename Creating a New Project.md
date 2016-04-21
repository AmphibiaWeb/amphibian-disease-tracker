# Restricted vs. Unrestricted Profiles

When you create an account, your default account access is **restricted**.

Restricted users have access to most of the system:

- You can view project contacts without answering the captcha
- You can be added to an existing project as a viewer, editor, or even as a new owner
- You have access to the administration panel, with lists of projects you have access to
- Most [API hits](/APIs) will work for you

The only thing you cannot do is create a new project.

## Getting your user unrestricted

To get your user unrestricted, you must:

1. Verify your email. From your [Account Settings](https://amphibiandisease.org/admin-login.php), click "verify" and click the link or input the code provided to prove ownership.
2. Have an email address that *either* matches the list of approved [TLDs](https://en.wikipedia.org/wiki/Top-level_domain) or [domains](https://en.wikipedia.org/wiki/Domain_name) (minus TLD).
3. If your username (the email you signed up with) doesn't match (2), you can add and verify an "alternate email" in [Account Settings](https://amphibiandisease.org/admin-login.php) to meet those criteria.

At this time, to have a unrestricted user, you must meet the following criteria:

| Domain | TLD |
|--------|-----|
| Any    | .gov, .edu |

Once you've met those criteria, you can create a project at any time. Until you do, clicking on the badge by your name in Administration, or clicking the unrestriction button that is first in the admin panel.


# Creating a Project

First, visit [https://amphibiandisease.org/admin](https://amphibiandisease.org/admin) to log in or create a user.

From there, you'll be confronted with this page:

PAGE SCREENSHOT

Click "Create Project", and you'll get the project creator page.

Fields with a red underline are invalid (or empty and mandatory) entries.

TODO

## Without Data

After the "Build Map" option and map interface, find the checkbox that says "My project already has data", and uncheck it.

If you leave this button checked, the system will not let you save the project until you've uploaded a dataset.

## With Data

All the steps above, in "[Without Data](#without-data)", are still valid -- there are now just more options.

### Getting your Template

We have partnered with [BiSciCol.org](http://biscicol.org) to provide a template generator for your project.

If you go to [http://biscicol.org/biocode-fims/templates.jsp](http://biscicol.org/biocode-fims/templates.jsp), and from the dropdown select "Amphibian Disease", you can get a template from which to start working.

The file you get will be an Excel 2007+ format (`.xlsx`) file. All your sample data should be in the worksheet title `Samples`. If you wish to use a different worksheet name, please be sure that it is the first worksheet in the notebook. **If you do not do this, your validation will always fail, and you will not be able to upload data to the system**.

If you would like to save your data in a non-proprietary format, saving it as a `.csv` file is also accepted. All CSV files should conform to [RFC4180](https://tools.ietf.org/html/rfc4180). Please be aware that if you use a Microsoft product, depending on the version, it may not conform properly to this standard and your data may be processed incorrectly.

The file should either have a header row, or use the order presented at BiSciCol.org.

### Uploading your project data

You'll find on the page a box that says "Drop your files here to upload" under the heading "Uploading your project data". You can drag and drop files from your filesystem into that box to upload files to the server. You may also use the blue button with an arrow pointing into a cloud to upload your files.

You may upload more than just a datafile to your project; the system will also accept images (anything with a [MIME type](https://en.wikipedia.org/wiki/Media_type) beginning with `image/`), `zip` files, and `7z` ([7-zip](https://en.wikipedia.org/wiki/7-Zip), open-source compression better than zip) files. At the time of this writing, these are not yet exposed in your project's viewer, but the feature is incoming.

When you upload your data, you'll be given several progress bars that complete sequentially. This will notify you if you have any problems with your data, and where they may occur. Handling your data upload occurs like this:

| Step | Relative Speed | Action | Possible Errors |
|------|----------------|--------|-----------------|
| Data Parsing | Fast | Does a quick check for most important attributes of datafile before slower steps | Missing columns, no rows, bad data types for obvious columns from a random row. An error summary will be provided in a hanging alert from the top of the screen. |
| Data Validation | Moderate | Does a full row-by-row data validatation with BiSciCol.org | Many. A full table of errors will be provided if any are found, as well as a short summary hanging from the top of the screen |
| Taxa Validation | Moderate-Slow | For each distinct species, validates against our [API](https://amphibian-disease-tracker.readthedocs.org/en/latest/APIs/#validating-updating-taxa). | See our [API documentation](https://amphibian-disease-tracker.readthedocs.org/en/latest/APIs/#validating-updating-taxa) for all possible errors. Taxa replacements will generate a (non-fatal) notice above the species list in the "Project Data Summary" later in the page. |
| Data Sync | Slow | Formats your data for CartoDB and uploads it to CartoDB. Scales roughly linearly with rows, and largely dependent on the connection from our servers to CartoDB. | Upload failure, if CartoDB rejects the data for any reason. |


You are allowed only one active datafile per project, and only one datafile at creation time. If you try to upload another, you'll be prompted to either keep your existing one or to replace it.

**IMPORTANT**: Uploading your data does NOT save your data to the system. If you quit before saving your project, your dataset will live on CartoDB, but not be associated with a project and inaccessible. You will have to upload it again to associate it with a new project.

## Saving

Before you click the save button, read it! It will give you feedback on what it thinks your project creation parameters are.

If your project is private, make sure that the button says you're creating a private project, and the symbol is of a lock. Remember, once a project is made public it can never be made private.

If your project is public, make sure that the button says public and the symbol is that of a globe. If you accidentally make a project private, you can easily make it public via a toggle on the editor.

If you've uploaded data, the save button will state "Save Data", as well. If it does not say that, your data will **not** be saved.

Once you click the save button, your data will be processed and saved to the server. Upon project saving, your datafile will be given an ARK identifier (such as `ark:/21547/ANU2`), resolvable by the Name2Thing service (eg, [https://n2t.net/ark:/21547/ANU2](https://n2t.net/ark:/21547/ANU2)). The system will then load the project editor immediately. To view your project, click the eye icon next to the project title.

If you have a datafile, upon project saving, your datafile will also be given an ARK identifier (such as [`ark:/21547/APH2`](https://n2t.net/ark:/21547/APH2)). This ARK is distinct from your project ARK, and visiting that resolver URL will scroll the download button into view and make it pulse green (resolving into your project url suffixed with something akin to [`#dataset:7f5d6fe37b819da189d99e077aa89279`](https://amphibiandisease.org/project.php?id=4bc91fb90ff5575d5affec1724447bba#dataset:7f5d6fe37b819da189d99e077aa89279)).
