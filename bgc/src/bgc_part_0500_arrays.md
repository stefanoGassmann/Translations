<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Arrays {#arrays}

> "¿Los índices de las matrices deben empezar en 0 o en 1?  
> Mi compromiso de 0.5 fue rechazado sin, pensé, la debida consideración."_
>
> ---Stan Kelly-Bootle, informático

[i[Arrays]<]Por suerte, C tiene matrices. Ya sé que se considera un lenguaje de bajo nivel
^[Hoy en día, por lo menos], pero al menos incorpora el concepto de arrays. Y como
muchos lenguajes se inspiraron en la sintaxis de C, probablemente ya estés
familiarizado con el uso de `[` y `]` para declarar y usar matrices.

Pero C apenas tiene arrays. Como veremos más adelante, los arrays, en el fondo, son sólo azúcar sintáctico
en C---en realidad son todo punteros. Pero por ahora,
usémoslos como arrays. _Phew_.

## Ejemplo sencillo

Pongamos un ejemplo:

[i[Arrays-->indexing]<]
``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i;
    float f[4];  // Declara un array de 4 floats

    f[0] = 3.14159;  // La indexación empieza en 0, por supuesto.
    f[1] = 1.41421;
    f[2] = 1.61803;
    f[3] = 2.71828;

    // Imprímelos todos:

    for (i = 0; i < 4; i++) {
        printf("%f\n", f[i]);
    }
}
```

Cuando declaras un array, tienes que darle un tamaño. Y el tamaño tiene que ser fijo
^[De nuevo, en realidad no, pero las matrices de longitud variable 
-de las que no soy muy fan- son una historia para otro momento].

En el ejemplo anterior, hicimos un array de 4 `float`s. El valor entre corchetes
de la declaración nos lo indica.

Más tarde, en las líneas siguientes, accedemos a los valores de la matriz, estableciéndolos
u obteniéndolos, de nuevo con corchetes.
[i[Arrays-->indexing]>]

Espero que le suenen de alguno de los idiomas que ya conoce.

## Obtener la longitud de una matriz

[i[Arrays-->getting the length]<]
No puedes...ish. C no registra esta información^[Dado que los arrays son sólo punteros
al primer elemento del array bajo el capó, no hay información adicional que registre
la longitud]. Tienes que gestionarlo por separado en otra variable.

Cuando digo "no se puede", en realidad quiero decir que hay algunas circunstancias
en las que _se puede_. Hay un truco para obtener el número de elementos de un array
en el ámbito en el que se declara un array. Pero, en general, esto no funcionará como
quieres si pasas el array a una función^[Porque cuando pasas un array a una función,
en realidad sólo estás pasando un puntero al primer elemento de ese array, no el
array "entero"].


Veamos este truco. La idea básica es que usted toma el [i[`sizeof` operator-->with arrays]<]`
sizeof` de la matriz, y luego se divide por el tamaño de cada elemento para obtener la
longitud. 
Por ejemplo, si un `int` es de 4 bytes, y la matriz es de 32 bytes de largo, debe
haber espacio para $\frac{32}{4}$ o $8$ `int`s allí.

``` {.c}
int x[12];  // 12 ints

printf("%zu\n", sizeof x);     // 48 bytes totales
printf("%zu\n", sizeof(int));  // 4 bytes por int

printf("%zu\n", sizeof x / sizeof(int));  // 48/4 = 12 ints!
```

Si es un array de `char`s, entonces `sizeof` del array _es_ el número de
elementos, ya que `sizeof(char)` está definido como 1. Para cualquier otro tipo,
tienes que dividir por el tamaño de cada elemento.

Pero este truco sólo funciona en el ámbito en el que se definió el array.
Si pasas el array a una función, no funciona. Incluso si lo haces "grande" en la
firma de la función:

``` {.c}
void foo(int x[12])
{
    printf("%zu\n", sizeof x);     // ¡8?! ¿Qué ha sido del 48?
    printf("%zu\n", sizeof(int));  // 4 bytes por int

    printf("%zu\n", sizeof x / sizeof(int));  // 8/4 = 2 ints?? INCORRECTO.
}
```
Esto se debe a que cuando "pasas" arrays a funciones, sólo estás pasando un puntero
al primer elemento, y eso es lo que mide `sizeof`. Más sobre esto en la sección, [Pasar arrays unidimensionales a funciones](#passing1darrays). más abajo.

Otra cosa que puedes hacer con `sizeof` y arrays es obtener el tamaño de un array
de un número fijo de elementos sin declarar el array. Es como obtener el tamaño
de un `int` con `sizeof(int)`.

Por ejemplo, para ver cuántos bytes se necesitarían para un array de 48
`dobles`s, puedes hacer esto:

``` {.c}
sizeof(double [48]);
```
[i[`sizeof` operator-->with arrays]>]
[i[Arrays-->getting the length]>]

## Inicializadores de matrices

[i[Array initializers]<]
Puedes inicializar un array de antemano:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i;
    int a[5] = {22, 37, 3490, 18, 95};  // Inicializar con estos valores

    for (i = 0; i < 5; i++) {
        printf("%d\n", a[i]);
    }
}
```

