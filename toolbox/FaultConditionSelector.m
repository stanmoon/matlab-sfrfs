classdef FaultConditionSelector
%FaultConditionSelector  Resolve a fault-condition key to a unique row.
%
% Key:
%   (FaultGroup, Speed, Load)
%
% Usage:
%   sel = OperatingConditionSelection(speed=speedHz, load=loadkN);
%   idx = FaultConditionSelector.selectRow( ...
%       tbl, faultGroup=faultGroup, selection=sel);

    methods (Static)

        function idx = selectRow(tbl, args)
            arguments
                tbl table
                args.faultGroup (1,1) double {mustBeFinite, mustBeReal}
                args.selection (1,1) OperatingConditionSelection
            end

            faultGroup = args.faultGroup;
            sel = args.selection;

            import tables.FaultConditionTableMetaSchema;
            ms = FaultConditionTableMetaSchema;
            FG = ms.FAULTGROUP;
            SP = ms.SPEED;
            LD = ms.LOAD;

            FaultConditionSelector.mustHaveColumn_(tbl, FG);
            FaultConditionSelector.mustHaveColumn_(tbl, SP);
            FaultConditionSelector.mustHaveColumn_(tbl, LD);

            m = (tbl.(FG) == faultGroup) & ...
                (tbl.(SP) == sel.speed) & ...
                (tbl.(LD) == sel.load);

            idxs = find(m);

            if isempty(idxs)
                error( ...
                    "sfrfs:tables:FaultConditionSelector:NoMatch", ...
                    "No row matches FaultGroup=%g, Speed=%.6g Hz, " + ...
                    "Load=%.6g.", faultGroup, sel.speed, sel.load);
            end

            if numel(idxs) > 1
                error( ...
                    ['sfrfs:tables:FaultConditionSelector:' ...
                     'AmbiguousMatch'], ...
                    "Selection matches %d rows: %s.", numel(idxs), ...
                    mat2str(idxs(:)'));
            end

            idx = idxs(1);
        end

        function [rec, idx] = extractRecordStruct(tbl, args)
            arguments
                tbl table
                args.faultGroup (1,1) double {mustBeFinite, mustBeReal}
                args.selection (1,1) OperatingConditionSelection
            end

            idx = FaultConditionSelector.selectRow(tbl, ...
                faultGroup=args.faultGroup, ...
                selection=args.selection);

            rec = table2struct(tbl(idx, :));
        end
    end

    methods (Static, Access = private)

        function mustHaveColumn_(tbl, name)
            if ~ismember(name, string(tbl.Properties.VariableNames))
                error( ...
                    ['sfrfs:tables:FaultConditionSelector:' ...
                     'MissingColumn'], ...
                    "Required column '%s' is missing.", name);
            end
        end
    end
end
