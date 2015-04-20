/**
 * Created by AshGillman on 20/04/2015.
 */

var config       = require('../config').lint;
var gulp = require('gulp');
var coffeelint = require('gulp-coffeelint');

gulp.task('lint', function () {
    gulp.src(config.src)
        .pipe(coffeelint())
        .pipe(coffeelint.reporter())
});