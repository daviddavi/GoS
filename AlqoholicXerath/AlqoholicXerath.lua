class "AlqoholicXerath"

local _castingUlt = false
local _chargingQ = false
local _ultStacks = 0

function AlqoholicXerath:__init()
	if myHero.charName ~= "Xerath" then return end
	require('DamageLib')
	PrintChat("[AlqoholicXerath] Initiated")
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add('Tick', function() self:Tick() end)
	Callback.Add('Draw', function() self:Draw() end)
end

function AlqoholicXerath:LoadSpells()
	Q = {Range = 1550, Delay = 0.6, Speed = 1337000, Radius = 95, Collision = false}
	W = {Range = 1200, Delay = 0.7, Speed = 1337000, Radius = 125, Collision = false}
	E = {Range = 1000, Delay = 0.25, Speed = 1400, Radius = 60, Collision = true}
	R = {Range = 0, Delay = 0.7, Speed = 1337000, Radius = 130, Collision = false}
	PrintChat("[AlqoholicXerath] Spells Loaded")
end

function AlqoholicXerath:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "AlqoholicXerath", name = "Alqohol - AlqoholicXerath", lefticon="https://cdn.discordapp.com/emojis/249237025754972171.png"})

	-- [[Keys]]
	self.Menu:MenuElement({type = MENU, id = "Key", name = "Key Settings"})
	self.Menu.Key:MenuElement({id = "ComboKey", name = "Combo Key", key = 32})
	self.Menu.Key:MenuElement({id = "HarassKey", name = "Harass Key", key = 67})
	self.Menu.Key:MenuElement({id = "FarmKey", name = "Farm Key", key = 86})

	--[[Combo]]
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	self.Menu.Combo:MenuElement({id = "ComboQ", name = "Use Q", value = true})
	self.Menu.Combo:MenuElement({id = "ComboW", name = "Use W", value = true})
	self.Menu.Combo:MenuElement({id = "ComboE", name = "Use E", value = true})
	self.Menu.Combo:MenuElement({id = "ComboR", name = "Use R", key = 84})

	--[[Harass]]
	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	self.Menu.Harass:MenuElement({id = "HarassQ", name = "Use Q", value = true})
	self.Menu.Harass:MenuElement({id = "HarassW", name = "Use W", value = true})
	self.Menu.Harass:MenuElement({id = "HarassMana", name = "Min. Mana", value = 40, min = 0, max = 100})

	--[[Farm]]
	self.Menu:MenuElement({type = MENU, id = "Farm", name = "Farm Settings"})
	self.Menu.Farm:MenuElement({id = "FarmQ", name = "Use Q", value = true})
	self.Menu.Farm:MenuElement({id = "FarmW", name = "Use W", value = true})
	self.Menu.Farm:MenuElement({id = "FarmMana", name = "Min. Mana", value = 40, min = 0, max = 100})

	--[[Misc]]
	self.Menu:MenuElement({type = MENU, id = "Misc", name = "Misc Settings"})
	self.Menu.Misc:MenuElement({id = "MaxRange", name = "Max Range Limiter", value = 0.9, min = 0.5, max = 1, step = 0.01})
	self.Menu.Misc:MenuElement({type = SPACE, id = "ToolTip", name = "eg. X = 0.80 (Q.Range = (1150 * 0.80) = 920)"})
	self.Menu.Misc:MenuElement({type = SPACE, id = "TODO", name = "Need things to add - Give feedback."})

	--[[Draw]]
	self.Menu:MenuElement({type = MENU, id = "Draw", name = "Drawing Settings"})
	self.Menu.Draw:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	self.Menu.Draw:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.Menu.Draw:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.Menu.Draw:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.Menu.Draw:MenuElement({id = "DrawTarget", name = "Draw Target", value = true})

	PrintChat("[AlqoholicXerath] Menu Loaded")
end

