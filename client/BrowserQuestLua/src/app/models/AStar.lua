
local AStar = {}

--[[
param s start point
param e end point
param g grid map
param w grid width
param h grid height
]]
function AStar.findPath(s, e, g, w, h)
	local startPoint = clone(s)
	local endPoint = clone(e)
	local width = w
	local height = h
	local grid = g
	local cur
	local EndPoint
	local isFindPath

	-- dump(startPoint, "startPoint:")
	-- dump(endPoint, "endPoint:")
	-- printInfo("width:%d, height:%d", width, height)

	-- local temp = {x = 312, y = 1}
	-- printInfo("312,1  %s", tostring(grid[temp.x][temp.y]))

	AStar.init()

	local open = AStar.open_
	local close = AStar.close_

	-- add start to open

	open[startPoint.x * 1000 + startPoint.y] = startPoint

	while true do

		if nil == next(open) then
			-- havn't find path
			break
		end

		-- find min f value point
		cur = nil
		for _, v in pairs(open) do
			if nil == cur then
				cur = v
			elseif cur.f > v.f then
				cur = v
			end
		end

		if cur.x * 1000 + cur.y == endPoint.x * 1000 + endPoint.y then
			EndPoint = cur
			-- dump(cur, "find end point:")
			-- find path
			isFindPath = true
			break
		end

		-- add the close
		close[cur.x * 1000 + cur.y] = cur
		open[cur.x * 1000 + cur.y] = nil

		-- add the neighbouring to open
		AStar.addPointIf({x = cur.x, y = cur.y - 1}, cur, endPoint, grid, width, height) -- up
		AStar.addPointIf({x = cur.x, y = cur.y + 1}, cur, endPoint, grid, width, height) -- down
		AStar.addPointIf({x = cur.x - 1, y = cur.y}, cur, endPoint, grid, width, height) -- left
		AStar.addPointIf({x = cur.x + 1, y = cur.y}, cur, endPoint, grid, width, height) -- right
	end

	local path
	if isFindPath then
		path = {}
		cur = EndPoint

		while cur do
			table.insert(path, 1, {x = cur.x, y = cur.y})
			cur = cur.parent
		end
	end

	-- dump(path, "astar find path:")

	return path
end

function AStar.init()
	AStar.open_ = {}
	AStar.close_ = {}
end

function AStar.addPointIf(p, parent, endPoint, grid, width, height)
	if p.x < 1 or p.x > width
		or p.y < 1 or p.y > height then
		-- invalid point
		return
	end

	-- printInfo("grid (%d,%d) %s", p.x, p.y, tostring(grid[p.y][p.x]))
	-- dump(grid[p.y], "line:")
	if grid and grid[p.y][p.x] then
		return
	end

	if AStar.close_[p.x * 1000 + p.y] then
		return
	end

	AStar.calcPointInfo(p, parent, endPoint)

	local pKey = p.x * 1000 + p.y
	if not AStar.open_[pKey] or AStar.open_[pKey].f > p.f then
		AStar.open_[pKey] = p
	end
end

function AStar.calcPointInfo(p, parent, endPoint)
	p.g = (parent.g or 0) + 1
	p.h = math.abs(endPoint.x - p.x) + math.abs(endPoint.y - p.y)
	p.f = p.g + p.h
	p.parentKey = parent.x * 1000 + parent.y
	p.parent = parent
end

return AStar
