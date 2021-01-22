
# Rename views: add locale folder
viewRename: (locale)->
	return Through2.obj (file, enc, cb)->
		path= Path.join file.base, locale, (file.path.slice file.base.length)
		# path= path.replace /\..+?$/, '.js'
		file.path= path
		cb null, file
		return
###*
 * Default view compiler
 * @param {Boolean} isModule - if it's a node module or simple js function
 * @optional @param {Object} viewSettings - settings to pug
###
pugPipeCompiler: do ->
	# text filter
	HTML_REPLACE=
		'>'	: '&gt;'
		'<'	: '&lt;'
		'\'': '&#039;'
		'"' : '&quot;'
		'&' : '&amp;'
	# coffeescript filter options
	CsOptions=
		bare: no
		header: no
		sourceMap: no
		sourceRoot: no
	# Filters
	devFilters=
		text: (txt, options) -> txt.replace /([<>&"'])/g, (_, c)-> HTML_REPLACE[c]
		coffeescript: (txt, options)-> Coffeescript.compile txt, CsOptions
		js:	(txt, options)-> txt
		sass: (txt, options)->
			# compile sass
			sassResult= Sass.renderSync
				data: txt
				indentedSyntax: yes
				indentType: 'tab'
				outputStyle: 'compact'
			# return string
			return sassResult.css.toString('utf8')
		json: (txt, options)->
			dt= null
			eval "dta= #{Coffeescript.compile txt, CsOptions}"
			JSON.stringify dta, null, "\t"
	prodFilters=
		text:	devFilters.text
		coffeescript: (txt, options)->
			try
				v = Terser.minify Coffeescript.compile txt, CsOptions
				throw v.error if v.error
				return v.code
			catch e
				console.log "ERR>>", e
		js:	(txt, options)->
			v = Terser.minify txt
			throw v.error if v.error
			return v.code
		sass: (txt, options)->
			# compile sass
			sassResult= Sass.renderSync
				data: txt
				indentedSyntax: yes
				indentType: 'tab'
				outputStyle: 'compressed'
			# return string
			return sassResult.css.toString('utf8')
		json: (txt, options)->
			eval "var dta= #{Coffeescript.compile txt, CsOptions}"
			return JSON.stringify dta
	# Interface
	return (isModule, viewSettings)->
		filters= if @isProd then prodFilters else devFilters
		return Through2.obj (file, enc, cb)->
			err = null
			try
				# Checks
				throw new Error "Compile-views>> Stream not supported: #{file.path}" if file.isStream()
				return cb null unless file.isBuffer()
				content= file.contents.toString('utf8')
				content= Pug.compileClient content, {
					filename:		file.path
					debug:			no
					compileDebug:	no
					filters:		filters
					viewSettings...
					} 
					# globals:		options.globals
					# inlineRuntimeFunctions: no
				if isModule
					content= "#{content}\nmodule.exports= template;"
				else
					content= content.replace /^function\s+template/, 'function'
				file.contents = Buffer.from content, 'utf8'
				file.path= file.path.replace /\..+$/, '.js'
			catch e
				err= new PluginError {plugin: '::view-compiler', error: e, fileName: file.path}
			cb err, file
			return
