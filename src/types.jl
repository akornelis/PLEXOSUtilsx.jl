abstract type AbstractDataset end

# Metadata

struct PLEXOSConfig
    element::String
    value::String
end

PLEXOSConfig(e::Node, ::AbstractDataset) = PLEXOSConfig(
    getchildtext("element", e),
    getchildtext("value", e)
)


struct PLEXOSUnit
    value::String
end

PLEXOSUnit(e::Node, ::AbstractDataset) =
    PLEXOSUnit(getchildtext("value", e))


struct PLEXOSTimeslice
    name::String
end

PLEXOSTimeslice(e::Node, ::AbstractDataset) =
    PLEXOSTimeslice(getchildtext("name", e))


struct PLEXOSModel
    name::String
end

PLEXOSModel(e::Node, ::AbstractDataset) =
    PLEXOSModel(getchildtext("name", e))


struct PLEXOSSample
    name::String
end

PLEXOSSample(e::Node, ::AbstractDataset) =
    PLEXOSSample(getchildtext("sample_name", e))

struct PLEXOSSampleWeight
    sample::PLEXOSSample
    phase::Int # maybe Parametrize on this?
    value::Float64
end

const sample_offset = plexostables_lookup["t_sample"].indexoffset
PLEXOSSampleWeight(e::Node, d::AbstractDataset) =
    PLEXOSSampleWeight(d.samples[getchildint("sample_id", e) + sample_offset],
                       getchildint("phase_id", e),
                       getchildfloat("value", e))

struct PLEXOSClassGroup
    name::String
end

PLEXOSClassGroup(e::Node, ::AbstractDataset) =
    PLEXOSClassGroup(getchildtext("name", e))

struct PLEXOSClass
    name::String
    classgroup::PLEXOSClassGroup
    state::Union{Int,Nothing}
end

PLEXOSClass(e::Node, d::AbstractDataset) =
    PLEXOSClass(getchildtext("name", e),
                d.classgroups[getchildint("class_group_id", e)],
                getchildint("state", e))

struct PLEXOSCategory
    name::String
    rank::Int
    class::PLEXOSClass

    # PLEXOS sometimes reports categories without reporting the classes they
    # refer to: if that happens, just leave the class undefined
    # (category won't have any objects anyways)

    function PLEXOSCategory(e::Node, d::AbstractDataset)

        class_idx = getchildint("class_id", e)

        if isassigned(d.classes, class_idx)
            new(getchildtext("name", e),
                getchildint("rank", e),
                d.classes[class_idx])
        else
            new(getchildtext("name", e),
                getchildint("rank", e))
        end

    end

end


struct PLEXOSAttribute
    name::String
    description::String
    enum::Int
    class::PLEXOSClass

    # PLEXOS sometimes reports attributes without reporting the classes they
    # refer to: if that happens, just leave the classes undefined

    function PLEXOSAttribute(e::Node, d::AbstractDataset)

        name = getchildtext("name", e)
        description = getchildtext("description", e)
        enum = getchildint("enum_id", e)
        class_idx = getchildint("class_id", e)

        if isassigned(d.classes, class_idx)
            new(name, description, enum, d.classes[class_idx])
        else
            new(name, description, enum)
        end

    end

end


struct PLEXOSCollection
    name::String
    complementname::Union{Nothing,String}
    parentclass::PLEXOSClass
    childclass::PLEXOSClass

    # PLEXOS sometimes reports collections without reporting the classes they
    # refer to: if that happens, just leave the classes undefined
    # (collection won't have any members anyways)

    function PLEXOSCollection(e::Node, d::AbstractDataset)

        name = getchildtext("name", e)
        cname = getchildtext("complement_name", e)
        cname == "" && (cname = nothing)

        parent_idx = getchildint("parent_class_id", e)
        child_idx = getchildint("child_class_id", e)

        if isassigned(d.classes, parent_idx) && isassigned(d.classes, child_idx)
            new(name, cname, d.classes[parent_idx], d.classes[child_idx])
        else
            new(name, cname)
        end

    end

end


