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
  # Validators
  grunt.loadNpmTasks('grunt-bootlint')
  grunt.loadNpmTasks('grunt-html')
  grunt.loadNpmTasks('grunt-string-replace')
  grunt.loadNpmTasks('grunt-postcss')
  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-php-cs-fixer')
  # https://www.npmjs.com/package/grunt-phplint
  grunt.loadNpmTasks("grunt-phplint");
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    shell:
      options:
        stderr: false
      bower:
        command: ["bower update"].join("&&")
      npm:
        command: ["npm update"].join("&&")
      movesrc:
        command: ["mv js/drop-upload.src.coffee js/maps/drop-upload.src.coffee"].join("&&")
    postcss:
      options:
        processors: [
          require('autoprefixer')({browsers: 'last 1 version'})
          ]
      dist:
        src: "css/main.css"
    uglify:
      options:
        mangle:
          except:['jQuery']
      dist:
        options:
          sourceMap:true
          sourceMapName:"js/maps/drop-upload.map"
          sourceMapIncludeSources:true
          sourceMapIn:"js/maps/drop-upload.js.map"
          compress:
            # From https://github.com/mishoo/UglifyJS2#compressor-options
            dead_code: true
            unsafe: true
            conditionals: true
            unused: true
            loops: true
            if_return: true
            drop_console: true #false
            warnings: true
            properties: true
            sequences: true
            cascade: true
        files:
          "js/drop-upload.min.js":["js/drop-upload.js"]
          "js/dropzone-custom.min.js":["bower_components/dropzone/dist/dropzone.js"]
      client:
        options:
          sourceMap:true
          sourceMapName:"js/maps/client-upload.map"
          sourceMapIncludeSources:true
          sourceMapIn:"js/maps/client-upload.js.map"
          compress:
            # From https://github.com/mishoo/UglifyJS2#compressor-options
            dead_code: true
            unsafe: true
            conditionals: true
            unused: true
            loops: true
            if_return: true
            drop_console: true #false
            warnings: true
            properties: true
            sequences: true
            cascade: true
        files:
          "client-upload.min.js":["client-upload.js"]
    less:
      # https://github.com/gruntjs/grunt-contrib-less
      options:
        sourceMap: true
        outputSourceFiles: true
        banner: "/*** Compiled from LESS source ***/\n\n"
      files:
        dest: "css/main.css"
        src: ["less/main.less"]
    cssmin:
      options:
        sourceMap: true
        advanced: true # Selector merging may break some shadow dom stuff ...
        # https://github.com/jakubpawlowicz/clean-css#how-to-use-clean-css-programmatically
        keepSpecialComments: 0
      target:
        files:
          "css/main.min.css":["css/main.css"]
    coffee:
      compile:
        options:
          bare: false # For release, set false and then debug!
          join: true
          sourceMapDir: "js/maps"
          sourceMap: true
        files:
          "js/drop-upload.js":"coffee/*.coffee"
          "client-upload.js":"client-bootstrapper.coffee"
      integration:
        options:
          bare: true
        files:
          "integration.js":"integration.coffee"
    phpcsfixer:
      scripts:
        dir: ["./", "core/"]
      options:
        ignoreExitCode: true
        verbose: true
        diff: false
        dryRun: false
    phplint:
      root: ["*.php"]
    watch:
      scripts:
        files: ["coffee/*.coffee", "client-bootstrapper.coffee", "integration.coffee"]
        tasks: ["coffee","uglify","shell:movesrc"]
      styles:
        files: ["less/main.less"]
        tasks: ["less","postcss","cssmin"]
      html:
        files: ["index.html"]
        tasks: ["bootlint","htmllint"]
      php:
        files: ["*.php"]
        tasks: ["phplint"]
    bootlint:
      options:
        stoponerror: false
        relaxerror: ['W009']
      files: ["index.html"]
    htmllint:
      all:
        src: ["index.html"]
      options:
        ignore: [/XHTML element “[a-z-]+-[a-z-]+” not allowed as child of XHTML element.*/,"Bad value “X-UA-Compatible” for attribute “http-equiv” on XHTML element “meta”.",/Bad value “theme-color”.*/,/Bad value “import” for attribute “rel” on element “link”.*/,/Element “.+” not allowed as child of element*/,/.*Illegal character in query: not a URL code point./]
  ## Now the tasks
  grunt.registerTask("default",["watch"])
  grunt.registerTask("compile","Compile coffeescript",["coffee","uglify","shell:movesrc"])
  ## The minification tasks
  # Part 2
  grunt.registerTask("lessify", "Run less/css postprocessors", ["less","postcss","cssmin"])
  grunt.registerTask("minifyBulk","Minify all the things",["uglify"])
  # Main call
  grunt.registerTask "minify","Minify all the things",->
    grunt.task.run("lessify","minifyBulk")
  ## Global update
  # Bower
  grunt.registerTask("updateBower","Update bower dependencies",["shell:bower"])
  grunt.registerTask("updateNPM","Update Node dependencies",["shell:npm"])
  # Minify the bower stuff in case it changed
  grunt.registerTask "update","Update dependencies", ->
    grunt.task.run("updateNPM","updateBower","minify")
  ## Deploy
  grunt.registerTask "qbuild","Quick rebuild", ->
    grunt.task.run("compile","minify")
  grunt.registerTask "build","Compile and update, then watch", ->
    grunt.task.run("updateNPM","updateBower","compile","minify", "watch")
