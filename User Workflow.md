# Logging In and User Creation

<!--
Images reference
-->
[login_page]: https://amphibiandisease.org/assets/documentation/login_page.png "The administrative login page"
[creation_page]: https://amphibiandisease.org/assets/documentation/creation_page.png "The user creation page"
[password_requirements]: https://amphibiandisease.org/assets/documentation/password.png "Password requirements block"
[admin_page_unverified]: https://amphibiandisease.org/assets/documentation/dummy.png "The administration view when unverified"
[admin_page]: https://amphibiandisease.org/assets/documentation/admin.png "The verified user administrative dashboard"
[projects_creation_page]: https://amphibiandisease.org/assets/documentation/proj_creation.png "Project creation view"
[upload_progress]: https://amphibiandisease.org/assets/documentation/upload.png "Upload progress indicators"
[bad_data_error_validation]: https://amphibiandisease.org/assets/documentation/badval.png "Example table shown for a FIMS error"
[map_building]: https://amphibiandisease.org/assets/documentation/mapbuilder.png "Map builder interface"
[dataset_ark]: https://amphibiandisease.org/assets/documentation/d_ark.png "ARK resolving to a dataset"

First, visit [https://amphibiandisease.org/admin](https://amphibiandisease.org/admin) to log in or create a user.

![Login landing page][login_page]

## Creating a user

If you don't have an account, you can create one. Clicking on the link to "Create Now" will present you with this page:

![User Creation page][creation_page]

When creating a password, your password either needs to be **complex** or **long**.

A complex password must be at least 8 characters long, with at least one uppercase letter, at least one lowercase letter, and at least one number or symbol.

For a long password, all other requirements are waived. A long password is any password of 20+ characters.

When you're creating your password, the bar on the right hand side will indicate the relative strength of your password, as well as a "standard" cracking time. The boxes above the bar indicate which character class requirements have been met.

![Password security meter][password_requirements]

As you're typing, the first password box will remain red until a password meeting security requirements has been entered.

The second password box will be green so long as the confirmed password matches the first password.

The maximum password length is 8191 characters (8 kiB - 1 B).

## Restricted vs. Unrestricted Profiles

When you create an account, your default account access is **restricted**.

Restricted users have access to most of the system:

- You can view project contacts without answering the captcha
- You can be added to an existing project as a viewer, editor, or even as a new owner
- You have access to the administration panel, with lists of projects you have access to
- Most [API hits](/APIs) will work for you

The only thing you cannot do is create a new project.

### Getting your user unrestricted

To get your user unrestricted, you must:

1. Verify your email. From your [Account Settings](https://amphibiandisease.org/admin-login.php), click "verify" and click the link or input the code provided to prove ownership.
2. Have an email address that *either* matches the list of approved [TLDs](https://en.wikipedia.org/wiki/Top-level_domain) or [domains](https://en.wikipedia.org/wiki/Domain_name) (minus TLD).
3. If your username (the email you signed up with) doesn't match (2), you can add and verify an "alternate email" in [Account Settings](https://amphibiandisease.org/admin-login.php) to meet those criteria.

At this time, to have a unrestricted user, you must meet the following criteria:

| Domain | TLD |
|--------|-----|
| Any    | .gov, .edu, .org, .ac.uk, .ed.co |

Once you've met those criteria, you can create a project at any time. Until you do, clicking on the badge by your name in Administration, or clicking the unrestriction button that is first in the admin panel.



# Creating a Project

Once you've logged in, you'll be confronted with this page:

![Administration Dashboard][admin_page]

If you don't see "Create Project", see ["Verifying your User" above](#getting-your-user-unrestricted).

Click "Create Project", and you'll get the project creator page.

![Project creation page][projects_creation_page]

Fields with a red underline are invalid (or empty and mandatory) entries. At any time, you can mouse over the information icons to get a helpful tooltip.

You'll note that you're prepopulated as the default project contact.

Next to the primary pathogen field, the "Bd" and "Bsal" buttons will fill the pathogen field with the full scientific name of the respective pathogen.

In the notes area, you're welcome to use [Markdown](https://help.github.com/articles/basic-writing-and-formatting-syntax/). The rendering uses the [marked library](https://github.com/chjj/marked) via [the Polymer element](https://elements.polymer-project.org/elements/marked-element), which fully supports Github-Flavored Markdown.


## Without Data

After the "Build Map" option and map interface, find the checkbox that says "My project already has data", and uncheck it.

If you leave this button checked, the system will not let you save the project until you've uploaded a dataset.

TODO MAPS
<!--
![Map Building][map_building]
-->
## With Data

When you have data, you don't need to specify a locality like without data; it will be calculated for you from your dataset.

### Getting your Template

We have partnered with Biocode ([BiSciCol.org](http://biscicol.org)) to provide a template generator for your project.

If you go to [https://www.biscicol.org/](https://www.biscicol.org/), and from the upper righthand dropdown menu Tools select "Generate Template, then "Amphibian Disease", you can customize and download a template from which to start working.

The template file will be an Excel 2007+ format (`.xlsx`) file. All your sample data should be in the worksheet title `Samples`. If you wish to use a different worksheet name, please be sure that it is the first worksheet in the notebook. **If you do not do this, your validation will always fail, and you will not be able to upload data to the system**.

If you would like to save your data in a non-proprietary format, saving it as a `.csv` file is also accepted. All CSV files should conform to [RFC4180](https://tools.ietf.org/html/rfc4180). Please be aware that if you use a Microsoft product, depending on the version, it may not conform properly to this standard and your data may be processed incorrectly.

The file should either have a header row, or use the order presented at BiSciCol.org.

### Uploading your project data

You'll find on the page a box that says "Drop your files here to upload" under the heading "Uploading your project data". You can drag and drop files from your filesystem into that box to upload files to the server. You may also use the blue button with an arrow pointing into a cloud to upload your files.

You may upload more than just a datafile to your project; the system will also accept images (anything with a [MIME type](https://en.wikipedia.org/wiki/Media_type) beginning with `image/`), `zip` files, and `7z` ([7-zip](https://en.wikipedia.org/wiki/7-Zip), open-source compression better than zip) files. At the time of this writing, these are not yet exposed in your project's viewer, but the feature is incoming.

>**Important Note**: If you dont use an [ISO 18601](https://en.wikipedia.org/wiki/ISO_8601) date, you will run into problems. Also, since Excel handles and exposes dates poorly, our system cannot reliably identify dates from February 1905 - July 1905 (and will interpret them as a year from 1863 through current), and will fail on the Unix timestamp for December 31, 1969.

When you upload your data, you'll be given several progress bars that complete sequentially. This will notify you if you have any problems with your data, and where they may occur.

![Upload progress indicators][upload_progress]

Handling your data upload occurs like this:

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

Once you click the save button, your data will be processed and saved to the server. Upon project saving, your datafile will be given an ARK identifier (such as `ark:/21547/ANU2`), resolvable by the Name2Thing service (eg, [https://n2t.net/ark:/21547/ANU2](https://n2t.net/ark:/21547/ANU2)). The system will then load the project editor immediately. To view your project, click the eye icon next to the project title. The URL you arrive at will always be a valid permalink for your project, in addition to the ARK url.

If you have a datafile, upon project saving, your datafile will also be given an ARK identifier (such as [`ark:/21547/APH2`](https://n2t.net/ark:/21547/APH2)). This ARK is distinct from your project ARK, and visiting that resolver URL will scroll the download button into view and make it pulse green (resolving into your project url suffixed with something akin to [`#dataset:7f5d6fe37b819da189d99e077aa89279`](https://amphibiandisease.org/project.php?id=4bc91fb90ff5575d5affec1724447bba#dataset:7f5d6fe37b819da189d99e077aa89279)).

![ARK dataset resolution][dataset_ark]

## Troubleshooting

### Trying to upload data?
Most errors in validation will be reported during the uploading process so they can be fixed and uploaded again.
Other Q & A may help.

1. Do the fields in the XLSX template need to remain in their original order?
  > If header fields are present, then they can be in any order; if absent, yes, the fields must be in their original order.

2. Can I add extra fields to the XLSX template?
  > Any fields not in the template will result in validation errors. We may add more fields if a common request. Please contact us.

3. What happens to null columns?
  > Empty fields are irrelevant. They'll just store as empty (since they're all saved anyway).

4. Can worksheets be altered, either names or their order?
  > They can be in any order if their names are unchanged; if not named then the Samples has to be the first and only worksheet.
