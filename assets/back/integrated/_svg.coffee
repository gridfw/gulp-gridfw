###*
 * Minify svg
###
svg: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	# Add task
	Gulp= @_Gulp
	@addTask options.name, options.src, =>
		Gulp.src options.src, nodir: yes
			.pipe @onError()
			.pipe Svgmin()
			.pipe Gulp.dest options.dest
	this # chain
