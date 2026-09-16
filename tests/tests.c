#define STB_DS_IMPLEMENTATION
#include "./lexer.c"
#include "./parser.c"

int main(int argc, char *argv[]) {
	MU_RUN_SUITE(test_suite_lexer);
	MU_RUN_SUITE(test_suite_parser);
	MU_REPORT();
	return MU_EXIT_CODE;
}
