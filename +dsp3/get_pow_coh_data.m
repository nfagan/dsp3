function outs = get_pow_coh_data(meas1, meas2, manip, drug_type, epoch)

mats = dsp3.require_intermediate_mats( fullfile(meas1, drug_type, manip, epoch) );

coh_p = dsp3.get_intermediate_dir( fullfile(meas2, drug_type, manip, epoch) );

totdata = cell( 1, numel(mats) );
totlabels = fcat.empties( size(totdata) );
freqs = cell( size(totdata) );
t = cell( size(freqs) );

if ( strcmp(meas2, 'coherence') )
  coh_sublab = 'subdir_coherence';
else
  coh_sublab = meas2;
end

% mats = shared_utils.cell.containing( mats, {'day__05232017', 'day__05252017', 'day__08232016'} );

% mats = mats(39);

n_mats = numel( mats );
% n_mats = 10;

parfor i = 1:n_mats
  dsp3.progress( i, numel(mats) );
  
  power_file = shared_utils.io.fload( mats{i} );
  un_filename = shared_utils.char.require_end( power_file.unified_filename, '.mat' );
  coh_file = shared_utils.io.fload( fullfile(coh_p, un_filename) );
  
  is_z = isfield( power_file, 'zlabels' );

  if ( is_z )
    plabels = fcat.from( power_file.zlabels, power_file.zcats );
    clabels = fcat.from( coh_file.zlabels, coh_file.zcats );
  else
    plabels = fcat.from( power_file.measure.labels );
    clabels = fcat.from( coh_file.measure.labels );
  end
  
  if ( ~isempty(plabels) )
    setcat( addcat(plabels, 'measure'), 'measure', 'power' );
    setcat( addcat(plabels, 'subdir'), 'subdir', meas1 );
  end
  
  if ( ~isempty(clabels) )
    setcat( addcat(clabels, 'measure'), 'measure', 'coherence' );
    setcat( addcat(clabels, 'subdir'), 'subdir', coh_sublab );
  end
  
  totlabels{i} = extend( totlabels{i}, plabels, clabels );
  
  if ( is_z )
    pdata = power_file.zdata;
    cdata = coh_file.zdata;
    
    f1 = power_file.frequencies;
    f2 = coh_file.frequencies;
    
    t_series = power_file.time;
  else
    pdata = power_file.measure.data;
    cdata = coh_file.measure.data;
    
    f1 = power_file.measure.frequencies;
    f2 = coh_file.measure.frequencies;
    t_series = coh_file.measure.get_time_series();
  end

  nf = min( numel(f1), numel(f2) );
  f1 = f1(1:nf);

  totdata{i} = [ dimref(pdata, 1:nf, 2); dimref(cdata, 1:nf, 2) ];

  t{i} = t_series;
  freqs{i} = f1;
end

totdata = vertcat( totdata{:} );
totlabels = vertcat( fcat(), totlabels{:} );

t = t{1};
freqs = freqs{1};

outs.t = t;
outs.frequencies = freqs;
outs.labels = totlabels;
outs.data = totdata;

end