SliderMenu = TuningMenu:subclass "SliderMenu"

local PARAM_CHANGE_SPEED = 1

function SliderMenu:init(headerText, labelText, position, rotation, bars)
	self.super:init(position, rotation, Vector2(1.4, 0.8))
	self.headerHeight = 70
	self.headerText = headerText

	self.labelHeight = 50

	self.barHeight = 20
	self.barOffset = 20

	self.bars = {
		{text = labelText, value = 0},
	}
	self.activeBar = 1
	self.price = 0
end

function SliderMenu:getValue()
	return self.bars[self.activeBar].value
end

function SliderMenu:setValue(value)
	if type(value) ~= "number" then
		return false
	end
	value = math.min(1, math.max(0, value))
	self.bars[self.activeBar].value = value
end

function SliderMenu:draw(fadeProgress)
	self.super:draw(fadeProgress)

	dxSetRenderTarget(self.renderTarget, true)
	dxDrawRectangle(0, 0, self.resolution.x, self.resolution.y, tocolor(42, 40, 41))
	dxDrawRectangle(0, 0, self.resolution.x, self.headerHeight, tocolor(32, 30, 31))
	dxDrawText(self.headerText, 20, 0, self.resolution.x, self.headerHeight, tocolor(255, 255, 255), 1, Assets.fonts.colorMenuHeader, "left", "center")
	
	local priceText = ""
	if self.price > 0 then
		priceText = "$" .. tostring(self.price)
	else
		priceText = exports.dpLang:getString("price_free")
	end
	dxDrawText(priceText, 0, 0, self.resolution.x - 20, self.headerHeight, tocolor(Garage.themePrimaryColor[1], Garage.themePrimaryColor[2], Garage.themePrimaryColor[3]), 1, Assets.fonts.colorMenuPrice, "right", "center")

	local y = self.headerHeight
	local barWidth = self.resolution.x - self.barOffset * 2
	for i, bar in ipairs(self.bars) do
		local cursorSize = 5
		local r, g, b, a = 255, 255, 255, 255
		if i == self.activeBar then
			cursorSize = 10
			r, g, b = Garage.themePrimaryColor[1], Garage.themePrimaryColor[2], Garage.themePrimaryColor[3]
		else
			a = 200
		end		

		-- Подпись
		dxDrawText(bar.text, 0, y, self.resolution.x, y + self.labelHeight, tocolor(255, 255, 255, a), 1, Assets.fonts.menuLabel, "center", "center")
		y = y + self.labelHeight

		-- Полоса
		if i == self.activeBar then
			dxDrawRectangle(self.barOffset - 1, y - 1, barWidth + 2, self.barHeight + 2, tocolor(255, 255, 255, 255))
		end
		dxDrawRectangle(self.barOffset, y, barWidth, self.barHeight, tocolor(32, 30, 31))
		
		-- Ползунок
		local x = (barWidth + 2) * bar.value
		x = self.barOffset + math.max(0, math.min(x, barWidth - cursorSize + 2)) - 1
		dxDrawRectangle(x, y - cursorSize, cursorSize, self.barHeight + cursorSize * 2, tocolor(r, g, b))	

		y = y + self.barHeight * 2
	end

	dxSetRenderTarget()
end


function SliderMenu:update(deltaTime)
	self.super:update(deltaTime)
end

function SliderMenu:selectNextBar()
	self.activeBar = self.activeBar + 1
	if self.activeBar > #self.bars then
		self.activeBar = 1
	end
end

function SliderMenu:selectPreviousBar()
	self.activeBar = self.activeBar - 1
	if self.activeBar < 1 then
		self.activeBar = #self.bars
	end
end

function SliderMenu:increase(dt)
	self.bars[self.activeBar].value = self.bars[self.activeBar].value + PARAM_CHANGE_SPEED * dt
	if self.bars[self.activeBar].value > 1 then
		self.bars[self.activeBar].value = 1
	end
end

function SliderMenu:decrease(dt)
	self.bars[self.activeBar].value = self.bars[self.activeBar].value - PARAM_CHANGE_SPEED * dt
	if self.bars[self.activeBar].value < 0 then
		self.bars[self.activeBar].value = 0
	end
end