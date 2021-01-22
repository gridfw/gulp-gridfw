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
				err= new PluginError {plugin: '::components', error: e, fileName: file.path}
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
					var pug_match_html=/["&<>]/;
					var pug_has_own_property=Object.prototype.hasOwnProperty;
					var pug={
						escape:function(e){var a=""+e,t=pug_match_html.exec(a);if(!t)return e;var r,c,n,s="";for(r=t.index,c=0;r<a.length;r++){switch(a.charCodeAt(r)){case 34:n="&quot;";break;case 38:n="&amp;";break;case 60:n="&lt;";break;case 62:n="&gt;";break;default:continue;}c!==r&&(s+=a.substring(c,r)),c=r+1,s+=n;}return c!==r?s+a.substring(c,r):s;},
						rethrow:function(n,e,r,t){if(!(n instanceof Error))throw n;if(!("undefined"==typeof window&&e||t))throw n.message+=" on line "+r,n;try{t=t||require("fs").readFileSync(e,"utf8");}catch(e){pug.rethrow(n,null,r);}var i=3,a=t.split("\\n"),o=Math.max(r-i,0),h=Math.min(a.length,r+i),i=a.slice(o,h).map(function(n,e){var t=e+o+1;return(t==r?"  > ":"    ")+t+"| "+n;}).join("\\n");throw n.path=e,n.message=(e||"Pug")+":"+r+"\\n"+i+"\\n\\n"+n.message,n;},
						attr:function(t,e,n,f){return!1!==e&&null!=e&&(e||"class"!==t&&"style"!==t)?!0===e?" "+(f?t:t+'="'+t+'"'):("function"==typeof e.toJSON&&(e=e.toJSON()),"string"==typeof e||(e=JSON.stringify(e),n||-1===e.indexOf('"'))?(n&&(e=pug.escape(e))," "+t+'="'+e+'"'):" "+t+"='"+e.replace(/'/g,"&#39;")+"'"):"";},
						classes:function(s,r){return Array.isArray(s)?pug.classes_array(s,r):s&&"object"==typeof s?pug.classes_object(s):s||"";},
						classes_array:function(r,a){for(var s,e="",u="",c=Array.isArray(a),g=0;g<r.length;g++)(s=pug.classes(r[g]))&&(c&&a[g]&&(s=pug.escape(s)),e=e+u+s,u=" ");return e;},
						classes_object:function(r){var a="",n="";for(var o in r)o&&r[o]&&pug_has_own_property.call(r,o)&&(a=a+n+o,n=" ");return a;},
						merge:function(e,r){if(1===arguments.length){for(var t=e[0],g=1;g<e.length;g++)t=pug.merge(t,e[g]);return t;}for(var l in r)if("class"===l){var n=e[l]||[];e[l]=(Array.isArray(n)?n:[n]).concat(r[l]||[]);}else if("style"===l){var n=pug.style(e[l]);n=n&&";"!==n[n.length-1]?n+";":n;var a=pug.style(r[l]);a=a&&";"!==a[a.length-1]?a+";":a,e[l]=n+a;}else e[l]=r[l];return e;},
						style:function(r){if(!r)return"";if("object"==typeof r){var t="";for(var e in r)pug_has_own_property.call(r,e)&&(t=t+e+":"+r[e]+";");return t;}return r+"";},
						attrs:function(t,r){var a="";for(var s in t)if(pug_has_own_property.call(t,s)){var u=t[s];if("class"===s){u=pug.classes(u),a=pug.attr(s,u,!1,r)+a;continue;}"style"===s&&(u=pug.style(u)),a+=pug.attr(s,u,!1,r);}return a;}
					};
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
				err= new PluginError {plugin: '::components', error: e}
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
