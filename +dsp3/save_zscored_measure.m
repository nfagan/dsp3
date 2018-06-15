function save_zscored_measure(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.meas_type = '';
defaults.epoch = '';
defaults.manipulation = '';
defaults.drug_type = '';
defaults.mean_spec = union( dsp3.get_default_mean_spec(), 'contexts' );
defaults.N = 100;

params = dsp3.parsestruct( defaults, varargin );

meas_type = field_or_err( params, 'meas_type' );
epoch = field_or_err( params, 'epoch' );
manipulation = field_or_err( params, 'manipulation' );
drug_type = field_or_err( params, 'drug_type' );
mean_spec = params.mean_spec;
N = params.N;

validate_manipulation( manipulation );

input_p = dsp3.get_intermediate_dir( fullfile(meas_type, epoch) );
output_p = dsp3.get_intermediate_dir( fullfile(sprintf('z_%s', meas_type) ...
  , drug_type, manipulation, epoch) );

mats = dsp3.require_intermediate_mats( params.files, input_p, params.files_containing );

parfor i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  
  meas_file = shared_utils.io.fload( mats{i} );
  
  un_filename = shared_utils.char.require_end( meas_file.unified_filename, '.mat' );
  output_filename = fullfile( output_p, un_filename );  
  
  if ( dsp3.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  meas = dsp3.get_subset( meas_file.measure, drug_type, {'days', 'sites', 'channels', 'regions'} );
  
  if ( isempty(meas) ), continue; end
  
  meas = remove( only(meas, 'choice'), 'errors' );
  
  data = meas.data;
  labs = dsp3.add_context_labels( fcat.from(meas.labels) );
  freqs = meas.frequencies;
  t = meas.get_time_series();
  
  switch ( manipulation )
    case 'pro_v_anti'
      outs = dsp3.pro_v_anti_z( data, labs, mean_spec, N );
    otherwise
      error( 'Unrecognized manipulation "%s".', manipulation );
  end
  
  z_file = struct();
  z_file.params = params;
  z_file.unified_filename = un_filename;
  z_file.zdata = outs.zdat;
  z_file.realdata = outs.realdat;
  z_file.zlabels = categorical( outs.zlabs );
  z_file.zcats = getcats( outs.zlabs );
  z_file.zdists = outs.zdists;
  z_file.zdistlabels = categorical( outs.zdistlabs );
  z_file.zdistcats = getcats( outs.zdistlabs );
  z_file.frequencies = freqs;
  z_file.time = t;
  
  shared_utils.io.require_dir( output_p );
  shared_utils.io.psave( output_filename, z_file, 'z_file' );
end

end

function validate_manipulation(manip)
assert( ismember(manip, {'pro_minus_anti', 'pro_v_anti'}) ...
  , 'Unrecognized manipulation "%s".', char(manip) );
end

function val = field_or_err(s, name)
val = s.(name);
if ( isempty(val) ), error( 'Specify a "%s".', name ); end
end