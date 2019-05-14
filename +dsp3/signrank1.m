function outs = signrank1(data, labels, spec, varargin)

defaults.mask = rowmask( data );
defaults.descriptive_funcs = dsp3.descriptive_funcs();

params = dsp3.parsestruct( defaults, varargin );

assert_ispair( data, labels );

mask = params.mask;
funcs = params.descriptive_funcs;

[slabs, I] = dsp3.keepeach_or_one( labels', spec, mask );

signrank_tbls = cell( numel(I), 1 );

for i = 1:numel(I)
  [p, ~, stats] = signrank( data(I{i}) );
  stats.p = p;
  
  signrank_tbls{i} = struct2table( stats );
end

[m_tbl, ~, mlabs] = dsp3.descriptive_table( data, labels', spec, funcs, mask );

outs.sr_tables = signrank_tbls;
outs.sr_labels = slabs;
outs.descriptive_tables = m_tbl;
outs.descriptive_labels = mlabs;
outs.descriptive_specificity = spec;

end