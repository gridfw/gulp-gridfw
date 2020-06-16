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
		glp= require Path.join process.cwd(), "#{GULP_FILE_NAME}"
		glp= glp.run()
		return glp(cb)
	# add task
	gulp.task 'default', gulp.series compileGulp, runGulp
	this # chain

