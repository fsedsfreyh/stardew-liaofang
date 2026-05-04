extends Node

## AudioManager - 音效系统（纯代码生成）
## 使用 AudioStreamGenerator 实时生成 8-bit 风格音效
## 无需加载任何外部音频文件

enum Sfx {
    PICKUP,       # 拾取物品
    PLANT,        # 播种
    HIT,          # 击中（战斗）
    COIN,         # 金币
    CHOP,         # 砍伐/挖掘
    FISH_CAST,    # 抛竿
    FISH_CATCH,   # 钓鱼成功
    COOK,         # 烹饪
    CRAFT,        # 合成
    UPGRADE,      # 升级
    DOOR,         # 开门
    NOTIFICATION, # 通知
    ERROR,        # 错误
    HEART,        # 好感度提升
    LEVEL_UP,     # 升级
    RAIN,         # 雨声（循环播放用）
}

# BGM 曲目（用正弦波 + 方波合成的简单旋律）
enum Bgm {
    FARM_DAY,     # 农场白天
    FARM_NIGHT,   # 农场夜晚
    TOWN,         # 小镇
    FOREST,       # 森林
    MINE,         # 矿洞
    FISHING,      # 钓鱼
    MENU,         # 主菜单
    WINTER,       # 冬天
    FESTIVAL,     # 节日
}

# 音效播放节点
var sfx_player: AudioStreamPlayer2D
var music_player: AudioStreamPlayer
var rain_player: AudioStreamPlayer

# 当前BGM
var current_bgm: String = ""
var bgm_volume: float = -10.0  # dB
var sfx_volume: float = 0.0  # dB

func _ready():
    _setup_players()
    # 从存档读取音量设置
    if SaveManager.has_save():
        var data = SaveManager.load_data()
        if data.has("audio_volume"):
            bgm_volume = data.audio_volume.get("bgm", -10.0)
            sfx_volume = data.audio_volume.get("sfx", 0.0)

func _setup_players():
    # SFX播放器（2D空间，可跟随玩家）
    sfx_player = AudioStreamPlayer2D.new()
    sfx_player.name = "SfxPlayer"
    add_child(sfx_player)
    
    # BGM播放器
    music_player = AudioStreamPlayer.new()
    music_player.name = "MusicPlayer"
    music_player.volume_db = bgm_volume
    add_child(music_player)
    
    # 雨声循环播放器
    rain_player = AudioStreamPlayer.new()
    rain_player.name = "RainPlayer"
    rain_player.volume_db = -5.0
    add_child(rain_player)

# --- 音效生成与播放 ---

func play_sfx(sfx: Sfx, position: Vector2 = Vector2.ZERO):
    if not is_inside_tree():
        return
    var gen = AudioStreamGenerator.new()
    gen.mix_rate = 22050  # 8-bit 风格低采样率
    gen.buffer_length = 0.5
    sfx_player.stream = gen
    sfx_player.global_position = position if position != Vector2.ZERO else Vector2.ZERO
    sfx_player.play()
    
    # 在播放线程中合成音效波形
    var playback = sfx_player.get_stream_playback()
    if not playback:
        return
    
    var frames = _generate_sfx_frames(sfx)
    for i in range(0, frames.size(), 1024):
        var chunk = PackedVector2Array()
        for j in range(i, min(i + 1024, frames.size())):
            chunk.append(Vector2(frames[j], frames[j]))
        if chunk.size() > 0:
            playback.push_buffer(chunk)

