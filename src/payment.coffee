@payment = payment = {}

# General utils

hasClass = (element, className) ->
  new RegExp(' ' + className + ' ').test(' ' + element.className + ' ');

addClass = (element, className) ->
  if element.classList
    return element.classList.add(className)
  return if hasClass(element, className)
  if element.className
    element.className += " " + className
    return
  element.className = className
  return

toggleClass = (element, className, force) ->
  if element.classList
    return element.classList.toggle(className, force)
  add = if typeof force is "undefined" then !hasClass(element, className) else force
  if add then addClass(element, className) else removeClass(element, className)
  return

removeClass = (element, className) ->
  if element.classList
    return element.classList.remove(className)
  reg = new RegExp("(?:^|\\s+)" + className + "(?!\\S)", "g")
  element.className = element.className.replace(reg, "")
  return

trim = (string) ->
  # Allow integers by converting it first.
  string = '' + string
  if String.prototype.trim
    String.prototype.trim.call(string)
  else
    string.replace(/^\s+|\s+$/g, '')

on_ = (element, eventName, callback) ->
  originalCallback = callback
  callback = (e) ->
    e = normalizeEvent(e)
    originalCallback(e)
  if element.addEventListener
    return element.addEventListener(eventName, callback, false)

  if element.attachEvent
    eventName = "on" + eventName
    return element.attachEvent(eventName, callback)

  element['on' + eventName] = callback
  return

preventDefault = (eventObject) ->
  if typeof eventObject.preventDefault is "function"
    eventObject.preventDefault()
    return
  eventObject.returnValue = false
  false

normalizeEvent = (e) ->
  original = e
  e =
    which: if original.which? then original.which
    # Fallback to srcElement for ie8 support
    target: original.target or original.srcElement
    preventDefault: -> preventDefault(original)
    originalEvent: original
  if not e.which?
    e.which = if original.charCode? then original.charCode else original.keyCode
  return e


# Library specific utils

defaultFormat = /(\d{1,4})/g

cards = [
  {
      type: 'maestro'
      pattern: /^(5018|5020|5038|6304|6759|676[1-3])/
      format: defaultFormat
      length: [12..19]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'dinersclub'
      pattern: /^(36|38|30[0-5])/
      format: defaultFormat
      length: [14]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'laser'
      pattern: /^(6706|6771|6709)/
      format: defaultFormat
      length: [16..19]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'jcb'
      pattern: /^35/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'unionpay'
      pattern: /^62/
      format: defaultFormat
      length: [16..19]
      cvcLength: [3]
      luhn: false
  }
  {
      type: 'discover'
      pattern: /^(6011|65|64[4-9]|622)/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'mastercard'
      pattern: /^5[1-5]/
      format: defaultFormat
      length: [16]
      cvcLength: [3]
      luhn: true
  }
  {
      type: 'amex'
      pattern: /^3[47]/
      format: /(\d{1,4})(\d{1,6})?(\d{1,5})?/
      length: [15]
      cvcLength: [3..4]
      luhn: true
  }
  {
      type: 'visa'
      pattern: /^4/
      format: defaultFormat
      length: [13, 16]
      cvcLength: [3]
      luhn: true
  }
]

cardFromNumber = (num) ->
  num = (num + '').replace(/\D/g, '')
  return card for card in cards when card.pattern.test(num)

cardFromType = (type) ->
  return card for card in cards when card.type is type

luhnCheck = (num) ->
  odd = true
  sum = 0

  digits = (num + '').split('').reverse()

  for digit in digits
    digit = parseInt(digit, 10)
    digit *= 2 if (odd = !odd)
    digit -= 9 if digit > 9
    sum += digit

  sum % 10 == 0

hasTextSelected = (target) ->
  # If some text is selected
  return true if target.selectionStart? and
    target.selectionStart isnt target.selectionEnd

  # If some text is selected in IE
  return true if document?.selection?.createRange?().text

  false

