'use strict';

var package_info = require('./package.json');
var fs = require('fs');


module.exports = function(grunt) {
    // Project configuration.
    var gruntConf = {
        watch: {
            options: {
                nospawn: true
            },
            default: {
                files: ['./**/*.coffee'],
                tasks: ['coffee', 'browserify']
            }
        },
        coffee: {
            default: {
                expand: true,
                cwd: 'coffee',
                src: ['**/*.coffee'],
                dest: 'js',
                ext: '.js',
                options: {
                    bare: true
                }
            }
        },
        concurrent: {
            server: {
                options: {
                    logConcurrentOutput: true
                }
            }
        },
        browserify: {
            dist: {
                files: {
                    './dist/clientstate.redis.js': [
                        'lib/JSONP.js', 'bower_components/oauth-js/dist/oauth.min.js', 'js/clientstate.js']
                }
            }
        },
        uglify: {
            my_target: {
                files: {
                    './dist/clientstate.redis.min.js': ['dist/clientstate.redis.js']
                }
            }
        },
        jasmine_node: {

            options: {
                forceExit: true,
                match: '.',
                matchall: false,
                extensions: 'js',
                specNameMatcher: 'spec'
            },
            all: ['tests/unit/spec/']
        },

        taskDefault: ['coffee', 'browserify', 'uglify']
    };

    grunt.initConfig(gruntConf);

    // These plugins provide necessary tasks.
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-concurrent');
    grunt.loadNpmTasks('grunt-browserify');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-jasmine-node');

    grunt.registerTask('coverage', 'Creates a tests coverage report', function() {
        var exec = require('child_process').exec;
        var done = this.async();
        exec('npm test', function(error, stdout, stderr) {
            console.log("Coverage report should be generated in ./coverage/lcov-report/index.html");
            done();
        });
    });

    // Default task.
    grunt.registerTask('default', gruntConf.taskDefault);

};