function AlqoholicXerath:GetTarget(range)
	local target
	for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if self:IsValidTarget(hero, range) and hero.team ~= myHero.team then
      		target = hero
      		break
		end
	end
	return target
end

function AlqoholicXerath:GetFarmTarget(range)
	local target
	for j = 1,Game.MinionCount() do
		local minion = Game.Minion(j)
		if self:IsValidTarget(minion, range) and minion.team ~= myHero.team then
      		target = minion
      		break
		end
	end
	return target
end

function AlqoholicXerath:Tick()

	R.Range = 1200 * myHero:GetSpellData(_R).level + 2000

	if Utility:HasBuff(myHero, "XerathLocusOfPower2") then _castingUlt =  true else _castingUlt = false end
	if Utility:HasBuff(myHero, "xerathArcanopulseChargeUp") then _chargingQ = true else _chargingQ = false end
	if Utility:HasBuff(myHero, "xerathrshots") then _ultStacks = Utility:BuffStacks(myHero, "xerathrshots") else _ultStacks = 0 end

	if _castingUlt then
		for i=1,_ultStacks do
			DelayAction(
				function()
					self:CastR()
				end,
			0.75)
		end
		_castingUlt = false
		_ultStacks = 0
	end


	-- [COMBO]
	if self.Menu.Key.ComboKey:Value() then
		self:DoCombo()
	end

	-- [ULT]
	if self.Menu.Combo.ComboR:Value() and self:CanCast(_R) then
		Control.CastSpell(HK_R)
		DelayAction(
			function()
				self:CastR()
			end,
		1)
	end

	-- [HARASS]
	if self.Menu.Key.HarassKey:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Harass.HarassMana:Value()/100) then
		self:DoHarass()
	end

	-- [FARM]
	if self.Menu.Key.FarmKey:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Farm.FarmMana:Value()/100) then
		self:DoFarm()
	end

end

function AlqoholicXerath:DoCombo()
	if self.Menu.Combo.ComboQ:Value() and self:CanCast(_Q) then
		self:CastQ("hero")
	end

	if self.Menu.Combo.ComboW:Value() and self:CanCast(_W) then
		self:CastW("hero")
	end

	if self.Menu.Combo.ComboE:Value() and self:CanCast(_E) then
		self:CastE()
	end
end

function AlqoholicXerath:DoHarass()
	if self.Menu.Harass.HarassQ:Value() and self:CanCast(_Q) then
		self:CastQ("hero")
	end
	
	if self.Menu.Harass.HarassW:Value() and self:CanCast(_W) then
		self:CastW("hero")
	end

end

function AlqoholicXerath:DoFarm()
	if self.Menu.Farm.FarmQ:Value() and self:CanCast(_Q) then
		self:CastQ("minion")
	end

	if self.Menu.Farm.FarmW:Value() and self:CanCast(_W) then
		self:CastW("minion")
	end
end

function AlqoholicXerath:CastQ(objType)
	if objType == "hero" then
		local target = self:GetTarget(Q.Range * self.Menu.Misc.MaxRange:Value())
		if target then
			local castPos = target:GetPrediction(Q.Speed, Q.Delay)

			if castPos:DistanceTo(myHero) <= 400 then
				Control.CastSpell(HK_Q, castPos)
			end
			if castPos:DistanceTo(myHero) > 400 then
				local distance = castPos:DistanceTo(myHero)
				local speed = 800 / 1.5
				local time = (distance / speed)
				Control.KeyDown(HK_Q)
				PrintChat(distance)
				DelayAction(
					function()
						Control.CastSpell(HK_Q, castPos)
					end, 
				time)
			end
		end
	end

	if objType == "minion" then
		local target = self:GetFarmTarget(Q.Range * self.Menu.Misc.MaxRange:Value())
		if target then
			local castPos = target:GetPrediction(Q.Speed, Q.Delay)

			if castPos:DistanceTo(myHero) <= 400 then
				Control.CastSpell(HK_Q, castPos)
			end
			if castPos:DistanceTo(myHero) > 400 then
				local distance = castPos:DistanceTo(myHero)
				local speed = 800 / 1.5
				local time = (distance / speed)
				Control.KeyDown(HK_Q)
				PrintChat(time)
				DelayAction(
					function()
						Control.CastSpell(HK_Q, castPos)
					end, 
				time)
			end
		end
	end
