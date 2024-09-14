<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Strings ("Cadenas" de caracteres)

[i[Strings]<]¡Por fin! ¡Cadenas! ¿Qué podría ser más sencillo?

Bueno, resulta que las cadenas en realidad no son cadenas en C. ¡Así es! ¡Son punteros!
Por supuesto que lo son.

Al igual que las matrices, las cadenas en C _apenas existen_.

Pero vamos a comprobarlo... en realidad no es para tanto.

## Literales de cadena

[i[String literals]<]Antes de empezar, hablemos de los literales de cadena en C.
Son secuencias de caracteres entre comillas _dobles_ (`"`).
(Las comillas simples encierran caracteres, y son un animal completamente diferente).

Por ejemplo:

``` {.c}
"Hello, world!\n"
"This is a test."
"When asked if this string had quotes in it, she replied, \"It does.\""
```

El primero tiene una nueva línea al final, algo bastante común.

La última tiene comillas incrustadas, pero cada una está precedida por
(decimos «escapada por») una barra invertida (`\`) indicando que una comilla literal
pertenece a la cadena en este punto. Así es como el compilador de C, puede diferenciar
entre, imprimir una comilla doble y la comilla doble al final de la cadena.[i[String literals]>]

## Variables de cadena


[i[String variables]<]Ahora que sabemos cómo hacer un literal de cadena, asignémoslo
a una variable para poder hacer algo con él.


``` {.c}
char *s = "Hello, world!";
```

Fíjate en el tipo: puntero a un `char`. La variable de cadena `s` es en realidad un
puntero al primer carácter de esa cadena, concretamente la `H`.

Y podemos imprimirlo con el especificador de formato `%s` (de **S**tring «cadena»):

``` {.c}
char *s = "Hello, world!"; // "Hola, mundo!"

printf("%s\n", s);  // Hello, world!
```
[i[String variables]>]

## Variables de cadena como matrices

[i[String variables-->as arrays]<]
Otra opción es ésta, casi equivalente al uso anterior de `char*`:

``` {.c}
char s[14] = "Hello, world!";

// o, si fuéramos perezosos y dejáramos que el compilador
// calculara la longitud por nosotros:

char s[] = "Hello, world!";
```

Esto significa que puedes utilizar la notación de matrices para acceder a los caracteres
de una cadena.Hagamos exactamente eso para imprimir todos los caracteres de una cadena
en la misma línea:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    char s[] = "Hello, world!";

    for (int i = 0; i < 13; i++)
        printf("%c\n", s[i]);
}
```

Tenga en cuenta que estamos utilizando el especificador de formato `%c` para
imprimir un solo carácter.

Además, fíjate en esto. El programa seguirá funcionando bien si cambiamos la
definición de `s` para que sea de tipo `char*`:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    char *s = "Hello, world!";   // char* aqui

    for (int i = 0; i < 13; i++)
        printf("%c\n", s[i]);    // ¿Pero seguir usando arrays aquí...?
}
```

Y aún podemos utilizar la notación de matrices para imprimirlo. Esto es sorprendente,
pero sólo porque aún no hemos hablado de la equivalencia matriz/puntero. Pero esto
es otra pista de que los arrays y los punteros son la misma cosa, en el fondo.
[i[String variables-->as arrays]>]

## Inicializadores de cadenas

[i[Strings-->initializers]<]
Ya hemos visto algunos ejemplos con la inicialización de variables de cadena
con literales de cadena:

``` {.c}
char *s = "Hello, world!";
char t[] = "Hello, again!";
```

Pero estas dos inicializaciones son sutilmente diferentes. Un literal de cadena, similar a un literal de número entero, tiene su memoria gestionada automáticamente por el compilador. Con un entero, es decir, un dato de tamaño fijo, el compilador puede gestionarlo con bastante facilidad. Pero las cadenas son una bestia de bytes variables que el compilador domestica lanzándolas a un trozo de memoria, y dándote un puntero a él.

Esta forma apunta al lugar donde se colocó esa cadena. Típicamente, ese lugar está en una tierra lejana del resto de la memoria de tu programa -- memoria de sólo lectura -- por razones relacionadas con el rendimiento y la seguridad.

``` {.c}
char *s = "Hello, world!";
```

Entonces, si intentas mutar esa cadena con esto:

``` {.c}
char *s = "Hello, world!";

s[0] = 'z';  // MALAS NOTICIAS: ¡intentó mutar una cadena literal!
```

El comportamiento es indefinido. Probablemente, dependiendo de su sistema, se producirá
un fallo.

Pero declararlo como un array es diferente. El compilador no guarda esos bytes en otra parte de la ciudad, están al final de la calle. Esta es una _copia_ mutable de la cadena -- una que podemos cambiar a voluntad:

``` {.c}
char t[] = "Hello, again!";  // t es una copia de la cadena 
t[0] = 'z'; //  No hay problema

printf("%s\n", t);  // "zello, again!"
```

Así que recuerda: si tienes un puntero a un literal de cadena, ¡no intentes cambiarlo!
Y si usas una cadena entre comillas dobles para inicializar un array, no es realmente
un literal de cadena. [i[Strings-->initializers]>]

## Obtención de la longitud de la cadena

[i[Strings-->getting the length]<]
No puedes, ya que C no lo rastrea por ti. Y cuando digo «no puede», en realidad quiero
decir «puede»^[Aunque es cierto que C no rastrea la longitud de las cadenas]. Hay una función
en `<string.h>` llamada `strlen()` que puede usarse para calcular la longitud de cualquier
cadena en bytes^[Si estás usando el juego de caracteres básico o un juego de caracteres
de 8 bits, estás acostumbrado a que un carácter sea un byte. Sin embargo, esto no es cierto
en todas las codificaciones de caracteres].

``` {.c .numberLines}
#include <stdio.h>
#include <string.h>

