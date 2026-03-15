#import "../../theme/common.typ": deck, code, code-file, note
#import "@preview/typslides:1.3.2": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/cetz:0.3.1"
#show: codly-init.with()

#show: deck
#codly(display-icon: false, display-name: false, zebra-fill: black.transparentize(96%))
#front-slide(
  title: "JIT-compilers basics",
  subtitle: [Байткод - универсальное представление программ],
  authors: "Ilya Gavrilin, Syntacore",
  info: [MIPT, 2026],
)

#slide(title: "Достаточно ли вам сжатия?")[#align(top)[
- На прошлых занятиях обсуждали, как бы мы хотели распространять файлы
- Исходный код - разумный вариант для распространения

]]

#slide(title: "Достаточно ли вам сжатия?")[#align(top)[
#grid(
  columns: (3fr, 2fr),
  gutter: 1.5em,

  [
  - На прошлых занятиях обсуждали, как бы мы хотели распространять файлы
  - Исходный код - разумный вариант для распространения
  - Размер исходного файла: 30.71 KB
  - Размер минифицированного: 9.92 KB (\~70%)
  ],

  [
    #align(bottom)[#image("assets/push_meme.jpg", width: 100%)]
  ],
)
#note[https://math.hws.edu/eck/cs124/javanotes8/source/chapter7/Checkers.java]
]]

#slide(title: "Достаточно ли вам сжатия?")[#align(top)[
#grid(
  columns: (3fr, 2fr),
  gutter: 1.5em,

  [
  - На прошлых занятиях обсуждали, как бы мы хотели распространять файлы
  - Исходный код - разумный вариант для распространения
  - Размер исходного файла: 30.71 KB
  - Размер минифицированного: 9.92 KB (\~70%)
  #v(2em)
  - Размер Classfile: \~ 32 KB
  - Размер JAR: \~ 4 KB
  ],

  [
    #align(bottom)[#image("assets/push_meme.jpg", width: 100%)]
  ],
)
#note[https://math.hws.edu/eck/cs124/javanotes8/source/chapter7/Checkers.java]
]]
#slide(title: "Точка синхронизации")[#align(top)[
- Универсальное представление позволяет нам абстрагироваться от языка
- Компактное представление позволяет нам проще интерпретировать код
#image("assets/jvm-combine.png", width: 100%)
]]

#slide(title: "Наши требования очень просты")[#align(top)[
- Требования к промежуточному представлению:
  - Бинарное представление
  - Компактность и удобство декодирования
  - Простота для интерпретации
  - _ Строгая типизация _
  #v(4em)
- Может используем что-то уже готовое?
  - Промежуточное представление оптимизирующего компилятора
  - Ассемблер некой архитектуры
]]
#slide(title: "3-адресный код (Three Address Code)")[#align(top)[
Пусть инструкция содержит три операнда (адреса) и операцию

```asm
res = lhs op rhs
// res, lhs, rhs - addresses
// op - operation
```
#v(2em)
С таким кодом вы уже встречались:
```asm
add  x1, x2, x3
addi x1, x2, 10

```
- Остановимся на таком представлении?
]]

#slide(title: "2-адресный код")[#align(top)[
- Чтобы поддержать все те же операции добавим условие: `res == lhs`

```asm
lhs op rhs
// lhs - killed
// res == lhs
lhs = lhs op rhs

a = inc a
```
- Теперь уменьшили число операнд, но потеряли экспрессивность
- Оставновимся на этом?
]]

#slide(title: "1-адресный код (Stack Machine)")[#align(top)[
- Операнды не указываются явно — они берутся из стека операндов

Трансляция выражения:

```asm
iload b
iload c
iadd
iload d
imul
istore a
```

- Наконец-то достигли того, что нас устраивает
- Но что делать с объектной структурой?
]]

#slide(title: "Байткод")[#align(top)[
- Байткод — платформонезависимое промежуточное представление программы, которое исполняется виртуальной машиной. (Название зачастую намекает на размер инструкции)
#v(2em)
В JVM байткод основан на:

