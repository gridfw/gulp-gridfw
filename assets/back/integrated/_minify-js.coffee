###*
 * Minify js files
###
minJS: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	# Add task
	task= =>
		Gulp= @_Gulp
		glp= Gulp.src options.src, nodir: yes, since: Gulp.lastRun(task)
			.pipe @onError()
		# Babel
		if options.babel
			glp1= glp.pipe GulpClone()
				.pipe @minifyJS()
				.pipe @_Gulp.dest options.dest
			glp2= glp.pipe GulpClone()
				.pipe @babel()
				.pipe @minifyJS()
				.pipe Rename (path)->
					path.basename += '-babel'
					return
				.pipe @_Gulp.dest options.dest
			rtn= EventStream.merge [glp1, glp2]	
		else
			rtn= glp.pipe @minifyJS()
				.pipe @_Gulp.dest options.dest
		return rtn
	@addTask options.name, options.src, task
	this # chain