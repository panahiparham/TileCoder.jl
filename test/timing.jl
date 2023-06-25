using TileCoder


tiles = 8
tilings=64
dims=6
input_ranges=[
    (0, 1),
    (0, 1),
    (0, 1),
    (0, 1),
    (0, 1),
    (0, 2),
]
arr = [0 1 2 3 4 5] ./ 6

c = TileCoderConfig(tiles, tilings, dims; input_ranges=input_ranges)
tc = TC(c)


@time get_indices(tc, arr)