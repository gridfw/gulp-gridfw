###*
 * Gulp Gridfw
###
Path=			require 'path'
Fs=				require 'fs'
EventStream=	require 'event-stream'

# Gulp=			require 'gulp'
PluginError=	require 'plugin-error'
Vinyl=			require 'vinyl'
GulpPlumber=	require 'gulp-plumber'
Rename=			require 'gulp-rename'
Chalk=			require 'chalk'


Glob = require 'glob'
GlobBase= require 'glob-base'

Terser=			require 'terser'
Pug=			require 'pug'
Coffeescript=	require 'coffeescript'

Include=		require 'gulp-include'
GulpClone=		require 'gulp-clone'
GulpPug=		require 'gulp-pug'
ImageMin=		require 'gulp-imagemin'
ToIco=			require 'to-ico'
Babel=			require 'gulp-babel'
GulpSass=		require 'gulp-sass'
Through2=		require 'through2'

Svgmin=			require 'gulp-svgmin'

GulpCoffeescript= require 'gulp-coffeescript'
EJS=			require 'ejs'

Sharp=			require 'sharp'
CliTable=		require 'cli-table'

GulpFilter=		require 'gulp-filter'

# {spawn: Spawn}=	require 'child_process'
{exec: Exec}=	require 'child_process'

# params
UGLIFY_NODE_PARAMS= {module: on, compress: {toplevel: true, module: true, keep_infinity: on, warnings: on} }
UGLIFY_BROWSER_PARAMS= {compress: {toplevel: no, keep_infinity: on, warnings: on} }

EJS_PRECOMPILE=
	delimiter: '%'
	async: yes


module.exports= class
	###*
	 * @param  {Boolean} options.isProd - if production mode
	 * @param {Object} options.uglifyNode - Uglify options for node js files
	 * @param {Object} options.uglifyBrowser - Uglify options for browser
	 * @optional @param {Object} options.precompileOptions - options to use for EJS used to precompiled files
	 * @optional @param {Integer} options.delay - watch delay, default to 200ms
	 *
	###
	constructor: (gulp, options)->
		options ?= {}
		@_Gulp= gulp
		@isProd= !!options.isProd
		@_uglifyNode= options.uglifyNode or UGLIFY_NODE_PARAMS
		@_uglifyBrowser= options.uglifyBrowser or UGLIFY_BROWSER_PARAMS
		@_precompileOptions= options.precompileOptions or EJS_PRECOMPILE
		@_delay= options.delay or 200
		# tasks
		@_tasks= []
		@_watch= []
		@_isRunning= no
		return
	# PIPES
	#=include pipes/_*.coffee

	# INTEGRATED CODE
	#=include integrated/_*.coffee
