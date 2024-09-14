<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->
# Punteros... ¡Poder con miedo! {#pointers}

> _"¿Cómo llegas al Carnegie Hall?"_ \
> _"Practica!"_
>
> ---Chiste del siglo XX de origen desconocido

[i[Pointers]<]Los punteros son una de las cosas más temidas del lenguaje C. De hecho,
son lo único que hace que este lenguaje sea todo un reto. ¿Por qué?

Porque, sinceramente, pueden provocar descargas eléctricas que salgan
por el teclado y te _suelden_ los brazos de forma permanente,
¡maldiciéndote a una vida al teclado en este idioma de los años 70!

¿De verdad? Bueno, en realidad no. Sólo estoy tratando de prepararte para el éxito.

Dependiendo del lenguaje del que provengas, puede que ya entiendas
el concepto de _referencias_, donde una variable hace referencia a un
objeto de algún tipo.

Esto es muy parecido, salvo que tenemos que ser más explícitos con C sobre
cuándo estamos hablando de la referencia o de la cosa a la que se refiere.

## Memoria y variables {#ptmem}

La memoria del ordenador contiene datos de todo tipo, ¿verdad? Contendrá `float`s,
`int`s, o lo que tengas. Para facilitar el manejo de la memoria, cada
byte de memoria se identifica con un número entero. Estos enteros aumentan
secuencialmente a medida que avanzas en la memoria^[Típicamente. Estoy seguro de que
hay excepciones en los oscuros pasillos de la historia de la informática].
Puedes pensar en ello como un montón de cajas numeradas, donde cada caja
contiene un byte^[Un byte es un número formado por no más de 8 dígitos binarios, o _bits_
para abreviar. Esto significa que en dígitos decimales como los que usaba la abuela,
puede contener un número sin signo entre 0 y 255, ambos inclusive] de datos.
O como un gran array donde cada elemento contiene un byte, si vienes de un lenguaje
con arrays. El número que representa cada casilla se llama _dirección_.

Ahora bien, no todos los tipos de datos utilizan sólo un byte. Por ejemplo, un `int` suele
tener cuatro bytes, al igual que un `float`, pero en realidad depende del sistema. Puedes
utilizar el operador `sizeof` para determinar cuántos bytes de memoria utiliza
un determinado tipo.

``` {.c}
// %zu es el especificador de formato para el tipo size_t

printf("Un int utiliza %zu bytes de memoria\n", sizeof(int));

// A mí me imprime "4", pero puede variar según el sistema.
```

> **Datos curiosos sobre la memoria**: Cuando tienes un tipo de datos (como el típico
> `int`) que utiliza más de un byte de memoria, los bytes que componen
> los datos son siempre adyacentes en memoria. A veces están en el
> orden que esperas, y a veces no^[El orden en que vienen los bytes
> se denomina _endianidad_ del número. Los sospechosos habituales son
> _big-endian_ (con el byte más significativo primero) y _little-endian_
> (con el byte más significativo al final), o, ahora poco común, _mixed-endian_
> (con los bytes más significativos en otro lugar)]. Aunque C no garantiza ningún
> orden de memoria en particular (depende de la plataforma), en general es posible
> escribir código de forma independiente de la plataforma sin tener que tener
> en cuenta estos molestos ordenamientos de bytes.

Así que, de todos modos, si podemos ponernos manos a la obra y poner un redoble de tambores
y algo de música premonitoria para la definición de puntero, _un puntero es una variable
que contiene una dirección_. Imagina la partitura clásica de 2001: Una Odisea
del Espacio en este punto. Ba bum ba bum ba bum ¡BAAAAH!

Vale, quizás un poco exagerado, ¿no? No hay mucho misterio sobre los punteros. Son la 
dirección de los datos. Al igual que una variable `int` puede contener el valor `12`, una 
variable puntero puede contener la dirección de los datos.

Esto significa que todas estas cosas son lo mismo, es decir, un número que representa un punto en la memoria:

* Índice en memoria (si piensas en la memoria como una gran matriz)
* Dirección
* Ubicación

Voy a usarlos indistintamente. Y sí, acabo de incluir _localización_ porque nunca hay 
suficientes palabras que signifiquen lo mismo.

Y una variable puntero contiene ese número de dirección. Al igual que
una variable `float` puede contener `3.14159`.

Imagina que tienes un montón de notas Post-it® numeradas en secuencia con
su dirección. (La primera está en el índice numerado `0`, la siguiente en el
índice `1`, y así sucesivamente).

