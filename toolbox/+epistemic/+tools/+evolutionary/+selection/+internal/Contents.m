% +internal
%
% Internal support routines for selection policies.
%
% This package contains instrumental routines used by selection and
% replacement policies to support decision-making over populations.
% Functions defined here induce auxiliary structure (e.g., dominance
% relations, ordering, diversity measures) that selection policies may
% consult when choosing parents or survivors.
%
% Components in this package do not constitute selection policies
% themselves. They provide intermediate computations that are meaningful
% only in the context of a specific selection decision.
%
% These routines are internal to the selection context and are not part of
% the supported public API. Their interfaces and implementations may
% evolve as selection policies are refined.
%
% See also +evolutionary/+selection