Nunca debes tener más elementos en tu inicializador de los que caben en el array, o
el compilador se pondrá de mal humor:

``` {.zsh}
foo.c: In function ‘main’:
foo.c:6:39: warning: excess elements in array initializer
    6 |     int a[5] = {22, 37, 3490, 18, 95, 999};
      |                                       ^~~
foo.c:6:39: note: (near initialization for ‘a’)
```

Pero (¡dato curioso!) puedes tener _menos_ elementos en tu inicializador de los
que caben en el array. Los elementos restantes de la matriz se inicializarán
automáticamente con cero. Esto es cierto en general para todos los tipos de inicializadores
de matrices: si tienes un inicializador, todo lo que no se establezca explícitamente
a un valor se establecerá a cero.

``` {.c}
int a[5] = {22, 37, 3490};

// Es lo mismo que:

int a[5] = {22, 37, 3490, 0, 0};
```

Es un atajo común ver esto en un inicializador cuando quieres poner un array entero a cero:

``` {.c}
int a[100] = {0};
```

Lo que significa, "Haz el primer elemento cero, y luego automáticamente
haz el resto cero, también".

También puedes establecer elementos específicos del array en el inicializador,
especificando un índice para el valor. Cuando haces esto, C seguirá inicializando
los valores subsiguientes por ti hasta que el inicializador se agote, llenando
todo lo demás con `0`.

Para hacer esto, pon el índice entre corchetes con un `=` después, y luego establece el valor.

Aquí hay un ejemplo donde construimos un array:

``` {.c}
int a[10] = {0, 11, 22, [5]=55, 66, 77};
```

Como hemos puesto el índice 5 como inicio para `55`, los datos resultantes
en el array son:

``` {.default}
0 11 22 0 0 55 66 77 0 0
```

También puedes introducir expresiones constantes sencillas.

``` {.c}
#define COUNT 5

int a[COUNT] = {[COUNT-3]=3, 2, 1};
```

que nos da:

``` {.default}
0 0 3 2 1
```

Por último, también puedes hacer que C calcule el tamaño del array a partir
del inicializador, simplemente dejando el tamaño desactivado:

``` {.c}
int a[3] = {22, 37, 3490};

// Es lo mismo que:

int a[] = {22, 37, 3490};  // ¡Dejé el tamaño!
```
[i[Array initializers]>]

## ¡Fuera de los límites! (Out of Bounds!)

[i[Arrays-->out of bounds]<]
C no te impide acceder a matrices fuera de los límites. Puede que ni siquiera te avise.

Robemos el ejemplo de arriba y sigamos imprimiendo el final del array. Sólo tiene 5 elementos,
pero vamos a tratar de imprimir 10 y ver lo que sucede:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i;
    int a[5] = {22, 37, 3490, 18, 95};

    for (i = 0; i < 10; i++) {  // MALAS NOTICIAS: ¡imprime demasiados elementos!
        printf("%d\n", a[i]);
    }
}
```

Ejecutándolo en mi computadora imprime:

``` {.default}
22
37
3490
18
95
32765
1847052032
1780534144
-56487472
21890
```

¡Caramba! ¿Qué es esto? Bueno, resulta que imprimir el final de un array resulta en
lo que los desarrolladores de C llaman _comportamiento indefinido_. Hablaremos más
sobre esta bestia más adelante, pero por ahora significa: "Has hecho algo malo, y
cualquier cosa podría pasar durante la ejecución de tu programa".

Y por cualquier cosa, me refiero típicamente a cosas como encontrar ceros, encontrar
números basura, o bloquearse. Pero en realidad la especificación de C dice que en
estas circunstancias el compilador puede emitir código que haga _cualquier cosa_^[En
los viejos tiempos de MS-DOS, antes de que existiera la protección de memoria, yo escribía
un código C particularmente abusivo que deliberadamente tenía todo tipo de comportamientos
indefinidos. Pero sabía lo que hacía, y las cosas funcionaban bastante bien. Hasta que
cometí un error que causó un bloqueo y, como descubrí al reiniciar, borró todas
mis configuraciones de BIOS. Fue divertido. (Un saludo a @man por esos momentos de diversión)].

Versión corta: no hagas nada que cause un comportamiento indefinido. Nunca
^[Hay un montón de cosas que causan un comportamiento indefinido, no sólo los
accesos a arrays fuera de los límites. Esto es lo que hace al lenguaje C tan _excitante_].
[i[Arrays-->out of bounds]>]

## Matrices multidimensionales

[i[Arrays-->multidimensional]<]
Puede añadir tantas dimensiones como desee a sus matrices.

``` {.c}
int a[10];
int b[2][7];
int c[4][5][6];
```

Se almacenan en memoria en [flw[row-major
order|Row-_and_column-major_order]].Esto significa que en una matriz 2D, el primer índice de la lista indica la _fila_ y el segundo la _columna_.
También puedes utilizar inicializadores en matrices multidimensionales anidándolos:


```{.c .numberLines}
#include <stdio.h>