end

function AlqoholicXerath:CastW(objType)
	if objType == "hero" then
		local target = self:GetTarget(W.Range)
		if target then
			local castPos = target:GetPrediction(W.Speed, W.Delay)
			Control.CastSpell(HK_W, castPos)
		end
	end

	if objType == "minion" then
		local target = self:GetFarmTarget(W.Range * self.Menu.Misc.MaxRange:Value())
		if target then
			local castPos = target:GetPrediction(W.Speed, W.Delay)
			Control.CastSpell(HK_W, castPos)
		end
	end
end

function AlqoholicXerath:CastE()
	local target = self:GetTarget(E.Range * self.Menu.Misc.MaxRange:Value())
	if target and target:GetCollision(E.Radius, E.Speed, E.Delay) == 0 then
		local castPos = target:GetPrediction(E.Speed, E.Delay)
		Control.CastSpell(HK_E, castPos)
	end
end

function AlqoholicXerath:CastR()
	local target = self:GetTarget(2000)
	if target and Utility:IsValidTarget(target, 2000) then
		local castPos = target:GetPrediction(Q.Speed, Q.Delay)
		self:Fire(castPos, rCount)
	end
end

function AlqoholicXerath:Fire(target, rCount)
	if target then
		Control.CastSpell(HK_R, target)
	end
end

function AlqoholicXerath:IsReady(spellSlot)
	return myHero:GetSpellData(spellSlot).currentCd == 0 and myHero:GetSpellData(spellSlot).level > 0
end

function AlqoholicXerath:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function AlqoholicXerath:CanCast(spellSlot)
	return self:IsReady(spellSlot) and self:CheckMana(spellSlot)
end

function AlqoholicXerath:IsValidTarget(obj, spellRange)
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= spellRange
end

function AlqoholicXerath:Draw()
	if myHero.dead then return end

	if self.Menu.Draw.DrawQ:Value()	then
		Draw.Circle(myHero.pos,Q.Range * self.Menu.Misc.MaxRange:Value(),1,Draw.Color(255, 255, 255, 255))
	end
	if self.Menu.Draw.DrawW:Value()	then
		Draw.Circle(myHero.pos,W.Range * self.Menu.Misc.MaxRange:Value(),1,Draw.Color(255, 255, 255, 255))
	end
	if self.Menu.Draw.DrawR:Value()	then
		Draw.Circle(myHero.pos,R.Range * self.Menu.Misc.MaxRange:Value(),1,Draw.Color(255, 255, 255, 255))
	end

    if self.Menu.Draw.DrawTarget:Value() then
	    local drawTarget = self:GetTarget(Q.Range)
	    if drawTarget then
		    Draw.Circle(drawTarget.pos,80,3,Draw.Color(255, 255, 0, 0))
	    end
    end
end

function OnLoad()
	AlqoholicXerath()
end

class "Utility"

function Utility:HasBuff(unit, buffname)
	for K, Buff in pairs(self:GetBuffs(unit)) do
		if Buff.name:lower() == buffname:lower() then
			return true
		end
	end
	return false
end

function Utility:GetBuffs(unit)
	self.T = {}
	for i = 0, unit.buffCount do
		local Buff = unit:GetBuff(i)
		if Buff.count > 0 then
			table.insert(self.T, Buff)
		end
	end
	return self.T
end

function Utility:BuffStacks(unit, buffname)
	for K, Buff in pairs(self:GetBuffs(unit)) do
		if Buff.name:lower() == buffname:lower() then
			return Buff.stacks
		end
	end
	return 0
end

function Utility:IsValidTarget(obj, spellRange)
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= spellRange
end

Utility()