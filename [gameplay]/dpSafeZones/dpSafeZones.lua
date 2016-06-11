local safeZonesList = {
	-- Hotel
	{Vector2( { x = 1841.980, y = -1334.551} ), Vector2( { x = 1775.478, y = -1447.706 })}
}

local function createSafeZone(pos1, pos2)
	local rectMin = Vector2(0, 0)
	rectMin.x = math.min(pos1.x, pos2.x)
	rectMin.y = math.min(pos1.y, pos2.y)
	local rectMax = Vector2(0, 0)
	rectMax.x = math.max(pos1.x, pos2.x)
	rectMax.y = math.max(pos1.y, pos2.y)
	local size = rectMax - rectMin
	local colShape = createColRectangle(rectMin, size)
	colShape:setData("dpSafeZone", true)
	return colShape
end

for _, zone in ipairs(safeZonesList) do
	createSafeZone(unpack(zone))
end

local function handleColShapeHit(colshape, element, matchingDimension)
	if not matchingDimension or not colshape:getData("dpSafeZone") then
		return
	end
	if element == localPlayer then
		setCameraClip(true, false)
	end
	if element.type == "player" or element.type == "vehicle" then
		for i, e in ipairs(colshape:getElementsWithin("player")) do
			element:setCollidableWith(e, false)
		end
		for i, e in ipairs(colshape:getElementsWithin("vehicle")) do
			element:setCollidableWith(e, false)
		end
	end
end

local function handleColShapeOut(colshape, element, matchingDimension)
	if not matchingDimension or not source:getData("dpSafeZone") then
		return
	end
	if element == localPlayer then
		setCameraClip(true, true)
	end
	if element.type == "player" or element.type == "vehicle" then
		for i, e in ipairs(source:getElementsWithin("player")) do
			element:setCollidableWith(e, true)
		end
		for i, e in ipairs(source:getElementsWithin("vehicle")) do
			element:setCollidableWith(e, true)
		end
	end
end

addEventHandler("onClientColShapeLeave", resourceRoot, function (element, matchingDimension)
	handleColShapeOut(source, element, matchingDimension)
end)

addEventHandler("onClientColShapeHit", resourceRoot, function (element, matchingDimension)
	handleColShapeHit(source, element, matchingDimension)
end)

for _, colshape in ipairs(getElementsByType("colshape")) do
	for _, element in ipairs(colshape:getElementsWithin()) do
		handleColShapeHit(colshape, element, element.dimension == colshape.dimension)
	end
end