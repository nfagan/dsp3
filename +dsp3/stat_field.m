function v = stat_field(stat_outs, fieldname)

%   STAT_FIELD -- Extract labels or tables from dsp3.* stat function outputs.
%
%     v = dsp3.stat_field( stat_outs, 'tables' ); returns the stat tables
%     from the outputs structure `stat_outs`, such as those returned by
%     dsp3.anova1.
%
%     v = dsp3.stat_field( stat_outs, 'labels' ); returns the labels.
%
%     See also dsp3.anova1, dsp3.anovan, dsp3.corr

if ( isfield(stat_outs, fieldname) )
  v = stat_outs.(fieldname);
  return
end

all_fields = fieldnames( stat_outs );

if ( ~isempty(strfind('tables', lower(fieldname))) )
  check_fields = table_fields();
elseif ( ~isempty(strfind('labels', lower(fieldname))) )
  check_fields = label_fields();
else
  error( 'Unrecognized field specifier: "%s".', fieldname );
end

matching_fields = intersect( check_fields, all_fields );

if ( numel(matching_fields) == 0 )
  error( 'No fields matched "%s".', fieldname );
end 

matching_field = matching_fields{1};

v = stat_outs.(matching_field);

end

function prefs = stat_prefixes()

prefs = { 'anova_', 'rs_', 'sr_', 'corr_' };

end

function fs = label_fields()

fs = cellfun( @(x) sprintf('%slabels', x), stat_prefixes(), 'un', 0 );

end

function fs = table_fields()

fs = cellfun( @(x) sprintf('%stables', x), stat_prefixes(), 'un', 0 );

end