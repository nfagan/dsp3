function adj_p = fdr(pvals)
      
%   FDR_BH -- Get FDR-adjusted pvalues.
%
%     http://www.mathworks.com/matlabcentral/fileexchange/27418-fdr-bh
%
%     IN:
%       - `pvals` (double)

s=size(pvals);
if (length(s)>2) || s(1)>1,
  [p_sorted, sort_ids]=sort(reshape(pvals,1,prod(s)));
else
  %p-values are already a row vector
  [p_sorted, sort_ids]=sort(pvals);
end
[~, unsort_ids]=sort(sort_ids); %indexes to return p_sorted to pvals order
m=length(p_sorted); %number of tests

wtd_p=m*p_sorted./(1:m);

%compute adjusted p-values; This can be a bit computationally intensive
adj_p=zeros(1,m)*NaN;
[wtd_p_sorted, wtd_p_sindex] = sort( wtd_p );
nextfill = 1;
for k = 1 : m
  if wtd_p_sindex(k)>=nextfill
    adj_p(nextfill:wtd_p_sindex(k)) = wtd_p_sorted(k);
    nextfill = wtd_p_sindex(k)+1;
    if nextfill>m
      break;
    end
  end
end
adj_p=reshape(adj_p(unsort_ids),s);

end