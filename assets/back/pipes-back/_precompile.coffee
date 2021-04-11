###*
 * Precompile code using 
###
precompile: (data)->
	Through2.obj (file, enc, cb)->
		err= null
		try
			code= file.contents.toString 'utf8'
			result= EJS.render code, data, @_precompileOptions
			file.contents= Buffer.from result
		catch e
			err= new PluginError {plugin: '::EJS', error: e, filename: file.path}
		cb err, file
		return