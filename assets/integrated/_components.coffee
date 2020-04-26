###*
 * Compile client side components
 * @param {String} options.src - Glob path to source files
 * @optional @param {String} options.target - target file @default components.js
 * @optional @param {String} options.template - template name @default window.components
###
joinComponents: do ->
	# Create element
	_createElement= ->
		dv= document.createElement 'div'
		(fxName, args, repeat)->
			fx= @[fxName]
			throw "Unknown component: #{fxName}" unless fx
			html= if Array.isArray args then args.map(fx).join('') else fx args
			html= html.repeat repeat if repeat
			dv.innerHTML= html
			nodes= dv.childNodes
			frag= document.createDocumentFragment()
			while nodes.length
				frag.appendChild nodes[0]
			return frag
	# Generate template name
	_fileNameToAttribute= (fileName)->
		fileName.toLowerCase()
			.replace /^[\s_-]+|[\s_-]+$/g, ''
			.replace /[_-\s]+(\w)/g, (_, w)-> w.toUpperCase()
			.slice(0, -3)
	# Join views
	return (options)->
		result= {}
		isProd= @isProd
		cwd  = null
		# Template
		template= options.template or 'window.components'
		targetFile= options.target or 'components.js'
		# Collector
		_collector= (file, enc, cb)->
			return cb null unless file.isBuffer()
			err = null
			try
				fileName= file.basename
				throw new Error "Expected JS file: #{file.path}" unless fileName.endsWith '.js'
				fileName= _fileNameToAttribute fileName
				# Content
				result[fileName] = file.contents.toString 'utf8'
				# base dir
				cwd= file._cwd
			catch e
				err= new PluginError '::components', e
			cb err
			return
		# Concat
		_concatAll= (cb)->
			err= null
			try
				# join data
				jn=[]
				for k,v of result
					jn.push "#{k}:#{v}"
				# add creator
				jn.push "_:(#{_createElement.toString()})()"
				# prepare content
				content= """
				(function(){
					var data={#{jn.join ','}};
					if(typeof #{template}=='object' && #{template}) Object.assign(#{template}, data);
					else #{template}=data;
				})();
				"""
				# push as file
				@push new Vinyl
					cwd:	cwd
					path:	targetFile
					contents: Buffer.from content
			catch e
				err= new PluginError '::components', e
			cb err
		return Through2.obj _collector, _concatAll

	# Interface
###*
 * Compile client side components
 * @param {String} options.name - task name
 * @param {Glob} options.src - Glob path to src files
 * @param {String} options.dest - dest path
 * @param {Glob} options.watch - Glob path to wached files
 * @param {Boolean} options.babel - If use babel
 * @optional @param {Array} globals - List of global variables @default ['i18n', 'window']
 * @optional @param {Object} data	- data to use when precompiling code
 * @optional @param {function} compiler - function that will compile views, @default GulpPug
 * @optional @param {String} options.target - target file @default components.js
 * @optional @param {String} options.template - template name @default window.components
###
components: (options)->
	throw new Error 'Illegal arguments' unless arguments.length is 1 and typeof options is 'object' and options
	throw new Error 'Missing options.src' unless options.src
	throw new Error 'Missing options.dest' unless options.dest
	throw new Error 'Missing options.watch' unless options.watch

	# Compiler
	isProd= @isProd
	unless viewCompiler= options.compiler
		viewCompiler= @pugPipeCompiler.bind this
	# Globals
	globals= options.globals or ['i18n', 'window']
	# Task
	task= (cb)=>
		# Prepar Gulp
		Gulp= @_Gulp
		gulpOptions= nodir: yes
		gulpOptions.since= Gulp.lastRun(task) if options.modifiedOnly
		
		glp= Gulp.src options.src, gulpOptions
			.pipe @onError()
			.pipe @precompile({options.data...})
			.pipe viewCompiler(no, {globals, inlineRuntimeFunctions: no})
			.pipe @joinComponents options
			
		# Babel
		if options.babel
			glp1= glp.pipe GulpClone()
				.pipe @minifyJS()
				.pipe @_Gulp.dest options.dest
			glp2= glp.pipe GulpClone()
				.pipe @babel()
				.pipe @minifyJS()
				.pipe Rename (path)->
					path.basename += '-babel'
					return
				.pipe @_Gulp.dest options.dest
			rtn= EventStream.merge [glp1, glp2]	
		else
			rtn= glp.pipe @minifyJS()
				.pipe @_Gulp.dest options.dest
		return rtn
	# Add
	@addTask options.name, options.watch, task
	this # chain
