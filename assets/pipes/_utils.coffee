###*
 * Wait for pipeline to finish and stream all
###
waitToFinish: ->
	files = []
	_prp= (file, enc,cb)->
		files.push file
		do cb
		return
	_acc= (cb)->
		@push file for file in files
		do cb
		return
	Through2.obj _prp, _acc


###*
 * Minify if prod
###
minifyJS: ->
	if @isProd
		_cb= (file, enc, cb)->
			err= null
			try
				if file.isBuffer()
					switch Path.extname(file.path).toLowerCase()
						when '.js'
							result= Terser.minify file.contents.toString 'utf8' #, @_uglifyBrowser
							throw result.error if result.error
							file.contents= Buffer.from result.code
						else
							console.log Chalk.keyword('orange')("--->> MinifyJS >> ignored file: #{file.path}")
			catch e
				# console.log 'ERR>', e
				err= new PluginError
					plugin: 'MinifyJS'
					fileName: file.path
					error: e
					showStack: yes
			cb err, file
			return
	else
		_cb= (file, enc, cb)->
			cb(null, file)
			return
	return Through2.obj _cb