- *стековой модели вычислений*
- *типизированных инструкциях*
- *массиве локальных переменных*
]]
#slide(title: "Типичные инструкции Java Bytecode")[#align(top)[
- Немного самых популярных инструкций:
#table(
  columns: (auto, 1fr),

  [*Инструкция*], [*Операция*],

  [`iload n`], [загрузить `int` из local variables в стек],
  [`istore n`], [сохранить `int` из стека в local variables],

  [`iadd`], [сложить два `int` на вершине стека],
  [`imul`], [умножить два `int`],

  [`new`], [создать объект],

  [`getfield`], [прочитать поле объекта],
  [`putfield`], [записать поле объекта],

  [`invokevirtual`], [вызвать виртуальный метод],

  [`return`], [вернуть управление из метода],
)
#note[https://docs.oracle.com/javase/specs/jvms/se25/html/jvms-6.html#jvms-6.5]
]]
#slide(title: "А с чем мы вообще работаем")[#align(horizon)[
#grid(
  columns: (1fr, 1.6fr),
  gutter: 1em,

  [
  *Run-Time Data Areas*

  - PC Register  
  - JVM Stacks  
    - Locals  
    - Operand Stack  
  - Heap  
  - Run-Time Constant Pool  
  - Native Stack *(optional)*
  ],

  [
  #image("assets/bytecode-areas.png", width: 100%)
  ]
)
]]

