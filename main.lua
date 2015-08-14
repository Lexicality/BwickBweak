local bounds = {
	x = 800;
	y = 600;
}

function new(wot, ...)
	local instance = setmetatable({}, {__index = wot});
	if instance.ctor then
		instance:ctor(...)
	end
	return instance;
end

----------------------------------
--                              --
--            Colour            --
--                              --
----------------------------------
local Colour = {
	r = 255;
	g = 255;
	b = 255;
	a = 255;
}

function Colour:ctor(r, g, b, a)
	if r then
		self.r = r;
	end
	if g then
		self.g = g;
	end
	if b then
		self.b = b;
	end
	if a then
		self.a = a;
	end
end

function Colour:unpack()
	return self.r, self.g, self.b, self.a;
end

-- Debugging Statix
Colour.RED = new(Colour, 255, 0, 0);
Colour.BLUE = new(Colour, 0, 255, 0);
Colour.Green = new(Colour, 0, 0, 255);

----------------------------------
--                              --
--            Player            --
--                              --
----------------------------------

local Player = {
	x = 0;
	y = 0;
	pos = 0;
	width = 100;
	height = 10;
	speed = 200;
	keys = {};
	colour = {};
};

function Player:ctor()
	self.keys = {};
	self.colour = new(Colour);
end

function Player:load()
	self.x = math.floor(bounds.x / 2 - self.width / 2);
	self.y = bounds.y-self.height-20
end

function Player:draw()
	love.graphics.setColor(255,255,255);
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height);
end

function Player:update(dt)
	local move = dt * self.speed;
	if self.keys.left and self.keys.right then
		-- do nothing
	elseif self.keys.left then
		self.x = self.x - move;
	elseif self.keys.right then
		self.x = self.x + move;
	end
	if self.x < 0 then
		self.x = 0;
	elseif self.x + self.width > bounds.x then
		self.x = bounds.x  - self.width;
	end
end

----------------------------------
--                              --
--             Ball             --
--                              --
----------------------------------
local Ball = {
	x = 0;
	y = 0;
	vx = 0;
	vy = 0;
	-- angle = 0;
	velocity = 0;
	size = 10;
	colour = {};
	paddleStuck = false;
}

function Ball:ctor()
	self.colour = new(Colour);
end

function Ball:load()
end

function Ball:update(dt)
	local dx, dy;
	local vx, vy = self:getHeading();
	local velocity = self.velocity * dt;
	dx = vx * velocity;
	dy = vy * velocity;
	local x, y;
	local size = self.size;
	x = self.x + dx;
	y = self.y + dy;

	-- Bounds checking.
	-- TODO: This needs to bounce!
	if x - size < 0 then
		x = size;
		self:setHeading(-vx, vy);
	elseif x + size > bounds.x then
		x = bounds.x - size;
		self:setHeading(-vx, vy);
	end

	if y - size < 0 then
		y = size;
		self:setHeading(vx, -vy);
	elseif y + size > bounds.y then
		y = bounds.y - size;
		self:setHeading(vx, -vy);
	end

	self.x = x;
	self.y = y;
end

function Ball:draw()
	love.graphics.setColor(self.colour:unpack())
	local size = self.size;
	love.graphics.rectangle("fill", self.x - size, self.y - size, size * 2, size * 2)
end

function Ball:stickToPaddle(paddle)
	local standoff = 10;
	self.x = paddle.x + paddle.width / 2;
	self.y = paddle.y - standoff - self.size;
	self.paddleStuck = true;
end

function Ball:setAngle(angle)
	self.vx = -math.sin(angle);
	self.vy = -math.cos(angle);
end

function Ball:getAngle()
	return math.atan2(-self.vx, -self.vy);
end

function Ball:setHeading( vx, vy )
	self.vx = vx;
	self.vy = vy;
end

function Ball:getHeading()
	return self.vx, self.vy;
end


----------------------------------
--                              --
--            Bricks            --
--                              --
----------------------------------
local Brick = {
	x = 0;
	y = 0;
	width = 60;
	height = 20;
	colour = {};
}

function Brick:ctor(x, y, r, g, b, a)
	if x then
		self.x = x;
	end
	if y then
		self.y = y;
	end
	self.colour = new(Colour, r, g, b, a);
end

function Brick:draw()
	love.graphics.setColor(self.colour:unpack());
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height);
end


------------------------------
------------------------------
------------------------------
------------------------------
------------------------------

local ply = new(Player);

local bricks = {};

local ball;

function love.load()
	ply:load()
	local spacing = 12;
	local x, y, j = 10, 10, 5;
	while true do
		bricks[#bricks + 1] = new(Brick, x, y);
		x = x + Brick.width + spacing;
		if x + Brick.width > bounds.x then
			x = 10;
			y = y + Brick.height + spacing;
			j = j - 1;
			if j == 0 then
				break
			end
		end
	end

	ball = new(Ball);
	ball:stickToPaddle(ply);

	-- test
	local angle = 2;
	ball:setAngle(angle);
	local wrong = ball:getAngle();
	assert(wrong == angle, "Expected " .. wrong .. " to equal " .. angle);
end

function love.update(dt)
	ply:update(dt);
	-- for _, brick in ipairs(bricks) do
	-- 	brick:update(dt#);
	-- end
	if ball.paddleStuck then
		if ply.keys.up then
			ball.paddleStuck = false;
			ball:setAngle(math.pi / 4);
			ball.velocity = 100;
		else
			ball:stickToPaddle(ply)
		end
	else
		ball:update(dt);
	end
end

local function drawDebuggingLines()
	love.graphics.setColor(60, 60, 60);
	love.graphics.line(bounds.x * 0.25, 0, bounds.x * 0.25, bounds.y);
	love.graphics.line(bounds.x * 0.75, 0, bounds.x * 0.75, bounds.y);
	love.graphics.line(0, bounds.y * 0.25, bounds.x, bounds.y * 0.25);
	love.graphics.line(0, bounds.y * 0.75, bounds.x, bounds.y * 0.75);
	love.graphics.setColor(100, 100, 100);
	love.graphics.line(bounds.x/2, 0, bounds.x/2, bounds.y);
	love.graphics.line(0, bounds.y/2, bounds.x, bounds.y/2);
end

function love.draw()
	drawDebuggingLines();

	ply:draw();
	for _, brick in ipairs(bricks) do
		brick:draw();
	end
	ball:draw();
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end

	ply.keys[key] = true;
end

function love.keyreleased(key)
	ply.keys[key] = false;
end
