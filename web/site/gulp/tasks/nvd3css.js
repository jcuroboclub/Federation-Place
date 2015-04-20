/**
 * Created by AshGillman on 20/04/2015.
 */
var gulp = require('gulp');
var config = require('../config').nvd3css;

gulp.task('nvd3css', function() {
    return gulp.src(config.src)
        .pipe(gulp.dest(config.dest));
});