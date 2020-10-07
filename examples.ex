"""
Pero antes de empezar con los macros vamos a examinar algo mas simple:
"""

"""
La gran mayoría de elixir está escrita en elixir gracias a los macros
Esto es gracias a la flexibilidad que los macros brindan.
En esta charla vamos a ver que son los macros y una pequeña parte de lo que podemos hacer con ellos.

Para hacernos una idea de como funcionan empecemos con lo siguiente:

La manera mas usual de usar elixir es Modulo.funcion(argumentos)
"""










if 1 + 2 == 3 do
  "this"
else
  "that"
end

if 1 + 2 == 3, do: "this", else: "that"
if(1 + 2 == 3, do: "this", else: "that")
if((1 + 2 == 3), [do: "this", else: "that"])
if((1 + 2) == 3), [do: "this", else: "that"])
if(Kernel.==(Kernel.+(1,2), 3), [do: "this", else: "that"])
Kernel.if(Kernel.==(Kernel.+(1,2), 3), [do: "this", else: "that"])

"""
La primer manera de leer código es mucho mas cómoda, la segunda es de 'mas bajo nivel'.

Vamos a ver los pasos que sigue el compilador para llegar a esto:

Paso 1: Leer código
Paso 2: Convertirlo en un AST
Paso 3: Pasarselo a beam para que lo ejecute


El AST de elixir está en términos del propio lenguaje:
Ese lenguaje está formado por dos tipos de elementos

1) Quote Literals

atoms :kalil
integers 165
floats 19.94
strings "Hola"
listas [1,2,3]
tuplas de dos elementos {"dos", :elementos}

2) tuplas de 3 elementos

variables
{:pepe, [], Elixir}

llamadas a funciones

{:+, [context: Elixir, import: Kernel], [1, 2]}

como hacemos para convertir nuestro código elixir al AST?

elixr define un macro para eso: quote

"""
quote do: 1 + 2

"que pasa si sumamos una variable ahora?"

pepe = 2

quote do: 1 + pepe

"eso no nos da exactamente lo que esperamos. para eso precisamos otro macro: unquote"

quote do: 1 + unquote(pepe)

"unquote funciona como una suerte de string interpolation cuando accedemos al valor de una variable o una llamada"

"volvamos ahora al primer if que vimos hace un rato:"

quote do: if 1 + 2 == 3 do: "this", else: "that"

"""
Tenemos una tupla de tres elementos donde el primero es el nombre de la funcion :if

{
  :if,
  [context: Elixir, import: Kernel],
  [
    {
      :==,
      [context: Elixir, import: Kernel],
      [
        {
          :+,
          [context: Elixir, import: Kernel],
          [
            1,
            2
          ]
        },
        3
      ]
    },
    [
      do: "this",
      else: "that",
    ]
  ]
}

El segundo es la metadata, y el tercero es una lista de argumentos.
El primero de estos argumentos es una llamada a otra función, y luego la lista de kwargs [do: this, else: that]
Si volvemos al primer argumento de la llamada, vamos a ver que es otra llamada a una función
"""

"""
hasta ahora vimos algunos macros útiles que define elixir pero no tenemos control real sobre ellos
eso va a cambiar con el siguiente macro:

defmacro

un macro es fundamentalmente una función que retorna un AST.

difiere en un par de cosas que vamos a ver a continuación

Los argumentos llegan quoteados
como los argumentos llegan quoteados estos no se evalúan.

Los nombres asignados en un macro no afectan a los nombres declarados en las funciones de adentro del macro.
podemos sobreescribir esto usando var!(a)

definamos un macro para el if
"""
defmodule MyIfs do
  defmacro m_if(condition, do: if_cond, else: if_not_cond) do
    quote do
      case unquote(condition) do
        false -> unquote(if_cond)
        _ -> unquote(if_not_cond)
      end
    end
  end

  def f_if(condition, do: if_cond, else: if_not_cond) do
    case condition do
      true -> if_cond
      _ -> if_not_cond
    end
  end

end
"""
Puedo hacer pattern matching sobre el ast
"""
defmodule PrettyPrint do

  defmacro pretty({name, _meta, [arg1, arg2]} = ast) do
    quote do
      IO.puts("""
          #{unquote(arg1)} 
        #{Atom.to_string(unquote(name))} #{unquote(arg2)}
        ---
         #{unquote(ast)}
      """)
    end
  end
  
  defmacro pretty({name, _meta, _context} = ast) do
    quote do: IO.puts("#{Atom.to_string(unquote(name))} => #{unquote(ast)}")
  end
  
  defmacro pretty(literal) do
    quote do: IO.puts(unquote(literal))
  end
end
"""
Otros macros interesantes del lenguage:

use
"""
defmodule Test do
  use Utility, argument: :lala
end
"""
es equivalente a
"""
defmodule Test do
  require Utility
  Utility.__using__(argument: :lala)
end
"""
esto es util para inyectar código de bibliotecas que usamos en nuestro código. 
https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/controller/pipeline.ex
https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/endpoint.ex
https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/router.ex
"""
