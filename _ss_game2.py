import time
import mss
time.sleep(3)
with mss.MSS() as sct:
    sct.shot(output="D:\\龙虾\\projects\\stardew-liaofang\\_game_shot2.png")
print("done")
