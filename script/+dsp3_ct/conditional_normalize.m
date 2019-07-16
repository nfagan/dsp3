function use_data = conditional_normalize(tf, targ, base)

if ( tf )
  use_data = targ - base;
else
  use_data = targ;
end

end