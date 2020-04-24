###*
 * Babel
###
babel: ->
	return Babel
		presets: ['@babel/env']
		# presets: ['babel-preset-env']
		# plugins: [
		# 	['transform-runtime',{
		# 		helpers: no
		# 		polyfill: no
		# 		regenerator: no
		# 	}]
		# 	'transform-async-to-generator'
		# ]