int main(void)
{
    int row, col;

    int a[2][5] = {      // Inicializar una matriz 2D
        {0, 1, 2, 3, 4},
        {5, 6, 7, 8, 9}
    };

    for (row = 0; row < 2; row++) {
        for (col = 0; col < 5; col++) {
            printf("(%d,%d) = %d\n", row, col, a[row][col]);
        }
    }
}
```

Para la salida de:

``` {.default}
(0,0) = 0
(0,1) = 1
(0,2) = 2
(0,3) = 3
(0,4) = 4
(1,0) = 5
(1,1) = 6
(1,2) = 7
(1,3) = 8
(1,4) = 9
```

Y se puede inicializar con índices explícitos:

``` {.c}
// Hacer una matriz de identidad 3x3
int a[3][3] = {[0][0]=1, [1][1]=1, [2][2]=1};
```

que construye un array 2D como este:

``` {.default}
1 0 0
0 1 0
0 0 1
```
[i[Arrays-->multidimensional]>]

## Matrices y punteros

[i[Arrays-->as pointers]<]
Así que... "_Casualmente_" ¿podría haber mencionado que los arrays
eran punteros, en el fondo? Deberíamos hacer una inmersión superficial en eso
ahora para que las cosas no sean completamente confusas. Más adelante veremos cuál
es la relación real entre arrays y punteros, pero por ahora sólo quiero
pasar arrays a funciones.

### Obtener un puntero a una matriz

Quiero contarte un secreto. En general, cuando un programador de C habla de un
puntero a un array, está hablando de un puntero _al primer elemento_ del array
^[Esto es técnicamente incorrecto, ya que un puntero a un array y un puntero al primer
elemento de un array tienen tipos diferentes. Pero podemos quemar ese puente
cuando lleguemos a él].

Obtengamos un puntero al primer elemento de un array.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int a[5] = {11, 22, 33, 44, 55};
    int *p;

    p = &a[0];  // p apunta a la matriz
                // Bueno, al primer elemento, en realidad

    printf("%d\n", *p);  // Imprime "11"
}
```

Esto es tan común de hacer en C que el lenguaje nos permite una forma abreviada:

``` {.c .numberLines}
p = &a[0];  // p apunta a la matriz

// Es lo mismo que:

p = a;      // p apunta a la matriz, ¡pero es mucho más bonito!
```

Hacer referencia al nombre del array de forma aislada es lo mismo que
obtener un puntero al primer elemento del array. Vamos a utilizar esto
ampliamente en los próximos ejemplos.

Pero espera un segundo... ¿no es `p` un `int*`? ¿Y `*p` nos da `11`, lo mismo
que `a[0]`? Sí. Estás empezando a ver cómo se relacionan las matrices y los punteros en C.
[i[Arrays-->as pointers]>]

### Paso de matrices unidimensionales a funciones {#passing1darrays}

[i[Arrays-->passing to functions]<]
Hagamos un ejemplo con un array unidimensional. Voy a escribir un par
de funciones a las que podemos pasar el array para que hagan cosas diferentes.

¡Prepárate para algunas firmas de funciones alucinantes!

``` {.c .numberLines}
#include <stdio.h>

// Pasar como puntero al primer elemento
void times2(int *a, int len)
{
    for (int i = 0; i < len; i++)
        printf("%d\n", a[i] * 2);
}

// Lo mismo, pero utilizando la notación de matriz
void times3(int a[], int len)
{
    for (int i = 0; i < len; i++)
        printf("%d\n", a[i] * 3);
}

// Lo mismo, pero utilizando la notación de matriz con tamaño
void times4(int a[5], int len)
{
    for (int i = 0; i < len; i++)
        printf("%d\n", a[i] * 4);
}

int main(void)
{
    int x[5] = {11, 22, 33, 44, 55};

    times2(x, 5);
    times3(x, 5);
    times4(x, 5);
}
```

