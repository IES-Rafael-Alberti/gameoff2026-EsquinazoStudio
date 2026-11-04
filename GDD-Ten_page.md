# Dungeon Stacker Desing Document
### Por Carlos Borrego Fajardo, José Carmona Rodríguez, Gonzalo Casas Rey, Rubén Gómez Bellido y Eduardo Pacheco Soto para la Game Off 2026

## Introducción
### Resumen del juego
Dungeon Stacker es un juego que mezcla puzle de colocación de piezas y la exploración de un dungeon crawler para que el jugador se coloque las piezas generando su propia mazmorra.
### Inspiración
  Utilizando la temática de la Game Off (**SHIFT**) como base, partimos de la idea de cambiar entre dos mecánicas de juegos completamente distintas, siendo la primera el Tetris, junto a juegos de mazmorras, como The legend of Zelda o The Binding of Isaac, hemos creado una mezcla interesante donde utilizamos un tablero de Tetris para que el jugador genere su propia mazmorra explorable.
  <div align="center">
    <table>
    <tr>
      <td>Tetris</td>
      <td>The Legend of Zelda</td>
      <td>The Binding of Isaac</td>
    </tr>
    <tr>
      <td><img width="256" height="224" alt="tetris" src="https://github.com/user-attachments/assets/091c2222-19d9-4c14-98d9-cb67ffae9b3e" />
  </td>
      <td><img width="256" height="224" alt="zelda" src="https://github.com/user-attachments/assets/6224b8fa-1109-4c21-a577-64b04e245306" />
  </td>
      <td><img width="256" height="224" alt="isaac" src="https://github.com/user-attachments/assets/3312d58b-79b6-454f-9d6c-d428c2a50f6d" />
  </td>
    </tr>
  </table>
</div>

### Experiencia del Jugador
A través de los cinco niveles, el jugador el jugador deberá experimentar con las mecánicas de colocación de bloques del conocidísimo juego Tetris, para crear una mazmorra explorable donde se podrá encontrar desafíos de puzles, combate y piezas de recompensa para seguir creando la mazmorra.

### Plataforma
Se va a desarrollar para dos plataformas: PC y Web. El formato web es necesario para publicarlo en itch.io y dado que el objetivo final es poner el juego en Steam es necesario desarrollar ambas versiones.

### Sotware de Desarrollo
  + Godot v4.7
  + Krita
  + Git
  + 
### Género
  El juego mezcla el genero de **Puzzle** con un **Dungeon crawler.**
  
### Público Objetivo
El principal público objetivo son los desarrolladores de la Game Off. Ademas, apuntamos a los entusiastas de los juegos de puzzle y los juegos de mazmorras.
## Concept
### Jugabilidad
La jugabilidad parte principalmente  del cambio de modo de juego, entre la mecánica de puzle creando la mazmorra y el modo de exploración de mazmorras. El jugador podra colocar las piezas haciendo el camino para llegar al lugar deseado.
Colocar las piezas de forma eficiente para hacer los caminos.
Encontrar piezas en la mazmorra para poder seguir avanzando.
Cambio del modo de juego entre mazmorreo y creación de mazmorra.
Mecánicas propias de la mazmorra (Ataque, puzles, curas, etc)
### Temática

### Mecánicas principales
+ **Conseguir Piezas:** El jugador explorará la mazmorra para encontrar piezas. Estas podran ser obtenidas de diversas formas, ya sea a través de cofres o matando enemigos.
+ **Colocar Piezas:** Las piezas caerán de arriba hasta abajo con el tiempo y el jugador deberá colocarlas donde quiera. Esto además lleva las siguientes submecanicas.
  - **Movimiento de piezas:** Las piezas se podran mover de izquierda a derecha.
  - **Rotación de piezas:** Las piezas se podrán rotar en sentido horario y antihorario.
  - **Eliminación de fila:** Si el jugador llena todas las casillas de la fila, esa fila será eliminada y el resto de piezas caerán hacia abajo.
+ **Objetivos:** Objetivos extras en el mapa para dificultar los niveles.
  - **Puntos de referencia:** Punto por los que hay pasar por el mapa para lograr abrir la puerta final.
  - **Puertas con llaves:** Puertas que se abren al obtener llaves.
  - **Puertas de enemigos:** Puertas que se abre solo si el jugador derrota a cierta cantidad de enemigos.
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
+ **Puzles**: Algunas habitaciones de desafío tendrán puzles a resolver.
## Arte
### Temática
### Diseño
## Audio
### Música
### Efectos de Sonido
## Experiencia de Juego
### UI
### Controles
