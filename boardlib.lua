-- Defines logic for generating boards.
--
-- Boards are tables of implicitly-indexed tables defining a map.
--  - 0 denotes a hole
--  - 1 denotes a path
--  - 2 denotes a light-off
--  - 3 denotes a light-on
--  - 4 denotes the exit

require("math")

-- Board class behaviour.
Board = {}
Board.__index = Board

function Board:create(size)
   -- Creates a board of a given size, and initialises its map to only
   -- holes. Does not define a start point.
   local board = {}
   setmetatable(board, Board)

   board.size = size
   board.clear_map()
end

function Board:clear_map()
   -- Clears the board so that its map comprises only of holes. Also clears any
   -- paths for this board.
   self.paths = {}
   self.map = {}
   for vertiIndex = 1, size do
      self.map[vertiIndex] = {}
      for horizIndex = 1, size do
         self.map[vertiIndex][horizIndex] = 0
      end
   end
end

function Board:count_nonvoids_around_point(horizIndex, vertiIndex)
   -- Returns the number of non-void tiles around a point described by a
   -- horizontal and vertical position.
   neighbourStates = self.get_neighbours_of_point(horizIndex, vertiIndex)
   nonvoidCount = 0
   for _, state in ipairs(neighbourStates) do
      if state > 0 then
         nonvoidCount += 1
      end
   end
   return nonvoidCount
end

function Board:get_neighbours_of_point(horizIndex, vertiIndex)
   -- Given a horizontal and a vertical position, returns the squares of the
   -- map to its north, south, east, and west, in sequence.
   --
   -- If the square has no neighbour point in a given direction (i.e. it is on
   -- an edge of the domain), nil is returned for that direction.
   return {self.get_point(horizIndex, vertiIndex - 1),
           self.get_point(horizIndex, vertiIndex + 1),
           self.get_point(horizIndex + 1, vertiIndex),
           self.get_point(horizIndex - 1, vertiIndex - 1)}
end

function Board:get_point(horizIndex, vertiIndex)
   -- Given a horizontal and a vertical position, returns the square of the map
   -- at that co-ordinate (see enum-comment at the top of this file).
   return self.map[vertiIndex][horizIndex]
end

function Board:set_point(horizIndex, vertiIndex, value)
   -- Given a horizontal and a vertical position, sets the square of the map
   -- at that co-ordinate (see enum-comment at the top of this file).
   self.map[vertiIndex][horizIndex] = value
end

function Board:populate_paths(complexityMaximum)
   -- Populates the map of a board with paths.

   -- This is achieved by:
   --  1. Marking each void that is not on the edge as a candidate.

   --  2. For each candidate void (chosen in a random sequence), determining
   --     whether that void can be made to a path. It can be made to a path if:
   --   - There are no walkable tiles neighbouring it (Manhattan)
   --
   --   - If there are walkable tiles neighbouring it, all of the following
   --     must be true:
   --     - Any super-path produced by adding the tile must have length less
   --       than complexityMaximum.
   --     - Two walkable tiles of the same path cannot be connected in this
   --       way.
   --  3. Setting all determined candidates to paths.

   -- Determine candidate voids.
   candidateTiles = {}
   for vertiIndex = 2, size - 1 do
      for horizIndex = 2, size - 1 do
         if self.get_point(horizIndex, vertiIndex) == 0 then
            candidateTiles[#candidateTiles + 1] = {horizIndex, vertiIndex}
         end
      end
   end

   -- Create an object to store information about paths.
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
      candidatePos = candidateTiles[candidateTileIndex]

      -- Move on if there is more than one tile surrounding this one from the
      -- same path.

      -- <!> Oh no, the map mechanism is broken while this method is being
      -- used, because we set the value of the points equal to the index of the
      -- path they refer to! The solution to this may be, at each point, to
      -- store a value for the enum, and a value dictating what path it belongs
      -- to, if any. We then need a methods to access the map by its "enum
      -- values", and to access the map by its "path values".
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


end

-- Helper for creating a board with specific properties.
function generate_board(size, complexityMaximum)
   -- Returns a square board of a given size that requires no more than
   -- complexityMax moves to solve.

   -- Generate an empty board.
   board = Board:create(size)

   -- Populate the board with paths.
   board.populate_paths(complexityMaximum)

   -- <!>

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

-- Define some "tutorial" boards.
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

-- Add more boards of increasing difficulty
for boardID = #defaultBoards + 1, 100 do
   defaultBoards[boardID] = generate_board(10 + boardID, 10 + boardID * 1.5)
end

return {defaultBoards=defaultBoards, generate_board=generate_board}
