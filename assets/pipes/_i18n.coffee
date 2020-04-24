###*
 * Compile i18n files for Gulp
###
compileI18n: do ->
	# JSON stringify
	STR_COMPILE_REGEX= /^\s*function \(.\)\{var .="";return .\+=("[^"]+")\}\s*$/
	PUG_REPLACE_REGEX= /(\b)pug\.escape\(/g
	_jsonStringify= (obj, replacer, indent)->
		# Replacer
		values= []
		valuesI= 0
		replacerWrap= (k,v)->
			v= replacer k, v
			if typeof v is 'string'
				values.push v
				v= "-'#{valuesI++}'-"
			return v
		# Stringify
		str= JSON.stringify obj, replacerWrap, indent
		# Replace strings
		str= str.replace /"-'(\d+)'-"/g, (_, i)-> "#{values[parseInt i]}"
		return str
	# PUG ESCAPE
	PUG_ESCAPE= 'const pug_match_html=/["&<>]/;function pugEscape(e){var a=""+e,t=pug_match_html.exec(a);if(!t)return e;var r,c,n,s="";for(r=t.index,c=0;r<a.length;r++){switch(a.charCodeAt(r)){case 34:n="&quot;";break;case 38:n="&amp;";break;case 60:n="&lt;";break;case 62:n="&gt;";break;default:continue}c!==r&&(s+=a.substring(c,r)),c=r+1,s+=n}return c!==r?s+a.substring(c,r):s}'
	# Map locales
	_mapLocales= (bufferedI18n)->
		# check for local name
		localeNames= bufferedI18n.localeName
		throw 'Expected "localeName" to map all used locales' unless (typeof localeNames is 'object') and localeNames
		usedLocales= Object.keys localeNames
		# prepare result
		result= {}
		result[k]= {} for k in usedLocales
		# Map
		missingLocales= []
		for k,v of bufferedI18n
			# general value
			if (typeof v is 'string') or (typeof v is 'function')
				for lg in usedLocales
					result[lg][k]= v
			# Custom message for each local
			else if (typeof v is 'object') and v
				# Add values
				for lg in usedLocales
					missingLocales.push "#{k}.#{lg}" unless result[lg][k]= v[lg]
				# Check for extra locales
				for lg of v
					unless lg in usedLocales
						throw "Enexpected local: #{k}.#{lg} - Please add this locale to 'localeName' first."
			else
				throw "Illegal value @#{k}"
		if missingLocales.length
			throw "Missing locales: #{missingLocales.join ','}"
		# Map locales names
		# Add reserved attributes
		throw '"locale" and "locales" are reserved attributes' if result.locale or result.locales
		for lg in usedLocales
			# Locale
			result[lg].locale= lg
			# locales names
			result[lg].locales= localeNames
		# Return
		return result
	# Compile strings
	_compileStr= (str, globals)->
		str= "|#{str.replace /\n/g, "\n|"}"
		str= Pug.compileClient str,
			compileDebug: off
			globals: globals
			inlineRuntimeFunctions: no
			name: 'ts'
		# uglify and remove unused vars
		v = Terser.minify str
		throw v.error if v.error
		str = v.code.replace /^function ts/, 'function '
		# Replace with simple string if is the case
		str= str.replace STR_COMPILE_REGEX, '$1'
		return str
	# Compile PUG
	_compile= (data, options)->
		# globals
		if globals= options.globals
			globals= if Array.isArray globals then globals.slice 0 else [globals]
			globals.push 'i18n' unless 'i18n' in globals
		else
			globals= ['i18n']
		if typeof options.varname is 'string'
			v= options.varname.split('.')[0]
			globals.push v unless v in globals
		# Stringify
		_stringify= (k,v)->
			# Compile PUG
			if typeof v is 'string'
				v= _compileStr v, globals
			# Function
			else if typeof v is 'function'
				v= v.toString()
			return v
		# compile
		result= {}
		for locale,fl of data
			content = _jsonStringify fl, _stringify, "\t"
			# Add pug escape
			if PUG_REPLACE_REGEX.test content
				content= content.replace PUG_REPLACE_REGEX, '$1 pugEscape('
				content= "(function{#{PUG_ESCAPE}; return #{content}})()"
			result[locale]= content
		return result
	# Convert to JS files
	_convertToJsFiles= (data, cwd, options)->
		# join
		for locale, content of data
			# Browser side
			if options.varname
				content= "#{options.varname}=#{content};"
			else if options.jsonp
				content= "#{options.jsonp}(#{content});"
			# server side
			else
				content= "module.exports=#{content};"
			# export file
			new Vinyl
				cwd: cwd
				path: "#{locale}.js"
				contents: Buffer.from content
	# Main function
	(options)->
		# buffer files content
		bufferedI18n = {}
		cwd  = null
		pretty= not @isProd
		bufferContents= (file, end, cb)->
			# ignore incorrect files
			return cb() if file.isNull()
			err = null
			try
			# process
				throw new Error "Streaming isn't supported" if file.isStream()
				# compile file and buffer data
				Object.assign bufferedI18n, eval file.contents.toString 'utf8'
				# base dir
				cwd= file._cwd
			catch e
				err = new PluginError 'GulpGridfw.i18n', e
			cb err
			return
		# concat all files
		concatAll = (cb)->
			err= null
			languages= []
			try
				# Convert into sepratated locales
				data= _mapLocales bufferedI18n
				# Compile
				data= _compile data, options, pretty
				# do operation on data (or just get data)
				if typeof options.dataCb is 'function'
					options.dataCb data
				# Convert to files
				files= _convertToJsFiles data, cwd, options
				# Create mapper data
				localesPath= {}
				localesPath[k]= "#{k}.js" for k of data
				# Mapper
				files.push new Vinyl
					cwd: cwd
					path: 'mapper.json'
					contents: Buffer.from JSON.stringify locales:localesPath
				# Push files
				@push file for file in files
			catch e
				err = new PluginError 'GulpGridfw.i18n', e
			cb err
			return
		# return
		return Through2.obj bufferContents, concatAll
