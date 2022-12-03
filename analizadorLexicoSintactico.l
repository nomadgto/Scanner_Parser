%{
/*  Construir, en un mismo programa, los analizadores Léxico y Sintáctico Descendente 
    Recursivo que revisen programas escritos en el lenguaje definido por la gramática definida en el curso.
    Autores: Hernandez Jaimes Rogelio Yael
             Toledo Sanchez Roberto
    Fecha: 6-diciembre-2022
*/
// Se importan las bibliotecas que se usaran
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*  Estructura definida para los tokens pertenecientes a la tabla de tokens.
*/
struct token{
    int class;
    char *value;
    char *atomo;
    struct token *ptrNext;
};

/*  Estructura definida para las constantes numéricas reales, cadenas e identificadores
    pertenecientes a sus respectivas tablas de literales y tabla de simbolos.
*/
struct node{
    int position;
    char *data;
    int type;
    struct node *ptrNext;
};

/*  Prototipos de las funciones para las ER, impresion de las tablas, liberacion de memoria de las tablas,
    insercion en las tablas y busqueda de identificadores en la tabla de simbolos.
*/
FILE *outputFile;
void functionReser(void);
void functionIdent(void);
void functionNumConstInt(void);
void functionNumConstReal(void);
void functionStr(void);
void functionSpec(void);
void functionArith(void);
void functionRelat(void);
void functionAssig(void);
void printTables(void);
void freeTables(void);
void insertToken(struct token **headToken, int classInput, char *dataInput, char *atomInput);
char *insertNode(struct node **headNode, char *dataInput);
void printTable(struct node **node, char *nameTable);
void printTokenTable(struct token **node);
void deleteLastNode(struct node **headNode);
void deleteTable(struct node **headNode);
void deleteLastToken(struct token **headToken);
void deleteTokenTable(struct token **headToken);
char *searchNodeTable(struct node **headNode, char* dataInput);
void printStringAtoms(struct token **node);                         // Nueva Funcion Analizador Sintactico

/*  Apuntadores de la tabla de tokens, tablas de literales y tabla de simbolos.
    Arreglos de los catalogos de palabras reservadas y operadores relacionales.
    Apuntador con el nombre del archivo de entrada.
*/
struct token *tokenTable = NULL;
char *catalogReser[]={"alternative","big","evaluate","instead","large","loop","make","number","other","real","repeat","select","small","step","stop","symbol","throw"};
struct node *symbolTable = NULL;
struct node *realNumConstTable = NULL;
struct node *stringTable = NULL;
char *catalogRelat[]={"<",">","<=",">=","==","!="};
char *nameFile;
char *atomsCatalogReser[]={"a","b","f","t","g","w","m","#","o","x","j","h","p","c","q","y","z"};    // Nueva Funcion Analizador Sintactico
char *atomsCatalogRelat[]={"<",">","l","u","e","d"};                                                // Nueva Funcion Analizador Sintactico

/* Expresiones Regulares de las 9 clases de componentes léxicos, junto con ER auxiliares en detectar errores
*/
%}
delimit [ \a\b\f\n\r\t\v]+
reser alternative|big|evaluate|instead|large|loop|make|number|other|real|repeat|select|small|step|stop|symbol|throw
ident \$[a-zA-Z]+
real [0-9]*\.[0-9]+
oct [oO][0-7]+
dec [1-9][0-9]*|0
str \"[^\"\'][^\"\']+\"|\'[^\']\'|\"\'\"
spec [(){},:;]|\[|\]
arith [+\-*/%\\^]
relat <|>|<=|>=|==|!=
assig =
%%
{delimit}
{reser} functionReser();
{ident} functionIdent();
{real} functionNumConstReal();
{oct} functionNumConstInt();
{dec} functionNumConstInt();
{str} functionStr();
{spec} functionSpec();
{arith} functionArith();
{relat} functionRelat();
{assig} functionAssig();
. printf("%s: error: %s :Formato Lexico No Valido\n\n",nameFile,yytext);
%%
int yywrap(){}
int main(int argc, char *argv[]){

    // Se comprueba si se paso como segundo argumento el archivo de entrada
    char *srcPath = argv[1];
    if (srcPath == NULL){
        printf("\n\terror: No ingreso el archivo\n\n");
        return 0;
    }
    nameFile = srcPath;
    yyin = fopen(srcPath,"r");
    outputFile = fopen("outputFile.txt","w");
    yylex();
    //Program(); // Funcion por definir
    printTables();                                          //Se imprimen las tablas en el archivo de salida
    fclose(outputFile);                                     //Se cierra el archivo de salida
    freeTables();                                           //Se libera la memoria reservada de las tablas
    return 0;
}

