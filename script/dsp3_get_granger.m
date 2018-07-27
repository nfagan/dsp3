function kept = dsp3_get_granger(varargin)

defaults.config = dsp3.config.load();
defaults.drug_type = 'nondrug';
defaults.use_sd_thresh = true;
defaults.epoch = 'targacq';
defaults.choice_kind = 'pre_choice';
defaults.sd_threshold = 1.5;

params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
epoch = params.epoch;
conf = params.config;
sd_threshold = params.sd_threshold;

assert( all(ismember(drug_type, {'nondrug', 'drug', 'replication', 'old'})) ...
  , 'Unrecognized manipulation "%s".', drug_type );

is_drug = strcmpi( drug_type, 'drug' );

%%  LOAD

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days', 'administration' };

use_sd_thresh = params.use_sd_thresh;

if ( ~is_drug )
  if ( strcmp(drug_type, 'replication') )
    subdir = fullfile( '071718_repl_350', 'non_drug_null' );
  elseif ( strcmp(drug_type, 'old') )
    subdir = 'null';
  else
    if ( strcmp(epoch, 'targacq') )
      if ( strcmp(params.choice_kind, 'pre_choice') )
        subdir = '071618_fullfreqs';
      else
        assert( strcmp(params.choice_kind, 'post_choice'), 'Unrecognized choice kind.' );
        subdir = '072418_350';
      end
    elseif ( strcmp(epoch, 'reward') )
      subdir = '072318_350';
    else
      error( 'Unrecognized epoch "%s".', epoch );
    end
    subdir = fullfile( subdir, 'non_drug_null' );
  end
else
  subdir = 'drug_effect_null';
end

load_p = fullfile( conf.PATHS.dsp2_analyses, 'granger', subdir );

[per_epoch, files] = dsp2.analysis.granger.load_granger( load_p, epoch, is_drug, m_within );

%%

if ( use_sd_thresh )
  kept = dsp2.analysis.granger.granger_sd_threshold( per_epoch, sd_threshold );
else
  kept = per_epoch;
end

kept = kept.keep_within_freqs( [0, 100] );
kept = kept.collapse( {'sessions', 'blocks', 'recipients', 'magnitudes'} );

end