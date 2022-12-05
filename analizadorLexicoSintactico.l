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
#include <stdbool.h>

/*  Estructura definida para los tokens pertenecientes a la tabla de tokens.
*/
struct token{
    int class;
    char *value;
    char *atomo;
    int line;
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

// Nuevas Funciones Analizador Sintactico
void printStringAtoms(struct token **node);
void nextAtom(struct token **node);
void saveReference(struct token **headNode, struct token **node);
void Program(struct token **node);
void otraFunc(struct token **node);
void Func(struct token **node);
void Param(struct token **node);
void otroParam(struct token **node);
void Cuerpo(struct token **node);
void Decl(struct token **node);
void D(struct token **node);
void Tipo(struct token **node);
void K(struct token **node);
void Q(struct token **node);
void N(struct token **node);
void C(struct token **node);
void A(struct token **node);
void AP(struct token **node);
void E(struct token **node);
void EP(struct token **node);
void T(struct token **node);
void TP(struct token **node);
void F(struct token **node);
void R(struct token **node);
void RP(struct token **node);
void V(struct token **node);
void VP(struct token **node);
void VPP(struct token **node);
void VPPP(struct token **node);
void P(struct token **node);
void listaP(struct token **node);
void W(struct token **node);
void I(struct token **node);
void IP(struct token **node);
void J(struct token **node);
void Y(struct token **node);
void X(struct token **node);
void Z(struct token **node);
void H(struct token **node);
void CP(struct token **node);
void OP(struct token **node);
void U(struct token **node);
void Devuelve(struct token **node);
void valor(struct token **node);
void Llama(struct token **node);
void otroArg(struct token **node);
void arg(struct token **node);
void rechaza(char *a, char *b,struct token **node);

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

// Nuevas Estructuras Analizador Sintactico
char *atomsCatalogReser[]={"a","b","f","t","g","w","m","#","o","x","j","h","p","c","q","y","z"};
char *atomsCatalogRelat[]={"<",">","l","u","e","d"};
struct token *referenceTokenTable = NULL;
int countAtom=1;
int countNewLine=1;
bool flagCorrectSintact=true;

/* Expresiones Regulares de las 9 clases de componentes léxicos, junto con ER auxiliares en detectar errores
*/
%}
newLine \n
delimit [ \a\b\f\r\t\v]+
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
{newLine} countNewLine=countNewLine+1;
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
. printf("%s:%d: error: %s :Formato Lexico No Valido\n\n",nameFile,countNewLine,yytext);
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
    yyin = fopen(srcPath,"r");                              //Se lee el programa fuente
    outputFile = fopen("outputFile.txt","w");               //Se abre el archivo de salida
    yylex();                                                //Analisis Lexico
    saveReference(&referenceTokenTable,&tokenTable);        //Guardar la referencia del primer nodo de tokenTable
    printTables();                                          //Se imprimen las tablas en el archivo de salida
    fclose(outputFile);                                     //Se cierra el archivo de salida
    Program(&tokenTable);                                   //Analisis Sintactico
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
    printTable(&symbolTable, "Symbols");
    printTable(&realNumConstTable, "Real Numeric Constants");
    printTable(&stringTable, "String Constants");
    printTokenTable(&tokenTable);
    printStringAtoms(&tokenTable);
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
        newToken->line = countNewLine;
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

/* Funciones del Analizador Sintáctico Descendente Recursivo <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*/

/*  Funcion para guardar referencia del primer token de la tabla de Tokens.
*/
void saveReference(struct token **headNode, struct token **node){
    *headNode=*node;
}

/*  Funcion para pasar al siguiente atomo de la cadena de atomos.
*/
void nextAtom(struct token **node){
    *node = (*node)->ptrNext;
    countAtom++;
}

