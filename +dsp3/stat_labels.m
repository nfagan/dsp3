function t = stat_labels(stat_outs)

%   STAT_LABELS -- Extract the labels from dsp3.* stat function outputs.
%
%     See also dsp3.stat_field

t = dsp3.stat_field( stat_outs, 'labels' );

end