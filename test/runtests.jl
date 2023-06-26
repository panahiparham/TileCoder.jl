using TileCoder
using Test
using Random

@testset "TileCoder" begin

    # TileCoderConfig

    @test TileCoderConfig(1, 2, 3) === TileCoderConfig(1, 2, 3)
    @test TileCoderConfig(1, 2, 3).tiles == 1
    @test TileCoderConfig(1, 2, 3).tilings == 2
    @test TileCoderConfig(1, 2, 3).dims == 3
    @test TileCoderConfig(1, 2, 3).offset == "cascade"
    @test TileCoderConfig(1, 2, 3).scale_output == true
    @test TileCoderConfig(1, 2, 3).input_ranges === nothing
    @test TileCoderConfig(1, 2, 3).bound == "clip"
    @test TileCoderConfig([1 2 3], 2, 3).tiles == [1 2 3]
    @test TileCoderConfig(1, 2, 3; input_ranges = [(0.0, 1.0), (1.0, 2.5), (0.0, 1.0)]).input_ranges == [(0.0, 1.0), (1.0, 2.5), (0.0, 1.0)]



    # TileCoder

    c = TileCoderConfig(1, 2, 3)

    @test TC(c)._c == c
    @test TC(c).rng === nothing

    @test TC(c, MersenneTwister(1234))._c == c
    @test TC(c, MersenneTwister(1234)).rng == MersenneTwister(1234)


    @test TC(c).ranges == [nothing, nothing, nothing]
    @test TC(TileCoderConfig(1, 2, 3; input_ranges = [(0.0, 1.0), (1.0, 2.5), (0.0, 1.0)])).ranges == [(0.0, 1.0), (1.0, 2.5), (0.0, 1.0)]

    c = TileCoderConfig(2, 2, 5)
    @test TC(c)._tiles == [2 2 2 2 2]


    c = TileCoderConfig(4, 2, 3)
    @test size(TC(c)._input_ranges) == (2, 3)


    # _normalize_tiles
    @test _normalize_tiles(3, 2) == [3 3]
    @test _normalize_tiles([3 4], 2) == [3 4]

    # _normalize_scalars
    @test _normalize_scalars([(0., 10.), nothing, (0., 5.)]) == [0. 0. 0.; 10. 1. 5.]


    # _build_offset
    tc = TC(TileCoderConfig(2, 3, 4; offset="cascade"))

    @test size(tc._tiling_offsets) == (3, 4)
    @test tc._tiling_offsets[1, 1] == 0.0
    @test tc._tiling_offsets[1, 2] == 0.0
    @test tc._tiling_offsets[1, 3] == 0.0
    @test tc._tiling_offsets[1, 4] == 0.0

    @test tc._tiling_offsets[2, 1] == 0.5 * (1/3)
    @test tc._tiling_offsets[2, 2] == 0.5 * (1/3)
    @test tc._tiling_offsets[2, 3] == 0.5 * (1/3)
    @test tc._tiling_offsets[2, 4] == 0.5 * (1/3)

    @test tc._tiling_offsets[3, 1] == 0.5 * (2/3)
    @test tc._tiling_offsets[3, 2] == 0.5 * (2/3)
    @test tc._tiling_offsets[3, 3] == 0.5 * (2/3)
    @test tc._tiling_offsets[3, 4] == 0.5 * (2/3)


    tc = TC(TileCoderConfig(2, 3, 4; offset="random"), MersenneTwister(1234))
    @test size(tc._tiling_offsets) == (3, 4)
    @test tc._tiling_offsets[1, 1] < 1.0 && tc._tiling_offsets[1, 1] >= 0.0
    @test tc._tiling_offsets[1, 2] < 1.0 && tc._tiling_offsets[1, 2] >= 0.0
    @test tc._tiling_offsets[1, 3] < 1.0 && tc._tiling_offsets[1, 3] >= 0.0
    @test tc._tiling_offsets[1, 4] < 1.0 && tc._tiling_offsets[1, 4] >= 0.0
    @test tc._tiling_offsets[2, 1] < 1.0 && tc._tiling_offsets[2, 1] >= 0.0
    @test tc._tiling_offsets[2, 2] < 1.0 && tc._tiling_offsets[2, 2] >= 0.0
    @test tc._tiling_offsets[2, 3] < 1.0 && tc._tiling_offsets[2, 3] >= 0.0
    @test tc._tiling_offsets[2, 4] < 1.0 && tc._tiling_offsets[2, 4] >= 0.0
    @test tc._tiling_offsets[3, 1] < 1.0 && tc._tiling_offsets[3, 1] >= 0.0
    @test tc._tiling_offsets[3, 2] < 1.0 && tc._tiling_offsets[3, 2] >= 0.0
    @test tc._tiling_offsets[3, 3] < 1.0 && tc._tiling_offsets[3, 3] >= 0.0
    @test tc._tiling_offsets[3, 4] < 1.0 && tc._tiling_offsets[3, 4] >= 0.0


    tc = TC(TileCoderConfig(2, 3, 4; offset="even"))
    @test size(tc._tiling_offsets) == (3, 4)

    @test tc._tiling_offsets[1, 2] <= 0.25 && tc._tiling_offsets[1, 2] >= -0.25
    @test tc._tiling_offsets[2, 3] <= 0.25 && tc._tiling_offsets[2, 3] >= -0.25
    @test tc._tiling_offsets[3, 4] <= 0.25 && tc._tiling_offsets[3, 4] >= -0.25


    # _total_tiles
    tc = TC(TileCoderConfig(2, 3, 4))
    @test tc._total_tiles == prod([2 2 2 2]) * 3


    tc = TC(TileCoderConfig([4 8 16], 10, 3))
    @test tc._total_tiles == prod([4 8 16]) * 10



    # features
    tc = TC(TileCoderConfig(2, 3, 4))
    @test features(tc) == prod([2 2 2 2]) * 3


    tc = TC(TileCoderConfig([4 8 16], 10, 3))
    @test features(tc) == prod([4 8 16]) * 10



    # get_indices


    # encode




    # apply_bounds
    pos = [0.3 0.5 1.3 -0.5]
    bounds = [0.0 0.0 0.0 0.0; 5.0 5.0 5.0 5.0]
    @test size(apply_bounds(pos, bounds)) == (1, 4)

    
    # get_tiling_idx
    @test get_tiling_index(1, 8, [8], true, [0.0]) == 1
    @test get_tiling_index(1, 8, [8], true, [0.49]) == 4
    @test get_tiling_index(1, 8, [8], true, [0.99]) == 8

    @test get_tiling_index(2, 4, [2 2], true, [0.0 0.0]) == 1
    @test get_tiling_index(2, 4, [2 2], true, [0.99 0.99]) == 4



    @test get_tiling_index(4, 256, [4 4 4 4], true, [0.0 0.0 0.0 0.0]) == 1
    @test get_tiling_index(4, 256, [4 4 4 4], true, [0.0 0.0 0.0 0.999]) == 4
    @test get_tiling_index(4, 256, [4 4 4 4], true, [0.0 0.0 0.999 0.999]) == 16
    # println(get_tiling_index(4, 256, [4 4 4 4], [0.8 0.7 -0.3 0.46]))


    # get_tc_indices
    # get_tc_indices(tc._c.dims, tc._tiles, tc._c.tilings, tc._input_ranges, tc._tiling_offsets, tc._wrap_tiles, pos)
    @test get_tc_indices(1, [8], 1, [0.; 1.;;], [0.], false, [0.0]) == [1]
    @test get_tc_indices(1, [8], 2, [0.; 1.;;], [0.; 0.;;], false, [0.0]) == [1, 9]
    @test get_tc_indices(1, [8], 1, [0.; 1.;;], [0.], false, [0.0]) == [1]



    # test tile coder
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

    @test features(tc) == tiles^dims * tilings
    x = get_indices(tc, arr)
    

    println(x)
    println(length(x))
    println(typeof(x))
    println(features(tc))

    # TODO: Make these an exact match to Andy's tile coder output
    
end