//Produccion 1:
void Program(struct token **node){
    if (*node == NULL){
        rechaza("b|g|#|y|x","EOF",node);
    }else if(strcmp((*node)->atomo,"b") == 0
        ||strcmp((*node)->atomo,"g") == 0
        ||strcmp((*node)->atomo,"#") == 0
        ||strcmp((*node)->atomo,"y") == 0
        ||strcmp((*node)->atomo,"x") == 0){
        Func(node);
        otraFunc(node);
    }else{
        rechaza("b|g|#|y|x",(*node)->atomo,node);
    }

    outputFile = fopen("outputFile.txt","a+");              //Se abre el archivo de salida
    if ((*node == NULL) && (flagCorrectSintact)){
        *node = referenceTokenTable;
        fprintf(outputFile,"\n%s: message: \"Programa fuente sintácticamente CORRECTO\"\n\n",nameFile);
    }else{
        *node = referenceTokenTable;
        fprintf(outputFile,"\n%s: message: \"Programa fuente sintácticamente INCORRECTO\"\n\n",nameFile);
    }
    fclose(outputFile);                                     //Se cierra el archivo de salida
}

//Produccion 2,3:
void otraFunc(struct token **node){
    if (*node == NULL){
        //No se hace nada pues es una transición epsilon
    }else if(strcmp((*node)->atomo,"b") == 0
        ||strcmp((*node)->atomo,"g") == 0
        ||strcmp((*node)->atomo,"#") == 0
        ||strcmp((*node)->atomo,"y") == 0
        ||strcmp((*node)->atomo,"x") == 0){
        Func(node);
        otraFunc(node);
    }else{
        rechaza("b|g|#|y|x|EOF",(*node)->atomo,node);
    }
}

//Produccion 4:
void Func(struct token **node){
    if (*node == NULL){
        rechaza("b|g|#|y|x","EOF",node);
    }else if(strcmp((*node)->atomo,"b") == 0
        ||strcmp((*node)->atomo,"g") == 0
        ||strcmp((*node)->atomo,"#") == 0
        ||strcmp((*node)->atomo,"y") == 0
        ||strcmp((*node)->atomo,"x") == 0){
        Tipo(node);
        if (strcmp((*node)->atomo,"i") == 0){
            nextAtom(node);
            if(strcmp((*node)->atomo,"(") == 0){
                nextAtom(node);
                Param(node);
                if(strcmp((*node)->atomo,")") == 0){
                    nextAtom(node);
                    if(strcmp((*node)->atomo,"{") == 0){
                        nextAtom(node);
                        Cuerpo(node);
                        if(strcmp((*node)->atomo,"}") == 0){
                            nextAtom(node);
                        }else{
                            rechaza("}",(*node)->atomo,node);
                        }
                    }else{
                        rechaza("{",(*node)->atomo,node);
                    }
                }else{
                    rechaza(")",(*node)->atomo,node);
                }
            }else{
                rechaza("(",(*node)->atomo,node);
            }
        }else{
            rechaza("i",(*node)->atomo,node);
        }
    }else{
        rechaza("b|g|#|y|x",(*node)->atomo,node);
    }
}


//Produccion 5,6:
void Param(struct token **node){
    if (*node == NULL){
        rechaza("b|g|#|y|x|)","EOF",node);
    }else if( (strcmp((*node)->atomo,"b") == 0)
         ||(strcmp((*node)->atomo,"g") == 0)
         ||(strcmp((*node)->atomo,"#") == 0)
         ||(strcmp((*node)->atomo,"y") == 0)
         ||(strcmp((*node)->atomo,"x") == 0) ){
        Tipo(node);
        if(strcmp((*node)->atomo,"i")==0){
            nextAtom(node);
            otroParam(node);
        }else{
            rechaza("i",(*node)->atomo,node);
        }
    } else if (strcmp((*node)->atomo,")") == 0) {
        //No se hace nada pues es una transición epsilon
    }
    else{
        rechaza("b|g|#|y|x|)",(*node)->atomo,node);
    }
}

//Produccion 7,8:
void otroParam(struct token **node){
    if (*node == NULL){
        rechaza(",|)","EOF",node);
    }else if(strcmp((*node)->atomo,",") == 0){
        nextAtom(node);
        Tipo(node);
        if (strcmp((*node)->atomo,"i") == 0){
            nextAtom(node);
        }else{
            rechaza("i",(*node)->atomo,node);
        }
        otroParam(node);
    } else if (strcmp((*node)->atomo,")") == 0){
        //No se hace nada pues es una transición epsilon
    }else{
        rechaza(",|)",(*node)->atomo,node);
    }
}

