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
  subtitle: [Интерпретация байткода],
  authors: "Ilya Gavrilin, Syntacore",
  info: [MIPT, 2026],
)

#slide(title: "Что вы понимаете под программой?")[#align(top)[
- На прошлых занятиях узнали, что такое байткод и как с нима работать
- Программа - набор отдельных классов с некой точкой входа
- Класс - набор методов и полей, методы - последовательность байткодов
#v(2em)
- Давайте попробуем подумать в ином ключе\...
]]

#slide(title: "Что вы понимаете под программой?")[#align(top)[
- На прошлых занятиях узнали, что такое байткод и как с нима работать
- Программа - набор отдельных классов с некой точкой входа
- Класс - набор методов и полей, методы - последовательность байткодов
#v(2em)
- Давайте попробуем подумать в ином ключе
- Пришло время познакомить вас с *lisp*
]]

#slide(title: "Lisp: всё есть список")[
#grid(columns: (1fr, 1fr), gutter: 2em,

  align(top)[
  #text(weight: "bold")[Особенности]

  #v(0.5em)
  - Всё является выражением
  - Префиксная форма записи
  - *Код = данные*
  - Минимальный синтаксис
  ],

  align(top)[
  #text(weight: "bold")[Пример]

  #v(0.5em)

```lisp
(+ 1 2 3)

(define (square x)
  (* x x))

(square 5)
```
  ])


#note[Программа в Lisp — это структурированные данные]
]

#slide(title: "S-expression")[
#grid(columns: (1fr, 1fr), gutter: 2em,

  align(top)[
  #text(weight: "bold")[Определение]

  #v(0.5em)

  - S-expression:
    - атом (число, символ)
    - или список S-выражений

  #v(0.5em)

  Определение рекурсивно
  ],
  align(top)[
  #text(weight: "bold")[Примеры]

  #v(0.5em)

```lisp
42
x
(+ 1 2)
(* (+ 1 2) 3)
```
  ])


#note[Любая программа на Lisp — это S-выражение]
]

#slide(title: "Код как синтаксическое дерево")[
#grid(columns: (1fr, 1fr), gutter: 2em,
[
В большинстве языков:

 текст → парсер → AST

В Lisp:

текст = готовое синтаксическое дерево

Пример:

```lisp
(* (+ 1 2) 3)
```
- список = узел дерева
- первый элемент — операция
- остальные — аргументы
],
[#align(horizon)[#image("assets/ast-tree.png",height:100%)]])
]
#slide(title: "Интерпретатор")[

- Интерпретатор — это программа, которая реализует семантику другого языка, непосредственно выполняя его конструкции без предварительной генерации
самостоятельного исполняемого кода.

#v(1.5em)

#grid(columns: (1fr, 1fr), gutter: 1em,

  align(top)[
  #text(weight: "bold")[Формальная схема]


```text
I : Program × State → State
```
  - Program — программа на интерпретируемом языке
  - State — состояние выполнения
  - I — функция интерпретации
  ],

  align(top)[
  #text(weight: "bold")[Операционная модель]

  #v(0.5em)

  - разбор представления (AST / байткод)
  - последовательное применение правил семантики
  - явное управление состоянием
  ]
)
]

#slide(title: "Чуть более реальное описание")[#align(top)[
  ```text
  program → (AST | bytecode) → interpret → result
  ```

  #text()[Характерные свойства]

  - выполнение без отдельного этапа генерации машинного кода
  - поведение определяется правилами интерпретации
  - каждая конструкция языка обрабатывается в момент выполнения
]]

#slide(title: "Интерпретация: eval / apply")[
#grid(columns: (1fr, 1fr), gutter: 2em,

  align(top)[
  #text(weight: "bold")[Идея]

  #v(0.5em)

  *eval* — вычисляет выражение
  *apply* — применяет функцию


  ],

  align(top)[
  #text(weight: "bold")[Шаги]

  #v(0.5em)

  1. eval списка
  2. eval оператора
  3. eval аргументов
  4. apply
  ]
)

#v(1.5em)

Пример:

```lisp
(* (+ 1 2) 3)
```
- Попробуйте произвести всю последовательность операций eval, apply.
#v(1em)

]

#slide(title: "Цикл eval/apply")[
#grid(columns: (1fr, 1fr), gutter: 2em,
[

Пример:

```lisp
(* (+ 1 2) 3)
```
Цепочка вычисления:
```lisp
 eval(* (+ 1 2) 3)
 → eval(*)
 → eval((+ 1 2)), eval(3)
 → eval(+), eval(1), eval(2)
 → apply(+, 1, 2) = 3
 → apply(*, 3, 3) = 9
```
],
[#align(horizon)[#image("assets/ast-tree.png",height:100%)]])
]


