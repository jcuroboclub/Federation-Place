/**
 * Added by AshGillman on 19/04/2015.
 *
 * Thanks to:
 * https://github.com/greypants/gulp-starter/
 */

var requireDir = require('require-dir');

// Require all tasks in gulp/tasks, including subfolders
requireDir('./gulp/tasks', { recurse: true });