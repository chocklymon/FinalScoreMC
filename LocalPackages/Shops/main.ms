####################
# SIGN CHEST SHOPS #
####################

# CLICKING SIGNS!
bind(player_interact, null, array('block': 68), @event,
assign(@signtext, get_sign_text(@event['location']))
if(length(@signtext[0]) > 2 && @signtext[0][0] == '['
&& (length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy'
|| length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell')) {
  set_timeout(100, closure(
  assign(@itemid, _shop_item(@signtext[0]))
  assign(@shops, get_value('shops.'.@itemid))
  if(@shops == null, @shops = array(array(), array()))
  if(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy') {
    assign(@count, _get_inventory_count(array(@event['location'][0], @event['location'][1] - 1, @event['location'][2], @event['location'][3]), reg_replace('\\.', ':', @itemid)))
    # debug #
    if(!is_array(@shops[0]), console('This shop list is not an array: '.@shops))
    foreachelse(array_keys(@shops[0]), @i,
      if(@shops[0][@i]['location'] == @event['location']) {
        if(@count < parse_args(@signtext[1])[1]) {
          array_remove(@shops[0], @i)
        } else {
          array_set(@shops[0], @i, array('location': @event['location'], 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count))
        }
        break()
      }
      if(@i == (length(@shops[0]) - 1)) {
        if(@count >= parse_args(@signtext[1])[1]) {
          array_push(@shops[0], array('location': @event['location'], 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count))
        }
      }
    , #else
      if(@count >= parse_args(@signtext[1])[1]) {
        @shops[0] = array(array('location': @event['location'], 'price': substr(@signtext[1], 4), 'owner': @signtext[3], 'stock': @count))
      }
    )
  }

  if(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell') {
    switch(substr(@signtext[2], length(@signtext[2]) - 1)
    , 'g',
      @currency = '266'
    , 'i',
      @currency = '265'
    , 'd',
      @currency = '264'
    , 'e',
      @currency = '388'
    , die()
    )
    assign(@count, _get_inventory_count(array(@event['location'][0], @event['location'][1] - 1, @event['location'][2], @event['location'][3]), @currency.':0'))
    @cost = parse_args(@signtext[2])[3]
    try(
    foreachelse(array_keys(@shops[1]), @i,
      if(@shops[1][@i]['location'] == @event['location']) {
        if(@count < substr(@cost, 0, length(@cost) - 1)) {
          array_remove(@shops[1], @i)
        } else {
          array_set(@shops[1], @i, array('location': @event['location'], 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count))
        }
          break()
      }
      if(@i == (length(@shops[1]) - 1)) {
        if(@count >= substr(@cost, 0, length(@cost) - 1)) {
          array_push(@shops[1], array('location': @event['location'], 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count))
        }
      }
    , #else
      if(@count >= substr(@cost, 0, length(@cost) - 1)) {
        @shops[1] = array(array('location': @event['location'], 'price': substr(@signtext[2], 5), 'owner': @signtext[3], 'stock': @count))
      }
    )
    , #catch
    console('Shop debug: '.@shops)
    )
  }

  if(@shops == array(array(), array())) {
    clear_value('shops.'.@itemid)
  } else {
    store_value('shops.'.@itemid, @shops)
  }

  ))
}
)

# Breaking signs
bind(block_break, null, array('type': 68), @event,
  assign(@location, array(@event['block']['X'], @event['block']['Y'], @event['block']['Z'], @event['block']['world']))
  assign(@signtext, get_sign_text(@location))
  if(length(@signtext[0]) < 3 || @signtext[0][0] != '[', die())
  if(!(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy')
  && !(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell'), die())
  assign(@itemid, _shop_item(@signtext[0]))
  assign(@shops, get_value('shops.'.@itemid))
  if(!@shops, die())
  if(length(@signtext[1]) > 7 && substr(@signtext[1], 0, 3) == 'Buy') {
    if(@shops[0] != array()) {
      for(assign(@i, 0), @i < length(@shops[0]), @i++,
        if(@shops[0][@i]['location'] == @location && (@shops[0][@i]['owner'] == player() || has_permission('group.moderators'))) {
          array_remove(@shops[0], @i)
          break()
        }
      )
    }
  }
  if(length(@signtext[2]) > 8 && substr(@signtext[2], 0, 4) == 'Sell') {
    if(@shops[1] != array()) {
      for(assign(@i, 0), @i < length(@shops[1]), @i++,
        if(@shops[1][@i]['location'] == @location && (@shops[1][@i]['owner'] == player() || has_permission('group.moderators'))) {
          array_remove(@shops[1], @i)
          break()
        }
      )
    }
  }
  if(@shops == array(array(), array())) {
    clear_value('shops.'.@itemid)
  } else {
    store_value('shops.'.@itemid, @shops)
  }
)