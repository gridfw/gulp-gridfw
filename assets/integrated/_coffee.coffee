###*
 * Compile server files
###
js: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	throw new Error 'Missing Options.watch' unless options.watch
	# Add task
	@addTask options.name, options.watch, =>
		glp= @_Gulp.src options.src, nodir: yes
			.pipe @onError()
			.pipe Include hardFail: true
			.pipe @precompile(options.data)
			.pipe GulpCoffeescript bare: true
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
	this # chain
