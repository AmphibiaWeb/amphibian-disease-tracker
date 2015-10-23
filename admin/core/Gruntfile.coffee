#spawn = require('child_process').spawn
#require("load-grunt-tasks")(grunt)

module.exports = (grunt) ->
  # Gruntfile
  # https://github.com/sindresorhus/grunt-shell
  grunt.loadNpmTasks("grunt-shell")
  # https://www.npmjs.com/package/grunt-contrib-coffee
  grunt.loadNpmTasks("grunt-contrib-coffee")
  # https://github.com/gruntjs/grunt-contrib-watch
  grunt.loadNpmTasks("grunt-contrib-watch")
  grunt.loadNpmTasks("grunt-contrib-uglify")
  grunt.loadNpmTasks("grunt-contrib-cssmin")
  # https://www.npmjs.com/package/grunt-phplint
  grunt.loadNpmTasks("grunt-phplint");
  grunt.loadNpmTasks('grunt-php-cs-fixer')
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    phplint:
      scripts: ["core.php"]
    phpcsfixer:
      app:
        dir: ["core.php","db","xml","stronghash/php-stronghash.php","wysiwyg/wysiwyg.php","wysiwyg/classic-wysiwyg.php"]
      options:
        ignoreExitCode: true
        verbose: true
        diff: false
        dryRun: false
    watch:
      php:
        files: ["*.php","db/*.php","xml/*.php","wysiwyg/*.php","stronghash/*.php"]
        tasks: ["phplint"]
  ## Now the tasks
  grunt.registerTask("default",["watch"])
