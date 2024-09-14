<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Funciones {#functions}

> "Señor, no en un ambiente como éste. Por eso también he sido 
> programado para más de treinta funciones secundarias que..."_>
>
> ---C3PO[i[C3PO]], antes de ser interrumpido bruscamente, informando de un número ya poco 
> impresionante de funciones adicionales, _Star Wars_ script
[i[Functions]<]

Muy parecido a otros lenguajes a los que estás acostumbrado, C tiene el concepto de
_funciones_.

Las funciones pueden aceptar una variedad de _argumentos_ [i[Function arguments]] y
devolver un valor. Sin embargo, hay algo importante: los tipos de argumentos y valores de retorno están predeclarados,—¡porque así lo prefiere C!

Veamos una función. Esta es una función que toma un `int` como argumento,
y devuelve [i[`return` statement]] un `int`.


``` {.c .numberLines}
#include <stdio.h>

int plus_one(int n)  // La "Definición"
{
    return n + 1;
}
 
```

El `int` antes del `plus_one` indica el tipo de retorno.

El `int n` indica que esta función toma un argumento `int`,
almacenado en el _parámetro_ `n`[i[Function parameters]]. Un parámetro es un
tipo especial de variable local en la que se copian los argumentos.

Voy a insistir en que los argumentos se copian en los parámetros. Muchas cosas en C
son más fáciles de entender si sabes que el parámetro es una _copia_ del argumento,
no el argumento en sí. Más sobre esto en un minuto.

Continuando el programa hasta `main()`, podemos ver la llamada a la función, donde asignamos 
el valor de retorno a la variable local `j`:

``` {.c .numberLines startFrom="8"}
int main(void)
{
    int i = 10, j;
    
    j = plus_one(i);  // La "llamada"

    printf("i + 1 es %d\n", j);
}
```

> Antes de que se me olvide, fíjate en que he definido la función
> antes de usarla. Si no lo hubiera hecho, el compilador aún no la conocería
> al compilar `main()` y habría dado un error de llamada a función desconocida.
> Hay una forma más adecuada de hacer el código anterior con _prototipos de función_,
> pero hablaremos de eso más adelante.

Observa también que `main()`[i[`main()` function]] ¡es una función!

Devuelve un `int`.

¿Pero qué es eso de `void`[i[`void` type]]? Es una palabra clave
para indicar que la función no acepta argumentos.

También puede devolver `void` para indicar que no devuelve ningún valor:


``` {.c .numberLines}
#include <stdio.h>

// Esta función no toma argumentos y no devuelve ningún valor:

void hello(void)
{
    printf("Hello, world!\n");
}

int main(void)
{
    hello();  // Imprime "Hello, world!"
}
```

## Transmisión por valor {#passvalue}

[i[Pass by value]()]He mencionado antes que cuando pasas un argumento
a una función, se hace una copia de ese argumento y se almacena en el parámetro 
correspondiente.

Si el argumento es una variable, se hace una copia del valor de esa variable y se almacena en 
el parámetro.

De forma más general, se evalúa toda la expresión del argumento y se determina su valor. Ese 
valor se copia en el parámetro.

En cualquier caso, el valor del parámetro es algo propio. Es independiente de los valores o 
variables que hayas utilizado como argumentos al llamar a la función.

Veamos un ejemplo. Estúdielo y vea si puede determinar
la salida antes de ejecutarlo:

``` {.c .numberLines}
#include <stdio.h>

void increment(int a)
{
    a++;
}

int main(void)
{
    int i = 10;

    increment(i);

    printf("i == %d\n", i);  // ¿Qué imprime esto?
}
```

A primera vista, parece que `i` es `10`, y lo pasamos a la función
`increment()`. Allí el valor se incrementa, así que cuando lo imprimimos,
 debe ser `11`, ¿no?

> "Acostúmbrate a la decepción."
>
> ---El temible pirata Roberts, La princesa prometida

Pero no es `11`... ¡imprime `10`! ¿Cómo?

Se trata de que las expresiones que pasas a las funciones
se _copian_ en sus parámetros correspondientes. El parámetro
es una copia, no el original

Así que `i` es `10` en `main()`. Y se lo pasamos a `increment()`. El parámetro
correspondiente se llama `a` en esa función.

Y la copia ocurre, como si fuera una asignación. Más o menos,
`a = i`. Así que en ese punto, `a` es `10`. Y en `main()`, `i` es también `10`.

Entonces incrementamos `a` a `11`. ¡Pero no estamos tocando `i` en absoluto!
Sigue siendo `10`.

Finalmente, la función está completa. Todas sus variables locales se descartan
(¡adiós, `a`!) y volvemos a `main()`, donde `i` sigue siendo `10`.

Y lo imprimimos, obteniendo `10`, y hemos terminado.

Por eso en el ejemplo anterior con la función `plus_one()`,
`devolvíamos` el valor modificado localmente para poder verlo de nuevo en `main()`.

Parece un poco restrictivo, ¿no? Como si sólo pudieras recuperar un dato
de una función, es lo que estás pensando. Hay, sin embargo, otra forma de recuperar
datos; la gente de C lo llama _pasar por referencia_ y esa es una historia que contaremos
en otra ocasión.

Pero ningún nombre rimbombante te distraerá del hecho de que _TODO_
lo que pasas a una función _SIN EXCEPCIÓN_ se copia en su parámetro correspondiente,
y la función opera sobre esa copia local, _NO IMPORTA QUÉ_.
Recuérdalo, incluso cuando estemos hablando del llamado paso por referencia.
[i[Pass by value]>]

## Prototipos de funciones {#prototypes}

[i[Function prototypes]<]Así que si recuerdas en la edad de hielo hace unas secciones,
mencioné que tenías que definir la función antes de usarla, de lo contrario el compilador
no lo sabría de antemano, y bombardearía con un error.

Esto no es estrictamente cierto. Puedes notificar al compilador por adelantado que vas a
utilizar una función de un tipo determinado que tiene una lista de parámetros determinada.
De esta forma, la función puede definirse en cualquier lugar (incluso en un fichero diferente),
siempre que el _prototipo de función_ haya sido declarado antes de llamar a esa función.

Afortunadamente, el prototipo de función es realmente sencillo. Es simplemente una copia de la 
primera línea de la definición de la función con un punto y coma al final. Por ejemplo, este 
código llama a una función que se define más tarde, porque primero se ha declarado un prototipo:

``` {.c .numberLines}
#include <stdio.h>

int foo(void);  // Esto es el prototipo!

int main(void)
{
    int i;
    
    // Podemos llamar aquí a foo() antes de su definición porque el
    // prototipo ya ha sido declarado, ¡arriba!

    i = foo();
    
    printf("%d\n", i);  // 3490
}

int foo(void)  // ¡Esta es la definición, igual que el prototipo!
{
    return 3490;
}
```

Si no declaras tu función antes de usarla (ya sea con un prototipo o
con su definición), estás realizando algo llamado _declaración implícita_.[i[Implicit 
declaration]]Esto estaba permitido en el primer estándar C (C89), y ese estándar
tiene reglas al respecto, pero ya no está permitido hoy en día. Y no hay ninguna
razón legítima para confiar en ello en código nuevo.

Puede que notes algo en el código de ejemplo que hemos estado utilizando... Es decir,
¡hemos estado usando la vieja función `printf()` sin definirla ni declarar un prototipo!
¿Cómo nos libramos de esta ilegalidad? En realidad, no lo hacemos.
Hay un prototipo; está en ese fichero de cabecera `stdio.h` que incluimos
con `#include`, ¿recuerdas? ¡Así que seguimos siendo legales, oficial!
[i[Function prototypes]>]

## Listas de parámetros vacías

[i[Empty parameter lists]]Es posible que los veas de vez en cuando en código antiguo, pero 
nunca deberías usar uno en código nuevo. Usa siempre `void`[i[`void` type]] para indicar que 
una función no toma parámetros. Nunca hay^[Nunca digas "nunca".] una razón para omitir esto en 
código moderno.


Si eres bueno recordando poner `void` para listas de parámetros vacías en funciones y 
prototipos, puedes saltarte el resto de esta sección.

Hay dos contextos para esto:

* Omitir todos los parámetros donde se define la función
* Omitir todos los parámetros en un prototipo

Veamos primero una posible definición de función:

``` {.c}
void foo()  // Realmente debería tener un `void` ahí
{
    printf("Hello, world!\n");
}
```


Aunque la especificación dice que el comportamiento en este caso es _como si_ hubieras 
indicado `void` (C11§6.7.6.3¶14), el tipo `void` está ahí por una razón. Utilícelo.

Pero en el caso de un prototipo de función, hay una diferencia _significativa_ entre
usar `void`[i[tipo `void`-->en prototipos de función]] y no:

``` {.c}
void foo();
void foo(void);  // ¡No es lo mismo!
```


Dejar `void` fuera del prototipo indica al compilador que no hay información adicional sobre 
los parámetros de la función. De hecho, desactiva toda la comprobación de tipos.

Con un prototipo **definitivamente** use `void` cuando tenga una lista de parámetros vacía.

[i[Functions]>]
