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
				code = line = col = '?'
			# ...
			# Render
			table = new CliTable()
			table.push {Plugin: err.plugin || '-'},
				{Name: err.name || '?'},
				{Filename: err.filename || err.fileName || err.path || ''},
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
		