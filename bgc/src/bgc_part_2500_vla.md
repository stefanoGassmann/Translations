<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Matrices de longitud variable (VLA)

[i[Variable-length array]<]

C permite declarar un array cuyo tamaño se determina en tiempo de ejecución. Esto te da los beneficios del dimensionamiento dinámico en tiempo de ejecución que obtienes con `malloc()`, pero sin tener que preocuparte de `free()` la memoria después.

A mucha gente no le gustan los VLAs. Por ejemplo, han sido prohibidos en el kernel de Linux. Profundizaremos más en ese razonamiento
[más tarde](#vla-general-issues).
[i[`__STDC_NO_VLA__` macro]<]

Se trata de una característica opcional del lenguaje. La macro `__STDC_NO_VLA__` se pone a `1` si los VLAs _no_ están presentes. (Eran obligatorios en C99, y luego pasaron a ser opcionales en C11).

``` {.c}
#if __STDC_NO_VLA__ == 1
   #error Sorry, need VLAs for this program!
#endif
```

[i[`__STDC_NO_VLA__` macro]>]

Pero como ni GCC ni Clang se molestan en definir esta macro, puede que le saques poco provecho.

Vamos a sumergirnos primero con un ejemplo, y luego buscaremos el diablo en los detalles.

## Lo Básico

Un array normal se declara con un tamaño constante, así:

``` {.c}
int v[10];
```

[i[Variable-length array-->defining]<]

Pero con VLAs, podemos utilizar un tamaño determinado en tiempo de ejecución para establecer la matriz, así:

``` {.c}
int n = 10;
int v[n];
```

Ahora, eso parece lo mismo, y en muchos sentidos lo es, pero esto le da la flexibilidad para calcular el tamaño que necesita, y luego obtener una matriz de exactamente ese tamaño.

Vamos a pedir al usuario que introduzca el tamaño de la matriz, y luego almacenar el índice 10 veces, en cada uno de los elementos de la matriz:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int n;
    char buf[32];

    printf("Enter a number: "); fflush(stdout);
    fgets(buf, sizeof buf, stdin);
    n = strtoul(buf, NULL, 10);

    int v[n];

    for (int i = 0; i < n; i++)
        v[i] = i * 10;

    for (int i = 0; i < n; i++)
        printf("v[%d] = %d\n", i, v[i]);
}
```

(En la línea 7, tengo un `fflush()` que debería forzar la salida de la línea aunque no tenga una nueva línea al final).

La línea 10 es donde declaramos el VLA---una vez que la ejecución pasa esa línea, el tamaño del array se establece a lo que sea `n` en ese momento.
La longitud del array no se puede cambiar más tarde.

También puedes poner una expresión entre paréntesis:

``` {.c}
int v[x * 100];
```

Algunas restricciones:

* No puedes declarar una VLA en el ámbito de un fichero, y no puedes hacer una `static` en el ámbito de un bloque^[Esto se debe a que las VLAs se asignan típicamente en la pila, mientras que las variables `static` están en el montón. Y la idea con las VLAs es que serán automáticamente desasignadas cuando el marco de la pila sea vaciado al final de la función].
* No puedes usar una lista inicializadora para inicializar el array.

Además, introducir un valor negativo para el tamaño del array invoca un comportamiento indefinido--- al menos en este universo.

[i[Variable-length array-->defining]>]

## `sizeof` y VLAs

[i[Variable-length array-->and `sizeof()`]<]

Estamos acostumbrados a que `sizeof` nos indique el tamaño en bytes de cualquier objeto, incluidas las matrices. Y los VLAs no son una excepción.

La principal diferencia es que `sizeof` en una VLA se ejecuta en _runtime_, mientras que en una variable de tamaño no variable se calcula en _tiempo de compilación_.

Pero el uso es el mismo.

Incluso se puede calcular el número de elementos de un VLA con el truco habitual de los arrays:

``` {.c}
size_t num_elems = sizeof v / sizeof v[0];
```

Hay una implicación sutil y correcta en la línea anterior: la aritmética de punteros funciona como cabría esperar para una matriz normal. Así que adelante, úsala a tu antojo:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int n = 5;
    int v[n];

    int *p = v;

    *(p+2) = 12;
    printf("%d\n", v[2]);  // 12

    p[3] = 34;
    printf("%d\n", v[3]);  // 34
}
```

