function xcorr(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.ref_type = 'none';
defaults.epoch = 'targacq';
defaults.subtract_reference = true;

params = dsp3.parsestruct( defaults, varargin );

epoch = params.epoch;
ref_type = params.ref_type;

signal_p = fullfile( 'signals', ref_type, epoch );
output_p = dsp3.get_intermediate_dir( fullfile('xcorr', ref_type, epoch) );

mats = dsp3.require_intermediate_mats( signal_p );

ts = [ -500, 500 ];

bands = { [4, 8], [15, 25], [45, 60] };
bandnames = { 'theta', 'beta', 'gamma' };

site_pairs = dsp2.io.get_site_pairs();

for i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  
  signal_file = shared_utils.io.fload( mats{i} );
  signals = signal_file.measure;
  
  un_filename = get_unf( signal_file.unified_filename );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( dsp3.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  t = dsp3.get_matrix_t( signals );
  
  t_ind = t >= ts(1) & t <= ts(2);
  
  data = signals.data(:, t_ind);
  fs = signals.fs;
  labs = fcat.from( signals.labels );
  
  [I, C] = findall( labs, 'days' );
  
  c_inds = combvec( 1:numel(I), 1:numel(bands) );
  n_combs = size( c_inds, 2 );
  
  totlabs = arrayfun( @(x) fcat(), 1:n_combs, 'un', false );
  totdata = cell( size(totlabs) );
  
  parfor j = 1:n_combs
    dsp3.progress( j, n_combs, 2 );
    
    inds = c_inds(:, j);
    data_ind = I{inds(1)};
    band_ind = inds(2);
    day_ind = strcmp( site_pairs.days, C{inds(1)} );
    
    band_name = bandnames{band_ind};
    
    lowf = bands{band_ind}(1);
    highf = bands{band_ind}(2);
    
    channels = site_pairs.channels{day_ind};    
    n_chans = size( channels, 1 );
%     n_chans = 1;
    
    for k = 1:n_chans
      dsp3.progress( k, n_chans, 3 );
       
      chan1 = channels{k, 1};
      chan2 = channels{k, 2};
      
      reg1_ind = intersect( data_ind, find(labs, chan1) );
      reg2_ind = intersect( data_ind, find(labs, chan2) );
      
      msg_id = strjoin( [channels(k, :), site_pairs.days{day_ind}], ' | ' );
      
      assert( numel(reg1_ind) == numel(reg2_ind), 'Non-matching subsets for "%s"', msg_id );
      
      if ( params.subtract_reference )
        ref_ind = intersect( data_ind, find(labs, 'ref') );
        
        assert( numel(ref_ind) == numel(reg1_ind), 'Non-matching reference subset for "%s"', msg_id );
      end
      
      tmp_outs = cell( numel(reg1_ind), 1 );
      
      for h = 1:numel(reg1_ind)        
        s1 = data(reg1_ind(h), :);
        s2 = data(reg2_ind(h), :);
        
        if ( params.subtract_reference )
          s1 = s1 - data(ref_ind(h), :);
          s2 = s2 - data(ref_ind(h), :);
        end
        
        [lags, crosscorr, max_crosscorr_lag] = dsp3.amp_crosscorr( s1, s2, fs, lowf, highf );
        
        tmp = struct();
        tmp.lags = lags;
        tmp.value = crosscorr;
        tmp.lag_at_max = max_crosscorr_lag;
        
        tmp_outs{h} = tmp;
      end
      
      lab1 = labs(reg1_ind);
      lab2 = labs(reg2_ind);
      
      reg1 = strjoin( combs(lab1, 'regions'), '_' );
      reg2 = strjoin( combs(lab2, 'regions'), '_' );
      
      region = sprintf( '%s_%s', reg1, reg2 );
      
      channel_str = sprintf( '%s_%s', chan1, chan2 );
      
      setcat( lab1, 'regions', region );
      setcat( lab1, 'channels', channel_str );
      setcat( addcat(lab1, 'bands'), 'bands', band_name );
      
      totlabs{j} = append( totlabs{j}, prune(lab1) );
      totdata{j} = [ totdata{j}; tmp_outs ];
    end
  end
  
  totdata = totdata(:);
  totlabs = extend( totlabs{:} );
  totdata = vertcat( totdata{:} );
  
  xcorr_file = struct();
  xcorr_file.unified_filename = un_filename;
  xcorr_file.data = totdata;
  xcorr_file.labels = totlabs;
  xcorr_file.params = params;
  xcorr_file.bands = bands;
  xcorr_file.bandnames = bandnames;
  
  shared_utils.io.require_dir( output_p );
   
  save( output_filename, 'xcorr_file' );
end

end

function un_filename = get_unf(un_filename)
  
  if ( ~shared_utils.char.ends_with(un_filename, '.mat') )
    un_filename = sprintf( '%s.mat', un_filename );
  end
  
end



