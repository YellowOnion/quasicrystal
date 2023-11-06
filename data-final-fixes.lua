local noise = require("noise")
local expression_to_ascii_math = require("noise.expression-to-ascii-math")
local tne = noise.to_noise_expression
local litexp = noise.literal_expression

local resources = data.raw["resource"]

local ores = {}
local i = 0

local scale = 32

for n, e in pairs(resources) do
  if e and e.autoplace then
    log("Patching: " .. n)
    ores[n] = e
    i = i + 1
  end
end

local amount = i

i = 0

local function make_noise_func(x, y, i, scale, amount)
    local theta = 2 * math.pi * i / (amount + 1)
    x = x / scale
    y = y / scale
    local sym = 7
    local sum = 0
    for j = 0, sym - 1, 1 do
        sum = sum + noise.cos(noise.cos(theta + math.pi * j / sym)*x + noise.sin(theta + math.pi * j / sym)*y)
    end
    sum = sum / sym
    return  sum / 2 + 0.5
end

for n, e in pairs(ores) do
  e.autoplace.probability_expression = noise.define_noise_function(
    function(x, y, tile, map)
    return noise.less_than(0.5, make_noise_func(x, y, i, scale, amount))
  end) * e.autoplace.probability_expression
  i = i + 1
end

data:extend{
  {
    type = "noise-expression",
    name = "quasicrystal",
    intended_property = "elevation",
    expression = noise.define_noise_function(function(x, y, tile, map)
            return noise.max(noise.ridge(25*make_noise_func(x,y, i, scale * 1/map.segmentation_multiplier, amount) - 12, -20, 20) + (map.wlc_elevation_offset / 6), map.wlc_elevation_minimum)
    end)
  }
}
