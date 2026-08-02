function run_tests()
%RUN_TESTS Run the project's MATLAB/Octave-compatible unit tests.

tests_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(tests_dir);
addpath(fullfile(project_root, 'src'));
addpath(tests_dir);

tests = {@() test_environment(project_root), @test_adc_loader};
names = {'environment', 'ADC loader'};
for idx = 1:numel(tests)
    fprintf('[TEST] %s ... ', names{idx});
    tests{idx}();
    fprintf('PASS\n');
end
fprintf('%d test groups passed.\n', numel(tests));
end

run_tests();

