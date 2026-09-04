package tests

import "core:testing"
import main "../src"

init :: proc (input: string) -> ^main.Parser {
    l := main.Lexer({input=input,lines=1, col=1, file=""})
    tokens := main.tokenize(&l)
    p := new(main.Parser)
    p.tokens = tokens
    return p
}


// ============================================================
// Helpers
// ============================================================

expect_binary :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_Binary {
    eb, is := expr.(main.Expr_Binary)
    testing.expect(t, is, "Expression expected was binary")
    return eb
}

expect_unary :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_Unary {
    eu, is := expr.(main.Expr_Unary)
    testing.expect(t, is, "Expression expected was unary")
    return eu
}

expect_number :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_Number {
    en, is := expr.(main.Expr_Number)
    testing.expect(t, is, "Expression expected was number")
    return en
}

expect_identifier :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_Identifier {
    ei, is := expr.(main.Expr_Identifier)
    testing.expect(t, is, "Expression expected was identifier")
    return ei
}

expect_string :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_String {
    es, is := expr.(main.Expr_String)
    testing.expect(t, is, "Expression expected was string")
    return es
}

expect_call :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_Call {
    ec, is := expr.(main.Expr_Call)
    testing.expect(t, is, "Expression expected was call")
    return ec
}

expect_subscript :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_Subscript {
    es, is := expr.(main.Expr_Subscript)
    testing.expect(t, is, "Expression expected was subscript")
    return es
}

expect_member :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_MemberAccess {
    em, is := expr.(main.Expr_MemberAccess)
    testing.expect(t, is, "Expression expected was member access")
    return em
}

expect_array :: proc(t: ^testing.T, expr: ^main.Expr) -> main.Expr_Array {
    ea, is := expr.(main.Expr_Array)
    testing.expect(t, is, "Expression expected was array")
    return ea
}


// ============================================================
// Primary expressions
// ============================================================

@(test)
test_expression_number :: proc(t: ^testing.T) {
    p := init("123")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    en := expect_number(t, expr)

    testing.expect(t, en.value == "123", "Number value was incorrect")

    main.delete_expression(expr)
}


@(test)
test_expression_zero :: proc(t: ^testing.T) {
    p := init("0")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    en := expect_number(t, expr)

    testing.expect(t, en.value == "0", "Number value was incorrect")

    main.delete_expression(expr)
}


@(test)
test_expression_float :: proc(t: ^testing.T) {
    p := init("1.5")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    en := expect_number(t, expr)

    testing.expect(t, en.value == "1.5", "Float value was incorrect")

    main.delete_expression(expr)
}


@(test)
test_expression_identifier :: proc(t: ^testing.T) {
    p := init("foo")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ei := expect_identifier(t, expr)

    testing.expect(t, ei.value == "foo", "Identifier value was incorrect")

    main.delete_expression(expr)
}


@(test)
test_expression_string :: proc(t: ^testing.T) {
    p := init(`"hello"`)
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    es := expect_string(t, expr)

    testing.expect(t, es.value == "\"hello\"", "String value was incorrect")

    main.delete_expression(expr)
}


// ============================================================
// Unary expressions
// ============================================================




@(test)
test_unary_up :: proc(t: ^testing.T) {
    p := init("foo^")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eu := expect_unary(t, expr)

    testing.expect(t, eu.operator == .UP, "Expected unary UP")

    operand := expect_identifier(t, eu.operand)
    testing.expect(t, operand.value == "foo", "Unary operand was incorrect")

    main.delete_expression(expr)
}


@(test)
test_unary_ampersand :: proc(t: ^testing.T) {
    p := init("foo&")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eu := expect_unary(t, expr)

    testing.expect(t, eu.operator == .AMPER, "Expected unary AMPER")

    operand := expect_identifier(t, eu.operand)
    testing.expect(t, operand.value == "foo", "Unary operand was incorrect")

    main.delete_expression(expr)
}


// ============================================================
// Binary arithmetic expressions
// ============================================================

@(test)
test_plus :: proc(t: ^testing.T) {
    p := init("1+1")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .PLUS, "Expected PLUS operator")

    left := expect_number(t, eb.left)
    right := expect_number(t, eb.right)

    testing.expect(t, left.value == "1", "Left operand was incorrect")
    testing.expect(t, right.value == "1", "Right operand was incorrect")

    main.delete_expression(expr)
}


