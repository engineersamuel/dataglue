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

  # Load npm  Tasks
  grunt.loadNpmTasks('grunt-mocha-test')

  # Default task.
  grunt.registerTask('default', 'mochaTest')

