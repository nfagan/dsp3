function [data, labels, freqs, t] = load_signal_measure(mats, varargin)

persistent d;
persistent l;
persistent f_;
persistent t_;

defaults = struct();

defaults.identify_meas_func = @default_identify_meas_type;
defaults.get_meas_func = @default_get_meas_func;
defaults.get_time_series_func = @default_get_time_series;
defaults.get_frequencies_func = @default_get_frequencies;
defaults.get_data_func = @default_get_data;
defaults.get_labels_func = @default_get_labels;
defaults.is_cached = true;

params = dsp3.parsestruct( defaults, varargin );

if ( check_use_cached(mats) && params.is_cached )
  fprintf( '\n\n Using cached data ...' );
  data = d;
  labels = l';
  freqs = f_;
  t = t_;
  return
end

identify_meas_func =    params.identify_meas_func;
get_meas_func =         params.get_meas_func;
get_time_series_func =  params.get_time_series_func;
get_frequencies_func =  params.get_frequencies_func;
get_data_func =         params.get_data_func;
get_labels_func =       params.get_labels_func;

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
  
  t = get_time_series_func( meas, meas_file );
  freqs = get_frequencies_func( meas, meas_file );
  
  t_ind = t >= -500 & t <= 500;
  f_ind = freqs <= 100;
  
  lab = get_labels_func( meas, meas_file );
  
  if ( ~isempty(lab) )
    setcat( addcat(lab, 'measure'), 'measure', meas_t );  
  end
  
  data = get_data_func( meas, meas_file );
  
  labs{i} = lab;
  dat{i} = data(:, f_ind, t_ind);
  
  freqs = freqs(f_ind);
  t = t(t_ind);
end

labels = vertcat( fcat(), labs{:} );
data = vertcat( dat{~cellfun(@isempty, dat)} );

assert_rowsmatch( data, labels );
assert( size(data, 2) == numel(freqs), 'Frequencies do not match data.' );

if ( ~isempty(data) )
  assert( size(data, 3) == numel(t), 'Times do not match data.' );
end

d = data;
l = labels';
f_ = freqs;
t_ = t;

end

function tf = check_use_cached(mats)
persistent last_mats;
tf = ~isempty( last_mats ) && isequal( sort(last_mats(:)), sort(mats(:)) );
last_mats = mats;
end

function t_series = default_get_time_series(meas, meas_file)

t_series = get_time_series( meas );

end

function freqs = default_get_frequencies(meas, meas_file)

freqs = meas.frequencies;

end

function data = default_get_data(meas, meas_file)

data = meas.data;

end

function labels = default_get_labels(meas, meas_file)

labels = fcat.from( meas.labels );

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