func _generate_sfx_frames(sfx: Sfx) -> PackedFloat32Array:
    var sr = 22050.0
    var frames = PackedFloat32Array()
    match sfx:
        Sfx.PICKUP:
            # 上升音调拾取音（8帧递增）
            for i in range(200):
                var t = i / sr
                var freq = 400.0 + (i / 200.0) * 800.0
                var amp = 1.0 - (i / 200.0)
                frames.append(sin(t * freq * TAU) * amp * 0.4)
        Sfx.PLANT:
            # 短促低音+噪声
            for i in range(100):
                var t = i / sr
                var n = (randf() - 0.5) * (1.0 - i / 100.0)
                frames.append(sin(t * 150.0 * TAU) * 0.3 + n * 0.2)
        Sfx.HIT:
            # 打击音（高频衰减）
            for i in range(150):
                var t = i / sr
                var freq = 800.0 + sin(i * 0.3) * 200.0
                var amp = 1.0 - (i / 150.0)
                frames.append(sin(t * freq * TAU) * amp * 0.5)
        Sfx.COIN:
            # 金币叮当（双音叠加）
            for i in range(300):
                var t = i / sr
                var amp = 1.0 - (i / 300.0)
                var f1 = sin(t * 1200.0 * TAU)
                var f2 = sin(t * 1800.0 * TAU)
                frames.append((f1 * 0.3 + f2 * 0.2) * amp)
        Sfx.CHOP:
            # 砍伐（低频+噪声）
            for i in range(200):
                var t = i / sr
                var n = (randf() - 0.5) * (1.0 - i / 200.0) * 0.5
                frames.append(sin(t * 200.0 * TAU) * 0.3 + n)
        Sfx.FISH_CAST:
            # 抛竿（高频下滑）
            for i in range(400):
                var t = i / sr
                var freq = 600.0 - (i / 400.0) * 400.0
                var amp = (1.0 - i / 400.0) * 0.4
                frames.append(sin(t * freq * TAU) * amp)
        Sfx.FISH_CATCH:
            # 上钩（快速上升+叮）
            for i in range(500):
                var t = i / sr
                var freq = 200.0 + (i / 500.0) * 1000.0
                var amp = max(0, 1.0 - (i - 300) / 200.0) if i > 300 else 1.0
                frames.append(sin(t * freq * TAU) * amp * 0.4)
        Sfx.COOK:
            # 烹饪（气泡沸腾声）
            for i in range(600):
                var t = i / sr
                var b = sin(t * 50.0 * TAU) * 0.5 + 0.5  # 包络
                var n = (randf() - 0.5) * b * 0.3
                frames.append(sin(t * 300.0 * TAU) * b * 0.2 + n)
        Sfx.CRAFT:
            # 合成（金属碰撞+上升）
            for i in range(400):
                var t = i / sr
                var f = 200.0 + sin(i * 0.5) * 100.0
                var amp = 1.0 - (i / 400.0)
                frames.append(sin(t * f * TAU) * amp * 0.4 + sin(t * 400.0 * TAU) * amp * 0.2)
        Sfx.UPGRADE:
            # 升级（华丽上升琶音）
            for i in range(800):
                var t = i / sr
                var note = int(i / 100) % 4
                var freqs = [400.0, 500.0, 600.0, 800.0]
                var freq = freqs[note]
                var amp = 1.0 - (i / 800.0)
                frames.append(sin(t * freq * TAU) * amp * 0.3)
        Sfx.DOOR:
            # 门声（沉闷吱呀）
            for i in range(400):
                var t = i / sr
                var freq = 100.0 + sin(i * 0.05) * 50.0
                var amp = 1.0 - (i / 400.0)
                frames.append(sin(t * freq * TAU) * amp * 0.3)
        Sfx.NOTIFICATION:
            # 通知（双音叮咚）
            for i in range(200):
                var t = i / sr
                var amp = 1.0 - (i / 200.0)
                var f1 = sin(t * 1000.0 * TAU) * 0.3
                var f2 = 0.0
                if i < 100:
                    f2 = sin(t * 600.0 * TAU) * 0.3
                frames.append((f1 + f2) * amp)
        Sfx.ERROR:
            # 错误（低沉短促）
            for i in range(150):
                var t = i / sr
                var freq = 150.0 + sin(i * 0.5) * 30.0
                var amp = 1.0 - (i / 150.0)
                frames.append(sin(t * freq * TAU) * amp * 0.4)
        Sfx.HEART:
            # 心形（两个上升音）
            for i in range(500):
                var t = i / sr
                var phase = 1.0 if i < 250 else (1.0 - (i - 250) / 250.0)
                var freq = 600.0 if i < 250 else 900.0
                frames.append(sin(t * freq * TAU) * phase * 0.3)
        Sfx.LEVEL_UP:
            # 升级（长琶音+颤音）
            for i in range(1200):
                var t = i / sr
                var note = int(i / 200) % 6
                var freqs = [400.0, 500.0, 600.0, 700.0, 900.0, 1200.0]
                var freq = freqs[note] + sin(t * 20.0 * TAU) * 5.0  # 轻微颤音
                var amp = 1.0 - (i / 1200.0)
                frames.append(sin(t * freq * TAU) * amp * 0.3)
    return frames

