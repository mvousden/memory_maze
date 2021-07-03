boardlib = require("boardlib")
board = boardlib.generate_board(20, 10)

boardRepr = ""
for _, row in ipairs(board) do
   if #boardRepr > 0 then
      boardRepr = boardRepr .. "\n"
   end
   for _, cell in ipairs(row) do
      boardRepr = boardRepr .. cell
   end
end
print(boardRepr)
print("start: " .. board["start"][1] .. ", " .. board["start"][2])
