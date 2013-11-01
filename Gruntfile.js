(function() {
  module.exports = function(grunt) {
    grunt.initConfig({
      mochaTest: {
        test: {
          options: {
            reporter: 'spec',
            require: ['coffee-script', 'should']
          },
          src: ['src/dataglue/test/**/*.coffee']
        }
      },
      coverage: {
        options: {
          reporter: 'html-cov',
          require: ['blanket', 'coffee-script', 'should'],
          quiet: true,
          captureFile: 'src/dataglue/test/coverage.html'
        },
        src: ['src/dataglue/test/**/*.coffee']
      },
      clean: ['public/dist/**.*'],
      requirejs: {
        compile: {
          options: {
            name: "main",
            baseUrl: "public/js",
            mainConfigFile: "public/js/main.js",
            out: "public/dist/optimized.min.js",
            preserveLicenseComments: false,
            findNestedDependencies: true,
            optimize: "uglify2",
            uglify2: {
              compress: {
                sequences: false,
                global_defs: {
                  DEBUG: false
                }
              },
              warnings: true,
              mangle: false
            }
          }
        }
      },
      cssmin: {
        minify: {
          files: {
            'public/dist/dataglue.min.css': ['public/css/app.css']
          }
        }
      }
    });
    grunt.loadNpmTasks('grunt-mocha-test');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    grunt.registerTask('default', 'mochaTest');
    return grunt.registerTask('prod', ['clean', 'requirejs', 'cssmin']);
  };

}).call(this);
