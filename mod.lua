function Mod:init()
    self:registerShaders()

    -- Accur acy
    MUSIC_PITCHES["deltarune/THE_HOLY"] = 0.9
    MUSIC_VOLUMES["deltarune/queen_car_radio"] = 0.8
    MUSIC_PITCHES["ruins_beta"] = 0.8

    MUSIC_VOLUMES["cybercity"] = 0.8
    MUSIC_PITCHES["cybercity"] = 0.97

    MUSIC_VOLUMES["cybercity_alt"] = 0.8
    MUSIC_PITCHES["cybercity_alt"] = 1.2

    self:initTaunt()

    -- taunt stuff for characters that use "walk" as their default sprite (i.e. party members and Sans)
    -- and characters that use "idle" as their default sprite (i.e. NPCs and such)
    self.taunt_sprites = {
        ['YOU'] = {"disappointed", "fell", "shoutoutstosimpleflips", "date", "date_flowey_4", "riot"},
        ['susie'] = {"pose", "away_hand", "turn_around", "angry_down", "diagonal_kick_left_5", "shock_right"},
        ['dess'] = {"reddit_gold", "sonic_adventure", "bup", "beatbox", "angreh", "oc", "paneton"},
        ['brandon'] = {"box"},
        ['kris'] = {"pose", "peace", "t_pose", "sit"},
        ['berdly'] = {"fall", "nerd", "drama", "shocked", "fell"},
        ['bor'] = {"pizza", "pizza_b", "kirby"},
        ['sans'] = {"shrug", "sleeping", "eyes", "bike", "wink"},
        ['velvetspam'] = self:isNight() and {"pissed", "bundled", "pipis"} or {"day_blankie", "day_blankie_hug", "box"}
    }

    self.voice_timer = 0
end

function Mod:registerShaders()
    self.shaders = {}
    for _,path,shader in Registry.iterScripts("shaders/") do
        assert(shader ~= nil, '"shaders/'..path..'.lua" does not return value')
        self.shaders[path] = shader
    end
end

function Mod:postInit(new_file)
    Mod:initializeImportantFlags(new_file)

    if new_file then
        Game.world:startCutscene("introcutscene")
    end
end
function Mod:initializeImportantFlags(new_file)
    if new_file then
        -- FUN Value
        Game:setFlag("fun", love.math.random(1, 100))
    end

    if new_file then
        Game:setFlag("vesselChosen", 0)

        Game:setFlag("weird", false)
        Game:setFlag("weirdEnemiesKilled", 0)

        Game:setFlag("timesUsedWrongBorDoorCode", 0)
        Game:setFlag("BorDoorCodeUnlocked", false)
        Game:setFlag("AddiSwitchOn", false)


        Game:setFlag("cloudwebStoryFlag", 0)
    end

    if new_file then
        Game:setFlag("YOU_party", true)
        Game:setFlag("susie_party", true)
    end

    if new_file
        or not Game:getFlag("party") --[[ will upgrade from a old save ]] then
        -- Unlocked party members for the Party Menu
        Game:setFlag("party", {"YOU", "susie"})
    end
end

function Mod:unload()
    if Mod.text_input_active then
        print("Warp Bin was open, ending text input to be safe")
        TextInput.endInput()
        Mod.text_input_active = false
    end
end

function Mod:onMapMusic(map, music)
    if Game:getFlag("cloudwebStoryFlag") == 1 and music == "cloudwebs" and map.id == "cloudwebs/cloudwebs_entrance" then
        return ""
    elseif Game:getFlag("weird") and music == "cybercity" then
        return "cybercity_alt"
    end
end

function Mod:preUpdate()
    self:updateVoiceTimer()
end

function Mod:postUpdate()
    self.taunt_sprites['velvetspam'] = self:isNight() and {"pissed", "bundled", "pipis"} or {"day_blankie", "day_blankie_hug", "box"}

    self:updateTaunt()

    if Game.save_name == "MERG" then
        for _, member in ipairs(Game.party) do
           if member.health > 1 then
              member.health = 1
           end
           if member.stats.health ~= 1 then
              member.stats.health = 1
           end
        end

        if Game.battle and Game.battle.soul and not Game.gameover then
           for _, member in ipairs(Game.battle.party) do
                if member.chara:getHealth() < member.chara:getStat("health") then
                    Game:gameOver(Game.battle.soul:getScreenPos())
                    break
                end
            end
        end
    end
end

function Mod:updateVoiceTimer()
    self.voice_timer = Utils.approach(self.voice_timer, 0, DTMULT)
end

function Mod:onTextSound(sound, node)
    if sound == "omori" then
        if self.voice_timer == 0 then
            local snd = Assets.playSound("voice/omori")
            snd:setPitch(0.9 + Utils.random(0.18))
            self.voice_timer = 1.1
        end
        return true
    end
end

modRequire("scripts/main/warp_bin")
modRequire("scripts/main/debugsystem")
modRequire("scripts/main/ow_taunt")

function Mod:onFootstep(char, num)
    if Game:getFlag("footsteps", false) and char == Game.world.player then
        if num == 1 then
            Assets.playSound("step1")
        elseif num == 2 then
            Assets.playSound("step2")
        end
    end
end

--- Returns a class of the leader of the party, either the Actor, Character or PartyMember ones
---@param class? string Either "character", "chara", "sprite", "actorsprite" or "actor". Will changes what class the function returns
---@return PartyMember|Character|ActorSprite|Actor leader_obj A class from the leader.
function Mod:getLeader(class)
    local leader = Game.party[1]
    if class then
        if class:lower() == "character" or class:lower() == "chara" then
            return Game.world:getCharacter(leader.id)
        elseif class:lower() == "sprite" or class:lower() == "actorsprite" then
            return Game.world:getCharacter(leader.id).sprite
        elseif class:lower() == "actor" then
            return leader.actor
        end
    end
    return leader
end

function Mod:isInRematchMode()
    return Game.world.map.id == "thearena"
end

function Mod:setOmori(omori)
    omori = omori or false
    self.omori = omori
end

function Mod:isOmori()
    return self.omori
end

function Mod:getUISkin()
    if self:isOmori() then
        return "omori"
    end
end

function Mod:isNight()
    local hour = os.date("*t").hour
    return hour < 8 or hour >= 21
end

Utils.hook(EnemyBattler, "hurt", function(orig, self, amount, battler, on_defeat, color, showStatusMsg)
    self.health = self.health - amount
    local showstatus = showStatusMsg or true
    if showstatus then
        self:statusMessage("damage", amount, color or (battler and {battler.chara:getDamageColor()}))
    end

    self.hurt_timer = 1
    self:onHurt(amount, battler)

    self:checkHealth(on_defeat, amount, battler)
end)

function Mod:SwitchOn()
    Game:getFlag("AddiSwitchOn", true)
        return Game:getFlag("AddiSwitchOn")
end
