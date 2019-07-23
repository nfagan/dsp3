function [psd, labels, freqs, t] = load_summarized_psd(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

psd_p = dsp3.get_intermediate_dir( 'original_summarized_psd', conf );
full_psd_p = fullfile( psd_p, 'targAcq-150-cc' );
psd_mats = shared_utils.io.findmat( full_psd_p );

[psd, labels, freqs, t] = bfw.load_time_frequency_measure( psd_mats ...
  , 'get_labels_func', @(x) x.labels ...
);

end