% +helpers
%
% Small utility components shared across epistemic tools.
%
% This package contains lightweight helper classes and functions that
% provide ergonomic or structural support to higher level components.
% Helpers are intentionally minimal and stateless, and they do not encode
% domain specific logic or evolutionary policy.
%
% Public helpers
% --------------
% CellContainerIndexingDelegate
%   Utility class that delegates indexing operations for objects backed by
%   cell containers. It is used to provide consistent and predictable
%   subsref semantics when exposing composite structures.
%
% Notes
% -----
% Helpers are not part of the evolutionary machinery itself. They exist to
% reduce boilerplate and to isolate MATLAB specific idioms in a single
% location.
%
% See also epistemic.tools
