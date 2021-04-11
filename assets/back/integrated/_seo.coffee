###*
 * Seo
###
seo: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and options
	throw new Error 'Missing Options.robots' unless options.robots
	throw new Error 'Missing Options.sitemap' unless options.sitemap
	throw new Error 'Missing Options.dest' unless options.dest
	# robots
	Gulp= @_Gulp
	@addTask options.name, options.robots, =>
		Gulp.src options.robots, nodir: yes
			.pipe @onError()
			.pipe @precompile(options.data)
			.pipe Gulp.dest options.dest
	# sitemap
	@addTask options.name, options.sitemap, =>
		Gulp.src options.sitemap, nodir: yes
			.pipe @onError()
			.pipe @precompile(options.data)
			.pipe GulpPug {}
			.pipe Rename {extname: '.xml'}
			.pipe Gulp.dest options.dest
	this # chain