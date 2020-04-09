###*
 * Minify images and create equivalent webp
###
webp: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.src' unless options.src
	throw new Error 'Missing Options.dest' unless options.dest
	# Add task
	task= =>
		Gulp= @_Gulp
		Gulp.src options.src, nodir: yes, since: Gulp.lastRun(task)
			.pipe @onError()
			.pipe Through2.obj (file, enc, cb)->
				# keep original file
				@push file
				# dest webp
				extname= Path.extname(file.name).toLowerCase()
				webpPath= file.path+'.webp'
				unless extname is '.webp' or Fs.existsSync webpPath
					Sharp(file.path)
						.webp()
						.toBuffer()
						.then (b) ->
							cb null, new Vinyl
								cwd: file.cwd
								base: file.base
								path: webpPath
								contents: b
							return
						.catch cb
				return
			.pipe ImageMin()
			.pipe Gulp.dest options.dest
	@addTask options.name, options.src, task
	this # chain