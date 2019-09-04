function t = stat_tables(stat_outs)

%   STAT_TABLES -- Extract the tables from dsp3.* stat function outputs.
%
%     See also dsp3.stat_field

t = dsp3.stat_field( stat_outs, 'tables' );

end