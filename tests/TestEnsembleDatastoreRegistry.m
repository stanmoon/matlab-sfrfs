classdef TestEnsembleDatastoreRegistry < matlab.unittest.TestCase
% TestEnsembleDatastoreRegistry
% 
% Validates all core functionality of the EnsembleDatastoreRegistry static 
% registry, including registration, retrieval, property equivalence, 
% listing, reconfiguration, and removal of
% fileEnsembleDatastore objects using the EnsembleMock utility.

    properties
        mock
        name = "testEnsemble"
    end

    methods(TestMethodSetup)

        function createMockEnsemble(testCase)
            testCase.mock = EnsembleMock();
            testCase.mock.prepare();
        end

    end
    methods(TestMethodTeardown)

        function cleanupMock(testCase)
            testCase.mock.cleanup();
        end
    end
    methods(Test)
        
        function testAddAndRetrieveEnsemble(testCase)
            EnsembleDatastoreRegistry.addEnsemble( ...
                name=testCase.name, ...
                datastore=testCase.mock.fileEnsembleDS);
            ds = EnsembleDatastoreRegistry.getEnsemble(testCase.name);
            src = testCase.mock.fileEnsembleDS; % The source object

            propsToCheck = {'DataVariables', 'ConditionVariables', ...
                'IndependentVariables', 'SelectedVariables', ...
                'ReadFcn', 'WriteToMemberFcn', 'Files'};

            for k = 1:numel(propsToCheck)
                prop = propsToCheck{k};
                testCase.verifyEqual(ds.(prop), src.(prop), ...
                    sprintf('Property %s does not match.', prop));
            end

            testCase.verifyClass(ds, 'fileEnsembleDatastore');
            testCase.verifyTrue(...
                EnsembleDatastoreRegistry.hasEnsemble(testCase.name));
        end

        function testGetAllNames(testCase)
            EnsembleDatastoreRegistry.addEnsemble( ...
                name=testCase.name, ...
                datastore=testCase.mock.fileEnsembleDS);
            names = EnsembleDatastoreRegistry.getAllEnsembleNames();
            testCase.verifyTrue(any(names == testCase.name));
        end

        function testReconfigureAndReset(testCase)
            EnsembleDatastoreRegistry.addEnsemble( ...
                name=testCase.name, ...
                datastore=testCase.mock.fileEnsembleDS);
            ds = EnsembleDatastoreRegistry.getEnsemble(testCase.name);
            oldVars = ds.DataVariables;
            newVars = "HorizontalAcceleration";
            EnsembleDatastoreRegistry.reconfigureEnsemble( ...
                name=testCase.name, ...
                DataVariables=newVars);
            ds2 = EnsembleDatastoreRegistry.getEnsemble(testCase.name);
            testCase.verifyEqual(ds2.DataVariables, newVars);
            testCase.verifyNotEqual(ds2.DataVariables, oldVars);
        end

        function testNotFoundException(testCase)
            testCase.verifyError(@() ...
                EnsembleDatastoreRegistry.getEnsemble("notPresent"), ...
                'sfrfs:EnsembleFactory:NotFound');
            testCase.verifyFalse(...
                EnsembleDatastoreRegistry.hasEnsemble("notPresent"));
        end

        function testRemove(testCase)
            EnsembleDatastoreRegistry.addEnsemble( ...
                name=testCase.name, ...
                datastore=testCase.mock.fileEnsembleDS);
            EnsembleDatastoreRegistry.removeEnsemble(testCase.name);
            testCase.verifyFalse(...
                EnsembleDatastoreRegistry.hasEnsemble(testCase.name));
        end
    end
end