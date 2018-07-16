function [data, labels, freqs, t] = load_signal_measure(mats, varargin)

defaults.identify_meas_func = @default_identify_meas_type;
defaults.get_meas_func = @default_get_meas_func;

params = dsp3.parsestruct( defaults, varargin );

identify_meas_func = params.identify_meas_func;
get_meas_func = params.get_meas_func;

labs = cell( size(mats) );
dat = cell( size(labs) );
freqs = [];
t = [];

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  file = mats{i};
  
  meas_file = dsp3.fload( file );
  meas = get_meas_func( meas_file );
  
  meas_t = identify_meas_func( meas_file, file );
  
  t = meas.get_time_series();
  freqs = meas.frequencies;
  
  t_ind = t >= -500 & t <= 500;
  f_ind = freqs <= 100;
  
  lab = fcat.from( meas.labels );
  
  if ( ~isempty(lab) )
    setcat( addcat(lab, 'measure'), 'measure', meas_t );  
  end
  
  labs{i} = lab;
  dat{i} = meas.data(:, f_ind, t_ind);
  
  freqs = freqs(f_ind);
  t = t(t_ind);
end

labels = vertcat( fcat(), labs{:} );
data = vertcat( dat{:} );

assert_rowsmatch( data, labels );
assert( size(data, 2) == numel(freqs) );
assert( size(data, 3) == numel(t) );

end

function meas = default_get_meas_func(meas)
%
end

function meas_t = default_identify_meas_type(meas, file)

cfunc = @shared_utils.char.contains;

if ( cfunc(file, 'coherence') )
  meas_t = 'coherence';
elseif ( cfunc(file, 'raw_power') )
  meas_t = 'rawpower';
else
  error( 'Failed to parse meas type from filename.' );
end

end