extends Node

enum SoundKind {SFX, MUSIC}

@onready var sfx_players: Node = $SFXPlayers
@onready var music_players: Node = $MusicPlayers

@onready var PlayersMap: = {
	SoundKind.SFX: sfx_players,
	SoundKind.MUSIC: music_players
}

const SHUFFLE1_SFX := preload("res://media/audio/shuffle1.mp3")
const SHUFFLE2_SFX := preload("res://media/audio/shuffle2.mp3")
const SHUFFLE3_SFX := preload("res://media/audio/shuffle3.mp3")
const SHUFFLES_SFX := [SHUFFLE1_SFX, SHUFFLE2_SFX, SHUFFLE3_SFX]

const MUSIC1 = preload("res://media/audio/music1.mp3")


func pick_sound_at_random(choices: Array) -> AudioStream:
	return choices[randi_range(0, len(choices) - 1)]
	

func play_audio(
	kind: SoundKind, stream: AudioStream, volume: float = 1
) -> AudioStreamPlayer:
	var players: Node = PlayersMap[kind]
		
	for player: AudioStreamPlayer in players.get_children():
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(volume)
			player.play()
			return player
	print('No free audio stream.')
	return null


func play_sfx(stream: AudioStream, volume: float = 1):
	return play_audio(SoundKind.SFX, stream, volume)


func play_music(stream: AudioStream, volume: float = 1):
	return play_audio(SoundKind.MUSIC, stream, volume)
