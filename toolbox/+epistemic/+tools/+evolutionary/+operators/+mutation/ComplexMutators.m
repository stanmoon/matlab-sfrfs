classdef ComplexMutators
% ComplexMutators
% Complex-valued mutation via decoupled polar increments.
%
% The mutation is performed in polar coordinates. Given a complex atom
% z = rho * exp(1i * theta), independent increments deltaRho and
% deltaTheta are sampled using
% epistemic.tools.evolutionary.operators.mutation.PowerLaw objects and
% applied as
%   rhoNew = rho + deltaRho,
%   thetaNew = theta + deltaTheta  (wrapped to [-pi, pi]).
%
% The updated value is reconstructed as
%   zNew = rhoNew * exp(1i * thetaNew).
%
% Notes
%   The sampling is decoupled in magnitude (radial component) and phase
%   (angular component). The parameter rMin in the
%   epistemic.tools.evolutionary.operators.mutation.PowerLaw class excludes
%   a neighborhood of zero increments for numerical stability. This induces
%   exclusion bands in the realized displacement field, which are artifacts
%   of the decoupled simulation and not of the intended mutation law.
%
%   For practical values of rMin, the affected regions carry negligible
%   probability mass and are not treated explicitly.
%
%   The implementation mirrors
%   epistemic.tools.evolutionary.operators.mutation.RealMutators and
%   reuses the PowerLaw object without additional geometric corrections.

    methods (Static)

        function mutateFcn = infer(args)
        % infer  Return mutateFcn(block,i,idx)

            arguments
                args.config (1,1) ...
                    epistemic.tools.evolutionary.EngineConfig
            end

            cfg = args.config;

            alpha = cfg.getConfig(cfg.POWER_LAW_ALPHA);
            rMin = cfg.getConfig(cfg.POWER_LAW_RMIN);

            mutateFcn = @(block, i, idx) ...
                epistemic.tools.evolutionary. ...
                operators.mutation.ComplexMutators.mutate( ...
                block, i, idx, alpha, rMin);
        end

        function mutate(block, i, idx, alpha, rMin)
        % mutate  Apply complex-valued mutation in polar coordinates

            z = block.getAtoms( ...
                individualIndex = i, ...
                atomIndices = idx);

            rho = abs(z);
            theta = angle(z);

            radialLaw = epistemic.tools.evolutionary. ...
                operators.mutation.PowerLaw( ...
                lo = block.lo, ...
                hi = block.hi, ...
                alpha = alpha, ...
                rMin = rMin);

            angularLaw = epistemic.tools.evolutionary. ...
                operators.mutation.PowerLaw( ...
                lo = -pi, ...
                hi = pi, ...
                alpha = alpha, ...
                rMin = rMin);

            dRho = radialLaw.sample(rho);
            dTheta = angularLaw.sample(zeros(size(theta)));

            rhoNew = rho + dRho;
            thetaNew = mod(theta + dTheta + pi, 2 * pi) - pi;

            zNew = rhoNew .* exp(1i * thetaNew);

            block.setAtoms( ...
                individualIndex = i, ...
                atomIndices = idx, ...
                values = zNew);
        end

    end

end