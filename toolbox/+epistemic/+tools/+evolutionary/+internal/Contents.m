% +internal
%
% Internal engine routines for evolutionary search.
%
% This package contains internal routines that implement the control flow
% and orchestration logic of evolutionary algorithms. Functions defined
% here support the execution of the evolutionary loop (initialization,
% evaluation, variation, selection, replacement) but do not represent
% evolutionary mechanisms or policies themselves.
%
% Components in this package act as glue between public evolutionary
% building blocks. They coordinate data flow, enforce consistency, and
% manage execution details that are intentionally kept out of the public
% API to preserve clarity and flexibility.
%
% These routines are internal to the evolutionary engine and are not part
% of the supported public API. Their interfaces and behavior may change as
% the engine is refined or extended.
%
% See also +evolutionary
