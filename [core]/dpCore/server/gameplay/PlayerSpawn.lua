--- Спавн игроков
-- @module dpCore.PlayerSpawn
-- @author Wherry

PlayerSpawn = {}
local DEBUG_ALWAYS_SPAWN_AT_HOTEL = true

local hotelsPositions = {
	{x = 1787.025, y = -1384.408, z = 15.393}
}

--- Возвращает место спавна в отеле для игрока
-- @local
-- @tparam player player игрок
-- @treturn table {interior = 0, position = Vector3}
local function getPlayerHotelLocation(player)
	local hotelID = 1
	local pos = hotelsPositions[hotelID]
	return {interior = 0, position = Vector3(pos.x, pos.y, pos.z)}
end

--- Возвращает место спавна игрока
-- @local
-- @tparam player player игрок
-- @treturn table {interior = 0, position = Vector3}
local function getPlayerSpawnLocation(player)
	local playerHasHome = false
	-- Если у игрока нет дома, спавн в отеле
	if not playerHasHome or DEBUG_ALWAYS_SPAWN_AT_HOTEL then
		return getPlayerHotelLocation(player)
	end

	-- Спавн в доме
	local position = Vector3 {0, 0, 10}
	return {interior = 0, position = position}
end

--- Заспавнить игрока.
-- Если у игрока нет дома, он будет заспавнен в отеле.
-- @tparam player player игрок, которого необходимо заспавнить
-- @treturn bool удалось ли заспавнить игрока
function PlayerSpawn.spawn(player)
	if not isElement(player) then
		return false
	end
	local location = getPlayerSpawnLocation(player)
	player:spawn(location.position)
	player:setCameraTarget()
	player:fadeCamera(true, 3)
	player.model = player:getData("skin")
	return true
end

addEventHandler("onPlayerWasted", root, function ()
	local player = source
	player:fadeCamera(false, 3)
	setTimer(function ()
		if isElement(player) then
			PlayerSpawn.spawn(player)
		end
	end, 3000, 1)
end)