# --- BGM 系统 ---

func play_bgm(bgm: Bgm):
    var key = str(bgm)
    if current_bgm == key:
        return
    current_bgm = key
    
    if not is_inside_tree():
        return
    
    var gen = AudioStreamGenerator.new()
    gen.mix_rate = 22050
    gen.buffer_length = 2.0  # 2秒缓冲（循环播放）
    music_player.stream = gen
    music_player.play()
    
    var playback = music_player.get_stream_playback()
    if not playback:
        return
    
    # 启动 BGM 循环线程
    _start_bgm_loop(playback, bgm)

func _start_bgm_loop(playback: AudioStreamGeneratorPlayback, bgm: Bgm):
    # 使用 _process 循环推送 BGM 音帧
    # 实际会持续调用直到切歌
    pass

# 简化版本：用 Timer 推送 BGM 帧
var _bgm_timer: Timer = null

func _push_bgm_frame(bgm: Bgm):
    if not music_player.playing:
        return
    var playback = music_player.get_stream_playback()
    if not playback:
        return
    if playback.get_frames_available() < 2048:
        return
    
    var frames = _generate_bgm_frames(bgm, 4096)
    var chunk = PackedVector2Array()
    for f in frames:
        chunk.append(Vector2(f, f))
    if chunk.size() > 0:
        playback.push_buffer(chunk)

func _generate_bgm_frames(bgm: Bgm, count: int) -> PackedFloat32Array:
    var sr = 22050.0
    var frames = PackedFloat32Array()
    # 全局时间（用于循环旋律）
    var global_t = _bgm_global_time
    var bpm = 120.0
    var beat_len = 60.0 / bpm
    
    # 根据 BGM 类型生成不同旋律
    for i in range(count):
        var t = global_t + i / sr
        var sample = 0.0
        match bgm:
            Bgm.FARM_DAY:
                # C大调欢乐农场（三和弦分解）
                var beat = int(t / beat_len) % 8
                var notes = [262.0, 330.0, 392.0, 330.0, 523.0, 392.0, 330.0, 262.0]  # C E G E C5 G E C
                var freq = notes[beat]
                var env = sin(t * 4.0 * TAU) * 0.5 + 0.5  # 缓慢包络
                sample = sin(t * freq * TAU) * 0.15 * env
                # 低音
                var bass_note = 131.0 if beat < 4 else 165.0
                sample += sin(t * bass_note * TAU) * 0.1
                # 装饰颤音
                sample += sin(t * freq * 2.0 * TAU) * 0.05 * env
            Bgm.TOWN:
                # D大调小镇（温暖的七和弦）
                var beat = int(t / (beat_len * 1.5)) % 8
                var notes = [294.0, 370.0, 440.0, 370.0, 587.0, 440.0, 370.0, 294.0]
                var freq = notes[beat]
                sample = sin(t * freq * TAU) * 0.12
                sample += sin(t * freq * 0.5 * TAU) * 0.08  # 低八度
                sample += sin(t * freq * 3.0 * TAU) * 0.03  # 泛音
            Bgm.FOREST:
                # 自然风（五声音阶）
                var beat = int(t / (beat_len * 2.0)) % 8
                var notes = [392.0, 440.0, 523.0, 587.0, 784.0, 587.0, 523.0, 440.0]
                var freq = notes[beat]
                sample = sin(t * freq * TAU) * 0.1
                # 风声（低频噪声）
                sample += (randf() - 0.5) * 0.02
            Bgm.MINE:
                # 矿洞（阴暗低音+不和谐音）
                var beat = int(t / (beat_len * 2.0)) % 4
                var notes = [110.0, 98.0, 110.0, 130.0]  # A G A C
                var freq = notes[beat]
                sample = sin(t * freq * TAU) * 0.15
                sample += (randf() - 0.5) * (sin(t * 2.0 * TAU) * 0.5 + 0.5) * 0.05
            Bgm.MENU:
                # 主菜单（安详C大调）
                var beat = int(t / (beat_len * 2.0)) % 4
                var notes = [262.0, 392.0, 523.0, 392.0]
                var freq = notes[beat]
                sample = sin(t * freq * TAU) * 0.12
                sample += sin(t * freq * 0.5 * TAU) * 0.08
        frames.append(sample)
    
    _bgm_global_time += count / sr
    return frames