/*  Funcion ER de Palabras Reservadas. Busca en el catalogo de palabras 
    reservadas la ER encontrada, obtiene el indice de la palabra reservada,
    convierte a cadena el indice, inserta el token pasando el apuntador de
    la tabla de tokens, la clase 0 y el indice.
*/
void functionReser(void){
    int index,positionSearch;
    char *position;
    for(index=0;index<17;++index){
        if (strcmp(yytext,catalogReser[index]) == 0){
            positionSearch = index;
        };
    }
    position = (char*) malloc(sizeof(positionSearch));
    sprintf(position, "%d", positionSearch);
    insertToken(&tokenTable,0,position,atomsCatalogReser[positionSearch]);
}

/*  Funcion ER de Identificadores. Busca en la tabla de simbolos la ER encontrada pasando
    el apuntador de la tabla de simbolos y la ER encontrada, obtiene el indice del identificador, 
    en forma de cadena y se verifica si ya existe el identificador en la tabla de simbolos: 
    si ya existe solo se inserta el token pasando el apuntador de la tabla 
    de tokens, la clase 1 y el indice encontrado, si no existe se inserta en la tabla de
    simbolos pasando el apuntador de la tabla de simbolos y la ER encontrada, se obtiene 
    el indice del identificador en forma de cadena y se inserta el token pasando el 
    apuntador de la tabla de tokens, la clase 1 y el indice encontrado.
*/
void functionIdent(void){
    char *positionSearch = searchNodeTable(&symbolTable,yytext);
    if (strcmp(positionSearch,"-1") == 0){
        char *position = insertNode(&symbolTable,yytext);
        insertToken(&tokenTable,1,position,"i");
    } else {
        insertToken(&tokenTable,1,positionSearch,"i");
    }
}

/*  Funcion ER de Constantes Numéricas Enteras. Se inserta el token pasando el apuntador de
    la tabla de tokens, la clase 2 y la ER encontrada.
*/
void functionNumConstInt(void){
    insertToken(&tokenTable,2,yytext,"n");
}

/*  Funcion ER de Constantes Numéricas Reales. Se inserta la ER encontrada en la tabla 
    de literales reales pasando el apuntador de la tabla de reales y la ER encontrada, 
    se obtiene el indice de la constante real en forma de cadena y se inserta el token 
    pasando el apuntador de la tabla de tokens, la clase 3 y el indice obtenido.
*/
void functionNumConstReal(void){
    char *position = insertNode(&realNumConstTable,yytext);
    insertToken(&tokenTable,3,position,"r");
}

/*  Funcion ER de Constantes Cadenas. Se inserta la ER encontrada en la tabla 
    de literales cadenas pasando el apuntador de la tabla de cadenas y la ER encontrada, 
    se obtiene el indice de la constante cadena en forma de cadena y se inserta el token 
    pasando el apuntador de la tabla de tokens, la clase 4 y el indice obtenido.
*/
void functionStr(void){
    char *position = insertNode(&stringTable,yytext);
    insertToken(&tokenTable,4,position,"s");
}

/*  Funcion ER de Simbolos Especiales. Se inserta el token pasando el apuntador de
    la tabla de tokens, la clase 5 y la ER encontrada.
*/
void functionSpec(void){
    insertToken(&tokenTable,5,yytext,yytext);
}

/*  Funcion ER de Operadores Aritmeticos. Se inserta el token pasando el apuntador de
    la tabla de tokens, la clase 6 y la ER encontrada.
*/
void functionArith(void){
    insertToken(&tokenTable,6,yytext,yytext);
}

/*  Funcion ER de Operadores Relacionales. Busca en el catalogo de operadores 
    relacionales la ER encontrada, obtiene el indice del operador relacional,
    convierte a cadena el indice, inserta el token pasando el apuntador de
    la tabla de tokens, la clase 7 y el indice.
*/
void functionRelat(void){
    int index,positionSearch;
    char *position;
    for(index=0;index<6;++index){
        if (strcmp(yytext,catalogRelat[index]) == 0){
            positionSearch = index;
        };
    }
    position = (char*) malloc(sizeof(positionSearch));
    sprintf(position, "%d", positionSearch);
    insertToken(&tokenTable,7,position,atomsCatalogRelat[positionSearch]);
}

/*  Funcion ER de Operador de Asignacion. Se inserta el token pasando el apuntador de
    la tabla de tokens, la clase 8 y la ER encontrada.
*/
void functionAssig(void){
    insertToken(&tokenTable,8,yytext,yytext);
}

/*  Funcion Imprimir Tablas. Impresion de la tabla de tokens, tabla de simbolos y 
    tablas de literales en el archivo de salida.
*/
void printTables(void){
    printStringAtoms(&tokenTable);
    printTokenTable(&tokenTable);
    printTable(&symbolTable, "Symbols");
    printTable(&realNumConstTable, "Real Numeric Constants");
    printTable(&stringTable, "String Constants");
}

