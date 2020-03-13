###*
 * Compile sass
###
sass: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	throw new Error 'Missing Options.watch' unless options.watch
	# Add task
	@addTask options.watch, =>
		Gulp.src options.src, nodir: yes
			.pipe @onError()
			.pipe GulpSass(outputStyle: if @isProd then 'compressed' else 'compact')
			.pipe Gulp.dest options.dest
	this # chain
