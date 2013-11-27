module.exports = function (grunt) {

//    var outdir = "public";
    var outdir = "..";

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        less: {
            compile: {
                files: {
                    'app/css/_app_less.css': 'app/styles/*.less'
                }
            }
        },
        coffee: {
            compile: {
                options: {
                    join: true
                },
                files: {
                    'app/js/_app_coffee.js': 'app/scripts/*.coffee'
                }
            }
        },
        // todo: uglify (already in scope) instead of concat?
        concat: {
            vendor_js: {
                src: [
                    'lib/moment.js',
                    'lib/jquery/jquery.js',
                    'lib/angular/angular.js',
                    'lib/angular/angular-route.js'
                ],
                dest: outdir + '/js/vendor.js'
            },
            app_js: {
                src: [
                    'app/js/*.js'
                ],
                dest: outdir + '/js/app.js'
            },
            app_css: {
                src: [
                    'app/css/*.css'
                ],
                dest: outdir + '/css/app.css'
            }
        },
        copy: {
            static: {
                files: [
                    {
                        expand: true,
                        cwd: 'app/static/',
                        src: ['**'],
                        dest: outdir + '/',
                        filter: 'isFile'
                    }
                ]
            }
        },
        watch: {
            less: {
                files: [
                    'app/styles/*.less'
                ],
                tasks: ['less']
            },
            coffee: {
                files: [
                    'app/scripts/*.coffee'
                ],
                tasks: ['coffee']
            },
            vendor_js: {
                files: [
                    'lib/**/*.js'
                ],
                tasks: ['concat:vendor_js']
            },
            app_js: {
                files: [
                    'app/js/*.js'
                ],
                tasks: ['concat:app_js']
            },
            templates_js: {
                files: [
                    'app/partials/*.html'
                ],
                tasks: ['ngtemplates']
            },
            app_css: {
                files: [
                    'app/css/*.css'
                ],
                tasks: ['concat:app_css']
            },
            static: {
                files: [
                    'app/static/**/*'
                ],
                tasks: ['copy']
            }
        },
        ngtemplates: {
            compile: {
                options: {
                    module: 'ThatOneFeed',
                    htmlmin: {
                        removeComments: true
                    }
                },
                cwd: 'app',
                src: 'partials/*.html',
                dest: 'app/js/_templates.js'
            }
        },
        clean: [
            "public", // not outdir, in case we go up...
            "app/css/_*",
            "app/js/_*"
        ]
    });

    // Load the plugin
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-angular-templates');

    grunt.registerTask('build', ['clean', 'coffee', 'less', 'ngtemplates', 'concat', 'copy']);
    grunt.registerTask('default', ['build']);
    grunt.registerTask('client', ['build', 'watch']);

};