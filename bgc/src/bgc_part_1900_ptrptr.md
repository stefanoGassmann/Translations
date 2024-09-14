<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Punteros III: Punteros a punteros y más

Aquí es donde cubrimos algunos usos intermedios y avanzados de los punteros. Si no conoces bien
los punteros, repasa los capítulos anteriores sobre [punteros](#pointers) y [aritmética de
punteros](#pointers2) antes de empezar con esto.

## Punteros a punteros

[i[Pointers-->to pointers]<]

Si puedes tener un puntero a una variable, y una variable puede ser un puntero, ¿puedes tener
un puntero a una variable que a su vez sea un puntero?

Sí. Esto es un puntero a un puntero, y se mantiene en una variable de tipo puntero-puntero. 

Antes de entrar en materia, quiero que te hagas una idea de cómo funcionan los punteros a punteros.

Recuerda que un puntero es sólo un número. Es un número que representa un índice en la memoria
del ordenador, que normalmente contiene un valor que nos interesa.

Ese puntero, que es un número, tiene que ser almacenado en algún lugar. Y ese lugar es la memoria,
como todo lo demás^[Hay un poco de diablo en los detalles con los valores que se almacenan
sólo en los registros, pero podemos ignorar con seguridad que para nuestros propósitos aquí.
Además, la especificación C no se pronuncia sobre estos "registros" más allá de la palabra clave
`register`, cuya descripción no menciona los registros].

Pero como está almacenado en memoria, debe tener un índice en el que está almacenado, ¿no?
El puntero debe tener un índice en la memoria donde se almacena. Y ese índice es un número.
Es la dirección del puntero. Es un puntero al puntero.

Empecemos con un puntero regular a un `int`, de los capítulos anteriores:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int x = 3490; // Tipo: int
    int *p = &x; // Tipo: puntero a un int

    printf("%d\n", *p);  // 3490
}
```

Bastante sencillo, ¿verdad? Tenemos dos tipos representados: `int` e `int*`, y configuramos
`p` para que apunte a `x`. Entonces podemos desreferenciar `p` en la línea 8 e imprimir
el valor `3490`.

Pero, como hemos dicho, podemos tener un puntero a cualquier variable... ¿eso significa
que podemos tener un puntero a `p`?

En otras palabras, ¿de qué tipo es esta expresión?


``` {.c}
int x = 3490; // Tipo: int
int *p = &x; // Tipo: puntero a un int

&p // <-- ¿De qué tipo es la dirección de p? ¿Un puntero a p?
```

Si `x` es un `int`, entonces `&x` es un puntero a un `int` que hemos almacenado en `p` que es
de tipo `int*`. ¿Entiendes? (¡Repite este párrafo hasta que lo hagas!)

Y por tanto `&p` es un puntero a un `int*`, alias "puntero a un puntero a un `int`". También
conocido como "`int`-pointer-pointer".

¿Lo ha entendido? (¡Repite el párrafo anterior hasta que lo entiendas!)

Escribimos este tipo con dos asteriscos: `int **`. Veámoslo en acción.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int x = 3490; // Tipo: int
    int *p = &x; // Tipo: puntero a un int
    int **q = &p; // Tipo: puntero a puntero a int

    printf("%d %d\n", *p, **q);  // 3490 3490
}
```

Vamos a inventar algunas direcciones ficticias para los valores anteriores como ejemplos y ver
lo que estas tres variables podrían parecer en la memoria. Los valores de dirección, a
continuación son sólo inventados por mí para fines de ejemplo:

|Variable|Almacenada en la dirección|Valor almacenado allí|
|-|-|-|
|`x`|`28350`|`3490`---el valor del código|
|`p`|`29122`|`28350`---¡la dirección de `x`!|
|`q`|`30840`|`29122`---¡la dirección de `p`!|

De hecho, vamos a probarlo de verdad en mi ordenador^[Es muy probable que obtengas números
diferentes en el tuyo] e imprimir los valores de los punteros con `%p` y volveré a hacer
la misma tabla con las referencias reales (impresas en hexadecimal).

|Variable|Almacenada en la dirección|Valor almacenado allí|
|-|-|-|
|`x`|`0x7ffd96a07b94`|`3490`---el valor del código|
|`p`|`0x7ffd96a07b98`|`0x7ffd96a07b94`---la dirección de `x`!|
|`q`|`0x7ffd96a07ba0`|`0x7ffd96a07b98`---la dirección de `p`!|

