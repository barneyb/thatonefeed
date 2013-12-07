module.exports = function (grunt) {

    var outdir = grunt.option("server") ? ".." : "public";

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
        uglify: {
            vendor_js: {
                files: function() {
                    var r = {};
                    r[outdir + "/js/vendor.js"] = [outdir + "/js/vendor.js"];
                    return r;
                }()
            },
            app_js: {
                files: function() {
                    var r = {};
                    r[outdir + "/js/app.js"] = [outdir + "/js/app.js"];
                    return r;
                }()
            }
        },
        cssmin: {
            app_css: {
                files: function() {
                    var r = {};
                    r[outdir + "/css/app.css"] = [outdir + "/css/app.css"];
                    return r;
                }()
            }
        },
        htmlmin: {
            index_html: {
                options: {
                    removeComments: true,
                    collapseWhitespace: true
                },
                files: function() {
                    var r = {};
                    r[outdir + "/index.html"] = [outdir + "/index.html"];
                    return r;
                }()
            }
        },
        concat: {
            vendor_js: {
                src: [
                    'lib/moment.js',
                    'lib/jquery/jquery.js',
                    'lib/angular/angular.js',
                    'lib/angular/angular-route.js',
                    'lib/angular/angular-touch.js'
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
                        src: ['index.html', 'data/*.*'],
                        dest: outdir + '/'
                    }
                ]
            },
            icons: {
                files: [
                    {
                        expand: true,
                        cwd: 'logo/',
                        src: ['*.*png'],
                        dest: outdir + '/'
                    }
                ]
            },
            server: {
                files: [
                    {
                        expand: true,
                        cwd: 'server/',
                        src: ['*.*'],
                        dest: outdir + '/data'
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
                tasks: ['copy:static']
            },
            icons: {
                files: [
                    'logo/*.png'
                ],
                tasks: ['copy:icons']
            }
        },
        connect: {
            server: {
                options: {
                    port: 80,
                    base: outdir,
                    keepalive: true
                }
            }
        },
        ngtemplates: {
            compile: {
                options: {
                    module: 'ThatOneFeed',
                    htmlmin: {
                        removeComments: true,
                        collapseWhitespace: true
                    }
                },
                cwd: 'app',
                src: 'partials/*.html',
                dest: 'app/js/_templates.js'
            }
        },
        clean: {
            all: [
                "public", // not outdir, in case we go up...
                "target",
                "app/css/_*",
                "app/js/_*"
            ],
            static: [
                outdir + "/data",
                outdir + "/images"
            ]
        },
        exec: {
            deploy: {
                cmd: "rsync --progress --verbose --stats -a --delete-excluded --delete-after public/ barneyb@barneyb.com:/home/www/barneyb.com/thatonefeed/"
            }
        }
    });

    // Load the plugin
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-angular-templates');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-contrib-htmlmin');
    grunt.loadNpmTasks('grunt-exec');

    grunt.registerTask('build', ['clean:all', 'coffee', 'less', 'ngtemplates', 'concat', 'copy:static', 'copy:icons']);
    grunt.registerTask('default', ['build']);
    grunt.registerTask('client', ['build', 'watch']);
    grunt.registerTask('package', ['build', 'clean:static', 'copy:server', "uglify", "cssmin", "htmlmin"]);
    grunt.registerTask('deploy', ['exec:deploy'])

};