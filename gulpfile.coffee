path       = require 'path'
glob       = require 'glob'
fs         = require 'fs-extra'

_          = require 'lodash'

moment     = require 'moment'

mime       = require 'mime'
image_size = require 'image-size'

# PHP
php        = require 'phpjs'
# YAML
YAML       = require 'yamljs'
# MarkDown
marked     = require 'remarkable'


# Utils
write = (data, out_file, rw = false) ->
	fs.ensureDir path.dirname out_file, (err) ->
		console.error 'ERROR create dir ' + path.dirname out_file
	fs.exists out_file, (exist) ->
		if exist and rw == true or !exist
			fs.outputFile out_file , data, 'utf8', (err) ->
				console.error 'ERROR during Write the file ' + out_file + ' ' + err if err


# readJSON

Posts = fs.readJsonSync './PostsSort.json'

# console.log _(Posts).pluck('post_title').value()


# GulpFile
gulp       = require 'gulp'
gutil      = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'
coffee     = require 'gulp-coffee'
uglify     = require 'gulp-uglify'
jade       = require 'gulp-jade'
stylus     = require 'gulp-stylus'

# Stylus FW
koutoSwiss = require 'kouto-swiss'
axis       = require 'axis'
jeet       = require 'jeet'

prefix     = require 'gulp-autoprefixer'
csso       = require 'gulp-csso'
livereload = require 'gulp-livereload'
watchify   = require 'watchify'
changed    = require 'gulp-changed'


del        = require 'del'

# Server
ecstatic   = require 'ecstatic'

# ENV
production = process.env.NODE_ENV is 'production'


# Pathes
paths =
	scripts:
		source: './src/coffee/main.coffee'
		watch: './src/coffee/**/*.coffee'
		destination: './public/js/'
	templates:
		source: './src/jade/**/[^_]*.jade'
		watch: './src/jade/**/*.jade'
		destination: './public/'
	styles:
		source: './src/stylus/main.styl'
		watch: './src/stylus/*.styl'
		destination: './public/css/'
	assets:
		source: './src/assets/**/*.*'
		watch: './src/assets/**/*.*'
		destination: './public/'
	# public:
	# 	watch: './public/**/*.*'


# Error handler ???
handleError = (err) ->
	gutil.log err
	gutil.beep()
	this.emit 'end'


# TASKS

# SCRIPTS
gulp.task 'scripts', ->
	scripts = gulp
		.src paths.scripts.source
		.pipe sourcemaps.init()
		.pipe coffee
			bare: true
		.on 'error', handleError

	scripts = scripts.pipe uglify() unless !production
	scripts = scripts.pipe sourcemaps.write()
	scripts = scripts.pipe gulp.dest paths.scripts.destination
	scripts = scripts.pipe livereload() unless production
	scripts

# JADE
gulp.task 'templates', ->
	templates = gulp
		.src paths.templates.source
		# .pipe jade pretty: not production
		.pipe jade
			pretty: true
			locals: _(Posts)
		.on 'error', handleError

	templates = templates.pipe gulp.dest paths.templates.destination
	templates = templates.pipe livereload() unless production
	templates

# STYLES
gulp.task 'styles', ->
	styles = gulp
		.src paths.styles.source
		.pipe stylus
			set: ['include css']
			use: [axis()]
			sourcemap:
				inline: true
				sourceRoot: '.'
				basePath: paths.styles.destination
		.on 'error', handleError

	styles = styles
		.pipe prefix
			browsers: ['last 2 versions']
			cascade: false
		.pipe csso()  unless !production
		# .pipe gulp.dest paths.templates.destination + 'prefix.css'
		# .pipe csso()
		# .pipe gulp.dest paths.templates.destination + 'csso.css' unless !production

	styles = styles.pipe gulp.dest paths.styles.destination
	styles = styles.pipe livereload() unless production
	styles

# ASSETS
gulp.task 'assets', ->
	assets = gulp
		.src paths.assets.source
		.pipe changed paths.assets.destination

	assets = assets.pipe gulp.dest paths.assets.destination
	assets = assets.pipe livereload() unless production
	assets


# CLEAN
gulp.task 'clean', ->
	del build + '**/Thumbs.db', (err) ->
		console.log 'Files deleted'

# SERVER
gulp.task 'server', ->
	require 'http'
		.createServer ecstatic root: __dirname + '/public'
		.listen 9001

gulp.task 'watch', ->
	livereload.listen()

	gulp.watch paths.scripts.watch, ['scripts']
	gulp.watch paths.templates.watch, ['templates']
	gulp.watch paths.styles.watch, ['styles']
	gulp.watch paths.assets.watch, ['assets']
	# gulp.watch paths.public.watch, ['build']

	.emit 'update'

gulp.task 'build', ['scripts', 'templates', 'styles', 'assets']
gulp.task 'default', ['build', 'watch', 'server']