struct PLEXOSCustomColumn
    name::String
    position::Int
    class::PLEXOSClass

    function PLEXOSCustomColumn(e::Node, d::AbstractDataset)

        name = getchildtext("name", e)
        position = getchildint("position", e)
        class_idx = getchildint("class_id", e)

        if isassigned(d.classes, class_idx)
            new(name, position, d.classes[class_idx])
        else
            new(name, position)
        end

    end

end

struct PLEXOSProperty
    name::String
    summaryname::String
    enum::Int
    unit::PLEXOSUnit 
    summaryunit::PLEXOSUnit
    ismultiband::Bool
    isperiod::Bool
    issummary::Bool
    collection::PLEXOSCollection

    # PLEXOS sometimes reports properties without reporting the collections they
    # refer to: if that happens, just leave the collections undefined
    # (property won't have any data anyways)

    function PLEXOSProperty(e::Node, d::AbstractDataset)

        collection_idx = getchildint("collection_id", e)

        name = getchildtext("name", e)
        summary_name = getchildtext("summary_name", e)
        enum = getchildint("enum_id", e)
        unit = d.units[getchildint("unit_id", e) + 1]
        summary_unit = d.units[getchildint("summary_unit_id", e) + 1]
        is_multiband = getchildbool("is_multi_band", e)
        is_period = getchildbool("is_period", e)
        is_summary = getchildbool("is_summary", e)

        if isassigned(d.collections, collection_idx)
            new(name, summary_name, enum,
                unit, summary_unit,
                is_multiband, is_period, is_summary,
                d.collections[collection_idx])
        else
            new(name, summary_name, enum,
                unit, summary_unit,
                is_multiband, is_period, is_summary)
        end

    end

end

# System Data

struct PLEXOSObject
    name::String
    class::PLEXOSClass
    category::PLEXOSCategory
    index::Int
    show::Bool
end

PLEXOSObject(e::Node, d::AbstractDataset) =
    PLEXOSObject(getchildtext("name", e),
                 d.classes[getchildint("class_id", e)],
                 d.categories[getchildint("category_id", e)],
                 getchildint("index", e),
                 getchildbool("show", e))


struct PLEXOSMembership
    parentclass::PLEXOSClass
    childclass::PLEXOSClass
    collection::PLEXOSCollection
    parentobject::PLEXOSObject
    childobject::PLEXOSObject
end

PLEXOSMembership(e::Node, d::AbstractDataset) =
    PLEXOSMembership(d.classes[getchildint("parent_class_id", e)],
                     d.classes[getchildint("child_class_id", e)],
                     d.collections[getchildint("collection_id", e)],
                     d.objects[getchildint("parent_object_id", e)],
                     d.objects[getchildint("child_object_id", e)])


struct PLEXOSAttributeData

    value::Float64
    attribute::PLEXOSAttribute
    object::PLEXOSObject

    function PLEXOSAttributeData(e::Node, d::AbstractDataset)

        value = getchildfloat("value", e)
        attribute = d.attributes[getchildint("attribute_id", e)]
        object_idx = getchildint("object_id", e)

        # PLEXOS sometimes reports attributes without reporting the objects they
        # refer to: if that happens, just leave the objects undefined

        if isassigned(d.objects, object_idx)
            new(value, attribute, d.objects[object_idx])
        else
            new(value, attribute)
        end

    end

end

struct PLEXOSMemoObject
    value::String
    column::PLEXOSCustomColumn
    object::PLEXOSObject

    function PLEXOSMemoObject(e::Node, d::AbstractDataset)

        value = getchildtext("value", e)
        object_idx = getchildint("object_id", e)
        column = d.customcolumns[getchildint("column_id", e)]

        if isassigned(d.objects, object_idx)
            new(value, column, d.objects[object_idx])
        else
            new(value, column)
        end

    end

end

# Results

struct PLEXOSPeriod0
    periodofday::Int
    hour::Int
    day::Int
    week::Int
    month::Int
    quarter::Int
    fiscalyear::Int
    datetime::String
end

PLEXOSPeriod0(e::Node, d::AbstractDataset) =
    PLEXOSPeriod0(getchildint("period_of_day", e),
                  getchildint("hour_id", e),
                  getchildint("day_id", e),
                  getchildint("week_id", e),
                  getchildint("month_id", e),
                  getchildint("quarter_id", e),
                  getchildint("fiscal_year_id", e),
                  getchildtext("datetime", e))


