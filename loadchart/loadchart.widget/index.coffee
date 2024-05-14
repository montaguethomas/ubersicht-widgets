# name: Load Chart
# source: https://github.com/montaguethomas/ubersicht-widgets/tree/master/loadchart

# Vars needed for style rendering
refreshFrequency = 5000 # milliseconds
colors =
  low      : "rgb(60, 160, 189)"
  normal   : "rgb(88, 189, 60)"
  high     : "rgb(243, 255, 134)"
  important: "rgb(255, 168, 80)"
  urgent   : "rgb(255, 71, 71)"

settings:
  background: true
  color     : true
  brighter  : false
  inverse   : false
  bars      : 60
  animations:
    bars: false
    period: true

command: "sysctl -n hw.physicalcpu && sysctl -n vm.loadavg|awk '{print $2}'"

refreshFrequency: refreshFrequency # milliseconds

style: """
  top 10px
  left 10px
  min-width 320px
  height 90px
  line-height: @height
  border-radius 5px

  h1
    font-size 100px
    font-weight 700
    text-align center
    margin 0
    line-height 1
    font-family Avenir
    color rgba(255,255,255,.35)
    transition all 1s ease-in-out

  i
    display inline-block
    text-shadow none
    font-style normal
    animation-direction alternate
    animation-timing-function ease-out

  b
    font-size 36px

  &.bg
    background rgba(0,0,0,.5)

  &.inverse
    &.bg
      background rgba(255,255,255,.5)
    .bar
      border-left 3px solid rgb(0,0,0)
    h1
      color rgba(0,0,0,.35)

  #chartcontainer
    position absolute
    bottom 0
    left 10px
    height 100%
    font-size 0
    transform-origin 50% 100%
    overflow hidden

  .bar
    color rgba(255,255,255,.65)
    display inline-block
    vertical-align bottom
    border-left 3px solid rgb(255,255,255)
    width 2px
    padding 0
    height 1px
    transform-origin 50% 100%
    opacity .4

  &.brighter .bar
    opacity 1

  &.animated-bars
    .bar
      -webkit-backface-visibility hidden;
      -webkit-perspective 1000;
      -webkit-transform translate3d(0, 0, 0);
      transition all 500ms linear
  &.animated-period
    i.low
      animation pulseOpacity #{refreshFrequency / 1}ms infinite
    i.normal
      animation pulseOpacity #{refreshFrequency / 2}ms infinite
    i.high
      animation pulseOpacity #{refreshFrequency / 3}ms infinite
    i.important
      animation pulse #{refreshFrequency / 5}ms infinite
    i.urgent
      animation pulse #{refreshFrequency / 8}ms infinite

  color-low = #{colors.low}
  color-normal = #{colors.normal}
  color-high = #{colors.high}
  color-important = #{colors.important}
  color-urgent = #{colors.urgent}

  &.color
    .low
      color color-low
      border-left-color color-low
    .normal
      color color-normal
      border-left-color color-normal
    .high
      color color-high
      border-left-color color-high
    .important
      color color-important
      border-left-color color-important
    .urgent
      color color-urgent
      border-left-color color-urgent
"""

render: (output) -> """
  <style>
    @-webkit-keyframes pulse
    {
      0% {-webkit-transform: scale(1); opacity: .8;}
      50% {-webkit-transform: scale(1.2) translateY(-4px); opacity: .6;}
      100% {-webkit-transform: scale(1); opacity: .8;}
    }
    @-webkit-keyframes pulseSmall
    {
      0% {-webkit-transform: scale(1); opacity: .8;}
      50% {-webkit-transform: scale(1.1) translateY(-4px); opacity: .6;}
      100% {-webkit-transform: scale(1); opacity: .8;}
    }
    @-webkit-keyframes pulseOpacity
    {
      0% {opacity: .9;}
      50% {opacity: .4;}
      100% {opacity: .9;}
    }
  </style>
  <h1></h1>
  <div id="chartcontainer"></div>
"""

afterRender: (domEl) ->
  el = $(domEl)
  @$chart = $(domEl).find('#chartcontainer')
  @chartHeight = @$chart.height() - 10 # leave some padding at the top

  el.addClass('bg')       if @settings.background
  el.addClass('animated-bars') if @settings.animations.bars
  el.addClass('animated-period') if @settings.animations.period
  el.addClass('color')    if @settings.color
  el.addClass('brighter') if @settings.brighter
  el.addClass('inverse')  if @settings.inverse

  el.css width: @settings.bars * 5 + 20

  # preload bars
  while @loads.length isnt @settings.bars
    @loads.push(0.00)
    @$chart.append ($bar = $('<div class="bar">')).addClass @colorClass(0.00)

update: (output, domEl) ->
  # parse output
  lines    = output.split("\n")
  @numcores = lines[0]
  load     = lines[1]

  # figure out new max load
  max = Math.max.apply(Math, @loads)
  max = Math.max load, max

  $stat = $(domEl).find('h1')
  $stat.removeClass('highest higher high normal low')
  $stat.html(load.replace(/\./, '<i>.</i>'))

  if @settings.animations.period
    $stat.find('i').addClass @colorClass(load)

  # resize all bars if necessary
  bars = @$chart.children()
  if max != @prevMax
    @setBarHeight(bar, @loads[i], max) for bar, i in bars
    @prevMax = max

  # store current load
  @loads.push load

  # create new bar
  ($bar = $('<div class="bar">')).addClass @colorClass(load)

  # remove old bars and loads
  if bars.length >= @settings.bars
    @loads.shift()
    $(bars[0]).remove()

  # render
  @$chart.append $bar
  requestAnimationFrame =>
    @setBarHeight($bar[0], load, max)

colorClass: (load) ->
  switch
    when load >= (@numcores * 2.0) then 'urgent'
    when load >= (@numcores * 1.5) then 'important'
    when load >= (@numcores * 1.0) then 'high'
    when load >= (@numcores * 0.5) then 'normal'
    else 'low'

setBarHeight: (bar, load, max) ->
  bar.style.webkitTransform = "scale(1, #{@chartHeight * load / max})"

loads: []
numcores: 0
prevMax: null
