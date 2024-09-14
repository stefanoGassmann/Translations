<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Matrices Parte II

En este capítulo vamos a repasar algunas cosas extra relacionadas con los arrays.

* Calificadores de tipo con parámetros de arrays
* La palabra clave `static` con parámetros de arrays
* Inicializadores parciales de arrays multidimensionales

No son muy comunes, pero los veremos ya que son parte de la nueva especificación.

## Calificadores de tipo para matrices en listas de parámetros

[i[Type qualifiers-->arrays in parameter lists]<]
[i[Arrays-->type qualifiers in parameter lists]<]

Si lo recuerdas de antes, estas dos cosas son equivalentes en las listas de parámetros de funciones:

``` {.c}
int func(int *p) {...}
int func(int p[]) {...}
```

Y puede que también recuerdes que puedes añadir calificadores de tipo a una variable puntero de esta forma:
``` {.c}
int *const p;
int *volatile p;
int *const volatile p;
// etc.
```

Pero, ¿cómo podemos hacer eso cuando estamos utilizando la notación de matriz en su lista de parámetros?

Resulta que va entre paréntesis. Y puedes poner el recuento opcional después. Las dos líneas siguientes son equivalentes:

``` {.c}
int func(int *const volatile p) {...}
int func(int p[const volatile]) {...}
int func(int p[const volatile 10]) {...}
```

Si tiene una matriz multidimensional, debe colocar los calificadores de tipo en el primer conjunto de corchetes.

[i[Type qualifiers-->arrays in parameter lists]>]
[i[Arrays-->type qualifiers in parameter lists]>]

## `static` para matrices en listas de parámetros

[i[Arrays-->`static` in parameter lists]<]

Del mismo modo, puede utilizar la palabra clave static en la matriz en una lista de parámetros.

Esto es algo que nunca he visto en la naturaleza. Es **siempre** seguido de una dimensión:

``` {.c}
int func(int p[static 4]) {...}
```

Lo que esto significa, en el ejemplo anterior, es que el compilador va a asumir que cualquier array que pases a la función tendrá _al menos_ 4 elementos.

Cualquier otra cosa es un comportamiento indefinido.

``` {.c}
int func(int p[static 4]) {...}

int main(void)
{
    int a[] = {11, 22, 33, 44};
    int b[] = {11, 22, 33, 44, 55};
    int c[] = {11, 22};

    func(a); // ¡OK! a tiene 4 elementos, el mínimo
    func(b); // ¡Bien! b tiene al menos 4 elementos
    func(c); // ¡Comportamiento indefinido! c tiene menos de 4 elementos!
}
```

Esto básicamente establece el tamaño mínimo de array que puedes tener.

Nota importante: no hay nada en el compilador que te prohíba pasar un array más pequeño. El compilador probablemente no te advertirá, y no lo detectará en tiempo de ejecución.

Poniendo `static` ahí, estás diciendo, "Prometo en doble secreto que nunca pasaré un array más pequeño que este". Y el compilador dice, "Sí, bien", y confía en que no lo harás.

Y entonces el compilador puede hacer ciertas optimizaciones de código, con la seguridad de que tú, el programador, siempre harás lo correcto.

[i[Arrays-->`static` in parameter lists]>]

## Inicializadores equivalentes

[i[Arrays-->multidimensional initializers]<]

C es un poco, digamos, _flexible_ cuando se trata de inicializadores de arrays.

Ya hemos visto algo de esto, donde cualquier valor que falte es reemplazado por cero.

Por ejemplo, podemos inicializar un array de 5 elementos a `1,2,0,0,0` con esto:

``` {.c}
int a[5] = {1, 2};
```

O poner un array completamente a cero con:

``` {.c}
int a[5] = {0};
```

Pero las cosas se ponen interesantes cuando se inicializan matrices multidimensionales.

Hagamos un array de 3 filas y 2 columnas:

``` {.c}
int a[3][2];
```

Escribamos algo de código para inicializarlo e imprimir el resultado:

``` {.c}
#include <stdio.h>

int main(void)
{
    int a[3][2] = {
        {1, 2},
        {3, 4},
        {5, 6}
    };

    for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 2; col++)
            printf("%d ", a[row][col]);
        printf("\n");
    }
}
```

Y cuando lo ejecutamos, obtenemos lo esperado:

``` {.default}
1 2
3 4
5 6
```

Dejemos fuera algunos de los elementos inicializadores y veamos cómo se ponen a cero:

``` {.c}
    int a[3][2] = {
        {1, 2},
        {3},    // ¡Deja el 4!
        {5, 6}
    };
```

que produce:

``` {.default}
1 2
3 0
5 6
```

Ahora dejemos todo el último elemento del medio:

``` {.c}
    int a[3][2] = {
        {1, 2},
        // {3, 4},   // Solo corta todo esto
        {5, 6}
    };
```

Y ahora tenemos esto, que puede que no sea lo que esperas:

``` {.default}
1 2
5 6
0 0
```

Pero si te paras a pensarlo, sólo proporcionamos inicializadores suficientes para dos filas, por lo que se utilizaron para las dos primeras filas. Y los elementos restantes se inicializaron a cero.

Hasta aquí todo bien. Generalmente, si omitimos partes del inicializador, el compilador pone los elementos correspondientes a "0".

Pero pongámonos _locos_.

``` {.c}
    int a[3][2] = { 1, 2, 3, 4, 5, 6 };
```

¿Qué...? Es un array 2D, ¡pero sólo tiene un inicializador 1D!

Resulta que es legal (aunque GCC avisará de ello con las advertencias adecuadas activadas).

Básicamente, lo que hace es empezar a rellenar los elementos de la fila 0, luego la fila 1, luego la fila 2 de izquierda a derecha.

Así que cuando imprimimos, imprime en orden:

``` {.default}
1 2
3 4
5 6
```

Si dejamos algunos fuera:

``` {.c}
    int a[3][2] = { 1, 2, 3 };
```

se llenan con "0":

``` {.default}
1 2
3 0
0 0
```

Así que si quieres llenar todo el array con `0`, entonces adelante:

``` {.c}
    int a[3][2] = {0};
```

Pero mi recomendación es que si tienes un array 2D, uses un inicializador 2D. Hace el código más legible. (Excepto para inicializar todo el array con `0`, en cuyo caso es idiomático usar `{0}` sin importar la dimensión del array).

[i[Arrays-->multidimensional initializers]>]

