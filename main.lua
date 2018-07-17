require("math")
boardLib = require("boardlib")

function love.load()
   -- Define boards
   boards = boardLib.defaultBoards
   boardIndex = 1

   -- Define board state
   boardCleared = false
   boardIntroduced = false
   boardFadeInTime = 0
   boardFadeInEnd = 1
   boardFadeOutTime = 0
   boardFadeOutEnd = 1

   -- Starting player state
   playerFalling = false
   fallTime = 0

   -- Starting light status
   lightsOn = true

   -- Colours
   safeColour = {1, 1, 1}
   outlineColour = {0.3, 0.3, 0.3}
   playerColour = {0.5, 0.5, 0.5}
   lightsOffColour = {0.7, 0.2, 0.2}
   lightsOnColour = {0, 0.2, 0}
   exitColour = {0, 0, 0.2}
end

function love.draw()
   -- Define colours for this loop
   safeColourNow = {}
   outlineColourNow = {}
   playerColourNow = {}
   lightsOffColourNow = {}
   lightsOnColourNow = {}
   exitColourNow = {}
   opacity = (boardFadeInTime / boardFadeInEnd) - (boardFadeOutTime / boardFadeOutEnd)
   for index = 1, 3 do
      safeColourNow[index] = safeColour[index] * opacity
      outlineColourNow[index] = outlineColour[index] * opacity
      playerColourNow[index] = playerColour[index] * opacity
      lightsOffColourNow[index] = lightsOffColour[index] * opacity
      lightsOnColourNow[index] = lightsOnColour[index] * opacity
      exitColourNow[index] = exitColour[index] * opacity
   end

   -- Draw squares
   for vertiIndex = 1, #boards[boardIndex].map do
      vertiPos = vertiIndex - 1

      for horizIndex = 1, #boards[boardIndex].map[vertiIndex] do
         squareType = boards[boardIndex].map[vertiIndex][horizIndex]
         horizPos = horizIndex - 1

         -- Draw outlines
         love.graphics.setColor(unpack(outlineColourNow))
         love.graphics.rectangle("line", horizPos * boxSize,
                                 vertiPos * boxSize, boxSize, boxSize)

         -- Draw safe squares if the lights are on.
         if squareType > 0 then
            if lightsOn then
               love.graphics.setColor(unpack(safeColourNow))
               love.graphics.rectangle("fill", horizPos * boxSize,
                                       vertiPos * boxSize, boxSize, boxSize)
            end
         end

         -- Always draw switches.
         if squareType == 2 then
            love.graphics.setColor(unpack(lightsOffColourNow))
            love.graphics.rectangle("fill", horizPos * boxSize,
                                    vertiPos * boxSize, boxSize, boxSize)
         elseif squareType == 3 then
            love.graphics.setColor(unpack(lightsOnColourNow))
            love.graphics.rectangle("fill", horizPos * boxSize,
                                    vertiPos * boxSize, boxSize, boxSize)

         -- Draw the exit only if the lights are on.
         elseif squareType == 4 then
            if lightsOn then
               love.graphics.setColor(unpack(exitColourNow))
               love.graphics.rectangle("fill", horizPos * boxSize,
                                       vertiPos * boxSize, boxSize, boxSize)
            end
         end
      end
   end

   -- Draw the player once we're done fading in. The player's position uses
   -- 1-based indexing.
   if boardIntroduced then
      love.graphics.setColor(unpack(playerColourNow))
      love.graphics.rectangle("fill",
                              (playerPos[1] - 1 + fallTime / 2) * boxSize,
                              (playerPos[2] - 1 + fallTime / 2) * boxSize,
                              boxSize * (1 - fallTime),
                              boxSize * (1 - fallTime))
   end
end

function love.keypressed(key)
   -- Only react if not falling and not fading.
   if not playerFalling and not boardCleared and boardIntroduced then

      -- Move player
      if key == "left" then
         playerPos[1] = playerPos[1] - 1
      elseif key == "right" then
         playerPos[1] = playerPos[1] + 1
      elseif key == "up" then
         playerPos[2] = playerPos[2] - 1
      elseif key == "down" then
         playerPos[2] = playerPos[2] + 1
      end

      -- If player is now on a hole, mark them as falling and turn the lights
      -- back on.
      onType = boards[boardIndex].map[playerPos[2]][playerPos[1]]
      if onType == 0 then
         playerFalling = true

      -- If the player is at the exit, start fading out.
      elseif onType == 4 then
         lightsOn = true
         boardCleared = true

      -- Control the lights
      elseif onType == 2 then
         lightsOn = false
      elseif onType == 3 then
         lightsOn = true
      end
      if playerFalling then
         lightsOn = true
      end
   end
end

function love.update(dt)

   -- Handle window resizing.
   screenWidth = love.graphics.getWidth()
   screenHeight = love.graphics.getHeight()
   boxMinWidth = screenWidth / #boards[boardIndex].map
   boxMinHeight = screenHeight / #boards[boardIndex].map[1]
   boxSize = math.min(boxMinWidth, boxMinHeight)

   -- Falling logic
   if playerFalling then
      fallTime = fallTime + dt

      -- We're done with falling. Reset the player.
      if fallTime >= 1 then
         playerFalling = false
         fallTime = 0
         playerPos = {unpack(boards[boardIndex]["start"])}
      end
   end

   -- Board introduction logic
   if not boardIntroduced then
      boardFadeInTime = boardFadeInTime + dt

      -- We're done with fading in.
      if boardFadeInTime >= boardFadeInEnd then
         boardIntroduced = true
         playerPos = {unpack(boards[boardIndex]["start"])}
      end
   end

   -- Board exit logic
   if boardCleared then
      boardFadeOutTime = boardFadeOutTime + dt

      -- We're done with fading out. Reset the player and use the next board.
      if boardFadeOutTime >= boardFadeOutEnd then
         boardCleared = false
         boardIntroduced = false
         boardFadeInTime = 0
         boardFadeOutTime = 0
         boardIndex = boardIndex + 1
         if boardIndex > #boards then
            boardIndex = 1
         end
         playerPos = {unpack(boards[boardIndex]["start"])}
      end
   end
end