Todos esos métodos de enumerar el array como parámetro en la función son idénticos.

``` {.c}
void times2(int *a, int len)
void times3(int a[], int len)
void times4(int a[5], int len)
```

En el uso por parte de los habituales de C, la primera es la más común, con diferencia.

Y, de hecho, en la última situación, el compilador ni siquiera le importa qué número
le pasas (aparte de que tiene que ser mayor que cero^[C11 §6.7.6.2¶1 requiere que sea
mayor que cero. Pero puede que veas código por ahí con arrays declarados de longitud cero
al final de `struct`s y GCC es particularmente indulgente al respecto a menos que compiles
con `-pedantic`. Este array de longitud cero era un mecanismo para hacer estructuras de
longitud variable. Desafortunadamente, es técnicamente un comportamiento indefinido acceder
a un array de este tipo aunque básicamente funcionaba en todas partes. C99 codificó un
reemplazo bien definido llamado _flexible array members_, del que hablaremos más adelante]). No impone nada en absoluto.

Ahora que lo he dicho, el tamaño del array en la declaración de la función realmente
_importa_ cuando pasas arrays multidimensionales a funciones, pero volveremos a eso.
[i[Arrays-->passing to functions]>]

### Modificación de matrices en funciones

[i[Arrays-->modifying within functions]<]
Ya hemos dicho que las matrices son punteros disfrazados. Esto significa
que si pasas un array a una función, probablemente estés pasando un puntero
al primer elemento del array.

Pero si la función tiene un puntero a los datos, ¡puede manipular esos datos! Así que
los cambios que una función hace a un array serán visibles de nuevo en el invocador.

He aquí un ejemplo en el que pasamos un puntero a un array a una función, la función
manipula los valores de ese array, y esos cambios son visibles en la llamada.

``` {.c .numberLines}
#include <stdio.h>

void double_array(int *a, int len)
{
    // Multiplica cada elemento por 2
    //
    // Esto duplica los valores en 'x' en main() ya que 'x' y 'a' apuntan
    // ¡Al mismo array en memoria!

    for (int i = 0; i < len; i++)
        a[i] *= 2;
}

int main(void)
{
    int x[5] = {1, 2, 3, 4, 5};

    double_array(x, 5);

    for (int i = 0; i < 5; i++)
        printf("%d\n", x[i]);  // 2, 4, 6, 8, 10!
}
```

Aunque pasamos el array como parámetro `a` que es de tipo `int*`, ¡mira cómo accedemos
a él usando la notación array con `a[i]`! Vaya. Esto está totalmente permitido.

Más adelante, cuando hablemos de la equivalencia entre arrays y punteros, veremos
que esto tiene mucho más sentido. Por ahora, es suficiente saber que las funciones
pueden hacer cambios a los arrays que son visibles en el llamador.
[i[Arrays-->modifying within functions]>]

### Paso de matrices multidimensionales a funciones

[i[Arrays-->passing to functions]<]
La historia cambia un poco cuando hablamos de matrices multidimensionales. C necesita
conocer todas las dimensiones (excepto la primera) para saber en qué parte de la memoria
debe buscar un valor.

He aquí un ejemplo en el que somos explícitos con todas las dimensiones:

``` {.c .numberLines}
#include <stdio.h>

void print_2D_array(int a[2][3])
{
    for (int row = 0; row < 2; row++) {
        for (int col = 0; col < 3; col++)
            printf("%d ", a[row][col]);
        printf("\n");
    }
}

int main(void)
{
    int x[2][3] = {
        {1, 2, 3},
        {4, 5, 6}
    };

    print_2D_array(x);
}
```

Pero en este caso, estos dos^[Esto también es equivalente: `void print_2D_array(int (*a)[3])`,
pero eso es más de lo que quiero entrar ahora] son equivalentes:

``` {.c}
void print_2D_array(int a[2][3])
void print_2D_array(int a[][3])
```

En realidad, el compilador sólo necesita la segunda dimensión para poder calcular
la distancia de memoria que debe saltarse en cada incremento de la primera dimensión.
En general, necesita conocer todas las dimensiones excepto la primera.

Además, recuerda que el compilador hace una comprobación mínima de los límites en tiempo
de compilación (si tienes suerte), y C no hace ninguna comprobación de los límites en
tiempo de ejecución.¡Sin cinturones de seguridad! No te estrelles accediendo a elementos
del array fuera de los límites.
[i[Arrays-->passing to functions]>] [i[Arrays]>]