Además del número que representa su posición, también puedes escribir
otro número de tu elección en cada uno. Puede ser el número de perros
que tienes. O el número de lunas alrededor de Marte...

...O, _podría ser el índice de otra nota Post-it_

Si has escrito el número de perros que tienes, eso es sólo una variable
normal. Pero si has escrito ahí el índice de otro Post-it, _eso es un puntero_. ¡Apunta
a la otra nota!

Otra analogía podría ser con las direcciones de las casas. Puedes tener
una casa con ciertas cualidades, patio, tejado metálico, solar, etc. O puedes
tener la dirección de esa casa. La dirección no es lo mismo que la casa en sí.
Una es una casa completa, y la otra son sólo unas líneas de texto. Pero la dirección
de la casa es un _puntero_ a esa casa. No es la casa en sí, pero te dice dónde encontrarla.

Y podemos hacer lo mismo en el ordenador con los datos. Puedes tener una variable
de datos que contenga algún valor. Y ese valor está en la memoria en alguna dirección. Y
puedes tener una variable _puntero_ diferente, que contenga la dirección de esa variable
de datos.

No es la variable de datos en sí, pero, como con la dirección de una casa,
nos dice dónde encontrarla.

Cuando tenemos eso, decimos que tenemos un "puntero a" esos datos. Y podemos seguir
el puntero para acceder a los datos en sí.

(Aunque todavía no parece especialmente útil, todo esto se vuelve indispensable
cuando se utiliza con llamadas a funciones. Ten paciencia conmigo hasta que lleguemos allí).

Así que si tenemos un `int`, digamos, y queremos un puntero a él, lo que queremos es
alguna forma de obtener la dirección de ese `int`, ¿verdad? Después de todo, el puntero
sólo contiene la _dirección de_ los datos. ¿Qué operador crees que usaríamos para
encontrar la _dirección_ del `int`?

Pues bien, por una sorpresa que debe resultarle chocante a usted, amable lector,
utilizamos el operador `dirección` (que resulta ser un ampersand: "`&`")
para encontrar la dirección de los datos. Ampersand.

Así que para un ejemplo rápido, introduciremos un nuevo _especificador de formato_ para
`printf()` para que puedas imprimir un puntero. Ya sabes cómo `%d` imprime un entero decimal,
¿verdad? Pues bien, `%p`[i[`printf()` function-->with
pointers]] imprime un puntero. Ahora, este puntero va a parecer
un número basura (y podría imprimirse en hexadecimal^[Es decir, base 16
con dígitos 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, y F.] en lugar de decimal),
pero es simplemente el índice en memoria en el que se almacenan los datos.
(O el índice en memoria en el que se almacena el primer byte de datos, si los datos son
multibyte). En prácticamente todas las circunstancias, incluyendo ésta, el valor real
del número impreso no es importante para usted, y lo muestro aquí sólo para la
demostración del operador `de dirección`.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i = 10;

    printf("El valor de i es %d\n", i);
    printf("Y su dirección es %p\n", (void *)&i);

