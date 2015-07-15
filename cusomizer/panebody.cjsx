{relative, join} = require 'path-extra'
{$, $$, _, React, ReactBootstrap, resolveTime, notify} = window
{Table, ProgressBar, OverlayTrigger, Tooltip, Grid, Col, Alert, Row} = ReactBootstrap

Slotitems = require './slotitems'


getMaterialStyle = (percent) ->
  if percent <= 50
    'danger'
  else if percent <= 75
    'warning'
  else if percent < 100
    'primary'
  else
    'success'

getCondStyle = (cond) ->
  if cond > 49
    '#ffd600'
  else if cond < 20
    '#DD514C'
  else if cond < 30
    '#F37B1D'
  else if cond < 40
    '#FFC880'
  else
    '#FFF'


getFontStyle = (theme)  ->
  if window.isDarkTheme then color: '#FFF' else color: '#000'

getCondCountdown = (deck) ->
  {$ships, $slotitems, _ships} = window
  countdown = [0, 0, 0, 0, 0, 0]
  cond = [49, 49, 49, 49, 49, 49]
  for shipId, i in deck.api_ship
    if shipId == -1
      countdown[i] = 0
      cond[i] = 49
      continue
    ship = _ships[shipId]
    # if ship.api_cond < 49
    #   cond[i] = Math.min(cond[i], ship.api_cond)
    cond[i] = ship.api_cond
    countdown[i] = Math.max(countdown[i], Math.ceil((49 - cond[i]) / 3) * 180)
  ret =
    countdown: countdown
    cond: cond

getHpStyle = (percent) ->
  if percent <= 25
    'danger'
  else if percent <= 50
    'warning'
  else if percent <= 75
    'primary'
  else
    'success'

getMaterialStyleData = (percent) ->
  if percent <= 20
    color: '#F37B1D'
  else if percent <= 40
    color: '#DD514C'
  else if percent < 100
    color: '#FFFF00'
  else
    null


getDeckMessage = (deck) ->
  {$ships, $slotitems, _ships} = window
  totalLv = totalShip = totalTyku = totalSaku = shipSaku = itemSaku = teitokuSaku = 0
  for shipId in deck.api_ship
    continue if shipId == -1
    ship = _ships[shipId]
    shipInfo = $ships[ship.api_ship_id]
    totalLv += ship.api_lv
    totalShip += 1
    shipPureSaku = ship.api_sakuteki[0]
    for itemId, slotId in ship.api_slot
      continue if itemId == -1
      item = _slotitems[itemId]
      itemInfo = $slotitems[item.api_slotitem_id]
      # Airplane Tyku
      if itemInfo.api_type[3] in [6, 7, 8]
        totalTyku += Math.floor(Math.sqrt(ship.api_onslot[slotId]) * itemInfo.api_tyku)
      else if itemInfo.api_type[3] == 10 && itemInfo.api_type[2] == 11
        totalTyku += Math.floor(Math.sqrt(ship.api_onslot[slotId]) * itemInfo.api_tyku)
      # Saku
      # 索敵スコア = 艦上爆撃機 × (1.04) + 艦上攻撃機 × (1.37) + 艦上偵察機 × (1.66) + 水上偵察機 × (2.00)
      #            + 水上爆撃機 × (1.78) + 小型電探 × (1.00) + 大型電探 × (0.99) + 探照灯 × (0.91)
      #            + √(各艦毎の素索敵) × (1.69) + (司令部レベルを5の倍数に切り上げ) × (-0.61)
      shipPureSaku -= itemInfo.api_saku
      switch itemInfo.api_type[3]
        when 7
          itemSaku += itemInfo.api_saku * 1.04
        when 8
          itemSaku += itemInfo.api_saku * 1.37
        when 9
          itemSaku += itemInfo.api_saku * 1.66
        when 10
          if itemInfo.api_type[2] == 10
            itemSaku += itemInfo.api_saku * 2.00
          else if itemInfo.api_type[2] == 11
            itemSaku += itemInfo.api_saku * 1.78
        when 11
          if itemInfo.api_type[2] == 12
            itemSaku += itemInfo.api_saku * 1.00
          else if itemInfo.api_type[2] == 13
            itemSaku += itemInfo.api_saku * 0.99
        when 24
          itemSaku += itemInfo.api_saku * 0.91
    shipSaku += Math.sqrt(shipPureSaku) * 1.69
  teitokuSaku = 0.61 * Math.floor((window._teitokuLv + 4) / 5) * 5
  totalSaku = shipSaku + itemSaku - teitokuSaku
  avgLv = totalLv / totalShip
  [totalLv, parseFloat(avgLv.toFixed(0)), totalTyku, parseFloat(totalSaku.toFixed(0)), parseFloat(shipSaku.toFixed(2)), parseFloat(itemSaku.toFixed(2)), parseFloat(teitokuSaku.toFixed(2))]