int main(void)
{
    char *s = "Hello, world!";

    printf("La cadena tiene %zu bytes de longitud.\n", strlen(s));
}
```

La función `strlen()` devuelve el tipo `size_t`, que es un tipo entero por lo que
se puede utilizar para matemáticas de enteros. Imprimimos `size_t` con `%zu`.

El programa anterior imprime:

``` {.default}
La cadena tiene 13 bytes de longitud.
```

Estupendo. ¡Así que _es_ posible obtener la longitud de la cadena!
[i[Strings-->getting the length]>]

Pero... si C no rastrea la longitud de la cadena en ninguna parte, ¿cómo sabe cuán
larga es la cadena?

## Terminación de la cadena

[i[Strings-->termination]<]
C hace las cadenas de forma un poco diferente a muchos lenguajes de programación,
y de hecho de forma diferente a casi todos los lenguajes de programación modernos.

Cuando estás haciendo un nuevo lenguaje, tienes básicamente dos opciones para
almacenar una cadena en memoria:

 1. Almacenar los bytes de la cadena junto con un número que indica la longitud de la cadena.

 2. Almacenar los bytes de la cadena, y marcar el final de la cadena con un byte
especial llamado _terminador_.

Si desea cadenas de más de 255 caracteres, la opción 1 requiere al menos dos bytes
para almacenar la longitud. Mientras que la opción 2 sólo requiere un byte para
terminar la cadena. Así que se ahorra un poco.

Por supuesto, hoy en día parece ridículo preocuparse por ahorrar
un byte (o 3: muchos lenguajes te permiten tener cadenas de 4 gigabytes de longitud).
Pero en su día, era un problema mayor.

Así que C adoptó el enfoque nº 2. En C, una «cadena» se define por dos
características básicas:

* Un puntero al primer carácter de la cadena.
* Un byte de valor cero (o carácter `NUL`^[Esto es diferente del puntero `NULL`, y lo
abreviaré `NUL` cuando hable del carácter frente a `NULL` para el puntero]) en algún
lugar de la memoria después del puntero que indica el final de la cadena.

Un carácter `NUL` puede escribirse en código C como `\0`, aunque no es necesario
hacerlo a menudo.

Cuando incluyes una cadena entre comillas dobles en tu código, el carácter `NUL` se
incluye automática e implícitamente.

``` {.c}
char *s = "Hello!";  // En realidad «Hola!\0» entre bastidores
```

Así que con esto en mente, vamos a escribir nuestra propia función `strlen()`
que cuenta `caracteres` en una cadena hasta que encuentra un `NUL`.

El procedimiento es buscar en la cadena un único carácter `NUL`, contando
a medida que avanzamos^[Más adelante aprenderemos una forma más ordenada de
hacerlo con aritmética de punteros]:

``` {.c}
int my_strlen(char *s)
{
    int count = 0;

    while (s[count] != '\0')  // Comillas simples para caracteres simples
        count++;

    return count;
}
```

Y así es como la función `strlen()` hace su trabajo.
[i[Strings-->termination]>]

## Copiar una cadena

[i[Strings-->copying]<]
No se puede copiar una cadena mediante el operador de asignación (`=`). Todo lo
que hace es hacer una copia del puntero al primer carácter... por lo que terminas
con dos punteros a la misma cadena:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    char s[] = "Hello, world!";
    char *t;

    // Esto hace una copia del puntero, ¡no una copia de la cadena!
    t = s;

    // Modificamos t
    t[0] = 'z';

    // ¡Pero imprimir s muestra la modificación!
    // ¡Porque t y s apuntan a la misma cadena!

    printf("%s\n", s);  // "zello, world!"
}
```

Si quieres hacer una copia de una cadena, tienes que copiarla byte a byte---pero esto
es más fácil con la función `strcpy()`^[Hay una función más segura llamada `strncpy()`
que probablemente deberías usar en su lugar, pero llegaremos a eso más tarde].

Antes de copiar la cadena, asegúrate de que tienes espacio para copiarla, es decir,
la matriz de destino que va a contener los caracteres debe ser al menos tan larga
como la cadena que estás copiando.

``` {.c .numberLines}
#include <stdio.h>
#include <string.h>

int main(void)
{
    char s[] = "Hello, world!";
    char t[100];  // Cada char es un byte, así que hay espacio de sobra

    // ¡Esto hace una copia de la cadena!
    strcpy(t, s);

    // Modificamos t
    t[0] = 'z';

    // Y s no se ve afectada porque es una cadena diferente
    printf("%s\n", s);  // "Hello, world!"

    // Pero t ha cambiado
    printf("%s\n", t);  // "zello, world!"
}
```

Observe que con `strcpy()`, el puntero de destino es el primer argumento, y el puntero
de origen es el segundo. Una mnemotécnica que uso para recordar esto es que es el orden
en el que habrías puesto `t` y `s` si una asignación `=` funcionara para cadenas,
con el origen a la derecha y el destino a la izquierda.
[i[Strings-->copying]>][i[Strings]>]
