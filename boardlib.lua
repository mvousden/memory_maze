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
   board:clear_map()
   return board
end

function Board:append_path_by_id(old, new)
   -- Append path "old" to path "new", and clear path "old", where "old" and
   -- "new" are path indeces.

   -- Move each point in the old path to the new path.
   for _, tilePosition in ipairs(self.paths[old]) do
      self:set_path_at_point(tilePosition[1], tilePosition[2], new)
      self.paths[new][#self.paths[new] + 1] = {tilePosition[1],
                                               tilePosition[2]}
   end
   self.paths[old] = {}
end

function Board:clear_map()
   -- Clears the board so that its map comprises only of holes. Also clears any
   -- paths for this board.
   --
   -- Pathing information is stored both as a Cartesian map (to allow us to
   -- determine which paths are neighbouring), and as a list by IDs, where each
   -- entry is an unordered list of points in the Cartesian map. Each value in
   -- self.paths_map matches an index in self.paths.
   --
   -- When a path is created, the seed tile position is added into the
   -- self.paths table, where paths are indexed by sequential integers. When a
   -- tile is added to a path, it is added to that same sub-table, and the path
   -- index is written in self.paths_map.
   self.paths = {}
   self.paths_map = {}

   self.map = {}
   for vertiIndex = 1, self.size do
      self.map[vertiIndex] = {}
      self.paths_map[vertiIndex] = {}
      for horizIndex = 1, self.size do
         self.map[vertiIndex][horizIndex] = 0
         self.paths_map[vertiIndex][horizIndex] = 0
      end
   end
end

function Board:count_nonvoids_around_point(horizIndex, vertiIndex)
   -- Returns the number of non-void tiles around a point described by a
   -- horizontal and vertical position.
   neighbourStates = self:get_neighbours_of_point(horizIndex, vertiIndex)
   nonvoidCount = 0
   for _, state in ipairs(neighbourStates) do
      if state > 0 then
         nonvoidCount = nonvoidCount + 1
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
   return {self:get_point(horizIndex, vertiIndex - 1),
           self:get_point(horizIndex, vertiIndex + 1),
           self:get_point(horizIndex + 1, vertiIndex),
           self:get_point(horizIndex - 1, vertiIndex)}
end

function Board:get_neighbouring_paths_of_point(horizIndex, vertiIndex)
   -- Given a horizontal and a vertical position, returns the indeces of the
   -- paths of the map to its north, south, east, and west, in sequence.
   --
   -- If the square has no neighbour point in a given direction (i.e. it is on
   -- an edge of the domain), nil is returned for that direction.
   return {self:get_path_at_point(horizIndex, vertiIndex - 1),
           self:get_path_at_point(horizIndex, vertiIndex + 1),
           self:get_path_at_point(horizIndex + 1, vertiIndex),
           self:get_path_at_point(horizIndex - 1, vertiIndex)}
end

function Board:get_path_at_point(horizIndex, vertiIndex)
   -- Given a horizontal and a vertical position, returns the path index at
   -- that co-ordinate, or nil if there is no path there.
   return self.paths_map[vertiIndex][horizIndex]
end

function Board:get_point(horizIndex, vertiIndex)
   -- Given a horizontal and a vertical position, returns the square of the map
   -- at that co-ordinate (see enum-comment at the top of this file).
   return self.map[vertiIndex][horizIndex]
end

