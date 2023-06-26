using TileCoder


tiles = 4
tilings=16
dims=4
input_ranges=[
    (0., 1.),
    (0., 1.),
    (-2., 2.),
    (-2., 2.),
]
arr = [0.99, 0.99, 1.99, 1.99]

c = TileCoderConfig(tiles, tilings, dims; input_ranges=input_ranges, scale_output = false, bound="wrap")
tc = TC(c)


println(get_indices(tc, arr))