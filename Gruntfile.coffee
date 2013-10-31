module.exports = (grunt) ->
  grunt.initConfig
    mochaTest:
      test:
        options:
          reporter: 'spec'
          require: ['coffee-script', 'should']
        src: ['src/dataglue/test/**/*.coffee']

    # Not yet working -- need to upgrade dev to >= nodejs 10.7
    coverage:
      options:
        reporter: 'html-cov'
        require: ['blanket', 'coffee-script', 'should']
        # use the quiet flag to suppress the mocha console output
        quiet: true
        # specify a destination file to capture the mocha
        # output (the quiet option does not suppress this)
        captureFile: 'src/dataglue/test/coverage.html'
      src: ['src/dataglue/test/**/*.coffee']

    clean: ['public/dist/**.*']

    # Uncaught ReferenceError: define is not defined
    requirejs:
      compile:
        options:
          # Without almond the requirejs compile doesn't package requirejs itself
          #almond: true
          name: "main"
          baseUrl: "public/js"
          mainConfigFile: "public/js/main.js"
          out: "public/dist/optimized.min.js"
          preserveLicenseComments: false
          findNestedDependencies: true
          optimize: "uglify2"
          #uglify:
          #  toplevel: true
          #  beautify: false
          #  defines:
          #    DEBUG: ['name', 'false']
          #  no_mangle: true
          # https://github.com/mishoo/UglifyJS2
          uglify2:
            compress:
              sequences: false
              global_defs:
                DEBUG: false
            warnings: true
            mangle: false

    cssmin:
      minify:
        files:
          'public/dist/dataglue.min.css': ['public/css/app.css']

  # Load npm  Tasks
  grunt.loadNpmTasks('grunt-mocha-test')
  grunt.loadNpmTasks('grunt-contrib-requirejs')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-cssmin')

  # Default task.
  grunt.registerTask('default', 'mochaTest')
  grunt.registerTask 'prod', ['clean', 'requirejs', 'cssmin']

