classdef RunToFailureSFRFsViewer < handle
%RunToFailureSFRFsViewer  Visualize SFRFs over snapshots (run-to-failure).
%
% Design:
%   - All computation is delegated to CenterSurroundCompute.compute().
%   - This viewer only plots the returned SFRF vector over snapshots.
%
% Exploratory injection:
%   - receptiveFieldResponseFunction and contrastMapping are forwarded
%     verbatim to the compute layer, which defines defaults when empty.

    properties (SetAccess = private)
        memberTable table = table()
        snapshotParameters ParametersSnapshot = ParametersSnapshot.empty()
        rfgfs ReceptiveFieldGainFunctions
    end

    properties
        parent matlab.graphics.axis.Axes = ...
            matlab.graphics.axis.Axes.empty()
        % Axes. If empty or invalid, renderSFRF() creates figure+axes.
    end

    properties (Access = private)
        csc CenterSurroundCompute = CenterSurroundCompute.empty()
    end

    methods
        function obj = RunToFailureSFRFsViewer(args)
            arguments
                args.memberTable table {mustBeNonempty}
                args.snapshotParameters ParametersSnapshot {mustBeNonempty}
                args.rfgfs ReceptiveFieldGainFunctions {mustBeNonempty}
                args.parent matlab.graphics.axis.Axes = ...
                    matlab.graphics.axis.Axes.empty()
            end

            obj.memberTable = args.memberTable;
            obj.snapshotParameters = args.snapshotParameters;
            obj.rfgfs = args.rfgfs;
            obj.parent = args.parent;

            obj.csc = CenterSurroundCompute( ...
                snapshotParameters=obj.snapshotParameters, ...
                rfgfs=obj.rfgfs);
        end

        function ax = renderSFRF(obj, args)
        %renderSFRF Plot SFRF over snapshots.
        %
        % ax = renderSFRF(Name=Value, ...)
        %
        % Selection (choose one):
        %   - row
        %   - faultType + selection
        %
        % Name-Value:
        %   spectralColumn                 - FFT cell column in memberTable.
        %   row                            - Row in gainFunctionsTable.
        %   faultType                      - Key to resolve fault group.
        %   selection                      - OperatingConditionSelection.
        %   titleText                      - Optional title.
        %   receptiveFieldResponseFunction - rf(X, f) -> r(1,nSnap).
        %   contrastMapping                - cm(Rc, Rs, p) -> c(1,nSnap).

            arguments
                obj
                args.spectralColumn (1,1) string
            
                args.row double = []
                args.faultType (1,1) string = ""
                args.selection OperatingConditionSelection = ...
                    OperatingConditionSelection.empty()
            
                args.titleText (1,1) string = ""
            
                args.receptiveFieldResponseFunction (1,1) ...
                    function_handle = ...
                    ReceptiveFieldResponseFunctions.integralAbs()
                args.contrastMapping function_handle = ...
                    function_handle.empty()
            end

            obj.validateSelection(args);
            ax = obj.getAxes();
            cla(ax);

            sfrf = obj.csc.compute( ...
                memberTable=obj.memberTable, ...
                spectralColumn=args.spectralColumn, ...
                row=args.row, ...
                faultType=args.faultType, ...
                selection=args.selection, ...
                receptiveFieldResponseFunction= ...
                    args.receptiveFieldResponseFunction, ...
                contrastMapping=args.contrastMapping);

            y = sfrf(:);
            x = (1:numel(y)).';

            plot(ax, x, y);
            grid(ax, "on");

            xlabel(ax, "Snapshot");
            ylabel(ax, "SFRF");
            title(ax, obj.defaultTitle(args.titleText));
        end
    end

    methods (Access = private)
        function ax = getAxes(obj)
            if isempty(obj.parent) || ~isvalid(obj.parent)
                fig = figure("Name", "RunToFailureSFRFsViewer");
                ax = axes(fig);
                obj.parent = ax;
            else
                ax = obj.parent;
            end
        end

        function validateSelection(~, args)
            hasRow = ~isempty(args.row);
            hasKey = (args.faultType ~= "");
            hasSel = ~isempty(args.selection);

            if hasRow && (hasKey || hasSel)
                error("sfrfs:viz:AmbiguousSelection", ...
                    "Specify either row OR faultType + selection.");
            end

            if ~hasRow && ~(hasKey && hasSel)
                error("sfrfs:viz:MissingSelection", ...
                    "Specify row OR faultType + selection.");
            end
        end

        function t = defaultTitle(~, titleText)
            if titleText ~= ""
                t = titleText;
            else
                t = "SFRF";
            end
        end
    end
end
