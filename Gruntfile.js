module.exports = function (grunt) {

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        stylus: {
            compile: {
                options: {
                    compress: true
                },
                files: {
                    'app/css/_app.css': 'app/styles/*.styl'
                }
            }
        },
        coffee: {
            compile: {
                files: {
                    'app/js/_app.js': 'app/scripts/*.coffee'
                }
            }
        },
        // todo: uglify (already in scope) after concat...
        concat: {
            vendor_js: {
                src: [
                    'app/lib/jquery/jquery.js',
                    'app/lib/angular/angular.js',
                    'app/lib/angular/angular-route.js'
                ],
                dest: 'public/js/vendor.js'
            },
            app_js: {
                src: [
                    'app/js/*.js'
                ],
                dest: 'public/js/app.js'
            },
            css: {
                src: [
                    'app/css/*.css'
                ],
                dest: 'public/css/app.css'
            }
        },
        copy: {
            static: {
                files: [
                    {
                        expand: true,
                        cwd: 'app/static/',
                        src: ['**'],
                        dest: 'public/',
                        filter: 'isFile'
                    }
                ]
            }
        },
        watch: {
            stylus: {
                files: [
                    'app/styles/*.styl'
                ],
                tasks: ['stylus']
            },
            coffee: {
                files: [
                    'app/scripts/*.coffee'
                ],
                tasks: ['coffee']
            },
            vendor_js: {
                files: [
                    'app/lib/*/*.js'
                ],
                tasks: ['concat:vendor_js']
            },
            app_js: {
                files: [
                    'app/js/*.js'
                ],
                tasks: ['concat:app_js']
            },
            app_css: {
                files: [
                    'app/css/*.css'
                ],
                tasks: ['concat:css']
            },
            static: {
                files: [
                    'app/static/**/*'
                ],
                tasks: ['copy']
            }
        }
    });

    // Load the plugin
    grunt.loadNpmTasks('grunt-contrib-stylus');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-uglify');

    grunt.registerTask('default', ['concat', 'copy', 'watch']);

};