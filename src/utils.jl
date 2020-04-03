function open_plexoszip(zippath::String)
    xmlname = match(r"^(.+)\.zip$", basename(zippath)).captures[1] * ".xml"
    archive = open_zip(zippath)
    return archive, xmlname
end

function perioddata(archive::Archive)
    results = Dict{Int,Vector{UInt8}}()
    for filename in keys(archive)
        rgx = match(r"t_data_(\d).BIN", filename)
        isnothing(rgx) && continue
        data = archive[filename]
        results[parse(Int, rgx[1])] = data
    end
    return results
end

function getchildtext(name::String, e::Node)
    resultnode = findfirst("x:" * name, e, ["x"=>namespace(e)])
    isnothing(resultnode) && error("$e does not have child $name")
    return nodecontent(resultnode)
end

getchildfloat(name::String, e::Node) = parse(Float64, getchildtext(name, e))
getchildint(name::String, e::Node) = parse(Int, getchildtext(name, e))
getchildbool(name::String, e::Node) = parse(Bool, getchildtext(name, e))


# Write from DataFrame

function string_table!(
    f::HDF5Group, tablename::String, strlen::Int,
    colnames::NTuple{N,String}, data::Vector{NTuple{N,String}}) where N

    nrows = length(data)

    stringtype_id = HDF5.h5t_copy(HDF5.hdf5_type_id(String))
    HDF5.h5t_set_size(stringtype_id, strlen)
    stringtype = HDF5.HDF5Datatype(stringtype_id)

    dt_id = HDF5.h5t_create(HDF5.H5T_COMPOUND, N * strlen)
    for (i, colname) in enumerate(colnames)
        HDF5.h5t_insert(dt_id, colname, (i-1)*strlen, stringtype)
    end

    strings = vcat(collect.(data)...)
    charlists = convertstring.(strings, strlen)
    rawdata = UInt8.(vcat(charlists...))

    dset = HDF5.d_create(f, tablename, HDF5.HDF5Datatype(dt_id),
                    HDF5.dataspace((nrows,)))
    HDF5.h5d_write(
        dset, dt_id, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, rawdata)

    return

end

convertstring(s::AbstractString, strlen::Int) =
    Vector{Char}.(rpad(ascii(s), strlen, '\0')[1:strlen])

sanitize(s::AbstractString) = replace(lowercase(ascii(s)), " " => "")