@(test)
test_minus :: proc(t: ^testing.T) {
    p := init("5-2")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .MINUS, "Expected MINUS operator")

    left := expect_number(t, eb.left)
    right := expect_number(t, eb.right)

    testing.expect(t, left.value == "5", "Left operand was incorrect")
    testing.expect(t, right.value == "2", "Right operand was incorrect")

    main.delete_expression(expr)
}


@(test)
test_multiply :: proc(t: ^testing.T) {
    p := init("2*3")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .STAR, "Expected STAR operator")

    main.delete_expression(expr)
}


@(test)
test_divide :: proc(t: ^testing.T) {
    p := init("6/2")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .DIVIDE, "Expected DIVIDE operator")

    main.delete_expression(expr)
}


// ============================================================
// Comparison expressions
// ============================================================

@(test)
test_less :: proc(t: ^testing.T) {
    p := init("1<2")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .LESS, "Expected LESS operator")

    main.delete_expression(expr)
}


@(test)
test_greater :: proc(t: ^testing.T) {
    p := init("2>1")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .GREATER, "Expected GREATER operator")

    main.delete_expression(expr)
}


@(test)
test_equal :: proc(t: ^testing.T) {
    p := init("1==1")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .EQ, "Expected EQ operator")

    main.delete_expression(expr)
}


@(test)
test_less_equal :: proc(t: ^testing.T) {
    p := init("1<=2")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .LEQ, "Expected LEQ operator")

    main.delete_expression(expr)
}


@(test)
test_greater_equal :: proc(t: ^testing.T) {
    p := init("2>=1")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .GEQ, "Expected GEQ operator")

    main.delete_expression(expr)
}


// ============================================================
// Logical expressions
// ============================================================


@(test)
test_and :: proc(t: ^testing.T) {
    p := init("a&&b")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .AND, "Expected AND operator")

    main.delete_expression(expr)
}


@(test)
test_or :: proc(t: ^testing.T) {
    p := init("a||b")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .OR, "Expected OR operator")

    main.delete_expression(expr)
}


// ============================================================
// Precedence
// ============================================================

@(test)
test_precedence_multiply_over_plus :: proc(t: ^testing.T) {
    p := init("1+2*3")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)
    testing.expect(t, root.op == .PLUS, "Expected PLUS at root")

    left := expect_number(t, root.left)
    testing.expect(t, left.value == "1", "Left operand was incorrect")

    right := expect_binary(t, root.right)
    testing.expect(t, right.op == .STAR, "Expected STAR on right side")

    main.delete_expression(expr)
}


@(test)
test_precedence_parentheses :: proc(t: ^testing.T) {
    p := init("(1+2)*3")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .STAR, "Expected STAR at root")

    left := expect_binary(t, root.left)
    testing.expect(t, left.op == .PLUS, "Expected PLUS inside parentheses")

    main.delete_expression(expr)
}

@(test)
test_precedence_minus_left_associative :: proc(t: ^testing.T) {
    p := init("a-b-c")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .MINUS, "Expected MINUS at root")

    left := expect_binary(t, root.left)
    testing.expect(t, left.op == .MINUS, "Expected left-associated MINUS")

    main.delete_expression(expr)
}


@(test)
test_precedence_divide_left_associative :: proc(t: ^testing.T) {
    p := init("a/b/c")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .DIVIDE, "Expected DIVIDE at root")

    left := expect_binary(t, root.left)
    testing.expect(t, left.op == .DIVIDE, "Expected left-associated DIVIDE")

    main.delete_expression(expr)
}



@(test)
test_precedence_and_over_or :: proc(t: ^testing.T) {
    p := init("a||b&&c")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .OR, "Expected OR at root")

    right := expect_binary(t, root.right)

    testing.expect(t, right.op == .AND, "Expected AND below OR")

    main.delete_expression(expr)
}


@(test)
test_precedence_comparison_before_and :: proc(t: ^testing.T) {
    p := init("a<b&&c<d")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .AND, "Expected AND at root")

    left := expect_binary(t, root.left)
    right := expect_binary(t, root.right)

    testing.expect(t, left.op == .LESS, "Expected LESS on left")
    testing.expect(t, right.op == .LESS, "Expected LESS on right")

    main.delete_expression(expr)
}


