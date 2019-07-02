function dsp3_save_day_formatted_aligned_lfp(out, event_name, conf, varargin)

defaults = dsp3.get_common_lfp_defaults();
params = dsp3.parsestruct( defaults, varargin );

output_directory = fullfile( dsp3.dataroot(conf), 'analyses', 'reprocessed_signals', event_name );
shared_utils.io.require_dir( output_directory );

data = out.data;
labels = out.labels;

[day_I, day_C] = findall( labels, 'days' );

for i = 1:numel(day_I)
  shared_utils.general.progress( i, numel(day_I) );
  
  tmp_dat = data(day_I{i}, :);
  tmp_labs = prune( labels(day_I{i}) );
  
  if ( hascat(tmp_labs, 'region') )
    renamecat( tmp_labs, 'region', 'regions' );
  end
  
  if ( hascat(tmp_labs, 'channel') )
    renamecat( tmp_labs, 'channel', 'channels' );
  end
  
  [tmp_dat, tmp_labs] = dsp3.ref_subtract( tmp_dat, tmp_labs );
  tmp_dat = dsp3.zpfilter( tmp_dat, params.f1, params.f2, params.sample_rate, params.filter_order );
  
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