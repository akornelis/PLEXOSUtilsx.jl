module PLEXOSUtilsx

import EzXML: Document, eachelement, namespace, Node, nodecontent, parsexml
import InfoZIPx: Archive, open_zip

export open_plexoszip, PLEXOSSolutionDataset, PLEXOSSolutionDatasetSummary


struct PLEXOSTable

    name::String
    fieldname::Symbol
    fieldtype::Symbol
    loadorder::Int
    identifier::Union{String,Nothing}
    timestampfield::Union{Symbol,Nothing}
    indexoffset::Int

    PLEXOSTable(name::String, fieldname::Symbol, fieldtype::Symbol,
                loadorder::Int,
                identifier::Union{String,Nothing}=nothing,
                timestampfield::Union{Symbol,Nothing}=nothing,
                indexoffset::Int=0
    ) = new(name, fieldname, fieldtype, loadorder,
            identifier, timestampfield, indexoffset)

end

plexostables = [

    PLEXOSTable("t_config", :configs, :PLEXOSConfig, 1),
    PLEXOSTable("t_unit", :units, :PLEXOSUnit, 1, "unit_id", nothing, 1),
    PLEXOSTable("t_timeslice", :timeslices, :PLEXOSTimeslice, 1, "timeslice_id", nothing, 1),
    PLEXOSTable("t_model", :models, :PLEXOSModel, 1, "model_id"),

    PLEXOSTable("t_sample", :samples, :PLEXOSSample, 1, "sample_id", nothing, 4),
    PLEXOSTable("t_sample_weight", :sampleweights, :PLEXOSSampleWeight, 2),

    PLEXOSTable("t_class_group", :classgroups, :PLEXOSClassGroup, 1, "class_group_id"),
    PLEXOSTable("t_class", :classes, :PLEXOSClass, 2, "class_id"),
    PLEXOSTable("t_category", :categories, :PLEXOSCategory, 3, "category_id"),

    PLEXOSTable("t_attribute", :attributes, :PLEXOSAttribute, 3, "attribute_id"),
    PLEXOSTable("t_collection", :collections, :PLEXOSCollection, 3, "collection_id"),
    PLEXOSTable("t_property", :properties, :PLEXOSProperty, 4, "property_id"),

    PLEXOSTable("t_object", :objects, :PLEXOSObject, 4, "object_id"),
    PLEXOSTable("t_membership", :memberships, :PLEXOSMembership, 5, "membership_id"),
    PLEXOSTable("t_attribute_data", :attribute_data, :PLEXOSAttributeData, 5),

    PLEXOSTable("t_custom_column", :customcolumns, :PLEXOSCustomColumn, 3, "column_id"),
    PLEXOSTable("t_memo_object", :memos, :PLEXOSMemoObject, 5),

    PLEXOSTable("t_period_0", :intervals, :PLEXOSPeriod0, 1, "interval_id", :datetime),
    PLEXOSTable("t_period_1", :days, :PLEXOSPeriod1, 1, "day_id", :date),
    PLEXOSTable("t_period_2", :weeks, :PLEXOSPeriod2, 1, "week_id", :week_ending),
    PLEXOSTable("t_period_3", :months, :PLEXOSPeriod3, 1, "month_id", :month_beginning),
    PLEXOSTable("t_period_4", :years, :PLEXOSPeriod4, 1, "fiscal_year_id", :year_ending),
    PLEXOSTable("t_period_6", :hours, :PLEXOSPeriod6, 1, "hour_id", :datetime),
    PLEXOSTable("t_period_7", :quarters, :PLEXOSPeriod7, 1, "quarter_id", :quarter_beginning),

    PLEXOSTable("t_phase_1", :lt, :PLEXOSPhase1, 2),
    PLEXOSTable("t_phase_2", :pasa, :PLEXOSPhase2, 2),
    PLEXOSTable("t_phase_3", :mt, :PLEXOSPhase3, 2),
    PLEXOSTable("t_phase_4", :st, :PLEXOSPhase4, 2),

    PLEXOSTable("t_key", :keys, :PLEXOSKey, 6, "key_id"),
    PLEXOSTable("t_key_index", :keyindices, :PLEXOSKeyIndex, 7)

]

plexostables_lookup = Dict(x.name => x for x in plexostables)

include("types.jl")
include("PLEXOSSolutionDatasetSummary.jl")
include("PLEXOSSolutionDataset.jl")
include("utils.jl")

end
