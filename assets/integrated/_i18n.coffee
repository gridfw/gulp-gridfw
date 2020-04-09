###*
 * Compile i18n files for the server
 * @param {String} options.src - Path to source files
 * @param {String} options.dest - Path to dest folder
 * @optional @param {Object} data	- data to use when precompiling code
 * @optional @param {String} varname - name of the global variable to use when browser
###
i18n: (options)->
	# Checks
	throw new Error 'Illegal arguments' unless arguments.length is 1 and typeof options is 'object' and options
	throw new Error 'Missing options.src' unless options.src
	throw new Error 'Missing options.dest' unless options.dest
	# Add task
	Gulp= @_Gulp
	@addTask options.name, options.src, =>
		Gulp.src options.src, nodir: yes
			.pipe @onError()
			.pipe @precompile(options.data)
			.pipe GulpCoffeescript bare: true
			.pipe @compileI18n options
			.pipe @minifyJS()
			.pipe Gulp.dest options.dest
	this # chain


###*
 * Get i18n files value
###
loadI18n: (path, data)->
	new Promise (resolve, reject)=>
		Gulp= @_Gulp
		i18n= null
		Gulp.src path
			.pipe @precompile(data)
			.pipe GulpCoffeescript bare: true
			.pipe(@compileI18n dataCb: (data)-> i18n= data)
			.on 'error', reject
			.on 'finish', -> resolve i18n
		return