Puedes ver que esas direcciones son las mismas excepto el último byte, así que céntrate en ellas.

En mi sistema, los `int`s son de 4 bytes, por lo que vemos que la dirección aumenta en 4
de `x` a `p`^[No hay absolutamente nada en la especificación que diga que esto funcionará siempre
así, pero resulta que funciona así en mi sistema] y luego aumenta en 8 de `p` a `q`. En mi
sistema, todos los punteros son de 8 bytes.

¿Importa si es un `int*` o un `int**`? ¿Es uno más bytes que el otro? No. Recuerda que todos
los punteros son direcciones, es decir, índices de memoria. Y en mi máquina puedes representar
un índice con 8 bytes... no importa lo que esté almacenado en ese índice.

Fíjate en lo que hicimos en la línea 9 del ejemplo anterior: hicimos _doble dereferencia_ `q` para
volver a nuestro `3490`.

Esta es la parte importante sobre punteros y punteros a punteros:

* Puedes obtener un puntero a cualquier cosa con `&` (¡incluyendo a un puntero!)
* Puedes obtener la cosa a la que apunta un puntero con `*` (¡incluyendo un
  puntero!)

Así que puedes pensar que `&` se usa para hacer punteros, y que `*` es la inversa--va en la
dirección opuesta a `&`--para llegar a la cosa apuntada.

En términos de tipo, cada vez que `&`, se añade otro nivel de puntero al tipo.

|Si tiene|Entonces ejecuta|El tipo de resultado es|
|:-|:-:|:-|
|`int x`|`&x`|`int *`|
|`int *x`|`&x`|`int **`|
|`int **x`|`&x`|`int ***`|
|`int ***x`|`&x`|`int ****`|

Y cada vez que se utiliza la desreferencia (`*`), hace lo contrario:

|Si tiene|Entonces ejecuta|El tipo de resultado es|
|:-|:-:|:-|
|`int ****x`|`*x`|`int ***`|
|`int ***x`|`*x`|`int **`|
|`int **x`|`*x`|`int *`|
|`int *x`|`*x`|`int`|

Tenga en cuenta que puede utilizar varias `*`s seguidas para realizar una desreferencia rápida,
como vimos en el código de ejemplo con `**q`, más arriba. Cada uno elimina un nivel de indirección.

|Si tiene|Entonces ejecuta|El tipo de resultado es|
|:-|:-:|:-|
|`int ****x`|`***x`|`int *`|
|`int ***x`|`**x`|`int *`|
|`int **x`|`**x`|`int`|

En general, `&*E == E`^[Incluso si `E` es `NULL`, resulta, extrañamente]. La desreferencia
"deshace" la dirección-de.

Pero `&` no funciona de la misma manera---sólo puedes hacerlos de uno en uno, y tienes que
almacenar el resultado en una variable intermedia:

``` {.c}
int x = 3490; // Tipo: int
int *p = &x; // Tipo: int *, puntero a un int
int **q = &p; // Tipo: int **, puntero a puntero a int
int ***r = &q; // Tipo: int ***, puntero a puntero a puntero a int
int ****s = &r; // Tipo: int ****, se entiende la idea
int *****t = &s; // Tipo: int *****
```

[i[Pointers-->to pointers]>]

### Puntero Punteros y `const`.

[i[Pointers-->to pointers, `const`]<]

Si recuerdas, declarando un puntero como este:

``` {.c}
int *const p;
```

significa que no puedes modificar `p`. Intentar `p++` daría un error de compilación.

¿Pero cómo funciona eso con `int **` o `int ***`? ¿Dónde va `const` y qué significa?

Empecemos por lo más sencillo. El símbolo `const` que aparece junto al nombre de la variable
se refiere a esa variable. Así que si quieres un `int***` que no puedas cambiar, puedes hacer esto:

``` {.c}
int ***const p;

p++;  // No autorizado
```

Pero aquí es donde las cosas se ponen un poco raras.

¿Y si tuviéramos esta situación:

``` {.c .numberLines}
int main(void)
{
    int x = 3490;
    int *const p = &x;
    int **q = &p;
}
```

Cuando construyo eso, recibo una advertencia:

``` {.default}
warning: initialization discards ‘const’ qualifier from pointer target type
    7 |     int **q = &p;
      |               ^
```

¿Qué es lo que ocurre? El compilador nos está diciendo aquí que teníamos una variable que
era `const`, y estamos asignando su valor a otra variable que no es `const`.
La "constancia" se descarta, que probablemente no es lo que queríamos hacer.

