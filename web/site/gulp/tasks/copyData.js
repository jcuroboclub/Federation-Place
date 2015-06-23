var gulp       = require('gulp');
var config     = require('../config').copyData;

gulp.task('copyData', function() {
  return gulp.src(config.src)
    .pipe(gulp.dest(config.dest));
});