#slide(title: "Специальные формы в Lisp")[
#grid(columns: (1fr, 1fr), gutter: 2em,

  align(top)[
  #text(weight: "bold")[Почему это не функции]

  #v(0.5em)

  Обычная функция:
  - сначала вычисляются все аргументы
  - затем вызывается функция

  #v(0.5em)

  Но иногда это невозможно:
  - условные выражения
  - определение переменных
  - создание функций

  #v(0.5em)

  Поэтому существуют специальные формы
  ],

  align(top)[
  #text(weight: "bold")[Примеры]

  #v(0.5em)

```lisp
(if cond then else)

(define x 10)

(lambda (x) (* x x))
```

Ключевое отличие:

- специальные формы *сами управляют тем, какие аргументы вычислять*
  ]
)
]

#slide(title: "Как устроен интерпретатор")[
#grid(columns: (1fr, 1fr), gutter: 2em,

  align(top)[
  #text(weight: "bold")[Основные компоненты]

  #v(0.5em)

  - представление программы (AST / байткод)
  - среда (environment)
  - механизм выполнения
  - стек вызовов
  ],

  align(top)[
  #text(weight: "bold")[Главный цикл]

  #v(0.5em)

```cpp
while (true) {
  instruction = next()
  execute(instruction)
}
```
  ]
)

#v(1.5em)

Различие подходов:

- интерпретация AST
- интерпретация байткода

*Практически всегда используют байткод*
]

#slide(title: "Recap: с чем мы работаем")[#align(horizon)[
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

#slide(title: "Switch-интерпретатор")[

```c
while (running) {
  switch (opcode) {
    case ADD: ...
    case MUL: ...
    case LOAD: ...
  }
}
```
#grid(columns: (1fr, 1fr), gutter: 1em,
[Особенности:

- централизованная обработка инструкций
- один большой switch
],[
Недостатки:

- большой switch → плохой branch prediction
- overhead на каждую инструкцию
])
]

#slide(title: "Посмотрим, как это сделали в OpenJDK")[#align(top)[
 - OpenJDK создавалась силами лучших инженеров, посмотрим, что у них вышло
```cpp
void Interpreter::main_loop(interpreterState istate) {
while (!stop) {
switch (opcode)
    case opc_iaload:
        arrayOop arrObj = (arrayOop)STACK_OBJECT(arrayOff);
        jint index = STACK_INT(arrayOff + 1);
        ARRAY_INDEX_CHECK(arrObj, index);
        SET_STACK_INT(GET_HEAP_INT(arrObj, index));
        UPDATE_PC_AND_TOS_AND_CONTINUE();
...
```
]]

#slide(title: "Проблемы текущего решения")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,
  [
    #align(top)[
      #text(weight: "bold")[Основные проблемы]

      #v(0.5em)
      - Неизвестность последущей инструкции
      - много обращений к различной памяти
      - программный стек для операндов
      - полная зависимость от оптимизаций компилятора
    ]
  ],
  [
    #align(center + horizon)[
      #image("assets/JVM-state.png", width: 100%)
    ]
  ]
)
]

#slide(title: "Шаблонный интерпретатор")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
    #align(top)[
      #text(weight: "bold")[Идея]

      #v(0.5em)

      - каждая инструкция имеет свой шаблон
      - шаблон = заранее подготовленный фрагмент кода
      - при исполнении выбирается нужный шаблон

    ]
  ],

  [
    #align(top)[
      #text(weight: "bold")[Схема]


```text
bytecode → template → code → execute
```

      #v(1em)

      - меньше ветвлений
      - лучше локальность
      - выше производительность
    ]
  ]
)
]

#slide(title: "Строим таблицу байткодов")[#align(top)[
- Сделаем для каждого байткода – обработчик на асссемблере
- Сделаем таблицу, в которой сохраним адреса всех обработчиков
- Каждый обработчик может вызвать следующий: через таблицу

```cpp
class DispatchTable {
public:
  enum { length = 1 << BitsPerByte };
private:
  address _table[length];
public:
  address* table_for()
              { return _table; }
};
```
]]

#slide(title: "Посмотрим на код шаблона")[#align(top)[
  - Шаблоны напишем с учётом особенностей архитектуры
  - Переменные внутри обработчика заменим регистрами
  - Используем стек процессора напрямую
#v(2em)
```cpp
void TemplateTable::iadd() {
    pop_i(x10);
    pop_i(x11);
    addi(x10, x10, x11);
    push_i(x10);
    dispatch_next();
}
```
]]

#slide(title: "Посмотрим на код шаблона")[#align(top)[
```cpp
void TemplateTable::iadd() {
    pop_i(x10);
    pop_i(x11);
    addi(x10, x10, x11);
    push_i(x10);
    dispatch_next();
}
```
#v(2em)
- Каждый обработчик вызывает после себя следующий
- `dispatch_next() -> call(table_for[++pc])`
- Видите ли вы тут проблемы?
]]
#slide(title: "Safepoint")[
#v(0.5em)

- Safepoint — это состояние выполнения программы, в котором виртуальная машина может безопасно приостановить поток и получить согласованное представление его состояния.

