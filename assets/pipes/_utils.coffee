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
		return GulpTerser(@_uglifyBrowser)
	else
		_cb= (file, enc, cb)->
			cb(null, file)
			return
		return Through2.obj _cb