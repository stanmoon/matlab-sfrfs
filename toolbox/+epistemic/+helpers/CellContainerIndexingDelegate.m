classdef CellContainerIndexingDelegate
% CellContainerIndexingDelegate
% Internal delegate for ceremonial subsref/subsasgn patterns on
% handle-classes that wrap a 1D cell collection.
%
% Supported first-hop indexing:
%   - S(1).type == "{}"  -> use braces accessor
%   - S(1).type == "()"  -> use parentheses accessor
%
% After resolving the first hop, any remaining indexing operations
% are forwarded via builtin("subsref", ...) or builtin("subsasgn", ...).
%
% This delegate does not prescribe any container semantics beyond the
% first hop. It simply resolves and forwards.

    methods (Static)
        function [handled, out] = trySubsrefCell(items, S)
            arguments
                items (1,:) cell
                S (1,:) struct
            end

            handled = false;
            out = [];

            if isempty(S)
                return
            end

            t = S(1).type;
            if strcmp(t, "{}")
                out = items{S(1).subs{1}};
                handled = true;
                out = epistemic.helpers.CellContainerIndexingDelegate. ...
                    forwardSubsrefTail_(out, S);
                return
            end

            if strcmp(t, "()")
                out = items(S(1).subs{:});
                handled = true;
                out = epistemic.helpers.CellContainerIndexingDelegate. ...
                    forwardSubsrefTail_(out, S);
                return
            end
        end

        function out = subsrefOrBuiltin(host, items, S)
            % subsrefOrBuiltin
            % Resolve subsref for {} and () against a cell collection and
            % otherwise fall back to builtin("subsref", host, S).
            arguments
                host (1,1)
                items (1,:) cell
                S (1,:) struct
            end

            [handled, out] = ...
                epistemic.helpers.CellContainerIndexingDelegate. ...
                trySubsrefCell(items, S);

            if handled
                return
            end

            out = builtin("subsref", host, S);
        end

        function [handled, items] = trySubsasgnBrace( ...
                items, S, value, assignFirstHopFn)
        % trySubsasgnBrace
        % Handle {} assignment into a 1D cell collection.
        %
        % Ceremony:
        %   - detect first-hop "{}"
        %   - use assignFirstHopFn(k, value) to produce the new cell 
        %     element
        %   - if tail exists, forward subsasgn into that element
        %
        % Policy:
        %   - assignFirstHopFn owns validation/conversion/replacement 
        %     semantics.
        %   - It must return the value to store in items{k} for the first 
        %     hop.
            arguments
                items (1,:) cell
                S (1,:) struct
                value
                assignFirstHopFn (1,1) function_handle
            end
        
            handled = false;
        
            if isempty(S) || ~strcmp(S(1).type, "{}")
                return
            end
        
            k = S(1).subs{1};
        
            % Policy hook must produce the base element for items{k}.
            elem = assignFirstHopFn(k, value);
        
            % Store first-hop result into the returned cell.
            items{k} = elem;
        
            % Forward any tail indexing into the element (if present).
            if numel(S) > 1
                items{k} = builtin("subsasgn", items{k}, S(2:end), value);
            end
        
            handled = true;
        end


        function tf = isBraceOrParen(S)
            arguments
                S (1,:) struct
            end

            if isempty(S)
                tf = false;
                return
            end

            tf = strcmp(S(1).type, "{}") || strcmp(S(1).type, "()");
        end
    end

    methods (Static, Access = private)
        function out = forwardSubsrefTail_(out, S)
            if numel(S) > 1
                out = builtin("subsref", out, S(2:end));
            end
        end

        function items = forwardSubsasgnTailIntoCell_(items, k, S, value)
            if numel(S) <= 1
                return
            end

            items{k} = builtin("subsasgn", items{k}, S(2:end), value);
        end
    end
end
