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

# With Data
## Getting your Template

We have partnered with [BiSciCol.org](http://biscicol.org) to provide a template generator for your project.

If you go to [http://biscicol.org/biocode-fims/templates.jsp](http://biscicol.org/biocode-fims/templates.jsp), and from the dropdown select "Amphibian Disease", you can get a template from which to start working.

The file you get will be an Excel 2007+ format (`.xlsx`) file. All your sample data should be in the worksheet title `Samples`. If you wish to use a different worksheet name, please be sure that it is the first worksheet in the notebook. **If you do not do this, your validation will always fail, and you will not be able to upload data to the system**.

If you would like to save your data in a non-proprietary format, saving it as a `.csv` file is also accepted.

The file should either have a header row, or use the order presented at BiSciCol.org.

Upon project saving, your datafile will be given an ARK identifier (such as `ark:/1547/APH2`), resolvable by the Name2Thing service (eg, https://n2t.net/ark:/21547/APH2). This ARK is distinct from your project ARK, and visiting that resolver URL will scroll the download button into view and make it pulse green (resolving into a url akin to https://amphibiandisease.org/project.php?id=4bc91fb90ff5575d5affec1724447bba#dataset:7f5d6fe37b819da189d99e077aa89279).

# Without Data

First, visit [https://amphibiandisease.org/admin](https://amphibiandisease.org/admin) to log in or create a user.

From there, you'll be confronted with this page:

PAGE SCREENSHOT

Click "Create Project", and you'll get the project creator page.

TODO
