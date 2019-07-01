function coherence(files, event_name, varargin)

defaults = dsp3.make.defaults.coherence();
defaults.step_size = 0.05;

params = dsp3.parsestruct( defaults, varargin );

%%

lfp_file = shared_utils.general.get( files, event_name );

labels = lfp_file.labels';
renamecat( labels, 'region', 'regions' );
renamecat( labels, 'channel', 'channels' );

if ( params.reference_subtract )
  [data, labels] = dsp3.ref_subtract( lfp_file.data, labels' );
else
  data = lfp_file.data;
end

end