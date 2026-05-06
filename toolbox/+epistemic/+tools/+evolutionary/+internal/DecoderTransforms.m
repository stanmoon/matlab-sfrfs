classdef DecoderTransforms
% DecoderTransforms
%
% Low-level transformations used by genotype decoders.
%
% These utilities perform purely mechanical transformations and do not
% perform semantic validation. Structural validation must be handled by
% DecoderValidator before calling these methods.

    methods (Static)

        function codes = decodeBinaryCodesRowwise(G, p, nBits)
        % decodeBinaryCodesRowwise
        %
        % Convert a binary genotype matrix into integer codes.
        %
        % Interpretation:
        %   - Rows correspond to individuals.
        %   - Bits are grouped per parameter.
        %   - Each parameter uses nBits consecutive bits.
        %
        % Inputs
        %   G      [nIndividuals x (p*nBits)] logical or numeric
        %   p      number of parameters
        %   nBits  bits per parameter
        %
        % Output
        %   codes  [nIndividuals x p] integer codes

            G = double(logical(G));

            nIndividuals = size(G, 1);

            G = reshape(G.', nBits, p, nIndividuals);
            G = permute(G, [3 2 1]);

            weights = reshape(2.^((nBits - 1):-1:0), 1, 1, nBits);

            codes = sum(G .* weights, 3);
        end

        function Y = wrapToInterval(X, lo, hi)
        % wrapToInterval
        %
        % Wrap values into the half-open interval [lo, hi).
        %
        % Inputs
        %   X   numeric array
        %   lo  finite scalar lower bound
        %   hi  finite scalar upper bound, with hi > lo
        %
        % Output
        %   Y   wrapped array, same size as X

            Y = lo + mod(X - lo, hi - lo);
        end

    end

end