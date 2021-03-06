/**
 * Created by AshGillman on 19/04/2015.
 *
 * Based on:
 * https://github.com/greypants/gulp-starter/
 */

var dest = "./build";
var src = './src';

module.exports = {
    browserSync: {
        server: {
            // Serve up our build folder
            baseDir: dest
        }
    },
    sass: {
        src: src + "/sass/**/*.{sass,scss,css}",
        dest: dest,
        settings: {
            indentedSyntax: true, // Enable .sass syntax!
            imagePath: 'images' // Used by the image-url helper
        }
    },
    images: {
        src: src + "/images/**",
        dest: dest + "/images"
    },
    markup: {
        src: src + "/htdocs/**",
        dest: dest
    },
    iconFonts: {
        name: 'Gulp Starter Icons',
        src: src + '/icons/*.svg',
        dest: dest + '/fonts',
        sassDest: src + '/sass',
        template: './gulp/tasks/iconFont/template.sass.swig',
        sassOutputName: '_icons.sass',
        fontPath: 'fonts',
        className: 'icon',
        options: {
            fontName: 'Post-Creator-Icons',
            appendCodepoints: true,
            normalize: false
        }
    },
    browserify: {
        // A separate bundle will be generated for each
        // bundle config in the list below
        bundleConfigs: [/*{
            entries: src + '/javascript/index.coffee',
            dest: dest,
            outputName: 'index.js',
            extensions: ['.coffee'],
            require: ['jquery', 'underscore', 'd3', 'nvd3/build/nv.d3.js']
        },*/
        {
            entries: src + '/javascript/status/index.coffee',
            dest: dest,
            outputName: 'status/index.js',
            extensions: ['.coffee'],
            require: ['jquery', 'underscore', 'd3', 'nvd3/build/nv.d3.js']
        },
        {
            entries: src + '/javascript/scatter/index.coffee',
            dest: dest,
            outputName: 'scatter/index.js',
            extensions: ['.coffee'],
            require: ['jquery', 'underscore', 'd3', 'nvd3/build/nv.d3.js']
        }]
    },
    production: {
        cssSrc: dest + '/*.css',
        jsSrc: dest + '/*.js',
        dest: dest
    },
    deploy: {
        dest: dest
    },
    nvd3css: {
        src: './node_modules/nvd3/build/nv.d3.css',
        dest: src + "/sass/"
    },
    lint: {
        src: src + '/javascript/**/*.coffee'
    },
    karma: {
        src: src + '/javascript/__test__/**/*.coffee'
    },
    copyData: {
        src: src + '/data/**/*',
        dest: dest + '/data'
    }
};