struct PLEXOSPeriod1
    week::Int
    month::Int
    quarter::Int
    fiscalyear::Int
    date::String
end

PLEXOSPeriod1(e::Node, d::AbstractDataset) =
    PLEXOSPeriod1(getchildint("week_id", e),
                  getchildint("month_id", e),
                  getchildint("quarter_id", e),
                  getchildint("fiscal_year_id", e),
                  getchildtext("date", e))


struct PLEXOSPeriod2
    week_ending::String
end

PLEXOSPeriod2(e::Node, d::AbstractDataset) =
    PLEXOSPeriod2(getchildtext("week_ending", e))


struct PLEXOSPeriod3
    month_beginning::String
end

PLEXOSPeriod3(e::Node, d::AbstractDataset) =
    PLEXOSPeriod3(getchildtext("month_beginning", e))


struct PLEXOSPeriod4
    year_ending::String
end

PLEXOSPeriod4(e::Node, d::AbstractDataset) =
    PLEXOSPeriod4(getchildtext("year_ending", e))


struct PLEXOSPeriod6
    day::Int
    datetime::String
end

PLEXOSPeriod6(e::Node, d::AbstractDataset) =
    PLEXOSPeriod6(getchildint("day_id", e),
                  getchildtext("datetime", e))


struct PLEXOSPeriod7
    quarter_beginning::String
end

PLEXOSPeriod7(e::Node, d::AbstractDataset) =
    PLEXOSPeriod7(getchildtext("quarter_beginning", e))


struct PLEXOSPhase1

    period::Int # LT period
    interval::PLEXOSPeriod0

    function PLEXOSPhase1(e::Node, d::AbstractDataset)

        period = getchildint("period_id", e)

        if length(d.intervals) > 0
            new(period, d.intervals[getchildint("interval_id", e)])
        else
            new(period)
        end

    end

end

struct PLEXOSPhase2

    period::Int # PASA period
    interval::PLEXOSPeriod0

    function PLEXOSPhase2(e::Node, d::AbstractDataset)

        period = getchildint("period_id", e)

        if length(d.intervals) > 0
            new(period, d.intervals[getchildint("interval_id", e)])
        else
            new(period)
        end

    end

end

struct PLEXOSPhase3

    period::Int # MT period
    interval::PLEXOSPeriod0

    function PLEXOSPhase3(e::Node, d::AbstractDataset)

        period = getchildint("period_id", e)

        if length(d.intervals) > 0
            new(period, d.intervals[getchildint("interval_id", e)])
        else
            new(period)
        end

    end

end

struct PLEXOSPhase4 # are these values always 1:1 matches?

    period::Int # ST period
    interval::PLEXOSPeriod0

    function PLEXOSPhase4(e::Node, d::AbstractDataset)

        period = getchildint("period_id", e)

        if length(d.intervals) > 0
            new(period, d.intervals[getchildint("interval_id", e)])
        else
            new(period)
        end

    end

end

struct PLEXOSKey
    membership::PLEXOSMembership
    model::PLEXOSModel
    phase::Int
    property::PLEXOSProperty
    periodtype::Int # not accurate, use KeyIndex.periodtype instead
    band::Int
    sample::PLEXOSSample
    timeslice::PLEXOSTimeslice
end

PLEXOSKey(e::Node, d::AbstractDataset) =
    PLEXOSKey(d.memberships[getchildint("membership_id", e)],
              d.models[getchildint("model_id", e)],
              getchildint("phase_id", e),
              d.properties[getchildint("property_id", e)],
              getchildint("period_type_id", e),
              getchildint("band_id", e),
              d.samples[getchildint("sample_id", e) + sample_offset],
              d.timeslices[getchildint("timeslice_id", e) + 1])

struct PLEXOSKeyIndex
    key::PLEXOSKey
    periodtype::Int
    position::Int # bytes from binary file start
    length::Int # 8-byte (Float64) increments
    periodoffset::Int # temporal data offset (if any) in stored times
end

PLEXOSKeyIndex(e::Node, d::AbstractDataset) =
    PLEXOSKeyIndex(d.keys[getchildint("key_id", e)],
                   getchildint("period_type_id", e),
                   getchildint("position", e),
                   getchildint("length", e),
                   getchildint("period_offset", e))
