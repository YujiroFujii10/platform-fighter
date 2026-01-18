extends Control

var player1
var player2


func set_players(p1, p2):
	player1 = p1
	player2 = p2


func _process(delta):
	if player1:
		$P1Percent.text = str(player1.percentage) + "%"
		$P1Stocks.text = str(player1.stocks) + " x "
	if player2:
		$P2Percent.text = str(player2.percentage) + "%"
		$P2Stocks.text = str(player2.stocks) + " x "
