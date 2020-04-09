###*
 * Compile gulp file
###
compileAndRunGulp: (gulp, src)->
	throw new Error 'Illegal arguments' unless arguments.length is 2
	# Load arguments
	args={}
	for argv in process.argv
		args[argv.slice(2)]= yes if argv.startsWith('--')

	# Data
	data=
		isProd: !!args.prod
		args: args

	# Gulp file name
	GULP_FILE_NAME= 'gulp-compiled.tmp.js'

	# Compile gulp
	compileGulp= =>
		console.log '════════════════════════════ Compile Gulp ════════════════════════════'
		gulp.src src
			.pipe @onError()
			.pipe Include hardFail: true
			.pipe @precompile data
			.pipe GulpCoffeescript bare: true
			.pipe Rename GULP_FILE_NAME
			.pipe gulp.dest './'
	# Run Gulp
	runGulp= (cb)->
		console.log '════════════════════════════ Run Gulp ════════════════════════════════'
		ps= Exec "gulp --gulpfile=#{GULP_FILE_NAME}"
		# stdout
		ps.stdout.on 'data', (data)->
			console.log data.trim()
			return
		# stderr
		ps.stderr.on 'data', (data)->
			console.log data.trim()
			return
		# error
		ps.on 'error', (data)->
			console.log 'GULP-ERR>>', data.trim()
			return
		# close
		ps.on 'close', ->
			console.log '════════════════════════════ Gulp closed ════════════════════════════════'
			return
		return ps
	# add task
	gulp.task 'default', gulp.series compileGulp, runGulp
	this # chain