```
> **El código anterior contiene un _cast_** donde coaccionamos el tipo de la
> expresión `&i` para que sea del tipo `void*`. Esto es para evitar que el compilador
> arroje una advertencia aquí. Esto es todo lo que no hemos cubierto todavía, así que
> por ahora ignora el `(void*)` en el código de arriba y finge que no está ahí.


En mi computadora, se imprime esto:

``` {.default}
El valor de i es 10
Y su dirección es 0x7ffddf7072a4
```
[i[`&` address-of operator]>]

Si tienes curiosidad, ese número hexadecimal es 140.727.326.896.068 en
decimal (base 10 como la que usaba la abuela). Ese es el índice en memoria
donde se almacenan los datos de la variable `i`. Es la dirección de `i`.
Es la ubicación de `i`. Es un puntero a `i`.

> **Espera-¿Tienes 140 terabytes de RAM?** ¡Sí! ¿No? Pero me causa gracia,
> por supuesto que no (ca. 2024). Los ordenadores modernos usan una
> tecnología milagrosa llamada [flw[memoria virtual|Virtual_memory]] que
> hace que los procesos piensen que tienen todo el espacio de memoria de tu
> ordenador para ellos solos, independientemente de cuánta RAM física lo respalde.
> Así que aunque la dirección era ese enorme número, está siendo mapeada
> a alguna dirección de memoria física más baja por el sistema de memoria virtual de
> mi CPU. Este ordenador en particular tiene 16 GB de RAM (de nuevo, ca. 2024, pero
> uso Linux, así que es suficiente). ¿Terabytes de RAM? Soy profesor,
> no un multimillonario punto-com. Nada de esto es algo de lo que
> que preocuparse, excepto la parte en la que no soy fenomenalmente rico.

Es un puntero porque te permite saber dónde está `i` en la memoria. Al igual
que una dirección escrita en un trozo de papel te dice dónde puedes encontrar
una casa en particular, este número nos indica en qué parte de la memoria podemos
encontrar el valor de `i`. Apunta a `i`.

Una vez más, no nos importa cuál es el número exacto de la dirección,
por lo general. Sólo nos importa que es un puntero a "i".

## Tipos de puntero {#pttypes}

[i[Pointer types]<]Así que... todo esto está muy bien. Ahora puede
tomar con éxito la dirección de una variable e imprimirla en la pantalla. Hay
algo para el viejo currículum, ¿verdad? Aquí es donde me agarras por el cuello
y me preguntas amablemente ¡¡Para qué sirven los punteros!!

Excelente pregunta, y llegaremos a ella justo después de estos
mensajes de nuestro patrocinador.

> `SERVICIOS DE LIMPIEZA ROBOTIZADA DE VIVIENDAS. SU VIVIENDA
>  SERÁ DRÁSTICAMENTE MEJORADA O SERÁ DESPEDIDO.
>  FIN DEL MENSAJE.`

Bienvenidos a otra entrega de la Guía de Beej. La última vez que nos vimos
estuvimos hablando de cómo hacer uso de los punteros. Pues bien, lo que vamos
a hacer es almacenar un puntero en una variable para poder utilizarlo más adelante.
Puedes identificar el _tipo de puntero_ porque hay un asterisco (`*`) antes
del nombre de la variable y después de su tipo:

``` {.c .numberLines}
int main(void)
{
    int i;  // El tipo de i es "int"
    int *p; // El tipo de p es "puntero a un int", o "int-pointer".
}
```

Así que.. aquí tenemos una variable, que es de tipo puntero, y puede apuntar
a otros `int`s. Es decir, puede contener la dirección de otros `int`s. Sabemos que
apunta a `int`s, ya que es de tipo `int*` (léase "int-pointer").

Cuando haces una asignación a una variable puntero, el tipo de la parte derecha
de la asignación tiene que ser del mismo tipo que la variable puntero. Afortunadamente
para nosotros, cuando tomas la `dirección de` (`address-of`) de una variable, el tipo resultante es
un puntero a ese tipo de variable, por lo que asignaciones como la siguiente son perfectas:

``` {.c}
int i;
int *p;  // p es un puntero, pero no está inicializado y apunta a basura

p = &i;  // a p se le asigna la dirección de i--p ahora "apunta a" i
```

A la izquierda de la asignación, tenemos una variable de tipo puntero a `int` (`int*`),
y a la derecha, tenemos una expresión de tipo puntero a `int` ya que `i` es un `int` 
(porque la dirección de `int` te da un puntero a `int`). La dirección de una cosa
puede almacenarse en un puntero a esa cosa.

¿Lo entiendes? Sé que todavía no tiene mucho sentido ya que no has visto un uso "real"
para la variable puntero, pero estamos dando pequeños pasos aquí para que nadie se pierda.
Así que ahora, vamos a presentarte el operador `anti-dirección-de`. Es algo así como lo que 
sería `address-of` en Bizarro World.[i[Pointer types]>]

## Desreferenciación {#deref}

[i[Dereferencing]<]Una variable puntero puede considerarse como _referida_ a otra variable apuntando a ella.
Es raro que oigas a alguien en la tierra de C hablar de "referir" o "referencias", pero
lo traigo a colación sólo para que el nombre de este operador tenga un poco más de sentido.

Cuando tienes un puntero a una variable (más o menos "una referencia a una variable"), puedes
usar la variable original a través del puntero _referenciando_ el puntero. (Puedes pensar
en esto como "despointerizar" el puntero, pero nadie dice nunca "despointerizar").

Volviendo a nuestra analogía, esto es vagamente como mirar la dirección de una casa
y luego ir a esa casa.

Ahora bien, ¿qué quiero decir con "acceder a la variable original"? Bueno, si
tienes una variable llamada `i`, y tienes un puntero a `i` llamado `p`, ¡puedes usar
el puntero desreferenciado `p` _exactamente como si fuera la variable original `i`_!

Casi tienes conocimientos suficientes para manejar un ejemplo. El último dato
que necesitas saber es el siguiente: ¿qué es el operador de desreferencia?
En realidad se llama _operador de dirección_, porque estás accediendo a valores
indirectamente a través del puntero. Y es el asterisco, otra vez: `*`. No lo confundas
con el asterisco que usaste antes en la declaración del puntero. Son el mismo carácter,
pero tienen significados diferentes en contextos diferentes^[¡Eso no es todo! Se usa
en `/*comentarios*/` y en multiplicaciones, ¡y en prototipos de funciones con matrices
de longitud variable! Es el mismo `*`, pero el contexto le da un significado diferente].

He aquí un ejemplo en toda regla:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i;
    int *p;  // esto NO es una desreferencia--esto es un tipo "int*"

    p = &i;  // p apunta ahora a i, p tiene la dirección de i

    i = 10;  // i es ahora 10
    *p = 20; // lo que p señala (es decir, i!) es ahora 20!!

    printf("i es %d\n", i);   // Imprime "20"
    printf("i es %d\n", *p);  // ¡"20"! ¡Dereferencia-p es lo mismo que i!
}
```

