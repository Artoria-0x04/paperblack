{$, $$, _, React, ReactBootstrap} = window
{ProgressBar, OverlayTrigger, Tooltip} = ReactBootstrap

getCondStyle = (cond) ->
  if cond > 84
    '#FFE924'
  else if cond > 49
    '#FFCF00'
  else if cond < 20
    '#DD514C'
  else if cond < 30
    '#F37B1D'
  else if cond < 40
    '#FFC880'
  else
    '#FFF'

CondBar = React.createClass
  getInitialState: ->
    cond: @props.cond
  componentDidMount: ->
    for shipId, j in @props.deck.api_ship
      continue if shipId == -1
      $("#ShipView #condProgress-#{@props.deckIndex}-#{j}.progress-bar").style.backgroundColor = getCondStyle @props.cond[j]
  componentDidUpdate: (prevProps, prevState) ->
    for shipId, j in @props.deck.api_ship
      continue if shipId == -1
      $("#ShipView #condProgress-#{@props.deckIndex}-#{j}.progress-bar").style.backgroundColor = getCondStyle @props.cond[j]
  render: ->
    <span className="condBar" style={display: "flex"}>
      <span className="condText" >{@props.cond[@props.j]}</span>
      <OverlayTrigger placement='right' overlay={<Tooltip>Cond. {@props.cond[@props.j]}</Tooltip>} >
        <ProgressBar key={2} className="condProgress" id="condProgress-#{@props.deckIndex}-#{@props.j}" now={@props.cond[@props.j]} />
      </OverlayTrigger>
    </span>

module.exports = CondBar
