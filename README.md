rebol
=====

Code for grounded SMT on geoquery data or Free917 data.

(N.b. This has nothing to do with the programming language REBOL [0]!)


Dependencies
------------

###Geoquery:
_WASP_-1.0 includes the geoquery knowledge base and scripts for querying it.
The evaluation scripts were slightly modified to produce full outputs.
These scripts can be found in data/geoquery/wasp/, and they go into wasp-1.0/data/geo-funql/eval/.
WASP-1.0 can be downloaded from here [1].

You'll also need a _Prolog_ environment for geoquery, e.g. SWI-Prolog [2].

We use the a slightly modified implementation of _smt-semparse_,
as described in *Semantic parsing as machine translation* (Andreas et al, ACL 2013).
Our fork can be found here [3]. This software depends on more stuff, e.g. the Moses decoder
and SRILM.

###Free917:
The parser used for Free917 is _sempre_,
as described in *Semantic Parsing on Freebase from Question-Answer Pairs* (Berant et al, EMNLP 2013).
It can be downloaded here [4] and further dependencies can be found in QUICKSTART.md.

###Both:
For translation we use the _cdec_ toolkit, [5].

As semantic parsing is quite slow and rebol does it quite often,
results are cached with _memcached_ [6].

You'll need the following _ruby gems_:
 * https://rubygems.org/gems/memcached
 * http://rubygems.org/gems/zipf
 * http://trollop.rubyforge.org/



---
* [0] http://www.rebol.com/
* [1] http://www.cs.utexas.edu/~ml/wasp/wasp-1.0.tar.bz2
* [2] http://www.swi-prolog.org/
* [3] https://github.com/pks/smt-semparse
* [4] https://github.com/percyliang/sempre
* [5] https://github.com/redpony/cdec
* [6] http://memcached.org/