El tipo de `p` es `int *const p`, y `&p` es del tipo `int *const *`. E intentamos asignarlo a `q`.

¡Pero `q` es `int **`! ¡Un tipo con diferente `const`ness en el primer `*`! Así que recibimos
un aviso de que el `const` en `int *const *` de `p` está siendo ignorado y desechado.

Podemos arreglarlo asegurándonos de que el tipo de `q` es al menos tan `const` como `p`.

``` {.c}
int x = 3490;
int *const p = &x;
int *const *q = &p;
```

Y ahora estamos contentos.

Podríamos hacer `q` aún más `constante`. Tal como está, arriba, estamos diciendo, "`q` no es en
sí `const`, pero la cosa a la que apunta es `const`". Pero podríamos hacer que ambos sean `const`:

``` {.c}
int x = 3490;
int *const p = &x;
int *const *const q = &p;  // ¡Más const!
```

Y eso también funciona. Ahora no podemos modificar `q`, o el puntero `q` apunta a.

[i[Pointers-->to pointers, `const`]>]

## Valores multibyte {#multibyte-values}

[i[Pointers-->to multibyte values]<]

Ya lo hemos insinuado en varias ocasiones, pero está claro que no todos los valores pueden
almacenarse en un solo byte de memoria. Las cosas ocupan varios bytes de memoria (suponiendo que
no sean `char`s). Puedes saber cuántos bytes usando `sizeof`. Y puedes saber qué dirección
de memoria es el _primer_ byte del objeto usando el operador estándar `&`, que siempre devuelve
la dirección del primer byte.

Y aquí tienes otro dato curioso. Si iteras sobre los bytes de cualquier objeto, obtienes su
_representación de objeto_. Dos cosas con la misma representación de objeto en memoria son iguales.

Si quieres iterar sobre la representación del objeto, debes hacerlo con punteros a `unsigned char`.