TopAlert = React.createClass
  messages: ['没有舰队信息']
  countdown: [0, 0, 0, 0, 0, 0]
  maxCountdown: 0
  timeDelta: 0
  cond: [0, 0, 0, 0, 0, 0]
  isMount: false
  inBattle: false
  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    refreshFlag = false
    switch path
      when '/kcsapi/api_port/port'
        @inBattle = false
        refreshFlag = true
      when '/kcsapi/api_req_map/start'
        @inBattle = true
      when '/kcsapi/api_get_member/deck', '/kcsapi/api_get_member/ship_deck', '/kcsapi/api_get_member/ship2', '/kcsapi/api_get_member/ship3'
        refreshFlag = true
      when '/kcsapi/api_req_hensei/change', '/kcsapi/api_req_kaisou/powerup', '/kcsapi/api_req_kousyou/destroyship'
        refreshFlag = true
    if refreshFlag
      @setAlert()
  setAlert: ->
    decks = window._decks
    @messages = getDeckMessage decks[@props.deckIndex]
    tmp = getCondCountdown decks[@props.deckIndex]
    @maxCountdown = tmp.countdown.reduce (a, b) -> Math.max a, b    # new countdown
    @countdown = tmp.countdown
    minCond = tmp.cond.reduce (a, b) -> Math.min a, b               # new cond
    thisMinCond = @cond.reduce (a, b) -> Math.min a, b              # current cond
    if thisMinCond isnt minCond
      @timeDelta = 0
    @cond = tmp.cond
    if @maxCountdown > 0
      @interval = setInterval @updateCountdown, 1000 if !@interval?
    else
      if @interval?
        @interval = clearInterval @interval
        @clearCountdown()
  componentWillUpdate: ->
    @setAlert()
  updateCountdown: ->
    flag = true
    if @maxCountdown - @timeDelta > 0
      flag = false
      @timeDelta += 1
      # Use DOM operation instead of React for performance
      if @isMount
        $("#ShipView #deck-condition-countdown-#{@props.deckIndex}-#{@componentId}").innerHTML = resolveTime(@maxCountdown - @timeDelta)
      if @timeDelta % (3 * 60) == 0
        cond = @cond.map (c) => if c < 49 then Math.min(49, c + @timeDelta / 60) else c
        @props.updateCond(cond)
      if @maxCountdown is @timeDelta and not @inBattle and window._decks[@props.deckIndex].api_mission[0] <= 0
        notify "#{@props.deckName} 疲劳回复完成", {icon: join(ROOT, 'assets', 'img', 'operation', 'sortie.png')}
    if flag or @inBattle
      @interval = clearInterval @interval
      @clearCountdown()
  clearCountdown: ->
    if @isMount
      $("#ShipView #deck-condition-countdown-#{@props.deckIndex}-#{@componentId}").innerHTML = resolveTime(0)
  componentWillMount: ->
    @componentId = Math.ceil(Date.now() * Math.random())
    @setAlert()
  componentDidMount: ->
    @isMount = true
    window.addEventListener 'game.response', @handleResponse
  componentWillUnmount: ->
    window.removeEventListener 'game.response', @handleResponse
    @interval = clearInterval @interval if @interval?
  render: ->
    <Alert style={getFontStyle window.theme}>
      <div style={display:"flex"}>
        <span style={flex:1}>总 Lv.{@messages[0]}</span>
        <span style={flex:1}>均 Lv.{@messages[1]}</span>
        <span style={flex:1}>制空:&nbsp;{@messages[2]}</span>
        <span style={flex:1}>
          <OverlayTrigger placement='bottom' overlay={<Tooltip>[艦娘]{@messages[4]} + [装備]{@messages[5]} - [司令部]{@messages[6]}</Tooltip>}>
            <span>索敌:&nbsp;{@messages[3]}</span>
          </OverlayTrigger>
        </span>
        <span style={flex:1.5}>回复:&nbsp;<span id={"deck-condition-countdown-#{@props.deckIndex}-#{@componentId}"}>{resolveTime @maxCountdown}</span></span>
      </div>
    </Alert>

