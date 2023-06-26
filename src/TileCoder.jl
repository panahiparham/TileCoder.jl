module TileCoder

using Random


greet() = print("Hello World!")


# Type Aliases

Optional = x -> Union{x, Nothing}
Range = Tuple{Float64, Float64}


# release exports
export TileCoderConfig
export TC

export get_indices
export features
export encode


# test exports
export _normalize_tiles
export _normalize_scalars
export _build_offset
export apply_bounds
export get_tiling_index
export get_tc_indices


# Logic

struct TileCoderConfig
    tiles:: Union{Int, Array{Int}}
    tilings:: Int
    dims:: Int
    offset:: String
    scale_output:: Bool
    input_ranges:: Optional(Array{Range})
    bound:: String

    function TileCoderConfig(tiles, tilings, dims; offset = "cascade", scale_output = true, input_ranges = nothing, bound = "clip")
            @assert bound in ["wrap", "clip"]
            return new(tiles, tilings, dims, offset, scale_output, input_ranges, bound)
        end
end

mutable struct TC
    _c:: TileCoderConfig
    rng:: Optional(AbstractRNG)
    ranges:: Array{Union{Range, Nothing}}
    _tiles:: Any
    _input_ranges
    _tiling_offsets:: Array
    _total_tiles:: Int
    _wrap_tiles:: Bool

    function TC(c, rng = nothing)

        ranges = [nothing for _=1:c.dims]
        if c.input_ranges !== nothing
            @assert length(c.input_ranges) == c.dims
            ranges = c.input_ranges
        end

        _tiles = _normalize_tiles(c.tiles, c.dims)
        _input_ranges = _normalize_scalars(ranges)
        _tiling_offsets = vcat([_build_offset(ntl, _tiles, c, rng) for ntl=0:c.tilings-1]...)
        _total_tiles = Int(c.tilings * prod(_tiles))
        if c.bound == "wrap"
            _wrap_tiles = true
        elseif c.bound == "clip"
            _wrap_tiles = false
        else
            error("Unknown bound type")
        end
        # wrap or clip are the same along all dims


        return new(c, rng, ranges, _tiles, _input_ranges, _tiling_offsets, _total_tiles, _wrap_tiles)
    end
end


# public functions

function get_indices(tc::TC, pos::Array{Float64})
    return get_tc_indices(tc._c.dims, tc._tiles, tc._c.tilings, tc._input_ranges, tc._tiling_offsets, tc._wrap_tiles, pos)
end

function features(tc::TC)
    return tc._total_tiles
end

function encode(tc::TC, s::Array)
    indices = get_indices(tc, s)
    vec = zeros(features(tc))
    v = 1.
    if tc._c.scale_output
        v = 1. / tc._c.tilings
    end
    vec[indices] .= v
    return vec
end


# private functions

function _normalize_tiles(tiles::Union{Int, Array{Int}}, dims::Int) :: Array
    if typeof(tiles) == Int
        tiles = [tiles for _=1:dims]
    end

    x = Array{Int, 2}(undef, 1, dims)
    for i=1:dims
        x[i] = tiles[i]
    end
    return x
end


function _normalize_scalars(sc)
    out:: Vector{Range} = []
    for r in sc
        if r === nothing
            push!(out, (0., 1.))
        else
            push!(out, r)
        end
    end

    x = Array{Float64, 2}(undef, 2, length(out))
    for i=eachindex(out)
        x[1, i] = out[i][1]
        x[2, i] = out[i][2]
    end

    return x
end


# construct tiling offsets
function _build_offset(n::Int, tiles::Array, c::TileCoderConfig, rng::Optional(AbstractRNG))
    if c.offset == "cascade"
        tile_length = 1.0 ./ tiles
        return (n / c.tilings) .* tile_length
    end

    if c.offset == "even"
        tile_length = 1.0 ./ tiles
        i = n - (c.tilings / 2)
        return (i / c.tilings) .* tile_length
    end

    if c.offset == "random"
        @assert rng !== nothing
        return rand(rng, 1, length(tiles))
    end

    error("Unknown offset type")
end



function get_tc_indices(dims::Int, tiles::Array, tilings::Int, bounds::Array, offsets::Array, wrap_tiles::Bool, pos::Array) :: Array
    pos = apply_bounds(pos, bounds)
    res = Array{Int, 1}(undef, tilings)
    tiles_per_tiling = prod(tiles)

    # println("offsets: ", size(offsets), typeof(offsets))
    # offsets: (16, 4)Matrix{Float64}

    for ntl=1:tilings
        tmp = copy(pos)
        for i=axes(tmp, 1)
            tmp[i] += offsets[ntl, i]
        end
        ind = get_tiling_index(dims, tiles_per_tiling, tiles, wrap_tiles, tmp)
        println(ind)
        res[ntl] = ind + tiles_per_tiling * (ntl - 1)
    end
    return res
end

function apply_bounds(pos::Array, bounds::Array) :: Array
    for i=1:length(pos)
        pos[i] = minmax_scale(pos[i], bounds[:, i])
    end
    return pos
end

function minmax_scale(pos::Float64, bound::Array) :: Float64
    return (pos - bound[1]) / (bound[2] - bound[1])
end

function get_tiling_index(dims::Int, tiles_per_tiling::Int, tiles::Array, wrap_tiles::Bool, arr::Array) :: Int
    t = tiles_per_tiling
    ind = 1
    for i=1:dims
        if wrap_tiles
            id_along_axis = floor(arr[i] * tiles[i]) % tiles[i]
        else
            id_along_axis = min(max(floor(arr[i] * tiles[i]), 0),tiles[i]-1)     
        end
        t = t / tiles[i]
        ind = ind + id_along_axis * t
    end
    return ind
end



end # module TileCoder
