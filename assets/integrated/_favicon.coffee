###*
 * Create favicons
###
favicon: do ->
	# Resizer
	_resize= (obj, file, img, size, path)->
		img.clone().resize({width: size, height: size}).toBuffer().then (bf)->
			obj.push new Vinyl
				cwd: file.cwd
				base: file.base
				path: path
				contents: bf
		return
	# interface
	return (options)->
		throw new Error 'Illegal arguments' unless arguments.length is 1 and options
		throw new Error 'Missing Options.src' unless options.src
		throw new Error 'Missing Options.dest' unless options.dest
		# Add task
		Gulp= @_Gulp
		@addTask options.name, options.src, =>
			Gulp.src options.src, nodir: yes
				.pipe @onError()
				.pipe Through2.obj (file, enc, cb)->
					img= Sharp(file.path)
					basePath= file.base
					# favicon
					dirP= file.base
					# operations
					jobs= [
						# favicon
						_resize this, file, img, 64, Path.join basePath, 'favicon.png'
						# icon
						img.clone()
							.resize({width: 64, height: 64})
							.toBuffer()
							.then (bf)-> ToIco(bf, {})
							.then (bf)=>
								@push new Vinyl
									cwd:	file.cwd
									base:	file.base
									path:	Path.join basePath, 'favicon.ico'
									contents: bf
								return
					]
					# icons
					if (icons= options.icons) and icons.length
						# push
						resizeCb= (bf)=>
							@push new Vinyl
								cwd: file.cwd
								base: file.base
								path: path
								contents: bf
							return
						# op
						for sz in icons
							jobs.push _resize(this, file, img, sz, Path.join basePath, 'icons', "icon-#{sz}x#{sz}.png")
					# Promise
					Promise.all jobs
					.then -> do cb
					.catch (e)->
						cb new PluginError '::favicon', e
				.pipe ImageMin()
				.pipe Gulp.dest options.dest
		this # chain