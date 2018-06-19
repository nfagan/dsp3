function [newlabs, newinds] = match_pow_coh_sites(totlabels)

tic;

newlabs = fcat.with( getcats(totlabels) );
newinds = [];
  
coh_ind = find( totlabels, 'coherence' );
pow_ind = find( totlabels, 'power' );

[chan_i, chans] = findall( totlabels, {'channels', 'regions', 'days'}, coh_ind );

addcat( totlabels, 'siteid' );
id = 1;

ids = [];

for i = 1:numel(chan_i)
  c_chan = chans{1, i};
  c_reg = chans{2, i};
  c_day = chans{3, i};

  two_chans = strsplit( c_chan, '_' );
  two_regs = strsplit( c_reg, '_' );

  assert( numel(two_chans) == 2 && numel(two_regs) == 2);

  chan1 = two_chans{1};
  chan2 = two_chans{2};

  reg1 = two_regs{1};
  reg2 = two_regs{2};

  site1_ind = find( totlabels, {chan1, reg1, c_day}, pow_ind );
  site2_ind = find( totlabels, {chan2, reg2, c_day}, pow_ind );
  site3_ind = chan_i{i};
  
  assert( numel(findall(totlabels, 'sites', site1_ind)) == 1 );
  assert( numel(findall(totlabels, 'sites', site2_ind)) == 1 );

  append( newlabs, totlabels, site1_ind );
  append( newlabs, totlabels, site2_ind );
  append( newlabs, totlabels, site3_ind );
  
  nrep = numel( site1_ind ) + numel( site2_ind ) + numel( site3_ind );

  newinds = [ newinds; site1_ind; site2_ind; site3_ind ];
  
  ids = [ ids; repmat(id, nrep, 1) ];
  
  id = id + 1;
end

addcat( newlabs, 'siteid' );

unqs = unique( ids );

for i = 1:numel(unqs)
  setcat( newlabs, 'siteid', sprintf('siteid_%d', i), find(ids == unqs(i)) );
end

toc;

end