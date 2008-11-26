Countdown = {}
function Countdown:__index(k)
	if Countdown[k] then
		return Countdown[k]
	end
	if k == 'client' then
		self.client = { hooks = {} }
		return self.client
	end
end

Countdown.instances = {}
Countdown.clientinstances = {}

function Countdown.create(start, endFunction, text, r, g, b, ...)
	local result = setmetatable(
		{
			startvalue = start or 5,
			text = text,
			r = r,
			g = g,
			b = b,
			hooks = {},
			texts = {}
		},
		Countdown
	)
	result:setValueText(0, '')
	if endFunction then
		result:addHook(0, endFunction, ...)
	end
	return result
end

function Countdown:addHook(value, fn, ...)
	if not self.hooks[value] then
		self.hooks[value] = {}
	end
	table.insert(self.hooks[value], { fn = fn, args = {...} })
end

function Countdown:addClientHook(value, fnName, ...)
	if not self.client.hooks[value] then
		self.client.hooks[value] = {}
	end
	table.insert(self.client.hooks[value], { fn = fnName, args = {...} })
end

function Countdown:setValueText(value, text)
	self.texts[value] = text
end

function Countdown:clientCall(player, fn, ...)
	clientCall(player, 'Countdown.call', self.client.id, fn, ...)
end

function Countdown:setBackground(file, width, height)
	self.client.background = { file = file, width = width, height = height }
end

function Countdown:useImages(namePattern, width, height)
	self.client.images = { namepattern = namePattern, width = width, height = height }
end

function Countdown:enableFade(enable)
	self.client.fade = enable
end

function Countdown:isClient()
	return rawget(self, 'client') and true
end

function Countdown:start(player)
	self.value = self.startvalue
	self.id = #Countdown.instances + 1
	Countdown.instances[self.id] = self
	
	if self:isClient() then
		self.client.id = #Countdown.clientinstances + 1
		Countdown.clientinstances[self.client.id] = self
		self.client.startvalue = self.startvalue
		self:clientCall(player or g_Root, 'start', self.client)
		self.client.player = player or g_Root
	else
		self.display = textCreateDisplay()
		if self.text then
			self.textitem = textCreateTextItem(self.text, 0.5, 0.49, 'medium', self.r or 255, self.g or 0, self.b or 0, 255, 2, 'center', 'bottom')
			textDisplayAddText(self.display, self.textitem)
		end
		self.countitem = textCreateTextItem('', 0.5, self.text and 0.51 or 0.5, 'medium', self.r or 255, self.g or 0, self.b or 0, 255, 2, 'center', 'top')
		textDisplayAddText(self.display, self.countitem)
		
		if player then
			textDisplayAddObserver(self.display, player)
		else
			for i,player in ipairs(getElementsByType('player')) do
				textDisplayAddObserver(self.display, player)
			end
		end
	end
	self.timer = setTimer(Countdown.update, 1000, self.startvalue+1, self.id)
	self:update()
end

function Countdown:update()
	if type(self) ~= 'table' then
		self = Countdown.instances[self]
	end
	if self:isClient() then
		self:clientCall(self.client.player, 'update')
	end
	if self.value == -1 then
		self.timer = nil
		self:destroy()
		return
	end
	local hooks = self.hooks[self.value]
	if hooks then
		for i,hook in ipairs(hooks) do
			hook.fn(unpack(hook.args))
		end
	end
	if not self:isClient() then
		textItemSetText(self.countitem, self.texts[self.value] or tostring(self.value))
	end
	self.value = self.value - 1
end

function Countdown:destroy()
	if type(self) ~= 'table' then
		self = Countdown.instances[self]
	end
	if self:isClient() then
		Countdown.clientinstances[self.client.id] = nil
		self.client.id = nil
		self.client.player = nil
	else
		textDestroyDisplay(self.display)
		self.display = nil
		textDestroyTextItem(self.textitem)
		self.textitem = nil
		textDestroyTextItem(self.countitem)
		self.countitem = nil
	end
	Countdown.instances[self.id] = nil
	if self.timer then
		killTimer(self.timer)
		self.timer = nil
	end
	self.id = nil
end

function Countdown.destroyAll()
	for id,countdown in pairs(Countdown.instances) do
		countdown:destroy()
	end
end