//Produccion 9:
void Cuerpo(struct token **node){
    if (*node == NULL){
        rechaza("b|g|#|y|x|i|f|h|w|j|[|z|c|}","EOF",node);
    }else if(strcmp((*node)->atomo,"b")==0
        ||strcmp((*node)->atomo,"g")==0
        ||strcmp((*node)->atomo,"#")==0
        ||strcmp((*node)->atomo,"y")==0
        ||strcmp((*node)->atomo,"x")==0
        ||strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"f")==0
        ||strcmp((*node)->atomo,"h")==0
        ||strcmp((*node)->atomo,"w")==0
        ||strcmp((*node)->atomo,"j")==0
        ||strcmp((*node)->atomo,"[")==0
        ||strcmp((*node)->atomo,"z")==0
        ||strcmp((*node)->atomo,"c")==0
        ||strcmp((*node)->atomo,"}")==0){
        Decl(node);
        listaP(node);
    }else{
        rechaza("b|g|#|y|x|i|f|h|w|j|[|z|c|}",(*node)->atomo,node);
    }
}

//Produccion 10,11:
void Decl(struct token **node){
    if (*node == NULL){
        rechaza("i|f|h|w|j|[|z|c|}|b|g|#|y|x","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"f")==0
        ||strcmp((*node)->atomo,"h")==0
        ||strcmp((*node)->atomo,"w")==0
        ||strcmp((*node)->atomo,"j")==0
        ||strcmp((*node)->atomo,"[")==0
        ||strcmp((*node)->atomo,"z")==0
        ||strcmp((*node)->atomo,"c")==0
        ||strcmp((*node)->atomo,"}")==0){
        //Produccion epsilon, no se hace alguna accion
    }else if(strcmp((*node)->atomo,"b")==0
        ||strcmp((*node)->atomo,"g")==0
        ||strcmp((*node)->atomo,"#")==0
        ||strcmp((*node)->atomo,"y")==0
        ||strcmp((*node)->atomo,"x")==0){
        D(node);
        Decl(node);
    } else {
        rechaza("i|f|h|w|j|[|z|c|}|b|g|#|y|x",(*node)->atomo,node);
    }
}

//Produccion 12:
void D(struct token **node){
    if (*node == NULL){
        rechaza("b|g|#|y|x","EOF",node);
    }else if(strcmp((*node)->atomo,"b")==0
        ||strcmp((*node)->atomo,"g")==0
        ||strcmp((*node)->atomo,"#")==0
        ||strcmp((*node)->atomo,"y")==0
        ||strcmp((*node)->atomo,"x")==0){
        Tipo(node);
        K(node);
        if(strcmp((*node)->atomo,";")==0){
            nextAtom(node);
        }else{
            rechaza(";",(*node)->atomo,node);
        }
    }else{
        rechaza("b|g|#|y|x",(*node)->atomo,node);
    }
}

//Produccion 13,14,15,16,17:
void Tipo(struct token **node){
    if (*node == NULL){
        rechaza("b|g|#|y|x","EOF",node);
    }else if(strcmp((*node)->atomo,"b")==0
        ||strcmp((*node)->atomo,"g")==0
        ||strcmp((*node)->atomo,"#")==0
        ||strcmp((*node)->atomo,"y")==0
        ||strcmp((*node)->atomo,"x")==0){
        nextAtom(node);
    }else{
        rechaza("b|g|#|y|x",(*node)->atomo,node);
    }
}

//Produccion 18:
void K(struct token **node){
    if (*node == NULL){
        rechaza("i","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
        Q(node);
    }else{
        rechaza("i",(*node)->atomo,node);
    }
}

//Produccion 19,20,21:
void Q(struct token **node){
    if (*node == NULL){
        rechaza(";|=|,","EOF",node);
    }else if(strcmp((*node)->atomo,";")==0){
        //Produccion epsilon, no se hace alguna accion
    }else if(strcmp((*node)->atomo,"=")==0){
        nextAtom(node);
        N(node);
        C(node);
    }else if(strcmp((*node)->atomo,",")==0){
        nextAtom(node);
        K(node);
    }else{
        rechaza(";|=|,",(*node)->atomo,node);
    }
}

//Produccion 22,23,24:
void N(struct token **node){
    if (*node == NULL){
        rechaza("n|r|s","EOF",node);
    }else if(strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0
        ||strcmp((*node)->atomo,"s")==0){ //sintetizamos las tres producciones de N como una
        nextAtom(node);
    }else{
        rechaza("n|r|s",(*node)->atomo,node);
    }
}

//Produccion 25,26:
void C(struct token **node){
    if (*node == NULL){
        rechaza(";|,","EOF",node);
    }else if(strcmp((*node)->atomo,";")==0){
        //Produccion epsilon, no se hace alguna accion
    }else if(strcmp((*node)->atomo,",")==0){
        nextAtom(node);
        K(node);
    } else {
        rechaza(";|,",(*node)->atomo,node);
    }
}

//Produccion 27:
void A(struct token **node){
    if (*node == NULL){
        rechaza("s|(|i|n|r|[","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
        if(strcmp((*node)->atomo,"=")==0){
            nextAtom(node);
            AP(node);
            if(strcmp((*node)->atomo,";")==0){
                nextAtom(node);
            }else{
                rechaza(";",(*node)->atomo,node);
            }
        }else{
            rechaza("=",(*node)->atomo,node);
        }
    }else{
        rechaza("i",(*node)->atomo,node);
    }
}

//Produccion 28,29:
void AP(struct token **node){
    if (*node == NULL){
        rechaza("s|(|i|n|r|[","EOF",node);
    }else if(strcmp((*node)->atomo,"s")==0){
        nextAtom(node);
    }else if(strcmp((*node)->atomo,"(")==0||strcmp((*node)->atomo,"i")==0||strcmp((*node)->atomo,"n")==0||strcmp((*node)->atomo,"r")==0||strcmp((*node)->atomo,"[")==0){
        E(node);
    }else{
        rechaza("s|(|i|n|r|[",(*node)->atomo,node); //POSIBLE ERROR----------------
    }
}

//Produccion 30:
void E(struct token **node){
    if (*node == NULL){
        rechaza("(|i|n|r|[","EOF",node);
    }else if(strcmp((*node)->atomo,"(")==0
        ||strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0
        ||strcmp((*node)->atomo,"[")==0){
        T(node);
        EP(node);
    }else{
        rechaza("(|i|n|r|[",(*node)->atomo,node);
    }
}

//Produccion 31,32,33:
void EP(struct token **node){
    if (*node == NULL){
        rechaza("+|-|)|;","EOF",node);
    }else if(strcmp((*node)->atomo,"+")==0){
        nextAtom(node);
        T(node);
        EP(node);
    }else if(strcmp((*node)->atomo,"-")==0){
        nextAtom(node);
        T(node);
        EP(node);
    }else if(strcmp((*node)->atomo,";")==0||strcmp((*node)->atomo,")")==0){
        //Transicion epsilon, no se realiza alguna acción
    }else{
        rechaza("+|-|)|;",(*node)->atomo,node);
    }
}

//Produccion 34:
void T(struct token **node){
    if (*node == NULL){
        rechaza("(|i|n|r|[","EOF",node);
    }else if(strcmp((*node)->atomo,"(")==0
        ||strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0
        ||strcmp((*node)->atomo,"[")==0){
        F(node);
        TP(node);
    }else{
        rechaza("(|i|n|r|[",(*node)->atomo,node);
    }
}

//Produccion 35,36,37,38,38,40:
void TP(struct token **node){
    if (*node == NULL){
        rechaza("*|/|\\|%|^|)|;","EOF",node);
    }else if(strcmp((*node)->atomo,"*")==0){
        nextAtom(node);
        F(node);
        TP(node);
    }else if(strcmp((*node)->atomo,"/")==0){
        nextAtom(node);
        F(node);
        TP(node);
    }else if(strcmp((*node)->atomo,"\\")==0){
        nextAtom(node);
        F(node);
        TP(node);
    }else if(strcmp((*node)->atomo,"%")==0){
        nextAtom(node);
        F(node);
        TP(node);
    }else if(strcmp((*node)->atomo,"^")==0){
        nextAtom(node);
        F(node);
        TP(node);
    }else if(strcmp((*node)->atomo,")")==0||strcmp((*node)->atomo,";")==0||strcmp((*node)->atomo,"+")==0||strcmp((*node)->atomo,"-")==0){
        //Produccion epsilon, no se hace alguna accion
    }else{
        rechaza("*|/|\\|%|^|)|;",(*node)->atomo,node);
    }
}

//Produccion 41,42,43,44,45:
void F(struct token **node){
    if (*node == NULL){
        rechaza("(|i|n|r|[","EOF",node);
    }else if(strcmp((*node)->atomo,"(")==0){
        nextAtom(node);
        E(node);
        if(strcmp((*node)->atomo,")")==0){
            nextAtom(node);
        }else{
            rechaza(")",(*node)->atomo,node);
        }
    }else if(strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0){
        nextAtom(node);
    }else if(strcmp((*node)->atomo,"[")==0){
        Llama(node);
    }else{
        rechaza("(|i|n|r|[",(*node)->atomo,node);
    }
}

//Produccion 46,47,48,49:
void R(struct token **node){
    if (*node == NULL){
        rechaza("i|n|r|s","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
        RP(node);
        V(node);
    }else if(strcmp((*node)->atomo,"n")==0){
        nextAtom(node);
        RP(node);
        VP(node);
    }else if(strcmp((*node)->atomo,"r")==0){
        nextAtom(node);
        RP(node);
        VPP(node);
    }else if(strcmp((*node)->atomo,"s")==0){
        nextAtom(node);
        RP(node);
        VPPP(node);
    }else{
        rechaza("i|n|r|s",(*node)->atomo,node);
    }
}

//Produccion 50,51,52,53,54,55:
void RP(struct token **node){
    if (*node == NULL){
        rechaza(">|<|l|e|d|u","EOF",node);
    }else if(strcmp((*node)->atomo,">")==0
        ||strcmp((*node)->atomo,"<")==0
        ||strcmp((*node)->atomo,"l")==0
        ||strcmp((*node)->atomo,"e")==0
        ||strcmp((*node)->atomo,"d")==0
        ||strcmp((*node)->atomo,"u")==0){
        nextAtom(node);
    }else{
        rechaza(">|<|l|e|d|u",(*node)->atomo,node);
    }
}

//Produccion 56,57,58,59:
void V(struct token **node){
    if (*node == NULL){
        rechaza("i|n|r|s","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0
        ||strcmp((*node)->atomo,"s")==0){
        nextAtom(node);
    }else{
        rechaza("i|n|r|s",(*node)->atomo,node);
    }
}

//Produccion 60,61:
void VP(struct token **node){
    if (*node == NULL){
        rechaza("n|i","EOF",node);
    }else if(strcmp((*node)->atomo,"n")==0||strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
    }else{
        rechaza("n|i",(*node)->atomo,node);
    }
}

//Produccion 62,63:
void VPP(struct token **node){
    if (*node == NULL){
        rechaza("r|i","EOF",node);
    }else if(strcmp((*node)->atomo,"r")==0||strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
    }else{
        rechaza("r|i",(*node)->atomo,node);
    }
}

//Produccion 64,65:
void VPPP(struct token **node){
    if (*node == NULL){
        rechaza("s|i","EOF",node);
    }else if(strcmp((*node)->atomo,"s")==0||strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
    }else{
        rechaza("s|i",(*node)->atomo,node);
    }
}

//Produccion 66,67,68,69,70,71,72,73:
void P(struct token **node){
    if (*node == NULL){
        rechaza("i|f|h|w|j|[|z|c","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0){
        A(node);
    }else if(strcmp((*node)->atomo,"f")==0){
        I(node);
    }else if(strcmp((*node)->atomo,"h")==0){
        H(node);
    }else if(strcmp((*node)->atomo,"w")==0){
        W(node);
    }else if(strcmp((*node)->atomo,"j")==0){
        J(node);
    }else if(strcmp((*node)->atomo,"[")==0){
        Llama(node);
    }else if(strcmp((*node)->atomo,"z")==0){
        Devuelve(node);
    }else if(strcmp((*node)->atomo,"c")==0){
        nextAtom(node);
        if(strcmp((*node)->atomo,";")==0){
            nextAtom(node); 
        }else{
            rechaza(";",(*node)->atomo,node);
        }
    }else{
        rechaza("i|f|h|w|j|[|z|c",(*node)->atomo,node);
    }
}

//Produccion 74,75:
void listaP(struct token **node){
    if (*node == NULL){
        rechaza("}|:|q|a|t|o|i|f|h|w|j|[|z|c","EOF",node);
    }else if(strcmp((*node)->atomo,"}")==0
        ||strcmp((*node)->atomo,":")==0
        ||strcmp((*node)->atomo,"q")==0
        ||strcmp((*node)->atomo,"a")==0
        ||strcmp((*node)->atomo,"t")==0
        ||strcmp((*node)->atomo,"o")==0){
        //al ser epsilon no avanza en la cadena
    }else if(strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"f")==0
        ||strcmp((*node)->atomo,"h")==0
        ||strcmp((*node)->atomo,"w")==0
        ||strcmp((*node)->atomo,"j")==0
        ||strcmp((*node)->atomo,"[")==0
        ||strcmp((*node)->atomo,"z")==0
        ||strcmp((*node)->atomo,"c")==0){
        P(node);
        listaP(node);
    }else{
        rechaza("}|:|q|a|t|o|i|f|h|w|j|[|z|c",(*node)->atomo,node);
    }
}

//Produccion 76:
void W(struct token **node){
    if (*node == NULL){
        rechaza("w","EOF",node);
    }else if(strcmp((*node)->atomo,"w")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,"(")==0){
            nextAtom(node);
            R(node);
            if (strcmp((*node)->atomo,")")==0){
                nextAtom(node);
                if (strcmp((*node)->atomo,"m")==0){
                    nextAtom(node);
                    if (strcmp((*node)->atomo,"{")==0){
                        nextAtom(node);
                        listaP(node);
                        if (strcmp((*node)->atomo,"}")==0){
                            nextAtom(node);
                        }else{
                            rechaza("}",(*node)->atomo,node);
                        }
                    }else{
                        rechaza("{",(*node)->atomo,node);
                    }
                }else{
                    rechaza("m",(*node)->atomo,node);
                }
            }else{
                rechaza(")",(*node)->atomo,node);
            }
        }else{
            rechaza("(",(*node)->atomo,node);
        }
    }else{
        rechaza("w",(*node)->atomo,node);
    }
}

//Produccion 77:
void I(struct token **node){
    if (*node == NULL){
        rechaza("f","EOF",node);
    }else if(strcmp((*node)->atomo,"f")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,"(")==0){
            nextAtom(node);
            R(node);
            if (strcmp((*node)->atomo,")")==0){
                nextAtom(node);
                listaP(node);
                IP(node);
                if (strcmp((*node)->atomo,":")==0){
                    nextAtom(node);
                }else{
                    rechaza(":",(*node)->atomo,node);
                }
            }else{
                rechaza(")",(*node)->atomo,node);
            }
        }else{
            rechaza("(",(*node)->atomo,node);
        }
    }else{
        rechaza("f",(*node)->atomo,node);
    }
}

//Produccion 78,79:
void IP(struct token **node){
    if (*node == NULL){
        rechaza("t|:","EOF",node);
    }else if(strcmp((*node)->atomo,"t")==0){
        nextAtom(node);
        listaP(node);
    }else if(strcmp((*node)->atomo,":")==0){
        //Produccion epsilon, no se hace alguna accion
    }else{
        rechaza("t|:",(*node)->atomo,node);
    }
}

//Produccion 80:
void J(struct token **node){
    if (*node == NULL){
        rechaza("j","EOF",node);
    }else if(strcmp((*node)->atomo,"j")==0){
        nextAtom(node);
         if (strcmp((*node)->atomo,"(")==0){
            nextAtom(node);
            Y(node);
            X(node);
            Z(node);
            if (strcmp((*node)->atomo,"{")==0){
                nextAtom(node);
                listaP(node);
                if (strcmp((*node)->atomo,"}")==0){
                    nextAtom(node);
                }else{
                    rechaza("}",(*node)->atomo,node);
                }
            }else{
                rechaza("{",(*node)->atomo,node);
            }
        }else{
            rechaza("(",(*node)->atomo,node);
        }
    }else{
        rechaza("j",(*node)->atomo,node);
    }
}

//Produccion 81,82:
void Y(struct token **node){
    if (*node == NULL){
        rechaza("i|;","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,"=")==0){
            nextAtom(node);
            E(node);
            if (strcmp((*node)->atomo,";")==0){
                nextAtom(node);
            }else{
                rechaza(";",(*node)->atomo,node);
            }
        }else{
            rechaza("=",(*node)->atomo,node);
        }
    }else if(strcmp((*node)->atomo,";")==0){
        nextAtom(node);
    }else{
        rechaza("i|;",(*node)->atomo,node);
    }
}

//Produccion 83,84:
void X(struct token **node){
    if (*node == NULL){
        rechaza("i|n|r|s|;","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0
        ||strcmp((*node)->atomo,"s")==0){
        R(node);
        if (strcmp((*node)->atomo,";")==0){
            nextAtom(node);
        }else{
            rechaza(";",(*node)->atomo,node);
        }
    }else if(strcmp((*node)->atomo,";")==0){
        nextAtom(node);
    }else{
        rechaza("i|n|r|s|;",(*node)->atomo,node);
    }
}

//Produccion 85,86:
void Z(struct token **node){
    if (*node == NULL){
        rechaza("i|)","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,"=")==0){
            nextAtom(node);
            E(node);
            if (strcmp((*node)->atomo,")")==0){
                nextAtom(node);
            }else{
                rechaza(")",(*node)->atomo,node);
            }
        }else{
            rechaza("=",(*node)->atomo,node);
        }
    }else if(strcmp((*node)->atomo,")")==0){
        nextAtom(node);
    }else{
        rechaza("i|)",(*node)->atomo,node);
    }
}

//Produccion 87:
void H(struct token **node){
    if (*node == NULL){
        rechaza("h","EOF",node);
    }else if(strcmp((*node)->atomo,"h")==0){
        nextAtom(node);
         if (strcmp((*node)->atomo,"(")==0){
            nextAtom(node);
            if (strcmp((*node)->atomo,"i")==0){
                nextAtom(node);
                if (strcmp((*node)->atomo,")")==0){
                    nextAtom(node);
                    if (strcmp((*node)->atomo,"{")==0){
                        nextAtom(node);
                        CP(node);
                        OP(node);
                        if (strcmp((*node)->atomo,"}")==0){
                            nextAtom(node);
                        }else{
                            rechaza("}",(*node)->atomo,node);
                        }
                    }else{
                        rechaza("{",(*node)->atomo,node);
                    }
                }else{
                    rechaza(")",(*node)->atomo,node);
                }
            }else{
                rechaza("i",(*node)->atomo,node);
            }
        }else{
            rechaza("(",(*node)->atomo,node);
        }
    }else{
        rechaza("h",(*node)->atomo,node);
    }
}

//Produccion 88,89:
void CP(struct token **node){
    if (*node == NULL){
        rechaza("a|}|o","EOF",node);
    }else if(strcmp((*node)->atomo,"a")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,"n")==0){
            nextAtom(node);
            if (strcmp((*node)->atomo,":")==0){
                nextAtom(node);
                listaP(node);
                U(node);
                CP(node);      
            }else{
                rechaza(":",(*node)->atomo,node);
            }
        }else{
            rechaza("n",(*node)->atomo,node);
        }
    }else if(strcmp((*node)->atomo,"}")==0
        ||strcmp((*node)->atomo,"o")==0){
        //Produccion epsilon, no se hace alguna accion
    }else{
        rechaza("a|}|o",(*node)->atomo,node);
    }
}

