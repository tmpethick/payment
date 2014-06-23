###
describe 'formatCardNumber', ->
  it 'should format cc number correctly', ->
    number = document.createElement('input')
    payment.formatCardNumber(number)
    number.value = '4242'

    # press '4'
    e = document.createEvent('HTMLEvents');
    e.initEvent("keypress", true, true);
    e.which = 52
    number.dispatchEvent(e);

    assert.equal number.value, '4242 4'

describe 'formatCardExpiry', ->
  it 'should format month shorthand correctly', ->
    expiry = document.createElement('input')
    payment.formatCardExpiry(expiry)

    # press '4'
    e = event('keypress', {keyCode: 52})
    expiry.dispatchEvent(e)

    assert.equal expiry.value, '04 / '

  it 'should format forward slash shorthand correctly', ->
    expiry = document.createElement('input')
    payment.formatCardExpiry(expiry)
    expiry.value = '1'

    # press '/'
    e = event('keypress', {keyCode: 191})
    expiry.dispatchEvent(e)

    assert.equal expiry.value, '01 / '

  it 'should only allow numbers', ->
    expiry = document.createElement('input')
    payment.formatCardExpiry(expiry)
    expiry.value = '1'

    # press 'd'
    e = event('keypress', {keyCode: 68})
    expiry.dispatchEvent(e)

    assert.equal expiry.value, '1'
###