/*  Funcion Liberar Memoria. Se libera la memoria reservada por la tabla de tokens, 
    tabla de simbolos y tablas de literales.
*/
void freeTables(void){
    deleteTokenTable(&tokenTable);
    deleteTable(&symbolTable);
    deleteTable(&realNumConstTable);
    deleteTable(&stringTable);
}

/*  Funcion Insercion en la Tabla de Tokens. Se inserta un token al final de la tabla de tokens.
    Recibe como parametro la referencia de la tabla de tokens, la clase, y el indice de la
    tabla de simbolos o tabla de literales correspondiente o el valor directo de la ER.
*/
void insertToken(struct token **headToken, int classInput, char *dataInput, char *atomInput){
    
    struct token *currentToken;
    struct token *previousToken;
    struct token *newToken = (struct token*) malloc(sizeof(struct token));
    
    if (newToken != NULL){
        
        int size = strlen(dataInput);
        int sizeAtom = strlen(atomInput);
        newToken->value = (char*) malloc(size*sizeof(char));
        newToken->atomo = (char*) malloc(sizeAtom*sizeof(char));
        strcpy(newToken->value, dataInput);
        strcpy(newToken->atomo, atomInput);

        newToken->class = classInput;
        previousToken = NULL;
        currentToken = *headToken;
        
        while (currentToken != NULL){
            previousToken = currentToken;
            currentToken = currentToken->ptrNext;
        }
        if(previousToken == NULL){
            newToken->ptrNext = NULL;
            *headToken = newToken;
        }else{
            previousToken->ptrNext = newToken;
            newToken->ptrNext = NULL;
        }  
    } else {
        printf("\terror: Not enough memory to complete this operation.\n");
        exit(0);
    }  
}

/*  Funcion Insercion en la Tabla de Literales o Simbolos. Se inserta una constante real o constante cadena 
    o identificador al final de su respectiva tabla. Recibe como parametro la referencia de la tabla de simbolos 
    o la tabla de literales correspondiente y el valor directo de la ER.
*/
char *insertNode(struct node **headNode, char *dataInput){
    
    struct node *currentNode;
    struct node *previousNode;
    struct node *newNode = (struct node*) malloc(sizeof(struct node));
    int size, position;
    char *positionString;
    
    if (newNode != NULL){

        size = strlen(dataInput);
        newNode->data = (char*) malloc(size*sizeof(char));
        strcpy(newNode->data, dataInput);
        newNode->type = -1;
    
        previousNode = NULL;
        currentNode = *headNode;
        
        while (currentNode != NULL){
            previousNode = currentNode;
            currentNode = currentNode->ptrNext;
        }
        if(previousNode == NULL){
            newNode->ptrNext = NULL;
            *headNode = newNode;
            newNode->position = 0;
            position = 0;
        }else{
            previousNode->ptrNext = newNode;
            newNode->ptrNext = NULL;
            newNode->position = previousNode->position + 1;
            position = (*previousNode).position + 1;
        }
        positionString = (char*) malloc(sizeof(position));
        sprintf(positionString, "%d", position);
        return positionString;
    } else {
        printf("\terror: Not enough memory to complete this operation.\n");
        exit(0);
    }
}

/*  Funcion Imprimir Tabla. Impresion de la tabla de simbolos o tablas de literales 
    en el archivo de salida. Recibe como parametro la referencia de la tabla de simbolos 
    o la tabla de literales correspondiente y el nombre de la tabla correspondiente.
    Si la tabla esta vacia imprime el mensaje.
*/
void printTable(struct node **node, char *nameTable){
    struct node *headNode = *node;
    if (*node == NULL){
        fprintf(outputFile,"\n>> Empty %s Table.\n",nameTable);
    } else {
        fprintf(outputFile,"\n>> %s Table:\n",nameTable);
        while (*node != NULL){   
            fprintf(outputFile," (%i,%s)\n",(*node)->position,(*node)->data);
            *node = (*node)->ptrNext;
        }
    }
    *node=headNode;
}

/*  Funcion Imprimir Cadena de Atomos. Impresion de la cadena de atomos en el archivo de salida.
    Recibe como parametro solo la referencia de la tabla de tokens.
    Si la tabla esta vacia imprime el mensaje.
*/
void printStringAtoms(struct token **node){
    struct token *headToken = *node;
    if (*node == NULL) {
        fprintf(outputFile,"\n>> Empty String of atoms.\n");
    } else {
        fprintf(outputFile,"\n>> String of atoms:\n");
        while (*node != NULL){
            fprintf(outputFile,"%s",(*node)->atomo);
            *node = (*node)->ptrNext;
        }
    }
    fprintf(outputFile,"\n");
    *node=headToken;
}

