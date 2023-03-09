function open_plexoszip(zippath::String, xmlname::String=defaultxml(zippath))

    resultsarchive = _open_plexoszip(zippath)
    xml = parsexml(resultsarchive[xmlname])

    data = PLEXOSSolutionDataset(xml)
    resultvalues = perioddata(resultsarchive)

    return data, resultvalues

end

function _open_plexoszip(zippath::String)
    isfile(zippath) || error("$zippath does not exist")
    archive = open_zip(zippath)
    return archive
end

defaultxml(zippath::String) = replace(basename(zippath), r".zip$"=>".xml")

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
    isnothing(resultnode) && return
    return nodecontent(resultnode)
end

function getchildfloat(name::String, e::Node)
    text = getchildtext(name, e)
    isnothing(text) && return
    return parse(Float64, text)
end

function getchildint(name::String, e::Node)
    text = getchildtext(name, e)
    isnothing(text) && return
    return parse(Int, text)
end

function getchildbool(name::String, e::Node)
    text = getchildtext(name, e)
    isnothing(text) && return
    return parse(Bool, text)
end
