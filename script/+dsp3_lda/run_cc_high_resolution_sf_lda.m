function run_cc_high_resolution_sf_lda(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.spike_region = 'acc';
defaults.max_num_files = inf;
params = dsp3.parsestruct( defaults, varargin );

spike_region = validatestring( params.spike_region, {'acc', 'bla'}, mfilename, 'spike_region' );

repadd( 'dsp3/script' );

dsp2.cluster.init();

load_path = get_load_p( params );
[load_mats, mat_info] = get_load_mats( load_path, spike_region );
[data, labels, freqs, t] = load_data( load_mats, mat_info, params );

labels = fcat.from( labels );

assert_ispair( data, labels );

%%

cont = make_container( data, labels, freqs, t );

%%

to_lda = remove_nans_and_infs( cont );

n_freqs = size( to_lda.data, 2 );

base_inputs = struct();
base_inputs.n_perms = 100;
base_inputs.specificity = 'contexts';
base_inputs.analysis_type = 'lda';

if ( params.is_parallel )
  spmd
    indices = getLocalPart( codistributed(1:n_freqs) );
    
    if ( ~isempty(indices) )
      start = indices(1);
      stop = indices(end);

      fprintf( '\n %d : %d', start, stop );

      base_inputs.start = start;
      base_inputs.stop = stop;

      dsp2.analysis.lda.script.run_null_lda_cc_sf( to_lda, base_inputs );
    end
  end
  
else
  
  indices = getLocalPart( codistributed(1:n_freqs) );

  start = indices(1);
  stop = indices(end);
  
  base_inputs.start = start;
  base_inputs.stop = stop;

  fprintf( '\n %d : %d', start, stop );

  dsp2.analysis.lda.script.run_null_lda_cc_sf( to_lda, base_inputs );
end

end

function load_p = get_load_p(params)

load_p = fullfile( dsp3.dataroot(params.config), 'analyses' ...
  , 'linearized_sfcoh_data_5ms' );

end

function [mats, mat_info] = get_load_mats(load_p, spike_region)

mats = shared_utils.io.findmat( load_p );
mat_info = dsp3_lda.parse_file_identifiers( mats );

matches_region = strcmp( mat_info.regions, spike_region );
mats = mats(matches_region);
mat_info = dsp3_lda.keep_file_identifiers( mat_info, matches_region );

end

function [data, labels, freqs, t] = load_data(mats, mat_info, params)

subset_mats = mats(1:min(numel(mats), params.max_num_files));

[data, labels, freqs, t] = bfw.load_time_frequency_measure( subset_mats ...
  , 'get_labels_func', @(x) x.labels ...
  , 'load_func', @load ...
);

if ( ~hascat(labels, 'contexts') )
  dsp3.add_context_labels( labels );
  prune( labels );
end

end

function cont = make_container(data, labels, freqs, t)

cont = Container( data, SparseLabels.from_fcat(labels) );
cont = SignalContainer( cont );
cont.frequencies = freqs;
cont.start = min( t );
cont.stop = max( t );
cont.step_size = uniquetol( diff(t) );
cont.window_size = 150;
cont.fs = 1e3;

end