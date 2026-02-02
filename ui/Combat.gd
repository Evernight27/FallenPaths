extends CanvasLayer

signal battle_ended(winner: String)

var enemy_name_label: Label = null
var enemy_health_bar: ProgressBar = null
var enemy_speed_bar: ProgressBar = null

var player_name_label: Label = null
var player_health_bar: ProgressBar = null
var player_speed_bar: ProgressBar = null

func _ready() -> void:
	# Safely acquire UI nodes (use get_node_or_null to avoid errors if structure changes)
	enemy_name_label = get_node_or_null("Panel/EnemyVBox/EnemyName") as Label
	enemy_health_bar = get_node_or_null("Panel/EnemyVBox/EnemyHealth") as ProgressBar
	enemy_speed_bar = get_node_or_null("Panel/EnemyVBox/EnemySpeed") as ProgressBar

	player_name_label = get_node_or_null("Panel/PlayerVBox/PlayerName") as Label
	player_health_bar = get_node_or_null("Panel/PlayerVBox/PlayerHealth") as ProgressBar
	player_speed_bar = get_node_or_null("Panel/PlayerVBox/PlayerSpeed") as ProgressBar

var player: Node = null
var enemy: Node = null

func start(p_player: Node, p_enemy: Node) -> void:
	player = p_player
	enemy = p_enemy
	_update_ui()
	set_process(true)

func _update_ui() -> void:
	if enemy != null:
		if enemy_name_label:
			enemy_name_label.text = str(enemy.name)
		if enemy_health_bar:
			enemy_health_bar.max_value = max(1, enemy.max_health)
			enemy_health_bar.value = enemy.health
	if player != null:
		if player_name_label:
			player_name_label.text = str(player.name)
		if player_health_bar:
			player_health_bar.max_value = max(1, player.max_health)
			player_health_bar.value = player.health

func _process(delta: float) -> void:
	if player == null or enemy == null:
		return

	# increase speed bars (guard against missing UI nodes)
	if enemy_speed_bar:
		enemy_speed_bar.value = min(100, enemy_speed_bar.value + enemy.speed * delta * 0.5)
	if player_speed_bar:
		player_speed_bar.value = min(100, player_speed_bar.value + player.speed * delta * 0.5)

	# check for ready actions (only when bars exist)
	if enemy_speed_bar and enemy_speed_bar.value >= 100:
		_perform_attack(enemy, player)
		enemy_speed_bar.value = 0
		_update_ui()
	if player_speed_bar and player_speed_bar.value >= 100:
		_perform_attack(player, enemy)
		player_speed_bar.value = 0
		_update_ui()

func _perform_attack(attacker: Node, defender: Node) -> void:
	if attacker == null or defender == null:
		return
	var dmg = int(attacker.strength)
	if "take_damage" in defender:
		defender.take_damage(dmg)
	# refresh bars
	_update_ui()
	# check death
	if defender.health <= 0:
		var winner = "player" if attacker == player else "enemy"
		emit_signal("battle_ended", winner)
		queue_free()