Al igual que con las matrices normales, puede utilizar paréntesis con `sizeof()` para obtener el tamaño de un posible VLA sin tener que declararlo:

``` {.c}
int x = 12;

printf("%zu\n", sizeof(int [x]));  // Imprime 48 en mi sistema
```

[i[Variable-length array-->and `sizeof()`]>]

## VLA multidimensionales

[i[Variable-length array-->multidimensional]<]

puede seguir adelante y hacer todo tipo de VLA con una o más dimensiones establecidas en una variable

``` {.c}
int w = 10;
int h = 20;

int x[h][w];
int y[5][w];
int z[10][w][20];
```

De nuevo, puedes navegar por ellas como lo harías por un array normal.

[i[Variable-length array-->multidimensional]>]

## Pasar VLAs unidimensionales a funciones

[i[Variable-length array-->passing to functions]<]

Pasar VLAs unidimensionales a una función no puede ser diferente de pasar un array normal. Basta con hacerlo.

``` {.c .numberLines}
#include <stdio.h>

int sum(int count, int *v)
{
    int total = 0;

    for (int i = 0; i < count; i++)
        total += v[i];

    return total;
}

int main(void)
{
    int x[5];   // Standard array

    int a = 5;
    int y[a];   // VLA

    for (int i = 0; i < a; i++)
        x[i] = y[i] = i + 1;

    printf("%d\n", sum(5, x));
    printf("%d\n", sum(a, y));
}
```

Pero hay algo más. También puedes hacer saber a C que el array tiene un tamaño VLA específico pasándolo primero y luego dando esa dimensión en la lista de parámetros:

``` {.c}
int sum(int count, int v[count])
{
    // ...
}
```

[i[Variable-length array-->in function prototypes]<]
[i[`*` for VLA function prototypes]<]

Por cierto, hay un par de formas de listar un prototipo para la función anterior; una de ellas implica un `*` si no se quiere nombrar específicamente el valor en el VLA. Sólo indica que el tipo es un VLA en lugar de un puntero normal.

Prototipos VLA:

``` {.c}
void do_something(int count, int v[count]);  // Con nombres
void do_something(int, int v[*]);            // Sin nombres
```

De nuevo, eso de `*` sólo funciona con el prototipo--en la función en sí, tendrás que poner el tamaño explícito.

[i[`*` for VLA function prototypes]>]
[i[Variable-length array-->in function prototypes]>]

Ahora... ¡vamos a lo multidimensional! Aquí empieza la diversión.

## Pasar VLAs multidimensionales a funciones

Lo mismo que hicimos con la segunda forma de VLAs unidimensionales, arriba, pero esta vez pasamos dos dimensiones y las usamos.

En el siguiente ejemplo, construimos una matriz de tabla de multiplicación de anchura y altura variables, y luego la pasamos a una función para que la imprima. Aquí empieza la diversión.

``` {.c .numberLines}
#include <stdio.h>

void print_matrix(int h, int w, int m[h][w])
{
    for (int row = 0; row < h; row++) {
        for (int col = 0; col < w; col++)
            printf("%2d ", m[row][col]);
        printf("\n");
    }
}

int main(void)
{
    int rows = 4;
    int cols = 7;

    int matrix[rows][cols];

    for (int row = 0; row < rows; row++)
        for (int col = 0; col < cols; col++)
            matrix[row][col] = row * col;

    print_matrix(rows, cols, matrix);
}
```

### VLA multidimensionales parciales

Puede tener algunas de las dimensiones fijas y otras variables. Digamos que tenemos una longitud de registro fija en 5 elementos, pero no sabemos cuántos registros hay.

