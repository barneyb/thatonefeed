module.exports = function (grunt) {

    const isServer = grunt.option('server');
    const outdir = isServer ? '..' : 'public';

    function inPlaceOutfile(path) {
        while (path.charAt(0) === "/") {
            path = path.substr(1);
        }
        path = outdir + "/" + path;
        return {
            [path]: [path],
        };
    }

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        less: {
            compile: {
                files: {
                    'app/css/_app_less.css': 'app/styles/**/*.less',
                },
            },
        },
        babel: {
            options: {
                sourceMap: false,
                presets: ['@babel/env'],
            },
            src: {
                files: inPlaceOutfile("js/app.js"),
            },
        },
        uglify: {
            vendor_js: {
                files: inPlaceOutfile("js/vendor.js"),
            },
            app_js: {
                files: inPlaceOutfile("js/app.js"),
            },
        },
        imageEmbed: {
            app_css: {
                src: [outdir + '/css/app.css'],
                dest: outdir + '/css/app.css',
                options: {
                    deleteAfterEncoding: false,
                },
            },
        },
        cssmin: {
            app_css: {
                files: inPlaceOutfile("css/app.css"),
            },
        },
        cacheBust: {
            index_html: {
                options: {
                    assets: [
                        outdir + '/js/**',
                        outdir + '/css/**',
                    ],
                    deleteOriginals: true,
                    length: 10,
                },
                src: [outdir + '/index.html'],
            },
        },
        htmlmin: {
            index_html: {
                options: {
                    removeComments: true,
                    collapseWhitespace: true,
                },
                files: inPlaceOutfile("index.html"),
            },
        },
        concat: {
            vendor_js: {
                src: [
                    'lib/moment.js',
                    'lib/jquery/jquery.js',
                    'lib/angular/angular.js',
                    'lib/angular/angular-route.js',
                ],
                dest: outdir + '/js/vendor.js',
            },
            app_js: {
                src: [
                    'app/scripts/app.js', // entry point has to be first
                    'app/scripts/**/*.js',
                    'app/js/*.js',
                ],
                dest: outdir + '/js/app.js',
            },
            app_css: {
                src: [
                    'app/css/*.css',
                ],
                dest: outdir + '/css/app.css',
            },
        },
        copy: {
            static: {
                files: [
                    {
                        expand: true,
                        cwd: 'app/',
                        src: [
                            'data/**/*.*',
                            'images/**/*.*',
                            'index.html',
                        ],
                        dest: outdir + '/',
                    },
                ],
            },
            icons: {
                files: [
                    {
                        expand: true,
                        cwd: 'logo/',
                        src: ['*.*png'],
                        dest: outdir + '/',
                    },
                ],
            },
            server: {
                files: [
                    {
                        expand: true,
                        cwd: 'server/',
                        src: ['*.*'],
                        dest: outdir + '/data',
                    },
                ],
            },
            server_config: {
                files: [
                    {
                        expand: true,
                        cwd: 'app/data/',
                        src: ['config.server.js'],
                        dest: outdir + '/data',
                        rename: function (dest, src) {
                            return dest + "/config.js";
                        },
                    },
                ],
            },
        },
        watch: {
            less: {
                files: [
                    'app/styles/**/*.less',
                ],
                tasks: ['less'],
            },
            vendor_js: {
                files: [
                    'lib/**/*.js',
                ],
                tasks: ['concat:vendor_js'],
            },
            app_js: {
                files: [
                    'app/js/*.js',
                    'app/scripts/**/*.js',
                ],
                tasks: ['concat:app_js'],
            },
            templates_js: {
                files: [
                    'app/partials/*.html',
                ],
                tasks: ['ngtemplates'],
            },
            app_css: {
                files: [
                    'app/css/*.css',
                ],
                tasks: ['concat:app_css'],
            },
            static: {
                files: [
                    'app/data/**/*.*',
                    'app/images/**/*.*',
                    'app/index.html',
                ],
                tasks: ['copy:static'],
            },
            icons: {
                files: [
                    'logo/*.png',
                ],
                tasks: ['copy:icons'],
            },
        },
        connect: {
            server: {
                options: {
                    port: 80,
                    base: outdir,
                    keepalive: true,
                },
            },
        },
        ngtemplates: {
            compile: {
                options: {
                    module: 'ThatOneFeed',
                    htmlmin: {
                        removeComments: true,
                        collapseWhitespace: true,
                    },
                },
                cwd: 'app',
                src: 'partials/*.html',
                dest: 'app/js/_templates.js',
            },
        },
        clean: {
            all: [
                'public', // not outdir, in case we go up...
                // children of outdir
                outdir + "/css",
                outdir + "/data",
                outdir + "/images",
                outdir + "/js",
                // internal stuff
                'target',
                'app/css',
                'app/js',
            ],
            static: [
                outdir + '/data',
                outdir + '/images',
            ],
        },
        exec: {
            deploy: {
                cmd: 'rsync --progress --verbose --stats -a --delete-excluded --delete-after public/ barneyb@barneyb.com:/home/www/barneyb.com/thatonefeed/',
            },
        },
    });

    // Load the plugin
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-babel');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-angular-templates');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    grunt.loadNpmTasks('grunt-image-embed');
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-contrib-htmlmin');
    grunt.loadNpmTasks('grunt-cache-bust');
    grunt.loadNpmTasks('grunt-exec');

    grunt.registerTask(
        'build',
        ['clean:all', 'less', 'ngtemplates', 'concat', 'copy:static', 'copy:icons'],
    );
    grunt.registerTask('default', ['build']);
    var clientTasks = ['build', 'watch'];
    if (isServer) {
        clientTasks.splice(1, 0, "copy:server_config")
    }
    grunt.registerTask('client', clientTasks);
    grunt.registerTask(
        'package',
        ['build', 'imageEmbed', 'clean:static', 'copy:server', 'babel', 'uglify', 'cssmin', 'cacheBust', 'htmlmin'],
    );
    grunt.registerTask('deploy', ['exec:deploy'])

};
