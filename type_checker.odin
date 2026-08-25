package main;
import "core:fmt"
import "core:strings"

checker_get_func :: proc (program: Program, name: string) -> (Function_Decl, bool) {
    for func in program.functions {
        if func.name == name do return func, true
    }
    return {}, false
}

checker_get_var :: proc {
    checker_get_var_func,
    checker_get_var_block
}

checker_get_var_block :: proc (block: Block, name: string) -> (Variable_Decl, bool) {
    for items in block.items {
        #partial switch item in items {
            case Decl:
            #partial switch decl in item{
                case Variable_Decl:
                if decl.name == name {
                    return decl, true
                }
            }
        }
    }
    return {}, false
}

checker_get_var_func :: proc (func: Function_Decl, name: string) -> (Variable_Decl, bool) {
    if func.block == nil do return {}, false

    for arg in func.args {
        if arg.name == name {
            return arg, true
        }
    }

    return checker_get_var_block(func.block^, name)
}

expr_set_type :: proc(expr_u: ^Expr, type: Type) {
    #partial switch &expr in expr_u {
        case Expr_Subscript:
        expr.type = type
        case Expr_Number:
        expr.type = type
        case Expr_Identifier:
        expr.type = type
        case Expr_Call:
        expr.type = type
    }
}

get_member :: proc(obj: Expr_MemberAccess, member: string) -> Expr {
    // TODO make so the memberaccess obj inst an expression
    // it should be a custom union for struct, package enum etc
    // here we should return what the .member should return
    // #partial switch v in obj {
        
    // }
    return {}
}

checker_get_type :: proc(program: Program, current_func: Function_Decl, expr: ^Expr) -> Type {
    switch &value in expr {
    case Expr_MemberAccess:
        //checker_get_type(program, current_func, value.obj.(Struct_Decl))
        found := false
        struc := value.obj.type.(Struct_Decl)
        type : Type
        for i in 0..<len(struc.members) {
            member := struc.members[i]
            if member.name == value.member {
                found = true
                type = member.type
            }
        }
        if !found do parser_panic(expr^, fmt.tprintf("'{}' has no member '{}'", struc.name, value.member))
        return type
    case Expr_Unary:
        //fmt.println(expr_to_string(value.operand^))
        p_t := checker_get_type(program, current_func, value.operand)
        // have to set the real value type
        expr_set_type(value.operand, p_t) 
        
        if value.operator == .UP && !check_type(p_t, Pointer({})) && !check_type(p_t, Array({})) {
            parser_panic(value, fmt.tprintf("Can't do %s on %s because it's not right type ({})", value.operator, expr_to_string(value.operand^), p_t))
        }
        
        switch v in p_t {
        case Pointer: return v.to^
        case Array:   return v.of^
        case Basic, Struct_Decl:
            if value.operator == .UP do parser_panic(expr^, "Can't dereferance non pointer type")
            t := new(Type)
            t^ = get_expr_type(value.operand^)
            return Pointer({to=t})
        }

    case Expr_Subscript:
        type := checker_get_type(program, current_func, cast(^Expr)value.left)
        checker_get_type(program, current_func, value.index) // type checking index
        #partial switch v in type {
            case Array:
            return v.of^;
            case Pointer:
            return v.to^;
        }
        parser_panic(expr^, "Variable not an array")
        panic("NOT AN ARRAY?!")
    case Expr_Identifier:
        // look in the ast for the identifer
        //func, f_func := checker_get_func(program, value.value);
        //fmt.println("looking for", value.value)
        var, f_var := checker_get_var(current_func, value.value);
        if !f_var do parser_panic(value, fmt.tprintf("Variable '%s' not found", value.value))
        value.type = var.type // We set it here also
        return var.type
    case Expr_Array:
        //return checker_get_type(program, current_func, value.values[0]^)
        //return fmt.tprintf("%s_arr", checker_get_type(program, current_func, value.values[n0]^))
        val_type := new(Type) // FIXME MEMORY
        val_type^ = checker_get_type(program, current_func, value.values[0])
        return Array({of=val_type})

    case Expr_Number: return value.type
    case Expr_String:  return .STRING
    case Expr_Binary:
        lt := checker_get_type(program, current_func, value.left)
        rt := checker_get_type(program, current_func, value.right)
        if !check_type(lt, rt) do parser_panic(value, fmt.tprintf("Assigment types doesnt match {} != {}", lt, rt))

        return get_expr_type(expr^)
    case Expr_Call:
        func_call, found := checker_get_func(program, value.name)
        if !found do parser_panic(value , fmt.tprintf("function %s hasn't be declared", value.name))

        value.type = func_call.type;

        if len(value.args) < len(func_call.args) {
            parser_panic(value, value.args[len(value.args)-1]^, fmt.tprintf("Argument length missmatch wanted %d got %d", len(func_call.args), len(value.args)))
        }


        for i in 0..<len(value.args) {
            if i >= len(func_call.args) {
                parser_panic(value, value.args[i]^, fmt.tprintf("Argument length missmatch wanted %d got %d", len(func_call.args), len(value.args)))
            }
            func_type := func_call.args[i].type
            call_type := checker_get_type(program, current_func, value.args[i])
            parser_panic(value, fmt.tprintf("want {} got {}", type_to_string(func_type), type_to_string(call_type)), level=0)
            if !check_type(func_type, call_type) {
                parser_panic(value, value.args[i]^, fmt.tprintf("Argument missmatch {} != {}", type_to_string(func_type), type_to_string(call_type)))
            }
        }
        return func_call.type
    }
    fmt.println(expr)
    panic("TODO")
}
check_type :: proc(a, b: Type) -> bool {
    if a == nil || b == nil do return false

    switch x in a {
    case Struct_Decl:
        struc, ok := a.(Struct_Decl);
        if !ok do return false
        return x.name == struc.name 
        
    case Basic:
        y, ok := b.(Basic)
        if !ok {
            return false
        }
        if x == y do return true
        // if ((x == .FLOAT && y == .INT)  || (x == .INT && y == .FLOAT)) do return true
        // if ((x == .DOUBLE && y == .INT) || (x == .INT && y == .DOUBLE)) do return true

    case Array:
        y, ok := b.(Array)
        if !ok {
            return false
        }
        return check_type(x.of^, y.of^)

    case Pointer:
        #partial switch v in b {
            case Array:
            if v.of == nil do return true // FIXME
            return check_type(x.to^, v.of^)
            case Pointer:
            if v.to == nil do return true // FIXME
            return check_type(x.to^, v.to^)
            case Basic:
            return false //check_type(x.to^, v)
        }
    }

    return false 
}

