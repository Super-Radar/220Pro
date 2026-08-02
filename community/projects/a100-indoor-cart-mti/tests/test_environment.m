function test_environment(project_root)
%TEST_ENVIRONMENT Verify free runtime dependency and writable result paths.

env = prepare_environment(project_root);
assert(exist(env.figures_dir, 'dir') == 7);
assert(exist(env.results_dir, 'dir') == 7);
assert(exist('hann', 'file') == 2 || exist('hann', 'builtin') == 5);
end