#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
    #align(top)[
      #text(weight: "bold")[Назначение]

      #v(0.5em)

      - остановка потоков
      - работа сборщика мусора
      - инспекция состояния
      - выполнение служебных операций
    ]
  ],

  [
    #align(top)[
      #text(weight: "bold")[Требования]

      #v(0.5em)

      - корректное состояние стека
      - известные корни (references)
      - определённое положение в программе
    ]
  ]
)]

#slide(title: "Safepoint и гранулярность")[
#v(0.5em)

- Точки остановки быть расположены в разумных местах
- Один из важных параметров JVM: TTS(Time-To-Safepoint)
#v(2em)
#image("assets/safepoint.png", width: 100%)
]
#slide(title: "Safepoint и интерпретатор")[
Интерпретатор обязан:

- предоставлять механизм safepoint
- регулярно проверять необходимость остановки


#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
    #align(top)[
      #text(weight: "bold")[Где возникают]


      - между инструкциями
      - на границах методов
      - в циклах
    ]
  ],

  [
    #align(top)[
      #text(weight: "bold")[Механизм]


```cpp
while (running) {
  check_safepoint()
  execute(opcode)
}
```
    ]
  ]
)
#note[В реальности Safepoint добавляются не после каждой инструкции, но вероятность такой необходиомсти существует]
]
#slide(title: "Ээээ, притормози по-братски")[#align(top)[
  ```cpp
  void TemplateInterpreter::notice_safepoints() {
    if (!_notice_safepoints) {
      _notice_safepoints = true;
      copy_table((address*)&_safept_table, (address*)&_active_table,
                 sizeof(_active_table) / sizeof(address));
    }
  }
  ```
  #align(center)[#image("assets/tables.png", width: 80%)]
]]
#slide(title: "О правилах разморозки")[#align(top)[
  - Создаём две таблицы вместо одной
  - Останавливаемся менее чем за время исполнения самой долгой инструкции
#v(2em)
  #align(center)[#image("assets/stop-point.png", width: 80%)]

]]

#slide(title: "Мало производительности")[#align(top)[
  - Шаблоны напишем с учётом особенностей архитектуры
  - Переменные внутри обработчика *заменим регистрами*
  - Используем стек процессора напрямую
#v(2em)
```cpp
void TemplateTable::iadd() {
    pop_i(x10);
    pop_i(x11);
    addi(x10, x10, x11);
    push_i(x10);
    dispatch_next();
}
```
]]

#slide(title: "Улучшаем интерпретатор")[#align(top)[
- Будем хранить вершину стека не в нём, а в отдельном регистре
- За счёт этого можем удалить лишние обращение из/в стек
- Есть ещё один бонус...
#v(2em)
#align(center)[#image("assets/tos.png", width: 70%)]
]]
#slide(title: "Улучшаем интерпретатор")[#align(top)[
- Будем хранить вершину стека не в нём, а в отдельном регистре
- За счёт этого можем удалить лишние обращение из/в стек
- Можем сохранить состояние вершины стека и разделить инструкции
  ```cpp
  class DispatchTable {
    public:
      enum { length = 1 << BitsPerByte };
    private:
      address _table[states][length];
    public:
      address* table_for(TosState state)
                  { return _table[state]; }
    };
    ```
]]

#slide(title: "Улучшаем интерпретатор")[#align(top)[
- Будем хранить вершину стека не в нём, а в отдельном регистре
- За счёт этого можем удалить лишние обращение из/в стек
- Можем сохранить состояние вершины стека и разделить инструкции
  #grid(columns: (1fr, 1fr), gutter: 1em,
  [
```cpp
  void TemplateTable::iadd() {
    // x10 – holds int
    pop_i(x11);
    addi(x10, x10, x11);

    update_tos(itos, itos);
    dispatch_next();
  }
  ```],[
  ```cpp
  enum TosState {
  btos = 0,ztos = 1
  ctos = 2,
  ...
  number_of_states,
  };
  ```
  ])
]]

#slide(title: "Ну как там с затратами?")[#align(top)[
  - Мы отошли от типичного интерпретатора и должны за это заплатить
  - Но платим не так уж и много
  #v(2em)
  ```bash
  $ java --XX:+UnlockDiagnosticVMOptions  -XX:+PrintInterpreter

  Interpreter
  code size        =     98K bytes
  total space      =     98K bytes
  wasted space     =      0K bytes
  # of codelets    =    280
  avg codelet size =    359 bytes
  ```
]]
#slide(title: "Давайте подумаем о будущем")[#align(top)[
  - Насколько хорошо при каждом старте VM генерировать столько кода?
 - Хотим ли мы каждый раз смотреть на то, какой байткод исполняем?
#v(2em)
- Но, об этом в следующий раз...
]]
#slide(title: "Список литературы")[#align(top)[
  - Engineering a Compiler: Keith Cooper, Linda Torczon
  - Structure and Interpretation of Computer Programs: Harold Abelson, Gerald Jay Sussman, Julie Sussman
  - JVMS SE25: https://docs.oracle.com/javase/specs/jvms/se25/html/
  - ZeroInterpreter: https://github.com/openjdk/jdk/blob/master/src/hotspot/share/interpreter/zero/bytecodeInterpreter.cpp

]]
