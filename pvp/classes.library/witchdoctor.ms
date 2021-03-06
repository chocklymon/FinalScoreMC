switch(@action) {
case 'load':
	bind('player_interact', array('id': @player.'blind'), array('player': @player, 'item': 290, 'button': 'right'), @e, @pvp) {
		@pvp = import('pvp'.@id)
		@item = pinv(player(), null)
		if(@item['data'] > 0, die())
		foreach(@player in players_in_radius(ploc(), 18)) {
			if(@player != player()
			&& array_index_exists(@pvp['players'], @player)) {
				set_peffect(@player, 15, 0, 7)
			}
		}
		play_sound(ploc(), array('sound': 'HORSE_SKELETON_DEATH', 'pitch': 0.5, 'volume': 2))
		set_pinv(player(), array(null: array('type': 290, 'data': 59)))
		@slot = pinfo(player(), 15)
		set_interval(1000, closure(){
			@item = pinv(player(), @slot)
			if(!is_null(@item) && @item['type'] == 290 && @item['data'] > 0) {
				@inv = array()
				@item['data'] -= 3
				@inv[@slot] = @item
				set_pinv(player(), @inv)
			} else {
				clear_task()
			}
		})
	}

case 'unload':
	unbind(@player.'blind')

}