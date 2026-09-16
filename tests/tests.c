#define STB_DS_IMPLEMENTATION
#include "./lexer.c"
#include "./parser.c"
#include "./symbol_table.c"

int main(int argc, char *argv[]) {
	/* MU_RUN_SUITE(test_suite_lexer); */
	/* MU_RUN_SUITE(test_suite_parser); */
	MU_RUN_SUITE(test_suite_symbol_table);
	MU_REPORT();
	return MU_EXIT_CODE;
}
