<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Alcance {#scope}

[i[Scope]<]
El alcance se refiere a, en qué contextos son visibles las variables.

## Alcance del bloque

[i[Scope-->block]<]
Este es el ámbito de casi todas las variables que definen los desarrolladores. Incluye
lo que en otros lenguajes se denomina «ámbito de función», es decir, las variables
que se declaran dentro de funciones.

La regla básica es que si has declarado una variable en un bloque delimitado por
llaves, el ámbito de esa variable es ese bloque.

Si hay un bloque dentro de otro bloque, las variables declaradas en el bloque _interior_
son locales a ese bloque y no pueden verse en el ámbito exterior.

Una vez que el ámbito de una variable termina, ya no se puede hacer referencia
a esa variable, y se puede considerar que su valor se ha ido [flw[al gran cubo de bits|Bit_
bucket]] en el cielo.


Un ejemplo con ámbito anidado:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int a = 12;         // Local al bloque exterior, pero visible en el bloque interior

    if  (a == 12) {
        int b = 99;     // Local al bloque interior, no visible en el bloque exterior

        printf("%d %d\n", a, b);  // OK: "12 99"
    }

    printf("%d\n", a);  // OK, todavía estamos en el ámbito de a

    printf("%d\n", b);  // ILEGAL, fuera del ámbito de b
}
```

### Dónde definir las variables

Otro dato curioso es que se pueden definir variables en cualquier parte del bloque, dentro
de lo razonable: tienen el ámbito de ese bloque, pero no se pueden utilizar antes
de definirlas.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i = 0;

    printf("%d\n", i);     // OK: "0"

    //printf("%d\n", j);   // ILEGAL--no se puede usar j antes de que esté definido

    int j = 5;

    printf("%d %d\n", i, j);   // OK: "0 5"
}
```

Históricamente, C exigía que todas las variables estuvieran definidas antes de cualquier
código del bloque, pero esto ya no es así en el estándar C99.

### Ocultación de variables

[i[Variable hiding]<]
Si tienes una variable con el mismo nombre en un ámbito interno y en un ámbito externo, la
del ámbito interno tiene preferencia mientras estés ejecutando en el ámbito interno. Es decir,
_oculta_ a la del ámbito externo durante todo su tiempo de vida.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i = 10;

    {
        int i = 20;

        printf("%d\n", i);  // Ámbito interno i, 20 (el externo i está oculto)
    }

    printf("%d\n", i);  // Ámbito exterior i, 10
}
```

Te habrás dado cuenta de que en ese ejemplo acabo de lanzar un bloque en la línea 7,
¡ni siquiera una sentencia `for` o `if` para iniciarlo! Esto es perfectamente legal. A veces
un desarrollador querrá agrupar un montón de variables locales para un cálculo rápido y hará
esto, pero es raro de ver.
[i[Variable hiding]>]
[i[Scope-->block]>]

## Alcance de fichero / Archivo

[i[Scope-->file]<]
Si define una variable fuera de un bloque, esa variable tiene _ámbito de fichero_. Es visible
en todas las funciones del archivo que vienen después de ella, y compartida entre ellas.
(Una excepción es si un bloque define una variable del mismo nombre, ocultaría la que
tiene ámbito de archivo).

Es lo más parecido a lo que se consideraría ámbito «global» en otro idioma.

Por ejemplo:

``` {.c .numberLines}
#include <stdio.h>

int shared = 10;    // ¡Alcance del fichero!
                    // ¡Visible a todo el archivo después de esto!

void func1(void)
{
    shared += 100;  // Ahora shared tiene 110
}

void func2(void)
{
    printf("%d\n", shared);  // Imprime "110"
}

int main(void)
{
    func1();
    func2();
}
```

Ten en cuenta que si `shared` se declarara al final del fichero, no compilaría. Tiene que
ser declarado _antes_ de que cualquier función lo use.

Hay otras formas de modificar elementos en el ámbito del fichero, concretamente con
[static](#static) y [extern](#extern), pero hablaremos de ellas más adelante.
[i[Scope-->file]>]

## Ambito del bucle `for`

[i[Scope-->`for` loop]<]
Realmente no sé cómo llamar a esto, ya que C11 §6.8.5.3¶1 no le da un nombre apropiado.
También lo hemos hecho ya varias veces en esta guía. Es cuando declaras una variable
dentro de la primera cláusula de un bucle `for`:

``` {.c}
for (int i = 0; i < 10; i++)
    printf("%d\n", i);

printf("%d\n", i);  // ILEGAL--i sólo está en el ámbito del bucle for
```

En ese ejemplo, el tiempo de vida de `i` comienza en el momento en que se define, y continúa
durante la duración del bucle.

Si el cuerpo del bucle está encerrado en un bloque, las variables definidas en el bucle
`for` son visibles desde ese ámbito interno. 

A menos, por supuesto, que ese ámbito interno las oculte. Este ejemplo loco
imprime `999` cinco veces:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    for (int i = 0; i < 5; i++) {
        int i = 999;  // Oculta la i en el ámbito del bucle for
        printf("%d\n", i);
    }
}
```
[i[Scope-->`for` loop]>]

## Nota sobre el alcance de las funciones

[i[Scope-->function]<]
La especificación C hace referencia a _function scope_ (alcance de funciones), pero se utiliza exclusivamente
con _labels_ (etiquetas), algo que aún no hemos discutido. Otro día hablaremos de ello.
[i[Scope-->function]>]
[i[Scope]>]
