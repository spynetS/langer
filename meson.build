project('langer', 'c',
  default_options: ['warning_level=1'])

cc = meson.get_compiler('c')

# ---------------------------------------------------------------- LLVM
llvm_config = find_program('llvm-config')

llvm_cflags = run_command(
  llvm_config, '--cflags',
  check: true,
).stdout().strip().split()

llvm_ldflags = run_command(
  llvm_config, '--ldflags',
  check: true,
).stdout().strip().split()

# The Makefile used plain `--libs` (all components). If the tests need more
# than `core`, change this (e.g. add 'analysis', 'native', ...) or drop 'core'.
llvm_libs = run_command(
  llvm_config, '--libs', 'core',
  check: true,
).stdout().strip().split()

llvm_system_libs = run_command(
  llvm_config, '--system-libs',
  check: true,
).stdout().strip().split()

common_c_args = ['-Wall', '-pedantic'] + llvm_cflags
common_link_args = llvm_ldflags + llvm_libs + llvm_system_libs

# ------------------------------------------------------------- Sources
# Everything except main.c, so it can be shared with the test binary.
lib_src = files(
  'src/lexer.c',
  'src/llvm.c',
  'src/parser.c',
  'src/symbol_table.c',
  'src/type_resolver.c',
  'src/utils.c',
  'include/sb.c',
)

main_src = files('src/main.c')

# ------------------------------------------------------------ Compiler
langer = executable('langer',
  main_src + lib_src,
  c_args: common_c_args,
  link_args: common_link_args,
  install: false,
)

# --------------------------------------------------------------- Tests
# Equivalent of the Makefile's `test` (silent) and `verbose` targets.
#   meson setup build                      -> silent tests  (-DSILENT)
#   meson setup build -Dverbose_tests=true -> verbose tests
test_c_args = common_c_args

test_deps = [
  cc.find_library('m'),
  cc.find_library('rt', required: false), # librt doesn't exist on macOS
]

tests_exe = executable('tests',
  files('tests/tests.c') + lib_src,
  c_args: test_c_args,
  link_args: common_link_args,
  dependencies: test_deps,
  build_by_default: false,   # only built when running `meson test`
)

test('langer unit tests', tests_exe,
  workdir: meson.project_source_root(),
  is_parallel: false,
)
