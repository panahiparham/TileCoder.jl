using TileCoder
using Random


tiles = 4
tilings=16
dims=4
input_ranges=[
    (0., 1.),
    (0., 1.),
    (-2., 2.),
    (-2., 2.),
]
arr = [0.5, 0.99, 0.9, 1.99]

c = TileCoderConfig(tiles, tilings, dims; input_ranges=input_ranges, scale_output = false, bound="clip", offset="random")
tc = TC(c, MersenneTwister(1234))


println(get_indices(tc, arr))