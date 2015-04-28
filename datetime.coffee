
# pad a number with a zero
pad = (n) ->
  n = parseInt n, 10
  if n < 10 then "0#{n}" else "#{n}"

# setup intervals of 15 for minutes and seconds
intervals = [0, 15, 30, 45]

# enums for dropdowns
ENUM = {
  year: (pad year for year in [2020..1900])
  month: [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ]
  day: (pad day for day in [1..31])
  hour: (pad hour for hour in [0..23])
  minute: (pad minute for minute in intervals)
  second: (pad second for second in intervals)
  timezone: (v for k, v of TIMEZONE_ABBR_MAP)
}

# regexes for input parsing
DATE = '(\\w{3})\\s(\\d{1,2})\\s(\\d{4})'
TIME = '(\\d{2}):(\\d{2}):(\\d{2})'
TIMEZONE = '(GMT[\\+\\-]\\d{4}\\s\\([A-Z]*\\))'

REGEX = {
  datetime: new RegExp "^#{DATE}\\s#{TIME}\\s#{TIMEZONE}$"
  date: new RegExp "^#{DATE}$"
  time: new RegExp "^#{TIME}$"
}

# get the current time. used if input is invalid
now = (type) ->
  d = new Date().toString()
  return {
    datetime: d.substring 4
    date: d.substring 4, 15
    time: d.substring 16, 24
  }[type]

# input parsing
parse = (type, val) ->
  re = REGEX[type]
  matches = val.match(re) or now(type).match(re)
  switch type
    when 'datetime'
      [val, month, day, year, hour, minute, second, timezone] = matches
    when 'date'
      [val, month, day, year] = matches
    when 'time'
      [val, hour, minute, second] = matches
  {val, year, month, day, hour, minute, second, timezone}

# output formatting
format = (type, val) ->
  {month, day, year, hour, minute, second, timezone} = val
  switch type
    when 'datetime'
      "#{month} #{day} #{year} #{pad hour}:#{pad minute}:00 #{timezone}"
    when 'date'
      "#{month} #{day} #{year}"
    when 'time'
      "#{pad hour}:#{pad minute}:#{pad second}"

# render modal
render = ($input, type, options) ->

  # parse input
  values = parse type, $input.val()
  $input.val values.val

  # disable keyboard entry from $input
  $input.bind 'keydown', (e) ->
    e.preventDefault()

  # render modal
  $modal = $ teacup.render ( ->
    groups = {
      date: ['month', 'day', 'year']
      time: ['hour', 'minute', 'second', 'timezone']
    }
    div '.jquery-datetime', data: {type: type}, ->
      div '.overlay'
      div '.wrapper.animated.fadeIn', ->
        for group, units of groups
          div ".#{group}", ->
            for unit in units
              div '.unit', data: {unit: unit}, ->
                label -> unit
                select ->
                  for v in ENUM[unit]
                    selected = v in [values[unit], parseInt(values[unit], 10)]
                    option value: v, selected: selected, -> v
        div '.preview-wrapper', ->
          div '.preview', ->
          div '.clear', ->
            span -> 'Clear'
  )

  # append modal to dom directly beneath the input
  $input.after $modal

  # shortcut dom elements
  $overlay = $modal.find '.overlay'
  $wrapper = $modal.find '.wrapper'
  $preview = $modal.find '.preview'

  # init preview value
  $preview.text $input.val()

  # update value
  update = ->
    v = {}
    for unit of ENUM
      v[unit] = $wrapper.find("[data-unit=#{unit}] select").val()
    val = format type, v
    $preview.text val
    $input.val val
    $input.keyup()
    options.on?.change?($modal)

  # listen for updates
  $wrapper.find('select').on 'change', ->
    update()

  # remove value on click clear
  $wrapper.find('.clear').on 'click', ->
    $input.val ''
    $input.attr 'value', ''
    $input.keyup()

  # close on click overlay
  $overlay.on 'click', ->
    options.on?.close?($modal)
    $modal.remove()

  # bubble scrolling events on the overlay to the first scrolling parent
  $overlay.on 'mousewheel', (e) ->
    e = e.originalEvent
    $parent = $modal.scrollParent()
    top = (e.wheelDelta * -1) + $parent.scrollTop()
    $parent.scrollTop top

  # close on click preview
  $preview.on 'click', ->
    options.on?.close?($modal)
    $modal.remove()

  # notify caller
  options.on?.open?($modal)

# add jquery plugins
types = ['datetime', 'date', 'time']
((type) ->
  $.fn[type] = (options = {}) ->
    this.each (i) ->
      $(this).on 'click', ->
        render $(this), type, options
)(type) for type in types
