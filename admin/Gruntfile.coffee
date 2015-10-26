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
    shell:
      options:
        stderr: false
      bower:
        command: ["bower update"].join("&&")
      movesrc:
        command: ["mv js/c.src.coffee js/maps/c.src.coffee"].join("&&")
    uglify:
      options:
        mangle:
          except:['jQuery']
      combine:
        options:
          sourceMap:true
          sourceMapName:"js/maps/combined.map"
          sourceMapIncludeSources:true
          sourceMapIn:"js/maps/c.js.map"
        files:
          "js/combined.min.js":["js/c.js","bower_components/purl/purl.js","bower_components/jquery-cookie/jquery.cookie.js"]
      dist:
        options:
          sourceMap:true
          sourceMapName:"js/maps/c.map"
          sourceMapIncludeSources:true
          sourceMapIn:"js/maps/c.js.map"
        files:
          "js/c.min.js":["js/c.js"]
      minzxcvbn:
        options:
          sourceMap:true
          sourceMapName:"js/maps/zxcvbn.map"
          sourceMapIncludeSources:true
          sourceMapIn:"js/zxcvbn/dist/zxcvbn.js.map"
        files:
          "js/zxcvbn/zxcvbn.min.js": ["js/zxcvbn/dist/zxcvbn.js"]
          "js/zxcvbn.min.js": ["js/zxcvbn/dist/zxcvbn.js"]
      minpurl:
        options:
          sourceMap:true
          sourceMapName:"js/maps/purl.map"
        files:
          "js/purl.min.js": ["bower_components/purl/purl.js"]
      minjcookie:
        options:
          sourceMap:true
          sourceMapName:"js/maps/jquery.cookie.map"
        files:
          "js/jquery.cookie.min.js": ["bower_components/jquery-cookie/jquery.cookie.js"]
      minljq:
        options:
          sourceMap:true
          sourceMapName:"js/maps/loadjquery.map"
        files:
          "js/loadJQuery.min.js": ["js/loadJQuery.js"]
    cssmin:
      options:
        sourceMap: true
        advanced: false
      target:
        files:
          "css/otp.min.css":["css/otp_styles.css","css/otp_panels.css"]
    coffee:
      compile:
        options:
          bare: false
          join: true
          sourceMapDir: "js/maps"
          sourceMap: true
        files:
          "js/c.js":["coffee/core.coffee", "coffee/login.coffee"]
          "js/loadJQuery.js": ["coffee/loadJQuery.coffee"]
    phplint:
      scripts: ["handlers/login_functions.php","login.php"]
    phpcsfixer:
      app:
        dir: ["handlers/login_functions.php"]
      options:
        ignoreExitCode: true
        verbose: true
        #diff: true
        #dryRun: true
    watch:
      scripts:
        files: ["coffee/*.coffee"]
        tasks: ["coffee:compile","uglify:dist","shell:movesrc"]
      styles:
        files: ["css/otp_styles.css","css/otp_panels.css"]
        tasks: ["cssmin"]
      php:
        files: ["*.php","handlers/*.php"]
        tasks: ["phplint"]
  ## Now the tasks
  grunt.registerTask("default",["watch"])
  grunt.registerTask("compile","Compile coffeescript",["coffee:compile","uglify:dist","shell:movesrc"])
  ## The minification tasks
  # Part 1
  grunt.registerTask("minifyIndependent","Minify Bower components that aren't distributed min'd",["uglify:minpurl","uglify:minjcookie","uglify:minljq"])
  # Part 2
  grunt.registerTask("minifyBulk","Minify all the things",["uglify:combine","uglify:dist","cssmin"])
  # Main call
  grunt.registerTask "minify","Minify all the things",->
    grunt.task.run("minifyIndependent","minifyBulk")
  ## Global update
  # Bower
  grunt.registerTask("updateBower","Update bower dependencies",["shell:bower"])
  # Minify the bower stuff in case it changed
  grunt.registerTask "update","Update dependencies", ->
    grunt.task.run("updateBower","minify")
  ## Deploy
  grunt.registerTask "qbuild","Compile uglify/minify", ->
    grunt.task.run("compile","minify")
  grunt.registerTask "build","Compile and update", ->
    grunt.task.run("updateBower","compile","minify")
  ## Deploy
  grunt.registerTask "startWork","Compile and update, then watch", ->
    grunt.task.run("updateBower","compile","minify","default")