``` {.c .numberLines}
#include <stdio.h>

void print_records(int count, int record[count][5])
{
    for (int i = 0; i < count; i++) {
        for (int j = 0; j < 5; j++)
            printf("%2d ", record[i][j]);
        printf("\n");
    }
}

int main(void)
{
    int rec_count = 3;
    int records[rec_count][5];

    // Fill with some dummy data
    for (int i = 0; i < rec_count; i++)
        for (int j = 0; j < 5; j++)
            records[i][j] = (i+1)*(j+2);

    print_records(rec_count, records);
}
```

[i[Variable-length array-->passing to functions]>]

## Compatibilidad con matrices regulares

[i[Variable-length array-->with regular arrays]<]

Dado que los VLA son como matrices normales en memoria, es perfectamente permisible pasarlos indistintamente... siempre que las dimensiones coincidan.

Por ejemplo, si tenemos una función que específicamente quiere un array de $3\times5$, podemos pasarle un VLA.

``` {.c}
int foo(int m[5][3]) {...}

\\ ...

int w = 3, h = 5;
int matrix[h][w];

foo(matrix);   // OK!
```

Del mismo modo, si tiene una función VLA, puede pasarle una matriz normal:

``` {.c}
int foo(int h, int w, int m[h][w]) {...}

\\ ...

int matrix[3][5];

foo(3, 5, matrix);   // OK!
```

Pero cuidado: si las dimensiones no coinciden, es probable que se produzcan comportamientos indefinidos.
[i[Variable-length array-->with regular arrays]>]

## `typedef` Y VLAs

[i[Variable-length array-->with `typedef`]<]

Puedes `typedef` un VLA, pero el comportamiento puede no ser el que esperas.

Básicamente, `typedef` hace un nuevo tipo con los valores tal y como existían en el momento en que se ejecutó `typedef`.

Así que no es un `typedef` de un VLA tanto como un nuevo tipo de array de tamaño fijo de las dimensiones en ese momento.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int w = 10;

    typedef int goat[w];

    // goat es un array de 10 ints
    goat x;

    // Init con cuadrados de números
    for (int i = 0; i < w; i++)
        x[i] = i*i;

    // Imprimirlos
    for (int i = 0; i < w; i++)
        printf("%d\n", x[i]);

    // Ahora vamos a cambiar w...

    w = 20;

    // Pero cabra es TODAVÍA un array de 10 ints, porque ese era el
    // valor de w cuando se ejecutó el typedef.
}
```

Así que actúa como un array de tamaño fijo.

Pero todavía no se puede utilizar una lista de inicializadores en él.

[i[Variable-length array-->with `typedef`]>]

## Salto de Trampas

[i[Variable-length array-->with `goto`]<]

Hay que tener cuidado cuando se usa `goto` cerca de VLAs porque muchas cosas no son legales.

[i[Variable-length array-->with `goto`]>]
[i[Variable-length array-->with `longjmp()`]<]

Y cuando usas `longjmp()` hay un caso en el que podrías tener fugas de memoria con VLAs.
[i[Variable-length array-->with `longjmp()`]>]

Pero ambas cosas las trataremos en sus respectivos capítulos.


## Cuestiones generales {#vla-general-issues}

[i[Variable-length array-->controversy]<]

Los VLAs han sido prohibidos en el kernel de Linux por varias razones:

* Muchos de los lugares en los que se usaban deberían haber sido de tamaño fijo.
* El código detrás de los VLAs es más lento (en un grado que la mayoría de la gente no notaría, pero que marca la diferencia en un sistema operativo).
* No todos los compiladores de C soportan VLA en el mismo grado.
* El tamaño de la pila es limitado, y los VLAs van en la pila. Si algún código accidentalmente (o maliciosamente) pasa un valor grande a una función del núcleo que asigna un VLA, _Bad Things_™ podría suceder.

Otras personas en línea señalan que no hay manera de detectar un fallo en la asignación de un VLA, y los programas que sufrieran tales problemas probablemente simplemente se bloquearían. Aunque las matrices de tamaño fijo también tienen el mismo problema, es mucho más probable que alguien haga accidentalmente una _VLA de tamaño inusual_ que declarar accidentalmente una matriz de tamaño fijo, digamos, de 30 megabytes.

[i[Variable-length array-->controversy]>]
[i[Variable-length array]>]