PaneBody = React.createClass
  condDynamicUpdateFlag: false
  getInitialState: ->
    cond: [0, 0, 0, 0, 0, 0]
  onCondChange: (cond) ->
    condDynamicUpdateFlag = true
    @setState
      cond: cond
  shouldComponentUpdate: (nextProps, nextState) ->
    nextProps.activeDeck is @props.deckIndex
  componentWillReceiveProps: (nextProps) ->
    if @condDynamicUpdateFlag
      @condDynamicUpdateFlag = not @condDynamicUpdateFlag
    else
      cond = [0, 0, 0, 0, 0, 0]
      for shipId, j in nextProps.deck.api_ship
        if shipId == -1
          cond[j] = 49
          continue
        ship = _ships[shipId]
        cond[j] = ship.api_cond
      @setState
        cond: cond
  componentWillMount: ->
    cond = [0, 0, 0, 0, 0, 0]
    for shipId, j in @props.deck.api_ship
      if shipId == -1
        cond[j] = 49
        continue
      ship = _ships[shipId]
      cond[j] = ship.api_cond
    @setState
      cond: cond
  render: ->
    <div>
      <TopAlert
        updateCond={@onCondChange}
        messages={@props.messages}
        deckIndex={@props.deckIndex}
        deckName={@props.deckName} />
      <div className="shipDetails">
      {
        {$ships, $shipTypes, _ships} = window
        for shipId, j in @props.deck.api_ship
          continue if shipId == -1
          ship = _ships[shipId]
          shipInfo = $ships[ship.api_ship_id]
          shipType = $shipTypes[shipInfo.api_stype].api_name
          [
            <div className="shipItem">
              <div className="shipInfo">
                <div style={display: "flex", flexDirection: "column"}>
                  <div className="shipBasic">
                    <span className="shipLv">
                      Lv. {ship.api_lv}
                    </span>
                    <span className='shipType'>
                      {shipType}
                    </span>
                  </div>
                  <div className="shipName">
                    {shipInfo.api_name}
                  </div>
                  <OverlayTrigger placement='right' overlay={<Tooltip>Next. {ship.api_exp[1]}</Tooltip>}>
                    <div className="expProgress">
                      <ProgressBar bsStyle="info" now={ship.api_exp[2]} />
                    </div>
                  </OverlayTrigger>
                </div>
              </div>
              <div className="shipCond">
                <span>{@state.cond[j]}</span>
                <OverlayTrigger placement='right' overlay={<Tooltip>Cond. {@state.cond[j]}</Tooltip>}>
                  <span className="condIndicator" style={backgroundColor:getCondStyle @state.cond[j]} />
                </OverlayTrigger>
              </div>
              <div className="shipHp" >
                <div style={flex: 1, display: "flex"}>
                  <span style={flex: 2}>{ship.api_nowhp} / {ship.api_maxhp}</span>
                </div>
                <ProgressBar style={flex: 1} bsStyle={getHpStyle ship.api_nowhp / ship.api_maxhp * 100}
                           now={ship.api_nowhp / ship.api_maxhp * 100} />
              </div>
              <span className="shipFB" >
                <span style={flex: 1}>
                  <ProgressBar bsStyle={getMaterialStyle ship.api_fuel / shipInfo.api_fuel_max * 100}
                               now={ship.api_fuel / shipInfo.api_fuel_max * 100} />
                </span>
                <span style={flex: 1}>
                  <ProgressBar bsStyle={getMaterialStyle ship.api_bull / shipInfo.api_bull_max * 100}
                               now={ship.api_bull / shipInfo.api_bull_max * 100} />
                </span>
              </span>
              <div className="shipSlot" >
                <Slotitems data={ship.api_slot} onslot={ship.api_onslot} maxeq={ship.api_maxeq} />
              </div>
            </div>
          ]
      }
      </div>
    </div>

module.exports = PaneBody
