Validator = {}
Validator.validators = {}
Validator.messages = {}
Validator.messageHandlers = {}

Validator.cfg = 
	ignore: ':hidden'


Validator.validate = (id) ->
	$form = $ '#' + id
	throw 'should be form' unless $form[0].nodeName.toLowerCase() is 'form'

	elements = $form .data "_#{id}_"
	if not elements 
		elements = $form 
			.find 'input, textarea, select'
			.not ':submit, :reset, :image, [disabled]'
			.not @cfg.ignore
		$form .data "_#{id}_", elements

	pass = yes
	for elem in elements
		type = elem.nodeName.toLowerCase()
		$elem = $ elem
		# @validateElement $elem, type
		pass = no if not @validateElement $elem, type
	return pass

Validator.validateElement = (elem, type) ->
	type = 'input' if type is 'textarea'
	pass = Validator[type].call(this, elem)
	return pass

Validator.input = (elem) ->
	pass = yes
	if @checkable elem
		pass = @check elem
	else 
		val = elem.val()
		for rule, validator of @validators when elem.is '['+rule+']' 
			if not (pass = validator.call this, val, elem) 
				@tip rule, elem
				break
	return pass


Validator.select = (elem) ->
	pass = !!elem.val()
	elem.css 'color', 'red' if not pass
	elem.one 'change', ->
		$(this) .css 'color', ''
	return pass

# OPTIMIZE: should be better
Validator.check = (elem) ->
	pass = yes
	name = elem[0].name
	form = elem[0].form
	$group = $(form).find "[name=#{name}]"
	elem0 = $($group[0])
	if elem0.is '[required]'
		checkedCount = $group.filter(':checked').length
		pass = checkedCount > 0

		if not pass then @messageHandlers.check.call this, ' ', elem

	return pass


Validator.tip = (rule, elem) ->
	messageHandler = if rule of @messageHandlers then rule else 'defaults'
	message = if rule of @messages then rule else 'defaults' 
	@messageHandlers[messageHandler].call this, (@messages[message].call this, elem), elem


Validator.isOptional = (val, elem) ->
	it_is_optional = if elem.is '[required]' then @validators.required.call this, val, elem else val.length 	
	return not it_is_optional

Validator.checkable = (elem) ->
	/radio|checkbox/i.test elem.attr('type')


$.extend Validator.validators, {
	required: (val, elem) ->
		!!val

	max: (val, elem) ->
		max = elem.attr 'max'
		@isOptional(val, elem) or val.length <= max
		# val.length <= max unless @isOptional(val, elem)

	min: (val, elem) ->
		min = elem.attr 'min'
		@isOptional(val, elem) or val.length >= min
		# val.length >= min unless @isOptional(val, elem)

	regexp: (val, elem) ->
		reStr = elem.attr 'regexp'
		re = new RegExp reStr
		@isOptional(val, elem) or re.test val
		# re.test val unless @isOptional(val, elem)

	hidden: (val, elem) ->
		!!val
}


$.extend Validator.messageHandlers, {
	defaults: (msg, elem) ->
		elem.css('color', 'red').val(msg).one 'focus', -> 
			$(this) .val('') .css 'color', ''

	hidden: (msg, elem) ->
		console.log "#{elem.attr 'name'} say: i am hidden input but i am required"

	check: (msg, elem) ->
		console.log "#{elem.attr 'name'} say: i am required"

}


$.extend Validator.messages, {
	defaults: (elem) ->
		msg = elem.attr 'data-msg'
		msg ?= '总感觉哪里不对-_-'

	required: (elem) ->
		msg = elem.attr 'data-msg'
		msg ?= '必填'

	min: (elem) ->
		min = elem.attr 'min'
		msg = elem.attr 'data-msg'
		msg ?= "不能小于#{min}个字符"

	max: (elem) ->
		max = elem.attr 'max'
		msg = elem.attr 'data-msg'
		msg ?= "不能大于#{max}个字符"

	regexp: (elem) ->
		msg = elem.attr 'data-msg'
		msg ?= '格式错误'

}

# exports as global object
@Validator or= Validator

# exports as jQuery plupin
$.fn.validate = ->
	id = @attr 'id'
	Validator.validate id
