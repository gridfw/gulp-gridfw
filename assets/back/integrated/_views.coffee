###*
 * Compile views
 * @param {PATH} options.views - path to views
 * @param {PATH} options.i18n - path to i18n files
 * @param {PATH} options.dest - dest directory
 * @optional @param {Boolean} options.modifiedOnly - if compile modified files only
 * @optional @param {Object} data	- data to use when precompiling code
 * @optional @param {function} compiler - function that will compile views, @default GulpPug
 * @optional @param {Strign} tmpDir - Path of temporary directory that will be used to store temporary compiled views, @default tmp/views
###
views: (options)->
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
		viewCompiler= @pugPipeCompiler.bind this

	# Compile data
	data= options.data or {}

	# Tmp dir
	tmpDir= options.tmpDir or 'tmp/views'
	# Task
	self= this
	task= (cb)->
		try
			# Load i18n data
			i18n= await self.loadI18n(options.i18n, data)
			# parse i18n values
			d= null
			for k,v of i18n
				eval 'd='+v
				i18n[k]= d
		catch err
			console.error 'ERR>>', err

		# Compile views
		Gulp= self._Gulp
		gulpOptions= nodir: yes
		gulpOptions.since= Gulp.lastRun(task) if options.modifiedOnly
		gulp= Gulp.src options.src, gulpOptions
		gulps= []
		_execGulps= (locale, i18nContent)->
			# Create filter
			filterIgnoreLocales= []
			for k of i18n when k isnt locale
				filterIgnoreLocales.push k
			# return pipline
			return gulp
				.pipe(GulpClone())
				.pipe self.onError()
				# Filter files that are in specific language
				.pipe GulpFilter (file)->
					fileName= file.path
					if ~(i= fileName.lastIndexOf('.')) and ~(j= fileName.lastIndexOf('.', i-1))
						part= fileName.substring(j+1, i)
						if part is locale
							file.path= "#{fileName.substr(0, j)}#{fileName.substr(i)}"
						else if part in filterIgnoreLocales
							return no
					return yes
				.pipe self.viewRename(locale)
				.pipe self.precompile({data..., i18n: i18nContent})
				.pipe Gulp.dest tmpDir
				.pipe self.waitToFinish()
				# .pipe Through2.obj (file, enc, cb)->
				# 	console.log '-------- File: ', file.path
				# 	cb null, file
				# 	return
				.pipe viewCompiler(yes, null)
				# .pipe Rename (path)->
				# 	path.extname= '.js'
				# 	path.dirname= Path.join path.dirname, locale
				# 	return
				.pipe self.minifyJS()
				.pipe Gulp.dest options.dest
		for locale, i18nContent of i18n
			gulps.push _execGulps locale, i18nContent
		return EventStream.merge(gulps)
	@addTask options.name, watchQ, task
	this # chain