# Private

# Format Card Number

reFormatCardNumber = (e) ->
  setTimeout =>
    target = e.target
    value   = payment.formatCardNumberString(target.value)
    target.value = value

formatCardNumber = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  target = e.target
  value   = target.value
  card    = cardFromNumber(value + digit)
  length  = (value.replace(/\D/g, '') + digit).length

  upperLength = 16
  upperLength = card.length[card.length.length - 1] if card
  return if length >= upperLength

  # Return if focus isn't at the end of the text
  return if target.selectionStart? and
    target.selectionStart isnt value.length

  if card && card.type is 'amex'
    # Amex cards are formatted differently
    re = /^(\d{4}|\d{4}\s\d{6})$/
  else
    re = /(?:^|\s)(\d{4})$/

  # If '4242' + 4
  if re.test(value)
    e.preventDefault()
    target.value = value + ' ' + digit

  # If '424' + 2
  else if re.test(value + digit)
    e.preventDefault()
    target.value = value + digit + ' '

formatBackCardNumber = (e) ->
  target = e.target
  value  = target.value

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if target.selectionStart? and
    target.selectionStart isnt value.length

  # Remove the trailing space
  if /\d\s$/.test(value)
    e.preventDefault()
    target.value = value.replace(/\d\s$/, '')
  else if /\s\d?$/.test(value)
    e.preventDefault()
    target.value = value.replace(/\s\d?$/, '')

# Format Expiry

formatExpiry = (e) ->
  # Only format if input is a number
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  target = e.target
  value  = target.value + digit

  if /^\d$/.test(value) and value not in ['0', '1']
    e.preventDefault()
    target.value = "0#{value} / "

  else if /^\d\d$/.test(value)
    e.preventDefault()
    target.value = "#{value} / "

formatForwardExpiry = (e) ->
  digit = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  target = e.target
  value  = target.value

  if /^\d\d$/.test(value)
    target.value = "#{value} / "

formatForwardSlash = (e) ->
  slash = String.fromCharCode(e.which)
  return unless slash is '/'

  target = e.target
  value  = target.value

  if /^\d$/.test(value) and value isnt '0'
    target.value = "0#{val} / "

formatBackExpiry = (e) ->
  target = e.target
  value  = target.value

  # Return unless backspacing
  return unless e.which is 8

  # Return if focus isn't at the end of the text
  return if target.selectionStart? and
    target.selectionStart isnt value.length

  # Remove the trailing space
  if /\d(\s|\/)+$/.test(value)
    e.preventDefault()
    target.value = value.replace(/\d(\s|\/)*$/, '')
  else if /\s\/\s?\d?$/.test(value)
    e.preventDefault()
    target.value = value.replace(/\s\/\s?\d?$/, '')

#  Restrictions

restrictNumeric = (e) ->

  # Key event is for a browser shortcut
  return true if e.originalEvent.metaKey or e.originalEvent.ctrlKey

  # If keycode is a space
  return e.preventDefault() if e.which is 32

  # If keycode is a special char (WebKit)
  return true if e.which is 0

  # If char is a special char (Firefox)
  return true if e.which < 33

  input = String.fromCharCode(e.which)

  # Char is a number or a space
  return e.preventDefault() if !/[\d\s]/.test(input)

restrictCardNumber = (e) ->
  target = e.target
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected(target)

  # Restrict number of digits
  value = (target.value + digit).replace(/\D/g, '')
  card  = cardFromNumber(value)

  if card
    e.preventDefault() if value.length > card.length[card.length.length - 1]
  else
    # All other cards are 16 digits long
    e.preventDefault() if value.length > 16

restrictExpiry = (e) ->
  target = e.target
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected(target)

  value = target.value + digit
  value = value.replace(/\D/g, '')

  e.preventDefault() if value.length > 6

