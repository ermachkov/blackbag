SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 800

ZONE_SIZE = 80
MOVE_THRESHOLD = 40

WIDTH_PER_SCREEN = 15
DIAM_PER_SCREEN = 12
OFS_PER_SCREEN = 70

-----------------------------------------------------------

MOAISim.openWindow("BlackBag", SCREEN_WIDTH, SCREEN_HEIGHT)

layer = MOAILayer2D.new()
MOAISim.pushRenderPass(layer)

viewport = MOAIViewport.new()
viewport:setSize(SCREEN_WIDTH, SCREEN_HEIGHT)
viewport:setScale(SCREEN_WIDTH, SCREEN_HEIGHT)
layer:setViewport(viewport)

partition = MOAIPartition.new()
layer:setPartition(partition)

gfxQuad = MOAIGfxQuad2D.new()
gfxQuad:setTexture("dog.png")
gfxQuad:setRect(-SCREEN_WIDTH / 2, -SCREEN_HEIGHT / 2, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

prop = MOAIProp2D.new()
prop:setDeck(gfxQuad)
prop:setLoc(0, 0)
layer:insertProp(prop)

gfxQuad = MOAIGfxQuad2D.new()
gfxQuad:setTexture("bag.png")
gfxQuad:setRect(-64, -64, 64, 64)

bag = MOAIProp2D.new()
bag:setDeck(gfxQuad)
bag:setLoc(-550, 0)
layer:insertProp(bag)

font = MOAIFont.new()
font:load("arialbd.ttf")

style = MOAITextStyle.new()
style:setFont(font)
style:setSize(64)
style:setColor(1.0, 0.0, 0.0)

function addLabel(x, y, text)
	local textbox = MOAITextBox.new()
	textbox:setLoc(x, y)
	textbox:setRect(0, 0, SCREEN_WIDTH, 80)
	textbox:setString(text)
	textbox:setYFlip(true)
	textbox:setStyle(style)
	layer:insertProp(textbox)
	return textbox
end

width, diam, ofs = 6.5, 15, 140

widthLabel = addLabel(-600, 320, string.format("W = %.1f", width))
diamLabel = addLabel(-600, 260, string.format("D = %.1f", diam))
ofsLabel = addLabel(-600, 200, string.format("O = %d", ofs))

mouseX, mouseY = 0, 0
mouseDown = false
mouseZone = nil

testX, testY = 0, 0
testZone = nil

function getZone(x, y)
	if x > SCREEN_WIDTH / 2 - ZONE_SIZE then
		return "diam"
	elseif y > SCREEN_HEIGHT / 2 - ZONE_SIZE then
		return "width"
	elseif y < -SCREEN_HEIGHT / 2 + 40 + ZONE_SIZE then
		return "ofs"
	end
	return nil
end

function clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	end
	return value
end

function round(value, num)
	return math.floor((value + num / 2) / num) * num
end

function pointerCallback(x, y)
	local oldX, oldY = mouseX, mouseY
	mouseX, mouseY = layer:wndToWorld(x, y)
	if mouseDown then
		if math.abs(mouseX - testX) > MOVE_THRESHOLD or math.abs(mouseY - testY) > MOVE_THRESHOLD then
			mouseZone = testZone
		end

		local diffX, diffY = mouseX - oldX, mouseY - oldY
		if mouseZone == "width" then
			width = clamp(width + diffX / SCREEN_WIDTH * WIDTH_PER_SCREEN, 0, 20)
			widthLabel:setString(string.format("W = %.1f", round(width, 0.5)))
		elseif mouseZone == "diam" then
			diam = clamp(diam + diffY / SCREEN_HEIGHT * DIAM_PER_SCREEN, 0, 30)
			diamLabel:setString(string.format("D = %.1f", round(diam, 0.5)))
		elseif mouseZone == "ofs" then
			ofs = clamp(ofs + diffX / SCREEN_WIDTH * OFS_PER_SCREEN, 0, 300)
			ofsLabel:setString(string.format("O = %d", round(ofs, 1.0)))
		end

		if pick == bag then
			itemOffset = itemOffset + diffX
			local totalWidth = NUM_ITEMS * (ITEM_WIDTH + ITEM_INTERVAL)
			if itemOffset <= -totalWidth then
				itemOffset = itemOffset + totalWidth
			elseif itemOffset >= totalWidth then
				itemOffset = itemOffset - totalWidth
			end
			arrangeItems(itemOffset)
		end
	end
end

function clickCallback(down)
	mouseDown = down
	if mouseDown then
		testX, testY = mouseX, mouseY
		testZone = getZone(mouseX, mouseY)

		pick = partition:propForPoint(mouseX, mouseY)
		if pick == bag then
			itemsLayer:setVisible(true)
		end
	else
		mouseZone = nil
		pick = nil
		itemsLayer:setVisible(false)
	end
end

if MOAIInputMgr.device.pointer then	
	-- mouse input
	MOAIInputMgr.device.pointer:setCallback(pointerCallback)
	MOAIInputMgr.device.mouseLeft:setCallback(clickCallback)
else
	-- touch input
	MOAIInputMgr.device.touch:setCallback(
		function(eventType, idx, x, y, tapCount)
			pointerCallback(x, y)
			if eventType == MOAITouchSensor.TOUCH_DOWN then
				clickCallback(true)
			elseif eventType == MOAITouchSensor.TOUCH_UP then
				clickCallback(false)
			end
		end
	)
end

-----------------------------------------------------------

NUM_ITEMS = 7

ITEM_WIDTH = 147
ITEM_HEIGHT = 147
ITEM_INTERVAL = 10
ITEM_SCALE = 2.0

TOTAL_ITEMS_WIDTH = (NUM_ITEMS - 1) * ITEM_WIDTH + ITEM_SCALE * ITEM_WIDTH + NUM_ITEMS * ITEM_INTERVAL - 1

ITEMS_X = -547
ITEMS_Y = 0

itemOffset = 0

itemsLayer = MOAILayer2D.new()
MOAISim.pushRenderPass(itemsLayer)
itemsLayer:setViewport(viewport)
itemsLayer:setVisible(false)

local scLeft = ITEMS_X - ITEM_WIDTH / 2
local scRight = scLeft + TOTAL_ITEMS_WIDTH
local sc = MOAIScissorRect.new()
sc:setRect(scLeft, SCREEN_HEIGHT / 2, scRight, -SCREEN_HEIGHT / 2)

items = {}
for i = 1, NUM_ITEMS do
	local gfxQuad = MOAIGfxQuad2D.new()
	gfxQuad:setTexture(i .. ".png")
	gfxQuad:setRect(-ITEM_WIDTH / 2, -ITEM_HEIGHT / 2, ITEM_WIDTH / 2, ITEM_HEIGHT / 2)

	local prop = MOAIProp2D.new()
	prop:setDeck(gfxQuad)
	prop:setScissorRect(sc)
	itemsLayer:insertProp(prop)
	items[i] = prop

	prop = MOAIProp2D.new()
	prop:setDeck(gfxQuad)
	prop:setScissorRect(sc)
	itemsLayer:insertProp(prop)
	items[i - NUM_ITEMS] = prop

	prop = MOAIProp2D.new()
	prop:setDeck(gfxQuad)
	prop:setScissorRect(sc)
	itemsLayer:insertProp(prop)
	items[i + NUM_ITEMS] = prop
end

function arrangeItems(offset)
	local width = ITEM_WIDTH + ITEM_INTERVAL
	local x = ITEMS_X - NUM_ITEMS * width + offset
	local i1 = math.floor(NUM_ITEMS / 2) - math.floor(offset / width)
	local i2 = i1 + 1
	local coeff = (offset % width) / width
	local scale1 = 1.0 + coeff * (ITEM_SCALE - 1.0)
	local scale2 = 1.0 + (1.0 - coeff) * (ITEM_SCALE - 1.0)
	local ih = coeff > 0.5 and i1 or i2

	for i = -NUM_ITEMS + 1, 2 * NUM_ITEMS do
		local prop = items[i]
		local scale = i == i1 and scale1 or i == i2 and scale2 or 1.0
		prop:setLoc(x + ITEM_WIDTH * (scale - 1.0) / 2, ITEMS_Y)
		prop:setScl(scale)
		if i == ih then prop:setColor(1.0, 1.0, 1.0) else prop:setColor(0.5, 0.5, 0.5) end
		x = x + ITEM_WIDTH * scale + ITEM_INTERVAL
	end
end

arrangeItems(0)
