function norm_file = norm_psd(files, target_event_name, base_event_name, varargin)

defaults = dsp3.make.defaults.norm_psd();
params = dsp3.parsestruct( defaults, varargin );

targ_file = shared_utils.general.get( files, target_event_name );
base_file = shared_utils.general.get( files, base_event_name );

base_data = base_file.data;

if ( size(base_data, 3) ~= 1 )
  warning( 'Baseline data have more than one time bin; averaging across these.' );
  base_data = squeeze( nanmean(base_data, 3) );
end

norm_data = targ_file.data;
num_t_bins = size( norm_data, 3 );

for i = 1:num_t_bins
  norm_data(:, :, i) = params.norm_func( norm_data(:, :, i), base_data );
end

norm_file = targ_file;
norm_file.data = norm_data;

end