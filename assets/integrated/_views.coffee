###*
 * Compile views
 * @param {PATH} options.views - path to views
 * @param {PATH} options.i18n - path to i18n files
 * @param {PATH} options.dest - dest directory
 * @optional @param {Object} data	- data to use when precompiling code
 * @optional @param {function} compiler - function that will compile views, @default GulpPug
 * @optional @param {Strign} tmpDir - Path of temporary directory that will be used to store temporary compiled views, @default tmp/views
###
views: do ->
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
	# Rename views
	viewRename= (locale)->
		return Through2.obj (file, enc, cb)->
			path= Path.join file.base, locale, (file.path.slice file.base.length)
			# path= path.replace /\..+?$/, '.js'
			file.path= path
			cb null, file
			return
	# interface
	return (options)->
		throw new Error 'Illegal arguments' unless arguments.length is 1 and typeof options is 'object' and options
		throw new Error 'Missing options.src' unless options.src
		throw new Error 'Missing options.i18n' unless options.i18n
		throw new Error 'Missing options.dest' unless options.dest

		# watch files
		watchQ= options.src
		if Array.isArray watchQ
			watchQ= watchQ.slice 0
		else
			watchQ= [watchQ]
		i18n=options.i18n
		if Array.isArray i18n
			watchQ.push el for el in i18n
		else
			watchQ.push i18n
		# base path
		basePath= GlobBase(options.src).base
		# view compiler
		isProd= @isProd
		isDev= not isProd
		unless viewCompiler= options.compiler
			viewCompiler= ->
				# Filters
				filters=
					text: (txt, options) -> txt.replace /([<>&"'])/g, (_, c)-> HTML_REPLACE[c]
					coffeescript: (txt, options)->
						txt= Coffeescript.compile txt, CsOptions
						if isProd
							v = Terser.minify txt
							throw v.error if v.error
							txt= v.code
						return txt
					js:	(txt, options)->
						if isProd
							v = Terser.minify txt
							throw v.error if v.error
							txt= v.code
						return txt
					sass: (txt, options)->
						# compile sass
						sassResult= Sass.renderSync
							data: txt
							indentedSyntax: yes
							indentType: 'tab'
							outputStyle: if isDev then 'compact' else 'compressed'
						# return string
						return sassResult.css.toString('utf8')
					json: (txt, options)->
						eval "var dta= #{Coffeescript.compile txt, CsOptions}"
						if isDev
							return JSON.stringify dta, null, "\t"
						else
							return JSON.stringify dta
				# Interface
				return Through2.obj (file, enc, cb)->
					err = null
					try
						# Checks
						throw new Error "Compile-views>> Stream not supported: #{file.path}" if file.isStream()
						return cb null unless file.isBuffer()
						content= file.contents.toString('utf8')
						content= Pug.compileClient content,
							filename:		file.path
							debug:			no
							compileDebug:	no
							filters:		filters
							# globals:		options.globals
							# inlineRuntimeFunctions: no
						content= "#{content}\nmodule.exports= template;"
						file.contents = Buffer.from content, 'utf8'
						file.path= file.path.replace /\..+$/, '.js'
					catch e
						console.log 'HAS ERROR: ', e
						err = e
					cb err, file
					return
		# Tmp dir
		tmpDir= options.tmpDir or 'tmp/views'
		# Task
		@addTask options.name, watchQ, (cb)=>
			try
				# Load i18n data
				i18n= await @loadI18n(options.i18n, options.data)
				# parse i18n values
				d= null
				for k,v of i18n
					eval 'd='+v
					i18n[k]= d
			catch err
				console.error 'ERR>>', err
			
			# Compile views
			Gulp= @_Gulp
			gulp= Gulp.src options.src, nodir: yes
			gulps= []
			for locale, i18nContent of i18n
				glp= gulp
					.pipe(GulpClone())
					.pipe @onError()
					.pipe viewRename(locale)
					.pipe @precompile({options.data..., i18n: i18nContent})
					.pipe Gulp.dest tmpDir
					.pipe @waitToFinish()
					# .pipe Through2.obj (file, enc, cb)->
					# 	console.log '-------- File: ', file.path
					# 	cb null, file
					# 	return
					.pipe viewCompiler()
					# .pipe Rename (path)->
					# 	path.extname= '.js'
					# 	path.dirname= Path.join path.dirname, locale
					# 	return
					.pipe @minifyJS()
					.pipe Gulp.dest options.dest
				gulps.push glp
			return EventStream.merge(gulps)
		this # chain