function dsp3_save_day_formatted_aligned_lfp(out, event_name, conf)

output_directory = fullfile( dsp3.dataroot(conf), 'analyses', 'reprocessed_signals', event_name );
shared_utils.io.require_dir( output_directory );

data = out.data;
labels = out.labels;

[day_I, day_C] = findall( labels, 'days' );

for i = 1:numel(day_I)
  shared_utils.general.progress( i, numel(day_I) );
  
  tmp_dat = data(day_I{i}, :);
  tmp_labs = prune( labels(day_I{i}) );
  
  cont = Container( tmp_dat, SparseLabels.from_fcat(tmp_labs) );
  cont = SignalContainer( cont );

  cont.fs = out.fs;
  cont.start = out.start;
  cont.stop = out.stop;
  cont.step_size = out.step_size;
  cont.window_size = out.window_size;
  
  filename = sprintf( 'lfp_%s_%s.mat', day_C{i}, event_name );
  save( fullfile(output_directory, filename), 'cont' );
end

end