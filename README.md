# gulp-gridfw
Gridfw plugin for gulp



## Compile i18n files

### Features
* Translate literals
* Pluralize literals
* Switch value depending on some value
* Text combining
* Compatible with Gridfw and Grid-Reactor

### USE
```javascript
// If the message doesn't contain arguments, just call it as follow
i18n.myMessage

// If the message contains arguments, call it as a function like this:
i18n.messageWithArguments({param1:'value', param2:'value', ...})


// SERVER SIDE:
// For performance issues, we recommand to keep "i18n" as named.
app.get('/route', function(ctx){
	console.log('My message: ', ctx.i18n.myMessage);
	console.log('Message with arguments: ', ctx.i18n['i bought %books']({books: ['book1', 'book2']}) );
});

// INSIDE VIEWS:
// Just use: i18n.yourMessageKey
// or: i18n.yourMessageKeyWithArgs(args)


// BROWSER SIDE: (you can change "i18n" by any other variable in the browser side)
// call: i18n.yourMessage
// or: i18n.yourMessageKeyWithArgs(args)


// Get a specific local
app.get('/route', async function(ctx){
	enI18n= await app.getLocale('en');
	console.log('My message in user language: ', ctx.i18n.myMessage);
	console.log('My message in EN: ', enI18n.myMessage);
});

```

### Format
Each i18n file has the following format:
```coffeescript
###*
 * Map a key to a value for all locales
 */
key: 'value'

###*
 * Map a value for each locale
 */
key2:
	locale_1: 'value in locale_1'
	locale_2: 'value in locale_2'
	locale_n: 'value in locale_n'

###*
 * Parametred value
 * You can use any valid Pug format to add variables or any javascript expression
 * use: #{varname} to insert varname after escaping it's value
 * use: !{varname} to insert varname without escaping it
 * use: #[b kkk] to add: <b>kkk</b>
 * use: #[b #{varname}] to add: <b>content</b>
 *
 * <!> warn: use simple quoted string only, using double quoted will result an error.
 */
key3:
	locale_1: 'lorem #{param1} !{enescaped_param2}'
key4:
	locale_1: 'my name is #[b #{fullName}]'

###*
 * Insert an other messages from i18n
 */
key5:
	locale_1: 'This is my message: #{i18n.mySecondMessage}'
key6:
	locale_1: 'This is my message: #{i18n.mySecondMessage2({name: name, age:31})}'

###*
 * Do more controle using functions
 */
key5:
	# Using coffeescript style
	locale_1: (data)-> 'generated message'

	# Using javascript style
	locale_2: ```function(data){
		return 'generated message'
	}```

```

### Examples
```coffeescript

appName: 'My App' # used for all locales

'hello everybody':
	en: 'Hello everybody'
	fr: 'Bonjour tout le monde'

'hello %fullName':
	en: 'Hello #{fullName}'
	fr: 'Bonjour #{fullName}'

'i bought %books':
	en: (data)->
		switch data.books.length
			when 0 then 'I bought no book'
			when 1 then 'I bought a book'
			when 2 then 'I bought two books'
			else "I bought #{data.books.length} books"

```

### Reserved attributes
i18n.locale: Contain current locale
i18n.locales: map local and it's name