#slide(title: "Упражняемся в чтении байткода")[#align(top)[
```asm
       0: goto          11
       3: iload_0
       4: iload_1
       5: irem
       6: istore_2
       7: iload_1
       8: istore_0
       9: iload_2
      10: istore_1
      11: iload_1
      12: ifne          3
      15: iload_0
```
]]
#slide(title: "Упражняемся в чтении байткода")[#align(top)[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  ```asm
  0: goto 11
  3: iload_0
  4: iload_1
  5: irem
  6: istore_2
  7: iload_1
  8: istore_0
  9: iload_2
 10: istore_1
 11: iload_1
 12: ifne 3
 15: iload_0
  ``` 
  ],

  [
    #align(horizon)[

  ```c
  while (b != 0) {
      t = a % b
      a = b
      b = t
  }

  return a
  ```
  ]]
)
]]
#slide(title: "Слабая типизация")[
#grid(
  columns: (1.3fr, 1fr),
  gutter: 0em,

  [
  *Слабая типизация*

  Язык автоматически приводит типы
  во время выполнения.

  Пример:

  ```js
  "5" + 3   // "53"
  "5" - 3   // 2
  ```

  - неявное преобразование типов  
  - операции могут менять тип операндов
  ],

  [
  #align(center)[
    #image("assets/sad-meme.png", width: 80%)
  ]
  ]
)
]
#slide(title: "Динамическая типизация")[#align(top)[

- Тип связан со *значением*, а не с переменной.
- Он определяется во время выполнения.

Пример:

```js
let x = 10
x = "hello"
x = true
```
#v(2em)
- одна переменная может хранить разные типы
- проверка типов происходит во время выполнения
]]
#slide(title: "Как это исполнять")[
#grid(
  columns: (1fr, 1fr),
  gutter: 1em,

  [
  ```asm
  0 : Ldar a1
  4 : JumpIfTrue 18
  6 : Ldar a0
  8 : Mod a1
 10 : Star r2
 12 : Mov a1, a0
 14 : Mov r2, a1
 16 : JumpLoop 0
 18 : Ldar a0
 20 : Return
  ```
  ],

  [

  ```text
  while (b != 0) {
      t = a % b
      a = b
      b = t
  }

  return a
  ```
  ]
)
]
#slide(title: "А какая полярность у аккумулятора?")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  *Регистровая виртуальная машина*

  - оперируем ограниченным количеством регистров 
  - один регистр используется как *аккумулятор*
  #v(1em)
  - Аккумулятор — это регистр, где хранится текущий результат операции.
  ],

  [
  *Пример выполнения*


  ```text
  t = a % b
  ```
  #v(2em)
  Байткод:

  ```asm
  Ldar a0      ; acc = a
  Mod a1       ; acc = acc % b
  Star r2      ; r2 = acc
  ```
  ]
)

]
#slide(title: "И как теперь это интерпретировать?")[#align(top)[
  - Наличие динамических типов вынуждает нас проверять операнды и модифицировать поведение
  #align(center)[#image("assets/ecma-less.png", width: 80%)]

]]
#slide(title: "Тяжело, тяжело...")[#align(top)[
  - Наличие динамических типов вынуждает нас проверять операнды и модифицировать поведение
    - Нам необходимо в интерпретаторе проверять, что именно лежит в регистре
    - Нужно проверять результат
    - Оцените, насколько быстро заработает сложение...
    #v(2em)
  - А теперь подумайте, нужно ли в Java байткоде добавлять проверки?

    #v(3em)
  #note[https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html#sec-numeric-types-number-lessThan]
]]

#slide(title: "Как это интерпретировать")[#align(top)[
- Давайте подумаем, хотим ли мы такие проверки в нашем байткоде  
```cpp
  case IADD: {
      Value v1 = stack.pop();
      Value v2 = stack.pop();
      if (v1.type != INT || v2.type != INT) {
          throw TypeError();
      }
      stack.push(
          Value{INT, v2.i + v1.i}
      );
      break;
  }
  ```
]]
#slide(title: "Class Loading в JVM")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  *Этапы*

  ```text
  Loading
  ↓
  Linking
    • Verification
    • Preparation
    • Resolution
  ↓
  Initialization
  ```
  ],

  [
  *Что происходит*

  *1. Loading*

  чтение .class файла
 

  *2. Verification*

  проверка байткода
  

  *3. Initialization*

  запуск <clinit>
  ]
)
]
#slide(title: "Верификация байткода JVM")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  *Типы в JVM*

  Байткод работает с типами:

  - `int`, `long`, `float`, `double`
  - `reference`
  - `null`

  Проверяется:

  - корректность типов на стеке
  - допустимость приведения ссылочных типов
  ],

  [
  *Требования к байткоду*

  Структурные

  - корректные индексы переменных  
  - валидные инструкции

  Control Flow

  - одинаковые типы стека на точках слияния
  - стек не переполняется и не уходит в минус
  ]
)
]
#slide(title: "Статический анализ потока")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  ```asm
  if (...) goto L1

  iconst_1
  goto L2

  L1:
  iconst_2

  L2:
  iadd
  ```
  ],

  [
  *Идея*

  JVM делает _ data-flow анализ _

  - распространяем типы по control-flow graph

  Требование:
  - stack types must match
  ]
)
]
#slide(title: "StackMapTable")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  *StackMapTable*

  - таблица типов для точек программы
  - позволяет не искать решение, а проверять его
  
  Позволяет JVM:

  - не вычислять типы заново
  - ускорить verification
  ],

  [
  ```text
  offset 0
  locals: int int
  stack:  -

  offset 11
  locals: int int
  stack:  int
  ```
  ]
)
  #note[Посмотрим вживую: https://javap.yawk.at/#w5Yewy]

]

#slide(title: "Выводы")[#align(top)[
- Сегодня нашли наиболее эффективное представление кода - байткод
- Узнали, что делать с динамически типизируемыми языками
- Попробовали себя в верификации
#v(5em)
- Домашнего задания не будет - каждый из вас сможет выбрать наиболее интересную теоретическую тему
- Кстати о литературе
]]
#slide(title: "Список литературы")[#align(top)[
- Oracle: Java Bytecode Crash Course #link("https://youtu.be/e2zmmkc5xI0?si=Fq8I17r6p5mHOeM-")[youtube]
- Никита Липский — Верификация Java байт-кода: когда, как, а может отключить? #link("https://youtu.be/m16AIz1fIFI?si=ed4EcVO13Z8pHNZY")[youtube]
- Engineering a Compiler: CHAPTER 5 Intermediate Representations
]]