// ============================================================
// Function calls
// ============================================================

@(test)
test_call_no_arguments :: proc(t: ^testing.T) {
    p := init("foo()")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ec := expect_call(t, expr)

    testing.expect(t, main.expr_to_string(ec.name^) == "foo", "Function name was incorrect")
    testing.expect(t, len(ec.args) == 0, "Expected zero arguments")

    main.delete_expression(expr)
}

@(test)
test_call_one_argument :: proc(t: ^testing.T) {
    p := init("foo(1)")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ec := expect_call(t, expr)

    testing.expect(t, main.expr_to_string(ec.name^) == "foo", "Function name was incorrect")
    testing.expect(t, len(ec.args) == 1, "Expected one argument")

    arg := expect_number(t, ec.args[0])
    testing.expect(t, arg.value == "1", "Argument was incorrect")

    main.delete_expression(expr)
}


@(test)
test_call_multiple_arguments :: proc(t: ^testing.T) {
    p := init("foo(1,2,3)")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ec := expect_call(t, expr)

    testing.expect(t, main.expr_to_string(ec.name^) == "foo", "Function name was incorrect")
    testing.expect(t, len(ec.args) == 3, "Expected three arguments")

    main.delete_expression(expr)
}


@(test)
test_call_expression_arguments :: proc(t: ^testing.T) {
    p := init("foo(1+2,3*4)")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ec := expect_call(t, expr)

    testing.expect(t, len(ec.args) == 2, "Expected two arguments")

    first := expect_binary(t, ec.args[0])
    second := expect_binary(t, ec.args[1])

    testing.expect(t, first.op == .PLUS, "First argument should be PLUS")
    testing.expect(t, second.op == .STAR, "Second argument should be STAR")

    main.delete_expression(expr)
}


@(test)
test_nested_call :: proc(t: ^testing.T) {
    p := init("foo(bar(1))")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    outer := expect_call(t, expr)

    testing.expect(t, main.expr_to_string(outer.name^) == "foo", "Outer function name was incorrect")
    testing.expect(t, len(outer.args) == 1, "Expected one outer argument")

    inner := expect_call(t, outer.args[0])

    testing.expect(t, main.expr_to_string(inner.name^) == "bar", "Inner function name was incorrect")

    main.delete_expression(expr)
}


// ============================================================
// Array / subscript expressions
// ============================================================

