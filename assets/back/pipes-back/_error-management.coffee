###*
 * Error console
###
onError: ->
	GulpPlumber (err)->
		try
			# get error line
			if err.stack and expr= /:(\d+):(\d+):/.exec err.stack
				line = parseInt expr[1]
				col = parseInt expr[2]
				code = err.code?.split("\n")[line-3 ... line + 3].join("\n")
			else
				code= '?'
				line= err.Line or err.line or '?'
				col= err.Column or err.col or '?'
				col+= ':' + err.pos if err.pos
			# ...
			# Render
			table = new CliTable()
			table.push {Plugin: err.plugin || '-'},
				{Name: err.name || '?'},
				{Filename: err.fileName || err.filename || err.path || ''},
				{Message: err.message|| ''},
				{Line: line},
				{Col: col}
			console.log """Error: ════════════════════════════════════════════════════════════════════════════════════════════════════╗
				#{Chalk.red table.toString()}
				Stack:
				┌─────────────────────────────────────────────────────────────────────────────────────────┐
				#{err.stack or '?'}
				└─────────────────────────────────────────────────────────────────────────────────────────┘
				Code:
				┌─────────────────────────────────────────────────────────────────────────────────────────┐
				#{code}
				└─────────────────────────────────────────────────────────────────────────────────────────┘
				"""
		catch e
			console.log Chalk.red e
		return
		