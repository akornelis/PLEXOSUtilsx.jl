# PLEXOSSolutionDatasetSummary

eval(Expr(
    :struct, true, :PLEXOSSolutionDatasetSummary, Expr(:block,
        [:($(t.fieldname)::Tuple{Int,Int}) for t in plexostables]...
    )
))

PLEXOSSolutionDatasetSummary() =
    PLEXOSSolutionDatasetSummary(((0,0) for _ in 1:length(plexostables))...)

# IndexCounter

eval(Expr(
    :struct, true, :IndexCounter, Expr(:block,
        [:($(t.fieldname)::Int) for t in plexostables if isnothing(t.identifier)]...
    )
))

IndexCounter() = IndexCounter(zeros(Int, length(fieldnames(IndexCounter)))...)

function increment!(x::IndexCounter, fieldname::Symbol)
    idx = getfield(x, fieldname) + 1
    setfield!(x, fieldname, idx)
    return idx
end

# PLEXOSSolutionDataset

eval(Expr(
    :struct, false, :(PLEXOSSolutionDataset <: AbstractDataset), Expr(:block,
        [:($(t.fieldname)::Vector{$(t.fieldtype)}) for t in plexostables]...
    )
))

function PLEXOSSolutionDataset(
    summary::PLEXOSSolutionDatasetSummary;
    consolidated::Bool=false)

    selector = consolidated ? first : last

    return PLEXOSSolutionDataset((
        Vector{eval(t.fieldtype)}(undef, selector(getfield(summary, t.fieldname)))
        for t in plexostables)...)

end

function PLEXOSSolutionDataset(xml::Document)

    summary = summarize(xml)
    result = PLEXOSSolutionDataset(summary, consolidated=false)
    idxcounter = IndexCounter()

    for loadorder in 1:7
        for element in eachelement(xml.root)

            # Ignore the band table
            element.name == "t_band" && continue

            table = plexostables_lookup[element.name]
            table.loadorder == loadorder || continue

            idx = if isnothing(table.identifier)
                      increment!(idxcounter, table.fieldname)
                  else
                      getchildint(table.identifier, element)
                  end
            table.zeroindexed && (idx += 1)

            getfield(result, table.fieldname)[idx] =
                eval(table.fieldtype)(element, result)

        end
    end

    return consolidate(result, summary)

end

function PLEXOSSolutionDataset(zippath::String)
    resultsarchive, xmlname = open_plexoszip(zippath)
    xml = parsexml(resultsarchive[xmlname])
    return PLEXOSSolutionDataset(xml)
end

function consolidate(
    unconsolidated::PLEXOSSolutionDataset,
    summary::PLEXOSSolutionDatasetSummary)

    result = PLEXOSSolutionDataset(summary, consolidated=true)

    for name in fieldnames(PLEXOSSolutionDataset)
        idx = 0
        vec = getfield(unconsolidated, name)
        for i in 1:length(vec)
            if isassigned(vec, i)
                idx += 1
                getfield(result, name)[idx] = vec[i]
            end
        end
    end

    return result

end