Recuerda que `p` contiene la dirección de `i`, como puedes ver donde hicimos
la asignación a `p` en la línea 8. Lo que hace el operador de indirección es
decirle al ordenador que _utilice el objeto al que apunta el puntero_ en lugar de
utilizar el propio puntero. De esta manera, hemos convertido `*p` en una especie
de alias para `i`.[i[Dereferencing]>][i[`*` indirection operator]>]

Genial, pero _¿por qué?_ ¿Por qué hacer algo de esto?

## Pasar punteros como argumentos {#ptpass}

[i[Pointers-->as arguments]<]Ahora mismo estarás pensando que tienes muchísimos
conocimientos sobre punteros, pero absolutamente ninguna aplicación, ¿verdad?
Quiero decir, ¿para qué sirve `*p` si en su lugar puedes decir simplemente `i`?

Pues bien, amigo mío, el verdadero poder de los punteros entra en juego cuando
empiezas a pasarlos a funciones. ¿Por qué es esto tan importante? Tal vez
recuerdes que antes podías pasar todo tipo de argumentos a las funciones los cuales
se copiarían en parámetros, que luego podías manipular en copias locales de esas
variables desde dentro de la función, y así devolver un único valor.

¿Qué pasa si quieres devolver más de un dato de la función? Es decir, sólo puedes
devolver una cosa, ¿verdad? ¿Y si respondo a esa pregunta con otra pregunta?
...Er, ¿dos preguntas?

¿Qué ocurre cuando se pasa un puntero como argumento a una función?
¿Se coloca una copia del puntero en el parámetro correspondiente?
¿Recuerdas que antes he divagado sobre cómo _CADA ARGUMENTO_ se copia en los
parámetros y la función utiliza una COPIA del argumento? Pues aquí ocurre lo mismo.
La función obtendrá una copia del puntero.

Pero, y esta es la parte inteligente: habremos configurado el puntero de antemano
para que apunte a una variable... ¡y entonces la función puede desreferenciar su copia
del puntero para volver a la variable original! La función no puede ver la variable en sí,
¡pero sí puede desreferenciar un puntero a esa variable!

Esto es análogo a escribir la dirección de una casa en un papel y luego copiarla
en otro papel. Ahora tienes _dos_ punteros a esa casa, y ambos son igualmente buenos
para llevarte a la casa misma.

En el caso de una llamada a una función, una de las copias se almacena en una
variable puntero fuera del ámbito de llamada, y la otra se almacena
en una variable puntero que es el parámetro de la función.


Ejemplo: Volvamos a nuestra vieja función `increment()`, pero esta vez
hagámosla de modo que realmente incremente el valor en el ámbito de la llamada.

``` {.c .numberLines}
#include <stdio.h>

// Nota: ten en cuenta que acepta un puntero a un int
void increment(int *p) 
{
    *p = *p + 1;        // Añade uno a la cosa a la que p apunta
}

int main(void)
{
    int i = 10;
    int *j = &i;  // Nota: la dirección de [address-of (&)]; lo convierte en un puntero a i

    printf("i es %d\n", i);        // Imprime "10"
    printf("i es también %d\n", *j);  // Imprime "10"

    increment(j);                  // j es un int*--a i

    printf("i es %d\n", i);        // Imprime "11"!
}
```

¡Ok! Hay un par de cosas que ver aquí... la menor de ellas es que
la función `increment()` toma un `int*` como argumento. Le pasamos
un `int*` en la llamada cambiando la variable `int` `i` a un `int*` usando
el operador `address-of (&)`. (Recuerda, un puntero contiene una dirección, así que
hacemos punteros a variables pasándolas por el operador `address-of`).

