var gulp = require('gulp');
var config = require('../config').deploy;
var ghPages = require('gulp-gh-pages');

gulp.task('deploy', function() {
  return gulp.src(config.dest + '/**/*')
    .pipe(ghPages());
});