check_block :: proc(program: Program, func: Function_Decl, block: ^Block) {
    for &items in block.items {
        switch &item in items {
        case Decl:
            switch &decl in item {
            case Variable_Decl:
                if decl.initlizer != nil {
                    init_type := checker_get_type(program, func, &decl.initlizer)
                    dec_type := decl.type
                    if !check_type(dec_type,init_type) {
                        parser_panic(decl, fmt.tprintf("Variable declartion type missmatch %s != %s", type_to_string(dec_type), type_to_string(init_type)))
                    }
                }
            case Function_Decl:
                panic("Function declartion not support in function")
            case Struct_Decl:
                panic("Function declartion not support in function")

            }
        case Stmt:
            switch &stmt in item {
            case Expr:
                checker_get_type(program, func, &stmt)
            case Return_Stmt:
                type := checker_get_type(program, func, stmt.value)
                if !check_type(func.type, type) {
                    parser_panic(stmt.value^, "Return type doesnt match function type")
                }
                stmt.type = type

            case If_Stmt:
                t := checker_get_type(program, func, stmt.condition)
                check_block(program, func, stmt.block);
                if stmt.else_block != nil do check_block(program, func, stmt.else_block);

            case While_Stmt:
                checker_get_type(program, func, stmt.condition)
                check_block(program, func, stmt.block);
            case Block:
                check_block(program, func, &stmt)
            }
        }
    }
}


check :: proc(program: Program) {
    for &func in program.functions {
        if func.block == nil do continue

        // if func has no type we assign void to it (default)
        if func.type == nil do func.type = Basic(.VOID)
        
        // go trough function block and check all types
        check_block(program, func, func.block);
    }
}
