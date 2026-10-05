# Manual de uso

## Preparar una instalación

Introduce latitud y longitud, acimut de la cara frontal e inclinación.
Las dimensiones corresponden a la **mesa completa**, no a su proyección sobre
el suelo: la longitud se mide a lo largo de la fila y la anchura transversal
sobre el plano inclinado. Si una mesa reúne varios módulos, calcula previamente
sus dimensiones totales, incluyendo las juntas que desees representar.

Selecciona de una a treinta filas y la altura del borde inferior. Al confirmar
un campo, se actualiza la instalación; el botón **Actualizar** permite repetir
el cálculo. El panel resume hueco libre, paso, anchura proyectada, altura superior,
LCR y dimensiones de la envolvente de mesas, sin márgenes exteriores.

## Explorar un día

Selecciona la fecha con el calendario. El deslizador y el campo de hora controlan
el mismo instante. **Animar día** recorre las horas con el Sol sobre el horizonte
en pasos de quince minutos; el mismo botón permite detenerlo. La gráfica diaria
también se muestrea cada quince minutos; el instante del deslizador se calcula
individualmente, por lo que los saltos de la curva diaria son aproximados.

Las sombras lejanas pueden salir del encuadre del terreno. Esto no modifica el
cálculo de intersecciones sobre los módulos.

## Hora solar o civil

El selector a la derecha de la gráfica afecta al campo de hora, al deslizador,
a la animación y al eje temporal. Al cambiar la referencia se conserva el
instante, convertido a la nueva escala.

La hora solar aparente sitúa el mediodía en 12:00. La hora civil es la del reloj
en el huso indicado. La longitud interviene en esta conversión, no en una
posición solar expresada directamente en hora solar.

Utiliza nombres IANA válidos, como `Europe/Madrid`, `Atlantic/Canary` o `UTC`.
Las reglas de horario de verano proceden de la base de zonas de MATLAB.
En fechas de cambio horario, MATLAB normaliza las horas de reloj inexistentes
y selecciona la segunda ocurrencia de las horas repetidas. Este visualizador
no pretende analizar detalladamente esos días de transición.

## Actividades sugeridas

1. En 40° N, con mesas de 2 m de anchura e inclinación de 30°, comprueba que
   con acimut 0° el hueco es aproximadamente 2,158 m y el LCR es 44,52%.
2. En el 21 de diciembre, recorre 10:30–13:30 solar: las filas no deben sombrearse.
3. Varía el acimut a ±30° y compara mañana y tarde.
4. Elige 21 de julio y 18,86 horas solares: con acimut 0° e inclinación 30°,
   el ángulo con el plano es aproximadamente −8,4°. Las mesas se oscurecen y
   todas las curvas alcanzan 100% por ausencia de iluminación frontal directa.
5. Reduce la inclinación hasta 0°: el hueco geométrico se anula y el LCR llega
   al 100%, sin considerar necesidades de acceso o mantenimiento.

## Uso del modelo sin interfaz

```matlab
addpath('src');
p = struct('lat',40,'lon',-5,'alpha',0,'beta',30, ...
           'W',10,'L',2,'n',5,'h',0.3);
m = pv_filas_modelo(p,datetime(2026,7,21),[12 18.86]);
disp(m.incidencia);       % Ángulo firmado con el plano, en grados
disp(m.fraccion);         % Indicador didáctico, fracción de 0 a 1
disp(m.fraccionGeometrica); % Sombreado geométrico entre filas solamente
```

`m.sun` contiene vectores hacia el Sol en coordenadas locales; `m.alt` y `m.az`
son altura y acimut solares. `m.posterior` identifica incidencia no frontal con
el Sol sobre el horizonte. `m.sombras` y `m.suelo` son celdas de polígonos
`polyshape` por instante y fila. Las entradas del modelo deben respetar los
rangos físicos de la interfaz: el modelo programático no valida todos los campos.
