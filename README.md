# js-dragdrop-php

## Server Configuration

The script and the `.htaccess` in the repo both try to set a
higher-than-default upload filesize. However, this doesn't always work
on all servers.

In those cases, go to your `php.ini` file, and set the following two lines:

```
post_max_size=10M
upload_max_filesize=10M
```

If you want a file upload higher than ten megabytes, be sure to change it in `.htaccess` and `php.ini` also.

## Configuration

There plugin exposes the global variable `dropperParams`, which has two primary parameters:

- `dropperParams.uploadPath`: The path relative to `meta.php` that the images will be saved in. If you need a trailing slash, it should be inserted. **This path must be writeable by the PHP user**.
- `dropperParams.metaPath`: The path relative to the calling page of `meta.php`. It should terminate in a slash.

The following optional paramaters may be specified:

- `dropperParams.uploadText`: The text to show in the upload target. Defaults to "Drop your image here".
- `dropperParams.thumbWidth`: Maximum thumbnail width, in pixels. Default 640.
- `dropperParams.thumbHeight`: Maximum thumbnail height, in pixels. Default 480.
- `dropperParams.dependencyPath`: The path to the dependencies of the library. Defaults to `bower_components/`.
- `dropperParams.showProgress`: Show an extra progress bar beneath the drop target. Default `false`.
- `dropperParams.clickTargets`: Targets that can be clicked to initiate an upload. An array of CSS selectors. (Default: none)
- `dropperParams.mimeTypes`: Accepted mime types, comma-seperated. Defaults to `"image/*,video/mp4,video/3gpp,audio/*"`


## Using

Adding the function in is simple. **It has JQuery as a dependency**, but other than that simply run

```html
<script type="text/javascript" src="js/drop-upload.min.js"></script>
```

to load the script.

To configure it, you can do something like what's in [launch-test.coffee](launch-test.coffee):

```coffee
dropTargetSelector="#foobar"
callback = (file, result) ->
  # Callback here
  false
$ ->
  window.dropperParams.showProgress = true
  window.dropperParams.handleDragDropImage(dropTargetSelector, callback)
```

It's important to have the code run on the `onready` handler or similar, as the function will load its own dependencies, keeping the actual declaration slim.

Running the demo will show some sample outputs.

The most important of these outputs is the JSON result from `meta.php`. It will return an object like this:

```javascript
{
    "status": true, // Boolean true or false
    "original_file": "foobar.png", // The original file name
    "full_path": "path/to/MD5HASH.png", // A path to the uploaded file
    "thumb_path": "path/to/MD5HASH-thumb.png", // A path to the thumbnail of the uploaded file
    "resize_status": {
        "output": "path/to/MD5HASH-thumb.png", // A path to the thumbnail of the uploaded file. Same as thumb_path
        "output_size": "640 x 480", // The resized dimensions of the thumbnail
        "status": true // the status of the resize attempt
    },
    "error": "Could not write directory", // Developer error for the upload
    "human_error": "Please try again", // A friendly error for the user
    "wrote_file": "MD5HASH.png" // The bare filename of the uploaded image
}
```

## Compiling

The javascript is all originally written with [CoffeeScript](http://coffeescript.org/), then compiled via [Grunt](http://gruntjs.com/). Similarly, the CSS is all written with [Less](http://lesscss.org/). I strongly suggest you make your edits in CoffeeScript then run `grunt qbuild`.

Other options:

- `build`: Like `qbuild`, but update Bower and NPM first
- `compile`: Just compile CoffeeScript
- `minify`: Uglify all the things, run postcss and autoprefixer
- `watch`: Like it sounds like!

Before any of this will work, you'll need to have Node installed and run

`npm install`

from the repository root to get all your dependencies installed.

The result from `integration.js` should be refolded in to `server/public/observe/js/profile.js`.

The styles are all in the `less` directory. Ignore any others, unless they're on an import statement in `main.less`. Most notably, the file `less/shadow-dropzone.css` is most of the Dropzone css in `bower_components`, plus compatibility for shadow-peircing selectors (`>>>` and `/deep/`) (therefore **replacing** the one in `bower_components/`)

## License

This library is dual-licensed under the MIT and GPLv3 liceneses (as LICENSE and LICENSE-2 in this repository). Feel free to use either for your work, as appropriate.

Please contact the me for any other licences you may want, and we'll work something out
