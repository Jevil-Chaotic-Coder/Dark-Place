function Mod:init()
    -- Accur acy
    MUSIC_PITCHES["deltarune/cybercity_alt"] = 1.2
    MUSIC_PITCHES["deltarune/THE_HOLY"] = 0.9
end

function Mod:postInit(new_file)
    if new_file then
        -- FUN Value
        Game:setFlag("fun", love.math.random(1, 100))

        if Game:hasPartyMember("YOU") then
            Game.world:startCutscene("room1", "react_to_YOU")
        end
    end
end

-- Warp Bin
-- god I am so sorry for how shitty this code is

-- I'm going to cause pain and suffering with one weird trick:
-- here's the table containing any and all warp codes for the warp bin
-- have fun :]   -Char
-- Also for reference: first in a table is the code, second in a table is the result, and third in a table is the marker you wanna go (optional but defaults to spawn).
-- If the result is a string then it goes to that map, if the last argument is a function it will run the function.
Mod.warp_bin_codes = {
    ["00000000"] = { result = "warphub" },
    ["spamroom"] = { result = "spamroom" },
    ["desshere"] = { result = "dessstuff/dessstart" },
    ["wtf1998s"] = {
        result = function(cutscene)
            cutscene:text("* Wow![wait:10]\n* You found a secret![wait:10]\n* Awesome!")
            Mod:addBinCode("sppispod", function(cutscene2)
                cutscene2:text({
                    "* Since you found another one...",
                    "* Here's a fun fact:",
                    "* This was made as a way to showcase what the warp bin can do!"
                })
            end)
        end
    },
    ["bossrush"] = { result = "thearena" },
    ["devdiner"] = { result = "devstart" },
}

-- if you don't want to be cringe there's also this new totally cool helper function wowee
-- also returns success just in-case someone else steals your code before you get to use it.
function Mod:addBinCode(code, result, marker)
    if Mod:getBinCode(code) then
        -- whoops, no success
        return false
    end

    -- lmao
    Mod.warp_bin_codes[code:lower()] = { result = result, marker = marker or "spawn" }
    return true
end

-- and here's a function to get a Bin Code by its Code like lmao
function Mod:getBinCode(code)
    return Mod.warp_bin_codes[code:lower()]
end

-- and here's one to delete Bin Codes
function Mod:deleteBinCode(code)
    code = code:lower()

    if not Mod:getBinCode(code) then return false end
    Mod.warp_bin_codes[code] = nil
    return true
end

-- Wavy VFX

Mod.wave_shader = love.graphics.newShader([[
    extern number wave_sine;
    extern number wave_mag;
    extern number wave_height;
    extern vec2 texsize;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        number i = texture_coords.y * texsize.y;
        vec2 coords = vec2(max(0.0, min(1.0, texture_coords.x + (sin((i / wave_height) + (wave_sine / 30.0)) * wave_mag) / texsize.x)), max(0.0, min(1.0, texture_coords.y + 0.0)));
        return Texel(texture, coords) * color;
    }
]])

-- Other utilties

function Mod:getPartyMemberIfInParty(chara)
    return Game:hasPartyMember(chara) and Game:getPartyMember(chara) or nil
end

function Mod:getKris()
    local YOU = Mod:getPartyMemberIfInParty("YOU")
    local kris = Mod:getPartyMemberIfInParty("kris")
    return YOU or kris
end

function Mod:getKrisActor()
    return Game.world:getCharacter(Mod:getKris().id)
end

function Mod:isInTheArena()
    return Game.world.map.id == "thearena"
end

-- Debug Menu options

---@param debug DebugSystem
function Mod:registerDebugOptions(debug)
    -- Stole this idea from ULCA Deltarune
    debug:registerOption("main", "Replenish Party", "Replenishes health.", function()
        if Game.battle then
            for _,party in ipairs(Game.battle.party) do
                party:heal(math.huge)
            end
        else
            for i, chara in ipairs(Game.party) do
                local prev_health = chara:getHealth()
                chara:heal(math.huge, false)
                local amount = chara:getHealth() - prev_health

                if not Game:isLight() and Game.world.healthbar then
                    local actionbox = Game.world.healthbar.action_boxes[i]
                    local text = HPText("+" .. amount, Game.world.healthbar.x + actionbox.x + 69, Game.world.healthbar.y + actionbox.y + 15)
                    text.layer = WORLD_LAYERS["ui"] + 1
                    Game.world:addChild(text)
                end
            end

            Assets.stopAndPlaySound("power")
        end
    end)
end