function Board:set_path_at_point(horizIndex, vertiIndex, pathIndex)
   -- Given a horizontal and a vertical position, sets the path index at
   -- that co-ordinate,
   self.paths_map[vertiIndex][horizIndex] = pathIndex
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
   for vertiIndex = 2, self.size - 1 do
      for horizIndex = 2, self.size - 1 do
         if self:get_point(horizIndex, vertiIndex) == 0 then
            candidateTiles[#candidateTiles + 1] = {horizIndex, vertiIndex}
         end
      end
   end

   -- Keep choosing candidate voids at random, until there are no more
   -- candidate voids.
   while #candidateTiles > 0 do
      candidateTileIndex = math.random(#candidateTiles)
      candidatePos = candidateTiles[candidateTileIndex]

      -- Move on if there is more than one tile surrounding this one from the
      -- same path.
      neighbourPaths = self:get_neighbouring_paths_of_point(candidatePos[1],
                                                            candidatePos[2])
      if not nonzero_duplicate_in_table(neighbourPaths) then

         -- Determine the paths that this tile would join.
         pathsThatWouldBeJoined = {}
         for _, value in ipairs(neighbourPaths) do
            if value and value > 0 then  -- Filtering nil results.
               pathsThatWouldBeJoined[#pathsThatWouldBeJoined + 1] = value
            end
         end

         -- Compute the complexity of adding a tile here as the sum of the
         -- lengths of the paths it would combine.
         resultingComplexity = 0
         for _, pathIndex in ipairs(pathsThatWouldBeJoined) do
            resultingComplexity = resultingComplexity + #self.paths[pathIndex]
         end

         -- Only add the tile if it doesn't increase the maximum complexity
         -- beyond the specified maximum.
         if resultingComplexity <= complexityMaximum then

            -- Create a new path with this tile as a seed.
            newPathIndex = #self.paths + 1
            self.paths[newPathIndex] = {{candidatePos[1], candidatePos[2]}}
            self:set_path_at_point(candidatePos[1], candidatePos[2],
                                   newPathIndex)
            self:set_point(candidatePos[1], candidatePos[2], 1)

            -- Join all the paths neighbouring this one together into a new
            -- path.
            for _, oldPathIndex in ipairs(pathsThatWouldBeJoined) do
               self:append_path_by_id(oldPathIndex, newPathIndex)
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
   -- complexityMaximum moves to solve.

   -- Generate an empty board.
   board = Board:create(size)

   -- Populate the board with paths.
   board:populate_paths(complexityMaximum)

   -- Look for a path with the desired complexity. Do this by sorting the paths
   -- by length, and choosing the first path that doesn't exceed the maximum
   -- complexity.
   table.sort(board.paths, function(path1, path2) return #path1 > #path2 end)
   for pathIndex, path in ipairs(board.paths) do
      if #path <= complexityMaximum then
         chosenPath = path
         break
      end
   end

   -- Find members of the path that have only one neighbour.
   pathEnds = {}
   for _, position in ipairs(chosenPath) do
      neighbourStatus = board:get_neighbours_of_point(position[1], position[2])
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
   board:set_point(startSquare[1], startSquare[2], 3)
   board:set_point(endSquare[1], endSquare[2], 4)
   board["start"] = {unpack(startSquare)}

   -- Put a light-off square on each square adjacent to the start.
   -- neighbours = board:get_neighbours_of_point(startSquare[1], startSquare[2])
   neighbours = {{startSquare[1], startSquare[2] - 1},
      {startSquare[1], startSquare[2] + 1},
      {startSquare[1] + 1, startSquare[2]},
      {startSquare[1] - 1, startSquare[2]}}

   for _, position in pairs(neighbours) do
      if board:get_point(position[1], position[2]) == 1 then
         board:set_point(position[1], position[2], 2)
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
      map={{0, 0, 0, 0, 0, 0, 0, 0, 0},
           {0, 1, 1, 1, 0, 3, 1, 1, 0},
           {0, 1, 3, 1, 0, 1, 0, 1, 0},
           {0, 1, 1, 1, 1, 2, 0, 4, 0},
           {0, 0, 0, 0, 0, 0, 0, 0, 0}},
      start={3, 3}
   },
   {
      map={{0, 0, 0, 0, 0, 0, 0, 0},
           {0, 0, 1, 0, 0, 0, 0, 0},
           {0, 1, 3, 1, 0, 1, 4, 0},
           {0, 0, 1, 0, 0, 1, 0, 0},
           {0, 0, 2, 0, 0, 1, 2, 0},
           {0, 0, 1, 1, 0, 0, 1, 0},
           {0, 0, 0, 1, 1, 3, 1, 0},
           {0, 0, 0, 0, 0, 0, 0, 0}},
      start={3, 3},
   },
   {
      map={{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
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
           {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}},
      start={3, 13}
   }
}

-- Add more boards of increasing difficulty
for boardID = #defaultBoards + 1, 100 do
--for boardID = 1, 100 do
   defaultBoards[boardID] = generate_board(15, 10 + boardID * 1.5)
end

return {defaultBoards=defaultBoards, generate_board=generate_board}
