classdef RunToFailureSpectraViewer < handle
%RunToFailureSpectraViewer  Plot run-to-failure FFT snapshots as an image.
%
% Renders a member table (one run-to-failure sequence) as an image:
%   y-axis: frequency (Hz), first half only (one-sided)
%   x-axis: snapshot index (table row order)
%
% Color encodes log10(|FFT|), normalized by FFT length.
%
% Preconditions:
%   memberTable contains a spectral column with one FFT vector per snapshot
%   stored as a cell array, consistent size across snapshots.

    properties (SetAccess = private)
        memberTable table = table()
        snapshotParameters ParametersSnapshot = ...
            ParametersSnapshot.empty
    end

    properties
        parent matlab.graphics.axis.Axes = ...
            matlab.graphics.axis.Axes.empty()
    end

    methods
        function obj = RunToFailureSpectraViewer(args)
            arguments
                args.memberTable table {mustBeNonempty}
                args.snapshotParameters ParametersSnapshot {mustBeNonempty}
                args.parent matlab.graphics.axis.Axes = ...
                    matlab.graphics.axis.Axes.empty()
            end
            obj.memberTable = args.memberTable;
            obj.snapshotParameters = args.snapshotParameters;
            obj.parent = args.parent;
        end

        function ax = renderRunToFailure(obj, args)
        %renderRunToFailure Render stacked spectra as an image.
            arguments
                obj
                args.spectralColumn (1,1) string
                args.titleText (1,1) string = ...
                    "Run-to-failure spectral snapshots"
                args.freqRange (1,2) double = [NaN NaN]
                args.log10Floor (1,1) double = -5
            end

            if ~isfinite(args.log10Floor)
                error("sfrfs:viz:InvalidFloor", ...
                    "log10Floor must be a finite scalar.");
            end

            ax = obj.getAxes();

            f = obj.snapshotParameters.getFrequencyDomain();
            f = f(:);

            X = obj.extractStacked(spectralColumn = args.spectralColumn);

            if numel(f) ~= size(X, 1)
                error("sfrfs:viz:FreqAxisMismatch", ...
                    "FrequencyDomain length must match FFT bins.");
            end

            nBins = size(X, 1);
            nHalf = floor(nBins/2) + 1;

            f = f(1:nHalf);
            X = X(1:nHalf, :);

            % Optional frequency range cropping (Hz)
            fr = args.freqRange;
            if ~all(isnan(fr))
                if numel(fr) ~= 2 || any(~isfinite(fr))
                    error("sfrfs:viz:InvalidFreqRange", ...
                        "freqRange must be [fMin fMax] or [NaN NaN].");
                end
                if fr(1) >= fr(2)
                    error("sfrfs:viz:InvalidFreqRange", ...
                        "freqRange must satisfy fMin < fMax.");
                end

                idx = (f >= fr(1)) & (f <= fr(2));
                if ~any(idx)
                    error("sfrfs:viz:EmptyFreqRange", ...
                        "freqRangeHz does not overlap available axis.");
                end

                f = f(idx);
                X = X(idx, :);
            end

            % Normalize FFT and apply visualization floor
            X = X ./ nBins;

            floorVal = 10^args.log10Floor;
            Z = log10(max(abs(X), floorVal));

            imagesc(ax, 1:size(Z, 2), f, Z);
            axis(ax, 'xy');
            colormap(ax, jet);

            xlabel(ax, "Snapshot");
            ylabel(ax, "Frequency (Hz)");
            title(ax, args.titleText);

            cb = colorbar(ax);
            cb.Label.String = "log_{10}(|FFT|)";
        end
    end

    methods (Access = private)
        function ax = getAxes(obj)
            if isempty(obj.parent) || ~isvalid(obj.parent)
                fig = figure('Name', 'RunToFailureSpectraViewer');
                ax = axes(fig);
                obj.parent = ax;
            else
                ax = obj.parent;
            end
        end

        function X = extractStacked(obj, args)
            arguments
                obj
                args.spectralColumn (1,1) string
            end

            col = char(args.spectralColumn);

            if ~ismember(col, obj.memberTable.Properties.VariableNames)
                error("sfrfs:viz:MissingColumn", ...
                    "Spectral column '%s' not found.", col);
            end

            c = obj.memberTable.(col);

            if ~iscell(c) || isempty(c)
                error("sfrfs:viz:InvalidColumn", ...
                    "Column '%s' must be a nonempty cell array.", col);
            end

            ok = all(cellfun(@(x) isnumeric(x) && ~isempty(x), c));
            if ~ok
                error("sfrfs:viz:InvalidCells", ...
                    "Column '%s' must contain numeric FFT vectors.", col);
            end

            sz = cellfun(@size, c, 'UniformOutput', false);
            ref = sz{1};
            same = all(cellfun(@(s) isequal(s, ref), sz));
            if ~same
                error("sfrfs:viz:SizeMismatch", ...
                    "FFT vectors in '%s' have inconsistent sizes.", col);
            end

            X = [c{:}]; % [nFreqBins x nSnapshots]
        end
    end
end
