# creating types outside package saving llvm type

- STATUS: CLOSED
- PRIORITY: 200
- TAGS:

Currently when saving types we save it using a hashmap and the type name. 
But if we have 2 structs named Person one in main and one in person. The structs
will be saved over oneanother. We need to seperate the types.

An solution is to have a uid in the Type struct itself that refers to
which decleration it is. So instead of reling on the the name of the type, we have 
uniqe identifer for each type that we can use.

# FIXED

fixed by making every time prefixed with the pacackage
then we used this unique name to reference types