//Produccion 90,91:
void OP(struct token **node){
    if (*node == NULL){
        rechaza("o|}","EOF",node);
    }else if(strcmp((*node)->atomo,"o")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,":")==0){
            nextAtom(node);
            listaP(node);
        }else{
            rechaza(":",(*node)->atomo,node);
        }
    }else if(strcmp((*node)->atomo,"}")==0){
        //Produccion epsilon, no se hace alguna accion
    }else{
        rechaza("o|}",(*node)->atomo,node);
    }
}

//Produccion 92,93:
void U(struct token **node){
    if (*node == NULL){
        rechaza("q|a|}|o","EOF",node);
    }else if(strcmp((*node)->atomo,"q")==0){
        nextAtom(node);
    }else if(strcmp((*node)->atomo,"a")==0
        ||strcmp((*node)->atomo,"}")==0
        ||strcmp((*node)->atomo,"o")==0){
        //Produccion epsilon, no se hace alguna accion
    }else{
        rechaza("q|a|}|o",(*node)->atomo,node);
    }
}

//Produccion 94:
void Devuelve(struct token **node){
    if (*node == NULL){
        rechaza("z","EOF",node);
    }else if(strcmp((*node)->atomo,"z")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,"(")==0){
            nextAtom(node);
            valor(node);
            if (strcmp((*node)->atomo,")")==0){
                nextAtom(node);
                if (strcmp((*node)->atomo,";")==0){
                    nextAtom(node);
                }else{
                    rechaza(";",(*node)->atomo,node);
                }
            }else{
                rechaza(")",(*node)->atomo,node);
            }
        }else{
            rechaza("(",(*node)->atomo,node);
        }
    }else{
        rechaza("z",(*node)->atomo,node);
    }
}

