-- Defines logic for generating boards.
--
-- Boards are tables of implicitly-indexed tables defining a map.
--  - 0 denotes a hole
--  - 1 denotes a path
--  - 2 denotes a light-off
--  - 3 denotes a light-on
--  - 4 denotes the exit

require("math")

defaultBoards = {
   {
      {0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 1, 1, 1, 0, 3, 1, 1, 0},
      {0, 1, 3, 1, 0, 1, 0, 1, 0},
      {0, 1, 1, 1, 1, 2, 0, 4, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0},
      start={3, 3}
   },
   {
      {0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 1, 0, 0, 0, 0, 0},
      {0, 1, 3, 1, 0, 1, 4, 0},
      {0, 0, 1, 0, 0, 1, 0, 0},
      {0, 0, 2, 0, 0, 1, 2, 0},
      {0, 0, 1, 1, 0, 0, 1, 0},
      {0, 0, 0, 1, 1, 3, 1, 0},
      {0, 0, 0, 0, 0, 0, 0, 0},
      start={3, 3},
   },
   {
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 3, 1, 2, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0},
      {0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0},
      {0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0},
      {0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 4, 0},
      {0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0},
      {0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0},
      {0, 0, 1, 1, 2, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0},
      {0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0},
      {0, 1, 3, 1, 1, 2, 1, 0, 1, 0, 1, 1, 0, 1, 0},
      {0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      start={3, 13}
   }
}

