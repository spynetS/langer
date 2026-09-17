#ifndef TYPE_H
#define TYPE_H

#include <stdio.h>

typedef enum {
  TYPE_VOID,
  TYPE_BOOL,
  TYPE_BYTE,

  TYPE_I16,
  TYPE_I32,
  TYPE_I64,

  TYPE_F32,
  TYPE_F64,

  TYPE_POINTER,
  TYPE_ARRAY,
  TYPE_FUNCTION,

  TYPE_STRUCT,
  
  TYPE_STRING,
} TypeKind;


typedef struct Type Type;

struct Type {
  TypeKind kind;

  union {
    struct {
      Type *base;
    } Pointer;

    struct {
      Type *element;
      size_t length;
    } Array;

    struct {
      Type *return_type;
      Type **parameters; // stb dynamic array
    } Function;

    struct {
      const char *name;
      // TODO add members here
    } Struct;
  };
};

#endif
