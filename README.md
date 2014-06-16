rebol
=====

Code for grounded SMT on geoquery data.
(This has nothing to do with the programming language REBOL! [0])


Dependencies
------------

_WASP_-1.0 includes the geoquery knowledge base and scripts for querying it.
The evaluation scripts were slightly modified to include the full output.
These scripts are in data/geoquery/wasp/, they go into wasp-1.0/data/geo-funql/eval/.
WASP-1.0 can be downloaded from here [1].

You'll also need some _Prolog_ environment, e.g. SWI-Prolog [2].

We use the a slightly modified implementation of _smt-semparse_,
as described in 'Semantic parsing as machine translation' (Andreas et al, ACL 2013).
Our fork can be found here [3]. This depends on more stuff, e.g. the Moses decoder
and SRILM.

For translation we use the _cdec_ toolkit, [4].

As semantic parsing is quite slow and rebol does it quite often,
results are cached with _memcached_ [5].

You'll also need the following _ruby gems_:
 * https://rubygems.org/gems/memcached
 * http://rubygems.org/gems/zipf
 * http://trollop.rubyforge.org/



---
[0] http://www.rebol.com/
[1] http://www.cs.utexas.edu/~ml/wasp/wasp-1.0.tar.bz2
[2] http://www.swi-prolog.org/
[3] https://github.com/pks/smt-semparse
[4] https://github.com/redpony/cdec
[5] http://memcached.org/

