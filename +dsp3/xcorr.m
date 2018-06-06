function xcorr(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.ref_type = 'none';
defaults.epoch = 'targacq';
defaults.subtract_reference = true;
defaults.ts = [ -250, 0 ];
defaults.filt_func = @dsp3.xcorrfilter;
defaults.bands = { [4, 8], [15, 25], [45, 60] };
defaults.bandnames = { 'theta', 'beta', 'gamma' };
defaults.xcorr_scale_opt = 'coeff';
defaults.output_subdir = '';
defaults.shuffle = false;
defaults.per_trial = true;
defaults.across_trials_specificity = { 'outcomes', 'trialtypes', 'administration' };
defaults.across_trials_type = 'nondrug';

params = dsp3.parsestruct( defaults, varargin );

epoch = params.epoch;
ref_type = params.ref_type;

signal_p = fullfile( 'signals', ref_type, epoch );
output_p = dsp3.get_intermediate_dir( fullfile('xcorr', params.output_subdir, epoch) );

mats = dsp3.require_intermediate_mats( signal_p );

bands = params.bands;
bandnames = params.bandnames;

assert( numel(bands) == numel(bandnames), 'Number of bands and bandnames must match.' );

ts = params.ts;

site_pairs = dsp2.io.get_site_pairs();

parfor i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  
  signal_file = shared_utils.io.fload( mats{i} );
  signals = signal_file.measure;
  
  un_filename = get_unf( signal_file.unified_filename );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( dsp3.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  if ( ~params.per_trial )
    signals = dsp3.get_subset( signals, params.across_trials_type, {'days', 'sites', 'regions'} );
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
  
%   parfor j = 1:n_combs
  for j = 1:n_combs
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
    
    for k = 1:n_chans
      dsp3.progress( k, n_chans, 3 );
       
      chan1 = channels{k, 1};
      chan2 = channels{k, 2};
      channel_str = sprintf( '%s_%s', chan1, chan2 );
      
      msg_id = strjoin( [channels(k, :), site_pairs.days{day_ind}], ' | ' );
      
      if ( params.per_trial )
        [tmp_outs, lab1] = per_trial_xcorr( data, labs, params ...
          , data_ind, lowf, highf, fs, chan1, chan2, msg_id );
      else
        [tmp_outs, lab1] = across_trials_xcorr( data, labs, params ...
          , data_ind, lowf, highf, fs, chan1, chan2, msg_id );
      end
      
      setcat( lab1, 'channels', channel_str );
      setcat( addcat(lab1, 'bands'), 'bands', band_name );
      prune( lab1 );

      totlabs{j} = append( totlabs{j}, prune(lab1) );
      totdata{j} = [ totdata{j}; tmp_outs ];
    end
  end
  
  totdata = totdata(:);
  totlabs = extend( fcat(), totlabs{:} );
  totdata = vertcat( totdata{:} );
  
  xcorr_file = struct();
  xcorr_file.unified_filename = un_filename;
  xcorr_file.data = totdata;
  xcorr_file.labels = totlabs;
  xcorr_file.params = params;
  
  shared_utils.io.require_dir( output_p );
  shared_utils.io.psave( output_filename, xcorr_file );
end

end

function [tmp_outs, all_labs] = across_trials_xcorr(data, labs, params ...
  , data_ind, lowf, highf, fs, chan1, chan2, msg_id)

specificity = params.across_trials_specificity;

filt_func = params.filt_func;
scale_opt = params.xcorr_scale_opt;

[all_labs, cnd_ind] = keepeach( copy(labs), specificity );

cnd_ind = cellfun( @(x) trueat(labs, x), cnd_ind, 'un', false );
data_ind = trueat( labs, data_ind );

tmp_outs = cell( numel(cnd_ind), 1 );

chan1_ind = trueat( labs, find(labs, chan1) );
chan2_ind = trueat( labs, find(labs, chan2) );

for i = 1:numel(cnd_ind)
  
  full_cnd_ind = cnd_ind{i} & data_ind;
  
  reg1_ind = find( full_cnd_ind & chan1_ind );
  reg2_ind = find( full_cnd_ind & chan2_ind );
  
  assert( numel(reg1_ind) == numel(reg2_ind), msg_id );
  
  if ( isempty(reg1_ind) ), continue; end
  
  if ( params.subtract_reference )
    ref_ind = find( full_cnd_ind & trueat(labs, find(labs, 'ref')) );

    assert( numel(ref_ind) == numel(reg1_ind) ...
      , 'Non-matching reference subset for "%s"', msg_id );
  end
  
  reg1_data = cell( 1, numel(reg1_ind) );
  reg2_data = cell( size(reg1_data) );
  
  for h = 1:numel(reg1_ind)        
    s1 = data(reg1_ind(h), :);
    s2 = data(reg2_ind(h), :);

    if ( params.subtract_reference )
      s1 = s1 - data(ref_ind(h), :);
      s2 = s2 - data(ref_ind(h), :);
    end

    filt1 = filt_func( s1, lowf, highf, fs );
    filt2 = filt_func( s2, lowf, highf, fs );

    if ( params.shuffle )
      filt1 = filt1( randperm(numel(filt1)) );
    end
    
    reg1_data{h} = filt1;
    reg2_data{h} = filt2;
  end
  
  reg1_data = horzcat( reg1_data{:} );
  reg2_data = horzcat( reg2_data{:} );
  
  [lags, cc, lag_at_max] = dsp3.amp_crosscorr( reg1_data, reg2_data, fs, scale_opt );

  tmp = struct();
  tmp.lags = lags;
  tmp.value = cc;
  tmp.lag_at_max = lag_at_max;

  tmp_outs{i} = tmp;
end

lab1 = labs(find(data_ind & chan1_ind));
lab2 = labs(find(data_ind & chan2_ind));

reg1 = strjoin( combs(lab1, 'regions'), '_' );
reg2 = strjoin( combs(lab2, 'regions'), '_' );

region = sprintf( '%s_%s', reg1, reg2 );

setcat( addcat(all_labs, 'regions'), 'regions', region );

end

function [tmp_outs, lab1] = per_trial_xcorr(data, labs, params ...
  , data_ind, lowf, highf, fs, chan1, chan2, msg_id)

reg1_ind = intersect( data_ind, find(labs, chan1) );
reg2_ind = intersect( data_ind, find(labs, chan2) );

assert( numel(reg1_ind) == numel(reg2_ind), 'Non-matching subsets for "%s"', msg_id );

if ( params.subtract_reference )
  ref_ind = intersect( data_ind, find(labs, 'ref') );

  assert( numel(ref_ind) == numel(reg1_ind) ...
    , 'Non-matching reference subset for "%s"', msg_id );
end

filt_func = params.filt_func;
scale_opt = params.xcorr_scale_opt;

tmp_outs = cell( numel(reg1_ind), 1 );
      
for h = 1:numel(reg1_ind)        
  s1 = data(reg1_ind(h), :);
  s2 = data(reg2_ind(h), :);

  if ( params.subtract_reference )
    s1 = s1 - data(ref_ind(h), :);
    s2 = s2 - data(ref_ind(h), :);
  end

  filt1 = filt_func( s1, lowf, highf, fs );
  filt2 = filt_func( s2, lowf, highf, fs );

  if ( params.shuffle )
    filt1 = filt1( randperm(numel(filt1)) );
  end

  [lags, cc, lag_at_max] = dsp3.amp_crosscorr( filt1, filt2, fs, scale_opt );

  tmp = struct();
  tmp.lags = lags;
  tmp.value = cc;
  tmp.lag_at_max = lag_at_max;

  tmp_outs{h} = tmp;
end

lab1 = labs(reg1_ind);
lab2 = labs(reg2_ind);

reg1 = strjoin( combs(lab1, 'regions'), '_' );
reg2 = strjoin( combs(lab2, 'regions'), '_' );

region = sprintf( '%s_%s', reg1, reg2 );

setcat( lab1, 'regions', region );

end

function un_filename = get_unf(un_filename)
  
  if ( ~shared_utils.char.ends_with(un_filename, '.mat') )
    un_filename = sprintf( '%s.mat', un_filename );
  end
  
end



