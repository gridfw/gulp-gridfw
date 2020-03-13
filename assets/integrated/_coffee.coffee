###*
 * Compile server files
###
js: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	throw new Error 'Missing Options.watch' unless options.watch
	# Add task
	@addTask options.watch, =>
		glp= Gulp.src options.src, nodir: yes
			.pipe @onError()
			.pipe Include hardFail: true
			.pipe @precompile(options.data)
			.pipe GulpCoffeescript bare: true
		# babel
		if options.babel
			glp= glp.pipe Babel
				presets: ['babel-preset-env']
				plugins: [
					['transform-runtime',{
						helpers: no
						polyfill: no
						regenerator: no
					}]
					'transform-async-to-generator'
				]
		return glp.pipe @minifyJS()
			.pipe Gulp.dest options.dest
	this # chain
