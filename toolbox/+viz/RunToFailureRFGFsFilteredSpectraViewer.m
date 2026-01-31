classdef RunToFailureRFGFsFilteredSpectraViewer < handle
%RunToFailureRFGFsFilteredSpectraViewer
%
% Current implementation:
%   - All computation is delegated to CenterSurroundCompute.compute().
%   - The viewer renders response matrices as log10 images.
%
% Contrast rendering note:
%   The contrast provider is responsible for semantic consistency of the
%   returned contrast response (including its sign convention). This viewer
%   only adapts signed contrasts for log visualization:
%     - If contrast contains negative values, it renders either the 
%       positive or negative component (selected via invertGainSign).
%     - If contrast is nonnegative, it is rendered directly and
%       invertGainSign has no effect.

    properties (SetAccess = private)
        memberTable table = table()
        snapshotParameters ParametersSnapshot = ParametersSnapshot.empty
        rfgfs ReceptiveFieldGainFunctions
    end

    properties
        parent matlab.graphics.axis.Axes = ...
            matlab.graphics.axis.Axes.empty()
    end

    properties (Access = private)
        csc CenterSurroundCompute = CenterSurroundCompute.empty()
    end

    methods
        function obj = RunToFailureRFGFsFilteredSpectraViewer(args)
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

        function ax = renderFiltered(obj, args)
        %renderFiltered Render response image for a fault condition selection.
        %
        % ax = renderFiltered(Name=Value, ...)
        %
        % Selection (choose one):
        %   - row
        %   - faultType + selection
        %
        % Name-Value:
        %   spectralColumn - FFT cell column in memberTable.
        %   row            - Row index into gainFunctionsTable.
        %   faultType      - Fault type key used to resolve fault group.
        %   selection      - OperatingConditionSelection for row resolve.
        %   maskType       - CENTER | SURROUND | CONTRAST
        %   freqRangeHz    - [fMin fMax] or [NaN NaN] for full range.
        %   titleText      - Optional title.
        %   log10Floor     - Floor in log10 units (default: -5).
        %   invertGainSign - For contrast: show negative lobe (default: false)

            arguments
                obj
                args.spectralColumn (1,1) string

                args.row double = []
                args.faultType (1,1) string = ""
                args.selection OperatingConditionSelection = ...
                    OperatingConditionSelection.empty()

                args.maskType (1,1) string = ""
                args.freqRangeHz (1,2) double = [NaN NaN]
                args.titleText (1,1) string = ""
                args.log10Floor (1,1) double = -5
                args.invertGainSign (1,1) logical = false
            end


            if ~isfinite(args.log10Floor)
                error("sfrfs:viz:InvalidFloor", ...
                    "log10Floor must be a finite scalar.");
            end

            import structs.FrequencyBankMasksSchema
            kCenter = FrequencyBankMasksSchema.CENTER;
            kSur    = FrequencyBankMasksSchema.SURROUND;
            kCon    = FrequencyBankMasksSchema.CONTRAST;

            if args.maskType == ""
                maskType = kCon;
            else
                maskType = args.maskType;
            end

            allowed = [kCenter, kSur, kCon];
            if ~any(maskType == allowed)
                error("sfrfs:viz:InvalidMaskType", ...
                    "maskType must be one of: %s.", ...
                    strjoin(allowed, ", "));
            end

            ax = obj.getAxes();

            f = obj.snapshotParameters.getFrequencyDomain();
            f = f(:);

            nBins = numel(f);
            nHalf = floor(nBins/2) + 1;

            rf = @(Xin, ~) abs(Xin) ./ nBins;

            [contrast, Rc, Rs] = obj.csc.compute( ...
                memberTable=obj.memberTable, ...
                spectralColumn=args.spectralColumn, ...
                row=args.row, ...
                faultType=args.faultType, ...
                selection=args.selection, ...
                receptiveFieldResponseFunction=rf, ...
                contrastMapping=function_handle.empty());

            if maskType == kCenter
                A = Rc;
            elseif maskType == kSur
                A = Rs;
            else
                A = contrast;

                % If contrast is signed, select which lobe to visualize.
                % If contrast is nonnegative, render directly.
                hasNeg = any(A(:) < 0);
                if hasNeg
                    if args.invertGainSign
                        A = max(-A, 0);
                    else
                        A = max(A, 0);
                    end
                else
                    A = max(A, 0);
                end
            end


            f = f(1:nHalf);
            A = A(1:nHalf, :);

            fr = args.freqRangeHz;
            obj.validateFreqRange(fr);

            if ~all(isnan(fr))
                idx = (f >= fr(1)) & (f <= fr(2));

                if ~any(idx)
                    error("sfrfs:viz:EmptyFreqRange", ...
                        "freqRangeHz does not overlap available axis.");
                end

                f = f(idx);
                A = A(idx, :);
            end

            floorVal = 10^args.log10Floor;
            Z = log10(max(A, floorVal));

            imagesc(ax, 1:size(Z, 2), f, Z);
            axis(ax, "xy");
            colormap(ax, jet);

            xlabel(ax, "Snapshot");
            ylabel(ax, "Frequency (Hz)");

            title(ax, obj.defaultTitle(maskType, args.titleText));

            cb = colorbar(ax);
            cb.Label.String = "log_{10}(response)";
        end
    end

    methods (Access = private)
        function ax = getAxes(obj)
            if isempty(obj.parent) || ~isvalid(obj.parent)
                fig = figure("Name", ...
                    "RunToFailureRFGFsFilteredSpectraViewer");
                ax = axes(fig);
                obj.parent = ax;
            else
                ax = obj.parent;
            end
        end

        function t = defaultTitle(~, maskType, titleText)
            arguments
                ~
                maskType (1,1) string
                titleText (1,1) string
            end

            if titleText ~= ""
                t = titleText;
                return
            end

            import structs.FrequencyBankMasksSchema
            kCenter = FrequencyBankMasksSchema.CENTER;
            kSur    = FrequencyBankMasksSchema.SURROUND;

            if maskType == kCenter
                t = "Filtered spectrum (center)";
            elseif maskType == kSur
                t = "Filtered spectrum (surround)";
            else
                t = "Filtered spectrum (contrast)";
            end
        end

        function validateFreqRange(~, fr)
            if numel(fr) ~= 2
                error("sfrfs:viz:InvalidFreqRange", ...
                    "freqRangeHz must be [fMin fMax] or [NaN NaN].");
            end

            if all(isnan(fr))
                return
            end

            if any(~isfinite(fr))
                error("sfrfs:viz:InvalidFreqRange", ...
                    "freqRangeHz must be finite [fMin fMax] or [NaN NaN].");
            end

            if fr(1) >= fr(2)
                error("sfrfs:viz:InvalidFreqRange", ...
                    "freqRangeHz must satisfy fMin < fMax.");
            end
        end

    end
end
