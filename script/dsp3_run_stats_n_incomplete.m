function dsp3_run_stats_n_incomplete()

rev_types = dsp3.get_rev_types();

rev_ts = keys( rev_types );

for i = 1:numel(rev_ts)
  rev_t = rev_ts{i};
  
  stats__n_incomplete( ...
      'remove', rev_types(rev_t) ...
    , 'do_save', true ...
    , 'base_subdir', rev_t ...
  );
end

end
