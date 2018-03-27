#spawn = require('child_process').spawn
#require("load-grunt-tasks")(grunt)
Promise = require('es6-promise').Promise
module.exports = (grunt) ->
  # Gruntfile
  # https://github.com/sindresorhus/grunt-shell
  grunt.option('stack', true)
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
  # https://www.npmjs.com/package/grunt-phplint
  grunt.loadNpmTasks("grunt-phplint")
  grunt.loadNpmTasks('grunt-php-cs-fixer')
  # https://github.com/mpau23/grunt-regex-extract
  grunt.loadNpmTasks("grunt-regex-extract")
  # https://github.com/gruntjs/grunt-contrib-clean
  grunt.loadNpmTasks('grunt-contrib-clean')
  # https://github.com/davidtucker/grunt-line-remover
  grunt.loadNpmTasks('grunt-line-remover')
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    shell:
      options:
        stderr: false
      bower:
        command: ["bower update"].join("&&")
      npm:
        command: ["npm install", "npm update"].join("&&")
      movesrc:
        command: ["mv js/c.src.coffee js/maps/c.src.coffee","mv js/admin.src.coffee js/maps/admin.src.coffee", "mv js/project.src.coffee js/maps/project.src.coffee", "mv js/dashboard.src.coffee js/maps/dashboard.src.coffee","mv js/profile.src.coffee js/maps/profile.src.coffee","mv js/kml.src.coffee js/maps/kml.src.coffee","mv js/global-searach.src.coffee js/maps/global-search.src.coffee","mv js/global-search-worker.src.coffee js/maps/global-search-worker.src.coffee"].join("; ")
      updateglobals:
        command: ["npm install -g coffee-script npm-check-updates bower grunt-cli npm autoprefixer-core less"].join("&&")
      vulcanize:
        # Should also use a command to replace js as per uglify:vulcanize
        command: ["vulcanize --strip-comments pre-vulcanize.html --out-html vulcanized.html"].join("&&")
      retrim:
        command: []
    'string-replace':
      vulcanize_clean:
        options:
          replacements: [
              pattern: "(\\s{2,}|\\n+|(\\r\\n)+|\\t+|\\r+)"
              replacement: " "
            ,
              pattern: ";(\\r\\n|\\r|\\n)"
              replacement: ";"
            ,
              pattern: "}(\\r\\n|\\r|\\n)"
              replacement: "}"
            ]
        files:
          "modular/vulcanized-trimmed-withlines.html": ["modular/vulcanized-div-and-dom-module.html"]
    lineremover:
      noOptions:
        files:
          "modular/vulcanized-trimmed.html":"modular/vulcanized-trimmed-withlines.html"
    regex_extract:
      default_options:
        options:
          regex: "[\\s\\S]*?(<div[^>]*(?:by-vulcanize|by-polymer-bundler).*?>[\\s\\S]*?)<header[\\s\\S]*$"
          modifiers: "mig"
          includePath: false
          matchPoints: "1"
        files:
          "vulcanized.html": ["dashboard-static-bundled.html"]
    clean: ["vulcanized.html", "vulcanized-parsed.html", "post-vulcanize.html", "*.build.html", "*.build.js"]
    postcss:
      options:
        processors: [
          require('autoprefixer')({browsers: 'last 1 version'})
          ]
      dist:
        src: "css/main.css"
      drop:
        src: "css/shadow-dropzone.css"
    uglify:
      vulcanize:
        options:
          sourceMap:true
          sourceMapName:"js/maps/app.js.map"
        files:
          "js/app.min.js":["app-prerelease.js"]
      combine:
        options:
          sourceMap:true
          sourceMapName:"js/maps/combined.map"
          sourceMapIncludeSources:true
          sourceMapIn:"js/maps/c.js.map"
        files:
          "js/combined.min.js":["js/c.js","js/admin.js","js/project.js", "js/dashboard.js", "js/profile.js", "js/global-search.js","bower_components/purl/purl.js","bower_components/xmlToJSON/lib/xmlToJSON.js","bower_components/jquery-cookie/jquery.cookie.js"]
          "js/app.min.js":["js/c.js","js/admin.js","js/project.js", "js/dashboard.js", "js/global-search.js","js/global-search-worker.js"]
      dist:
        options:
          sourceMap:true
          # sourceMapName:"js/maps/c.map"
          sourceMapIncludeSources:true
          sourceMapIn: (fileIn) ->
            fileName = fileIn.split("/").pop()
            fileNameArr = fileName.split(".")
            fileNameArr.pop()
            fileId = fileNameArr.join(".")
            "js/maps/#{fileId}.js.map"
          compress:
            # From https://github.com/mishoo/UglifyJS2#compressor-options
            dead_code: true
            unsafe: true
            conditionals: true
            unused: true
            loops: true
            if_return: true
            drop_console: false
            warnings: false
            properties: true
            sequences: true
            #cascade: true
        files:
          "js/c.min.js":["js/c.js"]
          "js/admin.min.js":["js/admin.js"]
          "js/project.min.js":["js/project.js"]
          "js/dashboard.min.js":["js/dashboard.js"]
          "js/kml.min.js":["js/kml.js"]
          "js/profile.min.js":["js/profile.js"]
          "js/global-search.min.js":["js/global-search.js"]
          "js/global-search-worker.min.js":["js/global-search-worker.js"]
      mingeoxml:
        options:
          sourceMap:true
          sourceMapName: (fileIn) ->
            fileName = fileIn.split("/").pop()
            fileNameArr = fileName.split(".")
            fileNameArr.pop()
            fileId = fileNameArr.join(".")
            "js/maps/#{fileId}.map"
        files:
          "js/geoxml3.min.js": ["geoxml3/kmz/geoxml3.js"]
          "js/ZipFile.complete.min.js": ["geoxml3/kmz/ZipFile.complete.js"]
          "js/ProjectedOverlay.min.js": ["geoxml3/ProjectedOverlay.js"]
          "js/geoxml3_gxParse_kmz.min.js": ["geoxml3/kmz/geoxml3_gxParse_kmz.js"]
      minpurl:
        options:
          sourceMap:true
          sourceMapName:"js/maps/purl.map"
        files:
          "js/purl.min.js": ["bower_components/purl/purl.js"]
      minxmljson:
        options:
          sourceMap:true
          sourceMapName:"js/maps/xmlToJSON.map"
        files:
          "js/xmlToJSON.min.js": ["bower_components/xmlToJSON/lib/xmlToJSON.js"]
      minjcookie:
        options:
          sourceMap:true
          sourceMapName:"js/maps/jquery.cookie.map"
        files:
          "js/jquery.cookie.min.js": ["bower_components/jquery-cookie/jquery.cookie.js"]
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
        advanced: false
      target:
        files:
          "css/main.min.css":["css/main.css"]
    coffee:
      compile:
        options:
          bare: true
          join: true
          sourceMapDir: "js/maps"
          sourceMap: true
        files:
          "js/c.js":["coffee/core.coffee", "coffee/geo.coffee", "coffee/debug.coffee"]
          "js/admin.js":["coffee/admin.coffee", "coffee/admin-editor.coffee", "coffee/admin-viewer.coffee", "coffee/admin-validation.coffee", "coffee/admin-su.coffee"]
          "js/project.js":["coffee/project.coffee"]
          "js/dashboard.js":["coffee/dashboard.coffee"]
          "js/profile.js":["coffee/profile.coffee"]
          "js/kml.js":["coffee/kml.coffee"]
          "js/global-search.js":["coffee/global-search.coffee"]
          "js/global-search-worker.js":["coffee/global-search-worker.coffee", "coffee/core-worker.coffee"]
    phpcsfixer:
      app:
        dir: ["api.php", "meta.php", "admin-login.php", "admin-api.php", "project.php", "dashboard.php", "index.php", "helpers/excelHelper.php", "profile.php", "recordMigrator.php"]
      core:
        dir: ["core/*.php"]
      options:
        rules: "@PSR2"
        #diff: true
        #dryRun: true
    watch:
      scripts:
        files: ["coffee/*.coffee"]
        tasks: ["coffee:compile","uglify:dist","shell:movesrc"]
      styles:
        files: ["less/main.less"]
        tasks: ["less","postcss","cssmin"]
      html:
        files: ["index.html","admin-page.html"]
        tasks: ["bootlint","htmllint"]
      app:
        files: ["app.html"]
        tasks: ["bootlint","shell:vulcanize","uglify:vulcanize","string-replace:vulcanize"]
      php:
        files: ["*.php", "helpers/*.php", "admin/*.php", "admin/handlers/*.php", "core/*/*.php", "core/*.php"]
        tasks: ["phplint"]
    phplint:
      api: ["api.php"]
      root: ["*.php", "helpers/*.php", "core/*/*.php", "core/*.php"]
      admin: ["admin/*.php", "admin/handlers/*.php", "admin/core/*.php", "admin/core/*/*.php"]
    bootlint:
      options:
        stoponerror: false
        relaxerror: ['W009']
      files: ["index.html","admin-page.html"]
    htmllint:
      all:
        src: ["index.html","admin-page.html"]
      options:
        ignore: [/XHTML element “[a-z-]+-[a-z-]+” not allowed as child of XHTML element.*/,"Bad value “X-UA-Compatible” for attribute “http-equiv” on XHTML element “meta”.",/Bad value “theme-color”.*/,/Bad value “import” for attribute “rel” on element “link”.*/,/Element “.+” not allowed as child of element*/,/.*Illegal character in query: not a URL code point./]
  ## Now the tasks
  grunt.registerTask("default",["watch"])
  grunt.registerTask("vulcanize","Vulcanize web components",["shell:vulcanize","regex_extract","string-replace", "lineremover","clean"])
  grunt.registerTask("compile","Compile coffeescript",["coffee:compile","uglify:dist","shell:movesrc"])
  ## The minification tasks
  # Part 1
  grunt.registerTask("minifyIndependent","Minify Bower components that aren't distributed min'd",["uglify:minpurl","uglify:minxmljson","uglify:minjcookie", "uglify:mingeoxml"])
  # Part 2
  grunt.registerTask("minifyBulk","Minify the major things",["uglify:combine","uglify:dist"])
  grunt.registerTask "css", "Process LESS -> CSS", ["less","postcss","cssmin"]
  # Main call
  grunt.registerTask "minify","Minify all the things",->
    grunt.task.run("minifyIndependent","minifyBulk","css")
  ## Global update
  # Bower
  grunt.registerTask("updateBower","Update bower dependencies",["shell:bower"])
  grunt.registerTask("updateNPM","Update Node dependencies",["shell:updateglobals","shell:npm"])
  # Minify the bower stuff in case it changed
  grunt.registerTask "update","Update dependencies", ->
    grunt.task.run("shell:updateglobals","updateNPM","updateBower","compile","minify")
  ## Deploy
  grunt.registerTask "qbuild","CoffeeScript and CSS", ->
    # ,"vulcanize"
    grunt.task.run("phplint","compile","css")
  grunt.registerTask "build","Compile and update, then watch", ->
    # ,"vulcanize"
    grunt.task.run("updateNPM","updateBower","vulcanize","phplint","compile","minify")