//Produccion 95,96:
void valor(struct token **node){
    if (*node == NULL){
        rechaza("i|n|r|s|)","EOF",node);
    }else if(strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0
        ||strcmp((*node)->atomo,"s")==0){
        V(node);
    }else if(strcmp((*node)->atomo,")")==0){
        //produccion epsilon, no tiene instrucciones.
    }else{
        rechaza("i|n|r|s|)",(*node)->atomo,node);
    }
}

//Produccion 97:
void Llama(struct token **node){
    if (*node == NULL){
        rechaza("[","EOF",node);
    }else if(strcmp((*node)->atomo,"[")==0){
        nextAtom(node);
        if (strcmp((*node)->atomo,"i")==0){
            nextAtom(node);
            if (strcmp((*node)->atomo,"(")==0){
                nextAtom(node);
                arg(node);
                if (strcmp((*node)->atomo,")")==0){
                    nextAtom(node);
                    if (strcmp((*node)->atomo,"]")==0){
                        nextAtom(node);
                    }else{
                        rechaza("]",(*node)->atomo,node);
                    }
                }else{
                    rechaza(")",(*node)->atomo,node);
                }
            }else{
                rechaza("(",(*node)->atomo,node);
            }
        }else{
            rechaza("i",(*node)->atomo,node);
        }
    }else{
        rechaza("[",(*node)->atomo,node);
    }
}