/*  Funcion Imprimir Tabla de Tokens. Impresion de la tabla de tokens en el archivo de salida.
    Recibe como parametro solo la referencia de la tabla de tokens.
    Si la tabla esta vacia imprime el mensaje.
*/
void printTokenTable(struct token **node){
    struct token *headToken = *node;
    if (*node == NULL) {
        fprintf(outputFile,"\n>> Empty Tokens Table.\n");
    } else {
        fprintf(outputFile,"\n>> Tokens Table:\n");
        while (*node != NULL){
            fprintf(outputFile," (%i,%s)\n",(*node)->class,(*node)->value);
            *node = (*node)->ptrNext;
        }
    }
    *node=headToken;
}

/*  Funcion Eliminar Ultimo Nodo de Tabla. Elimina el ultimo nodo de la tabla de simbolos o tablas 
    de literales y se libera la memoria reservada. Recibe como parametro la referencia de la tabla 
    de simbolos o la tabla de literales correspondiente.
*/
void deleteLastNode(struct node **headNode){
    struct node *currentNode = *headNode;
    struct node *previousNode;
    struct node *behindPreviousNode;
        
    while (currentNode != NULL){
        behindPreviousNode = previousNode;
        previousNode = currentNode;
        currentNode = currentNode->ptrNext;
    }
    behindPreviousNode->ptrNext=NULL;
    free(previousNode);
}

/*  Funcion Eliminar Tabla. Elimina toda la tabla de simbolos o tablas de literales y se libera la memoria reservada. 
    Recibe como parametro la referencia de la tabla de simbolos o la tabla de literales correspondiente.
    Cuenta la cantidad de nodos de la respectiva tabla, siendo n nodos.
    Elimina los n nodos llamando a la funcion deleteLastNode() n veces.
*/
void deleteTable(struct node **headNode){

    if (*headNode != NULL){
        struct node *nodeCounter = *headNode;
        struct node *nodeEliminator = *headNode;
        int i=0;
    
        while (nodeCounter != NULL){   
            i = i+1;
            nodeCounter = nodeCounter->ptrNext;
        }
    
        while (i != 0){   
            deleteLastNode(&nodeEliminator);
            i = i-1;
        }
    }
}

/*  Funcion Eliminar Ultimo Token de la Tabla de Tokens. Elimina el ultimo token de la tabla de tokens 
    y se libera la memoria reservada. Recibe como parametro la referencia de la tabla de tokens.
*/
void deleteLastToken(struct token **headToken){
    struct token *currentToken = *headToken;
    struct token *previousToken;
    struct token *behindPreviousToken;
        
    while (currentToken != NULL){
        behindPreviousToken = previousToken;
        previousToken = currentToken;
        currentToken = currentToken->ptrNext;
    }
    behindPreviousToken->ptrNext=NULL;
    free(previousToken);
}

/*  Funcion Eliminar Tabla de Tokens. Elimina toda la tabla de tokens y se libera la memoria reservada. 
    Recibe como parametro la referencia de la tabla de tokens.
    Cuenta la cantidad de tokens de la respectiva tabla, siendo n tokens.
    Elimina los n tokens llamando a la funcion deleteLastNode() n veces.
*/
void deleteTokenTable(struct token **headToken){

    if (*headToken != NULL){
        struct token *tokenCounter = *headToken;
        struct token *tokenEliminator = *headToken;
        int i=0;
    
        while (tokenCounter != NULL){   
            i = i+1;
            tokenCounter = tokenCounter->ptrNext;
        }
    
        while (i != 0){   
            deleteLastToken(&tokenEliminator);
            i = i-1;
        }
    }
}

/*  Funcion Buscar Nodo de Tabla. Busca en la tabla de simbolos si existe el identificador.
    Recibe como parametro la referencia de la tabla de simbolos y la ER encontrada.
    Se recorren los nodos de la respectiva tabla, siendo n nodos.
    Se verifica si ya existe el identificador en la tabla de simbolos:
    si ya existe se retorna el indice del identificador en la tabla,
    si no existe se retorna -1.
*/
char *searchNodeTable(struct node **headNode, char* dataInput){
  struct node *currentNode = *headNode;
  int position;
  char *positionString=(char*) malloc(sizeof(position));

  while (currentNode != NULL) {
    if (strcmp(currentNode->data,dataInput) == 0){
        position = currentNode->position;
        sprintf(positionString, "%d", position);
        return positionString;
    }
    currentNode = currentNode->ptrNext;
  }
  sprintf(positionString, "%d", -1);
  return positionString;
}

/* Funciones del Analizador Sintáctico Descendente Recursivo <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*/