La función `increment()` obtiene una copia del puntero. Tanto el puntero
original `j` (en `main()`) como la copia de ese puntero `p` (el
parámetro en `increment()`) apuntan a la misma dirección, la que contiene
el valor `i`. (De nuevo, por analogía, como dos trozos de papel con la misma
dirección escrita en ellos). Si desreferenciamos cualquiera de las dos, podremos
modificar la variable original `i`. La función puede modificar una variable
en otro ámbito. ¡Muévete!

El ejemplo anterior a menudo se escribe de forma más concisa
en la llamada simplemente utilizando address-of en la lista de argumentos:

``` {.c}
printf("i es %d\n", i);  // Imprime "10"
increment(&i);
printf("i es %d\n", i);  // Imprime "11"!
```

Como regla general, si quieres que la función modifique la cosa que estás pasando para que veas el resultado, tendrás que pasar un puntero a esa cosa.

## El puntero `NULL`

[i[`NULL` pointer]<]Cualquier variable puntero de cualquier tipo de puntero
puede establecerse a un valor especial llamado `NULL`. Esto indica que este
puntero no apunta a nada.

``` {.c}
int *p;

p = NULL;
```

Dado que no apunta a un valor, su desreferencia es un comportamiento
INDEFINIDO y probablemente provoque un fallo:

``` {.c}
int *p = NULL;

*p = 12;  // FALLA o ALGO PROBABLEMENTE MALO. LO MEJOR ES EVITARLO.
```

A pesar de ser llamado [flw[el error del millon de dolares
por su creador|Null_pointer#Historia]], el puntero `NULL` es un buen [flw[sentinela|Sentinel 
value]] e indicador general de que un puntero aún no ha sido inicializado.

(Por supuesto, al igual que otras variables, el puntero apunta a basura a menos
que le asignes explícitamente que apunte a una dirección o a `NULL`). [i[puntero `NULL`]>]

## Nota sobre la declaración de punteros

[i[Pointers-->declarations]<]La sintaxis para declarar un puntero puede ser
un poco extraña. Veamos este ejemplo:

``` {.c}
int a;
int b;
```

Podemos condensarlo en una sola línea, ¿verdad?

``` {.c}
int a, b;  // Es lo mismo
```

Así que `a` y `b` son ambas `int`s. No hay problema.

Pero, ¿y esto?

``` {.c}
int a;
int *p;
```

¿Podemos convertirlo en una línea? Sí, podemos. ¿Pero dónde va el `*`?

La regla es que el `*` va delante de cualquier variable que sea de tipo puntero.
Es decir, el `*` no es parte del `int` en este ejemplo. es parte de la variable `p`.

Con eso en mente, podemos escribir esto:

``` {.c}
int a, *p;  // Es lo mismo
```

Es importante notar que la siguiente línea _no_ declara dos punteros:

``` {.c}
int *p, q;  // p es un puntero a un int; q es sólo un int.
```

Esto puede ser particularmente insidioso si el programador escribe la siguiente
línea de código (válida) que es funcionalmente idéntica a la anterior.

``` {.c}
int* p, q;  // p es un puntero a un int; q es sólo un int.
```

Así que echa un vistazo a esto y determina qué variables son punteros y cuáles no:

``` {.c}
int *a, b, c, *d, e, *f, g, h, *i;
```

Dejaré la respuesta en una nota al pie^[Las variables de tipo puntero son `a`, `d`, `f` e `i`, 
porque son las que tienen `*` delante].[i[Pointers-->declarations]>].

## `sizeof` y punteros

[i[Pointers-->with `sizeof`]<]Sólo un poco de sintaxis aquí que puede ser confusa y que
puedes ver de vez en cuando.

Recuerda que `sizeof` opera sobre el _tipo_ de la expresión.
``` {.c}
int *p;

// Imprime el tamaño de un 'int
printf("%zu\n", sizeof(int));

// p es de tipo 'int *', por lo que imprime el tamaño de 'int*'
printf("%zu\n", sizeof p);

// *p es de tipo 'int', por lo que imprime el tamaño de 'int'
printf("%zu\n", sizeof *p);
```

Usted puede ver el código en la naturaleza con ese último `sizeof` allí. Recuerda que
`sizeof` se refiere al tipo de expresión, no a las variables de la expresión.[i[Pointers-->with
`sizeof`]>][i[Pointers]>]