@(test)
test_subscript :: proc(t: ^testing.T) {
    p := init("foo[0]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    es := expect_subscript(t, expr)

    left := expect_identifier(t, es.left)
    index := expect_number(t, es.index)

    testing.expect(t, left.value == "foo", "Subscript left side was incorrect")
    testing.expect(t, index.value == "0", "Subscript index was incorrect")

    main.delete_expression(expr)
}


@(test)
test_subscript_expression :: proc(t: ^testing.T) {
    p := init("foo[a+1]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    es := expect_subscript(t, expr)

    index := expect_binary(t, es.index)

    testing.expect(t, index.op == .PLUS, "Expected PLUS in subscript")

    main.delete_expression(expr)
}


@(test)
test_nested_subscript :: proc(t: ^testing.T) {
    p := init("foo[0][1]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    outer := expect_subscript(t, expr)
    inner := expect_subscript(t, outer.left)

    index0 := expect_number(t, inner.index)
    index1 := expect_number(t, outer.index)

    testing.expect(t, index0.value == "0", "First index was incorrect")
    testing.expect(t, index1.value == "1", "Second index was incorrect")

    main.delete_expression(expr)
}


// ============================================================
// Member access
// ============================================================

@(test)
test_member_access :: proc(t: ^testing.T) {
    p := init("foo.age")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    em := expect_member(t, expr)

    obj := expect_identifier(t, em.obj)

    testing.expect(t, obj.value == "foo", "Member object was incorrect")
    testing.expect(t, em.member == "age", "Member name was incorrect")

    main.delete_expression(expr)
}


@(test)
test_member_access_different_name :: proc(t: ^testing.T) {
    p := init("person.name")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    em := expect_member(t, expr)

    testing.expect(t, em.member == "name", "Member name was incorrect")

    main.delete_expression(expr)
}


@(test)
test_member_then_subscript :: proc(t: ^testing.T) {
    p := init("foo.age[0]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    sub := expect_subscript(t, expr)
    member := expect_member(t, sub.left)

    testing.expect(t, member.member == "age", "Member name was incorrect")

    main.delete_expression(expr)
}



@(test)
test_subscript_then_member :: proc(t: ^testing.T) {
    p := init("foo[0].age")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    member := expect_member(t, expr)
    sub := expect_subscript(t, member.obj)

    index := expect_number(t, sub.index)

    testing.expect(t, index.value == "0", "Index was incorrect")
    testing.expect(t, member.member == "age", "Member name was incorrect")

    main.delete_expression(expr)
}

@(test)
test_subscript_member_subscript :: proc(t: ^testing.T) {
    p := init("foo[0].age[1]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    outer := expect_subscript(t, expr)
    member := expect_member(t, outer.left)
    inner := expect_subscript(t, member.obj)

    testing.expect(t, inner.index != nil, "Inner index was missing")
    testing.expect(t, outer.index != nil, "Outer index was missing")
    testing.expect(t, member.member == "age", "Member name was incorrect")

    main.delete_expression(expr)
}

// ============================================================
// Array literal expressions
// ============================================================
/*

@(test)
test_array_empty :: proc(t: ^testing.T) {
    p := init("{}")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ea := expect_array(t, expr)

    testing.expect(t, len(ea.values) == 0, "Expected empty array")

    main.delete_expression(expr)
}



@(test)
test_array_one_value :: proc(t: ^testing.T) {
    p := init("{1}")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ea := expect_array(t, expr)

    testing.expect(t, len(ea.values) == 1, "Expected one array value")

    value := expect_number(t, ea.values[0])
    testing.expect(t, value.value == "1", "Array value was incorrect")

    main.delete_expression(expr)
}


@(test)
test_array_multiple_values :: proc(t: ^testing.T) {
    p := init("{1,2,3}")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ea := expect_array(t, expr)

    testing.expect(t, len(ea.values) == 3, "Expected three array values")

    main.delete_expression(expr)
}


@(test)
test_array_expression_values :: proc(t: ^testing.T) {
    p := init("{1+2,3*4}")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ea := expect_array(t, expr)

    testing.expect(t, len(ea.values) == 2, "Expected two array values")

    first := expect_binary(t, ea.values[0])
    second := expect_binary(t, ea.values[1])

    testing.expect(t, first.op == .PLUS, "First array value should be PLUS")
    testing.expect(t, second.op == .STAR, "Second array value should be STAR")

    main.delete_expression(expr)
}


// ============================================================
// Complex expression combinations
// ============================================================
*/

@(test)
test_call_then_member :: proc(t: ^testing.T) {
    p := init("foo().bar")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    em := expect_member(t, expr)
    call := expect_call(t, em.obj)

    testing.expect(t, main.expr_to_string(call.name^) == "foo", "Call name was incorrect")
    testing.expect(t, em.member == "bar", "Member name was incorrect")

    main.delete_expression(expr)
}

@(test)
test_call_then_subscript :: proc(t: ^testing.T) {
    p := init("foo()[0]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    sub := expect_subscript(t, expr)
    call := expect_call(t, sub.left)

    testing.expect(t, main.expr_to_string(call.name^) == "foo", "Call name was incorrect")

    main.delete_expression(expr)
}


@(test)
test_subscript_then_call :: proc(t: ^testing.T) {
    p := init("foo[0]()")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    // This test is intentionally useful even if it currently fails.
    // It determines whether postfix calls can follow subscripting.
    main.delete_expression(expr)
}


@(test)
test_member_chain :: proc(t: ^testing.T) {
    p := init("foo.bar.baz")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    outer := expect_member(t, expr)
    inner := expect_member(t, outer.obj)

    testing.expect(t, inner.member == "bar", "First member was incorrect")
    testing.expect(t, outer.member == "baz", "Second member was incorrect")

    main.delete_expression(expr)
}


@(test)
test_nested_parentheses :: proc(t: ^testing.T) {
    p := init("(((1)))")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    number := expect_number(t, expr)

    testing.expect(t, number.value == "1", "Nested parentheses changed expression")

    main.delete_expression(expr)
}


@(test)
test_complex_expression :: proc(t: ^testing.T) {
    p := init("foo[0].age[1]+bar(2)*3")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .PLUS, "Expected PLUS at root")

    left := expect_subscript(t, root.left)
    member := expect_member(t, left.left)
    inner_subscript := expect_subscript(t, member.obj)

    testing.expect(t, inner_subscript.index != nil, "Missing first index")
    testing.expect(t, member.member == "age", "Expected age member")
    testing.expect(t, left.index != nil, "Missing second index")

    right := expect_binary(t, root.right)
    testing.expect(t, right.op == .STAR, "Expected STAR on right")

    call := expect_call(t, right.left)
    testing.expect(t, main.expr_to_string(call.name^) == "bar", "Expected bar call")

    main.delete_expression(expr)
}


@(test)
test_pointer_struct_array_expression :: proc(t: ^testing.T) {
    p := init("foo[0].age[1]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    outer := expect_subscript(t, expr)
    member := expect_member(t, outer.left)
    inner := expect_subscript(t, member.obj)

    inner_index := expect_number(t, inner.index)
    outer_index := expect_number(t, outer.index)

    testing.expect(t, inner_index.value == "0", "Pointer index was incorrect")
    testing.expect(t, member.member == "age", "Member was incorrect")
    testing.expect(t, outer_index.value == "1", "Array index was incorrect")

    main.delete_expression(expr)
}


// ============================================================
// Binary expressions with complex operands
// ============================================================

@(test)
test_binary_identifier_operands :: proc(t: ^testing.T) {
    p := init("a+b")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    left := expect_identifier(t, eb.left)
    right := expect_identifier(t, eb.right)

    testing.expect(t, left.value == "a", "Left identifier was incorrect")
    testing.expect(t, right.value == "b", "Right identifier was incorrect")

    main.delete_expression(expr)
}


@(test)
test_binary_call_operands :: proc(t: ^testing.T) {
    p := init("foo()+bar()")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    left := expect_call(t, eb.left)
    right := expect_call(t, eb.right)

    testing.expect(t, main.expr_to_string(left.name^) == "foo", "Left call was incorrect")
    testing.expect(t, main.expr_to_string(right.name^) == "bar", "Right call was incorrect")

    main.delete_expression(expr)
}


@(test)
test_binary_subscript_operands :: proc(t: ^testing.T) {
    p := init("a[0]+b[1]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    left := expect_subscript(t, eb.left)
    right := expect_subscript(t, eb.right)

    testing.expect(t, left.index != nil, "Left index was missing")
    testing.expect(t, right.index != nil, "Right index was missing")

    main.delete_expression(expr)
}


@(test)
test_binary_member_operands :: proc(t: ^testing.T) {
    p := init("a.x+b.y")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    left := expect_member(t, eb.left)
    right := expect_member(t, eb.right)

    testing.expect(t, left.member == "x", "Left member was incorrect")
    testing.expect(t, right.member == "y", "Right member was incorrect")

    main.delete_expression(expr)
}


// ============================================================
// Assignment expressions
// ============================================================

@(test)
test_assignment :: proc(t: ^testing.T) {
    p := init("a=1")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .EQUAL, "Expected EQUAL operator")

    left := expect_identifier(t, eb.left)
    right := expect_number(t, eb.right)

    testing.expect(t, left.value == "a", "Assignment left side was incorrect")
    testing.expect(t, right.value == "1", "Assignment right side was incorrect")

    main.delete_expression(expr)
}


@(test)
test_assignment_expression :: proc(t: ^testing.T) {
    p := init("a=1+2*3")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .EQUAL, "Expected assignment at root")

    rhs := expect_binary(t, root.right)
    testing.expect(t, rhs.op == .PLUS, "Expected PLUS on assignment RHS")

    multiply := expect_binary(t, rhs.right)
    testing.expect(t, multiply.op == .STAR, "Expected STAR below PLUS")

    main.delete_expression(expr)
}


@(test)
test_assignment_member :: proc(t: ^testing.T) {
    p := init("foo.age=10")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .EQUAL, "Expected EQUAL operator")

    left := expect_member(t, eb.left)
    testing.expect(t, left.member == "age", "Expected age member")

    main.delete_expression(expr)
}


@(test)
test_assignment_subscript :: proc(t: ^testing.T) {
    p := init("foo[0]=10")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    eb := expect_binary(t, expr)

    testing.expect(t, eb.op == .EQUAL, "Expected EQUAL operator")

    left := expect_subscript(t, eb.left)

    testing.expect(t, left.index != nil, "Expected assignment subscript")

    main.delete_expression(expr)
}


// ============================================================
// Mixed / stress expressions
// ============================================================

@(test)
test_every_postfix_layer :: proc(t: ^testing.T) {
    p := init("foo[0].bar[1]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    outer := expect_subscript(t, expr)
    member := expect_member(t, outer.left)
    inner := expect_subscript(t, member.obj)

    testing.expect(t, inner.left != nil, "Missing inner left expression")
    testing.expect(t, inner.index != nil, "Missing inner index")
    testing.expect(t, member.member == "bar", "Member was incorrect")
    testing.expect(t, outer.index != nil, "Missing outer index")

    main.delete_expression(expr)
}

/*
@(test)
test_unary_binary_combination :: proc(t: ^testing.T) {
    p := init("-a+b")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .PLUS, "Expected PLUS at root")

    unary := expect_unary(t, root.left)
    testing.expect(t, unary.operator == .MINUS, "Expected MINUS unary expression")

    main.delete_expression(expr)
}
*/



@(test)
test_binary_parenthesized_operands :: proc(t: ^testing.T) {
    p := init("(a+b)*(c-d)")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    root := expect_binary(t, expr)

    testing.expect(t, root.op == .STAR, "Expected STAR at root")

    left := expect_binary(t, root.left)
    right := expect_binary(t, root.right)

    testing.expect(t, left.op == .PLUS, "Expected PLUS on left")
    testing.expect(t, right.op == .MINUS, "Expected MINUS on right")

    main.delete_expression(expr)
}


@(test)
test_call_with_complex_expression :: proc(t: ^testing.T) {
    p := init("foo(a+b,c*d,e[0])")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    ec := expect_call(t, expr)

    testing.expect(t, len(ec.args) == 3, "Expected three arguments")

    first := expect_binary(t, ec.args[0])
    second := expect_binary(t, ec.args[1])
    third := expect_subscript(t, ec.args[2])

    testing.expect(t, first.op == .PLUS, "First argument should be PLUS")
    testing.expect(t, second.op == .STAR, "Second argument should be STAR")
    testing.expect(t, third.index != nil, "Third argument should be subscript")

    main.delete_expression(expr)
}


@(test)
test_complex_pointer_style_expression1 :: proc(t: ^testing.T) {
    p := init("foo[0]^")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    unary := expect_unary(t, expr)

    testing.expect(t, unary.operator == .UP, "Expected unary UP")

    subscript := expect_subscript(t, unary.operand)

    testing.expect(t, subscript.index != nil, "Expected array index")

    main.delete_expression(expr)
}

@(test)
test_variable_type :: proc(t: ^testing.T) {
    p := init("foo: bar;")
    defer delete(p.tokens)
    defer free(p)

    decl := main.parse_decl(p)

   _decl, is := decl.(main.Variable_Decl);
    testing.expect(t, is, "Expected variable decl")

    main.delete_decl(decl)
}


// @(test)
// test_func1 :: proc(t: ^testing.T) {
//     p := init("func main(): int { return 0; }")
//     defer delete(p.tokens)
//     defer free(p)

//     expr := main.parse_expression(p)

// //x    testing.expect(t, subscript.index != nil, "Expected array index")

//     main.delete_expression(expr)
// }
/*
@(test)
test_complex_pointer_style_expression :: proc(t: ^testing.T) {
    p := init("foo[0]^.age[1]")
    defer delete(p.tokens)
    defer free(p)

    expr := main.parse_expression(p)

    unary := expect_unary(t, expr)

    testing.expect(t, unary.operator == .UP, "Expected unary UP")

    subscript := expect_subscript(t, unary.operand)
    member := expect_member(t, subscript.left)
    inner := expect_subscript(t, member.obj)

    testing.expect(t, member.member == "age", "Expected age member")
    testing.expect(t, inner.index != nil, "Expected pointer index")
    testing.expect(t, subscript.index != nil, "Expected array index")

    main.delete_expression(expr)
}
*/