Hagamos nuestra propia versión de [fl[`memcpy()`|https://beej.us guide/bgclr/html/split/stringref.html#man-memcpy]] que hace exactamente esto:

``` {.c}
void *my_memcpy(void *dest, const void *src, size_t n)
{
    // Crear variables locales para src y dest, pero de tipo unsigned char

    const unsigned char *s = src;
    unsigned char *d = dest;

    while (n-- > 0) // Para el número de bytes dado
        *d++ = *s++; // Copia el byte origen al byte dest

    // La mayoría de las funciones de copia devuelven un puntero
    // al dest como conveniencia al que llama

    return dest;
}
```

(También hay algunos buenos ejemplos de post-incremento y post-decremento para que los estudies).

Es importante tener en cuenta que la versión anterior es probablemente menos eficiente que la
que viene con su sistema.

Pero puedes pasarle punteros a cualquier cosa, y copiará esos objetos. Puede ser `int*`,
`struct animal*`, o cualquier cosa.

Hagamos otro ejemplo que imprima los bytes de representación del objeto de una `struct` para
que podamos ver si hay algún relleno ahí y qué valores tiene^[Tu compilador de C no está obligado
a añadir bytes de relleno, y los valores de cualquier byte de relleno que se añada son 
indeterminados].

``` {.c .numberLines}
#include <stdio.h>

struct foo {
    char a;
    int b;
};

int main(void)
{
    struct foo x = {0x12, 0x12345678};
    unsigned char *p = (unsigned char *)&x;

    for (size_t i = 0; i < sizeof x; i++) {
        printf("%02X\n", p[i]);
    }
}
```

Lo que tenemos ahí es una `estructura foo` que está construida de tal manera que debería animar
al compilador a inyectar bytes de relleno (aunque no tiene por qué). Y entonces obtenemos
un `unsigned char *` en el primer byte de la variable `x` de la `struct foo`.

A partir de ahí, todo lo que necesitamos saber es el `sizeof x` y podemos hacer un bucle a través
de esa cantidad de bytes, imprimiendo los valores (en hexadecimal para mayor facilidad).

Ejecutar esto da un montón de números como salida. He anotado a continuación para identificar
donde se almacenan los valores:

``` {.default}
12  | x.a == 0x12

AB  |
BF  | padding bytes with "random" value
26  |

78  |
56  | x.b == 0x12345678
34  |
12  |
```

En todos los sistemas, `sizeof(char)` es 1, y vemos que el primer byte en la parte superior
de la salida contiene el valor `0x12` que almacenamos allí.

Luego tenemos algunos bytes de relleno--para mí, estos variaron de una ejecución a otra.

Finalmente, en mi sistema, `sizeof(int)` es 4, y podemos ver esos 4 bytes al final. Observa
que son los mismos bytes que hay en el valor hexadecimal `0x12345678`, pero extrañamente en orden
inverso^[Esto variará dependiendo de la arquitectura, pero mi sistema es _little endian_, lo que
significa que el byte menos significativo del número se almacena primero. Los sistemas _Big endian_
tendrán el `12` primero y el `78` al final. Pero la especificación no dicta nada sobre esta
representación].

Esto es un pequeño vistazo a los bytes de una entidad más compleja en memoria.

[i[Pointers-->to multibyte values]>]

## El puntero `NULL` y el cero

[i[`NULL` pointer-->zero equivalence]<]

Estas cosas pueden usarse indistintamente:

* `NULL`
* `0`
* `'\0'`
* `(void *)0`

Personalmente, siempre utilizo `NULL` cuando me refiero a `NULL`, pero puede que veas otras
variantes de vez en cuando. Aunque `'\0'` (un byte con todos los bits a cero) también se compara
igual, es _raro_ compararlo con un puntero; deberías comparar `NULL` contra el puntero. (Por
supuesto, muchas veces en el procesamiento de cadenas, estás comparando _la cosa a la que apunta
el puntero_ con `'\0`, y eso es correcto).

A `0` se le llama la _constante de puntero nulo_, y, cuando se compara o se asigna a otro puntero,
se convierte en un puntero nulo del mismo tipo.
[i[`NULL` pointer-->zero equivalence]>]

## Punteros como enteros

[i[Pointers-->as integers]<]

Los punteros se pueden convertir en enteros y viceversa (ya que un puntero no es más que un índice
de memoria), pero probablemente sólo sea necesario hacerlo si se realizan operaciones de hardware
de bajo nivel. Los resultados de tales maquinaciones están definidos por la implementación, por lo
que no son portables. Y pueden ocurrir _cosas raras_.

Sin embargo, C ofrece una garantía: puedes convertir un puntero a un tipo `uintptr_t` y podrás
volver a convertirlo en puntero sin perder ningún dato.

`uintptr_t` está definido en `<stdint.h>`^[Es una característica opcional, así que podría no estar
ahí---pero probablemente sí].

Además, si te apetece que te firmen, puedes usar `intptr_t` con el mismo efecto.

[i[Pointers-->as integers]>]

## Asignación de punteros a otros punteros

[i[Pointers-->casting]<]

Sólo hay una conversión de puntero segura:

1. Convertir a `intptr_t` o `uintptr_t`.
2. Convertir a y desde `void*`.

¡DOS! Dos conversiones de punteros seguras.

3. Conversión a y desde `char*` (o `signed char*`/`unsigned char*`).

¡TRES! ¡Tres conversiones seguras!

4. Convertir de y a un puntero a una `struct` y a un puntero a su primer miembro, y viceversa.

¡CUATRO! ¡Cuatro conversiones seguras!

Si convierte a un puntero de otro tipo y luego accede al objeto al que apunta, el comportamiento
es indefinido debido a algo llamado _aliasing_ estricto.

El viejo _aliasing_ se refiere a la capacidad de tener más de una forma de acceder al mismo
objeto. Los puntos de acceso son alias entre sí.

El _aliasing estricto_ dice que sólo se permite acceder a un objeto a través de punteros
a _tipos compatibles_ con ese objeto.

Por ejemplo, esto está definitivamente permitido:

``` {.c}
int a = 1;
int *p = &a;
```

`p` es un puntero a un `int`, y apunta a un tipo compatible--a saber `int`--así que estamos bien.

Pero lo siguiente no es bueno porque `int` y `float` no son tipos compatibles:

``` {.c}
int a = 1;
float *p = (float *)&a;
```

Aquí hay un programa de demostración que hace algo de aliasing. Toma una variable `v` de tipo
`int32_t` y la aliasea a un puntero a una `struct words`. Esa `struct` tiene dos `int16_t`s
dentro. Estos tipos son incompatibles, por lo que estamos violando las reglas estrictas de
aliasing. El compilador asumirá que estos dos punteros nunca apuntan al mismo objeto... pero
nosotros estamos haciendo que lo hagan. Lo cual es malo por nuestra parte.

Veamos si podemos romper algo.

``` {.c .numberLines}
#include <stdio.h>
#include <stdint.h>

struct words {
    int16_t v[2];
};

void fun(int32_t *pv, struct words *pw)
{
    for (int i = 0; i < 5; i++) {
        (*pv)++;

        // Imprime el valor de 32 bits y los valores de 16 bits:

        printf("%x, %x-%x\n", *pv, pw->v[1], pw->v[0]);
    }
}

int main(void)
{
    int32_t v = 0x12345678;

    struct words *pw = (struct words *)&v;  // Viola el aliasing estricto

    fun(&v, pw);
}
```

¿Ves cómo paso los dos punteros incompatibles a `fun()`? Uno de los tipos es `int32_t*` y el otro es `struct words*`.

Pero ambos apuntan al mismo objeto: el valor de 32 bits inicializado a `0x12345678`.

Así que si miramos los campos de `struct words`, deberíamos ver las dos mitades de 16 bits de ese número. ¿Verdad?

Y en el bucle `fun()`, incrementamos el puntero al `int32_t`. Y ya está. Pero como la `struct` apunta a esa misma memoria, también debería actualizarse al mismo valor.

Así que ejecutémoslo y obtendremos esto, con el valor de 32 bits a la izquierda y las dos
porciones de 16 bits a la derecha. Debería coincidir^[Estoy imprimiendo los valores de 16 bits
invertidos porque estoy en una máquina little-endian y así es más fácil de leer]:

``` {.default}
12345679, 1234-5679
1234567a, 1234-567a
1234567b, 1234-567b
1234567c, 1234-567c
1234567d, 1234-567d
```

y lo hace... HASTA MAÑANA

Probémoslo compilando GCC con `-O3` y `-fstrict-aliasing`:

``` {.default}
12345679, 1234-5678
1234567a, 1234-5679
1234567b, 1234-567a
1234567c, 1234-567b
1234567d, 1234-567c
```

¡Están separados por uno! ¡Pero apuntan al mismo recuerdo! ¿Cómo es posible? Respuesta: es un
comportamiento indefinido poner alias a la memoria de esa manera. Todo es posible, excepto
que no en el buen sentido.

Si tu código viola las estrictas reglas de aliasing, que funcione o no depende de cómo alguien
decida compilarlo. Y eso es un fastidio, ya que está fuera de tu control. A menos que seas una
especie de deidad omnipotente.

Poco probable, lo siento.

GCC puede ser forzado a no usar las reglas de aliasing estricto con `-fno-strict-aliasing`.
Compilar el programa de demostración, arriba, con `-O3` y esta bandera hace que la salida
sea la esperada.

Por último, _type punning_ es usar punteros de diferentes tipos para ver los mismos datos. Antes
del aliasing estricto, este tipo de cosas era bastante común:

``` {.c}
int a = 0x12345678;
short b = *((short *)&a);   // Viola el aliasing estricto
```

Si desea realizar puntuaciones (relativamente) seguras, consulte la sección sobre
[Uniones y puntuaciones](#union-type-punning).

[i[Pointers-->casting]>]

## Diferencias entre punteros {#ptr_differences}

[i[Pointers-->subtracting]<]

Como sabes de la sección sobre aritmética de punteros, puedes restar un puntero de otro
^[Suponiendo que apunten al mismo objeto array.] para obtener la diferencia entre ellos
en número de elementos del array.

Ahora el _tipo de esa diferencia_ es algo que depende de la implementación, por lo que podría
variar de un sistema a otro.

[i[`ptrdiff_t` type]<]

Para ser más portable, puedes almacenar el resultado en una variable de tipo `ptrdiff_t`
definida en `<stddef.h>`.

``` {.c}
int cats[100];

int *f = cats + 20;
int *g = cats + 60;

ptrdiff_t d = g - f;  // la diferencia es de 40
```

[i[`ptrdiff_t` type-->printing]<]
Y puede imprimirlo anteponiendo al especificador de formato entero `t`:

``` {.c}
printf("%td\n", d);  // Imprimir decimal: 40
printf("%tX\n", d);  // Imprimir hex:     28
```

[i[`ptrdiff_t` type-->printing]>]
[i[`ptrdiff_t` type]>]
[i[Pointers-->subtracting]>]

## Punteros a funciones

[i[Pointers-->to functions]<]

Las funciones son sólo colecciones de instrucciones de la máquina en la memoria, así que no hay
ninguna razón por la que no podamos obtener un puntero a la primera instrucción de la función.

Y luego llamarla.

Esto puede ser útil para pasar, un puntero a una función a otra función como argumento. Entonces
la segunda podría llamar a lo que se haya pasado.

La parte complicada de esto, sin embargo, es que C necesita saber el tipo de la variable que
es el puntero a la función.

Y realmente le gustaría conocer todos los detalles.

Como "esto es un puntero a una función que toma dos argumentos `int` y devuelve `void`".

¿Cómo se escribe todo eso para poder declarar una variable?

Bueno, resulta que se parece mucho a un prototipo de función, excepto que con algunos
paréntesis extra:

``` {.c}
// Declara que p es un puntero a una función.
// Esta función devuelve un float, y toma dos ints como argumentos.

float (*p)(int, int);
```

Fíjate también en que no tienes que dar nombres a los parámetros. Pero puedes hacerlo si quieres; simplemente se ignoran.

``` {.c}
// Declara que p es un puntero a una función.
// Esta función devuelve un float, y toma dos ints como argumentos.

float (*p)(int a, int b);
```

Ahora que sabemos cómo declarar una variable, ¿cómo sabemos qué asignarle? ¿Cómo obtenemos
la dirección de una función?

Resulta que hay un atajo, igual que para obtener un puntero a un array: puedes referirte
al nombre de la función sin paréntesis. (Puedes poner un `&` delante si quieres, pero es
innecesario y no es idiomático).

Una vez que tienes un puntero a una función, puedes llamarla simplemente añadiendo
paréntesis y una lista de argumentos.

Hagamos un ejemplo simple donde efectivamente hago un alias para una función estableciendo
un puntero a ella. Luego la llamaremos.

Este código imprime `3490`:

``` {.c .numberLines}
#include <stdio.h>

void print_int(int n)
{
    printf("%d\n", n);
}

int main(void)
{
    // Asigna p a print_int:

    void (*p)(int) = print_int;

    p(3490);          // Llamar a print_int a través del puntero
}
```

Observa cómo el tipo de `p` representa el valor de retorno y los tipos de parámetros
de `print_int`. Tiene que ser así, o C se quejará de incompatibilidad de tipos de punteros.

Otro ejemplo muestra cómo podemos pasar un puntero a una función como argumento de otra función.

Escribiremos una función que toma un par de argumentos enteros, más un puntero a una función
que opera sobre esos dos argumentos. Luego imprime el resultado.

``` {.c .numberLines}
#include <stdio.h>

int add(int a, int b)
{
    return a + b;
}

int mult(int a, int b)
{
    return a * b;
}

void print_math(int (*op)(int, int), int x, int y)
{
    int result = op(x, y);

    printf("%d\n", result);
}

int main(void)
{
    print_math(add, 5, 7);   // 12
    print_math(mult, 5, 7);  // 35
}
```

Tómate un momento para asimilarlo. La idea aquí es que vamos a pasar un puntero
a una función a `print_math()`, y va a llamar a esa función para hacer algo de matemáticas.

De esta forma podemos cambiar el comportamiento de `print_math()` pasándole otra función.
Puedes ver que lo hacemos en las líneas 22-23 cuando pasamos punteros a las funciones
`add` y `mult`, respectivamente.

Ahora, en la línea 13, creo que todos estamos de acuerdo en que la firma de la función
`print_math()` es un espectáculo para la vista. Y, si puedes creerlo, ésta es en realidad
bastante sencilla comparada con algunas cosas que puedes construir^[El Lenguaje de Programación
Go inspiró su sintaxis de declaración de tipos en lo contrario de lo que hace C.].

Pero vamos a digerirlo. Resulta que sólo hay tres parámetros, pero son un poco difíciles de ver:

``` {.c}
//                      op             x      y
//              |-----------------|  |---|  |---|
void print_math(int (*op)(int, int), int x, int y)
```

El primero, `op`, es un puntero a una función que toma dos `int` como argumentos y devuelve
un `int`. Esto coincide con las firmas de `add()` y `mult()`.

El segundo y el tercero, `x` e `y`, son parámetros `int` estándar.

Deja que tus ojos recorran la firma lenta y deliberadamente mientras identificas las partes
que funcionan. Una cosa que siempre me llama la atención es la secuencia `(*op)(`, los paréntesis
y el asterisco. Eso te delata que es un puntero a una función.

Por último, vuelve al capítulo _Pointers II_ para ver un puntero a función [ejemplo usando
la función incorporada `qsort()`](#qsort-example).

[i[Pointers-->to functions]>]
