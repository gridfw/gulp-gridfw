###*
 * Compile JSON files
###
json: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	throw new Error 'Missing Options.watch' unless options.watch
	# Add task
	Gulp= @_Gulp
	@addTask options.name, options.watch, =>
		Gulp.src options.src, nodir: yes
			.pipe @onError()
			.pipe Include hardFail: true
			.pipe @precompile(options.data)
			.pipe GulpCoffeescript bare: true
			.pipe Through2.obj (file, enc, cb)->
				cb null unless file.isBuffer()
				err= null
				try
					data= file.contents.toString 'utf8'
					dta= null
					eval "dta= #{data}"
					if @isProd
						data= JSON.stringify dta
					else
						data= JSON.stringify dta, null, "\t"
					file.contents= Buffer.from data
				catch e
					err= new PluginError {plugin: '::json', error: e, fileName: file.path}
				cb err, file
			.pipe Rename extname: '.json'
			.pipe Gulp.dest options.dest
	this # chain