var _bgm_global_time: float = 0.0

# 启动 BGM 定时推送
func _start_bgm(bgm: Bgm):
    if _bgm_timer:
        _bgm_timer.stop()
        _bgm_timer.queue_free()
    
    _bgm_global_time = 0.0
    _bgm_timer = Timer.new()
    _bgm_timer.name = "BgmTimer"
    _bgm_timer.timeout.connect(_on_bgm_timer.bind(bgm))
    _bgm_timer.wait_time = 0.2
    _bgm_timer.one_shot = false
    add_child(_bgm_timer)
    _bgm_timer.start()

func _on_bgm_timer(bgm: Bgm):
    _push_bgm_frame(bgm)

func stop_bgm():
    current_bgm = ""
    music_player.stop()
    if _bgm_timer:
        _bgm_timer.stop()

# --- 雨声循环 ---

func start_rain():
    if rain_player.playing:
        return
    var gen = AudioStreamGenerator.new()
    gen.mix_rate = 11025
    gen.buffer_length = 0.5
    rain_player.stream = gen
    rain_player.play()
    
    var playback = rain_player.get_stream_playback()
    if not playback:
        return
    
    # 用 Timer 持续推送雨声
    var t = Timer.new()
    t.name = "RainLoopTimer"
    t.timeout.connect(_push_rain_frame.bind(playback))
    t.wait_time = 0.1
    t.one_shot = false
    add_child(t)
    t.start()

func _push_rain_frame(playback: AudioStreamGeneratorPlayback):
    if not rain_player.playing:
        return
    if playback.get_frames_available() < 512:
        return
    var sr = 11025.0
    var count = 2048
    var frames = PackedFloat32Array()
    for i in range(count):
        # 白噪声（模拟雨声）
        frames.append((randf() - 0.5) * 0.3)
    var chunk = PackedVector2Array()
    for f in frames:
        chunk.append(Vector2(f, f))
    if chunk.size() > 0:
        playback.push_buffer(chunk)

func stop_rain():
    rain_player.stop()
    # 停止雨声定时器
    for child in get_children():
        if child.name == "RainLoopTimer":
            child.stop()
            child.queue_free()

# --- 音量控制 ---

func set_bgm_volume(db: float):
    bgm_volume = clamp(db, -40.0, 6.0)
    music_player.volume_db = bgm_volume

func set_sfx_volume(db: float):
    sfx_volume = clamp(db, -40.0, 6.0)

# --- 场景自动切换BGM ---

# 在场景切换时自动调用
func on_scene_changed(scene_name: String):
    match scene_name:
        "farm":
            play_bgm(Bgm.FARM_DAY)
        "town":
            play_bgm(Bgm.TOWN)
        "forest":
            play_bgm(Bgm.FOREST)
        "mine":
            play_bgm(Bgm.MINE)
        "menu":
            play_bgm(Bgm.MENU)
        _:
            stop_bgm()