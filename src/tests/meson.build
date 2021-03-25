test_sources = [
    'main.vala',
    'test_case.vala',
    'utils/hex_dump_test.vala',
]

test_deps = repose_deps
test_deps += [inc_root_dep]

tests_exe = executable(
    'repose-tests',
    test_sources,
    dependencies : test_deps,
    include_directories: inc_root)

test('all-tests', tests_exe)
