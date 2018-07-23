function c = except_uniform(labs, cats)

c = cssetdiff( cats, getcats(labs, 'un') );

end