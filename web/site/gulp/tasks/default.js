var gulp = require('gulp');

gulp.task('default', ['sass', 'images', 'copyData', 'markup', 'lint', 'karma', 'watch']);
