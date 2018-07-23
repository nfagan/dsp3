function kept = dsp3_get_granger(varargin)

defaults.drug_type = 'nondrug';
defaults.use_sd_thresh = true;
defaults.config = dsp3.config.load();

params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
conf = params.config;

assert( all(ismember(drug_type, {'nondrug', 'drug', 'replication'})) ...
  , 'Unrecognized manipulation "%s".', drug_type );

is_drug = strcmpi( drug_type, 'drug' );

%%  LOAD

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days', 'administration' };

use_sd_thresh = params.use_sd_thresh;

if ( ~is_drug )
%   subdir = 'null';  % MAIN NON_DRUG RESULT 
%   subdir = fullfile( '121117', 'non_drug_null' ); % reward
%   subdir = fullfile( '120717', 'non_drug_null' ); % targacq
%   subdir = fullfile( '071718_repl_350', 'non_drug_null' );
  if ( strcmp(drug_type, 'replication') )
    subdir = fullfile( '071718_repl_350', 'non_drug_null' );
  else
    subdir = fullfile( '071618_fullfreqs', 'non_drug_null' );
  end
%   subdir = fullfile( '071518', 'non_drug_null' );
%   subdir = fullfile( '071318', 'non_drug_null' ); % targacq, redux
%   subdir = fullfile( '121217', 'non_drug_null' ); % targon
%   subdir = 'null';
else
  subdir = 'drug_effect_null';
end

load_p = fullfile( conf.PATHS.dsp2_analyses, 'granger', subdir );

[per_epoch, files] = dsp2.analysis.granger.load_granger( load_p, 'targacq', is_drug, m_within );

%%

if ( use_sd_thresh )
  kept = dsp2.analysis.granger.granger_sd_threshold( per_epoch, 1.5 );
else
  kept = per_epoch;
end

kept = kept.keep_within_freqs( [0, 100] );
kept = kept.collapse( {'sessions', 'blocks', 'recipients', 'magnitudes'} );

end