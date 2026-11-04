# Dungeon Stacker Desing Document
### Por Carlos Borrego Fajardo, José Carmona Rodríguez, Gonzalo Casas Rey, Rubén Gómez Bellido y Eduardo Pacheco Soto para la Game Off 2026

## Introducción
### Resumen del juego
### Inspiración
  Utilizando la temática de la Game Off (**SHIFT**) como base, partimos de la idea de cambiar entre dos mecánicas de juegos completamente distintas, siendo la primera el Tetris, junto a juegos de mazmorras, como The legend of Zelda o The Binding of Isaac, hemos creado una mezcla interesante donde utilizamos un tablero de Tetris para que el jugador genere su propia mazmorra explorable.
### Experiencia del Jugador
### Plataforma
### Sotware de Desarrollo
  + Godot v4.7
  + Krita?
### Género
  El juego mezcla el genero de **Puzzle** con un **Dungeon crawler**
### Público Objetivo
## Concept
### Jugabilidad
### Temática
### Mecánicas principales
+ **Conseguir Piezas:** El jugador explorará la mazmorra para encontrar piezas. Estas podran ser obtenidas de diversas formas, ya sea a través de cofres o matando enemigos.
+ **Colocar Piezas:** Las piezas caerán de arriba hasta abajo con el tiempo y el jugador deberá colocarlas donde quiera. Esto además lleva las siguientes submecanicas.
  - **Movimiento de piezas:** Las piezas se podran mover de izquierda a derecha.
  - **Rotación de piezas:** Las piezas se podrán rotar en sentido horario y antihorario.
  - **Eliminación de fila:** Si el jugador llena todas las casillas de la fila, esa fila será eliminada y el resto de piezas caerán hacia abajo.
+ **Tipo de piezas:** Las piezas que se colocan tienen variedad de tipos
  - **Piezas normales:** Cada parte de la pieza tendrá asignada distintos tipos de habitaciones y se podran conectar desde todas direcciones.
  - **Piezas direccionales:** Cada parte de la pieza tendrá asignada distintos tipos de habitaciones y solo se podran conectar en la dirección que se marquen.
  - **Piezas sin rotación:** Cada parte de la pieza tendrá asignada distintos tipos de habitaciones, pero tendrá bloqueada la rotación
  - **Pieza bloqueada:** Las partes de la pieza no tendrán asignadas habitaciones y no será accesible.
+ **Modificación de tablero:** El tablero puede presentar diversas modificaciones, como por ejemplo, un nivel donde no se puedan rotar las piezas o tableros en horizontal.
+ **Habitaciones:** Cada sección de las piezas tendrá una habitación de la cual hay distintas posibilidades.
  - **Habitaciones de combate:** El jugador tendrá que pelear contra enemigos.
  - **Habitaciones de desafío:** El jugador encontrará un puzle que debe resolver.
  - **Habitaciones de Tesoro:** El jugador encontrará un cofre con piezas.
  - **Habitaciones vacías:** El jugador encontrara una habitación que puede cruzar directamente.
  - **Habitaciones de Sanación:** El jugador encontrará algo que le curará.
+ **Vida:** El jugador tendrá vida, que se reducirá con los ataques enemigos y las trampas. También habrá habitaciones que te permitiran aumentar la vida.
+ **Ataque:** El jugador podrá atacar a los enemigos que halla en la habitación.

### Mecánicas secundarias

+ **Mezcla de habitaciones:** Se podrá encontrar habitaciones que incluyan varios tipos, como una habitación de combate y tesoro.
+ 
## Arte
### Temática
### Diseño
## Audio
### Música
### Efectos de Sonido
## Experiencia de Juego
### UI
### Controles
