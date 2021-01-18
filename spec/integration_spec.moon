


-- these test whole documents, or larger fragments

snake_game_html = [[
<p></p><p><b>Aeon</b> is epic snake evolution game. It extends over wast period of time.</p><p>It all began with small snake that was lost in woods. After many many years snake begun to evolve, to adopt to its environment. Snake was forced to live rest of its life in tight and dark world. Snake had to evolve so much that now, instead of eating other creatures, snake is consuming energy that it can find.</p><p>Your task it to help snake to&nbsp;survive&nbsp;as long as possible. That can be done by carefully but quickly planing your moves.</p><p>You start as a little helpless snake.</p>By collecting tokens you increase length of your tail. As time passes, barriers will start to appear out of nowhere. Be aware, they are dangerous!<br><p>As your tail isn’t of much use, by evolution your tail will disappear. This is normal.</p><p>Over time it’s darker and darker. In darkness you don’t see a thing. You evolve. You consume energy instead of food and your head light path under you. This will greatly help you,&nbsp;especially&nbsp;since&nbsp;you&nbsp;are in tight space. You consume energy, during your first days, you have learned to use that energy more&nbsp;useful&nbsp;than just lightning you path. You can leave beacons that will stay lit so you can see where you have came from. Jumping is your&nbsp;specialty, but be&nbsp;careful&nbsp;what power ups you use, they cost energy.</p><p>Be careful and save your energy, without it you are dead!</p>

<hr>

<p>Goal of this game is to collect as many tokens as possible. This is done through number of stages. From simple - classical snake game to complex maze in dark gameplay, all in one level without interruptions.</p><p><b>NOTE:</b> <a href="http://www.microsoft.com/en-us/download/details.aspx?id=20914" target="_blank">Microsoft XNA Framework Redistributable 4.0</a> is required (it's free) in order to play the game<br></p>

<hr>

<p><b>Controls</b></p>
<p>Keyboard<br>
</p><ul>

<li><span style="line-height: 1.45em;">Left</span><span style="line-height: 1.45em;">, Right, Up, Down</span><i style="line-height: 1.45em;"> for navigation&nbsp;</i><br></li>

<li><span style="line-height: 1.45em;">Escape</span><i style="line-height: 1.45em;"> for Pause&nbsp;</i><br></li><li><span style="line-height: 1.45em;">Left shift</span><i style="line-height: 1.45em;"> for Jump power up&nbsp;</i><br></li><li><span style="line-height: 1.45em;">Left CTRL</span><i style="line-height: 1.45em;"> for Beacon power up&nbsp;</i><br></li><li><span style="line-height: 1.45em;">Space bar</span><i style="line-height: 1.45em;"> for EMP power up&nbsp;</i><br></li></ul>XBox 360 controller for PC<br><ul><li><span style="line-height: 1.45em;">DPad or Left Thumbstick</span><i style="line-height: 1.45em;"> for navigation&nbsp;</i><br></li><li><span style="line-height: 1.45em;">Start</span><i style="line-height: 1.45em;"> for pause&nbsp;</i><br></li><li><span style="line-height: 1.45em;">A</span><i style="line-height: 1.45em;"> for Jump power up&nbsp;</i><br></li><li><span style="line-height: 1.45em;">B</span><i style="line-height: 1.45em;"> for Beacon power up&nbsp;</i><br></li><li><span style="line-height: 1.45em;">X</span><i style="line-height: 1.45em;"> for EMP power up&nbsp;</i><br></li></ul><br><p></p><p></p>
]]


describe "web_sanitize integration", ->
  describe "snake game", ->
    import Sanitizer, Extractor from require "web_sanitize.html"

    it "extracts", ->
      out = Extractor! snake_game_html
      assert.same [[Aeon is epic snake evolution game. It extends over wast period of time. It all began with small snake that was lost in woods. After many many years snake begun to evolve, to adopt to its environment. Snake was forced to live rest of its life in tight and dark world. Snake had to evolve so much that now, instead of eating other creatures, snake is consuming energy that it can find. Your task it to help snake to survive as long as possible. That can be done by carefully but quickly planing your moves. You start as a little helpless snake. By collecting tokens you increase length of your tail. As time passes, barriers will start to appear out of nowhere. Be aware, they are dangerous! As your tail isn’t of much use, by evolution your tail will disappear. This is normal. Over time it’s darker and darker. In darkness you don’t see a thing. You evolve. You consume energy instead of food and your head light path under you. This will greatly help you, especially since you are in tight space. You consume energy, during your first days, you have learned to use that energy more useful than just lightning you path. You can leave beacons that will stay lit so you can see where you have came from. Jumping is your specialty, but be careful what power ups you use, they cost energy. Be careful and save your energy, without it you are dead! Goal of this game is to collect as many tokens as possible. This is done through number of stages. From simple - classical snake game to complex maze in dark gameplay, all in one level without interruptions. NOTE: Microsoft XNA Framework Redistributable 4.0 is required (it's free) in order to play the game Controls Keyboard Left , Right, Up, Down for navigation  Escape for Pause  Left shift for Jump power up  Left CTRL for Beacon power up  Space bar for EMP power up  XBox 360 controller for PC DPad or Left Thumbstick for navigation  Start for pause  A for Jump power up  B for Beacon power up  X for EMP power up ]], out




  
