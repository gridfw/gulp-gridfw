###*
 * Copy libs
###
copy: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	# Add task
	task= =>
		Gulp= @_Gulp
		Gulp.src options.src, nodir: yes, since: Gulp.lastRun(task)
			.pipe @onError()
			.pipe Gulp.dest options.dest
	@addTask options.name, options.src, task
	this # chain