//Produccion 98,99:
void arg(struct token **node){
    if (*node == NULL){
        rechaza(")|i|n|r|s","EOF",node);
    }else if(strcmp((*node)->atomo,")")==0){
        //produccion epsilon, no tiene instrucciones.
    }else if (strcmp((*node)->atomo,"i")==0
        ||strcmp((*node)->atomo,"n")==0
        ||strcmp((*node)->atomo,"r")==0
        ||strcmp((*node)->atomo,"s")==0){
        V(node);
        otroArg(node);
    }else{
        rechaza(")|i|n|r|s",(*node)->atomo,node);
    }
}

//Produccion 100,101:
void otroArg(struct token **node){
    if (*node == NULL){
        rechaza(",|)","EOF",node);
    }else if(strcmp((*node)->atomo,",")==0){
        nextAtom(node);
        V(node);
        otroArg(node);
    }else if(strcmp((*node)->atomo,")")==0){
        //produccion epsilon, no tiene instrucciones.
    }else{
        rechaza(",|)",(*node)->atomo,node);
    }
}

/*  Funcion rechaza la cadena de atomos.
*/
void rechaza(char *a, char *b,struct token **node){
    flagCorrectSintact=false;
    if (*node == NULL){
        *node = referenceTokenTable;
        printf("%s:EOF: error (%d): Se esperaba \"%s\" en lugar de \"%s\" :Formato Sintactico No Valido\n\n",nameFile,countAtom,a,b);
        outputFile = fopen("outputFile.txt","a+");              //Se abre el archivo de salida
        fprintf(outputFile,"\n%s: message: \"Programa fuente sintácticamente INCORRECTO\"\n\n",nameFile);
        fclose(outputFile);                                     //Se cierra el archivo de salida
        freeTables();                                           //Se libera la memoria reservada de las tablas
        exit(-1);
    }else{
        printf("%s:%d: error (%d): Se esperaba \"%s\" en lugar de \"%s\" :Formato Sintactico No Valido\n\n",nameFile,(*node)->line,countAtom,a,b);
        nextAtom(node);
    }
}