function generate_board(size, complexityMax)
   -- Returns a square board of a given size that requires no more than
   -- complexityMax moves to solve.

   -- Generate an empty board.
   board = {}
   for vertiIndex = 1, size do
      board[vertiIndex] = {}
      for horizIndex = 1, size do
         board[vertiIndex][horizIndex] = 0
      end
   end

   -- Categorise each void that can potentially hold a path square.
   candidateTiles = {}
   for vertiIndex = 2, size - 1 do
      for horizIndex = 2, size - 1 do
         candidateTiles[#candidateTiles + 1] = {horizIndex, vertiIndex}
      end
   end

   -- Store information about paths.
   --
   -- When a path is created, the seed tile position is added into this paths
   -- table, where paths are indexed by sequential integers. When a tile is
   -- added to a path, it is added to that same sub-table, and the path index
   -- is written on the board.
   paths = {}

   -- Keep choosing candidate voids at random, until there are no more
   -- candidate voids.
   while #candidateTiles > 0 do

      candidateTileIndex = math.random(#candidateTiles)

      -- A void is a valid place to build a walkable tiles if all one the
      -- following holds:
      --
      --  - There are no walkable tiles neighbouring it (Manhattan)
      --
      --  - If there are walkable tiles neighbouring it, all of the following
      --    must be true:
      --    - Any super-path produced by adding the tile must have length less
      --      than complexityMax
      --    - Two walkable tiles of the same path cannot be connected in this
      --      way.
      --
      -- Start by determining the neighbours of the tile.
      candidatePos = candidateTiles[candidateTileIndex]

      -- N, S, E, W
      neighbourStatus = {board[candidatePos[2] - 1][candidatePos[1]],
                         board[candidatePos[2] + 1][candidatePos[1]],
                         board[candidatePos[2]][candidatePos[1] - 1],
                         board[candidatePos[2]][candidatePos[1] + 1]}

      -- Move on if there is more than one tile surrounding this one from the
      -- same path.
      if not nonzero_duplicate_in_table(neighbourStatus) then

         -- Determine the paths that this tile would join.
         neighbourPaths = {}
         for _, value in ipairs(neighbourStatus) do
            if value > 0 then
               neighbourPaths[#neighbourPaths + 1] = value
            end
         end

         -- Check complexity requirement.
         resultingComplexity = 0
         for _, pathIndex in ipairs(neighbourPaths) do
            resultingComplexity = resultingComplexity + #paths[pathIndex]
         end

         if resultingComplexity <= complexityMax then

            newPathIndex = #paths + 1
            -- Create a new path with this tile as a seed.
            paths[newPathIndex] = {{candidatePos[1], candidatePos[2]}}
            board[candidatePos[2]][candidatePos[1]] = newPathIndex

            -- Join all the paths neighbouring this one together into a new
            -- path, and change all of their cells in the board to this new
            -- path ID. Note that we don't remove the old paths from the paths
            -- table; this is to maintain its sequential indexing.
            for _, pathIndex in ipairs(neighbourPaths) do
               for _, tilePosition in ipairs(paths[pathIndex]) do
                  board[tilePosition[2]][tilePosition[1]] = newPathIndex
                  paths[newPathIndex][#paths[newPathIndex] + 1] = {tilePosition[1], tilePosition[2]}
               end
               -- Clear the old path, so it won't be selected later.
               paths[pathIndex] = {}
            end
         end
      end

      -- Whether or not we added the tile, remove it from the candidate list,
      -- maintaining sequential ordering.
      candidateTiles[candidateTileIndex] = {candidateTiles[#candidateTiles][1],
                                            candidateTiles[#candidateTiles][2]}
      candidateTiles[#candidateTiles] = nil
   end

   -- For all squares on the board, make them into paths from whatever integer
   -- they are.
   for vertiIndex = 1, size do
      for horizIndex = 1, size do
         if board[vertiIndex][horizIndex] > 0 then
            board[vertiIndex][horizIndex] = 1
         end
      end
   end

   -- Look for a path with the desired complexity. Do this by sorting the paths
   -- by length, and choosing the first path that matches "#path <=
   -- complexityMax".
   table.sort(paths, function(path1, path2) return #path1 > #path2 end)
   for pathIndex, path in ipairs(paths) do
      if #path <= complexityMax then
         chosenPath = path
         break
      end
   end

   -- Find members of the path that have only one neighbour.
   pathEnds = {}
   for _, position in ipairs(chosenPath) do
      neighbourStatus = {board[position[2] - 1][position[1]],
                         board[position[2] + 1][position[1]],
                         board[position[2]][position[1] - 1],
                         board[position[2]][position[1] + 1]}
      if not nonzero_duplicate_in_table(neighbourStatus) then
         pathEnds[#pathEnds + 1] = {position[1], position[2]}
      end
   end

   -- Choose two neighbours that are furthest apart to hold the start and end
   -- squares.
   distances = {}
   for _, pathEnd1 in ipairs(pathEnds) do
      for _, pathEnd2 in ipairs(pathEnds) do
         distances[#distances + 1] = {ends={{pathEnd1[1], pathEnd1[2]},
                                         {pathEnd2[1], pathEnd2[2]}},
                                      manhattan=manhattan(pathEnd1, pathEnd2)}
      end
   end
   table.sort(distances, function(dist1, dist2)
                 return dist1["manhattan"] > dist2["manhattan"]
   end)
   startSquare, endSquare = unpack(distances[1]["ends"])
   board[startSquare[2]][startSquare[1]] = 3
   board[endSquare[2]][endSquare[1]] = 4
   board["start"] = {unpack(startSquare)}

   -- Put a light-off square on each square adjacent to the start.
   neighbours = {{startSquare[1] - 1, startSquare[2]},
      {startSquare[1] + 1, startSquare[2]},
      {startSquare[1], startSquare[2] - 1},
      {startSquare[1], startSquare[2] + 1}}

   for _, position in pairs(neighbours) do
      if board[position[2]][position[1]] == 1 then
         board[position[2]][position[1]] = 2
      end
   end

   return board
end

function manhattan(position1, position2)
   -- Returns the Manhattan distance between two positions.
   return math.abs(position1[1] - position2[1]) +
      math.abs(position1[2] - position2[2])
end

function nonzero_duplicate_in_table(tableToTest)
   -- Returns true if a non-zero duplicate exists in tableToTest, and false
   -- otherwise.
   for primaryIndex = 1, #tableToTest do
      if tableToTest[primaryIndex] ~= 0 then
         for secondaryIndex = primaryIndex + 1, #tableToTest do
            if tableToTest[primaryIndex] == tableToTest[secondaryIndex] then
               return true
            end
         end
      end
   end
   return false
end

-- Add more boards of increasing difficulty
for boardID = #defaultBoards + 1, 100 do
   defaultBoards[boardID] = generate_board(10 + boardID, 10 + boardID * 1.5)
end

return {defaultBoards=defaultBoards, generate_board=generate_board}