restrictCVC = (e) ->
  target = e.target
  digit   = String.fromCharCode(e.which)
  return unless /^\d+$/.test(digit)

  return if hasTextSelected(target)

  value = target.value + digit
  e.preventDefault() if value.length > 4

setCardType = (e) ->
  target = e.target
  value    = target.value
  cardType = payment.cardType(value) or 'unknown'

  unless hasClass(target, cardType)
    removeClass(target, 'unknown')
    for card in cards
      removeClass(target, card.type)

    addClass(target, cardType)
    toggleClass(target, 'identified', cardType isnt 'unknown')

# Public

# Formatting

payment.formatCardCVC = (element) ->
  payment.restrictNumeric(element)
  on_(element, 'keypress', restrictCVC)
  element

payment.formatCardExpiry = (element) ->
  payment.restrictNumeric(element)
  on_(element, 'keypress', restrictExpiry)
  on_(element, 'keypress', formatExpiry)
  on_(element, 'keypress', formatForwardSlash)
  on_(element, 'keypress', formatForwardExpiry)
  on_(element, 'keydown',  formatBackExpiry)
  element

payment.formatCardNumber = (element) ->
  payment.restrictNumeric(element)
  on_(element, 'keypress', restrictCardNumber)
  on_(element, 'keypress', formatCardNumber)
  on_(element, 'keydown', formatBackCardNumber)
  on_(element, 'keyup', setCardType)
  on_(element, 'paste', reFormatCardNumber)
  element

# Restrictions

payment.restrictNumeric = (element) ->
  on_(element, 'keypress', restrictNumeric)
  element

# Validations

payment.cardExpiryVal = (value) ->
  value = value.replace(/\s/g, '')
  [month, year] = value.split('/', 2)

  # Allow for year shortcut
  if year?.length is 2 and /^\d+$/.test(year)
    prefix = (new Date).getFullYear()
    prefix = prefix.toString()[0..1]
    year   = prefix + year

  month = parseInt(month, 10)
  year  = parseInt(year, 10)

  month: month, year: year

payment.validateCardNumber = (num) ->
  num = (num + '').replace(/\s+|-/g, '')
  return false unless /^\d+$/.test(num)

  card = cardFromNumber(num)
  return false unless card

  num.length in card.length and
    (card.luhn is false or luhnCheck(num))

payment.validateCardExpiry = (month, year) =>
  # Allow passing an object
  if typeof month is 'object' and 'month' of month
    {month, year} = month

  return false unless month and year

  month = trim(month)
  year  = trim(year)

  return false unless /^\d+$/.test(month)
  return false unless /^\d+$/.test(year)
  return false unless parseInt(month, 10) <= 12

  if year.length is 2
    prefix = (new Date).getFullYear()
    prefix = prefix.toString()[0..1]
    year   = prefix + year

  expiry      = new Date(year, month)
  currentTime = new Date

  # Months start from 0 in JavaScript
  expiry.setMonth(expiry.getMonth() - 1)

  # The cc expires at the end of the month,
  # so we need to make the expiry the first day
  # of the month after
  expiry.setMonth(expiry.getMonth() + 1, 1)

  expiry > currentTime

payment.validateCardCVC = (cvc, type) ->
  cvc = trim(cvc)
  return false unless /^\d+$/.test(cvc)

  if type
    # Check against a explicit card type
    cvc.length in cardFromType(type)?.cvcLength
  else
    # Check against all types
    cvc.length >= 3 and cvc.length <= 4

payment.cardType = (num) ->
  return null unless num
  cardFromNumber(num)?.type or null

payment.formatCardNumberString = (num) ->
  card = cardFromNumber(num)
  return num unless card

  upperLength = card.length[card.length.length - 1]

  num = num.replace(/\D/g, '')
  num = num[0..upperLength]

  if card.format.global
    num.match(card.format)?.join(' ')
  else
    groups = card.format.exec(num)
    groups?.shift()
    groups?.join(' ')
