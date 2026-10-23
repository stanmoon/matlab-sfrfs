classdef ContrastPolarityEmptyEnsembleFixture < handle
%CONTRASTPOLARITYEMPTYENSEMBLEFIXTURE Minimal datastore test double.
% Used only for input-validation tests; does not produce observations.
    properties
        IndependentVariables string = strings(0, 1)
        ConditionVariables string = strings(0, 1)
        DataVariables string = strings(0, 1)
        SelectedVariables string = strings(0, 1)
        NumMembers double = 0
    end
    methods
        function obj = ContrastPolarityEmptyEnsembleFixture(names)
            obj.DataVariables = names(:);
        end
        function reset(~)
        end
        function tf = hasdata(~)
            tf = false;
        end
    end
end
