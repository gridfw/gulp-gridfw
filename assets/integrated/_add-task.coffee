###*
 * Add gulp task
###
addTask: (name, glob, task)->
	throw new Error "Default task already created. Task adding expected sync" if @_isRunning
	if name
		Object.defineProperty task, 'name', value: name 
	@_tasks.push task
	@_watch.push glob, task
	this # chain

# Run gulp
run: ->
	Gulp= @_Gulp
	# watch
	watchFx= (cb)=>
		unless @isProd
			watchArr= @_watch
			i=0
			len= watchArr.length
			while i<len
				Gulp.watch watchArr[i++], watchArr[i++]
		cb()
		return
	# Default task
	Gulp.task 'default', Gulp.series Gulp.parallel.apply(Gulp, @_tasks), watchFx
	return